/-
  Witnesses for drv.motion.turning_left.

  One road user, track 1, a motor vehicle 4.5 m long and 1.8 m wide, observed at the origin
  heading north at 10 m/s; no structures, no
  devices. Each trace is that one observation, t = 0: the yaw rate is held over the interval before a
  scene, so a second scene would have to carry a heading rotated by 12°, which no rational unit vector
  states exactly; the concept reads one observation, and one suffices. The instance gives `tol`
  2 deg/s.
    holds: the yaw rate is +12 deg/s (turning left, above tol).
    fails: the yaw rate is -12 deg/s (turning right).
    blind: the scene is the holds scene, +12 deg/s, but kin.yaw_rate is masked by the manifest.
-/
import TrafficSpec.Concepts.motion.turning_left
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turning_left

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: `tol` 2 deg/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turning_left@w"
    concept := "drv.motion.turning_left"
    literals := []
    nats := []
    params := [("tol", .lit (Units.degrees 2) .degreePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Track 1 at the origin heading north at 10 m/s with the given yaw rate (deg/s). -/
def carX (yaw : Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m 0, m 0) Build.north (Units.metresPerSecond 10)
      (cm 225, cm 90, cm 75))
    (fun k => { k with yawRate := some yaw })

/-- `holds` (compliant): x's kin.yaw_rate is +12 deg/s with tol 2 deg/s: turning left. -/
def holdsTrace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ carX (Units.degrees 12) ]
      [ ]
      [ ]

/-- `fails` (violated): x's kin.yaw_rate is -12 deg/s: turning right. -/
def failsTrace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ carX (Units.degrees (-12)) ]
      [ ]
      [ ]

/-- `blind` (unknown): kin.yaw_rate is not observed for x. -/
def blindTrace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ carX (Units.degrees 12) ]
      [ ]
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
