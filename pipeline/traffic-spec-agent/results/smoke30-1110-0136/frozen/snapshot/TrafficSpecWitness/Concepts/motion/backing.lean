/-
  Witnesses for drv.motion.backing.

  One car, track 1 (half-extents 2.25 m × 0.9 m × 0.75 m), heading east (+x) on open ground, no
  regions or devices; three instants at 0, 1 and 2 s. The instance gives `tol` 0.1 m/s.
  - holds: the car points east but its velocity is 2 m/s west, (-2, 0): the component along the
    heading is -2 m/s, below -0.1; it reverses from x = 20 m to x = 16 m.
  - fails: the car moves forwards at 5 m/s east along its heading: the component is +5 m/s, not
    below -0.1; it drives from x = 0 m to x = 10 m.
  - blind: the holds scene (2 m/s west, heading east), with the source declaring `kin.velocity`
    absent: the component cannot be computed, so the body is unknown.
-/
import TrafficSpec.Concepts.motion.backing
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.backing

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: `tol` is 0.1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.backing@w"
    concept := "drv.motion.backing"
    literals := []
    nats := []
    params := [("tol", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car of track 1 pointing east at `x` metres, moving at `speed` m/s with velocity `v`
    (world frame). -/
def car (x : Q) (speed : Q) (v : Vec) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (x, m 0) Build.east speed (cm 225, cm 90, cm 75))
    fun kin => { kin with velocity := some v }

/-- `holds` (compliant): A car's velocity points opposite its heading with a magnitude above the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (20 - 2 * (k : Int))) (Units.metresPerSecond 2) (Units.metresPerSecond (-2), m 0) ]
      [ ]
      [ ]

/-- `fails` (violated): A car moves forwards: its velocity points along its heading. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (5 * (k : Int))) (Units.metresPerSecond 5) (Units.metresPerSecond 5, m 0) ]
      [ ]
      [ ]

/-- `blind` (unknown): The source declares kin.velocity absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (20 - 2 * (k : Int))) (Units.metresPerSecond 2) (Units.metresPerSecond (-2), m 0) ]
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.backing
