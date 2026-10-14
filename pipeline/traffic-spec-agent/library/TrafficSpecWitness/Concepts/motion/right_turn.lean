/-
  Witnesses for drv.motion.right_turn.

  The bodies. One car per track, 4.5 m long, 1.8 m wide and 1.5 m high (half-extents 2.25 m, 90 cm,
  75 cm), classed motor vehicle, running at 5 m/s — 5 m of ground between observations. Track 1 is
  the body the witnesses speak about; `fails` puts a second car, track 2, four metres to the north
  of it, in the lane beside it.

  No structures and no devices: the body reads a heading change integrated from the yaw rate and
  nothing else, so no street is drawn. The streets of the narratives are the courses the bodies
  take through the world frame (+x east, +y north).

  The instants. Nine observations one second apart, at 0.0 s through 8.0 s. The witnesses speak
  about 6.0 s and 7.0 s (`window`): at either of those the three-second window behind lies wholly
  inside the trace — an observation precedes it, so it is covered and not truncated — and the one
  second between observations is a third of the window, well inside the half the lookback asks for.

  The turn. A right turn is written as a steady swing of the body: the heading is rotated by the
  5-12-13 step — cosine 12/13, sine 5/13, which is 22.62 degrees to the hundredth — once per
  second over the four intervals ending at the observations 4 through 7, and the yaw rate the
  source reports over exactly those intervals is 22.62 deg/s, signed negative for a swing to the
  right. The primitive integrates the yaw rate by the interval that ends at each observation, so
  over the three seconds behind 6.0 s or 7.0 s the heading change is three such steps: −67.86
  degrees. The whole turn is four steps, 90.48 degrees — a corner from east to south, through a
  radius of about 12.7 m at 5 m/s; the car then runs straight on the new street at 8.0 s.

  The figures, all the witness's own: the instance's window 3 s and swing 30 deg, the car's speed
  5 m/s and the turn's 22.62 deg/s. 67.86 degrees of swing is more than twice the 30-degree swing
  the caller sets, so `holds` turns on the direction and extent of the swing and not on a margin.

  `holds`: track 1 rounds the corner; at both instants the integrated heading change is −67.86
  degrees, at or below −30.
  `fails`: track 1 runs the length of a straight street with a yaw rate of zero, so its integrated
  heading change is 0 degrees, above −30, at both instants; track 2 beside it swings through the
  same four steps to its left, at +22.62 deg/s, which is the other side and is not read here.
  `blind`: track 1 rounds the same corner — the source tracks its position and its heading on the
  map — but the manifest declares `kin.yaw_rate` absent and the scene reports no yaw rate, so no
  heading change can be integrated over the window behind and the comparison decides nothing.
-/
import TrafficSpec.Concepts.motion.right_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.right_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: user ↦ 1

/-- Half-length, half-width, half-height of a car. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The speed every body holds over the ground, and the ground it covers between observations. -/
def carSpeed : Q := Units.metresPerSecond 5
def stepLen : Q := m 5

/-- The 5-12-13 step the heading takes each second of the turn: 22.62 degrees to the hundredth. -/
def cosStep : Q := Units.ratio 12 13
def sinStep : Q := Units.ratio 5 13

/-- The yaw rate the source reports while a body is turning, unsigned. -/
def turnRate : Q := Units.millidegrees 22620

/-- One step of the heading to the right (clockwise), and one to the left. -/
def rotRight (v : Vec) : Vec :=
  (Q.add (Q.mul cosStep v.1) (Q.mul sinStep v.2), Q.sub (Q.mul cosStep v.2) (Q.mul sinStep v.1))
def rotLeft (v : Vec) : Vec :=
  (Q.sub (Q.mul cosStep v.1) (Q.mul sinStep v.2), Q.add (Q.mul cosStep v.2) (Q.mul sinStep v.1))

def spinRight : Nat → Vec → Vec
  | 0, v => v
  | n + 1, v => rotRight (spinRight n v)
