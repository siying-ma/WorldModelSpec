/-
  Witnesses for drv.road.opposed_directions.

  Geometry: c1 (region 100) is a lane 100 m long and 4 m wide, x ∈ [0, 100], y ∈ [0, 4],
  designated east. In `holds` c2 (region 101) is the lane beside it, y ∈ [4, 8], designated west
  (dot product −1). In `fails` c2 is a lane x ∈ [48, 52], y ∈ [−50, 50] crossing c1 at a right
  angle, designated north (dot product 0). In `blind` c2 is the westward lane's footprint with no
  lane record, so it carries no designated direction. One car (track 1) stands still on c1 at
  (10, 2), heading east, in every scene; three instants, one second apart.
  The instance gives opposed_cosine 9/10 (opposite within about 25.8°).
-/
import TrafficSpec.Concepts.road.opposed_directions
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.road.opposed_directions

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: (no track formal)
-- Formals ↦ regions: c1 ↦ 100, c2 ↦ 101

/-- The instance every scenario speaks about: opposed_cosine is 9/10. -/
def inst : Concept.Instance :=
  { name := "drv.road.opposed_directions@w"
    concept := "drv.road.opposed_directions"
    literals := []
    nats := []
    params := [("opposed_cosine", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car standing on c1. -/
def car : RoadUser :=
  Build.user 1 [.motorVehicle] (m 10, m 2) Build.east (Units.metresPerSecond 0) (m 2, cm 90, cm 75)

def laneC1 : Structure :=
  Build.lane 100 [(m 0, m 0), (m 100, m 0), (m 100, m 4), (m 0, m 4)] Build.east

def laneWest : Structure :=
  Build.lane 101 [(m 0, m 4), (m 100, m 4), (m 100, m 8), (m 0, m 8)] Build.west

def laneNorth : Structure :=
  Build.lane 101 [(m 48, m (-50)), (m 52, m (-50)), (m 52, m 50), (m 48, m 50)] Build.north

/-- c2 as a lane region with no lane record: no designated direction in the source. -/
def laneUndirected : Structure :=
  Build.rect 101 .lane (m 0) (m 4) (m 100) (m 8)

/-- `holds` (compliant): c1 has st.lane_direction (1, 0) and c2 (-1, 0). -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [car] [laneC1, laneWest] []

/-- `fails` (violated): c1 has st.lane_direction (1, 0) and c2 (0, 1): the carriers cross at a right angle. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [car] [laneC1, laneNorth] []

/-- `blind` (unknown): c2 carries no st.lane_direction in the source. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [car] [laneC1, laneUndirected] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := []
    regions := [("c1", 100), ("c2", 101)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.road.opposed_directions
