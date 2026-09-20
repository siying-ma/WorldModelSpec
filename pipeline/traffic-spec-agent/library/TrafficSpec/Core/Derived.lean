/-
  TrafficSpec.Core.Derived
  The derived concepts of ATOMS.md §9, defined once, with their parameters exposed.

  A derived concept is the vocabulary of manoeuvres and of operationalized standards: stopped,
  turning, overtaking, yields-to, time-to-conflict, forced halt. Each is one definition here,
  named `drv_name`, computed over the trace from atoms only, three-valued with reasons. Rules
  instantiate the parameters; they never redefine a concept or rebuild it inline.

  Parameters are arguments. No default lives here: a default would be a threshold frozen before
  any law is seen. `drv_distance_while` takes the condition as a function of the instant because it
  is the one concept whose argument is a formula; Semantics passes the closure.
-/
import TrafficSpec.Core.Atoms
import TrafficSpec.Core.Params
import TrafficSpec.Core.Unknown

namespace TrafficSpec
namespace Derived

structure Ctx where
  τ : Trace
  ρ : Reading

/-- An argument as the dispatcher receives it: a resolved entity id (tracks, regions and devices
    are all `Nat`), an enumeration spelling, or a natural. -/
inductive DArg
  | v (id : Nat)
  | s (lit : String)
  | n (nat : Nat)
  deriving Repr, DecidableEq

-- ---------------------------------------------------------------------------------------------
-- Trace access
-- ---------------------------------------------------------------------------------------------
def sceneAt (τ : Trace) (i : Nat) : Option Scene := τ[i]?
def timesQ (τ : Trace) : List (Option Q) := τ.map fun s => some (Time.ofTimestamp s.t)
def pathsQ (τ : Trace) (x : TrackId) : List (Option Q) := τ.map fun s => kin_path_length s x
def positions (m : Measure) (τ : Trace) (x : TrackId) : List (Option Q) :=
  match m with
  | .time => timesQ τ
  | .path => pathsQ τ x

def at' (c : Ctx) (i : Nat) (k : Scene → R) : R :=
  match sceneAt c.τ i with
  | some s => k s
  | none => R.u .outOfRange
def atQ (c : Ctx) (i : Nat) (k : Scene → QR) : QR :=
  match sceneAt c.τ i with
  | some s => k s
  | none => .error .outOfRange

def bAtom (o : Option Bool) (name : String) : R := R.ofOption o (.absentAtom name)
def qAtom (o : Option Q) (name : String) : QR :=
  match o with
  | some q => .ok q
  | none => .error (.absentAtom name)

/-- The observations in the window of length `d` behind `i`, adequate and covered, or the reason. -/
def window (m : Measure) (op : String) (τ : Trace) (x : TrackId) (i : Nat) (d : Q) :
    Except UnknownReason (List Nat) :=
  let pos := positions m τ x
  match Time.windowBack pos i d with
  | none => .error (match m with | .path => .absentAtom "kin_path_length" | .time => .outOfRange)
  | some (idx, covered) =>
    if !covered then .error (.windowTruncated op)
    else if !(Time.adequate d (Time.select pos idx)) then .error (.samplingGap op)
    else .ok idx

/-- The observations in the window of length `d` ahead of `i`; `covered` says whether the trace
    reaches past the window. -/
def windowFwd (m : Measure) (op : String) (τ : Trace) (x : TrackId) (i : Nat) (d : Q) :
    Except UnknownReason (List Nat × Bool) :=
  let pos := positions m τ x
  match Time.windowForward pos i d with
  | none => .error (match m with | .path => .absentAtom "kin_path_length" | .time => .outOfRange)
  | some (idx, covered) =>
    if !(Time.adequate d (Time.select pos idx)) then .error (.samplingGap op)
    else .ok (idx, covered)

def overWindow (w : Except UnknownReason (List Nat)) (p : Nat → R) : R :=
  match w with
  | .error e => R.u e
  | .ok idx => R.all (idx.map p)

/-- `R.any` over the instants `j < i`, newest first. -/
def existsBack (i : Nat) (p : Nat → R) : R := R.any ((List.range i).reverse.map p)
def existsUpTo (i : Nat) (p : Nat → R) : R := R.any ((List.range (i + 1)).reverse.map p)

-- ---------------------------------------------------------------------------------------------
-- Scene-level helpers over atoms
-- ---------------------------------------------------------------------------------------------
def lanesOf (s : Scene) (x : TrackId) : Option (List RegionId) :=
  (rel_occupies_regions s x).map fun rs => rs.filter fun r => st_lane s r == some true
def occupiesKind (s : Scene) (x : TrackId) (k : StructureKind) : Option Bool :=
  (rel_occupies_regions s x).map fun rs => rs.any fun r => (s.structure? r).map (·.kind == k) == some true
def others (s : Scene) (x : TrackId) : List TrackId := s.tracks.filter (· != x)
/-- Devices of a kind governing one of the lanes `x` occupies. -/
def governing (s : Scene) (x : TrackId) (k : DeviceKind) : Option (List DeviceId) :=
  (lanesOf s x).map fun ls =>
    (devicesOfKind s k).filter fun d => ls.any fun l => dev_governs s d l == some true
def centroid (poly : List Vec) : Option Vec :=
  if poly.isEmpty then none
  else
    let n := Q.ofInt (Int.ofNat poly.length)
    let sum := poly.foldl (fun acc p => Geom.vadd acc p) (Q.zero, Q.zero)
    some (Q.div sum.1 n, Q.div sum.2 n)
def nearestVertexDistance (p : Vec) (poly : List Vec) : Option Q :=
  (poly.map fun v => Geom.norm (Geom.vsub v p)).foldl (fun acc d => match acc with
    | none => some d
    | some a => some (Q.min a d)) none
