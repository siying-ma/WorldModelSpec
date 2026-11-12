/-
  Witnesses for drv.motion.turning_right.

  One passenger car, track 1, half-extent 2.25 m × 0.9 m × 0.75 m, at 8 m/s, at x = 8·k m, y = 0
  over three instants one second apart (t = 0, 1000, 2000 ms), its heading starting east and
  turning between instants as its yaw rate says (rational unit vectors). No devices.
  The instance sets the yaw tolerance to 2 deg/s and the speed tolerance to 0.1 m/s.
  - holds: the car crosses an intersection (rectangle (−5, −10)–(25, 10)) with a yaw rate of
    −25 deg/s at every instant, well below −2 deg/s.
  - fails: the car moves along a straight roadway (rectangle (−10, −4)–(40, 4)) with a yaw rate of
    0.5 deg/s (near zero) at every instant.
  - blind: the car of `holds`, moving, but the source declares kin.yaw_rate absent.
  Only the speed and the yaw rate are read by the body.
-/
import TrafficSpec.Concepts.motion.turning_right
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turning_right

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: yaw tolerance 2 deg/s, speed tolerance 0.1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turning_right@w"
    concept := "drv.motion.turning_right"
    literals := []
    nats := []
    params := [("yaw_tolerance", .lit (Units.degrees 2) .degreePerSecond),
               ("speed_tolerance", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car of every scene at instant `k`, at 8 m/s with heading `h` and yaw rate `yaw` (deg/s). -/
def car (k : Nat) (h : Vec) (yaw : Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m (8 * k), m 0) h (Units.metresPerSecond 8)
      (cm 225, cm 90, cm 75))
    fun kin => { kin with yawRate := some yaw }

/-- Headings of the right turn: east, then about 22.6° and 53.1° clockwise of east (unit vectors
    (12/13, −5/13) and (3/5, −4/5)), the yaw rate −25 deg/s turning it between instants. -/
def rightTurnHeading (k : Nat) : Vec :=
  match k with
  | 0 => Build.east
  | 1 => (Units.ratio 12 13, Units.ratio (-5) 13)
  | _ => (Units.ratio 3 5, Units.ratio (-4) 5)

/-- Headings along the straight road: east, then about 0.5° and 1° counter-clockwise of east (unit
    vectors from Pythagorean triples), the yaw rate 0.5 deg/s turning it between instants. -/
def straightHeading (k : Nat) : Vec :=
  match k with
  | 0 => Build.east
  | 1 => (Units.ratio 52440 52442, Units.ratio 458 52442)
  | _ => (Units.ratio 13224 13226, Units.ratio 230 13226)

def junction : Structure := Build.rect 10 .intersection (m (-5)) (m (-10)) (m 25) (m 10)
def straightRoad : Structure := Build.rect 20 .roadway (m (-10)) (m (-4)) (m 40) (m 4)

/-- `holds` (compliant): a moves through a junction with a yaw rate well below the negative of the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k (rightTurnHeading k) (Units.degrees (-25)) ]
      [ junction ]
      [ ]

/-- `fails` (violated): a moves along a straight road with a yaw rate near zero. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k (straightHeading k) (Units.millidegrees 500) ]
      [ straightRoad ]
      [ ]

/-- `blind` (unknown): a moves, but the source supplies no yaw rate. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.yaw_rate"]) holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.turning_right
