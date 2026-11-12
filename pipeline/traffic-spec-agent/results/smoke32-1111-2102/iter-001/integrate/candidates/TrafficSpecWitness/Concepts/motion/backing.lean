/-
  Witnesses for drv.motion.backing.

  One motor vehicle, track 1 (half-extents 2.5 m × 1 m × 0.75 m), its body pointing east, observed
  at 0, 1 and 2 s; no region, no device. The instance gives the motion tolerance 10 cm/s.
  - holds: in reverse gear, it rolls west at 2 m/s (x = 20, 18, 16 m): the velocity along the
    heading is −2 m/s, below −0.1 m/s at every instant.
  - fails: in reverse gear, it stands still at x = 20 m (velocity zero): the component along the
    heading is 0, not below −0.1 m/s.
  - blind: the holds scene, with kin.velocity declared absent by the manifest: the component is
    unknown, and so is the body.
-/
import TrafficSpec.Concepts.motion.backing
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.backing

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the motion tolerance at 10 cm/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.backing@w"
    concept := "drv.motion.backing"
    literals := []
    nats := []
    params := [("motion_tolerance", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Track 1, body pointing east, in reverse gear, at `x` with velocity `west · speed`. -/
def reversing (x : Q) (speed : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (x, m 0) Build.east speed (cm 250, m 1, cm 75))
    fun k => { k with velocity := some (Build.scale Build.west speed), gear := some (-1) }

/-- `holds` (compliant): A vehicle's velocity points opposite its heading at a speed above the motion tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ reversing (m (20 - 2 * (Int.ofNat k))) (Units.metresPerSecond 2) ]
      [ ]
      [ ]

/-- `fails` (violated): A vehicle in reverse gear stands still. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ reversing (m 20) Q.zero ]
      [ ]
      [ ]

/-- `blind` (unknown): The source declares kin.velocity absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ reversing (m (20 - 2 * (Int.ofNat k))) (Units.metresPerSecond 2) ]
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.backing
