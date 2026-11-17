/-
  Witnesses for drv.lane.heading_left_of_carrier.

  Geometry (all figures the witness's own): lane 100 is the rectangle (0,0)–(100,4) m with designated
  direction east. Road user 1 (a motor vehicle, half-extents 2.25 × 0.9 × 0.75 m) sits at (20,2) and
  moves at 10 m/s over three instants 1 s apart.
  - holds: heading (2,1), east-north-east; normalised, d·h = 2/√5 > 0 and the cross product
    1/√5 ≈ 0.447 > sin_tol = 0.1; speed 10 > 0.1.
  - fails: heading east; cross product 0 ≤ 0.1.
  - blind: as holds, with st.lane_direction unobserved: the direction decides, so unknown.
  Instance: sin_tol = 1/10 (ratio), speed_tol = 0.1 m/s.
-/
import TrafficSpec.Concepts.lane.heading_left_of_carrier
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.heading_left_of_carrier

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.lane.heading_left_of_carrier@w"
    concept := "drv.lane.heading_left_of_carrier"
    literals := []
    nats := []
    params := [("sin_tol", .lit (Units.ratio 1 10) .ratio),
               ("speed_tol", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Lane 100, designated direction east. -/
def laneR : Structure :=
  Build.lane 100 [(m 0, m 0), (m 100, m 0), (m 100, m 4), (m 0, m 4)] Build.east

/-- East-north-east: (2, 1). -/
def ene : Vec := (m 2, m 1)

def userA (h : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 20, m 2) h (Units.metresPerSecond 10) (cm 225, cm 90, cm 75)

/-- `holds` (compliant): a moves well above speed_tol in lane r whose designated direction points east; a's heading points east-north-east, turned counter-clockwise from r's direction by clearly more than the angle whose sine is sin_tol: the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [userA ene] [laneR] []

/-- `fails` (violated): a moves in r with its heading aligned with r's designated direction (cross product below sin_tol): the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [userA Build.east] [laneR] []

/-- `blind` (unknown): a moves turned to the left of the lane, but the source does not observe st.lane_direction for r. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [userA ene] [laneR] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    regions := [("r", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.lane.heading_left_of_carrier
