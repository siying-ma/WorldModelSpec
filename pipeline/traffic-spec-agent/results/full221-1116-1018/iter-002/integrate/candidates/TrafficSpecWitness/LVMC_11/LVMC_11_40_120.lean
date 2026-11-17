/-
  Witnesses for LVMC_11_40_120.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
    highway 10: x ∈ [-50, 50], y ∈ [-10, 10].
    roadway 11: y ∈ [-5, 5], on highway 10; designated direction east (except where stated).
    lane 12: y ∈ [-5, 0], direction east; lane 14: y ∈ [0, 5], direction west; both on 10.
    bicycle path 13: y ∈ [6, 9], 3 m wide (reading's minimum 1.2 m), direction east, on 10.
    Riders are 1.8 m long, 0.6 m wide; three instants one second apart.
    Along the roadway: y = -2.5, heading east at 5 m/s (cosine 1 > 0.94).
    Crossing: x = 0, heading north at 3 m/s (cosine 0 ≤ 0.94).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_120
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_120

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

def ext : Q × Q × Q := (cm 90, cm 30, cm 80)

def highway : Structure := Build.rect 10 .highway (m (-50)) (m (-10)) (m 50) (m 10)

/-- The roadway, with a designated direction east. -/
def roadway : Structure :=
  { Build.rect 11 .roadway (m (-50)) (m (-5)) (m 50) (m 5) with
    ways := some [10], lane := some { direction := some Build.east } }

/-- The roadway, carrying no designated direction (only its lanes do). -/
def roadwayNoDir : Structure :=
  { Build.rect 11 .roadway (m (-50)) (m (-5)) (m 50) (m 5) with ways := some [10] }

def laneEast : Structure :=
  { Build.rect 12 .lane (m (-50)) (m (-5)) (m 50) (m 0) with
    ways := some [10], lane := some { direction := some Build.east } }

def laneWest : Structure :=
  { Build.rect 14 .lane (m (-50)) (m 0) (m 50) (m 5) with
    ways := some [10], lane := some { direction := some Build.west } }

def pathOfWidth (w : Q) : Structure :=
  { Build.rect 13 .bicycleLaneOrPath (m (-50)) (m 6) (m 50) (m 9) with
    ways := some [10], lane := some { direction := some Build.east, width := some w } }

def path : Structure := pathOfWidth (m 3)

/-- A rider travelling east along lane 12 of the roadway. -/
def alongRoadway (cls : RoadUserClass) (k : Nat) : RoadUser :=
  Build.user 1 [cls] (m (-10 + 5 * (k : Int)), cm (-250)) Build.east (Units.metresPerSecond 5) ext

/-- A rider crossing the roadway northward towards the path. -/
def crossingRoadway (k : Nat) : RoadUser :=
  Build.user 1 [.bicycle] (m 0, m (-4 + 3 * (k : Int))) Build.north (Units.metresPerSecond 3) ext

def ride (users : Nat → List RoadUser) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (users k) structures devices

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): a rider rides at 5 m/s along a lane of the roadway, velocity parallel to
    its direction; a usable 3 m path lies on the same highway. The rider is an electric bicycle:
    under the run's reading the electric-scooter aggregate includes no class (ru.electric_scooter is
    unresolved), so a scooter-only rider would leave the class unknown (see task_result.md). -/
def forbidTrace : Trace :=
  ride (fun k => [alongRoadway .electricBicycle k]) [highway, roadway, laneEast, laneWest, path] []

/-- `permit` (compliant): the same rider travels on the bicycle path, its footprint inside it. -/
def permitTrace : Trace :=
  ride (fun k => [Build.user 1 [.electricBicycle] (m (-10 + 5 * (k : Int)), cm 750) Build.east
      (Units.metresPerSecond 5) ext])
    [highway, roadway, laneEast, laneWest, path] []

/-- `idle` (not_applicable): a bicycle rides along the roadway of a highway with no bicycle path. -/
def idleTrace : Trace :=
  ride (fun k => [alongRoadway .bicycle k]) [highway, roadway, laneEast, laneWest] []

