/-
  TrafficSpec.Core.Derived
  The derived concepts of ATOMS.md §9, defined once, with their parameters exposed.

  A derived concept is the vocabulary of manoeuvres and of operationalized standards: stopped,
  turning, overtaking, yields-to, time-to-conflict, forced halt. Each is one definition here,
  named `drv_name`, computed over the whole trace from atoms only: it takes the trace context and
  its entity and parameter arguments and returns one three-valued result per instant. Concepts
  that need history are one pass over the trace (Temporal); the others are one scene function
  mapped over the instants.

  Parameters are arguments. No default lives here: a default would be a threshold frozen before
  any law is seen.
-/
import TrafficSpec.Core.Atoms
import TrafficSpec.Core.Params
import TrafficSpec.Core.Temporal

namespace TrafficSpec
namespace Derived
open Temporal

/-- The trace indexed for evaluation, with the run's reading. -/
structure Ctx where
  scenes : Array Scene
  times : Array Q
  ρ : Reading

def Ctx.mk' (τ : Trace) (ρ : Reading) : Ctx :=
  ⟨τ.toArray, (τ.map fun s => Time.ofTimestamp s.t).toArray, ρ⟩
def Ctx.n (c : Ctx) : Nat := c.scenes.size

/-- An argument as the dispatcher receives it: a resolved entity id (tracks, regions and devices
    are all `Nat`), an enumeration spelling, or a natural. -/
inductive DArg
  | v (id : Nat)
  | s (lit : String)
  | n (nat : Nat)
  deriving Repr, DecidableEq

-- ---------------------------------------------------------------------------------------------
-- Lifting scene functions over the trace; positions for windows
-- ---------------------------------------------------------------------------------------------
def each (c : Ctx) (f : Scene → R) : Array R := c.scenes.map f
def eachQ (c : Ctx) (f : Scene → QR) : Array QR := c.scenes.map f
/-- A scene function of the previous and the current observation; `first` at the trace start. -/
def eachPrev (c : Ctx) (first : R) (f : Scene → Scene → R) : Array R :=
  (Array.range c.n).map fun i => if i = 0 then first else f c.scenes[i - 1]! c.scenes[i]!

def timePos (c : Ctx) : Array (Option Q) := c.times.map some
def pathPos (c : Ctx) (x : TrackId) : Array (Option Q) := c.scenes.map (kin_path_length · x)
def positions (c : Ctx) (m : Measure) (x : TrackId) : Array (Option Q) :=
  match m with | .time => timePos c | .path => pathPos c x
def missingPos (m : Measure) : UnknownReason :=
  match m with | .time => .outOfRange | .path => .absentAtom "kin_path_length"

def bAtom (o : Option Bool) (name : String) : R := R.ofOption o (.absentAtom name)
def qAtom (o : Option Q) (name : String) : QR :=
  match o with | some q => .ok q | none => .error (.absentAtom name)
def constQ (c : Ctx) (e : Except UnknownReason (Array R)) : Array R :=
  match e with | .ok a => a | .error w => const c.n (R.u w)

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
/-- The nearest region of a kind to `x` (boundary distance), with that distance and its centroid. -/
def nearestRegion (s : Scene) (x : TrackId) (k : StructureKind) : Option (RegionId × Q × Vec) := do
  let _ ← kin_position s x
  let cands := (regionsOfKind s k).filterMap fun r => do
    let d ← st_region_geometry_distance s x r
    let c ← (st_region_geometry_boundary s r).bind centroid <|> st_region_geometry_position s r
    pure (r, d, c)
  cands.foldl (fun acc c => match acc with
    | none => some c
    | some a => if Q.lt c.2.1 a.2.1 then some c else some a) none
/-- Two lane sets are adjacent when some lane of one is a neighbour of some lane of the other. -/
def adjacentSets (s : Scene) (as bs : List RegionId) : Bool :=
  as.any fun a => bs.any fun b =>
    st_lane_adjacency_left s a == some b || st_lane_adjacency_right s a == some b ||
    st_lane_adjacency_left s b == some a || st_lane_adjacency_right s b == some a

/-- Heading change (degrees, left positive) integrated over the back window of length w:
    prefix sums of yaw rate × interval, one window query per instant. -/
def yawChange (c : Ctx) (x : TrackId) (w : Q) : Array (Except UnknownReason Q) :=
  let n := c.n
  -- sums[i] = Σ_{k ≤ i} ω_k (t_k − t_{k−1}); a missing yaw rate contributes nothing and is tracked
  let sums := (List.range n).foldl (fun (acc : Array Q) i =>
    let prev := if i = 0 then Q.zero else acc[i - 1]!
    let dt := if i = 0 then Q.zero else Q.sub c.times[i]! c.times[i - 1]!
    acc.push (match kin_yaw_rate c.scenes[i]! x with
      | some ω => Q.add prev (Q.mul ω dt)
      | none => prev)) #[]
  -- lastMissing[i] = latest index ≤ i with a missing yaw rate (n when none)
  let lastMissing := (List.range n).foldl (fun (acc : Array Nat) i =>
    acc.push (if (kin_yaw_rate c.scenes[i]! x).isNone then i else (if i = 0 then n else acc[i - 1]!))) #[]
  let wins := Time.backWindows (timePos c) w
  (Array.range n).map fun i =>
    match wins[i]! with
    | none => .error .outOfRange
    | some win =>
      if !win.covered then .error (.windowTruncated "drv_turning")
      else if !win.adequate then .error (.samplingGap "drv_turning")
      else
        let lm := lastMissing[i]!
        if lm ≠ n && lm > win.j0 then .error (.absentAtom "kin_yaw_rate")
        else .ok (Q.sub sums[i]! sums[win.j0]!)

