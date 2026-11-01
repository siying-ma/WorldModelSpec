/-
  Witnesses for drv.motion.turn_right.

  The instance fills the window with 4 seconds and min_heading_change with 45 degrees: 45 degrees
  is well above the yaw a lane change or a bend puts into a 4-second window and well below the
  quarter circle of a turn at a junction.

  Every trace runs 23 observations at 2 Hz (0.5 s apart, so no window of 4 s is sparsely sampled),
  and every witness is judged over t = 7.5 s … 10.0 s, instants whose 4-second window behind lies
  inside the trace: the primitive looks back, and the first observations of any finite trace have a
  truncated window.

  `holdsTrace` — a car (track 1, 4.5 m × 1.8 m) runs east at 5 m/s along the kerbside lane
  (region 11, y ∈ [−4, 0] m) at y = −2 m, reaching x = −4.5 m at t = 5.5 s with the yaw rate zero.
  From t = 6.0 s to t = 7.5 s it yaws at −44 deg/s, four observations that carry its heading 22
  degrees further right each, 88 degrees to the right in all, along an arc of radius 6.5 m through
  the junction (region 13, x ∈ [0, 8] m, y ∈ [−8, 0] m) and out into the southbound lane of the
  cross street (region 12, x ∈ [0, 4] m), where it runs south at 5 m/s with the yaw rate zero
  again. Over the judged instants the integrated change behind is −88 degrees at t = 7.5 s … 9.5 s
  and −66 degrees at t = 10.0 s, each at most −45.

  `failsTrace` — a car runs east at 5 m/s on a straight two-lane road, from the left lane
  (region 22, y ∈ [0, 4] m) into the right lane (region 21, y ∈ [−4, 0] m): it yaws at −12 deg/s
  for one second (heading 12 degrees right of east), holds that heading while it crosses the line,
  then yaws back at +8 deg/s for one second (heading 4 degrees right of east). The integrated
  change behind is −12 degrees at the first judged instants, −4 degrees at t = 9.5 s and +2 degrees
  at t = 10.0 s: nowhere at most −45, so no turn is recognized.

  `blindTrace` is the turning trace, judged with kin.yaw_rate masked: the primitive integrates the
  yaw rate, so the heading change over the window cannot be formed and the comparison is unknown.
-/
import TrafficSpec.Concepts.motion.turn_right
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turn_right

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- Millimetres, the precision the positions and the heading components are written to. -/
def mm (n : Int) : Q := Units.millimetres n
/-- A position in millimetres, world frame (+x east, +y north). -/
def pos (x y : Int) : Vec := (mm x, mm y)
/-- A heading, its components in thousandths: `hdg 927 (-375)` is 22 degrees right of east. -/
def hdg (x y : Int) : Vec := (mm x, mm y)
/-- A yaw rate, degrees per second, left positive. -/
def dps (n : Int) : Q := Units.degrees n
/-- The car: 4.5 m long, 1.8 m wide, 1.5 m tall. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
/-- Five metres a second, the speed of both narratives. -/
def speed : Q := Units.metresPerSecond 5

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a 4-second window and a 45-degree bound. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turn_right@w"
    concept := "drv.motion.turn_right"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 4) .second),
               ("min_heading_change", .lit (Units.degrees 45) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The junction of the turning narrative
-- ---------------------------------------------------------------------------------------------
/-- The kerbside eastbound lane the car approaches in. -/
def approachLane : Structure :=
  Build.lane 11 [(m (-60), m (-4)), (m 0, m (-4)), (m 0, m 0), (m (-60), m 0)] Build.east
/-- The southbound lane of the cross street the car turns into. -/
def crossLane : Structure :=
  Build.lane 12 [(m 0, m (-60)), (m 4, m (-60)), (m 4, m (-8)), (m 0, m (-8))] Build.south
/-- The junction itself. -/
def junction : Structure := Build.rect 13 .intersection (m 0) (m (-8)) (m 8) (m 0)

/-- East until the turn, then 22 degrees further right at each of the four turning observations
    (−22, −44, −66, −88 degrees from east), then held. -/
def turnHeading (k : Nat) : Vec :=
  if k ≤ 11 then hdg 1000 0
  else if k == 12 then hdg 927 (-375)
  else if k == 13 then hdg 719 (-695)
  else if k == 14 then hdg 407 (-914)
  else hdg 35 (-999)

/-- Zero but for the four turning observations, where the car yaws to the right at 44 deg/s. -/
def turnYaw (k : Nat) : Q :=
  if 12 ≤ k && k ≤ 15 then dps (-44) else Q.zero

/-- Eastward at 2.5 m an observation, then the arc of radius 6.5 m about (−4.5, −8.5) m, then
    southward along the held heading. -/
def turnPos (k : Nat) : Vec :=
  if k ≤ 11 then pos (-32000 + 2500 * (k : Int)) (-2000)
  else if k == 12 then pos (-2063) (-2475)
  else if k == 13 then pos 18 (-3827)
  else if k == 14 then pos 1441 (-5855)
  else pos (1994 + 88 * ((k : Int) - 15)) (-8273 - 2498 * ((k : Int) - 15))

/-- `holds` (compliant): A car in the kerbside lane swings clockwise into the cross street at
    5 m/s; the integrated heading change over the window behind is 88 degrees to the right at the
    observation judged. -/
def holdsTrace : Trace :=
  Build.trace 23 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (Build.user 1 [.motorVehicle] (turnPos k) (turnHeading k) speed carExtent)
          fun kin => { kin with yawRate := some (turnYaw k) } ]
      [ approachLane, crossLane, junction ]
      []

