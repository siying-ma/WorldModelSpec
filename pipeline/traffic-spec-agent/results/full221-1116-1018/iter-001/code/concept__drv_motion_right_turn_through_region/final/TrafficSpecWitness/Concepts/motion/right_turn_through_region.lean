/-
  Witnesses for drv.motion.right_turn_through_region.

  Geometry (every figure the witness's own). Region r = 100 is a roundabout, the square
  x ∈ [0, 20] m, y ∈ [0, 20] m. Road user a = 1 is a motor vehicle of half-extents 2 m × 1 m × 1 m;
  occupancy is derived from its position. Seven scenes at 1 s spacing, t = 0 … 6 s.

  holds: a at (−10,10), (−5,10) outside heading east; (2,10) at 2 s — the entry; (10,10), (12,5)
    inside; (12,−5) at 5 s — the exit, heading south; (12,−10) after. Yaw rate 0 deg/s up to the
    entry, −30 deg/s at 3, 4 and 5 s, 0 after: the change since the entry at the exit is
    −30 × 3 = −90 deg, inside (−135, −45].
  fails: a at y = 10 throughout, x = −10, −5, 2, 10, 18, 25, 30 heading east, yaw rate 0: entry at
    2 s, exit at 5 s, change 0 deg, above −45.
  blind: the holds trace with kin.yaw_rate unobserved: the change since the entry is unknown.

  Each scenario is judged at the exit (5 s) only: the concept is false at every other observation
  by its own words (it holds at the exit only).

  Instance: step = 2 s (the scenes are 1 s apart), turn_min = 45 deg, u_turn_min = 135 deg.
-/
import TrafficSpec.Concepts.motion.right_turn_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.right_turn_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100 (the roundabout of every trace)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.motion.right_turn_through_region@w"
    concept := "drv.motion.right_turn_through_region"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 2) .second),
               ("turn_min", .lit (Units.degrees 45) .degree),
               ("u_turn_min", .lit (Units.degrees 135) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The roundabout region r. -/
def roundabout : Structure := Build.rect 100 .roundabout (m 0) (m 0) (m 20) (m 20)

/-- Road user a at a position and heading, with a yaw rate. -/
def userA (pos : Vec) (h : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos h (Units.metresPerSecond 6) (m 2, m 1, m 1))
    fun k => { k with yawRate := some yaw }

/-- holds: enters heading east, leaves heading south after a quarter turn to the right. -/
def turnUser (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m (-10), m 10) Build.east (Units.degrees 0)
  | 1 => userA (m (-5), m 10) Build.east (Units.degrees 0)
  | 2 => userA (m 2, m 10) Build.east (Units.degrees 0)
  | 3 => userA (m 10, m 10) Build.east (Units.degrees (-30))
  | 4 => userA (m 12, m 5) Build.south (Units.degrees (-30))
  | 5 => userA (m 12, m (-5)) Build.south (Units.degrees (-30))
  | _ => userA (m 12, m (-10)) Build.south (Units.degrees 0)

/-- fails: straight through heading east. -/
def straightUser (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m (-10), m 10) Build.east (Units.degrees 0)
  | 1 => userA (m (-5), m 10) Build.east (Units.degrees 0)
  | 2 => userA (m 2, m 10) Build.east (Units.degrees 0)
  | 3 => userA (m 10, m 10) Build.east (Units.degrees 0)
  | 4 => userA (m 18, m 10) Build.east (Units.degrees 0)
  | 5 => userA (m 25, m 10) Build.east (Units.degrees 0)
  | _ => userA (m 30, m 10) Build.east (Units.degrees 0)

/-- `holds` (compliant): Region r is a roundabout region. Road user a enters r heading east, circulates and leaves r heading south, its yaw rate observed at every scene at the sampling standard: its heading change since the entry is a quarter turn to the right, inside the band, so the concept holds at the exit. -/
def holdsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [turnUser k] [roundabout] []

/-- `fails` (violated): Same region; a enters heading east and leaves heading east again after passing straight through: its heading change is near zero, above minus turn_min, so the concept does not hold at the exit. -/
def failsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [straightUser k] [roundabout] []

/-- `blind` (unknown): As in holds, but a's yaw rate is missing at the scenes inside r: the heading change since the entry is unknown, and so is the concept at the exit. -/
def blindTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [turnUser k] [roundabout] []

/-- The exit observation, 5 s. -/
def exitWindow : Option (Timestamp × Timestamp) := some (5000, 5000)

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
    window := exitWindow }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.right_turn_through_region
