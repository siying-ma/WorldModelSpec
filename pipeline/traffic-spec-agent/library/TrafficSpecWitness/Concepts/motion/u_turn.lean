/-
  Witnesses for drv.motion.u_turn.

  One car, track 1, is the formal `u` in all three scenarios. Every figure here is the witness's
  own, including the three the instance gives the formal parameters:

    - `u_turn_window` = 8 s: long enough to hold a whole swing round, and, had the car made the
      turning in three movements, long enough to hold all three;
    - `u_turn_min_heading_change` = 150 deg and `u_turn_max_heading_change` = 210 deg: a band of
      thirty degrees either side of a half turn.

  Each trace is fourteen observations one second apart, t = 0 … 13 s, and every scenario is judged
  over t = 10 s … 12 s. The three leading seconds of straight running before the turning begins
  are what makes the eight-second window behind those instants covered rather than truncated, and
  one second between observations is well inside the half-window the sampling-adequacy test asks
  for.

  The turning (`holds` and `blind`): the car runs east along the centre of a wide street at
  2.6 m/s, reaches x = 20 m at t = 4 s, and from t = 5 s to t = 10 s swings left at 30 deg/s
  through a quarter-circle-and-again of radius 5 m about the point (20 m, 5 m) — thirty degrees in
  each of six seconds, a hundred and eighty in all — arriving at (20 m, 10 m) heading west at
  t = 10 s and driving back the way it came. Six contributions of 30 deg · 1 s lie inside the
  eight-second window behind t = 10, 11 and 12 s, so the heading change read there is 180 deg.
  Before and after the swing the source reports a yaw rate of zero, not a missing one.

    - region 11, the street: a rectangle from x = -10 m to x = 40 m, y = -4 m to y = 14 m.

  The junction turn (`fails`): the same car, the same approach, swings left at 30 deg/s for three
  seconds only, from t = 5 s to t = 7 s — ninety degrees — and from t = 7 s runs north up a side
  road at 2.6 m/s. The window behind t = 10, 11 and 12 s holds those three contributions and no
  others, so the heading change read there is 90 deg, short of the band's lower edge.

    - region 21, the main roadway, from x = -10 m to x = 40 m, y = -4 m to y = 4 m;
    - region 22, the side road, from x = 21 m to x = 29 m, y = 4 m to y = 40 m;
    - region 23, the junction, from x = 21 m to x = 29 m, y = -4 m to y = 4 m.

  The blind source (`blind`): the swing round of the first scenario, position, heading, speed and
  extent as before, on a source that reports no yaw rate for any road user at any instant and
  whose manifest declares `kin.yaw_rate` absent.

  holds: the magnitude of the heading change over the window behind is 180 deg at every judged
         instant, at or above 150 and at or below 210 — both comparisons true, the body true.
  fails: the magnitude is 90 deg at every judged instant, below the lower edge, so the first
         comparison is false and the body is false.
  blind: no yaw rate is observed anywhere, so the integration over the window behind is unknown
         (`absentAtom "kin_yaw_rate"`), both comparisons are unknown and the body is unknown.
-/
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.u_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- Degrees; used both for a heading change and, per second, for a yaw rate. -/
def deg (n : Int) : Q := Units.degrees n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. This
    concept is a formula over one track formal, so only the three parameters are filled. -/
