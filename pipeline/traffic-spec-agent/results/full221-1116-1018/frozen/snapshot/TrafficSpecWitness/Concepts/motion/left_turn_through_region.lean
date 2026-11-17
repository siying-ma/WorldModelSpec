/-
  Witnesses for drv.motion.left_turn_through_region.

  Geometry (every figure here is the witness's own):
    - region r = 100, an intersection, the square (0,0)–(20,20) m.
    - road user a = track 1, a motor vehicle of half-extent 2 m × 1 m × 1 m, speed 10 m/s.
    - five scenes, one per second (t = 0 … 4000 ms); occupancy is derived from the geometry.
      k0 (-10,5) east, yaw 0, outside r;  k1 (3,5) east, yaw 0, inside r: the entry.
      holds/blind: k2 (12,10) heading (1,1) (north-east), yaw +45°/s, inside r;
                   k3 (15,26) north, yaw +45°/s, outside r: the exit;
                   k4 (15,36) north, yaw 0.
                   Heading change since the entry: Σ yaw·dt over k2…k3 = 45 + 45 = +90°.
      fails:       the mirror image about y = 5 … : k2 (12,0) heading (1,-1) (south-east),
                   yaw −45°/s, inside r; k3 (15,-16) south, yaw −45°/s, outside r: the exit;
                   k4 (15,-26) south, yaw 0. Heading change since the entry: −90°.
      Each scene's heading is the previous one turned by its yaw rate held over the second
      before it (east → north-east → north, and east → south-east → south).
      At the diagonal scene the velocity is left unobserved: no rational vector of the speed's
      length lies on the diagonal, and no atom of the concept reads it.
    - each scenario judges the exit instant only (window 3000–3000 ms): the concept is an event
      recognized at the exit, and false at every other observation by its own contract.
  Instance: step = 1 s (the scenes' spacing), turn_min = 30°, u_turn_min = 150°, so the band is
  [30°, 150°): +90° lies in it, −90° below it.
  blind masks kin.yaw_rate: the integral since the entry is unknown, and so is the concept.
-/
import TrafficSpec.Concepts.motion.left_turn_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100 (an intersection, in every scene)

def inst : Concept.Instance :=
  { name := "drv.motion.left_turn_through_region@w"
    concept := "drv.motion.left_turn_through_region"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 1) .second),
               ("turn_min", .lit (Units.degrees 30) .degree),
               ("u_turn_min", .lit (Units.degrees 150) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The intersection region r. -/
def intersection : Structure := Build.rect 100 .intersection (m 0) (m 0) (m 20) (m 20)

/-- Road user a at a position, with a heading and a yaw rate (deg/s). -/
def userA (pos : Vec) (h : Vec) (yaw : Int) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos h (Units.metresPerSecond 10) (m 2, m 1, m 1))
    fun k => { k with yawRate := some (Units.degrees yaw) }

/-- Road user a on a diagonal heading: its velocity is not observed. -/
def userDiag (pos : Vec) (h : Vec) (yaw : Int) : RoadUser :=
  Build.withKin (userA pos h yaw) fun k => { k with velocity := none }

/-- a's pose at scene k of the left turn: enters heading east, leaves heading north. -/
def leftTurn (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m (-10), m 5) Build.east 0
  | 1 => userA (m 3, m 5) Build.east 0
  | 2 => userDiag (m 12, m 10) (m 1, m 1) 45
  | 3 => userA (m 15, m 26) Build.north 45
  | _ => userA (m 15, m 36) Build.north 0

/-- a's pose at scene k of the right turn: enters heading east, leaves heading south. -/
def rightTurn (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m (-10), m 5) Build.east 0
  | 1 => userA (m 3, m 5) Build.east 0
  | 2 => userDiag (m 12, m 0) (m 1, m (-1)) (-45)
  | 3 => userA (m 15, m (-16)) Build.south (-45)
  | _ => userA (m 15, m (-26)) Build.south 0

/-- `holds` (compliant): Region r is an intersection region. Road user a, observed at every scene at the sampling standard, enters r heading east with a yaw rate of zero up to and including the entry observation; from the next observation on it carries a constant yaw rate to the left, and its heading at every scene is the heading of the scene before turned by that scene's yaw rate held over the interval before it (so the trace is one an adapter produces: heading and yaw rate agree at every scene, passing through intermediate, non-axis headings), until it has turned a quarter turn to the left and leaves r heading north. At the exit observation its heading change since the entry, a quarter turn, lies in the band, so the concept holds there. -/
def holdsTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [leftTurn k] [intersection] []

/-- `fails` (violated): Same region; the mirror image of holds: a enters r heading east with a yaw rate of zero up to and including the entry, then carries a constant yaw rate to the right, its heading at every scene agreeing with the yaw rate held over the interval before that scene, and leaves r heading south after a quarter turn to the right: the heading change since the entry is negative, below turn_min, so the concept does not hold at the exit. -/
def failsTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [rightTurn k] [intersection] []

/-- `blind` (unknown): As in holds, the same positions and headings, but the source supplies no yaw rate for a at any scene: the heading change since the entry cannot be integrated and the concept is unknown at the exit. -/
def blindTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [leftTurn k] [intersection] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some (3000, 3000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.left_turn_through_region
