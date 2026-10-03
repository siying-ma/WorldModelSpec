/-
  Witnesses for drv.motion.left_turn.

  The place, one four-way junction for all three scenarios. The approach road runs east-west along
  y = 0; its eastbound lane (region 10) is the south half, y in [-4, 0] m, from x = -60 m to the
  junction at x = -6 m. The crossing road runs north-south along x = 0; its northbound lane
  (region 11) is the east half, x in [0, 4] m, from y = 6 m to y = 60 m, and its southbound lane
  (region 12) the west half, x in [-4, 0] m, from y = -60 m to y = -6 m. The junction itself
  (region 13) is the square x, y in [-6, 6] m. There are no devices: nothing in this concept reads
  one.

  The body: one tracked passenger car (track 1), 4 m long and 2 m wide, approaching east down the
  centre of the eastbound lane at y = -2 m and slowing — 8, 7, 6, 5 m/s — to 3 m/s as it reaches
  the junction, then swinging through a quarter circle at a steady 3 m/s and a steady yaw rate of
  18 deg/s in size, which is a radius of about 9.55 m: five seconds of turning, 18 degrees of
  heading per second, 90 degrees in all. Before the swing and after it the yaw rate is zero. Each
  trace is twelve observations one second apart, t = 0 ms … 11000 ms, and the swing occupies
  t = 4000 ms … 9000 ms (the heading is east at t = 4000 ms and the crossing road's direction at
  t = 9000 ms).

  How the heading change reads here. The primitive integrates kin.yaw_rate over the window behind
  the observation: with the observations one second apart and a three-second window, the figure at
  an observation is the sum of the yaw rates at the three observations after the oldest one in the
  window. At t = 7000 ms, 8000 ms and 9000 ms all three of those observations are inside the swing,
  so the figure is 3 x 18 = 54 degrees in size at each of them.

  The instance's own figures: turn_window = 3 s (a window long enough to hold a good part of a
  junction turn and short enough not to run back into the straight approach), and
  turn_heading_change_min = 20 deg (well above the heading a lane change or the curvature of a
  road describes in three seconds, well below the 54 degrees this swing describes).

  The instants the witnesses speak about: t = 7000 ms to t = 9000 ms. Before t = 3000 ms the
  three-second lookback runs off the start of the trace — unknown for truncation, by Core's
  finite-trace policy, and not about the concept — and from t = 3000 ms to t = 6000 ms the window
  still holds part of the straight approach, where the car is not yet turning. The one-second
  spacing is at most half the window, so no window in that range is sparse either.

    holds: the car swings left, out of the eastbound lane and across the junction into the
      northbound lane, at +18 deg/s. At every spoken instant the heading change over the window is
      +54 degrees: leftward, since it is above zero, and 54 degrees in size, which is at least the
      stated 20. Both conditions hold at every spoken instant: compliant.
    fails: the same car on the same approach swings right instead, at -18 deg/s, out of the
      eastbound lane and across the junction into the southbound lane, through the same quarter
      circle at the same speed. At every spoken instant the heading change over the window is
      -54 degrees: its size, 54 degrees, is at least the stated 20, so the size condition holds,
      but it is not above zero, so it is not leftward. Violated — and violated for the sense alone,
      which is the narrative's point: a rightward swing is not a left turn however large it is.
    blind: the `holds` trace, under a manifest that declares kin.yaw_rate absent. Positions,
      headings and body outlines are published; no rate of change of heading is. The primitive has
      nothing to integrate, so neither the sense nor the size of the change is decided. The windows
      over the spoken instants are covered and adequately sampled, so the missing yaw rate is the
      only reason left: unknown.

  Which way the car turns is the only difference between the holds and the fails traces: the same
  junction, the same approach, the same speeds, the same size of swing, the sign of the yaw rate
  reversed and the arc mirrored about the line of the approach, so that the fails car ends up in
  the southbound lane as a right-turning car does.
-/
import TrafficSpec.Concepts.motion.left_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n
/-- A yaw rate, in degrees per second. -/
private def degPerSec (n : Int) : Q := Units.degrees n
/-- A heading, as thousandths: `dir 951 309` is 18 degrees north of east. -/
private def dir (x y : Int) : Vec := (Q.mk' x 1000, Q.mk' y 1000)

-- Formals ↦ tracks: a ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.left_turn@w"
    concept := "drv.motion.left_turn"
    literals := []
    nats := []
    params :=
      [ ("turn_window", .lit (Units.seconds 3) .second)                 -- 3 s
      , ("turn_heading_change_min", .lit (Units.degrees 20) .degree) ]  -- 20 deg
    bounds := none }

def instances : List Concept.Instance := [inst]

-- The place: the eastbound approach lane, the two exit lanes of the crossing road, the junction.
private def approachLane : Structure :=
  Build.lane 10 [(m (-60), m (-4)), (m (-6), m (-4)), (m (-6), Q.zero), (m (-60), Q.zero)] Build.east
private def northboundLane : Structure :=
  Build.lane 11 [(Q.zero, m 6), (m 4, m 6), (m 4, m 60), (Q.zero, m 60)] Build.north
private def southboundLane : Structure :=
  Build.lane 12 [(m (-4), m (-60)), (Q.zero, m (-60)), (Q.zero, m (-6)), (m (-4), m (-6))] Build.south
