/-
  Witnesses for drv.motion.left_turn_from_onset.

  One passenger car, track 1, half-extent 2.25 m × 0.9 m × 0.75 m, at (0, 0) moving at 10 m/s,
  over seven instants one second apart (t = 0, 1000, …, 6000 ms). One intersection, a 30 m square
  around the car, for the junction of the narratives; no devices.
  The instance sets the turn angle to 60 deg, the yaw tolerance to 2 deg/s, the speed tolerance to
  0.1 m/s and the step bound to 2 s (the observations lie 1 s apart).
  Each yaw rate is held over the second before its scene, and each heading follows from it.
  - holds: the car drives straight east (yaw 0) at t = 0 and 1000 ms, yaws left at 3, 42 and
    45 deg/s at t = 2000, 3000 and 4000 ms (heading about 3°, about 45°, then north: a quarter
    turn), then drives straight north. turning_left rises at t = 2000 ms; the heading change since
    reads 0, 42, 87 deg at t = 2000, 3000, 4000 ms, so it first reaches the turn angle at
    t = 4000 ms: the window is that instant.
  - fails: the car drifts left for a lane change, yawing 10 deg/s left at t = 2000 ms and
    straightening at 10 deg/s right at t = 3000 ms; turning_left holds at t = 2000 ms only and the
    heading change since it never reaches the turn angle.
  - blind: the car is the turning one of `holds`, but the source declares kin.yaw_rate absent;
    the window is the recognition instant of `holds`.
-/
import TrafficSpec.Concepts.motion.left_turn_from_onset
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn_from_onset

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the turn angle 60 deg, the yaw tolerance 2 deg/s, the
    speed tolerance 0.1 m/s, the step bound 2 s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.left_turn_from_onset@w"
    concept := "drv.motion.left_turn_from_onset"
    literals := []
    nats := []
    params := [("turn_angle", .lit (Units.degrees 60) .degree),
               ("yaw_tolerance", .lit (Units.degrees 2) .degreePerSecond),
               ("speed_tolerance", .lit (Units.micrometresPerSecond 100000) .metrePerSecond),
               ("step", .lit (Units.seconds 2) .second)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car of every scene, moving at 10 m/s on `heading` with yaw rate `yaw` (deg/s). -/
def car (heading : Vec) (yaw : Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m 0, m 0) heading (Units.metresPerSecond 10) (cm 225, cm 90, cm 75))
    fun k => { k with yawRate := some yaw }

/-- The junction the car turns at. -/
def junction : Structure := Build.rect 10 .intersection (m (-15)) (m (-15)) (m 15) (m 15)

/-- The heading of the turning car at instant `k`: east, then a quarter turn left over three seconds
    (about 3°, about 45°, then north; rational unit vectors within 0.02° of those angles). -/
def turningHeading : Nat → Vec
  | 0 | 1 => Build.east
  | 2 => (Units.ratio 1443 1445, Units.ratio 76 1445)
  | 3 => (Units.ratio 4059 5741, Units.ratio 4060 5741)
  | _ => Build.north

/-- The yaw rate of the turning car at instant `k`, held over the second before it: 3, 42 and
    45 deg/s at instants 2, 3 and 4. -/
def turningYaw : Nat → Q
  | 2 => Units.degrees 3
  | 3 => Units.degrees 42
  | 4 => Units.degrees 45
  | _ => Units.degrees 0

/-- `holds` (compliant): a, moving, starts yawing left at a junction and keeps yawing until its heading has turned a quarter turn; at the observation where the heading change first reaches the turn angle the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (turningHeading k) (turningYaw k) ]
      [ junction ]
      [ ]

/-- The yaw rate of the lane-changing car at instant `k`: 10 deg/s left at instant 2, 10 deg/s
    right at instant 3 (straightening), none otherwise. -/
def driftYaw : Nat → Q
  | 2 => Units.degrees 10
  | 3 => Units.degrees (-10)
  | _ => Units.degrees 0

/-- The heading of the lane-changing car at instant `k`: east, about 10° left of east at instant 2
    (a rational unit vector within 0.01° of it), east again from instant 3. -/
def driftHeading : Nat → Vec
  | 2 => (Units.ratio 6351 6449, Units.ratio 1120 6449)
  | _ => Build.east

/-- `fails` (violated): a drifts left for a lane change; its yaw stops long before the heading change reaches the turn angle. -/
def failsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (driftHeading k) (driftYaw k) ]
      [ ]
      [ ]

/-- `blind` (unknown): a turns at a junction, but the source supplies no yaw rate. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.yaw_rate"]) holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (4000, 4000))
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (some (4000, 4000)) ]

end TrafficSpecWitness.Concepts.motion.left_turn_from_onset