-- ---------------------------------------------------------------------------------------------
-- The concepts. Signature: context, entity arguments, parameters; one result per instant.
-- ---------------------------------------------------------------------------------------------

def speedAtMost (s : Scene) (x : TrackId) (ε : Q) : R := bAtom ((kin_speed s x).map (Q.le · ε)) "kin_speed"

/-- speed ≤ ε for a span ≥ d. -/
def drv_stopped (c : Ctx) (x : TrackId) (ε d : Q) : Array R :=
  holdsForAll (timePos c) d "drv_stopped" .outOfRange (each c fun s => speedAtMost s x ε)

/-- A road user ahead of `x` in a shared lane within longitudinal gap `g`. -/
def vehicleAheadWithin (s : Scene) (x : TrackId) (g : Q) : R :=
  R.any ((others s x).map fun y =>
    R.and (bAtom (rel_ahead_in_lane s y x) "rel_ahead_behind_in_lane")
          (bAtom ((rel_surface_gap_longitudinal s x y).map (Q.le · g)) "rel_surface_gap"))

/-- stopped for ≥ d and not in a queue: no vehicle ahead within g. -/
def drv_standing_or_parked (c : Ctx) (x : TrackId) (ε d g : Q) : Array R :=
  zipAnd (drv_stopped c x ε d) (each c fun s => R.not (vehicleAheadWithin s x g))

/-- stopped at the previous observation, moving now. -/
def drv_moving_off (c : Ctx) (x : TrackId) (ε : Q) : Array R :=
  eachPrev c (truncated "drv_moving_off") fun sp s =>
    R.and (bAtom ((kin_speed s x).map (Q.gt · ε)) "kin_speed") (speedAtMost sp x ε)

/-- heading change ≥ θ (degrees) over the window w, to the left when `left`, else to the right. -/
def drv_turning (c : Ctx) (x : TrackId) (left : Bool) (θ w : Q) : Array R :=
  (yawChange c x w).map fun e => match e with
    | .error w => R.u w
    | .ok Δ => R.ofBool (if left then Q.ge Δ θ else Q.le Δ (Q.neg θ))

/-- heading reversal within w: |Δ| within tol of a half turn. -/
def drv_u_turn (c : Ctx) (x : TrackId) (w tol : Q) : Array R :=
  (yawChange c x w).map fun e => match e with
    | .error w => R.u w
    | .ok Δ =>
      let a := Q.abs Δ
      R.ofBool (Q.ge a (Q.sub (Units.degrees 180) tol) && Q.le a (Q.add (Units.degrees 180) tol))

/-- the start of a lane change: a lane adjacent to the lanes occupied at the previous
    observation is entered (true at that one observation, whether or not the body still
    straddles afterwards). -/
def drv_lane_change (c : Ctx) (x : TrackId) : Array R :=
  eachPrev c (truncated "drv_lane_change") fun sp s =>
    R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun now =>
    R.bindOpt (lanesOf sp x) (.absentAtom "rel_occupies") fun before =>
      let entered := now.filter (!before.contains ·)
      R.ofBool (!entered.isEmpty && adjacentSets s entered before)

/-- the neighbouring lane on `side` exists and has no other user within longitudinal gap g;
    undefined while the body occupies several lanes. -/
def drv_lane_change_feasible (c : Ctx) (x : TrackId) (left : Bool) (g : Q) : Array R :=
  each c fun s =>
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
      | _ => R.u (.undefined "drv_lane_change_feasible")

/-- `b` travels the same way (heading cosine ≥ cosTol), was ahead of `a` at some earlier
    observation and is behind now. -/
def drv_overtaking (c : Ctx) (a b : TrackId) (cosTol : Q) : Array R :=
  let same := each c fun s => bAtom (rel_same_direction s a b cosTol) "rel_same_direction"
  zipAnd (zipAnd same (each c fun s => bAtom (rel_bearing_behind s a b) "rel_bearing"))
         (onceAll (zipAnd same (each c fun s => bAtom (rel_bearing_ahead s a b) "rel_bearing")))

/-- the overtaken `b` was on `a`'s left (`left`) or right while the bodies overlapped, travelling
    the same way (heading cosine ≥ cosTol). -/
