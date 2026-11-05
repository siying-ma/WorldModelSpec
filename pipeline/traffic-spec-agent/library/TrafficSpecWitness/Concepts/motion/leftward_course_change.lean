/-
  Witnesses for drv.motion.leftward_course_change.

  One body, track 1, a car 5 m long and 2 m wide travelling at 5 m/s, in an empty world: no region
  and no device is read, because the concept reads the body's own heading change and its speed
  alone. Each trace is seven instants one second apart (t = 0 … 6000 ms), the car running through a
  junction turn; every scenario speaks about the last instant (`window` = [6000, 6000]), the one
  whose six-second window behind is covered by the trace — at the earlier instants the window
  reaches past the start of the trace and the heading change is unknown for that reason alone.

  The heading change the concept reads is integrated from the yaw rate (the rate at a scene is held
  over the interval before it), so the yaw rates at t = 1000 … 6000 ms are what the manoeuvre
  amounts to. The heading written at each instant is the nearest exact rational unit vector to the
  course the integrated yaw rate gives (no rotation by a whole number of degrees has rational
  components); the positions follow an arc of about 18 m radius, the radius 5 m/s and a turn of
  about 15 deg/s make.

  The instance's own figures: a window of 6 s, the time within which such a manoeuvre is completed;
  a smallest course change of 30 deg, below which a change of heading is lane-keeping or a bend
  taken; a largest of 135 deg, above which the road user has turned about; and a motion tolerance
  of 1 m/s, below which a reading counts as no travel.

    holds — the car turns left: yaw rates 16, 16, 16, 16, 14, 14 deg/s over the six seconds behind,
            a heading change of +92 deg, inside [30, 135]; its speed is 5 m/s, above the
            tolerance, at every observation of the window.
    fails — the same car turns right: yaw rates −15 deg/s throughout, a heading change of −90 deg,
            which is below the smallest leftward change, so no leftward change of course is read.
    blind — the left turn again with kin.yaw_rate unobserved (the field is `none` and the manifest
            declares the atom absent), so prim.heading_change is unknown over the window.
-/
import TrafficSpec.Concepts.motion.leftward_course_change
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.leftward_course_change

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.leftward_course_change@w"
    concept := "drv.motion.leftward_course_change"
    literals := []
    nats := []
    params :=
      [ ("turn_window", .lit (Units.seconds 6) .second)
      , ("min_course_change", .lit (Units.degrees 30) .degree)
      , ("max_course_change", .lit (Units.degrees 135) .degree)
      , ("motion_speed_tolerance", .lit (Units.metresPerSecond 1) .metrePerSecond) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car at an instant: 5 m long, 2 m wide, travelling at 5 m/s with the pose given, and the
    yaw rate this scenario observes of it. -/
def car (pos : Vec) (heading : Vec) (yaw : Option Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond 5) (cm 250, cm 100, cm 100))
    fun k => { k with yawRate := yaw }

/-- The pose of the left turn at instant `k`: position on the arc and heading, the courses
    0, 16, 31, 46, 62, 77, 90 deg from east (the nearest exact rational unit vectors to the
    courses the yaw rates below integrate to). -/
def leftPose (k : Nat) : Vec × Vec :=
  match k with
  | 0 => ((cm 0, cm 0), (Units.ratio 1 1, Units.ratio 0 1))
  | 1 => ((cm 504, cm 72), (Units.ratio 24 25, Units.ratio 7 25))
  | 2 => ((cm 914, cm 249), (Units.ratio 56 65, Units.ratio 33 65))
  | 3 => ((cm 1303, cm 559), (Units.ratio 20 29, Units.ratio 21 29))
  | 4 => ((cm 1588, cm 953), (Units.ratio 8 17, Units.ratio 15 17))
  | 5 => ((cm 1756, cm 1405), (Units.ratio 9 41, Units.ratio 40 41))
  | _ => ((cm 1800, cm 1800), (Units.ratio 0 1, Units.ratio 1 1))

/-- The pose of the right turn at instant `k`: the left turn's, mirrored about the car's first
    course, so the courses run 0, −16, −31, −46, −62, −77, −90 deg from east. -/
def rightPose (k : Nat) : Vec × Vec :=
  let (p, h) := leftPose k
  ((p.1, Q.neg p.2), (h.1, Q.neg h.2))

/-- The yaw rates of the left turn: none before the manoeuvre, then 16, 16, 16, 16, 14, 14 deg/s
    over the six seconds of the window, a heading change of +92 deg. -/
def leftYaw (k : Nat) : Option Q :=
  if k == 0 then some (Units.degrees 0)
  else if k ≤ 4 then some (Units.degrees 16)
  else some (Units.degrees 14)

/-- The yaw rates of the right turn: −15 deg/s over each of the six seconds of the window, a
    heading change of −90 deg. -/
def rightYaw (k : Nat) : Option Q :=
  if k == 0 then some (Units.degrees 0) else some (Units.degrees (-15))

/-- Seven instants a second apart, the car in the pose and with the yaw rate given. -/
def turnTrace (pose : Nat → Vec × Vec) (yaw : Nat → Option Q) : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (pose k).1 (pose k).2 (yaw k) ]
      [ ]  -- no structure is read
      [ ]  -- devices

/-- `holds` (compliant): A car travelling at 5 m/s turns left through 92 degrees over 6 s at a junction, its speed above the motion tolerance throughout. -/
def holdsTrace : Trace := turnTrace leftPose leftYaw

/-- `fails` (violated): The same car turns right through 90 degrees: the signed heading change is negative, so no leftward change of course is read. -/
def failsTrace : Trace := turnTrace rightPose rightYaw

/-- `blind` (unknown): The source declares kin.yaw_rate absent, so prim.heading_change is unknown over the window. -/
def blindTrace : Trace := turnTrace leftPose fun _ => none

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := some (6000, 6000) }   -- the one instant whose six-second window behind the trace covers

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.leftward_course_change
