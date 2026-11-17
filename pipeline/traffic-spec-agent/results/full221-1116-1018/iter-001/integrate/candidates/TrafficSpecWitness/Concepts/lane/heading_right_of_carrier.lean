/-
  Witnesses for drv.lane.heading_right_of_carrier.

  Geometry (the witness's own figures): lane 100 is the rectangle x ∈ [0, 100] m, y ∈ [0, 4] m,
  designated direction east (1, 0). Road user 1 (a motor vehicle, half-extent 2 × 1 × 1 m) stands
  at (20, 2) m, inside the lane, at speed 10 m/s, three observations 1 s apart.
  Instance: sin_tol = 1/10 (about 5.7°), speed_tol = 1 m/s.
  - holds: heading (4/5, −3/5), east-south-east, a unit vector: d·h = 4/5 > 0 and
    d×h = 1·(−3/5) − 0·(4/5) = −3/5 < −1/10, speed 10 > 1 → true at every instant.
  - fails: heading east (1, 0): d×h = 0, not below −1/10 → false.
  - blind: as holds, with st.lane_direction unobserved by the manifest → unknown.
-/
import TrafficSpec.Concepts.lane.heading_right_of_carrier
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.heading_right_of_carrier

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100 (lane 100 is a structure of every trace)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.lane.heading_right_of_carrier@w"
    concept := "drv.lane.heading_right_of_carrier"
    literals := []
    nats := []
    params := [("sin_tol", .lit (Units.ratio 1 10) .ratio),
               ("speed_tol", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Lane 100: x ∈ [0, 100], y ∈ [0, 4], designated direction east. -/
def laneR : Structure :=
  Build.lane 100 [(m 0, m 0), (m 100, m 0), (m 100, m 4), (m 0, m 4)] Build.east

/-- East-south-east: the unit vector (4/5, −3/5), turned clockwise from east by about 36.9°. -/
def eastSouthEast : Vec := (Units.ratio 4 5, Units.ratio (-3) 5)

def car (heading : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 20, m 2) heading (Units.metresPerSecond 10) (m 2, m 1, m 1)

/-- `holds` (compliant): a moves well above speed_tol in lane r whose designated direction points east; a's heading points east-south-east, turned clockwise from r's direction by clearly more than the angle whose sine is sin_tol: the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car eastSouthEast ]
      [ laneR ]
      [ ]

/-- `fails` (violated): a moves in r with its heading aligned with r's designated direction (cross product above minus sin_tol): the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car Build.east ]
      [ laneR ]
      [ ]

/-- `blind` (unknown): a moves turned to the right of the lane, but the source does not observe st.lane_direction for r. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car eastSouthEast ]
      [ laneR ]
      [ ]

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

end TrafficSpecWitness.Concepts.lane.heading_right_of_carrier