def drv_passing_side (c : Ctx) (a b : TrackId) (left : Bool) (cosTol : Q) : Array R :=
  onceAll (each c fun s =>
    R.and (bAtom (rel_same_direction s a b cosTol) "rel_same_direction")
      (R.and (bAtom ((rel_longitudinal_overlap s a b).map (Q.ge · Q.zero)) "rel_longitudinal_overlap")
             (bAtom (if left then rel_bearing_left s a b else rel_bearing_right s a b) "rel_bearing")))

def drv_in_intersection (c : Ctx) (x : TrackId) (k : StructureKind) : Array R :=
  each c fun s => bAtom (occupiesKind s x k) "rel_occupies"

def drv_entering_intersection (c : Ctx) (x : TrackId) (k : StructureKind) : Array R :=
  eachPrev c (truncated "drv_entering_intersection") fun sp s =>
    R.and (bAtom (occupiesKind s x k) "rel_occupies") (R.not (bAtom (occupiesKind sp x k) "rel_occupies"))

/-- outside the region, within d of its boundary, and moving toward it. -/
def drv_approaching (c : Ctx) (x : TrackId) (k : StructureKind) (d : Q) : Array R :=
  each c fun s =>
    R.and (R.not (bAtom (occupiesKind s x k) "rel_occupies"))
      (R.bindOpt (nearestRegion s x k) (.absentAtom "st_region_geometry") fun (_, dist, cen) =>
       R.bindOpt (kin_position s x) (.absentAtom "kin_position") fun p =>
       R.bindOpt (kin_velocity s x) (.absentAtom "kin_velocity") fun v =>
         R.ofBool (Q.le dist d && Q.gt (Geom.dot v (Geom.vsub cen p)) Q.zero))

def drv_crossing_line (c : Ctx) (x : TrackId) (k : StructureKind) : Array R :=
  drv_entering_intersection c x k

/-- the region is behind and the trailing end is at least d past its boundary. -/
def drv_cleared_line (c : Ctx) (x : TrackId) (k : StructureKind) (d : Q) : Array R :=
  each c fun s =>
    R.bindOpt (nearestRegion s x k) (.absentAtom "st_region_geometry") fun (_, dist, cen) =>
    R.bindOpt (kin_position s x) (.absentAtom "kin_position") fun p =>
    R.bindOpt (kin_heading s x) (.absentAtom "kin_heading") fun h =>
    R.bindOpt (kin_extent s x) (.absentAtom "kin_extent") fun (hl, _, _) =>
      R.ofBool (Q.lt (Geom.dot h (Geom.vsub cen p)) Q.zero && Q.ge (Q.sub dist hl) d)

def drv_backing (c : Ctx) (x : TrackId) : Array R :=
  each c fun s =>
    R.bindOpt (kin_velocity s x) (.absentAtom "kin_velocity") fun v =>
    R.bindOpt (kin_heading s x) (.absentAtom "kin_heading") fun h =>
      R.ofBool (Q.lt (Geom.dot v h) Q.zero)

/-- same lane, `b` ahead of `a`, longitudinal gap ≤ g. -/
def drv_following (c : Ctx) (a b : TrackId) (g : Q) : Array R :=
  each c fun s =>
    R.and (bAtom (rel_ahead_in_lane s b a) "rel_ahead_behind_in_lane")
          (bAtom ((rel_surface_gap_longitudinal s a b).map (Q.le · g)) "rel_surface_gap")

/-- longitudinal gap ÷ the follower's speed. -/
def drv_time_gap (c : Ctx) (a b : TrackId) : Array QR :=
  eachQ c fun s => do
    let gap ← qAtom (rel_surface_gap_longitudinal s a b) "rel_surface_gap"
    let v ← qAtom (kin_speed s a) "kin_speed"
    if Q.isZero v then .error (.divisionByZero "drv_time_gap") else .ok (Q.div gap v)

private def vecAtom (o : Option Vec) (name : String) : Except UnknownReason Vec :=
  match o with | some v => .ok v | none => .error (.absentAtom name)

/-- time to closest approach within the sum of half-lengths under constant velocity; `horizon`
    when the paths do not meet within the horizon. -/
def drv_time_to_conflict (c : Ctx) (a b : TrackId) (horizon : Q) : Array QR :=
  eachQ c fun s => do
    let pa ← vecAtom (kin_position s a) "kin_position"
    let pb ← vecAtom (kin_position s b) "kin_position"
    let va ← vecAtom (kin_velocity s a) "kin_velocity"
    let vb ← vecAtom (kin_velocity s b) "kin_velocity"
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

/-- oncoming and the paths meet within t. -/
def drv_meeting (c : Ctx) (a b : TrackId) (t cosTol : Q) : Array R :=
  Array.zipWith (fun onc ttc =>
    R.and onc (match ttc with | .error e => R.u e | .ok v => R.ofBool (Q.lt v t)))
    (each c fun s => bAtom (rel_oncoming s a b cosTol) "rel_oncoming")
    (drv_time_to_conflict c a b t)

