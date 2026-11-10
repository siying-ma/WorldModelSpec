/-
  Witnesses for drv.motion.stopping_distance.

  One road user, track 1, a motor vehicle 4.5 m long and 1.8 m wide, heading north along x = 0 at a
  steady speed; no structures, no devices. Each trace is three observations, t = 0, 1, 2 s, the
  vehicle advancing by its speed each second. The instance gives `reaction_time` 1 s and `decel`
  5 m/s², and bounds the value in [19 m, 21 m].
    holds: the speed is 10 m/s: 10 · 1 + 10² / (2 · 5) = 20 m, inside [19, 21].
    fails: the same vehicle at 20 m/s: 20 · 1 + 20² / (2 · 5) = 60 m; the bounds lie wholly below.
    blind: the holds scene, 10 m/s, with kin.speed masked by the manifest.
-/
import TrafficSpec.Concepts.motion.stopping_distance
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.stopping_distance

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: `reaction_time` 1 s, `decel` 5 m/s², value in
    [19 m, 21 m]. -/
def inst : Concept.Instance :=
  { name := "drv.motion.stopping_distance@w"
    concept := "drv.motion.stopping_distance"
    literals := []
    nats := []
    params := [("reaction_time", .lit (Units.seconds 1) .second),
               ("decel", .lit (Units.metresPerSecondSq 5) .metrePerSecondSq)]
    bounds := some (.lit (Units.metres 19) .metre, .lit (Units.metres 21) .metre)
  }

def instances : List Concept.Instance := [inst]

/-- Track 1 heading north at a steady `v` m/s, at y = v·k at the k-th observation. -/
def carX (v : Int) (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m (v * k)) Build.north (Units.metresPerSecond v)
    (cm 225, cm 90, cm 75)

/-- `holds` (compliant): A road user moves at a steady speed; the instance's bounds bracket its speed times the reaction time plus the square of its speed over twice the deceleration, read at that observation. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ carX 10 k ]
      [ ]
      [ ]

/-- `fails` (violated): The same road user; the instance's bounds lie wholly below the value the contract computes. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ carX 20 k ]
      [ ]
      [ ]

/-- `blind` (unknown): The source declares kin.speed absent; the value is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ carX 10 k ]
      [ ]
      [ ]

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
