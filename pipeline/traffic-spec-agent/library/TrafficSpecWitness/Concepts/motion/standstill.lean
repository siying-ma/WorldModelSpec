/-
  Witnesses for drv.motion.standstill.

  The geometry, all of it this file's own. One body throughout: track 1, a car (`motor_vehicle`)
  4.6 m long and 1.8 m wide (half-extents 2.3 m, 0.9 m, 0.75 m), heading east, read at three
  observations one second apart (t = 0, 1000, 2000 ms). The instance sets the only formal parameter,
  `speed_max`, to 0.1 m/s: the observer's resolution for rest, and the figure both moving scenes are
  placed around.

    holds   the car stands at the origin and creeps at 0.02 m/s, a fifth of the resolution; its
            position advances the 2 cm per second that speed accounts for. The body is true at every
            observation, so the episode is compliant.
    fails   the car rolls east through an intersection (region 10, the 20 m square about the origin)
            at 1.4 m/s, fourteen times the resolution, advancing 1.4 m per second. The body is false
            at every observation, so the episode is violated.
    blind   the car stands at the origin, but the manifest declares `kin.speed` absent: the one atom
            the body reads is unobserved, so the comparison -- and the episode -- is unknown.

  Only `fails` carries a region: nothing in the body reads one, and the junction is there because
  the narrative puts the rolling car at one.
-/
import TrafficSpec.Concepts.motion.standstill
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.standstill

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- Millimetres per second, through the micrometre-per-second constructor. -/
def mmps (n : Int) : Q := Units.micrometresPerSecond (n * 1000)

/-- The car's half-length, half-width and half-height: a 4.6 m by 1.8 m body. -/
def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.standstill@w"
    concept := "drv.motion.standstill"
    literals := []
    nats := []
    params := [("speed_max", .lit (mmps 100) .metrePerSecond)]   -- 0.1 m/s: the resolution for rest
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car's recorded speed falls to 0.02 m/s at the observation, below the rest resolution: it is at a standstill. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (cm (2 * Int.ofNat k), m 0) Build.east (mmps 20) carExtent ]
      [ ]  -- no structure: the body reads none
      [ ]  -- devices

/-- `fails` (violated): A car rolls through a junction at 1.4 m/s, above the rest resolution at every observation: it is at no standstill. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (cm (140 * Int.ofNat k), m 0) Build.east (mmps 1400) carExtent ]
      [ Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10) ]
      [ ]  -- devices

/-- `blind` (unknown): A car is present in the scene but the source declares speed absent, so whether its movement has ceased cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east Q.zero carExtent ]
      [ ]  -- no structure: the body reads none
      [ ]  -- devices

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
