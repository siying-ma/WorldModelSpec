/-
  Witnesses for drv.motion.stopping_distance.

  One motor vehicle (track 1, half-extents 2 m × 1 m × 1 m) drives east along y = 0, three
  observations 1 s apart; no structures, no devices. The instance gives reaction_time 1 s and
  deceleration 5 m/s², and expects the stopping distance within [0 m, 30 m].
  - holds: 10 m/s → 10·1 + 10²/(2·5) = 20 m, inside the bounds.
  - fails: 30 m/s → 30·1 + 30²/(2·5) = 120 m, above the upper bound.
  - blind: the holds scene, with kin.speed absent from the manifest.
-/
import TrafficSpec.Concepts.motion.stopping_distance
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.stopping_distance

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: reaction time 1 s, deceleration 5 m/s², and the
    stopping distance expected within [0 m, 30 m]. -/
def inst : Concept.Instance :=
  { name := "drv.motion.stopping_distance@w"
    concept := "drv.motion.stopping_distance"
    literals := []
    nats := []
    params := [("reaction_time", .lit (Units.seconds 1) .second),
               ("deceleration", .lit (Units.metresPerSecondSq 5) .metrePerSecondSq)]
    bounds := some (.lit (m 0) .metre, .lit (m 30) .metre)
  }

def instances : List Concept.Instance := [inst]

/-- Track 1 driving east at `v` m/s, at the position it reaches after `k` seconds. -/
def car (v : Int) (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (v * k), m 0) Build.east (Units.metresPerSecond v) (m 2, m 1, m 1)

/-- `holds` (compliant): a moves at a moderate speed; the instance bounds include the value computed from its speed, the reaction time and the deceleration. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car 10 k] [] []

/-- `fails` (violated): a moves at a high speed; the value exceeds the instance's upper bound. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car 30 k] [] []

/-- `blind` (unknown): the source does not supply a's speed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car 10 k] [] []

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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.stopping_distance