-- ---------------------------------------------------------------------------------------------
-- The straight road of the lane-change narrative
-- ---------------------------------------------------------------------------------------------
/-- The right (kerbside) lane the car changes into. -/
def rightLane : Structure :=
  Build.lane 21 [(m (-40), m (-4)), (m 40, m (-4)), (m 40, m 0), (m (-40), m 0)] Build.east
    (left := some 22)
/-- The left lane the car starts in. -/
def leftLane : Structure :=
  Build.lane 22 [(m (-40), m 0), (m 40, m 0), (m 40, m 4), (m (-40), m 4)] Build.east
    (right := some 21)

/-- East, then 6 and 12 degrees right of east while the car crosses the line, then back to 8 and
    4 degrees right of east. -/
def laneChangeHeading (k : Nat) : Vec :=
  if k ≤ 11 then hdg 1000 0
  else if k == 12 then hdg 995 (-105)
  else if k ≤ 17 then hdg 978 (-208)
  else if k == 18 then hdg 990 (-139)
  else hdg 998 (-70)

/-- Out at 12 deg/s to the right over one second, back at 8 deg/s to the left over one second. -/
def laneChangeYaw (k : Nat) : Q :=
  if k == 12 || k == 13 then dps (-12)
  else if k == 18 || k == 19 then dps 8
  else Q.zero

/-- Eastward at 2.5 m an observation, drifting from y = 2 m to y = −1.89 m across the line. -/
def laneChangePos (k : Nat) : Vec :=
  if k ≤ 11 then pos (-30000 + 2500 * (k : Int)) 2000
  else if k == 12 then pos (-10) 1740
  else if k ≤ 17 then pos (2440 + 2450 * ((k : Int) - 13)) (1220 - 520 * ((k : Int) - 13))
  else if k == 18 then pos 14710 (-1210)
  else pos (17200 + 2500 * ((k : Int) - 19)) (-1380 - 170 * ((k : Int) - 19))

/-- `fails` (violated): A car changes lanes to the right on a straight road; the yaw out and back
    nets 4 degrees to the right over the window behind, below the bound, so no turn is
    recognized. -/
def failsTrace : Trace :=
  Build.trace 23 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (laneChangePos k) (laneChangeHeading k) speed carExtent)
          fun kin => { kin with yawRate := some (laneChangeYaw k) } ]
      [ rightLane, leftLane ]
      []

/-- `blind` (unknown): A car swings right into the cross street, but the trace carries no yaw rate
    for it, so the integrated heading change cannot be formed. -/
def blindTrace : Trace := holdsTrace

/-- The instants every witness is judged over: their 4-second windows lie inside the trace. -/
def judged : Timestamp × Timestamp := (7500, 10000)

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

end TrafficSpecWitness.Concepts.motion.turn_right
