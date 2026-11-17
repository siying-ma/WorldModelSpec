/-
  Witnesses for drv.motion.right_turn.

  One electric scooter, track 1, observed every 1 s from t = 0 to t = 19 s (20 scenes). It rides
  east at 5 m/s with yaw rate 0 for indices 0..8, turns during indices 9..13 at a yaw rate of
  18 deg/s (right: −18, left: +18), five 1 s intervals, so 90 degrees, and rides on with yaw rate 0
  from index 14 on (south after a right turn, north after a left one).

  Instance: window 8 s (so every window from t = 8 s on is covered), turn_min 45 deg,
  u_turn_min 150 deg, yaw_tol 2 deg/s.

  The heading change over the 8 s window behind index i is the sum of ω_k·1 s over k = i−7 .. i.
  - holds: at index 13 the change is −90 but the yaw rate is −18 (still turning); at index 14 it is
    −90 and the yaw rate 0: the condition rises at t = 14 s, the instant the witness judges.
  - fails: the same turn to the left; at t = 14 s the change is +90, outside the band: the body is
    false at the instant the turn completes, the instant the witness judges.
  - blind: the holds trace with kin.yaw_rate masked: at t = 14 s both the heading change and the
    yaw rate are unknown for the masked atom.
-/
import TrafficSpec.Concepts.motion.right_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.right_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.motion.right_turn@w"
    concept := "drv.motion.right_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 8) .second),
               ("turn_min", .lit (Units.degrees 45) .degree),
               ("u_turn_min", .lit (Units.degrees 150) .degree),
               ("yaw_tol", .lit (Units.degrees 2) .degreePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The scooter's half extents: 60 cm long, 25 cm wide, 60 cm high (halves). -/
def scooterExtent : Q × Q × Q := (cm 60, cm 25, cm 60)

/-- The scooter at index k of a 90-degree turn; `dir` is −1 for a right turn, +1 for a left one.
    East at 5 m/s until the turn ends, then south (right) or north (left). -/
def scooter (dir : Int) (k : Nat) : RoadUser :=
  let ki : Int := Int.ofNat k
  let yaw : Q := if 9 ≤ k ∧ k ≤ 13 then Units.degrees (18 * dir) else Units.degrees 0
  let pos : Vec := if k ≤ 13 then (m (5 * ki), m 0) else (m 65, m (dir * 5 * (ki - 13)))
  let hdg : Vec := if k ≤ 13 then Build.east else (if dir < 0 then Build.south else Build.north)
  Build.withKin (Build.user 1 [.electricScooter] pos hdg (Units.metresPerSecond 5) scooterExtent)
    fun kn => { kn with yawRate := some yaw }

def turnTrace (dir : Int) : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [scooter dir k] [] []

/-- `holds` (compliant): An electric scooter's heading turns 90 degrees to the right over 5 s, then its yaw rate falls below yaw_tol; at that observation the concept holds. -/
def holdsTrace : Trace := turnTrace (-1)

/-- `fails` (violated): An electric scooter turns 90 degrees to the left; the concept does not hold. -/
def failsTrace : Trace := turnTrace 1

/-- `blind` (unknown): The source does not observe the scooter's yaw rate during its turn. -/
def blindTrace : Trace := turnTrace (-1)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (14000, 14000))
  , witness "fails" failsTrace .violated [] (some (14000, 14000))
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (some (14000, 14000)) ]

end TrafficSpecWitness.Concepts.motion.right_turn
