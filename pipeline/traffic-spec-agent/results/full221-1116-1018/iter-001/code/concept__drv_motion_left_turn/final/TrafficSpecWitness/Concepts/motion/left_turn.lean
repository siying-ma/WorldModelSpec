/-
  Witnesses for drv.motion.left_turn.

  One bicycle, track 1 (half-extent 90 cm × 30 cm × 60 cm), riding at 5 m/s; twenty observations,
  one per second, t = 0 … 19 s. No region, no device.

  Instance: window 10 s, turn_min 45°, u_turn_min 150°, yaw_tol 2 °/s.

  The heading change over the window behind observation i is Σ ω_k · (t_k − t_{k−1}) over the
  observations k after the window's oldest one, up to i. With observations 1 s apart, the window of
  10 s is covered from t = 10 s on (its oldest observation is exactly 10 s behind).

  - holds: heading east, the bicycle turns left at 15 °/s at the observations t = 8 … 13 s (six
    seconds, 90°), then its yaw rate is 0 from t = 14 s on, heading north. At t = 14 s the heading
    change over the window behind is 90° (in [45°, 150°)) and the yaw rate 0 ≤ 2 °/s; at t = 13 s
    the yaw rate was 15 °/s > 2 °/s, so the condition rises at t = 14 s. The scenario's window is
    the recognition instant, t = 14 s.
  - fails: a lane change to the left: yaw rate 5 °/s at t = 8, 9 s (10° to the left) and −5 °/s at
    t = 10, 11 s (back to straight), 0 elsewhere; the heading change over the window behind never
    exceeds 10° < 45°, so the condition never holds and the concept is false over t = 10 … 19 s.
  - blind: the holds trace, with kin.yaw_rate unobserved: neither the heading change nor the yaw
    rate is known, and at t = 14 s the concept is unknown.
-/
import TrafficSpec.Concepts.motion.left_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.motion.left_turn@w"
    concept := "drv.motion.left_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 10) .second),
               ("turn_min", .lit (Units.degrees 45) .degree),
               ("u_turn_min", .lit (Units.degrees 150) .degree),
               ("yaw_tol", .lit (Units.degrees 2) .degreePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 60)

/-- A bicycle at a position and heading, with a yaw rate (degrees per second). -/
def bike (pos : Vec) (heading : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.bicycle] pos heading (Units.metresPerSecond 5) bikeExtent)
    (fun k => { k with yawRate := some yaw })

/-- The left turn: yaw rate 15 °/s at k = 8 … 13, 0 elsewhere. -/
def turnYaw (k : Nat) : Q := if 8 ≤ k ∧ k ≤ 13 then Units.degrees 15 else Units.degrees 0

def turnPos (k : Nat) : Vec :=
  if k ≤ 8 then (m (5 * (k : Int)), m 0)
  else if k == 9 then (m 44, m 1)
  else if k == 10 then (m 48, m 4)
  else if k == 11 then (m 51, m 8)
  else if k == 12 then (m 53, m 12)
  else if k == 13 then (m 54, m 16)
  else (m 54, m (16 + 5 * ((k : Int) - 13)))

def turnHeading (k : Nat) : Vec :=
  if k ≤ 8 then Build.east
  else if k == 9 then (Units.ratio 24 25, Units.ratio 7 25)
  else if k == 10 then (Units.ratio 4 5, Units.ratio 3 5)
  else if k == 11 then (Units.ratio 3 5, Units.ratio 4 5)
  else if k == 12 then (Units.ratio 7 25, Units.ratio 24 25)
  else Build.north

/-- `holds` (compliant): A bicycle's heading turns 90 degrees to the left over 6 s, then its yaw rate falls below yaw_tol; at that observation the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ bike (turnPos k) (turnHeading k) (turnYaw k) ]
      [ ]
      [ ]

/-- The lane change: 5 °/s at k = 8, 9; −5 °/s at k = 10, 11; 0 elsewhere. -/
def laneYaw (k : Nat) : Q :=
  if k == 8 || k == 9 then Units.degrees 5
  else if k == 10 || k == 11 then Units.degrees (-5)
  else Units.degrees 0

def laneY (k : Nat) : Q :=
  if k ≤ 8 then cm 0
  else if k == 9 then cm 50
  else if k == 10 then cm 150
  else if k == 11 then cm 300
  else cm 350

def laneHeading (k : Nat) : Vec :=
  if k == 9 || k == 10 then (Units.ratio 985 1000, Units.ratio 174 1000) else Build.east

/-- `fails` (violated): A bicycle changes lane to the left with a heading change of 10 degrees; the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ bike (m (5 * (k : Int)), laneY k) (laneHeading k) (laneYaw k) ]
      [ ]
      [ ]

/-- `blind` (unknown): The source does not observe the bicycle's yaw rate during its turn. -/
def blindTrace : Trace := holdsTrace

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
  , witness "fails" failsTrace .violated [] (some (10000, 19000))
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (some (14000, 14000)) ]

end TrafficSpecWitness.Concepts.motion.left_turn
