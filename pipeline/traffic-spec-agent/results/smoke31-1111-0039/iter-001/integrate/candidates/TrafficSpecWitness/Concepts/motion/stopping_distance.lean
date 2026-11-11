/-
  Witnesses for drv.motion.stopping_distance.

  Geometry: one car (track 1), half-extent 2 m × 90 cm × 75 cm, drives east along y = 2 at a
  steady speed, starting at x = 0; three instants, one second apart; no regions, no devices.
  The instance gives reaction_time 1 s and deceleration 5 m/s², and bounds the distance to
  [19 m, 21 m].
  In `holds` the car moves at 10 m/s: 10·1 + 10²/(2·5) = 20 m, inside the bounds.
  In `fails` it moves at 20 m/s: 20·1 + 20²/(2·5) = 60 m, above the upper bound.
  In `blind` it moves as in `holds`, but its speed is not observed (kin.speed absent).
-/
import TrafficSpec.Concepts.motion.stopping_distance
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.stopping_distance

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: reaction_time 1 s, deceleration 5 m/s², the
    distance expected in [19 m, 21 m]. -/
def inst : Concept.Instance :=
  { name := "drv.motion.stopping_distance@w"
    concept := "drv.motion.stopping_distance"
    literals := []
    nats := []
    params := [("reaction_time", .lit (Units.seconds 1) .second),
               ("deceleration", .lit (Units.metresPerSecondSq 5) .metrePerSecondSq)]
    bounds := some (.lit (m 19) .metre, .lit (m 21) .metre)
  }

def instances : List Concept.Instance := [inst]

/-- The car at instant k, driving east at a steady `v` m/s. -/
def car (v : Int) (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (v * k), m 2) Build.east (Units.metresPerSecond v)
    (m 2, cm 90, cm 75) (some (m (v * k)))

/-- `holds` (compliant): x moves at a steady speed; the instance fixes reaction_time and deceleration, and its bounds bracket the speed times reaction_time plus the squared speed over twice deceleration: the value lies in the bounds. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car 10 k] [] []

/-- `fails` (violated): x moves at a higher steady speed with the same instance parameters and the same bounds: the computed distance lies above the upper bound. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car 20 k] [] []

/-- `blind` (unknown): As holds, but the source does not observe x's speed at the observation. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [Build.withKin (car 10 k) fun kin => { kin with speed := none }] [] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.stopping_distance
