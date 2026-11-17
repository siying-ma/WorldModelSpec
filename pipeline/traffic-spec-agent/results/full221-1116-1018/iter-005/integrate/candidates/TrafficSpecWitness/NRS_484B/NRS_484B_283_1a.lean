/-
  Witnesses for NRS_484B_283_1a.

  Geometry (the witness's own figures, none in the rule): a two-lane highway along x. Lane 11
  (y 0…4) is designated eastbound, lane 12 (y 4…8) westbound. A crosswalk 13 (unmarked) spans
  x 19…23 across both lanes. For the one-way branch, region 14 is a one-way roadway (y 0…8)
  designated eastbound, with no lanes. The subject (track 1, a motor vehicle, half-extents
  2.5 × 1.0 × 0.75 m) heads east in lane 11; the pedestrian (track 2, half-extents 0.3 × 0.3 ×
  0.9 m) is in the crosswalk. Each trace is three identical scenes 1 s apart; the rule reads
  no window.

  Against the reading (horizon 3 s, clearance 3 m, halt tolerance 0.1 m/s):
  - forbid: subject at (5, 2) at 10 m/s, pedestrian standing at (20, 2.5): closest approach in
    1.5 s at 0.5 m.
  - branch_2: subject at (-30, 2) at 10 m/s, pedestrian at (20, 6) in lane 12: closest approach in
    5 s, beyond the horizon.
  - branch_3: pedestrian at (20, 5) in lane 12 walking south at 1 m/s, subject at (5, 2) at
    10 m/s: closest approach ≈ 1.51 s at ≈ 1.49 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_283_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_283_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 250, cm 100, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

def laneEast : Structure :=
  Build.lane 11 [(m (-50), m 0), (m 50, m 0), (m 50, m 4), (m (-50), m 4)] Build.east
def laneWest : Structure :=
  Build.lane 12 [(m (-50), m 4), (m 50, m 4), (m 50, m 8), (m (-50), m 8)] Build.west
def crosswalk : Structure :=
  { Build.rect 13 .crosswalk (m 19) (m 0) (m 23) (m 8) with marked := some false }
def oneWay : Structure :=
  { Build.rect 14 .oneWayRoadway (m (-50)) (m 0) (m 50) (m 8) with
      lane := some { direction := some Build.east } }

def twoLanes : List Structure := [laneEast, laneWest, crosswalk]

def movingCar : RoadUser :=
  Build.user 1 [.motorVehicle] (m 5, m 2) Build.east (Units.metresPerSecond 10) carExtent
def standingPed : RoadUser :=
  Build.user 2 [.pedestrian] (m 20, cm 250) Build.east Q.zero pedExtent

def constTrace (users : List RoadUser) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures devices

/-- `forbid` (violated): No signal head governs the subject's lane; a pedestrian stands in an unmarked crosswalk on a lane whose direction matches the subject's heading, 15 m ahead; the subject moves at 10 m/s with a predicted closest approach of 0.5 m in 1.5 s. -/
def forbidTrace : Trace :=
  constTrace [movingCar, standingPed] twoLanes []

/-- `permit` (compliant): Same scene, but the subject is at rest (speed 0.0 m/s) before the crosswalk while the pedestrian crosses its half. -/
def permitTrace : Trace :=
  constTrace
    [ Build.user 1 [.motorVehicle] (m 5, m 2) Build.east Q.zero carExtent
    , Build.user 2 [.pedestrian] (m 20, cm 250) Build.north (Units.metresPerSecond 1) pedExtent ]
    twoLanes []

/-- `idle` (not_applicable): A traffic signal head governing the subject's lane shows circular_green: the devices are in operation. -/
def idleTrace : Trace :=
  constTrace [movingCar, standingPed] twoLanes
    [ { Build.signal 100 [11] [.circularGreen] with inoperative := some false, uncovered := some true } ]

/-- `blind` (unknown): No signal head governs the subject's lane; a pedestrian near the crosswalk is on the predicted collision course, but whether its footprint overlaps the crosswalk is not observed. -/
def blindTrace : Trace :=
  constTrace [movingCar, standingPed] twoLanes []

/-- `branch_1` (not_applicable): No signal heads and no pedestrian anywhere in the scene: the duty is decided for the subject alone as not engaged. -/
def branch_1Trace : Trace :=
  constTrace [movingCar] twoLanes []

/-- `branch_2` (not_applicable): A pedestrian in the crosswalk on the opposite half, on a lane whose direction points against the subject's heading, with no predicted closest approach within the horizon. -/
def branch_2Trace : Trace :=
  constTrace
    [ Build.user 1 [.motorVehicle] (m (-30), m 2) Build.east (Units.metresPerSecond 10) carExtent
    , Build.user 2 [.pedestrian] (m 20, m 6) Build.east Q.zero pedExtent ]
    twoLanes []

/-- `branch_3` (violated): the pedestrian walks south on the opposite half (lane 12) into the subject's path; the moving subject's closest approach is ≈ 1.5 m in ≈ 1.5 s: st2's danger. -/
def branch_3Trace : Trace :=
  constTrace
    [ movingCar
    , Build.user 2 [.pedestrian] (m 20, m 5) Build.south (Units.metresPerSecond 1) pedExtent ]
    twoLanes []

/-- `branch_4` (violated): a one-way roadway designated eastbound, no lanes; the pedestrian stands in the crosswalk on it ahead of the moving subject: the whole highway is the subject's half. -/
def branch_4Trace : Trace :=
  constTrace [movingCar, standingPed] [oneWay, crosswalk] []

/-- `branch_5` (not_applicable): the forbid scene with a pedestrian head governing lane 11 showing walk: the pedestrian devices are in operation. -/
def branch_5Trace : Trace :=
  constTrace [movingCar, standingPed] twoLanes
    [ { Build.device 101 .pedestrianSignal [11] with pedState := some .walk } ]

/-- `branch_6` (violated): the forbid scene with a traffic signal head governing lane 11 that is inoperative (no valid indication shown): not in operation. -/
def branch_6Trace : Trace :=
  constTrace [movingCar, standingPed] twoLanes
    [ { Build.signal 100 [11] [] with inoperative := some true, uncovered := some true } ]

/-- `branch_7` (violated): the forbid scene with a traffic signal head governing lane 11 showing dark: not in operation. -/
def branch_7Trace : Trace :=
  constTrace [movingCar, standingPed] twoLanes
    [ { Build.signal 100 [11] [.dark] with inoperative := some false, uncovered := some true } ]

/-- `branch_8` (compliant): two pedestrians. Pedestrian 2 stands in a second crosswalk 15
    (x −20…−16) on the subject's half, behind the subject: the duty is engaged and kept towards it.
    Pedestrian 3 walks south on the opposite half into the subject's path (branch_3's geometry), but
    a pedestrian head governing lane 12, the lane it occupies, shows walk: it is not a pedestrian the
    duty is owed to under this section. -/
def branch_8Trace : Trace :=
  constTrace
    [ movingCar
    , Build.user 2 [.pedestrian] (m (-18), cm 250) Build.east Q.zero pedExtent
    , Build.user 3 [.pedestrian] (m 20, m 5) Build.south (Units.metresPerSecond 1) pedExtent ]
    (twoLanes ++ [{ Build.rect 15 .crosswalk (m (-20)) (m 0) (m (-16)) (m 8) with marked := some false }])
    [ { Build.device 101 .pedestrianSignal [12] with pedState := some .walk } ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_283_1a"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant ]

end TrafficSpecWitness.NRS_484B_283_1a
