/-
  Witnesses for drv.motion.right_turn_from_onset.

  One passenger car, track 1, half-extent 2.25 m × 0.9 m × 0.75 m, at 8 m/s throughout, over six
  instants one second apart (t = 0 … 5000 ms), its heading turning between instants as its yaw rate
  says (rational unit vectors from Pythagorean triples, approximate: the rate at a scene turns the
  heading over the interval before it, so the heading changes at every scene whose rate is not
  zero). No devices.
  The instance sets the turn angle to 60°, the yaw tolerance to 2 deg/s, the speed tolerance to
  0.1 m/s and the step bound to 2 s (the instants are 1 s apart).
  - holds: the car crosses an intersection (rectangle (−5, −30)–(30, 10)) heading east with no yaw at
    t = 0, then yaws at −30 deg/s at t = 1000 … 4000 (turning_right rises at t = 1000) and goes
    straight south at t = 5000. The heading change since the onset is 0, −30, −60, −90 at
    t = 1000 … 4000: it first reaches −60 at t = 3000, the window of the witness.
  - fails: the car moves east along a roadway (rectangle (−10, −8)–(60, 8)) and changes lane to the
    right: yaw 0 at t = 0, −5 deg/s at t = 1000 and 2000 (heading change −5 at t = 2000), then
    +5 deg/s and 0 to straighten. The heading change never reaches −60; the concept is false at
    every instant.
  - blind: the trace of `holds`, with kin.yaw_rate declared absent; judged over t = 1000 … 5000
    (the first instant's `rises` looks before the recording).
  Only the speed and the yaw rate are read by the body.
-/
import TrafficSpec.Concepts.motion.right_turn_from_onset
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.right_turn_from_onset

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: turn angle 60°, yaw tolerance 2 deg/s, speed
    tolerance 0.1 m/s, step bound 2 s. -/
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

/-- The car at position `p`, at 8 m/s with heading `h` and yaw rate `yaw` (deg/s). -/
def car (p : Vec) (h : Vec) (yaw : Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] p h (Units.metresPerSecond 8) (cm 225, cm 90, cm 75))
    fun kin => { kin with yawRate := some yaw }

/-- The right turn at the junction: straight east, then −30 deg/s for four seconds, then south. -/
def turnCar (k : Nat) : RoadUser :=
  match k with
  | 0 => car (m 0, m 0) Build.east (Units.degrees 0)
  | 1 => car (m 8, m 0) (Units.ratio 12 13, Units.ratio (-5) 13) (Units.degrees (-30))
  | 2 => car (m 15, m (-3)) (Units.ratio 3 5, Units.ratio (-4) 5) (Units.degrees (-30))
  | 3 => car (m 20, m (-9)) (Units.ratio 5 13, Units.ratio (-12) 13) (Units.degrees (-30))
  | 4 => car (m 22, m (-17)) Build.south (Units.degrees (-30))
  | _ => car (m 22, m (-25)) Build.south (Units.degrees 0)

/-- The lane change: a short yaw to the right, then back, the heading change about 5° at most. -/
def laneChangeCar (k : Nat) : RoadUser :=
  match k with
  | 0 => car (m 0, m 2) Build.east (Units.degrees 0)
  | 1 => car (m 8, m 2) (Units.ratio 52440 52442, Units.ratio (-458) 52442) (Units.degrees (-5))
  | 2 => car (m 16, m 1) (Units.ratio 13224 13226, Units.ratio (-230) 13226) (Units.degrees (-5))
  | 3 => car (m 24, m 0) (Units.ratio 52440 52442, Units.ratio (-458) 52442) (Units.degrees 5)
  | 4 => car (m 32, m (-1)) Build.east (Units.degrees 5)
  | _ => car (m 40, m (-1)) Build.east (Units.degrees 0)

def junction : Structure := Build.rect 10 .intersection (m (-5)) (m (-30)) (m 30) (m 10)
def road : Structure := Build.rect 20 .roadway (m (-10)) (m (-8)) (m 60) (m 8)

/-- `holds` (compliant): a, moving, starts yawing right at a junction and keeps yawing until its heading has turned a quarter turn to the right; the concept holds where the change first reaches the negative of the turn angle. -/
def holdsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turnCar k ]
      [ junction ]
      [ ]

/-- `fails` (violated): a drifts right for a lane change; its yaw stops long before the heading change reaches the turn angle. -/
def failsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ laneChangeCar k ]
      [ road ]
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
  [ witness "holds" holdsTrace .compliant [] (some (3000, 3000))
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (some (1000, 5000)) ]

end TrafficSpecWitness.Concepts.motion.right_turn_from_onset