/-- `b` is behind `a` now, was ahead earlier, and `a` slowed to ≤ ε at or after that. -/
def drv_yields_to (c : Ctx) (a b : TrackId) (ε : Q) : Array R :=
  let ahead := onceAll (each c fun s => bAtom (rel_bearing_ahead s a b) "rel_bearing")
  let slowedSince := onceAll (zipAnd ahead (each c fun s => speedAtMost s a ε))
  zipAnd (each c fun s => bAtom (rel_bearing_behind s a b) "rel_bearing") slowedSince

/-- `before`: `a` reached the region more than τ before `b` (`b` may not have arrived yet).
    `same`: both reached it within τ of each other. An arrival already in progress at the first
    observation is only an upper bound on the onset: the comparison is decided when the bound
    decides it and unknown otherwise. -/
def drv_arrival_order (c : Ctx) (a b : TrackId) (k : StructureKind) (same : Bool) (τ : Q) : Array R :=
  let fa := firstTrueAll (each c fun s => bAtom (occupiesKind s a k) "rel_occupies")
  let fb := firstTrueAll (each c fun s => bAtom (occupiesKind s b k) "rel_occupies")
  let trunc := truncated "drv_arrival_order"
  (Array.range c.n).map fun i =>
    match fa[i]!, fb[i]! with
    | .error e, _ | _, .error e => R.u e
    | .ok (some ja), .ok (some jb) =>
      let ta := c.times[ja]!; let tb := c.times[jb]!
      match ja == 0, jb == 0 with
      | false, false => if same then R.ofBool (Q.le (Q.abs (Q.sub ta tb)) τ) else R.ofBool (Q.lt ta (Q.sub tb τ))
      | true, false =>              -- a arrived at or before ta
        if same then (if Q.gt (Q.sub tb ta) τ then R.f else trunc)
        else (if Q.lt ta (Q.sub tb τ) then R.t else trunc)
      | false, true =>              -- b arrived at or before tb
        if same then (if Q.gt (Q.sub ta tb) τ then R.f else trunc)
        else (if Q.ge ta tb then R.f else trunc)
      | true, true => trunc
    | .ok (some _), .ok none => if same then trunc else R.t
    | .ok none, _ => trunc

/-- heading opposed to the occupied lane's direction (cosine ≤ −tol). -/
def drv_wrong_way (c : Ctx) (x : TrackId) (tol : Q) : Array R :=
  each c fun s =>
    R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun ls =>
    R.bindOpt (kin_heading s x) (.absentAtom "kin_heading") fun h =>
      R.any (ls.map fun l =>
        R.bindOpt (st_lane_direction s l) (.absentAtom "st_lane_direction") fun d =>
          let n := Q.mul (Geom.norm h) (Geom.norm d)
          if Q.isZero n then R.u (.undefined "drv_wrong_way") else
          R.ofBool (Q.le (Geom.dot h d) (Q.neg (Q.mul tol n))))

def drv_straddles_marking (c : Ctx) (x : TrackId) : Array R :=
  each c fun s => R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun ls => R.ofBool (ls.length ≥ 2)

/-- emergency class with red or blue warning lamps or a siren; an unobserved lamp or siren is unknown. -/
def drv_responding_emergency (c : Ctx) (x : TrackId) : Array R :=
  each c fun s =>
    R.and (bAtom (ru_emergency_vehicle s x) "ru_emergency_vehicle")
      (R.or (R.or (bAtom (sig_warning_lamp_colour s x .red) "sig_warning_lamp")
                  (bAtom (sig_warning_lamp_colour s x .blue) "sig_warning_lamp"))
            (bAtom (sig_siren s x) "sig_siren"))

private def hasClassOpt (s : Scene) (x : TrackId) (k : RoadUserClass) : Option Bool :=
  (s.user x).bind fun u => if u.unobservedClasses.contains k then none else u.classes.map (·.contains k)

/-- pedestrian or rider of a bicycle, electric bicycle or electric scooter, or a class the reading adds. -/
def drv_vulnerable_road_user (c : Ctx) (x : TrackId) : Array R :=
  let extraClasses : List RoadUserClass := match c.ρ.aggregate "vulnerable" with
    | some cls => cls.filterMap fun id => RoadUserClass.ofString ((id.drop 3).toString)
    | none => []
  each c fun s =>
    let base := [ru_pedestrian s x, ru_bicycle s x, ru_electric_bicycle s x, ru_electric_scooter s x]
    R.any ((base ++ extraClasses.map (hasClassOpt s x)).map fun o => bAtom o "ru_class")

def drv_laned_roadway (c : Ctx) (x : TrackId) : Array R :=
  each c fun s =>
    R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun ls =>
      R.any (ls.map fun l => bAtom ((st_lane_adjacency_count s l).map (· ≥ 2)) "st_lane_adjacency")

def drv_extreme_lane (c : Ctx) (x : TrackId) (left : Bool) : Array R :=
  each c fun s =>
    R.bindOpt (lanesOf s x) (.absentAtom "rel_occupies") fun ls =>
      R.any (ls.map fun l =>
        R.bindOpt (st_lane_adjacency_ordinal s l) (.absentAtom "st_lane_adjacency") fun o =>
        R.bindOpt (st_lane_adjacency_count s l) (.absentAtom "st_lane_adjacency") fun n =>
          R.ofBool (if left then o == 0 else o + 1 == n))

