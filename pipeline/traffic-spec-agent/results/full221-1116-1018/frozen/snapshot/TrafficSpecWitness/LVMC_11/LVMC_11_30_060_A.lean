/-
  Witnesses for LVMC_11_30_060_A.

  Geometry (the witness's own figures; none appears in the rule): a straight roadway (region 10)
  x ∈ [0, 200] m, y ∈ [0, 7.5] m; lane 11 (y ∈ [0, 3.75], eastbound) and lane 12 (y ∈ [3.75, 7.5],
  westbound, or eastbound on a one-way roadway). A two-way roadway carries no designated direction
  of its own; a one-way or unlaned one carries east. The pedestrian (track 1, half-extent
  0.25 × 0.25 × 0.9 m) crosses northward at x = 100 m at 1.4 m/s; a car (track 2, half-extent
  2.3 × 0.9 × 0.75 m) drives east at 12 m/s. Observations every 1 s from t = 0.

  Conflict figures against the reading (horizon 3 s, clearance 3 m): in `forbid` the car is 24 m
  short of the crossing line, 1.8 m north of the pedestrian, so under constant velocities the
  centres come to 0.99 m at 1.99 s (next instant: 0.99 m at 0.99 s). In `branch_1` the halted
  pedestrian sits 2 m south of the car's line: closest approach 2 m (a projected conflict) while the
  car approaches; at the first instant, when the pedestrian still walks, the closest approach lies
  3.73 s ahead (beyond the horizon). In `branch_3` the walking pedestrian's first instant on the
  roadway has its closest approach 4.95 s ahead; after the halt it walks on with the car 24 m off,
  closest approach 0.99 m at 1.99 s.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_060_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_060_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def pedWalk : Q := Units.micrometresPerSecond 1400000   -- 1.4 m/s
def carSpeed : Q := Units.metresPerSecond 12
def pedExt : Q × Q × Q := (cm 25, cm 25, cm 90)
def carExt : Q × Q × Q := (cm 230, cm 90, cm 75)

/-- The roadway; `directed` gives it an eastbound designated direction (one-way or unlaned). -/
def roadway (directed : Bool) : Structure :=
  let base := Build.rect 10 .roadway (m 0) (m 0) (m 200) (cm 750)
  if directed then { base with lane := some { direction := some Build.east } } else base

def lane1 : Structure :=
  Build.lane 11 [(m 0, m 0), (m 200, m 0), (m 200, cm 375), (m 0, cm 375)] Build.east
def lane2 (dir : Vec) : Structure :=
  Build.lane 12 [(m 0, cm 375), (m 200, cm 375), (m 200, cm 750), (m 0, cm 750)] dir

/-- Two-way laned roadway: no designated direction on the roadway itself. -/
def twoWay : List Structure := [roadway false, lane1, lane2 Build.west]

/-- The pedestrian at (x, y) cm heading north at `speed`. -/
def ped (x y : Int) (speed : Q) : RoadUser :=
  Build.user 1 [.pedestrian] (cm x, cm y) Build.north speed pedExt

/-- The car at (x, y) cm heading east at `speed`. -/
def car (x y : Int) (speed : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm x, cm y) Build.east speed carExt

/-- The forbid scene at instant k: pedestrian crossing at 1.4 m/s, car 24 m short of the line. -/
def forbidUsers (k : Nat) : List RoadUser :=
  [ ped 10000 (70 + 140 * (k : Int)) pedWalk
  , car (7600 + 1200 * (k : Int)) 250 carSpeed ]

/-- `forbid` (violated): A pedestrian crosses a laned roadway mid-block at 1.4 m/s; a car on that roadway at 12 m/s would come within 1 m of the pedestrian's centre in 2 s, and the pedestrian keeps walking. -/
def forbidTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (forbidUsers k) twoWay []

/-- `permit` (compliant): A pedestrian crosses the roadway mid-block at 1.4 m/s; no vehicle is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ ped 10000 (100 + 140 * (k : Int)) pedWalk ] twoWay []

/-- A marked crosswalk across the roadway at x ∈ [98, 102] m. -/
def crosswalk : Structure :=
  { Build.rect 13 .crosswalk (m 98) (m 0) (m 102) (cm 750) with marked := some true }

/-- `idle` (not_applicable): A pedestrian crosses the roadway within a marked crosswalk while a car approaches. -/
def idleTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (forbidUsers k) (twoWay ++ [crosswalk]) []

/-- `blind` (unknown): A pedestrian occupies the roadway mid-block while a car approaches, but the pedestrian's velocity is not observed.
    (The pedestrian is first observed 0.5 m short of the roadway edge, so its history on the
    roadway is recorded; the manifest alone withholds kin.velocity. Unmasked, the scene at k = 1
    has the car 24 m short of the line, 1.8 m north of the pedestrian: a violation.) -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped 10000 (-50 + 140 * (k : Int)) pedWalk
      , car (6400 + 1200 * (k : Int)) 270 carSpeed ]
      twoWay []

