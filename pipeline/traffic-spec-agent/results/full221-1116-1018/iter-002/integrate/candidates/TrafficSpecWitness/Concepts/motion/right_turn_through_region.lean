/-
  Witnesses for drv.motion.right_turn_through_region.

  Geometry (every figure here is the witness's own):
    - region r = 100, a roundabout, the rectangle (0,10)–(30,40) m.
    - road user a = track 1, a motor vehicle of half-extent 2 m × 1 m × 1 m, speed 10 m/s.
    - six scenes, one per second (t = 0 … 5000 ms); occupancy is derived from the geometry.
      holds/blind (a quarter turn to the right at a constant −30°/s from the scene after the entry
      up to and including the exit; a rate at a scene covers the interval before it):
        k0 (-5,30) east, yaw 0, outside r;  k1 (5,30) east, yaw 0, inside r: the entry;
        k2 (14,26) heading −30° (56/65, −33/65), yaw −30°/s;
        k3 (20,18) heading −60° (33/65, −56/65), yaw −30°/s;
        k4 (22,5) south, yaw −30°/s, outside r: the exit;  k5 (22,-5) south, yaw 0.
        Heading change since the entry: Σ yaw·dt over k2…k4 = −90°.
        (The intermediate headings are the rational unit vectors nearest −30° and −60° of the
        65-56-33 triangle.)
      fails (straight through): k0 (-5,30), k1 (5,30) the entry, k2 (15,30), k3 (25,30),
        k4 (35,30) outside r: the exit, k5 (45,30); heading east and yaw 0 throughout.
        Heading change since the entry: 0°.
    - each scenario judges the exit instant only (window 4000–4000 ms): the concept is an event
      recognized at the exit, and is false at every other observation by its own contract.
  Instance: step = 1 s (the scenes' spacing), turn_min = 45°, u_turn_min = 150°, so the band is
  (−150°, −45°].
  blind masks kin.yaw_rate: the integral since the entry is unknown, and so is the concept.
-/
import TrafficSpec.Concepts.motion.right_turn_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.right_turn_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100 (a roundabout, in every scene)

def inst : Concept.Instance :=
  { name := "drv.motion.right_turn_through_region@w"
    concept := "drv.motion.right_turn_through_region"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 1) .second), ("turn_min", .lit (Units.degrees 45) .degree), ("u_turn_min", .lit (Units.degrees 150) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The roundabout region r. -/
def roundabout : Structure := Build.rect 100 .roundabout (m 0) (m 10) (m 30) (m 40)

/-- Heading about 30° to the right of east. -/
def h30 : Vec := (Units.ratio 56 65, Units.ratio (-33) 65)
/-- Heading about 60° to the right of east. -/
def h60 : Vec := (Units.ratio 33 65, Units.ratio (-56) 65)

/-- Road user a at a position, with a heading and a yaw rate (deg/s). -/
def userA (pos : Vec) (h : Vec) (yaw : Int) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos h (Units.metresPerSecond 10) (m 2, m 1, m 1))
    fun k => { k with yawRate := some (Units.degrees yaw) }

/-- a's pose at scene k of the right turn: enters heading east, leaves heading south. -/
def rightTurn (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m (-5), m 30) Build.east 0
  | 1 => userA (m 5, m 30) Build.east 0
  | 2 => userA (m 14, m 26) h30 (-30)
  | 3 => userA (m 20, m 18) h60 (-30)
  | 4 => userA (m 22, m 5) Build.south (-30)
  | _ => userA (m 22, m (-5)) Build.south 0

/-- a's pose at scene k of the passage straight through, heading east. -/
def straight (k : Nat) : RoadUser :=
  userA (m (10 * (Int.ofNat k) - 5), m 30) Build.east 0

/-- `holds` (compliant): Region r is a roundabout region. Road user a approaches heading east with zero yaw rate and enters r. At each scene from the one after its entry up to and including its exit it turns to the right at a constant yaw rate, and its heading at every scene is consistent with that rate: the heading at a scene is the heading at the previous scene turned by the yaw rate observed at that scene times the interval since the previous scene (a rate at a scene covers the interval before it), so the heading goes from east through intermediate directions to south and is never held while the rate is non-zero. Every interval between scenes is within the sampling standard. At its exit, heading south, its integrated heading change since the entry is a quarter turn to the right, inside the band, so the concept holds at the exit, the observation at which it is judged. -/
def holdsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [rightTurn k] [roundabout] []

/-- `fails` (violated): Same region; a enters heading east and leaves heading east again after passing straight through, its heading unchanged and its yaw rate zero at every scene, consistent with each other: its heading change since the entry is zero, above minus turn_min, so the concept does not hold at the exit, the observation at which it is judged. -/
def failsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [straight k] [roundabout] []

/-- `blind` (unknown): As in holds, with the same positions and the same headings turning from east to south between the entry and the exit, but a's yaw rate is not observed: the heading change since the entry is unknown, and so is the concept at the exit. -/
def blindTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [rightTurn k] [roundabout] []

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
    window := some (4000, 4000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.right_turn_through_region
