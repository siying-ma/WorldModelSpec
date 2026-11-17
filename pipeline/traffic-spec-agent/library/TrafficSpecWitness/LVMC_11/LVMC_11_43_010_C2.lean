/-
  Witnesses for LVMC_11_43_010_C2.

  Geometry (the witness's own figures; none appears in the rule). Angles φ are measured clockwise
  from the +y axis about the point C = (0, 0); headings are rational approximations (a 15-term
  Taylor series with π ≈ 355/113, rounded to micrometres) of the exact unit vectors.
  - Roundabout r (region 10): the rectangle x −0.5 … 20 m, y 0.5 … 20 m (central island at C's
    corner, circulatory roadway, entry on its west side, exit on its south side).
  - Two circulating lanes about C, annular sectors from φ = −6° to 96°: lane 11, radii 10 … 14 m,
    ordinal 1 of 2 (the left lane, looking along the clockwise direction of travel); lane 12,
    radii 6 … 10 m, ordinal 2 of 2 (the right lane). The `blind` witness is `forbid`'s trace with
    st.lane_adjacency masked by its manifest.
  - The subject (track 1), a passenger car (motor_vehicle), half-extents 2 m × 1 m × 0.75 m.
    Scenes every 50 ms (the reading's step bound), k = 0 … 29 (t = 0 … 1450 ms):
      k < 5     approach heading east along y = R, short of r;
      5 ≤ k ≤ 25  a quarter circle of radius R about C (right turn) at 4.5° per scene, heading
                  rotated with it, yaw rate −90 deg/s at k = 6 … 25 (held over the interval before
                  each scene), 0 elsewhere;
      k > 25    heading south from (R, 0).
    Entry into r at k = 5 (250 ms), exit at k = 25 (1250 ms, y = 0 < 0.5): heading change −90°,
    a clear margin inside the right-turn band (−135°, −45°].
    `forbid`/`blind`: R = 12 m (lane 11, ordinal 1); `permit`: R = 8 m (lane 12, ordinal 2).
  - `idle`: R = 12 m, a left turn about (0, 24) with yaw rate +90 deg/s: the subject leaves r through
    its north side at k = 21 with a heading change of +72°, then heads north; no right turn.
  - `branch_1`: as `permit`, but the radius drifts 8 → 10 m at k = 11 … 14 and stays on the lane line
    (10 m) to the exit; at k = 12 … 24 the footprint overlaps both lanes (occupancy stated).
  The window (250 … 1450 ms) starts at the entry, so no look-back of the formulas reaches the start of
  the trace.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_C2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_C2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- A quantity rounded towards zero to whole micrometres (micro-units). -/
def roundMicro (q : Q) : Q := Units.micrometres ((q.num * 1000000) / (q.den : Int))

def piQ : Q := Units.ratio 355 113

/-- Degrees to radians. -/
def rad (d : Q) : Q := Q.div (Q.mul d piQ) (Q.ofInt 180)

def qpow (x : Q) : Nat → Q
  | 0 => Q.ofInt 1
  | n + 1 => Q.mul x (qpow x n)

def series (x : Q) (terms : List (Nat × Int × Nat)) : Q :=
  terms.foldl (fun acc (e, s, f) =>
    Q.add acc (Q.div (Q.mul (Q.ofInt s) (qpow x e)) (Q.ofInt (Int.ofNat f)))) Q.zero

def cosQ (x : Q) : Q :=
  roundMicro (series x [(0, 1, 1), (2, -1, 2), (4, 1, 24), (6, -1, 720), (8, 1, 40320),
    (10, -1, 3628800), (12, 1, 479001600), (14, -1, 87178291200)])

def sinQ (x : Q) : Q :=
  roundMicro (series x [(1, 1, 1), (3, -1, 6), (5, 1, 120), (7, -1, 5040), (9, 1, 362880),
    (11, -1, 39916800), (13, 1, 6227020800), (15, -1, 1307674368000)])

def rId : RegionId := 10
def laneLeft : RegionId := 11
def laneRight : RegionId := 12

def roundabout : Structure := Build.rect rId .roundabout (cm (-50)) (cm 50) (m 20) (m 20)

/-- An annular sector about C between radii a and b, from φ = −6° to 96°. -/
def sector (a b : Q) : List Vec :=
  let angles : List Int := (List.range 18).map fun i => -6 + 6 * Int.ofNat i
  let at_ (r : Q) (d : Int) : Vec :=
    (roundMicro (Q.mul r (sinQ (rad (Q.ofInt d)))), roundMicro (Q.mul r (cosQ (rad (Q.ofInt d)))))
  angles.map (at_ b) ++ (angles.reverse.map (at_ a))

/-- The two circulating lanes; `observed` says whether their ordinals and counts are supplied. -/
def lanes (observed : Bool) : List Structure :=
  [ Build.lane laneLeft (sector (m 10) (m 14)) Build.east
      none (some laneRight) (if observed then some 1 else none) (if observed then some 2 else none)
  , Build.lane laneRight (sector (m 6) (m 10)) Build.east
      (some laneLeft) none (if observed then some 2 else none) (if observed then some 2 else none) ]

/-- Steps of 4.5° turned by scene k. -/
def turnSteps (k : Nat) : Nat := if k < 5 then 0 else if k > 25 then 20 else k - 5

/-- The subject at scene k on a path of radius `radius` (`left`: a left turn about (0, 2R)). -/
def subjectAt (k : Nat) (radius : Q) (left : Bool) : RoadUser :=
  let φ := rad (Units.ratio (9 * Int.ofNat (turnSteps k)) 2)
  let c := cosQ φ
  let s := sinQ φ
  let step := Q.div (Q.mul radius piQ) (Q.ofInt 40)
  let pos : Vec :=
    if k < 5 then (Q.neg (Q.mul (Q.ofInt (Int.ofNat (5 - k))) step), radius)
    else if k ≤ 25 then
      if left then (Q.mul radius s, Q.sub (Q.mul radius (Q.ofInt 2)) (Q.mul radius c))
      else (Q.mul radius s, Q.mul radius c)
    else
      let d := Q.mul (Q.ofInt (Int.ofNat (k - 25))) step
      if left then (radius, Q.add (Q.mul radius (Q.ofInt 2)) d) else (radius, Q.neg d)
  let heading : Vec :=
    if k < 25 then (if left then (c, s) else (c, Q.neg s))
    else if left then Build.north else Build.south
  let rate : Q :=
    if 6 ≤ k ∧ k ≤ 25 then Units.degrees (if left then 90 else -90) else Units.degrees 0
  let speed : Q := roundMicro (Q.div (Q.mul radius piQ) (Q.ofInt 2))
  Build.withKin
    (Build.user 1 [.motorVehicle] (roundMicro pos.1, roundMicro pos.2) heading speed (m 2, m 1, cm 75))
    (fun kin => { kin with yawRate := some rate })

/-- A passage through r: path radius per scene, turn side, whether lane ordinals are observed, and
    the scenes at which the body straddles both lanes (occupancy stated). -/
def passage (radius : Nat → Q) (left : Bool) (laneObserved : Bool) (straddle : Nat → Bool) : Trace :=
  Build.trace 30 0 (Units.milliseconds 50) fun k t =>
    let occ : Option (List (TrackId × RegionId)) :=
      if straddle k then some [(1, rId), (1, laneLeft), (1, laneRight)] else none
    Build.scene t (some 1) [subjectAt k (radius k) left] (roundabout :: lanes laneObserved) [] occ

/-- `forbid` (violated): A two-lane roundabout r (st.roundabout) whose lanes carry st.lane_adjacency ordinals 1 (inner) and 2 (outer) with a count of two. The subject, a passenger car (ru.motor_vehicle), enters r heading east in the lane of ordinal 1 and leaves at the first exit heading south, its yaw rate observed at every scene integrating to a quarter turn to the right since the entry: the right turn through r is recognized and the subject occupied the lane of ordinal 1. -/
def forbidTrace : Trace := passage (fun _ => m 12) false true (fun _ => false)

/-- `permit` (compliant): Same roundabout and right turn, made in the lane of ordinal 2 throughout. -/
def permitTrace : Trace := passage (fun _ => m 8) false true (fun _ => false)

/-- `idle` (not_applicable): Same roundabout; the subject enters heading east in the lane of ordinal 1 and leaves heading north, a quarter turn to the left since the entry: no right turn is recognized. -/
def idleTrace : Trace := passage (fun _ => m 12) true true (fun _ => false)

/-- `blind` (unknown): As in forbid, but the source supplies no lane ordinals or counts (st.lane_adjacency absent). -/
def blindTrace : Trace := passage (fun _ => m 12) false true (fun _ => false)

/-- Branch radius: 8 m, drifting by 0.5 m per scene at k = 11 … 14 to the lane line at 10 m. -/
def driftRadius (k : Nat) : Q :=
  if k ≤ 10 then m 8 else if k ≥ 14 then m 10 else Q.add (m 8) (cm (50 * (Int.ofNat k - 10)))

/-- `branch_1` (violated): As in permit, but within r the subject drifts so that its footprint overlaps both lanes for several scenes before the exit. -/
def branch_1Trace : Trace :=
  passage driftRadius false true (fun k => decide (12 ≤ k) && decide (k ≤ 24))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_43_010_C2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (250, 1450)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.LVMC_11_43_010_C2