/-- branch_1 pedestrian: walks at k = 0, halted at (100, 1.0) m for k = 1 … 4, walks on from k = 5. -/
def branch1Ped (k : Nat) : RoadUser :=
  if k == 0 then ped 10000 20 pedWalk
  else if k ≤ 4 then ped 10000 100 Q.zero
  else ped 10000 (100 + 140 * ((k : Int) - 5)) pedWalk

/-- `branch_1` (compliant): A pedestrian walks across a lane mid-block from the roadway edge, then halts in the lane while a car on that roadway approaches and passes with its centre about 2 m from the pedestrian's (a conflict is projected while the car approaches, but the pedestrian is at rest and the bodies do not touch); the pedestrian walks on once the car has gone. -/
def branch_1Trace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ branch1Ped k, car (5500 + 1200 * (k : Int)) 300 carSpeed ] twoWay []

/-- `branch_2` (not_applicable): A pedestrian walks along the roadway mid-block, its velocity aligned with the lane's direction from the first observation on, while a car approaches behind it in the same lane: it never moves across a carrier, so it is not crossing.
    (One-way eastbound roadway; the pedestrian is first observed 1 m short of the mapped roadway's
    start, so the past of its stay on the roadway is recorded.) -/
def branch_2Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (cm (-100 + 140 * (k : Int)), cm 150) Build.east pedWalk pedExt
      , Build.user 2 [.motorVehicle] (cm (-4000 + 800 * (k : Int)), cm 175) Build.east
          (Units.metresPerSecond 8) carExt ]
      [roadway true, lane1, lane2 Build.east] []

/-- branch_3 pedestrian: off the roadway at k = 0, on it walking at k = 1, halted at k = 2, 3,
    walks on at k = 4, 5. -/
def branch3Ped (k : Nat) : RoadUser :=
  if k == 0 then ped 10000 (-50) pedWalk
  else if k == 1 then ped 10000 50 pedWalk
  else if k ≤ 3 then ped 10000 90 Q.zero
  else ped 10000 (90 + 140 * ((k : Int) - 4)) pedWalk

/-- `branch_3` (violated): A pedestrian walks onto the roadway mid-block, halts in the lane, then walks on into the path of an approaching car whose centre would come within 1 m of the pedestrian's in 2 s. -/
def branch_3Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ branch3Ped k, car (2800 + 1200 * (k : Int)) 270 carSpeed ] twoWay []

/-- A pedestrians_prohibited regulatory sign governing the roadway; its legend states no restriction. -/
def noPedSign : Device :=
  { Build.sign 20 .regulatorySign [10] with code := some .pedestriansProhibited, conditions := some {} }

/-- `branch_4` (not_applicable): the forbid scene, at a place where a pedestrians_prohibited sign
    governs the roadway: the exception (f8) suspends the section. -/
def branch_4Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (forbidUsers k) twoWay [noPedSign]

/-- `branch_5` (violated): the forbid crossing on an unlaned eastbound roadway: the pedestrian moves
    across the roadway itself (no lane to cross), and walks on into the car's projected path. -/
def branch_5Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (forbidUsers k) [roadway true] []

/-- The other roadway of a divided highway, north of roadway 10: region 14, y ∈ [7.5, 15] m, with
    its eastbound lane 15 (y ∈ [7.5, 11.25] m). -/
def roadwayB : Structure := Build.rect 14 .roadway (m 0) (cm 750) (m 200) (m 15)
def laneB : Structure :=
  Build.lane 15 [(m 0, cm 750), (m 200, cm 750), (m 200, cm 1125), (m 0, cm 1125)] Build.east

/-- A pedestrians_prohibited regulatory sign governing roadway 14 only. -/
def noPedSignB : Device :=
  { Build.sign 21 .regulatorySign [14] with code := some .pedestriansProhibited, conditions := some {} }

/-- `branch_6` (compliant): a pedestrian crossing roadway 10 northward stands, walking, at its seam
    with roadway 14 (it occupies both, stated, as its body spans the seam), where a
    pedestrians_prohibited sign governs roadway 14; a car on roadway 14 only (24 m short of the
    line, 1.8 m north) projects a 0.99 m closest approach. The section does not apply to the
    roadway the sign governs, and no vehicle is on roadway 10: compliant. -/
def branch_6Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ped 10000 750 pedWalk, car 7600 930 carSpeed ]
      (twoWay ++ [roadwayB, laneB]) [noPedSignB]
      (occupies := some [(1, 10), (1, 12), (1, 14), (1, 15), (2, 14), (2, 15)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_30_060_A"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant ]

end TrafficSpecWitness.LVMC_11_30_060_A
