/-
  Witnesses for drv.motion.slowing.

  One road user, track 1, a motor vehicle 4.6 m long and 1.8 m wide, drives east along y = 0 at
  8 m/s, heading east, observed at t = 0, 1, 2 s at x = 8·k m. No region and no device.
  - holds: kin.accel_longitudinal −2 m/s² at every instant: forward component 8 m/s > 0.1 m/s and
    −2 m/s² < −0.1 m/s².
  - fails: kin.accel_longitudinal 0 m/s²: 0 is not below −0.1 m/s².
  - blind: the same scene with the longitudinal acceleration unobserved (the field `none` and the
    atom masked in the manifest): the speed conjunct holds, so the masked atom decides.
  The instance's figures, the witness's own: speed_floor 0.1 m/s, decel_floor 0.1 m/s².
-/
import TrafficSpec.Concepts.motion.slowing
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.slowing

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: speed_floor 0.1 m/s, decel_floor 0.1 m/s². -/
def inst : Concept.Instance :=
  { name := "drv.motion.slowing@w"
    concept := "drv.motion.slowing"
    literals := []
    nats := []
    params := [("speed_floor", .lit (Units.micrometresPerSecond 100000) .metrePerSecond),
               ("decel_floor", .lit (Units.micrometresPerSecondSq 100000) .metrePerSecondSq)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Track 1 heading east at 8 m/s, at x = 8·k m, with the given longitudinal acceleration. -/
def car (k : Nat) (accel : Option Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m (8 * k), m 0) Build.east (Units.metresPerSecond 8)
      (cm 230, cm 90, cm 75))
    fun kn => { kn with accelLongitudinal := accel }

/-- `holds` (compliant): x moves forward at 8 m/s along its heading with kin.accel_longitudinal -2.0 m/s². -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k (some (Units.metresPerSecondSq (-2)))] [] []

/-- `fails` (violated): x moves forward at 8 m/s with kin.accel_longitudinal 0.0 m/s². -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k (some (Units.metresPerSecondSq 0))] [] []

/-- `blind` (unknown): x moves forward at 8 m/s and kin.accel_longitudinal is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k none] [] []

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
  , witness "blind" blindTrace (.unknown []) ["kin.accel_longitudinal"] ]

end TrafficSpecWitness.Concepts.motion.slowing
