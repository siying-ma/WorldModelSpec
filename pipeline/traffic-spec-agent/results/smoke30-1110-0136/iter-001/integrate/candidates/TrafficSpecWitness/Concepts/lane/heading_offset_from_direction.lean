/-
  Witnesses for drv.lane.heading_offset_from_direction.

  Geometry: one lane, region 100, the rectangle x ∈ [-50, 50] m, y ∈ [-2, 2] m, designated
  direction +x (east). Vehicle 1 (a motor vehicle, half-extents 2.5 × 1 × 0.75 m) stands at the
  origin, at rest, over three instants one second apart.
  - holds: heading (0.985, 0.174), about ten degrees to the left of east; the value is about
    0.174 (the sine of ten degrees is 0.1736), inside the instance's bounds [0.15, 0.2].
  - fails: heading east, along the lane direction; the value is zero, below 0.15.
  - blind: the holds scene, with st.lane_direction unobserved.
  The instance's bounds 0.15 and 0.2 are the witness's own figures, from the record's narrative.
-/
import TrafficSpec.Concepts.lane.heading_offset_from_direction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.heading_offset_from_direction

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: c ↦ 100 (the lane, a structure of every trace)

/-- The instance every scenario speaks about: no literal formals, no parameters; the value is
    expected between 0.15 and 0.2. -/
def inst : Concept.Instance :=
  { name := "drv.lane.heading_offset_from_direction@w"
    concept := "drv.lane.heading_offset_from_direction"
    literals := []
    nats := []
    params := []
    bounds := some (.lit (Units.ratio 15 100) .ratio, .lit (Units.ratio 20 100) .ratio)
  }

def instances : List Concept.Instance := [inst]

/-- The lane, direction east. -/
def laneC : Structure :=
  Build.lane 100 [(m (-50), m (-2)), (m 50, m (-2)), (m 50, m 2), (m (-50), m 2)] Build.east

/-- About ten degrees to the left of east: (cos 10°, sin 10°) to three places. -/
def tenLeft : Vec := (Units.ratio 985 1000, Units.ratio 174 1000)

def vehicle (h : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m 0) h (Units.metresPerSecond 0) (cm 250, m 1, cm 75)

/-- `holds` (compliant): A vehicle in a lane whose direction is +x points ten degrees to the left of it; the instance bounds the value between 0.15 and 0.2 and it lies there. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ vehicle tenLeft ]
      [ laneC ]
      [ ]

/-- `fails` (violated): The vehicle points along the lane direction; the value is zero, outside the instance's bounds 0.15 to 0.2. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ vehicle Build.east ]
      [ laneC ]
      [ ]

/-- `blind` (unknown): The source does not observe the lane's designated direction. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ vehicle tenLeft ]
      [ laneC ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("c", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.lane.heading_offset_from_direction