def spinLeft : Nat → Vec → Vec
  | 0, v => v
  | n + 1, v => rotLeft (spinLeft n v)

/-- The turn runs over the four intervals ending at the observations 4 through 7. -/
def turnFirst : Nat := 4
def turnLast : Nat := 7
def turning (k : Nat) : Bool := decide (turnFirst ≤ k ∧ k ≤ turnLast)

/-- Steps of heading taken by the observation `k`: none before the turn, one per interval of it. -/
def turnSteps (k : Nat) : Nat := (min k turnLast) - (turnFirst - 1)

/-- The yaw rate a turning body reports at `k`: to the right, to the left, or none at all. -/
def yawRight (k : Nat) : Q := if turning k then Q.neg turnRate else Q.zero
def yawLeft (k : Nat) : Q := if turning k then turnRate else Q.zero

/-- The heading at the observation `k` of a body that rounds the corner to the right, to the left,
    or of one that holds its course east. -/
def hdgRight (k : Nat) : Vec := spinRight (turnSteps k) Build.east
def hdgLeft (k : Nat) : Vec := spinLeft (turnSteps k) Build.east
def hdgEast (_k : Nat) : Vec := Build.east

def addVec (a b : Vec) : Vec := (Q.add a.1 b.1, Q.add a.2 b.2)

/-- The position at `k`: the start, advanced by the heading of each observation before it. -/
def posFrom (start : Vec) (h : Nat → Vec) : Nat → Vec
  | 0 => start
  | k + 1 => addVec (posFrom start h k) (Build.scale (h k) stepLen)

/-- Where track 1 starts, and where the car beside it in `fails` starts. -/
def startCorner : Vec := (m 0, m 0)
def startBeside : Vec := (m 0, m 4)

/-- A car on a course, with the yaw rate the source reports (`none` where it reports none). -/
def mover (track : TrackId) (start : Vec) (h : Nat → Vec) (ω : Option Q) (k : Nat) : RoadUser :=
  Build.withKin (Build.user track [.motorVehicle] (posFrom start h k) (h k) carSpeed carExtent)
    fun kin => { kin with yawRate := ω }

/-- Nine observations one second apart from 0.0 s, and the two the witnesses speak about. -/
def nObs : Nat := 9
def dt : Q := Units.seconds 1
def tFirst : Timestamp := 6000
def tLast : Timestamp := 7000

/-- The instance every scenario speaks about: the window 3 s, the swing 30 deg. -/
def inst : Concept.Instance :=
  { name := "drv.motion.right_turn@w"
    concept := "drv.motion.right_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 3) .second),
               ("swing", .lit (Units.degrees 30) .degree)]
    bounds := none }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A vehicle running along a street swings its body to the right into the intersecting street: over the window behind the observation the integrated heading change is to the right by more than the swing the caller sets. -/
def holdsTrace : Trace :=
  Build.trace nObs 0 dt fun k t =>
    Build.scene t (some 1)
      [ mover 1 startCorner hdgRight (some (yawRight k)) k ]
      [ ]
      [ ]

/-- `fails` (violated): A vehicle runs the length of a straight street, its integrated heading change over the window behind staying well within the swing the caller sets, while another vehicle beside it swings to its left: neither body has turned to its right. -/
def failsTrace : Trace :=
  Build.trace nObs 0 dt fun k t =>
    Build.scene t (some 1)
      [ mover 1 startCorner hdgEast (some Q.zero) k
      , mover 2 startBeside hdgLeft (some (yawLeft k)) k ]
      [ ]
      [ ]

/-- `blind` (unknown): A vehicle takes a bend and the source's manifest declares the rate of change of heading absent: no heading change can be integrated over the window behind, so the concept decides nothing. -/
def blindTrace : Trace :=
  Build.trace nObs 0 dt fun k t =>
    Build.scene t (some 1)
      [ mover 1 startCorner hdgRight none k ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("user", 1)]
    expected := expected
    window := some (tFirst, tLast) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.right_turn
