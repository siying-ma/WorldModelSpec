/-
  Witnesses for drv.motion.standstill.

  The scene is one approach to a junction, the same in all three witnesses: a two-lane north-bound
  stretch is not modelled beyond the junction itself — an intersection 10 m square centred on the
  origin (x from -5 to 5 m, y from -5 to 5 m) — because the concept reads no region. One car, track
  1, is the formal `u`: 4 m long, 2 m wide, 1.5 m high (half-extents 2 m, 1 m, 0.75 m), heading
  north, approaching the junction from the south. Three observations one second apart, at 0, 1000
  and 2000 ms.

  The instance's own figure: `speed_tolerance` = 0.2 m/s (200000 µm/s), a source resolution for a
  standing body. It is the witness's figure alone; the concept file carries no magnitude.

  - `holds`: the car has braked to rest short of the junction, at (0, -6) m, speed exactly 0 m/s at
    all three observations — 0 ≤ 0.2, so the body is true throughout: compliant.
  - `fails`: the car rolls through the same junction at 2 m/s, from (0, -6) m northwards by 2 m per
    observation, so it reads 2 m/s at every observation — 2 ≤ 0.2 is false: violated.
  - `blind`: the same rolling approach with `kin.speed` declared absent by the manifest, so the one
    atom that decides the body is unobserved and no observation decides whether the car was
    motionless: unknown.
-/
import TrafficSpec.Concepts.motion.standstill
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.standstill

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The junction the three narratives speak of: a 10 m square intersection about the origin. -/
def junction : Structure :=
  Build.rect 10 .intersection (m (-5)) (m (-5)) (m 5) (m 5)

/-- The half-extents of the car: 4 m long, 2 m wide, 1.5 m high. -/
def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- The instance every scenario speaks about: the speed tolerance is 0.2 m/s, the witness's own
    figure for the source's resolution for a standing body. -/
def inst : Concept.Instance :=
  { name := "drv.motion.standstill@w"
    concept := "drv.motion.standstill"
    literals := []
    nats := []
    params := [("speed_tolerance", .lit (Units.micrometresPerSecond 200000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car has braked to rest at a junction: its speed reads zero over several consecutive observations, below the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m (-6)) Build.north Q.zero carExtent ]
      [ junction ]
      [ ]

/-- `fails` (violated): A car rolls through the same junction at about 2 m/s without stopping: its speed is well above the tolerance at every observation. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m (-6 + 2 * (k : Int))) Build.north
          (Units.metresPerSecond 2) carExtent ]
      [ junction ]
      [ ]

/-- `blind` (unknown): The same approach with the source declaring the speed of road users absent: no observation decides whether the car was motionless. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m (-6 + 2 * (k : Int))) Build.north
          (Units.metresPerSecond 2) carExtent ]
      [ junction ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.standstill