/-- The region of a kind whose boundary vertex is nearest to `x`, with that distance and its centroid. -/
def nearestRegion (s : Scene) (x : TrackId) (k : StructureKind) : Option (RegionId × Q × Vec) := do
  let p ← kin_position s x
  let cands := (regionsOfKind s k).filterMap fun r => do
    let poly ← regionBoundary s r
    let d ← nearestVertexDistance p poly
    let c ← centroid poly
    pure (r, d, c)
  cands.foldl (fun acc c => match acc with
    | none => some c
    | some a => if Q.lt c.2.1 a.2.1 then some c else some a) none

/-- Heading change (degrees, left positive) over the instants `idx` by integrating yaw rate. -/
def yawChange (c : Ctx) (x : TrackId) (idx : List Nat) : QR :=
  match idx with
  | [] => .ok Q.zero
  | _ :: rest =>
    rest.foldl (fun acc j => do
      let a ← acc
      let s ← match sceneAt c.τ j with | some s => .ok s | none => .error .outOfRange
      let sp ← match sceneAt c.τ (j - 1) with | some s => .ok s | none => .error .outOfRange
      let ω ← qAtom (kin_yaw_rate s x) "kin_yaw_rate"
      let dt := Q.sub (Time.ofTimestamp s.t) (Time.ofTimestamp sp.t)
      pure (Q.add a (Q.mul ω dt))) (.ok Q.zero)

-- ---------------------------------------------------------------------------------------------
-- The concepts. Signature: context, instant, entity arguments, parameters.
-- ---------------------------------------------------------------------------------------------

/-- speed ≤ ε for a span ≥ d. -/
def drv_stopped (c : Ctx) (i : Nat) (x : TrackId) (ε d : Q) : R :=
  overWindow (window .time "drv_stopped" c.τ x i d) fun j =>
    at' c j fun s => bAtom ((kin_speed s x).map (Q.le · ε)) "kin_speed"

/-- A road user ahead of `x` in a shared lane within longitudinal gap `g`. -/
def vehicleAheadWithin (s : Scene) (x : TrackId) (g : Q) : R :=
  R.any ((others s x).map fun y =>
    R.and (bAtom (rel_ahead_in_lane s y x) "rel_ahead_behind_in_lane")
          (bAtom ((rel_surface_gap_longitudinal s x y).map (Q.le · g)) "rel_surface_gap"))

