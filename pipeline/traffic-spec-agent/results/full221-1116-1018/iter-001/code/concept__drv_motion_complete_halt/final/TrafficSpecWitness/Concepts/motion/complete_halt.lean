/-
  Witnesses for drv.motion.complete_halt.

  One passenger car (track 1, motor vehicle, half-extent 2.3 m × 0.9 m × 0.75 m) heading east on an
  open plane, no structures, no devices; three observations 1 s apart (t = 0, 1000, 2000 ms).
  The instance sets `speed_tol` to 0.1 m/s (100 000 µm/s), the witness's own figure for a speed
  resolution.
  - holds: the car stands at x = 0 m; its sampled speeds are 0, 0.05 m/s and exactly 0.1 m/s (the
    tolerance itself, "at or below").
  - fails: the car creeps forward at 0.5 m/s, 0.5 m per observation, above the tolerance at every
    instant.
  - blind: the car stands at x = 0 m, but the manifest does not observe `kin.speed`.
-/
import TrafficSpec.Concepts.motion.complete_halt
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.complete_halt

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The tolerance: 0.1 m/s. -/
def tol : Q := Units.micrometresPerSecond 100000

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.motion.complete_halt@w"
    concept := "drv.motion.complete_halt"
    literals := []
    nats := []
    params := [("speed_tol", .lit tol .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)

/-- The sampled speeds of the halted car: 0, 0.05 m/s, 0.1 m/s (at the tolerance). -/
def holdSpeed (k : Nat) : Q :=
  match k with
  | 0 => Units.metresPerSecond 0
  | 1 => Units.micrometresPerSecond 50000
  | _ => tol

/-- `holds` (compliant): A vehicle's sampled speed is at the tolerance or below. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (holdSpeed k) carExtent ]
      [ ]
      [ ]

/-- `fails` (violated): A vehicle creeps forward with a sampled speed above the tolerance. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (cm (50 * k), m 0) Build.east
          (Units.micrometresPerSecond 500000) carExtent ]
      [ ]
      [ ]

/-- `blind` (unknown): The source does not observe the road user's speed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (Units.metresPerSecond 0) carExtent ]
      [ ]
      [ ]

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

end TrafficSpecWitness.Concepts.motion.complete_halt
