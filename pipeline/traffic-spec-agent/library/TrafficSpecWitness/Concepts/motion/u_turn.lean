/-
  Witnesses for drv.motion.u_turn.

  The geometry, built once for all three scenes. One body, track 1, a saloon car 4.5 m long, 1.8 m
  wide and 1.5 m high (half-extents 225 cm, 90 cm, 75 cm), classed motor vehicle, running at a
  steady 4 m/s. No structures and no devices: the body reads the turning alone, and the place of
  the turning is the record's residue, which the caller reads.

  The instants. Each scene is five observations one second apart, at 8.0 s, 9.0 s, 10.0 s, 11.0 s
  and 12.0 s. The witnesses speak about the single instant 12.0 s, the observation at which the
  turning is complete, which is what `window` names: a u-turn is finished at an instant, and a
  verdict about a span of instants would ask the body to go on rotating after it had come about.
  One second between observations is exactly half the two-second window, which is the adequacy the
  primitive's lookback asks for, and the two observations at 8.0 s and 9.0 s lie behind the window
  of 12.0 s, so that window is covered rather than truncated.

  The figures, all the witness's own: the window 2 s and the tolerance 10 deg (the instance's
  values for the formal parameters), the car's speed 4 m/s and its turn rate 88 deg/s. The yaw
  rate is a rate in degrees per second; `Units` carries no constructor for that rate, so the
  figure is written through `Units.degrees`, which is the constructor of its angle.

  `prim_heading_change` integrates the yaw rate of each observation over the interval before it,
  so the heading change over the window behind 12.0 s is the yaw rate at 11.0 s plus the yaw rate
  at 12.0 s, each over one second. The headings the scenes report follow that integration: the car
  points east while it runs straight, 88 deg from east after a second of turning, 176 deg from east
  after two. They are written as rational approximations of the unit vectors at those angles; the
  body reads none of them, only the yaw rate, through the primitive.

  `holds`: the car runs east along the road to 10.0 s, then swings left across it at 88 deg/s for
  the two seconds of the window, coming about through 176 deg and setting off back the way it came
  (west, a little north of its old line). The magnitude of the heading change is 176 deg, which is
  4 deg short of a half turn and so within the 10 deg tolerance.
  `fails`: the car runs east to 10.0 s, turns left at 88 deg/s for one second into a side street
  and then runs straight up it. The heading change over the window behind 12.0 s is 88 deg — about
  a quarter turn, 92 deg short of a half turn and far outside the tolerance.
  `blind`: the source reports where the car was at each observation and nothing else: no yaw rate
  in any scene and `kin.yaw_rate` absent from the manifest, so the primitive forms no heading
  change over the window and the body is unknown. The positions are those of `holds` — the car did
  come about — which is the point: the turning cannot be read off the positions.
-/
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.u_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: user ↦ 1

/-- Half-length, half-width, half-height of the car. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The car's speed over the ground. -/
def carSpeed : Q := Units.metresPerSecond 4

/-- The rate at which the car swings about, in degrees per second (left positive). -/
def turnRate : Q := Units.degrees 88

/-- The car is not turning. -/
def straightRate : Q := Units.degrees 0

/-- The heading 88 degrees north of east, and 176 degrees: rational approximations of the unit
    vectors, which no atom of the body reads. -/
def hdg88 : Vec := (Units.ratio 349 10000, Units.ratio 9994 10000)
def hdg176 : Vec := (Units.ratio (-9976) 10000, Units.ratio 698 10000)

/-- The first observation of every scene, and the instant the witnesses speak about. -/
def tStart : Timestamp := 8000
def tLast : Timestamp := 12000

/-- One second between observations. -/
def dt : Q := Units.seconds 1

/-- The car at a position, pointing a way, turning at a rate. -/
def car (pos : Vec) (hdg : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos hdg carSpeed carExtent)
    fun k => { k with yawRate := some yaw }

/-- The car seen by a source that reports positions only. -/
def tracedCar (pos : Vec) : RoadUser := Build.sparseUser 1 [.motorVehicle]  pos

/-- A scene of one car and nothing else. -/
def carScene (t : Timestamp) (u : RoadUser) : Scene :=
  Build.scene t (some 1) [u] [] []

/-- Where the car is at each of the five observations while it comes about. -/
def turnPos (k : Nat) : Vec :=
  match k with
  | 0 => (m (-8), m 0)
  | 1 => (m (-4), m 0)
  | 2 => (m 0, m 0)
  | 3 => (cm 260, cm 251)
  | _ => (cm 18, cm 520)

/-- The instance every scenario speaks about: the window 2 s, the tolerance 10 deg. -/
def inst : Concept.Instance :=
  { name := "drv.motion.u_turn@w"
    concept := "drv.motion.u_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 2) .second),
               ("reversal_tolerance", .lit (Units.degrees 10) .degree)]
    bounds := none }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): Within the window the vehicle swings through about a half turn across the road and sets off back the way it came; the magnitude of the integrated heading change is within the tolerance of a half turn. -/
def holdsTrace : Trace :=
  Build.trace 5 tStart dt fun k t =>
    carScene t <|
      match k with
      | 0 | 1 | 2 => car (turnPos k) Build.east straightRate
      | 3 => car (turnPos 3) hdg88 turnRate
      | _ => car (turnPos 4) hdg176 turnRate

/-- `fails` (violated): Within the window the vehicle swings through about a quarter turn to its left into a side street; the magnitude of the integrated heading change is far short of a half turn. -/
def failsTrace : Trace :=
  Build.trace 5 tStart dt fun k t =>
    carScene t <|
      match k with
      | 0 | 1 | 2 => car (turnPos k) Build.east straightRate
      | 3 => car (turnPos 3) hdg88 turnRate
      | _ => car (cm 274, cm 651) hdg88 straightRate

/-- `blind` (unknown): The source gives positions but declares no yaw rate, so no heading change is formed over the window. -/
def blindTrace : Trace :=
  Build.trace 5 tStart dt fun k t => carScene t (tracedCar (turnPos k))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("user", 1)]
    expected := expected
    window := some (tLast, tLast) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.u_turn
