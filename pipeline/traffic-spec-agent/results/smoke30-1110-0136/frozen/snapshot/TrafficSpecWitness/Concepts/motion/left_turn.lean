/-
  Witnesses for drv.motion.left_turn.

  The instance: `window` 6 s, `min_angle` 60°, `max_angle` 150°.

  One car, track 1 (half-extent 2.25 m × 0.9 m × 0.75 m), 5 m/s, observed every second from
  t = 0 to t = 13 s (14 scenes).
  - holds: the car drives east along y = 0 from x = 0 to x = 20 m (t = 0 … 4 s), turns left at a
    junction at a yaw rate of 22.5 °/s over t = 5 … 8 s (90° in all), and drives north from
    (33, 13) m afterwards. The 6 s window's heading change is 67.5° at t = 7 s, 90° at t = 8 … 10 s
    and 67.5° at t = 11 s: within [60°, 150°) at every instant of the judged window 7 … 11 s.
  - fails: the car drives east along y = 0 at a yaw rate of zero throughout; the window's change is
    zero at every covered instant of the judged window 6 … 13 s.
  - blind: the holds trace and window, with `kin.yaw_rate` declared absent.
  Windows behind t < 6 s reach past the trace start, so each scenario names the instants it judges.
-/
import TrafficSpec.Concepts.motion.left_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.motion.left_turn@w"
    concept := "drv.motion.left_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 6) .second), ("min_angle", .lit (Units.degrees 60) .degree),
               ("max_angle", .lit (Units.degrees 150) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
def carSpeed : Q := Units.metresPerSecond 5

/-- Position, heading and yaw rate (deg/s) of the turning car at scene k. -/
def turnPose (k : Nat) : Vec × Vec × Q :=
  if k ≤ 4 then ((m (5 * k), m 0), Build.east, Units.degrees 0)
  else if k = 5 then ((m 25, m 1), (Units.ratio 12 13, Units.ratio 5 13), Units.millidegrees 22500)
  else if k = 6 then ((m 29, m 4), (Units.ratio 20 29, Units.ratio 21 29), Units.millidegrees 22500)
  else if k = 7 then ((m 32, m 8), (Units.ratio 5 13, Units.ratio 12 13), Units.millidegrees 22500)
  else if k = 8 then ((m 33, m 13), Build.north, Units.millidegrees 22500)
  else ((m 33, m (13 + 5 * (k - 8))), Build.north, Units.degrees 0)

def car (pos heading : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading carSpeed carExtent) fun k =>
    { k with yawRate := some yaw }

/-- `holds` (compliant): A car turns left at a junction: within the window its heading changes to the left by more than the minimum and well short of a reversal. -/
def holdsTrace : Trace :=
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    let (pos, heading, yaw) := turnPose k
    Build.scene t (some 1) [car pos heading yaw] [] []

/-- `fails` (violated): A car drives straight; its heading change over the window is near zero. -/
def failsTrace : Trace :=
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car (m (5 * k), m 0) Build.east (Units.degrees 0)] [] []

/-- `blind` (unknown): As holds, with kin.yaw_rate declared absent, so prim.heading_change is unknown. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (7000, 11000))
  , witness "fails" failsTrace .violated [] (some (6000, 13000))
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (some (7000, 11000)) ]

end TrafficSpecWitness.Concepts.motion.left_turn
