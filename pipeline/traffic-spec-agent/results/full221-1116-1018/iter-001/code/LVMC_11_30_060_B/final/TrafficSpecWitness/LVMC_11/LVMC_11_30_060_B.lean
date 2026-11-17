/-
  Witnesses for LVMC_11_30_060_B.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - Roadway 10: x −100…100 m, y 0…10 m, carrying no designated direction (except in branch_3, where
    it carries east and no lanes are mapped). Lane 11 (y 0…5, eastbound), lane 12 (y 5…10,
    westbound). Roadway 13 (y 10…20) is a second, adjacent roadway (branch_4 only).
  - Overpass 20 (pedestrian_grade_separation): x 10…14 m, y −10…30 m; the pedestrian's body at x 0
    (half-extent 0.25 m) lies 9.75 m from it (reach 30 m). In `idle` it lies at x 300…304 instead.
  - Pedestrian 1 at (0, 2) walking north at 1.4 m/s across eastbound lane 11 (cos 0 with its
    direction). Car 2 (half-extents 2.4 × 0.9 m) at (−20, 3.8) eastbound at 10 m/s: relative to
    the pedestrian it closes to about 0.99 m in about 1.99 s (horizon 3 s, clearance 3 m), with
    no contact at the instant.
  - Every scene of a trace is the same; three instants 1 s apart; nothing looks back in time.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_060_B
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_060_B

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def pedExtent : Q × Q × Q := (cm 25, cm 25, cm 90)
def carExtent : Q × Q × Q := (cm 240, cm 90, cm 75)

def pedestrianAt (pos : Vec) (heading : Vec) : RoadUser :=
  Build.user 1 [.pedestrian] pos heading (cm 140) pedExtent

def pedestrian : RoadUser := pedestrianAt (m 0, m 2) Build.north

def carAt (pos : Vec) : RoadUser :=
  Build.user 2 [.motorVehicle] pos Build.east (Units.metresPerSecond 10) carExtent

/-- The car whose projected closest approach to the pedestrian is about 1 m in about 2 s. -/
def conflictingCar : RoadUser := carAt (m (-20), cm 380)

def roadway : Structure := Build.rect 10 .roadway (m (-100)) (m 0) (m 100) (m 10)

def laneEast : Structure :=
  Build.lane 11 [(m (-100), m 0), (m 100, m 0), (m 100, m 5), (m (-100), m 5)] Build.east

def laneWest : Structure :=
  Build.lane 12 [(m (-100), m 5), (m 100, m 5), (m 100, m 10), (m (-100), m 10)] Build.west

def overpassNear : Structure :=
  Build.rect 20 .pedestrianGradeSeparation (m 10) (m (-10)) (m 14) (m 30)

def overpassFar : Structure :=
  Build.rect 20 .pedestrianGradeSeparation (m 300) (m (-10)) (m 304) (m 30)

def prohibitionSign : Device :=
  { Build.sign 30 .regulatorySign [10] with
      code := some .pedestriansProhibited, conditions := some {} }

def nearStructures : List Structure := [roadway, laneEast, laneWest, overpassNear]

def steady (users : List RoadUser) (structures : List Structure) (devices : List Device)
    (occupies : Option (List (TrackId × RegionId)) := none) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures devices occupies

/-- `forbid` (violated): A pedestrian crosses a roadway 10 m from a pedestrian overpass, walking at 1.4 m/s into the path of a car on that roadway whose projected closest approach is 1 m in 2 s. -/
def forbidTrace : Trace :=
  steady [pedestrian, conflictingCar] nearStructures []

/-- `permit` (compliant): A pedestrian crosses the roadway 10 m from the overpass at 1.4 m/s; no vehicle is in the scene. -/
def permitTrace : Trace :=
  steady [pedestrian] nearStructures []

/-- `idle` (not_applicable): A pedestrian crosses a roadway 300 m from any pedestrian tunnel or overpass. -/
def idleTrace : Trace :=
  steady [pedestrian] [roadway, laneEast, laneWest, overpassFar] []

/-- `blind` (unknown): A pedestrian crosses the roadway near an overpass while a car approaches, but the source maps the overpass without its outline, so the distance to it is unknown. -/
def blindTrace : Trace :=
  steady [pedestrian, conflictingCar] nearStructures []

/-- `branch_1` (not_applicable): the forbid scene, but a pedestrians_prohibited regulatory sign
    governs the roadway crossed (g8). -/
def branch1Trace : Trace :=
  steady [pedestrian, conflictingCar] nearStructures [prohibitionSign]

/-- `branch_2` (compliant): the pedestrian crosses near the overpass while a car on the roadway is
    80 m away: no closest approach within the horizon, no contact. -/
def branch2Trace : Trace :=
  steady [pedestrian, carAt (m (-80), cm 380)] nearStructures []

/-- `branch_3` (violated): the roadway itself carries the designated direction and no lanes are
    mapped; the pedestrian crosses it into the car's path. -/
def branch3Trace : Trace :=
  let road : Structure := { roadway with lane := some { direction := some Build.east } }
  steady [pedestrian, conflictingCar] [road, overpassNear] []

/-- `branch_4` (compliant): the pedestrian, walking south across westbound lane 12, straddles
    roadway 10 (governed by a pedestrians_prohibited sign) and the adjacent roadway 13; the car
    in conflict is on roadway 10 only, which is not a roadway whose crossing this rule governs. -/
def branch4Trace : Trace :=
  let road2 : Structure := Build.rect 13 .roadway (m (-100)) (m 10) (m 100) (m 20)
  let ped := pedestrianAt (m 0, cm 990) Build.south
  let car := carAt (m (-20), cm 810)
  steady [ped, car] [roadway, laneEast, laneWest, road2, overpassNear] [prohibitionSign]
    (some [(1, 10), (1, 12), (1, 13), (2, 10), (2, 12)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_30_060_B"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch1Trace .notApplicable
  , witness "branch_2" branch2Trace .compliant
  , witness "branch_3" branch3Trace .violated
  , witness "branch_4" branch4Trace .compliant ]

end TrafficSpecWitness.LVMC_11_30_060_B
