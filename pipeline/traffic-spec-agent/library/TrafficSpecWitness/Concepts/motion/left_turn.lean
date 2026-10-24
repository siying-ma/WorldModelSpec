/-
  Witnesses for drv.motion.left_turn.

  One junction and one length of bending road carry the three scenarios. Every figure below is the
  witness's own, including the three the instance gives the formal parameters: a window of 6 s, a
  band from 60° to 135° of signed heading change to the left.

  The subject is a car, 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), track 1, the formal
  `u`; it runs at 5 m/s. Every scene carries its yaw rate, which is the only thing the concept
  reads; its position and heading are the witness's own rendering of the same motion (headings are
  rational approximations of the unit vector at a bearing, to a thousandth), and the roadway
  regions are drawn so that the scene is a road scene — the body reads no region, and no scenario
  turns on one.

  Fourteen instants 1 s apart from t = 0, so t = 0 … 13 s. The body looks 6 s behind, so the
  window of every scenario is t = 9 s … 13 s: at those five instants the back window is covered
  (an observation 6 s earlier and five between), while the instants before t = 6 s have a window
  that reaches past the start of the trace. Nothing looks ahead, so no padding is needed.

  holds:  the car runs north at x = -5 m up to y = -35 m with no yaw (t = 0 … 5 s), then turns to
          its left at 16 deg/s for six seconds (t = 6 … 11 s), through 96° in all, and runs on
          with no yaw. Over the window behind, its signed heading change is 64° at t = 9 s, 80° at
          t = 10 s, 96° at t = 11 s (the whole turning inside the window), 80° at t = 12 s and 64°
          at t = 13 s, as the turning slides out behind it: inside the band 60° … 135° at every
          instant of the window. The concept holds throughout, which is the contract's "from the
          observation at which the heading change first enters the band until the window behind
          has passed".
  fails:  the car runs north along a roadway that bends to its left, holding the bend at 1 deg/s
          over the whole trace. Its signed heading change over the window behind is 6° at every
          instant of the window — a turning to the left, but below the lower edge of the band, a
          bend held rather than a left turn. The concept fails at every instant of the window. A
          body that turned through a half circle would fail the other way, above the upper edge.
  blind:  the holds scene on a source whose manifest declares kin.yaw_rate absent. The window
          behind is covered at every instant of the window, as above, but no rate of change of
          heading is observed within it, so the heading change cannot be integrated and the
          concept is unknown for that atom alone.
-/
import TrafficSpec.Concepts.motion.left_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A yaw rate (degrees per second, left positive), as `kin.yaw_rate` carries it. -/
def degPerSecond (n : Int) : Q := Units.degrees n

/-- A heading: the direction in the world frame (+x east, +y north) written in thousandths, the
    witness's own rational approximation of the unit vector at a bearing. -/
def dir (x y : Int) : Vec := (Units.ratio x 1000, Units.ratio y 1000)

/-- The timestamp, in milliseconds, of the observation at second `n`. -/
def atSecond (n : Int) : Timestamp := n * 1000

/-- The place a scene puts a body that has no table entry; no scenario reaches it. -/
def origin : Vec := (m 0, m 0)

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. The window
    behind is 6 s — long enough for a junction turning at the speed a turning body keeps — and the
    band is 60° … 135° of signed heading change to the left: below 60° the witness's source counts
    the turning a drift, a lane change or a bend held, above 135° a body still turning towards a
    reversal of direction. All three figures are the witness's own. -/