/-- the lane `x` occupies leads to a junction region whose other entering lanes carry a stop or
    yield sign, and its own lane carries none. -/
def drv_priority_roadway (c : Ctx) (x : TrackId) : Array R :=
  each c fun s =>
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
      | _ => R.u (.undefined "drv_priority_roadway")

/-- path length over which `holds` has held continuously up to each instant. -/
def drv_distance_while (c : Ctx) (x : TrackId) (holds : Array R) : Array QR :=
  distanceWhileAll (pathPos c x) holds

/-- between a begin sign of kind k governing a lane `x` occupies and its end sign: the latest
    such sign seen decides; before any sign the zone is unknown. -/
def drv_within_signed_zone (c : Ctx) (x : TrackId) (k : ZoneKind) : Array R :=
  let n := c.n
  ((List.range n).foldl (fun (acc : Array R × R) i =>
    let s := c.scenes[i]!
    let r : R := match lanesOf s x with
      | none => R.u (.absentAtom "rel_occupies")
      | some ls =>
        let signs := (devicesOfKind s .zoneSign).filter fun d =>
          dev_zone_sign_kind s d == some k && ls.any fun l => dev_governs s d l == some true
        if signs.any (fun d => dev_zone_sign_end s d == some false) then R.t
        else if signs.any (fun d => dev_zone_sign_end s d == some true) then R.f
        else acc.2
    (acc.1.push r, r)) (Array.mkEmpty n, truncated "drv_within_signed_zone")).1

/-- minute m of the day lies in the window [start, end), wrapping past midnight when end ≤ start. -/
def inWindow (w : TimeWindow) (m : Nat) : Bool :=
  if w.startMinute < w.endMinute then w.startMinute ≤ m && m < w.endMinute
  else m ≥ w.startMinute || m < w.endMinute

/-- a device's conditions hold now for the subject `x`. -/
def drv_condition_in_effect (c : Ctx) (d : DeviceId) (x : TrackId) : Array R :=
  each c fun s =>
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
            R.and dayOk (R.ofBool (inWindow w ct.minuteOfDay)))
      let occOk : R := match cd.minOccupancy with
        | none => R.t
        | some n => bAtom ((ru_occupant_count s x).map (· ≥ n)) "ru_occupant_count"
      let clsOk : R := match cd.vehicleClass with
        | none => R.t
        | some k => bAtom (hasClassOpt s x k) "ru_class"
      let childOk : R :=
        if cd.whenChildrenPresent then R.any (s.tracks.map fun y => bAtom (ru_child s y) "ru_child") else R.t
      R.and (R.and timeOk occOk) (R.and clsOk childOk)

/-- civil time later than sunset plus `afterSunset` or earlier than sunrise minus `beforeSunrise`
    (all in minutes of the day, supplied by the reading for the date and place). -/
def drv_civil_night (c : Ctx) (sunset sunrise afterSunset beforeSunrise : Q) : Array R :=
  each c fun s =>
    R.bindOpt (env_civil_time s) (.absentAtom "env_civil_time") fun ct =>
      let m := Q.ofInt (Int.ofNat ct.minuteOfDay)
      R.ofBool (Q.ge m (Q.add sunset afterSunset) || Q.le m (Q.sub sunrise beforeSunrise))

/-- at least n vehicles in line behind `x`, each within gap g of the one ahead. -/
def drv_queue_behind (c : Ctx) (x : TrackId) (n : Nat) (g : Q) : Array R :=
  each c fun s =>
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

/-- The indications that permit a movement: straight ahead, or a turn to a side. -/
def permitting (mov : Option TurnSide) : List SignalIndication :=
  match mov with
  | none => [.circularGreen]
  | some .left => [.circularGreen, .greenArrow .left, .flashingYellowArrow .left]
  | some .right => [.circularGreen, .greenArrow .right, .flashingYellowArrow .right]

/-- complete cycles of the signals governing `x`'s lane since `x` stopped (speed ≤ ε): the
    number of transitions into an indication permitting the movement `mov`. -/
def drv_signal_cycles (c : Ctx) (x : TrackId) (mov : Option TurnSide) (ε : Q) : Array QR :=
  let halted := each c fun s => speedAtMost s x ε
  let go := each c fun s =>
    match governing s x .trafficSignal with
    | some [] => R.u (.absentAtom "dev_traffic_signal")
    | some ds => R.any (ds.map fun d =>
        R.any ((permitting mov).map fun ind => bAtom (dev_traffic_signal_shows s d ind) "dev_traffic_signal"))
    | none => R.u (.absentAtom "rel_occupies")
  (countEdgesAll "drv_signal_cycles" go halted).map fun e => e.map fun k => Q.ofInt (Int.ofNat k)

/-- the governing maximum-speed sign's value, the lowest when several govern. -/
def postedLimit (s : Scene) (x : TrackId) : Option Q :=
  (governing s x .speedLimitSign).bind fun ds =>
    let vals := ds.filterMap fun d =>
      if dev_speed_limit_sign_kind s d == some .maximum then dev_speed_limit_sign_value s d else none
    vals.foldl (fun acc v => match acc with | none => some v | some a => some (Q.min a v)) none