/-- `blind` (unknown): a bicycle moves on the roadway beside a usable path; kin.velocity unobserved. -/
def blindTrace : Trace :=
  ride (fun k => [alongRoadway .bicycle k]) [highway, roadway, laneEast, laneWest, path] []

/-- `branch_1` (compliant): a bicycle crosses the roadway at right angles to the lane direction to
    reach the path; the roadway itself carries no direction, the lanes do. -/
def branch_1Trace : Trace :=
  ride (fun k => [crossingRoadway k]) [highway, roadwayNoDir, laneEast, laneWest, path] []

/-- `branch_2` (not_applicable): the only path is governed by a temporary traffic control closing
    it; a bicycle rides along the roadway. -/
def branch_2Trace : Trace :=
  ride (fun k => [alongRoadway .bicycle k]) [highway, roadway, laneEast, laneWest, path]
    [Build.device 20 .temporaryTrafficControl [13]]

/-- `branch_3` (not_applicable): the only path is 1 m wide, narrower than one rider's operating
    width; a bicycle rides along the roadway. -/
def branch_3Trace : Trace :=
  ride (fun k => [alongRoadway .bicycle k]) [highway, roadway, laneEast, laneWest, pathOfWidth (m 1)] []

/-- `branch_4` (not_applicable): a regulatory sign 'bicycles prohibited' governs the only path; a
    bicycle rides along the roadway. -/
def branch_4Trace : Trace :=
  ride (fun k => [alongRoadway .bicycle k]) [highway, roadway, laneEast, laneWest, path]
    [{ Build.sign 21 .regulatorySign [13] with code := some .bicyclesProhibited, conditions := some {} }]

/-- `branch_5` (compliant): a bicycle crosses a roadway that has no lanes, at right angles to the
    roadway's own direction. -/
def branch_5Trace : Trace :=
  ride (fun k => [crossingRoadway k]) [highway, roadway, path] []

/-- `branch_6` (violated): a bicycle rides along a lane-less roadway, parallel to its direction. -/
def branch_6Trace : Trace :=
  ride (fun k => [alongRoadway .bicycle k]) [highway, roadway, path] []

/-- `branch_7` (not_applicable): a bicycle stands still on the roadway (not riding). -/
def branch_7Trace : Trace :=
  ride (fun _ => [Build.user 1 [.bicycle] (m 0, cm (-250)) Build.east Q.zero ext])
    [highway, roadway, laneEast, laneWest, path] []

/-- A second bicycle lane 16 at y ∈ [4, 5.5], 1.5 m wide, overlapping the roadway's edge. -/
def edgePath : Structure :=
  { Build.rect 16 .bicycleLaneOrPath (m (-50)) (m 4) (m 50) (cm 550) with
    ways := some [10], lane := some { direction := some Build.east, width := some (cm 150) } }

/-- A rider travelling east at y = 4.5: on the roadway, in lane 14 (designated west) and on lane 16. -/
def alongEdge (k : Nat) : RoadUser :=
  Build.user 1 [.bicycle] (m (-10 + 5 * (k : Int)), cm 450) Build.east (Units.metresPerSecond 5) ext

/-- `branch_8` (violated): the bicycle lane 16 the rider is on is closed by a 'closed to traffic'
    regulatory sign, while the usable path 13 lies on the same highway; the rider travels along
    the roadway. -/
def branch_8Trace : Trace :=
  ride (fun k => [alongEdge k]) [highway, roadway, laneEast, laneWest, path, edgePath]
    [{ Build.sign 21 .regulatorySign [16] with code := some .closedToTraffic, conditions := some {} }]

/-- `branch_9` (violated): as branch_8, lane 16 closed by temporary traffic control instead. -/
def branch_9Trace : Trace :=
  ride (fun k => [alongEdge k]) [highway, roadway, laneEast, laneWest, path, edgePath]
    [Build.device 20 .temporaryTrafficControl [16]]

/-- `branch_10` (violated): as branch_8, lane 16 only 1 m wide. -/
def branch_10Trace : Trace :=
  ride (fun k => [alongEdge k]) [highway, roadway, laneEast, laneWest, path,
      { edgePath with lane := some { direction := some Build.east, width := some (m 1) } }] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_40_120"
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
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .violated ]

end TrafficSpecWitness.LVMC_11_40_120