def inst : Concept.Instance :=
  { name := "drv.motion.left_turn@w"
    concept := "drv.motion.left_turn"
    literals := []
    nats := []
    params := [("left_turn_window", .lit (Units.seconds 6) .second),
               ("left_turn_min_heading_change", .lit (Units.degrees 60) .degree),
               ("left_turn_max_heading_change", .lit (Units.degrees 135) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car of the witness, with the yaw rate its source observed at this instant. -/
def car (pos : Vec) (heading : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond 5) (m 2, m 1, m 1))
    (fun kin => { kin with yawRate := some yaw })

-- ---------------------------------------------------------------------------------------------
-- holds (and blind): a junction, and a car that turns a quarter circle to its left through it
-- ---------------------------------------------------------------------------------------------
/-- The north–south arm of the junction, 20 m wide. -/
def northArm : Structure := Build.rect 11 .roadway (m (-10)) (m (-60)) (m 10) (m (-10))

/-- The west arm, 20 m wide, which the car leaves by. -/
def westArm : Structure := Build.rect 12 .roadway (m (-60)) (m (-25)) (m (-10)) (m (-5))

def junction : List Structure := [northArm, westArm]

/-- The car's heading at each of the fourteen instants: north until t = 5 s, then round to the
    left by about 16° a second through the six seconds of the turning, ending 6° past west. -/
def holdsHeadings : List Vec :=
  [ Build.north, Build.north, Build.north, Build.north, Build.north, Build.north
  , dir (-276) 961, dir (-530) 848, dir (-743) 669, dir (-899) 438, dir (-985) 174
  , dir (-995) (-105), dir (-995) (-105), dir (-995) (-105) ]

/-- The car's place at each instant: 5 m further on each second, north up the arm to the junction,
    round a turning of about 18 m radius, then west. -/
def holdsPositions : List Vec :=
  [ (m (-5), m (-60)), (m (-5), m (-55)), (m (-5), m (-50)), (m (-5), m (-45))
  , (m (-5), m (-40)), (m (-5), m (-35))
  , (m (-6), m (-30)), (m (-8), m (-25)), (m (-11), m (-22)), (m (-15), m (-19))
  , (m (-20), m (-17)), (m (-25), m (-17)), (m (-30), m (-17)), (m (-35), m (-18)) ]

/-- The car's yaw rate at each instant: nil while it runs north, 16 deg/s to the left over the six
    seconds t = 6 s … 11 s (96° of turning in all), nil once it runs west. -/
def holdsYaws : List Q :=
  [ degPerSecond 0, degPerSecond 0, degPerSecond 0, degPerSecond 0, degPerSecond 0, degPerSecond 0
  , degPerSecond 16, degPerSecond 16, degPerSecond 16, degPerSecond 16, degPerSecond 16
  , degPerSecond 16, degPerSecond 0, degPerSecond 0 ]

/-- `holds` (compliant): A vehicle runs north along a roadway, then turns through about a quarter circle to its left and runs west. Over the window behind the observation its signed heading change is a little over a quarter turn to the left, inside the band. The concept holds. -/
def holdsTrace : Trace :=
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (holdsPositions.getD k origin) (holdsHeadings.getD k Build.north)
            (holdsYaws.getD k (degPerSecond 0)) ]
      junction
      []

-- ---------------------------------------------------------------------------------------------
-- fails: a roadway that bends to the left, and a car that holds the bend
-- ---------------------------------------------------------------------------------------------
/-- The bending roadway, 40 m wide, which the car holds all the way along. -/
def bendingRoadway : Structure := Build.rect 21 .roadway (m (-30)) (m (-65)) (m 10) (m 10)

/-- The car's heading at each instant: north, coming round by one degree a second as it holds the
    bend, 13° in all over the thirteen seconds. -/
def failsHeadings : List Vec :=
  [ Build.north, dir (-17) 1000, dir (-35) 999, dir (-52) 999, dir (-70) 998
  , dir (-87) 996, dir (-105) 995, dir (-122) 993, dir (-139) 990, dir (-156) 988
  , dir (-174) 985, dir (-191) 982, dir (-208) 978, dir (-225) 974 ]

/-- The car's place at each instant: 5 m further on each second, drifting west as the road bends. -/
def failsPositions : List Vec :=
  [ (m (-5), m (-60)), (m (-5), m (-55)), (m (-5), m (-50)), (m (-5), m (-45))
  , (m (-6), m (-40)), (m (-6), m (-35)), (m (-7), m (-30)), (m (-7), m (-25))
  , (m (-8), m (-20)), (m (-9), m (-15)), (m (-9), m (-10)), (m (-10), m (-5))
  , (m (-11), m 0), (m (-12), m 5) ]

/-- `fails` (violated): A vehicle runs north along a roadway and holds a long bend to its left over the whole window, its signed heading change amounting to a few degrees, below the band's lower edge. The concept fails; so would a vehicle that turned through a half circle, whose heading change lies above the upper edge. -/
def failsTrace : Trace :=
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (failsPositions.getD k origin) (failsHeadings.getD k Build.north) (degPerSecond 1) ]
      [ bendingRoadway ]
      []

/-- `blind` (unknown): The holds scene, except that the source declares the yaw rate absent, so no rate of change of heading is observed. The heading change over the window cannot be integrated, so the concept is unknown. -/
def blindTrace : Trace := holdsTrace

/-- The instants every scenario speaks about: t = 9 s … 13 s, where the window of 6 s behind the
    observation is covered by the trace. -/
def theWindow : Option (Timestamp × Timestamp) := some (atSecond 9, atSecond 13)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := theWindow }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.left_turn
