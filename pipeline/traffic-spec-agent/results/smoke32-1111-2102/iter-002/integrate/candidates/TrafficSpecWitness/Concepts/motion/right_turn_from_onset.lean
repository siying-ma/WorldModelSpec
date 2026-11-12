/-
  Witnesses for drv.motion.right_turn_from_onset.

  One passenger car, track 1, half-extent 2.25 m × 0.9 m × 0.75 m, at (0, 0) moving at 10 m/s,
  over ten instants one second apart (t = 0, 1000, …, 9000 ms). One intersection, a 30 m square
  around the car, for the junction of the narratives; no devices.
  The instance sets the turn angle to 60 deg, the yaw tolerance to 2 deg/s, the speed tolerance to
  0.1 m/s and the step bound to 2 s (the observations lie 1 s apart).
  Each yaw rate is held over the second before its scene, and each heading follows from it
  (degrees from east, left positive; rational unit vectors within 0.1° of the angles named).
  - holds: the car drives straight east (yaw 0) at t = 0 and 1000 ms, yaws right at 10 and
    20 deg/s at t = 2000 and 3000 ms (heading −10°, −30°), straightens (yaw 0) at t = 4000 ms, then
    yaws right again at 5, 40 and 50 deg/s at t = 5000, 6000 and 7000 ms (heading −35°, −75°,
    −125°: a quarter turn from the second onset), then drives straight on. turning_right rises at
    t = 2000 ms and again at t = 5000 ms; the heading change since the second rise reads 0, −40,
    −90 deg at t = 5000, 6000, 7000 ms, so it first reaches −60 deg at t = 7000 ms: the window is
    that instant. Counted from the first rise it would read −65 deg already at t = 6000 ms.
  - fails: the car drifts right for a lane change, yawing 10 deg/s right at t = 2000 ms and
    straightening at 10 deg/s left at t = 3000 ms; turning_right holds at t = 2000 ms only and the
    heading change since it never reaches −60 deg.
  - blind: the car is the turning one of `holds`, but the source declares kin.yaw_rate absent;
    the window is the recognition instant of `holds`.
-/
import TrafficSpec.Concepts.motion.right_turn_from_onset
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.right_turn_from_onset

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the turn angle 60 deg, the yaw tolerance 2 deg/s, the
    speed tolerance 0.1 m/s, the step bound 2 s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.right_turn_from_onset@w"
    concept := "drv.motion.right_turn_from_onset"
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

/-- The heading of the turning car at instant `k`: east, −10°, −30°, −30°, −35°, −75°, then −125°
    (rational unit vectors within 0.1° of those angles). -/
def turningHeading : Nat → Vec
  | 0 | 1 => Build.east
  | 2 => (Units.ratio 6351 6449, Units.ratio (-1120) 6449)
  | 3 | 4 => (Units.ratio 2911 3361, Units.ratio (-1680) 3361)
  | 5 => (Units.ratio 325 397, Units.ratio (-228) 397)
  | 6 => (Units.ratio 380 1469, Units.ratio (-1419) 1469)
  | _ => (Units.ratio (-1679) 2929, Units.ratio (-2400) 2929)

/-- The yaw rate of the turning car at instant `k`, held over the second before it: a first brief
    stretch at −10 and −20 deg/s (instants 2, 3), straight at instant 4, a second stretch at −5,
    −40 and −50 deg/s (instants 5, 6, 7). -/
def turningYaw : Nat → Q
  | 2 => Units.degrees (-10)
  | 3 => Units.degrees (-20)
  | 5 => Units.degrees (-5)
  | 6 => Units.degrees (-40)
  | 7 => Units.degrees (-50)
  | _ => Units.degrees 0

/-- `holds` (compliant): a, moving, yaws right briefly and straightens, then starts yawing right again at a junction and keeps yawing until its heading has turned a quarter turn to the right from that second onset; the concept holds where the change since the second onset first reaches the negative of the turn angle, not where the first and second stretches together would. -/
def holdsTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (turningHeading k) (turningYaw k) ]
      [ junction ]
      [ ]

/-- The yaw rate of the lane-changing car at instant `k`: 10 deg/s right at instant 2, 10 deg/s
    left at instant 3 (straightening), none otherwise. -/
def driftYaw : Nat → Q
  | 2 => Units.degrees (-10)
  | 3 => Units.degrees 10
  | _ => Units.degrees 0

/-- The heading of the lane-changing car at instant `k`: east, about 10° right of east at instant 2
    (a rational unit vector within 0.01° of it), east again from instant 3. -/
def driftHeading : Nat → Vec
  | 2 => (Units.ratio 6351 6449, Units.ratio (-1120) 6449)
  | _ => Build.east

/-- `fails` (violated): a drifts right for a lane change; its yaw stops long before the heading change reaches the turn angle. -/
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
  [ witness "holds" holdsTrace .compliant [] (some (7000, 7000))
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (some (7000, 7000)) ]

end TrafficSpecWitness.Concepts.motion.right_turn_from_onset
