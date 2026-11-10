/-
  Witnesses for drv.motion.moving.

  One car (track 1, the subject) on an open plane, no regions or devices; three observations one
  second apart. The instance sets `tol` to 0.1 m/s.
  - holds: the car heads east at 15 m/s, advancing 15 m per observation from (0, 0).
  - fails: the car stands at (0, 0), kin.speed zero.
  - blind: the car moves as in `holds`, but the source declares kin.speed absent (the manifest
    masks it and the field is unset), so the one leaf of the body is unknown.
-/
import TrafficSpec.Concepts.motion.moving
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.moving

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: `tol` is a 0.1 m/s speed resolution. -/
def inst : Concept.Instance :=
  { name := "drv.motion.moving@w"
    concept := "drv.motion.moving"
    literals := []
    nats := []
    params := [("tol", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A car 4.5 m long, 1.8 m wide, 1.5 m high (half-extents). -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The car heading east at `v`, at `x` metres along the x axis. -/
def car (x : Int) (v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m 0) Build.east v carExtent

/-- `holds` (compliant): A car's kin.speed is well above the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (15 * k) (Units.metresPerSecond 15) ]
      [ ]
      [ ]

/-- `fails` (violated): A car stands: kin.speed is zero. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 0 (Units.metresPerSecond 0) ]
      [ ]
      [ ]

/-- `blind` (unknown): The source declares kin.speed absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (car (15 * k) (Units.metresPerSecond 15)) fun kin => { kin with speed := none } ]
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

end TrafficSpecWitness.Concepts.motion.moving