private def theJunction : Structure :=
  Build.rect 13 .intersection (m (-6)) (m (-6)) (m 6) (m 6)

private def junction : List Structure :=
  [approachLane, northboundLane, southboundLane, theJunction]

/-- The car at an instant: a 4 m x 2 m passenger car at a position, with a heading, a speed and a
    yaw rate. -/
private def car (pos : Vec) (heading : Vec) (speed : Q) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading speed (m 2, m 1, m 1))
    (fun k => { k with yawRate := some yaw })

private def place (t : Timestamp) (u : RoadUser) : Scene :=
  Build.scene t (some 1) [u] junction []

/-- The left swing: straight and slowing down the eastbound lane to t = 4000 ms, then 18 deg/s to
    the left for five seconds, through the junction and into the northbound lane. -/
private def leftCar : Nat → RoadUser
  | 0 => car (cm (-3105), cm (-200)) Build.east (mps 8) Q.zero
  | 1 => car (cm (-2355), cm (-200)) Build.east (mps 7) Q.zero
  | 2 => car (cm (-1705), cm (-200)) Build.east (mps 6) Q.zero
  | 3 => car (cm (-1155), cm (-200)) Build.east (mps 5) Q.zero
  | 4 => car (cm (-755), cm (-200)) Build.east (mps 3) Q.zero
  | 5 => car (cm (-460), cm (-153)) (dir 951 309) (mps 3) (degPerSec 18)
  | 6 => car (cm (-194), cm (-18)) (dir 809 588) (mps 3) (degPerSec 18)
  | 7 => car (cm 18, cm 194) (dir 588 809) (mps 3) (degPerSec 18)
  | 8 => car (cm 153, cm 460) (dir 309 951) (mps 3) (degPerSec 18)
  | 9 => car (cm 200, cm 755) Build.north (mps 3) (degPerSec 18)
  | 10 => car (cm 200, cm 1055) Build.north (mps 3) Q.zero
  | _ => car (cm 200, cm 1355) Build.north (mps 3) Q.zero

/-- The right swing: the same approach four metres further back, then 18 deg/s to the right for
    five seconds, through the junction and into the southbound lane. -/
private def rightCar : Nat → RoadUser
  | 0 => car (cm (-3505), cm (-200)) Build.east (mps 8) Q.zero
  | 1 => car (cm (-2755), cm (-200)) Build.east (mps 7) Q.zero
  | 2 => car (cm (-2105), cm (-200)) Build.east (mps 6) Q.zero
  | 3 => car (cm (-1555), cm (-200)) Build.east (mps 5) Q.zero
  | 4 => car (cm (-1155), cm (-200)) Build.east (mps 3) Q.zero
  | 5 => car (cm (-860), cm (-247)) (dir 951 (-309)) (mps 3) (degPerSec (-18))
  | 6 => car (cm (-594), cm (-382)) (dir 809 (-588)) (mps 3) (degPerSec (-18))
  | 7 => car (cm (-382), cm (-594)) (dir 588 (-809)) (mps 3) (degPerSec (-18))
  | 8 => car (cm (-247), cm (-860)) (dir 309 (-951)) (mps 3) (degPerSec (-18))
  | 9 => car (cm (-200), cm (-1155)) Build.south (mps 3) (degPerSec (-18))
  | 10 => car (cm (-200), cm (-1455)) Build.south (mps 3) Q.zero
  | _ => car (cm (-200), cm (-1755)) Build.south (mps 3) Q.zero

/-- `holds` (compliant): A passenger car slows on its approach to a four-way junction and swings left across it. Its yaw rate is sampled throughout a trace that began long before the approach, so the window behind the observation is neither truncated nor sparse, and the heading change integrated over that window is leftward and far greater in size than the stated angle: both conditions hold. -/
private def holdsTrace : Trace :=
  Build.trace 12 0 (Units.seconds 1) fun k t => place t (leftCar k)

/-- `fails` (violated): The same car on the same approach swings right across the junction instead, turning through a quarter circle onto the crossing road. Its yaw rate is sampled throughout the same unbroken trace, so the window behind the observation is neither truncated nor sparse, and the heading change integrated over that window is of the same size as the leftward swing of the holds trace and far greater than the stated angle - but it is to the right, not leftward. The size condition is met and the sense condition is not, so the concept is false: a rightward swing is not a left turn however large it is. -/
private def failsTrace : Trace :=
  Build.trace 12 0 (Units.seconds 1) fun k t => place t (rightCar k)

/-- `blind` (unknown): The same car makes the same leftward swing through the junction, but the source's capability manifest declares the yaw rate absent: it publishes positions and body outlines and no rate of change of heading. The primitive's integration over the window is then undefined - the primitive is "unknown where ... a yaw rate is missing" - so neither the sense nor the size of the change is decided and the concept reports unknown rather than deciding the turn. -/
private def blindTrace : Trace := holdsTrace

/-- Every witness speaks about t = 7000 ms … 9000 ms: the three-second lookback is covered and
    adequately sampled there, and it holds the swing alone rather than part of the straight
    approach. -/
private def spoken : Timestamp × Timestamp := (7000, 9000)

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected
    window := some spoken }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.left_turn
