/-
  Witnesses for drv.lane.heading_left_of_carrier.

  Geometry (every figure here is the witness's own):
    - lane 100, the strip y ∈ [-2, 2] m from x = 0 to x = 200 m, its designated direction east
      (+x).
    - road user a = track 1, a motor vehicle of half-extent 2 m × 1 m × 1 m at (50, 0) m, moving
      at 10 m/s in every scene, three scenes one second apart (t = 0, 1000, 2000 ms).
      holds/blind: heading (0.9848, 0.1736), about ten degrees counter-clockwise from east:
                   dot 0.9848 > 0, cross 0.1736 > sin_tol.
      fails:       heading (0.9848, −0.1736), about ten degrees clockwise from east:
                   cross −0.1736, not above sin_tol.
  Instance: sin_tol = 1/20 (about 2.9 degrees), speed_tol = 1 m/s.
  blind masks kin.heading: the dot and cross products cannot be computed, the speed and the
  direction being observed and deciding nothing against it.
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
    params := [("sin_tol", .lit (Units.ratio 1 20) .ratio), ("speed_tol", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Lane 100, running east. -/
def laneR : Structure := Build.lane 100 [(m 0, m (-2)), (m 200, m (-2)), (m 200, m 2), (m 0, m 2)] Build.east

def half : Q × Q × Q := (m 2, m 1, m 1)

/-- About ten degrees counter-clockwise from east. -/
def leftTen : Vec := (Units.ratio 9848 10000, Units.ratio 1736 10000)

/-- About ten degrees clockwise from east. -/
def rightTen : Vec := (Units.ratio 9848 10000, Units.ratio (-1736) 10000)

def userA (h : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 50, m 0) h (Units.metresPerSecond 10) half

/-- `holds` (compliant): r's direction points along x; a moves at 10 m/s with its heading turned about ten degrees counter-clockwise from x: dot positive, cross above sin_tol. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [userA leftTen] [laneR] []

/-- `fails` (violated): r's direction points along x; a moves at 10 m/s with its heading turned about ten degrees clockwise from x: the cross product is negative. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [userA rightTen] [laneR] []

/-- `blind` (unknown): As holds, but a's heading is not observed on the source. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [userA leftTen] [laneR] []

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
  , witness "blind" blindTrace (.unknown []) ["kin.heading"] ]

end TrafficSpecWitness.Concepts.lane.heading_left_of_carrier
