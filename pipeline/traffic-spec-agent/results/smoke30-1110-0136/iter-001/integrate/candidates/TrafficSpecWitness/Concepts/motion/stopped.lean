/-
  Witnesses for drv.motion.stopped.

  One road user, track 1 (x), a car 4.6 m long and 1.8 m wide (half-extents 2.3, 0.9, 0.75 m),
  at (0, 0) heading east, on an empty scene: no structure, no device. Three instants, 1 s apart,
  at 0, 1000 and 2000 ms; the concept reads the one observation, so no window is needed.
  The instance gives `tol` 0.2 m/s.
  - holds: x's speed is 0.05 m/s at every instant, at or below 0.2 m/s: halted.
  - fails: x's speed is 2 m/s at every instant (it advances 2 m a second): moving.
  - blind: the scene of `holds` with x's speed unobserved, and `kin.speed` absent from the manifest.
-/
import TrafficSpec.Concepts.motion.stopped
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.stopped

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: `tol` is 0.2 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.stopped@w"
    concept := "drv.motion.stopped"
    literals := []
    nats := []
    params := [("tol", .lit (Units.micrometresPerSecond 200000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car x at `pos`, heading east at `speed`. -/
def car (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.east speed (cm 230, cm 90, cm 75)

/-- `holds` (compliant): x's kin.speed is 0.05 m/s with tol 0.2 m/s: halted. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 0, m 0) (Units.micrometresPerSecond 50000) ]
      [ ]
      [ ]

/-- `fails` (violated): x's kin.speed is 2 m/s: moving, not halted. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (2 * k), m 0) (Units.metresPerSecond 2) ]
      [ ]
      [ ]

/-- `blind` (unknown): kin.speed is not observed for x. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin (car (m 0, m 0) (Units.micrometresPerSecond 50000))
          (fun k => { k with speed := none }) ]
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

end TrafficSpecWitness.Concepts.motion.stopped