def drv_slower_than_posted (c : Ctx) (x : TrackId) (margin : Q) : Array R :=
  each c fun s =>
    R.bindOpt (postedLimit s x) (.absentAtom "dev_speed_limit_sign") fun lim =>
    R.bindOpt (kin_speed s x) (.absentAtom "kin_speed") fun v =>
      R.ofBool (Q.le v (Q.sub lim margin))

/-- speed below the median of same-direction users within range r by at least `margin`. -/
def drv_speed_below_traffic (c : Ctx) (x : TrackId) (r margin cosTol : Q) : Array R :=
  each c fun s =>
    R.bindOpt (kin_speed s x) (.absentAtom "kin_speed") fun v =>
      let speeds := (others s x).filterMap fun y =>
        if (rel_centre_distance s x y).map (Q.le · r) == some true &&
           rel_same_direction s x y cosTol == some true then kin_speed s y else none
      if speeds.isEmpty then R.u (.undefined "drv_speed_below_traffic")
      else
        let sorted := speeds.toArray.qsort (fun a b => Q.lt a b) |>.toList
        let med := sorted[sorted.length / 2]!
        R.ofBool (Q.le v (Q.sub med margin))

/-- v·t_r + v²/(2a). -/
def drv_stopping_distance (c : Ctx) (x : TrackId) (a reaction : Q) : Array QR :=
  eachQ c fun s => do
    let v ← qAtom (kin_speed s x) "kin_speed"
    if Q.isZero a || !Q.isNonneg a then .error (.divisionByZero "drv_stopping_distance")
    else .ok (Q.add (Q.mul v reaction) (Q.div (Q.mul v v) (Q.mul (Q.ofInt 2) a)))

/-- the sight distance recorded for a region `x` occupies is at least its stopping distance. -/
def drv_sight_distance_adequate (c : Ctx) (x : TrackId) (a reaction : Q) : Array R :=
  Array.zipWith (fun (sd : QR) (s : Scene) =>
    match sd with
    | .error e => R.u e
    | .ok sd =>
      R.bindOpt (rel_occupies_regions s x) (.absentAtom "rel_occupies") fun rs =>
        match rs.filterMap fun r => st_sight_distance s r with
        | [] => R.u (.absentAtom "st_sight_distance")
        | v :: rest => R.ofBool (Q.ge (rest.foldl Q.min v) sd))
    (drv_stopping_distance c x a reaction) c.scenes

def drv_hard_deceleration (c : Ctx) (x : TrackId) (bound : Q) : Array R :=
  each c fun s => bAtom ((kin_accel_longitudinal s x).map fun acc => Q.le acc (Q.neg bound)) "kin_accel_longitudinal"

/-- halted (speed ≤ ε) with a halted vehicle ahead within g, a governing red signal, a governing
    stop sign whose stop line or post is within g, or a governing officer signalling a halt. -/
def drv_forced_halt (c : Ctx) (x : TrackId) (g ε : Q) : Array R :=
  each c fun s =>
    let halted := speedAtMost s x ε
    let aheadHalted := R.any ((others s x).map fun y =>
      R.and (bAtom (rel_ahead_in_lane s y x) "rel_ahead_behind_in_lane")
        (R.and (bAtom ((rel_surface_gap_longitudinal s x y).map (Q.le · g)) "rel_surface_gap")
               (speedAtMost s y ε)))
    let redSignal := match governing s x .trafficSignal with
      | none => R.u (.absentAtom "rel_occupies")
      | some ds => R.any (ds.map fun d =>
          R.or (bAtom (dev_traffic_signal_shows s d .circularRed) "dev_traffic_signal")
               (bAtom (dev_traffic_signal_shows s d .flashingRed) "dev_traffic_signal"))
    let stopSign := match governing s x .stopSign with
      | none => R.u (.absentAtom "rel_occupies")
      | some [] => R.f
      | some ds =>
        let nearLine := R.any ((regionsOfKind s .stopLine).map fun r =>
          bAtom ((st_region_geometry_distance s x r).map (Q.le · g)) "st_region_geometry")
        let nearSign := R.any (ds.map fun d =>
          R.bindOpt (kin_position s x) (.absentAtom "kin_position") fun p =>
          R.bindOpt (dev_position s d) (.absentAtom "dev_position") fun q =>
            R.ofBool (Q.le (Geom.norm (Geom.vsub q p)) g))
        R.or nearLine nearSign
    let officer := match governing s x .humanDirection with
      | none => R.u (.absentAtom "rel_occupies")
      | some ds => R.any (ds.map fun d => bAtom ((dev_human_direction_indication s d).map (· == .stop)) "dev_human_direction")
    R.and halted (R.or (R.or aheadHalted redSignal) (R.or stopSign officer))

