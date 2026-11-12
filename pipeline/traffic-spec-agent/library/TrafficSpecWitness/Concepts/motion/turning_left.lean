/-
  Witnesses for drv.motion.turning_left.

  One passenger car, track 1, half-extent 2.25 m × 0.9 m × 0.75 m, at (0, 0) moving at 10 m/s,
  over three instants one second apart (t = 0, 1000, 2000 ms). No structures, no devices.
  The instance sets the yaw tolerance to 2 deg/s and the speed tolerance to 0.1 m/s.
  - holds: the moving car's yaw rate reads 90 deg/s (leftward) at every instant, its heading
    turning east → north → west accordingly.
  - fails: the moving car drives straight east, its yaw rate reading 0 deg/s at every instant.
  - blind: the car is the turning one of `holds`, but the source declares kin.yaw_rate absent.
-/
import TrafficSpec.Concepts.motion.turning_left
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turning_left

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the yaw tolerance 2 deg/s, the speed tolerance 0.1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turning_left@w"
    concept := "drv.motion.turning_left"
    literals := []
    nats := []
    params := [("yaw_tolerance", .lit (Units.degrees 2) .degreePerSecond),
               ("speed_tolerance", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car of every scene, moving at 10 m/s on `heading` with yaw rate `yaw` (deg/s). -/
def car (heading : Vec) (yaw : Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m 0, m 0) heading (Units.metresPerSecond 10) (cm 225, cm 90, cm 75))
    fun k => { k with yawRate := some yaw }

/-- The heading of the turning car at instant `k`: a quarter turn to the left per second. -/
def turningHeading : Nat → Vec
  | 0 => Build.east
  | 1 => Build.north
  | _ => Build.west

/-- `holds` (compliant): A moving vehicle's yaw rate is leftward above the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (turningHeading k) (Units.degrees 90) ]
      [ ]
      [ ]

/-- `fails` (violated): A moving vehicle drives straight with a yaw rate near zero. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car Build.east (Units.degrees 0) ]
      [ ]
      [ ]

/-- `blind` (unknown): The source declares kin.yaw_rate absent. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.yaw_rate"]) holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.turning_left