def inst : Concept.Instance :=
  { name := "drv.motion.u_turn@w"
    concept := "drv.motion.u_turn"
    literals := []
    nats := []
    params :=
      [ ("u_turn_window", .lit (Units.seconds 8) .second)
      , ("u_turn_min_heading_change", .lit (Units.degrees 150) .degree)
      , ("u_turn_max_heading_change", .lit (Units.degrees 210) .degree) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The speed the car keeps throughout: 2.6 m/s, the arc of thirty degrees a second on a radius
    of five metres. -/
def crawl : Q := Units.ratio 26 10

/-- Unit headings thirty degrees apart, counting left (anticlockwise) from east. -/
def h30 : Vec := (Units.ratio 866 1000, Units.ratio 500 1000)
def h60 : Vec := (Units.ratio 500 1000, Units.ratio 866 1000)
def h120 : Vec := (Units.ratio (-500) 1000, Units.ratio 866 1000)
def h150 : Vec := (Units.ratio (-866) 1000, Units.ratio 500 1000)

/-- The car: a motor vehicle 4 m long and 2 m wide, with the yaw rate the source reports. -/
def car (pos : Vec) (heading : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading crawl (m 2, m 1, m 1))
    fun kn => { kn with yawRate := some yaw }

/-- The same car on a source that reports no yaw rate at all. -/
def blindCar (pos : Vec) (heading : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading crawl (m 2, m 1, m 1)

/-- Where the car is and which way it points, second by second, as it swings round: east along
    y = 0 to (20 m, 0), a hundred and eighty degrees left about (20 m, 5 m) between t = 5 s and
    t = 10 s, then west along y = 10 m. -/
def uTurnPose : Nat → Vec × Vec
  | 0 => ((cm 960, m 0), Build.east)
  | 1 => ((cm 1220, m 0), Build.east)
  | 2 => ((cm 1480, m 0), Build.east)
  | 3 => ((cm 1740, m 0), Build.east)
  | 4 => ((m 20, m 0), Build.east)
  | 5 => ((cm 2250, cm 67), h30)
  | 6 => ((cm 2433, cm 250), h60)
  | 7 => ((m 25, m 5), Build.north)
  | 8 => ((cm 2433, cm 750), h120)
  | 9 => ((cm 2250, cm 933), h150)
  | 10 => ((m 20, m 10), Build.west)
  | 11 => ((cm 1740, m 10), Build.west)
  | 12 => ((cm 1480, m 10), Build.west)
  | _ => ((cm 1220, m 10), Build.west)

/-- The yaw rate of the swing round: thirty degrees a second to the left through the six seconds
    of the turning, zero before and after. -/
def uTurnYaw : Nat → Q
  | 5 | 6 | 7 | 8 | 9 | 10 => deg 30
  | _ => deg 0

/-- Where the car is and which way it points as it turns left at the junction: the same approach,
    ninety degrees left about (20 m, 5 m) between t = 5 s and t = 7 s, then north up the side
    road. -/
def junctionPose : Nat → Vec × Vec
  | 0 => ((cm 960, m 0), Build.east)
  | 1 => ((cm 1220, m 0), Build.east)
  | 2 => ((cm 1480, m 0), Build.east)
  | 3 => ((cm 1740, m 0), Build.east)
  | 4 => ((m 20, m 0), Build.east)
  | 5 => ((cm 2250, cm 67), h30)
  | 6 => ((cm 2433, cm 250), h60)
  | 7 => ((m 25, m 5), Build.north)
  | 8 => ((m 25, cm 760), Build.north)
  | 9 => ((m 25, cm 1020), Build.north)
  | 10 => ((m 25, cm 1280), Build.north)
  | 11 => ((m 25, cm 1540), Build.north)
  | 12 => ((m 25, m 18), Build.north)
  | _ => ((m 25, cm 2060), Build.north)

/-- The yaw rate of the junction turn: thirty degrees a second to the left through the three
    seconds of the turning, zero before and after. -/
def junctionYaw : Nat → Q
  | 5 | 6 | 7 => deg 30
  | _ => deg 0

/-- The wide street the turning is made on. -/
def street : List Structure :=
  [ Build.rect 11 .roadway (m (-10)) (m (-4)) (m 40) (m 14) ]

/-- The junction: the main roadway, the side road it turns into, and the junction between them. -/
def junction : List Structure :=
  [ Build.rect 21 .roadway (m (-10)) (m (-4)) (m 40) (m 4)
  , Build.rect 22 .roadway (m 21) (m 4) (m 29) (m 40)
  , Build.rect 23 .intersection (m 21) (m (-4)) (m 29) (m 4) ]

/-- `holds` (compliant): A car on a wide street slows, swings round through about a hundred and eighty degrees in one movement and drives back the way it came; over the window behind the observation its heading has reversed. -/
def holdsTrace : Trace :=
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (uTurnPose k).1 (uTurnPose k).2 (uTurnYaw k) ]
      street []

/-- `fails` (violated): The same car turns left at a junction into a side road and continues: over the window behind, its heading has turned about ninety degrees, short of the band about a half turn. -/
def failsTrace : Trace :=
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (junctionPose k).1 (junctionPose k).2 (junctionYaw k) ]
      junction []

/-- `blind` (unknown): The car swings round as in the first scenario, on a source that maps positions and headings but declares no yaw rate for any road user, so the heading change over the window cannot be integrated. -/
def blindTrace : Trace :=
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ blindCar (uTurnPose k).1 (uTurnPose k).2 ]
      street []

/-- Every scenario is judged over t = 10 s … 12 s: the eight-second window behind each of those
    instants is covered by the trace and holds the whole of the turning. -/
def judged : Timestamp × Timestamp := (10000, 12000)

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

end TrafficSpecWitness.Concepts.motion.u_turn