/-- a police officer governs a lane `x` occupies and gives an indication. -/
def drv_officer_directed (c : Ctx) (x : TrackId) : Array R :=
  each c fun s =>
    match governing s x .humanDirection with
    | none => R.u (.absentAtom "rel_occupies")
    | some ds => R.any (ds.map fun d =>
        R.and (bAtom ((dev_human_direction_role s d).map (· == .policeOfficer)) "dev_human_direction")
              (bAtom ((dev_human_direction_indication s d).map fun _ => true) "dev_human_direction"))

-- ---------------------------------------------------------------------------------------------
-- Tables and dispatch by name
-- ---------------------------------------------------------------------------------------------
/-- Every `drv_*` definition of this file. The doctor holds this against `derivedIds`. -/
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
    derived concepts into the atoms a source must observe; the perception stage reads it the other way. -/
def reads (n : String) : List String :=
  match n with
  | "drv_stopped" => ["kin_speed"]
  | "drv_standing_or_parked" => ["kin_speed", "rel_ahead_behind_in_lane", "rel_surface_gap"]
  | "drv_moving_off" => ["kin_speed"]
  | "drv_turning" => ["kin_yaw_rate"]
  | "drv_u_turn" => ["kin_yaw_rate"]
  | "drv_lane_change" => ["rel_occupies", "st_lane", "st_lane_adjacency"]
  | "drv_lane_change_feasible" => ["rel_occupies", "st_lane", "st_lane_adjacency", "rel_surface_gap"]
  | "drv_overtaking" => ["rel_bearing", "rel_same_direction"]
  | "drv_passing_side" => ["rel_longitudinal_overlap", "rel_bearing", "rel_same_direction"]
  | "drv_entering_intersection" => ["rel_occupies"]
  | "drv_in_intersection" => ["rel_occupies"]
  | "drv_approaching" => ["rel_occupies", "st_region_geometry", "kin_position", "kin_velocity"]
  | "drv_crossing_line" => ["rel_occupies"]
  | "drv_cleared_line" => ["st_region_geometry", "kin_position", "kin_heading", "kin_extent"]
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
  | "drv_forced_halt" => ["kin_speed", "rel_ahead_behind_in_lane", "rel_surface_gap", "rel_occupies", "st_lane", "dev_traffic_signal", "dev_stop_sign", "st_stop_line", "st_region_geometry", "dev_position", "dev_human_direction", "dev_governs"]
  | "drv_officer_directed" => ["rel_occupies", "st_lane", "dev_human_direction", "dev_governs"]
  | _ => []

/-- The sort each entity argument of a concept must have (`none` marks a literal or natural
    position). The static check holds variables to these; the doctor holds the table to `evalB`. -/
def argSorts (name : String) : Option (List (Option EntityKind)) :=
  let t := some EntityKind.track
  match name with
  | "drv_stopped" | "drv_standing_or_parked" | "drv_moving_off" | "drv_u_turn" | "drv_lane_change"
  | "drv_backing" | "drv_wrong_way" | "drv_straddles_marking" | "drv_responding_emergency"
  | "drv_vulnerable_road_user" | "drv_laned_roadway" | "drv_priority_roadway" | "drv_slower_than_posted"
  | "drv_speed_below_traffic" | "drv_sight_distance_adequate" | "drv_stopping_distance"
  | "drv_hard_deceleration" | "drv_forced_halt" | "drv_officer_directed" => some [t]
  | "drv_turning" | "drv_lane_change_feasible" | "drv_extreme_lane" | "drv_entering_intersection"
  | "drv_in_intersection" | "drv_approaching" | "drv_crossing_line" | "drv_cleared_line"
  | "drv_within_signed_zone" | "drv_signal_cycles" | "drv_queue_behind" => some [t, none]
  | "drv_overtaking" | "drv_following" | "drv_time_gap" | "drv_time_to_conflict" | "drv_meeting"
  | "drv_yields_to" => some [t, t]
  | "drv_passing_side" => some [t, t, none]
  | "drv_arrival_order" => some [t, t, none, none]
  | "drv_condition_in_effect" => some [some EntityKind.device, t]
  | "drv_civil_night" => some []
  | _ => none

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
private def movement (a : DArg) : Except UnknownReason (Option TurnSide) :=
  match a with
  | .s "straight" => .ok none
  | .s "left" => .ok (some .left)
  | .s "right" => .ok (some .right)
  | _ => .error (.malformed "movement")
private def tid (a : DArg) : Except UnknownReason TrackId :=
  match a with | .v t => .ok t | .n n => .ok n | _ => .error (.malformed "entity")
private def natArg (a : DArg) : Except UnknownReason Nat :=
  match a with | .n n => .ok n | .v t => .ok t | _ => .error (.malformed "natural")

private def unknownName (n : String) : UnknownReason :=
  if derivedNames.contains n then .malformed s!"arity {n}" else .malformed s!"derived concept {n}"

