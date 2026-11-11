/-
  Witnesses for drv.motion.halted.

  One road user, track 1, a motor vehicle 4.5 m × 1.8 m × 1.5 m (half-extents 225 cm, 90 cm, 75 cm),
  heading east along y = 0; no regions, no devices. Three observations at t = 0, 1, 2 s.
  - holds: it stands at (0, 0), speed 0 m/s at every observation.
  - fails: it drives east at 4 m/s, at x = 4·k m at observation k.
  - blind: it stands at (0, 0), but its speed is unobserved (field unset, and `kin.speed` absent
    from the manifest).
  The instance gives speed_floor 0.1 m/s (100000 µm/s), a speed resolution of the witness's own.
-/
import TrafficSpec.Concepts.motion.halted
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.halted

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: speed_floor = 0.1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.halted@w"
    concept := "drv.motion.halted"
    literals := []
    nats := []
    params := [("speed_floor", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def halfExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- `holds` (compliant): x has kin.speed 0.0 m/s at the observation. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (Units.metresPerSecond 0) halfExtent
          (some (m 0)) ]
      [ ]
      [ ]

/-- `fails` (violated): x has kin.speed 4.0 m/s at the observation. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (4 * k), m 0) Build.east (Units.metresPerSecond 4) halfExtent
          (some (m (4 * k))) ]
      [ ]
      [ ]

/-- `blind` (unknown): The source does not observe kin.speed for x. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (Units.metresPerSecond 0) halfExtent
            (some (m 0)))
          (fun kn => { kn with speed := none }) ]
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

end TrafficSpecWitness.Concepts.motion.halted
