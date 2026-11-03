/-
  Witnesses for drv.motion.leftward_course_change.

  The instance: window = 4 s, heading_change_min = 45° — a quarter turn of course is well above what
  lane-keeping or a highway curve accumulates in four seconds, and well below the 88° the junction
  turn of the `holds` scene carries out.

  The geometry. One road user, track 1, a motor vehicle 4.8 m long and 1.8 m wide (half-extents
  2.4 m, 0.9 m, 0.75 m), alone in an empty scene: the body reads the user's yaw rate and nothing
  else, so no region and no device is built. Every trace is sampled once a second, from t = 0 s to
  t = 5 s; one second is half of the 4 s window, so every window inside the trace is adequately
  sampled. Each scenario is judged over t ∈ [4 s, 5 s]: those are the two observations whose 4 s
  window of history the trace covers (the oldest observation of the window at t = 4 s is exactly
  4 s behind, and at t = 5 s an observed instant precedes the window), and at the earlier
  observations the window would reach past the start of the trace.

  `holds`: the car enters the junction at 6 m/s heading east and yaws left at 22°/s over the four
  intervals t = 1 … 4 s — 88° of accumulated course change, a junction left turn on a 15.6 m
  radius — then runs straight on its new heading. Over the window behind t = 4 s the change is
  88°, behind t = 5 s it is 66° (the first second of the turn has dropped out of the window);
  both are at least 45°, so the concept holds at both judged observations.

  `fails`: the car runs a gentle left-hand curve at 15 m/s on a 382 m radius, yawing left at
  2.25°/s throughout — 9° of accumulated course change over the 4 s window at every observation,
  below the bound, so the concept is false at both judged observations.

  `blind`: the junction turn of `holds`, in a scene whose source does not observe `kin.yaw_rate`:
  the manifest declares the atom absent and the trace carries no yaw rate, so the heading change
  cannot be integrated and the body is unknown, for that atom and nothing else.

  Headings are written as rational vectors of unit length to four decimal places; positions to the
  centimetre, on the arc the yaw rate and the speed describe.
-/
import TrafficSpec.Concepts.motion.leftward_course_change
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.leftward_course_change

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A heading as a unit vector, its components written to four decimal places. -/
def dir (x y : Int) : Vec := (Units.ratio x 10000, Units.ratio y 10000)

/-- The half-extents of the car: 2.4 m, 0.9 m, 0.75 m. -/
def carExtent : Q × Q × Q := (cm 240, cm 90, cm 75)

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a 4 s window of history, and a quarter turn (45°) of
    accumulated leftward course change as the bound a turn must reach. -/
def inst : Concept.Instance :=
  { name := "drv.motion.leftward_course_change@w"
    concept := "drv.motion.leftward_course_change"
    literals := []
    nats := []
    params := [("heading_change_min", .lit (Units.degrees 45) .degree),
               ("window", .lit (Units.seconds 4) .second)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The instants each scenario is judged over: the two observations whose 4 s window of history the
    trace covers. -/
def judged : Timestamp × Timestamp := (4000, 5000)

/-- The junction turn, once a second: position (on a 15.6 m arc at 6 m/s) and heading. The course
    swings 22° per second from east over t = 0 … 4 s and holds afterwards. -/
def turnPose : Nat → Vec × Vec
  | 0 => ((cm 0,    cm 0),    dir 10000 0)
  | 1 => ((cm 586,  cm 114),  dir 9272 3746)
  | 2 => ((cm 1086, cm 439),  dir 7193 6947)
  | 3 => ((cm 1428, cm 927),  dir 4067 9135)
  | 4 => ((cm 1562, cm 1508), dir 349 9994)
  | 5 => ((cm 1583, cm 2108), dir 349 9994)
  | _ => ((cm 1604, cm 2708), dir 349 9994)

/-- The yaw rate of the junction turn: 22°/s to the left over the four intervals ending at
    t = 1 … 4 s, straight running before and after. -/
def turnYaw : Nat → Q
  | 0 => Q.zero
  | 1 => Units.degrees 22
  | 2 => Units.degrees 22
  | 3 => Units.degrees 22
  | 4 => Units.degrees 22
  | _ => Q.zero

/-- The gentle curve, once a second: position (on a 382 m arc at 15 m/s) and heading, turning 2.25°
    per second from east. -/
def curvePose : Nat → Vec × Vec
  | 0 => ((cm 0,    cm 0),   dir 10000 0)
  | 1 => ((cm 1501, cm 29),  dir 9992 393)
  | 2 => ((cm 2999, cm 118), dir 9969 785)
  | 3 => ((cm 4489, cm 264), dir 9931 1175)
  | 4 => ((cm 5974, cm 470), dir 9877 1564)
  | _ => ((cm 7453, cm 733), dir 9808 1951)

/-- The car of a scene: its pose, its speed, and its yaw rate where the source observes one. -/
def car (pose : Vec × Vec) (speed : Q) (yaw : Option Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pose.1 pose.2 speed carExtent)
    (fun k => { k with yawRate := yaw })

/-- `holds` (compliant): A car approaching a junction yaws left for four seconds, accumulating 88 degrees of leftward heading change over the window, above the turn bound. -/
def holdsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (turnPose k) (Units.metresPerSecond 6) (some (turnYaw k)) ]
      [ ]  -- no structure: the body reads the user's yaw rate only
      [ ]  -- devices

/-- `fails` (violated): A car follows a gentle left-hand curve, accumulating 9 degrees of leftward heading change over the window, below the turn bound. -/
def failsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (curvePose k) (Units.metresPerSecond 15) (some (Units.millidegrees 2250)) ]
      [ ]  -- no structure: the body reads the user's yaw rate only
      [ ]  -- devices

/-- `blind` (unknown): A car turns at a junction in a scene whose source declares the yaw rate absent, so the heading change cannot be integrated. -/
def blindTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (turnPose k) (Units.metresPerSecond 6) none ]
      [ ]  -- no structure: the body reads the user's yaw rate only
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := some judged }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.leftward_course_change
