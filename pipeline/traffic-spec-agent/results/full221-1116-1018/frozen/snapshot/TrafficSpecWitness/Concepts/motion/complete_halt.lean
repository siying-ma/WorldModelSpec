/-
  Witnesses for drv.motion.complete_halt.

  Geometry (every figure here is the witness's own):
    - no region; road user a = track 1, a motor vehicle of half-extent 2 m × 1 m × 1 m at (0,0)
      heading east, the subject.
    - three scenes, one per second (t = 0, 1000, 2000 ms).
  Instance: speed_tol = 0.1 m/s (100000 µm/s).
    - holds: sampled speed 0, 0.1 m/s (exactly the tolerance), 0 — at or below at every scene.
    - fails: a creeps forward at 0.5 m/s (500000 µm/s) at every scene — above the tolerance.
    - blind: as holds, but kin.speed is masked: the comparison is unknown at every scene.
-/
import TrafficSpec.Concepts.motion.complete_halt
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.complete_halt

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

def inst : Concept.Instance :=
  { name := "drv.motion.complete_halt@w"
    concept := "drv.motion.complete_halt"
    literals := []
    nats := []
    params := [("speed_tol", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Road user a at the origin heading east with a sampled speed. -/
def userA (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m 0) Build.east speed (m 2, m 1, m 1)

/-- The sampled speed at scene k of the halt: zero, then exactly the tolerance, then zero. -/
def haltSpeed (k : Nat) : Q :=
  match k with
  | 1 => Units.micrometresPerSecond 100000
  | _ => Units.metresPerSecond 0

/-- `holds` (compliant): A vehicle's sampled speed is at the tolerance or below. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [userA (haltSpeed k)] [] []

/-- `fails` (violated): A vehicle creeps forward with a sampled speed above the tolerance. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [Build.user 1 [.motorVehicle] (cm (50 * k), m 0) Build.east
        (Units.micrometresPerSecond 500000) (m 2, m 1, m 1)] [] []

/-- `blind` (unknown): The source does not observe the road user's speed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [userA (haltSpeed k)] [] []

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
