/-
  Witnesses for drv.motion.turning_left.

  One car, track 1, half-extents 2.25 m × 0.9 m × 0.75 m, observed at a single instant (t = 0),
  heading east at 5 m/s at (0, 1.75) in a lane 3.5 m wide (x ∈ [−10, 100], y ∈ [0, 3.5]). One
  instant per trace: the body reads the observation only, and a yaw rate of ±15 deg/s held over
  an interval would turn the heading by an angle no exact rational heading vector reaches.
  The instance sets speed_floor to 0.1 m/s and yaw_floor to 0.5 deg/s.
  - holds: the car yaws at +15 deg/s (to its left), above 0.5 deg/s, while moving at 5 m/s.
  - fails: the car yaws at −15 deg/s (to its right), not above 0.5 deg/s.
  - blind: the car moves at 5 m/s and its yaw rate is not observed (kin.yaw_rate declared absent
    and left unset): moving holds, so the yaw-rate comparison alone decides, and it is unknown.
-/
import TrafficSpec.Concepts.motion.turning_left
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turning_left

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: speed_floor is 0.1 m/s, yaw_floor 0.5 deg/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turning_left@w"
    concept := "drv.motion.turning_left"
    literals := []
    nats := []
    params := [("speed_floor", .lit (Units.micrometresPerSecond 100000) .metrePerSecond),
               ("yaw_floor", .lit (Units.millidegrees 500) .degreePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- A lane heading east, x ∈ [−10, 100], y ∈ [0, 3.5]. -/
def eastLane : Structure :=
  Build.lane 20 [(m (-10), m 0), (m 100, m 0), (m 100, cm 350), (m (-10), cm 350)] Build.east

/-- The car at instant `k`, moving east at 5 m/s, with the yaw rate given (none: not observed). -/
def car (k : Nat) (yaw : Option Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m (5 * Int.ofNat k), cm 175) Build.east
      (Units.metresPerSecond 5) carExtent)
    fun kin => { kin with yawRate := yaw }

/-- `holds` (compliant): x has kin.speed 5 m/s and kin.yaw_rate 15 deg/s. -/
def holdsTrace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k (some (Units.degrees 15)) ]
      [ eastLane ]
      [ ]

/-- `fails` (violated): x has kin.speed 5 m/s and kin.yaw_rate -15 deg/s (turning right). -/
def failsTrace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k (some (Units.degrees (-15))) ]
      [ eastLane ]
      [ ]

/-- `blind` (unknown): x has kin.speed 5 m/s and kin.yaw_rate is not observed. -/
def blindTrace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k none ]
      [ eastLane ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.turning_left