/-- stopped for ≥ d and not in a queue: no vehicle ahead within g. -/
def drv_standing_or_parked (c : Ctx) (i : Nat) (x : TrackId) (ε d g : Q) : R :=
  R.and (drv_stopped c i x ε d) (at' c i fun s => R.not (vehicleAheadWithin s x g))

/-- stopped at the previous observation, moving now. -/
def drv_moving_off (c : Ctx) (i : Nat) (x : TrackId) (ε : Q) : R :=
  if i = 0 then R.u (.windowTruncated "drv_moving_off")
  else R.and (at' c i fun s => bAtom ((kin_speed s x).map (Q.gt · ε)) "kin_speed")
             (at' c (i - 1) fun s => bAtom ((kin_speed s x).map (Q.le · ε)) "kin_speed")

/-- heading change ≥ θ (degrees) over the window w, to the left when `left`, else to the right. -/
def drv_turning (c : Ctx) (i : Nat) (x : TrackId) (left : Bool) (θ w : Q) : R :=
  match window .time "drv_turning" c.τ x i w with
  | .error e => R.u e
  | .ok idx =>
    match yawChange c x idx with
    | .error e => R.u e
    | .ok Δ => R.ofBool (if left then Q.ge Δ θ else Q.le Δ (Q.neg θ))

/-- heading reversal within w: |Δ| within tol of a half turn. -/
def drv_u_turn (c : Ctx) (i : Nat) (x : TrackId) (w tol : Q) : R :=
  match window .time "drv_u_turn" c.τ x i w with
  | .error e => R.u e
  | .ok idx =>
    match yawChange c x idx with
    | .error e => R.u e
    | .ok Δ =>
      let a := Q.abs Δ
      R.ofBool (Q.ge a (Q.sub (Units.degrees 180) tol) && Q.le a (Q.add (Units.degrees 180) tol))

/-- the lane occupied now is an adjacent same-direction neighbour of the lane occupied before. -/
def drv_lane_change (c : Ctx) (i : Nat) (x : TrackId) : R :=
  if i = 0 then R.u (.windowTruncated "drv_lane_change")
  else at' c i fun s => at' c (i - 1) fun sp =>
    R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun now =>
    R.bindOpt (lanesOf sp x) (.absentAtom "rel_occupies") fun before =>
      match now, before with
      | [l], [lp] =>
        if l == lp then R.f
        else R.ofBool (st_lane_adjacency_left sp lp == some l || st_lane_adjacency_right sp lp == some l)
      | _, _ => R.f

/-- the neighbouring lane on `side` has no other user within longitudinal gap g. -/
def drv_lane_change_feasible (c : Ctx) (i : Nat) (x : TrackId) (left : Bool) (g : Q) : R :=
  at' c i fun s =>
    R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun ls =>
      match ls with
      | [l] =>
        let nb := if left then st_lane_adjacency_left s l else st_lane_adjacency_right s l
        match nb with
        | none => R.f
        | some n =>
          R.not (R.any ((others s x).map fun y =>
            R.and (bAtom (rel_occupies s y n) "rel_occupies")
                  (bAtom ((rel_surface_gap_longitudinal s x y).map (Q.le · g)) "rel_surface_gap")))
      | _ => R.f

/-- `b` was ahead of `a` at some earlier instant and is behind now. -/
def drv_overtaking (c : Ctx) (i : Nat) (a b : TrackId) : R :=
  R.and (at' c i fun s => bAtom (rel_bearing_behind s a b) "rel_bearing")
        (existsBack i fun j => at' c j fun s => bAtom (rel_bearing_ahead s a b) "rel_bearing")

/-- the overtaken `b` was on `a`'s left (`left`) or right while the bodies overlapped. -/
def drv_passing_side (c : Ctx) (i : Nat) (a b : TrackId) (left : Bool) : R :=
  existsUpTo i fun j => at' c j fun s =>
    R.and (bAtom ((rel_longitudinal_overlap s a b).map (Q.ge · Q.zero)) "rel_longitudinal_overlap")
          (bAtom (if left then rel_bearing_left s a b else rel_bearing_right s a b) "rel_bearing")

def drv_in_intersection (c : Ctx) (i : Nat) (x : TrackId) (k : StructureKind) : R :=
  at' c i fun s => bAtom (occupiesKind s x k) "rel_occupies"

def drv_entering_intersection (c : Ctx) (i : Nat) (x : TrackId) (k : StructureKind) : R :=
  if i = 0 then R.u (.windowTruncated "drv_entering_intersection")
  else R.and (drv_in_intersection c i x k) (R.not (drv_in_intersection c (i - 1) x k))

/-- outside the region, within d of its boundary, and moving toward it. -/
def drv_approaching (c : Ctx) (i : Nat) (x : TrackId) (k : StructureKind) (d : Q) : R :=
  at' c i fun s =>
    R.and (R.not (bAtom (occupiesKind s x k) "rel_occupies"))
      (R.bindOpt (nearestRegion s x k) (.absentAtom "regionBoundary") fun (_, dist, cen) =>
       R.bindOpt (kin_position s x) (.absentAtom "kin_position") fun p =>
       R.bindOpt (kin_velocity s x) (.absentAtom "kin_velocity") fun v =>
         R.ofBool (Q.le dist d && Q.gt (Geom.dot v (Geom.vsub cen p)) Q.zero))

def drv_crossing_line (c : Ctx) (i : Nat) (x : TrackId) (k : StructureKind) : R :=
  drv_entering_intersection c i x k

/-- the region is behind and the trailing end is at least d past its nearest boundary. -/
def drv_cleared_line (c : Ctx) (i : Nat) (x : TrackId) (k : StructureKind) (d : Q) : R :=
  at' c i fun s =>
    R.bindOpt (nearestRegion s x k) (.absentAtom "regionBoundary") fun (_, dist, cen) =>
    R.bindOpt (kin_position s x) (.absentAtom "kin_position") fun p =>
    R.bindOpt (kin_heading s x) (.absentAtom "kin_heading") fun h =>
    R.bindOpt (kin_extent s x) (.absentAtom "kin_extent") fun (hl, _, _) =>
      R.ofBool (Q.lt (Geom.dot h (Geom.vsub cen p)) Q.zero && Q.ge (Q.sub dist hl) d)

def drv_backing (c : Ctx) (i : Nat) (x : TrackId) : R :=
  at' c i fun s =>
    R.bindOpt (kin_velocity s x) (.absentAtom "kin_velocity") fun v =>
    R.bindOpt (kin_heading s x) (.absentAtom "kin_heading") fun h =>
      R.ofBool (Q.lt (Geom.dot v h) Q.zero)

/-- same lane, `b` ahead of `a`, longitudinal gap ≤ g. -/
def drv_following (c : Ctx) (i : Nat) (a b : TrackId) (g : Q) : R :=
  at' c i fun s =>
    R.and (bAtom (rel_ahead_in_lane s b a) "rel_ahead_behind_in_lane")
          (bAtom ((rel_surface_gap_longitudinal s a b).map (Q.le · g)) "rel_surface_gap")

/-- longitudinal gap ÷ the follower's speed. -/
def drv_time_gap (c : Ctx) (i : Nat) (a b : TrackId) : QR :=
  atQ c i fun s => do
    let gap ← qAtom (rel_surface_gap_longitudinal s a b) "rel_surface_gap"
    let v ← qAtom (kin_speed s a) "kin_speed"
    if Q.isZero v then .error (.divisionByZero "drv_time_gap") else .ok (Q.div gap v)

/-- time to closest approach within the sum of half-lengths under constant velocity; `horizon` when
    the paths do not meet within the horizon. -/
def drv_time_to_conflict (c : Ctx) (i : Nat) (a b : TrackId) (horizon : Q) : QR :=
  atQ c i fun s => do
    let pa ← qAtomV (kin_position s a) "kin_position"
    let pb ← qAtomV (kin_position s b) "kin_position"
    let va ← qAtomV (kin_velocity s a) "kin_velocity"
    let vb ← qAtomV (kin_velocity s b) "kin_velocity"
    let (la, _, _) ← (match kin_extent s a with | some e => .ok e | none => .error (.absentAtom "kin_extent"))
    let (lb, _, _) ← (match kin_extent s b with | some e => .ok e | none => .error (.absentAtom "kin_extent"))
    let r := Geom.vsub pb pa
    let v := Geom.vsub vb va
    let vv := Geom.dot v v
    if Q.isZero vv then .ok horizon
    else
      let tstar := Q.neg (Q.div (Geom.dot r v) vv)
      if Q.lt tstar Q.zero || Q.gt tstar horizon then .ok horizon
      else
        let closest := Geom.vadd r (Q.mul tstar v.1, Q.mul tstar v.2)
        let thr := Q.add la lb
        if Q.le (Geom.normSq closest) (Q.mul thr thr) then .ok tstar else .ok horizon
where
  qAtomV (o : Option Vec) (name : String) : Except UnknownReason Vec :=
    match o with | some v => .ok v | none => .error (.absentAtom name)

/-- oncoming and the paths meet within t. -/
def drv_meeting (c : Ctx) (i : Nat) (a b : TrackId) (t cosTol : Q) : R :=
  at' c i fun s =>
    R.and (bAtom (rel_oncoming s a b cosTol) "rel_oncoming")
      (match drv_time_to_conflict c i a b t with
       | .error e => R.u e
       | .ok ttc => R.ofBool (Q.lt ttc t))

/-- `a` slowed to ≤ ε while `b`, once ahead, passed to behind. -/
def drv_yields_to (c : Ctx) (i : Nat) (a b : TrackId) (ε : Q) : R :=
  R.and (at' c i fun s => bAtom (rel_bearing_behind s a b) "rel_bearing")
    (existsBack i fun j =>
      R.and (at' c j fun s => bAtom (rel_bearing_ahead s a b) "rel_bearing")
            (R.any ((List.range (i - j + 1)).map fun o => at' c (j + o) fun s =>
               bAtom ((kin_speed s a).map (Q.le · ε)) "kin_speed")))

/-- first instant ≤ i at which `x` occupies a region of kind k. -/
def firstArrival (c : Ctx) (i : Nat) (x : TrackId) (k : StructureKind) : Except UnknownReason (Option Q) :=
  let step (acc : Except UnknownReason (Option Q)) (j : Nat) : Except UnknownReason (Option Q) := do
    let a ← acc
    match a with
    | some t => pure (some t)
    | none =>
      match sceneAt c.τ j with
      | none => .error .outOfRange
      | some s =>
        match occupiesKind s x k with
        | none => .error (.absentAtom "rel_occupies")
        | some true => pure (some (Time.ofTimestamp s.t))
        | some false => pure none
  (List.range (i + 1)).foldl step (.ok none)

/-- `before`: `a` reached the region more than τ before `b` (`b` may not have arrived yet).
    `same`: both reached it within τ of each other. -/
def drv_arrival_order (c : Ctx) (i : Nat) (a b : TrackId) (k : StructureKind) (same : Bool) (τ : Q) : R :=
  match firstArrival c i a k, firstArrival c i b k with
  | .error e, _ | _, .error e => R.u e
  | .ok (some ta), .ok (some tb) =>
    if same then R.ofBool (Q.le (Q.abs (Q.sub ta tb)) τ) else R.ofBool (Q.lt ta (Q.sub tb τ))
  | .ok (some _), .ok none => if same then R.u (.windowTruncated "drv_arrival_order") else R.t
  | .ok none, _ => R.u (.windowTruncated "drv_arrival_order")

/-- heading opposed to the occupied lane's direction (cosine ≤ −tol). -/
def drv_wrong_way (c : Ctx) (i : Nat) (x : TrackId) (tol : Q) : R :=
  at' c i fun s =>
    R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun ls =>
    R.bindOpt (kin_heading s x) (.absentAtom "kin_heading") fun h =>
      R.any (ls.map fun l =>
        R.bindOpt (st_lane_direction s l) (.absentAtom "st_lane_direction") fun d =>
          let n := Q.mul (Geom.norm h) (Geom.norm d)
          if Q.isZero n then R.u (.malformed "zero heading") else
          R.ofBool (Q.le (Geom.dot h d) (Q.neg (Q.mul tol n))))

def drv_straddles_marking (c : Ctx) (i : Nat) (x : TrackId) : R :=
  at' c i fun s => R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun ls => R.ofBool (ls.length ≥ 2)

/-- emergency class with red or blue warning lamps or a siren; an unobserved lamp or siren is unknown. -/
def drv_responding_emergency (c : Ctx) (i : Nat) (x : TrackId) : R :=
  at' c i fun s =>
    R.and (bAtom (ru_emergency_vehicle s x) "ru_emergency_vehicle")
      (R.or (R.or (bAtom (sig_warning_lamp_colour s x .red) "sig_warning_lamp")
                  (bAtom (sig_warning_lamp_colour s x .blue) "sig_warning_lamp"))
            (bAtom (sig_siren s x) "sig_siren"))

/-- pedestrian or rider of a bicycle, electric bicycle or electric scooter, or a class the reading adds. -/
def drv_vulnerable_road_user (c : Ctx) (i : Nat) (x : TrackId) : R :=
  at' c i fun s =>
    let base := [ru_pedestrian s x, ru_bicycle s x, ru_electric_bicycle s x, ru_electric_scooter s x]
    let extra := match c.ρ.aggregate "vulnerable" with
      | some cls => cls.filterMap fun id => (RoadUserClass.ofString (id.drop 3).toString).map fun k =>
          (s.user x).bind fun u => if u.unobservedClasses.contains k then none else u.classes.map (·.contains k)
      | none => []
    R.any ((base ++ extra).map fun o => bAtom o "ru_class")

def drv_laned_roadway (c : Ctx) (i : Nat) (x : TrackId) : R :=
  at' c i fun s =>
    R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun ls =>
      R.any (ls.map fun l => bAtom ((st_lane_adjacency_count s l).map (· ≥ 2)) "st_lane_adjacency")

def drv_extreme_lane (c : Ctx) (i : Nat) (x : TrackId) (left : Bool) : R :=
  at' c i fun s =>
    R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun ls =>
      R.any (ls.map fun l =>
        R.bindOpt (st_lane_adjacency_ordinal s l) (.absentAtom "st_lane_adjacency") fun o =>
        R.bindOpt (st_lane_adjacency_count s l) (.absentAtom "st_lane_adjacency") fun n =>
          R.ofBool (if left then o == 0 else o + 1 == n))

/-- the lane `x` occupies leads to a junction region whose other entering lanes carry a stop or
    yield sign, and its own lane carries none. -/
def drv_priority_roadway (c : Ctx) (i : Nat) (x : TrackId) : R :=
  at' c i fun s =>
    R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun ls =>
      match ls with
      | [l] =>
        R.bindOpt (st_lane_connectivity s l) (.absentAtom "st_lane_connectivity") fun targets =>
          let signs := devicesOfKind s .stopSign ++ devicesOfKind s .yieldSign
          let ownSigned := signs.any fun d => dev_governs s d l == some true
          let otherSigned := signs.any fun d =>
            (dev_governs_regions s d).getD [] |>.any fun r =>
              r != l && ((st_lane_connectivity s r).getD []).any (targets.contains ·)
          R.ofBool (!ownSigned && otherSigned)
      | _ => R.f

/-- path length over which `holds` has held continuously up to `i`. -/
def drv_distance_while (c : Ctx) (i : Nat) (x : TrackId) (holds : Nat → R) : QR :=
  let rec back (j : Nat) (fuel : Nat) : Except UnknownReason Nat :=
    match fuel with
    | 0 => .ok j
    | fuel + 1 =>
      match (holds j).v with
      | .u => .error (match (holds j).why.head? with | some w => w | none => .malformed "drv_distance_while")
      | .f => .ok (j + 1)
      | .t => if j = 0 then .ok 0 else back (j - 1) fuel
  match (holds i).v with
  | .u => .error (match (holds i).why.head? with | some w => w | none => .malformed "drv_distance_while")
  | .f => .ok Q.zero
  | .t => do
    let j0 ← back i (i + 1)
    let si ← (match sceneAt c.τ i with | some s => .ok s | none => .error .outOfRange)
    let sj ← (match sceneAt c.τ j0 with | some s => .ok s | none => .error .outOfRange)
    let pi ← qAtom (kin_path_length si x) "kin_path_length"
    let pj ← qAtom (kin_path_length sj x) "kin_path_length"
    pure (Q.sub pi pj)

/-- between a begin sign of kind k governing a lane `x` occupies and its end sign. -/
def drv_within_signed_zone (c : Ctx) (i : Nat) (x : TrackId) (k : ZoneKind) : R :=
  let rec back (j : Nat) (fuel : Nat) : R :=
    match fuel with
    | 0 => R.u (.windowTruncated "drv_within_signed_zone")
    | fuel + 1 =>
      at' c j fun s =>
        match lanesOf s x with
        | none => R.u (.absentAtom "rel_occupies")
        | some ls =>
          let signs := (devicesOfKind s .zoneSign).filter fun d =>
            dev_zone_sign_kind s d == some k && ls.any fun l => dev_governs s d l == some true
          match signs.find? (fun d => dev_zone_sign_end s d == some false),
                signs.find? (fun d => dev_zone_sign_end s d == some true) with
          | some _, _ => R.t
          | none, some _ => R.f
          | none, none => if j = 0 then R.u (.windowTruncated "drv_within_signed_zone") else back (j - 1) fuel
  back i (i + 1)

/-- a device's conditions hold now for the subject `x`. -/
def drv_condition_in_effect (c : Ctx) (i : Nat) (d : DeviceId) (x : TrackId) : R :=
  at' c i fun s =>
    let conds := match dev_zone_sign_conditions s d with
      | some cd => some cd
      | none => dev_regulatory_sign_conditions s d
    R.bindOpt conds (.absentAtom "dev_zone_sign_conditions") fun cd =>
      let timeOk : R :=
        if cd.windows.isEmpty then R.t
        else R.bindOpt (env_civil_time s) (.absentAtom "env_civil_time") fun ct =>
          R.any (cd.windows.map fun w =>
            let dayOk : R := match w.calendarClass with
              | some cls => R.ofOption (s.assumption cls) (.assumptionMissing cls)
              | none => R.ofBool (w.weekdays.isEmpty || w.weekdays.contains ct.weekday)
            R.and dayOk (R.ofBool (w.startMinute ≤ ct.minuteOfDay && ct.minuteOfDay < w.endMinute)))
      let occOk : R := match cd.minOccupancy with
        | none => R.t
        | some n => bAtom ((ru_occupant_count s x).map (· ≥ n)) "ru_occupant_count"
      let clsOk : R := match cd.vehicleClass with
        | none => R.t
        | some k => bAtom ((s.user x).bind fun u =>
            if u.unobservedClasses.contains k then none else u.classes.map (·.contains k)) "ru_class"
      let childOk : R :=
        if cd.whenChildrenPresent then R.any (s.tracks.map fun y => bAtom (ru_child s y) "ru_child") else R.t
      R.and (R.and timeOk occOk) (R.and clsOk childOk)

/-- civil time later than sunset plus `afterSunset` or earlier than sunrise minus `beforeSunrise`
    (all in minutes of the day, supplied by the reading for the date and place). -/
def drv_civil_night (c : Ctx) (i : Nat) (sunset sunrise afterSunset beforeSunrise : Q) : R :=
  at' c i fun s =>
    R.bindOpt (env_civil_time s) (.absentAtom "env_civil_time") fun ct =>
      let m := Q.ofInt (Int.ofNat ct.minuteOfDay)
      R.ofBool (Q.ge m (Q.add sunset afterSunset) || Q.le m (Q.sub sunrise beforeSunrise))

/-- at least n vehicles in line behind `x`, each within gap g of the one ahead. -/
def drv_queue_behind (c : Ctx) (i : Nat) (x : TrackId) (n : Nat) (g : Q) : R :=
  at' c i fun s =>
    let rec chain (cur : TrackId) (fuel : Nat) (count : Nat) : Nat :=
      match fuel with
      | 0 => count
      | fuel + 1 =>
        match (others s cur).find? (fun y =>
            rel_ahead_in_lane s cur y == some true &&
            ((rel_surface_gap_longitudinal s y cur).map (Q.le · g)) == some true) with
        | some y => chain y fuel (count + 1)
        | none => count
    R.ofBool (chain x s.users.length 0 ≥ n)

/-- complete cycles (transitions into circular green) of the signal governing `x` since `x` stopped. -/
def drv_signal_cycles (c : Ctx) (i : Nat) (x : TrackId) (ε : Q) : QR :=
  atQ c i fun s => do
    let gov ← (match governing s x .trafficSignal with
      | some (d :: _) => .ok d
      | some [] => .error (.absentAtom "dev_traffic_signal")
      | none => .error (.absentAtom "rel_occupies"))
    -- start of the stop: scan back while speed ≤ ε
    let rec start (j : Nat) (fuel : Nat) : Except UnknownReason Nat :=
      match fuel with
      | 0 => .ok j
      | fuel + 1 =>
        match sceneAt c.τ j with
        | none => .error .outOfRange
        | some sj =>
          match (kin_speed sj x).map (Q.le · ε) with
          | none => .error (.absentAtom "kin_speed")
          | some false => .ok (j + 1)
          | some true => if j = 0 then .ok 0 else start (j - 1) fuel
    let j0 ← start i (i + 1)
    let green (j : Nat) : Option Bool := (sceneAt c.τ j).bind fun sj => dev_traffic_signal_shows sj gov .circularGreen
    let count := (List.range (i - j0)).foldl (fun acc o =>
      let k := j0 + o + 1
      if green k == some true && green (k - 1) == some false then acc + 1 else acc) 0
    pure (Q.ofInt (Int.ofNat count))

/-- the governing maximum-speed sign's value, the lowest when several govern. -/
def postedLimit (s : Scene) (x : TrackId) : Option Q :=
  (governing s x .speedLimitSign).bind fun ds =>
    let vals := ds.filterMap fun d =>
      if dev_speed_limit_sign_kind s d == some .maximum then dev_speed_limit_sign_value s d else none
    vals.foldl (fun acc v => match acc with | none => some v | some a => some (Q.min a v)) none

def drv_slower_than_posted (c : Ctx) (i : Nat) (x : TrackId) (margin : Q) : R :=
  at' c i fun s =>
    R.bindOpt (postedLimit s x) (.absentAtom "dev_speed_limit_sign") fun lim =>
    R.bindOpt (kin_speed s x) (.absentAtom "kin_speed") fun v =>
      R.ofBool (Q.le v (Q.sub lim margin))

/-- speed below the median of same-direction users within range r by at least `margin`. -/
def drv_speed_below_traffic (c : Ctx) (i : Nat) (x : TrackId) (r margin cosTol : Q) : R :=
  at' c i fun s =>
    R.bindOpt (kin_speed s x) (.absentAtom "kin_speed") fun v =>
      let speeds := (others s x).filterMap fun y =>
        if (rel_centre_distance s x y).map (Q.le · r) == some true &&
           rel_same_direction s x y cosTol == some true then kin_speed s y else none
      if speeds.isEmpty then R.u (.absentAtom "surrounding traffic")
      else
        let sorted := speeds.toArray.qsort (fun a b => Q.lt a b) |>.toList
        let med := sorted[sorted.length / 2]!
        R.ofBool (Q.le v (Q.sub med margin))

/-- v·t_r + v²/(2a). -/
def drv_stopping_distance (c : Ctx) (i : Nat) (x : TrackId) (a reaction : Q) : QR :=
  atQ c i fun s => do
    let v ← qAtom (kin_speed s x) "kin_speed"
    if Q.isZero a || !Q.isNonneg a then .error (.divisionByZero "drv_stopping_distance")
    else .ok (Q.add (Q.mul v reaction) (Q.div (Q.mul v v) (Q.mul (Q.ofInt 2) a)))

/-- the sight distance recorded for a region `x` occupies is at least its stopping distance. -/
def drv_sight_distance_adequate (c : Ctx) (i : Nat) (x : TrackId) (a reaction : Q) : R :=
  at' c i fun s =>
    match drv_stopping_distance c i x a reaction with
    | .error e => R.u e
    | .ok sd =>
      R.bindOpt (rel_occupies_regions s x) (.absentAtom "rel_occupies") fun rs =>
        let sights := rs.filterMap fun r => st_sight_distance s r
        match sights with
        | [] => R.u (.absentAtom "st_sight_distance")
        | v :: rest => R.ofBool (Q.ge (rest.foldl Q.min v) sd)

def drv_hard_deceleration (c : Ctx) (i : Nat) (x : TrackId) (bound : Q) : R :=
  at' c i fun s => bAtom ((kin_accel_longitudinal s x).map fun acc => Q.le acc (Q.neg bound)) "kin_accel_longitudinal"

/-- halted (speed ≤ ε) with a halted vehicle ahead within g, or a governing device or officer
    requiring a halt. -/
def drv_forced_halt (c : Ctx) (i : Nat) (x : TrackId) (g ε : Q) : R :=
  at' c i fun s =>
    let halted := bAtom ((kin_speed s x).map (Q.le · ε)) "kin_speed"
    let aheadHalted := R.any ((others s x).map fun y =>
      R.and (bAtom (rel_ahead_in_lane s y x) "rel_ahead_behind_in_lane")
        (R.and (bAtom ((rel_surface_gap_longitudinal s x y).map (Q.le · g)) "rel_surface_gap")
               (bAtom ((kin_speed s y).map (Q.le · ε)) "kin_speed")))
    let redSignal := match governing s x .trafficSignal with
      | none => R.u (.absentAtom "rel_occupies")
      | some ds => R.any (ds.map fun d =>
          R.or (bAtom (dev_traffic_signal_shows s d .circularRed) "dev_traffic_signal")
               (bAtom (dev_traffic_signal_shows s d .flashingRed) "dev_traffic_signal"))
    let stopSign := match governing s x .stopSign with
      | none => R.u (.absentAtom "rel_occupies")
      | some ds => R.ofBool (!ds.isEmpty)
    let officer := match governing s x .humanDirection with
      | none => R.u (.absentAtom "rel_occupies")
      | some ds => R.any (ds.map fun d => bAtom ((dev_human_direction_indication s d).map (· == .stop)) "dev_human_direction")
    R.and halted (R.or (R.or aheadHalted redSignal) (R.or stopSign officer))

/-- a police officer governs a lane `x` occupies and gives an indication. -/
def drv_officer_directed (c : Ctx) (i : Nat) (x : TrackId) : R :=
  at' c i fun s =>
    match governing s x .humanDirection with
    | none => R.u (.absentAtom "rel_occupies")
    | some ds => R.any (ds.map fun d =>
        R.and (bAtom ((dev_human_direction_role s d).map (· == .policeOfficer)) "dev_human_direction")
              (bAtom ((dev_human_direction_indication s d).map fun _ => true) "dev_human_direction"))

-- ---------------------------------------------------------------------------------------------
-- Dispatch by name, for the formula evaluator. Arguments arrive resolved; parameters as Q.
-- ---------------------------------------------------------------------------------------------
private def side (a : DArg) : Except UnknownReason Bool :=
  match a with
  | .s "left" => .ok true
  | .s "right" => .ok false
  | _ => .error (.malformed "side")
private def order (a : DArg) : Except UnknownReason Bool :=
  match a with
  | .s "before" => .ok false
  | .s "same" => .ok true
  | _ => .error (.malformed "arrival order")
private def skind (a : DArg) : Except UnknownReason StructureKind :=
  match a with
  | .s k => match StructureKind.ofString k with | some v => .ok v | none => .error (.malformed k)
  | _ => .error (.malformed "structure kind")
private def zkind (a : DArg) : Except UnknownReason ZoneKind :=
  match a with
  | .s k => match ZoneKind.ofString k with | some v => .ok v | none => .error (.malformed k)
  | _ => .error (.malformed "zone kind")
private def tid (a : DArg) : Except UnknownReason TrackId :=
  match a with | .v t => .ok t | .n n => .ok n | _ => .error (.malformed "entity")
private def natArg (a : DArg) : Except UnknownReason Nat :=
  match a with | .n n => .ok n | .v t => .ok t | _ => .error (.malformed "natural")
private def lift (e : Except UnknownReason R) : R :=
  match e with | .ok r => r | .error w => R.u w

/-- Every `drv_*` definition of this file, Boolean and quantity-valued, plus the one Semantics
    evaluates directly (`drv_distance_while`). The doctor holds this against `derivedIds`. -/
def derivedNames : List String := [
  "drv_stopped", "drv_standing_or_parked", "drv_moving_off", "drv_turning", "drv_u_turn",
  "drv_lane_change", "drv_lane_change_feasible", "drv_overtaking", "drv_passing_side",
  "drv_entering_intersection", "drv_in_intersection", "drv_approaching", "drv_crossing_line",
  "drv_cleared_line", "drv_backing", "drv_following", "drv_time_gap", "drv_time_to_conflict",
  "drv_meeting", "drv_yields_to", "drv_arrival_order", "drv_wrong_way", "drv_straddles_marking",
  "drv_responding_emergency", "drv_vulnerable_road_user", "drv_laned_roadway", "drv_extreme_lane",
  "drv_priority_roadway", "drv_distance_while", "drv_within_signed_zone", "drv_condition_in_effect",
  "drv_civil_night", "drv_queue_behind", "drv_signal_cycles", "drv_slower_than_posted",
  "drv_speed_below_traffic", "drv_sight_distance_adequate", "drv_stopping_distance",
  "drv_hard_deceleration", "drv_forced_halt", "drv_officer_directed"]

/-- The atoms each derived concept reads (Lean names of Atoms.lean). Manifest.lean turns a rule's
    derived concepts into the atoms a source must observe; the VLM stage reads it the other way. -/
def reads (n : String) : List String :=
  match n with
  | "drv_stopped" => ["kin_speed"]
  | "drv_standing_or_parked" => ["kin_speed", "rel_ahead_behind_in_lane", "rel_surface_gap"]
  | "drv_moving_off" => ["kin_speed"]
  | "drv_turning" => ["kin_yaw_rate"]
  | "drv_u_turn" => ["kin_yaw_rate"]
  | "drv_lane_change" => ["rel_occupies", "st_lane", "st_lane_adjacency"]
  | "drv_lane_change_feasible" => ["rel_occupies", "st_lane", "st_lane_adjacency", "rel_surface_gap"]
  | "drv_overtaking" => ["rel_bearing"]
  | "drv_passing_side" => ["rel_longitudinal_overlap", "rel_bearing"]
  | "drv_entering_intersection" => ["rel_occupies"]
  | "drv_in_intersection" => ["rel_occupies"]
  | "drv_approaching" => ["rel_occupies", "kin_position", "kin_velocity"]
  | "drv_crossing_line" => ["rel_occupies"]
  | "drv_cleared_line" => ["kin_position", "kin_heading", "kin_extent"]
  | "drv_backing" => ["kin_velocity", "kin_heading"]
  | "drv_following" => ["rel_ahead_behind_in_lane", "rel_surface_gap"]
  | "drv_time_gap" => ["rel_surface_gap", "kin_speed"]
  | "drv_time_to_conflict" => ["kin_position", "kin_velocity", "kin_extent"]
  | "drv_meeting" => ["rel_oncoming", "kin_position", "kin_velocity", "kin_extent"]
  | "drv_yields_to" => ["rel_bearing", "kin_speed"]
  | "drv_arrival_order" => ["rel_occupies"]
  | "drv_wrong_way" => ["rel_occupies", "st_lane", "st_lane_direction", "kin_heading"]
  | "drv_straddles_marking" => ["rel_occupies", "st_lane"]
  | "drv_responding_emergency" => ["ru_emergency_vehicle", "sig_warning_lamp", "sig_siren"]
  | "drv_vulnerable_road_user" => ["ru_pedestrian", "ru_bicycle", "ru_electric_bicycle", "ru_electric_scooter"]
  | "drv_laned_roadway" => ["rel_occupies", "st_lane", "st_lane_adjacency"]
  | "drv_extreme_lane" => ["rel_occupies", "st_lane", "st_lane_adjacency"]
  | "drv_priority_roadway" => ["rel_occupies", "st_lane", "st_lane_connectivity", "dev_stop_sign", "dev_yield_sign", "dev_governs"]
  | "drv_distance_while" => ["kin_path_length"]
  | "drv_within_signed_zone" => ["rel_occupies", "st_lane", "dev_zone_sign", "dev_governs"]
  | "drv_condition_in_effect" => ["dev_zone_sign", "dev_regulatory_sign", "env_civil_time", "ru_occupant_count", "ru_child"]
  | "drv_civil_night" => ["env_civil_time"]
  | "drv_queue_behind" => ["rel_ahead_behind_in_lane", "rel_surface_gap"]
  | "drv_signal_cycles" => ["rel_occupies", "st_lane", "dev_traffic_signal", "dev_governs", "kin_speed"]
  | "drv_slower_than_posted" => ["rel_occupies", "st_lane", "dev_speed_limit_sign", "dev_governs", "kin_speed"]
  | "drv_speed_below_traffic" => ["kin_speed", "rel_centre_distance", "rel_same_direction"]
  | "drv_sight_distance_adequate" => ["kin_speed", "rel_occupies", "st_sight_distance"]
  | "drv_stopping_distance" => ["kin_speed"]
  | "drv_hard_deceleration" => ["kin_accel_longitudinal"]
  | "drv_forced_halt" => ["kin_speed", "rel_ahead_behind_in_lane", "rel_surface_gap", "rel_occupies", "st_lane", "dev_traffic_signal", "dev_stop_sign", "dev_human_direction", "dev_governs"]
  | "drv_officer_directed" => ["rel_occupies", "st_lane", "dev_human_direction", "dev_governs"]
  | _ => []

/-- Boolean derived concepts. Unlisted names, wrong arities or wrong literals are `malformed`. -/
def evalB (name : String) (c : Ctx) (i : Nat) (args : List DArg) (ps : List Q) : R :=
  lift <| match name, args, ps with
  | "drv_stopped", [x], [ε, d] => do pure (drv_stopped c i (← tid x) ε d)
  | "drv_standing_or_parked", [x], [ε, d, g] => do pure (drv_standing_or_parked c i (← tid x) ε d g)
  | "drv_moving_off", [x], [ε] => do pure (drv_moving_off c i (← tid x) ε)
  | "drv_turning", [x, sd], [θ, w] => do pure (drv_turning c i (← tid x) (← side sd) θ w)
  | "drv_u_turn", [x], [w, tol] => do pure (drv_u_turn c i (← tid x) w tol)
  | "drv_lane_change", [x], [] => do pure (drv_lane_change c i (← tid x))
  | "drv_lane_change_feasible", [x, sd], [g] => do pure (drv_lane_change_feasible c i (← tid x) (← side sd) g)
  | "drv_overtaking", [a, b], [] => do pure (drv_overtaking c i (← tid a) (← tid b))
  | "drv_passing_side", [a, b, sd], [] => do pure (drv_passing_side c i (← tid a) (← tid b) (← side sd))
  | "drv_entering_intersection", [x, k], [] => do pure (drv_entering_intersection c i (← tid x) (← skind k))
  | "drv_in_intersection", [x, k], [] => do pure (drv_in_intersection c i (← tid x) (← skind k))
  | "drv_approaching", [x, k], [d] => do pure (drv_approaching c i (← tid x) (← skind k) d)
  | "drv_crossing_line", [x, k], [] => do pure (drv_crossing_line c i (← tid x) (← skind k))
  | "drv_cleared_line", [x, k], [d] => do pure (drv_cleared_line c i (← tid x) (← skind k) d)
  | "drv_backing", [x], [] => do pure (drv_backing c i (← tid x))
  | "drv_following", [a, b], [g] => do pure (drv_following c i (← tid a) (← tid b) g)
  | "drv_meeting", [a, b], [t, cosTol] => do pure (drv_meeting c i (← tid a) (← tid b) t cosTol)
  | "drv_yields_to", [a, b], [ε] => do pure (drv_yields_to c i (← tid a) (← tid b) ε)
  | "drv_arrival_order", [a, b, k, m], [τ] => do pure (drv_arrival_order c i (← tid a) (← tid b) (← skind k) (← order m) τ)
  | "drv_wrong_way", [x], [tol] => do pure (drv_wrong_way c i (← tid x) tol)
  | "drv_straddles_marking", [x], [] => do pure (drv_straddles_marking c i (← tid x))
  | "drv_responding_emergency", [x], [] => do pure (drv_responding_emergency c i (← tid x))
  | "drv_vulnerable_road_user", [x], [] => do pure (drv_vulnerable_road_user c i (← tid x))
  | "drv_laned_roadway", [x], [] => do pure (drv_laned_roadway c i (← tid x))
  | "drv_extreme_lane", [x, sd], [] => do pure (drv_extreme_lane c i (← tid x) (← side sd))
  | "drv_priority_roadway", [x], [] => do pure (drv_priority_roadway c i (← tid x))
  | "drv_within_signed_zone", [x, k], [] => do pure (drv_within_signed_zone c i (← tid x) (← zkind k))
  | "drv_condition_in_effect", [d, x], [] => do pure (drv_condition_in_effect c i (← tid d) (← tid x))
  | "drv_civil_night", [], [sunset, sunrise, aft, bef] => .ok (drv_civil_night c i sunset sunrise aft bef)
  | "drv_queue_behind", [x, n], [g] => do pure (drv_queue_behind c i (← tid x) (← natArg n) g)
  | "drv_slower_than_posted", [x], [m] => do pure (drv_slower_than_posted c i (← tid x) m)
  | "drv_speed_below_traffic", [x], [r, m, cosTol] => do pure (drv_speed_below_traffic c i (← tid x) r m cosTol)
  | "drv_sight_distance_adequate", [x], [a, tr] => do pure (drv_sight_distance_adequate c i (← tid x) a tr)
  | "drv_hard_deceleration", [x], [b] => do pure (drv_hard_deceleration c i (← tid x) b)
  | "drv_forced_halt", [x], [g, ε] => do pure (drv_forced_halt c i (← tid x) g ε)
  | "drv_officer_directed", [x], [] => do pure (drv_officer_directed c i (← tid x))
  | n, _, _ => .error (if derivedNames.contains n then .malformed s!"arity {n}" else .malformed s!"derived concept {n}")

/-- Quantity-valued derived concepts. -/
def evalQ (name : String) (c : Ctx) (i : Nat) (args : List DArg) (ps : List Q) : QR :=
  match name, args, ps with
  | "drv_time_gap", [a, b], [] => do drv_time_gap c i (← tid a) (← tid b)
  | "drv_time_to_conflict", [a, b], [h] => do drv_time_to_conflict c i (← tid a) (← tid b) h
  | "drv_signal_cycles", [x], [ε] => do drv_signal_cycles c i (← tid x) ε
  | "drv_stopping_distance", [x], [a, tr] => do drv_stopping_distance c i (← tid x) a tr
  | n, _, _ => .error (if derivedNames.contains n then .malformed s!"arity {n}" else .malformed s!"derived quantity {n}")

end Derived
end TrafficSpec
