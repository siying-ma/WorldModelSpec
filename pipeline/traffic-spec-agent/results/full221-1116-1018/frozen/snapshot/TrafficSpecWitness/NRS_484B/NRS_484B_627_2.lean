/-
  Witnesses for NRS_484B_627_2.

  Geometry (the witness's own figures; none appears in the rule): a straight eastbound road along
  +x, roadway 11 = x 0…120 m, y 0…7 m, lane 10 = x 0…120 m, y 0…3.5 m; a parking space 12 at
  x 45…55 m, y 7…10 m (off the roadway). Cars are 4.5 m × 1.8 m (half-extents 2.25, 0.9, 0.75),
  the bus 12 m × 2.5 m. The subject (track 1) halts at (50, 1.75) heading east. Every scene is
  three static observations 1 s apart (all bodies keep their positions; velocities are what the
  closest-approach primitive reads), so every instant carries the same verdict. Against the run's
  reading: follower gap 4 m (≤ 30 m reach) or 40 m (beyond); ahead gap 3 m (≤ 5 m queue gap) or
  10 m (beyond); a decelerating follower at 5 m/s, −2 m/s² (≥ 0.3 m/s²), 20 m behind, whose
  closest approach lies 4.9 s ahead (> 3 s horizon); a pedestrian crossing at 2 m/s whose centre
  passes 2 m (≤ 3 m) or 5 m (> 3 m) from the subject's 1.5 s ahead.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_627_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_627_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneId : RegionId := 10
def lane : Structure := Build.rect laneId .lane Q.zero Q.zero (m 120) (cm 350)
def roadway : Structure := Build.rect 11 .roadway Q.zero Q.zero (m 120) (m 7)
def parking : Structure := Build.rect 12 .parkingSpace (m 45) (m 7) (m 55) (m 10)

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- A car in lane 10 at longitudinal position `x`, heading east at `speed`. -/
def car (id : TrackId) (x : Q) (speed : Q) : RoadUser :=
  Build.user id [.motorVehicle] (x, cm 175) Build.east speed carExtent

/-- The subject, halted mid-block at x = 50 m. -/
def subjectCar : RoadUser := car 1 (m 50) Q.zero

/-- A car behind the subject in its lane with a body gap of `gap` m (front bumper at 47.75 − gap). -/
def followerAt (gap : Int) (speed : Q) : RoadUser :=
  car 2 (Q.sub (m 50) (Q.add (m gap) (cm 450))) speed

/-- A halted bus ahead of the subject in its lane with a body gap of `gap` m. -/
def busAhead (gap : Int) : RoadUser :=
  Build.user 4 [.bus, .motorVehicle] (Q.add (m 50) (Q.add (m gap) (cm 825)), cm 175) Build.east Q.zero
    (m 6, cm 125, cm 150)

/-- A pedestrian 3 m south of the lane centre line, `dx` m ahead of the subject's centre, walking
    north at 2 m/s: closest centre approach `dx` m, 1.5 s ahead. -/
def pedestrian (dx : Int) : RoadUser :=
  Build.user 3 [.pedestrian] (Q.add (m 50) (m dx), Q.sub (cm 175) (m 3)) Build.north
    (Units.metresPerSecond 2) (cm 30, cm 30, cm 90)

def staticTrace (users : List RoadUser) (devices : List Device := [])
    (structures : List Structure := [lane, roadway]) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures devices

/-- `forbid` (violated): A car halts mid-block in a roadway lane with no road user ahead, no road user in predicted conflict and no stop sign or signal; a car behind it in the same lane halts 4 m behind. -/
def forbidTrace : Trace := staticTrace [subjectCar, followerAt 4 Q.zero]

/-- `permit` (compliant): The same halt, but a bus is halted 3 m ahead of the car in its lane: the car halts behind other traffic. -/
def permitTrace : Trace := staticTrace [subjectCar, followerAt 4 Q.zero, busAhead 3]

/-- `idle` (not_applicable): A car halts in a parking space off the roadway with a car passing behind it. -/
def idleTrace : Trace :=
  staticTrace
    [ Build.user 1 [.motorVehicle] (m 50, cm 850) Build.east Q.zero carExtent
    , car 2 (m 40) (Units.metresPerSecond 10) ]
    [] [lane, roadway, parking]

/-- `blind` (unknown): As in forbid, but the source does not supply the in-lane ahead/behind relation, so neither the follower held behind nor the absence of a vehicle ahead is observed. -/
def blindTrace : Trace :=
  -- The manifest drops any measured ahead/behind relation; the source also does not report which
  -- lane the follower is in (only the subject's occupancy is observed), so Core cannot compute the
  -- relation from the scene either.
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    { Build.scene t (some 1) [subjectCar, followerAt 4 Q.zero] [lane, roadway] [] with
      occupancyObserved := [1], occupies := [(1, laneId), (1, 11)] }

/-- `branch_1` (compliant): As in forbid, but a stop sign governs the lane the car occupies. -/
def branch_1Trace : Trace :=
  staticTrace [subjectCar, followerAt 4 Q.zero] [Build.sign 20 .stopSign [laneId]]

/-- `branch_2` (compliant): A car halts in a roadway lane with no other road user in the scene. -/
def branch_2Trace : Trace := staticTrace [subjectCar]

/-- `branch_3` (compliant): As in forbid, but a yield sign governs the lane. -/
def branch_3Trace : Trace :=
  staticTrace [subjectCar, followerAt 4 Q.zero] [Build.sign 21 .yieldSign [laneId]]

/-- `branch_4` (compliant): As in forbid, but a traffic signal governing the lane shows circular red. -/
def branch_4Trace : Trace :=
  staticTrace [subjectCar, followerAt 4 Q.zero] [Build.signal 22 [laneId] [.circularRed]]

/-- `branch_5` (compliant): As in forbid, but a police officer directing traffic in the lane signals stop. -/
def branch_5Trace : Trace :=
  staticTrace [subjectCar, followerAt 4 Q.zero]
    [{ Build.device 23 .humanDirection [laneId] with
        humanRole := some .policeOfficer, humanIndication := some .stop }]

/-- `branch_6` (compliant): As in forbid, but railway crossing lights governing the lane flash (gate up). -/
def branch_6Trace : Trace :=
  staticTrace [subjectCar, followerAt 4 Q.zero]
    [{ Build.device 24 .railwaySignalOrGate [laneId] with
        railLights := some .flashing, gate := some .up }]

/-- `branch_7` (compliant): As in forbid, but a railway gate governing the lane is down (lights dark). -/
def branch_7Trace : Trace :=
  staticTrace [subjectCar, followerAt 4 Q.zero]
    [{ Build.device 24 .railwaySignalOrGate [laneId] with
        railLights := some .dark, gate := some .down }]

/-- `branch_8` (compliant): As in forbid, but a pedestrian crossing ahead is predicted within 2 m of the car's centre in 1.5 s. -/
def branch_8Trace : Trace := staticTrace [subjectCar, followerAt 4 Q.zero, pedestrian 2]

/-- `branch_9` (violated): As in forbid, but a pedestrian crossing ahead passes 5 m from the car's centre: no conflict. -/
def branch_9Trace : Trace := staticTrace [subjectCar, followerAt 4 Q.zero, pedestrian 5]

/-- `branch_10` (violated): The follower, 20 m behind, is still moving at 5 m/s and braking at 2 m/s² (impeded). -/
def branch_10Trace : Trace :=
  staticTrace [subjectCar,
    Build.withKin (followerAt 20 (Units.metresPerSecond 5))
      (fun k => { k with accelLongitudinal := some (Units.metresPerSecondSq (-2)) })]

/-- `branch_11` (compliant): The halted follower is 40 m behind: not immediately to the rear. -/
def branch_11Trace : Trace := staticTrace [subjectCar, followerAt 40 Q.zero]

/-- `branch_12` (violated): A bus is halted 10 m ahead, beyond queue spacing: not a halt behind traffic. -/
def branch_12Trace : Trace := staticTrace [subjectCar, followerAt 4 Q.zero, busAhead 10]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_627_2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.ahead_behind_in_lane"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .violated ]

end TrafficSpecWitness.NRS_484B_627_2
