/-
  Witnesses for NRS_484B_270_2b_o2.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - One lane eastward, y from 0 m to 4 m, x from -100 m to 300 m, count 1 in its direction
    (branch_2: two eastward lanes, y 0..4 (ordinal 2) and y 4..8 (ordinal 1), count 2).
  - Subject car (track 1): heading east, 10 m/s, half extents 2 m × 1 m; x = 5·k m.
  - Overtaken rider (track 2): heading east, 6 m/s, half extents 1 m × 0.3 m, y = 1 m; x = 3·k + 8 m.
  - Samples every 0.5 s, k = 0 … 9, from t = 20 s. The rider's offset ahead of the car is 8 − 2k m:
    ahead with a gap between the projections at k ≤ 2 (8, 6, 4 m), side by side at k = 3, 4, 5
    (2, 0, −2 m), behind at k ≥ 6: the pass is recognized at k = 6 (t = 23 s).
  - The trace is padded 12 s before (the first scene repeated) so the 10 s window behind every judged
    instant is covered, and each witness judges the unpadded instants only (`window`).
  - Car's lateral position (y of its centre) sets the body-to-body gap while side by side:
    gap = y_car − 1 m − 1.3 m. forbid / blind 2.8 m → 0.5 m (below 3 ft = 0.9144 m);
    permit 3.8 m → 1.5 m (above 3 ft and above the reading's 1.0 m clearance);
    branch_3 3.25 m → 0.95 m (above 3 ft, below the reading's 1.0 m clearance).
  - branch_1: the rider at y = 3.5 m, the car at y = 0.5 m: the rider lies on the car's left, gap 1.7 m.
  - idle: the overtaken vehicle is a moped (see the comment at idleTrace).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_2b_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_2b_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def t0 : Timestamp := 20000
def nSteps : Nat := 10
def judged : Option (Timestamp × Timestamp) := some (20000, 24500)

/-- One eastward lane, the only one in its direction. -/
def oneLaneRoad : List Structure :=
  [ Build.lane 10 [(m (-100), m 0), (m 300, m 0), (m 300, m 4), (m (-100), m 4)] Build.east
      none none (some 1) (some 1) ]

/-- Two eastward lanes: the rider's (right, ordinal 2) and one to its left (ordinal 1). -/
def twoLaneRoad : List Structure :=
  [ Build.lane 10 [(m (-100), m 0), (m 300, m 0), (m 300, m 4), (m (-100), m 4)] Build.east
      (some 11) none (some 2) (some 2)
  , Build.lane 11 [(m (-100), m 4), (m 300, m 4), (m 300, m 8), (m (-100), m 8)] Build.east
      none (some 10) (some 1) (some 2) ]

def car (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (5 * (k : Int)), y) Build.east (Units.metresPerSecond 10)
    (m 2, m 1, cm 75)

def rider (k : Nat) (cls : RoadUserClass) (y : Q) : RoadUser :=
  Build.user 2 [cls] (m (3 * (k : Int) + 8), y) Build.east (Units.metresPerSecond 6)
    (m 1, cm 30, cm 90)

/-- The pass: the car at lateral position `yCar`, the overtaken user of class `cls` at `yRider`. -/
def passTrace (cls : RoadUserClass) (yCar yRider : Q) (road : List Structure) : Trace :=
  Build.pad
    (Build.trace nSteps t0 (Units.milliseconds 500) fun k t =>
      Build.scene t (some 1) [car k yCar, rider k cls yRider] road [])
    (Units.seconds 12) (Units.seconds 1) (Units.milliseconds 500)

/-- `forbid` (violated): Road with one lane in the subject's direction; a bicycle rides in it. The subject car overtakes the bicycle on its left with a body-to-body gap below 3 feet while side by side. -/
def forbidTrace : Trace := passTrace .bicycle (cm 280) (m 1) oneLaneRoad

/-- `permit` (compliant): Same pass, the subject car keeping a gap above both 3 feet and the safe-gap clearance while side by side, the bicycle on its right. -/
def permitTrace : Trace := passTrace .bicycle (cm 380) (m 1) oneLaneRoad

/-- `idle` (not_applicable): The subject car overtakes another vehicle on a one-lane road; no bicycle,
    electric bicycle or electric scooter is in the scene. The overtaken vehicle is a moped: under the
    run's reading a car (`motor_vehicle`) is an unresolved class of the electric-bicycle and
    electric-scooter aggregates, so its membership is unknown, never decidedly false; a moped is
    excluded from all three. -/
def idleTrace : Trace := passTrace .moped (cm 380) (m 1) oneLaneRoad

/-- The measured overlap of the projections on the car's heading at step k (the rider offset 8 − 2k m
    ahead, car half-length 2 m, rider half-length 1 m): the figures the footprints would give. -/
def measuredOverlap (k : Nat) : Q :=
  let dx : Int := 8 - 2 * (k : Int)
  if dx == 0 then m 2 else m ((3 : Int) - (dx.natAbs : Int))

/-- `blind` (unknown): As in forbid, but the source does not observe the gap between bodies. Core
    computes `rel.surface_gap` from the footprints when it is not supplied, so masking the atom alone
    leaves it decided: here the source does not observe the subject car's extent (its footprint, so
    neither its occupancy, which the rule does not read for it), and supplies the overlap of the
    projections as a measured relation, which Core can then not compute. The gap between the bodies is
    neither supplied nor computable; the rider's footprint and occupancy are observed. -/
def blindScene (k : Nat) (t : Timestamp) : Scene :=
  let s := Build.scene t (some 1)
    [ Build.withKin (car k (cm 280)) fun kn => { kn with extent := none }
    , rider k .bicycle (m 1) ]
    oneLaneRoad []
  Build.withRelations
    { s with occupancyObserved := [2], occupies := s.occupies.filter (·.1 == 2) }
    [ Build.relation 1 2 fun r => { r with longitudinalOverlap := some (measuredOverlap k) } ]

def blindTrace : Trace :=
  Build.pad (Build.trace nSteps t0 (Units.milliseconds 500) blindScene)
    (Units.seconds 12) (Units.seconds 1) (Units.milliseconds 500)

/-- `branch_1` (violated): The subject car overtakes a rider on the rider's right, with a wide gap:
    while side by side the rider lies on the subject's left. The rider is an electric bicycle: under
    the run's reading the electric-scooter aggregate includes no class (`electric_scooter` is
    unresolved), so an electric scooter's membership is unknown and the pass could not be decided. -/
def branch_1Trace : Trace := passTrace .electricBicycle (cm 50) (cm 350) oneLaneRoad

/-- `branch_2` (not_applicable): The road has two lanes in the subject's direction; the subject passes a bicycle. -/
def branch_2Trace : Trace := passTrace .bicycle (cm 380) (m 1) twoLaneRoad

/-- `branch_3` (violated): one lane; the car passes the bicycle on its left with a gap of 0.95 m:
    above the stated 3 feet but below the reading's clearance, the larger of the two. -/
def branch_3Trace : Trace := passTrace .bicycle (cm 325) (m 1) oneLaneRoad

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_2b_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_270_2b_o2