/-- Boolean derived concepts by name. Unlisted names, wrong arities or wrong literals are `malformed`. -/
def evalB (name : String) (c : Ctx) (args : List DArg) (ps : List Q) : Except UnknownReason (Array R) :=
  match name, args, ps with
  | "drv_stopped", [x], [ε, d] => do pure (drv_stopped c (← tid x) ε d)
  | "drv_standing_or_parked", [x], [ε, d, g] => do pure (drv_standing_or_parked c (← tid x) ε d g)
  | "drv_moving_off", [x], [ε] => do pure (drv_moving_off c (← tid x) ε)
  | "drv_turning", [x, sd], [θ, w] => do pure (drv_turning c (← tid x) (← side sd) θ w)
  | "drv_u_turn", [x], [w, tol] => do pure (drv_u_turn c (← tid x) w tol)
  | "drv_lane_change", [x], [] => do pure (drv_lane_change c (← tid x))
  | "drv_lane_change_feasible", [x, sd], [g] => do pure (drv_lane_change_feasible c (← tid x) (← side sd) g)
  | "drv_overtaking", [a, b], [cosTol] => do pure (drv_overtaking c (← tid a) (← tid b) cosTol)
  | "drv_passing_side", [a, b, sd], [cosTol] => do pure (drv_passing_side c (← tid a) (← tid b) (← side sd) cosTol)
  | "drv_entering_intersection", [x, k], [] => do pure (drv_entering_intersection c (← tid x) (← skind k))
  | "drv_in_intersection", [x, k], [] => do pure (drv_in_intersection c (← tid x) (← skind k))
  | "drv_approaching", [x, k], [d] => do pure (drv_approaching c (← tid x) (← skind k) d)
  | "drv_crossing_line", [x, k], [] => do pure (drv_crossing_line c (← tid x) (← skind k))
  | "drv_cleared_line", [x, k], [d] => do pure (drv_cleared_line c (← tid x) (← skind k) d)
  | "drv_backing", [x], [] => do pure (drv_backing c (← tid x))
  | "drv_following", [a, b], [g] => do pure (drv_following c (← tid a) (← tid b) g)
  | "drv_meeting", [a, b], [t, cosTol] => do pure (drv_meeting c (← tid a) (← tid b) t cosTol)
  | "drv_yields_to", [a, b], [ε] => do pure (drv_yields_to c (← tid a) (← tid b) ε)
  | "drv_arrival_order", [a, b, k, m], [τ] => do pure (drv_arrival_order c (← tid a) (← tid b) (← skind k) (← order m) τ)
  | "drv_wrong_way", [x], [tol] => do pure (drv_wrong_way c (← tid x) tol)
  | "drv_straddles_marking", [x], [] => do pure (drv_straddles_marking c (← tid x))
  | "drv_responding_emergency", [x], [] => do pure (drv_responding_emergency c (← tid x))
  | "drv_vulnerable_road_user", [x], [] => do pure (drv_vulnerable_road_user c (← tid x))
  | "drv_laned_roadway", [x], [] => do pure (drv_laned_roadway c (← tid x))
  | "drv_extreme_lane", [x, sd], [] => do pure (drv_extreme_lane c (← tid x) (← side sd))
  | "drv_priority_roadway", [x], [] => do pure (drv_priority_roadway c (← tid x))
  | "drv_within_signed_zone", [x, k], [] => do pure (drv_within_signed_zone c (← tid x) (← zkind k))
  | "drv_condition_in_effect", [d, x], [] => do pure (drv_condition_in_effect c (← tid d) (← tid x))
  | "drv_civil_night", [], [sunset, sunrise, aft, bef] => .ok (drv_civil_night c sunset sunrise aft bef)
  | "drv_queue_behind", [x, n], [g] => do pure (drv_queue_behind c (← tid x) (← natArg n) g)
  | "drv_slower_than_posted", [x], [m] => do pure (drv_slower_than_posted c (← tid x) m)
  | "drv_speed_below_traffic", [x], [r, m, cosTol] => do pure (drv_speed_below_traffic c (← tid x) r m cosTol)
  | "drv_sight_distance_adequate", [x], [a, tr] => do pure (drv_sight_distance_adequate c (← tid x) a tr)
  | "drv_hard_deceleration", [x], [b] => do pure (drv_hard_deceleration c (← tid x) b)
  | "drv_forced_halt", [x], [g, ε] => do pure (drv_forced_halt c (← tid x) g ε)
  | "drv_officer_directed", [x], [] => do pure (drv_officer_directed c (← tid x))
  | n, _, _ => .error (unknownName n)

/-- Quantity-valued derived concepts by name. -/
def evalQ (name : String) (c : Ctx) (args : List DArg) (ps : List Q) : Except UnknownReason (Array QR) :=
  match name, args, ps with
  | "drv_time_gap", [a, b], [] => do pure (drv_time_gap c (← tid a) (← tid b))
  | "drv_time_to_conflict", [a, b], [h] => do pure (drv_time_to_conflict c (← tid a) (← tid b) h)
  | "drv_signal_cycles", [x, mov], [ε] => do pure (drv_signal_cycles c (← tid x) (← movement mov) ε)
  | "drv_stopping_distance", [x], [a, tr] => do pure (drv_stopping_distance c (← tid x) a tr)
  | n, _, _ => .error (unknownName n)

end Derived
end TrafficSpec
