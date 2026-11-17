/-
  Witnesses for drv.motion.parked.

  Geometry (every figure here is the witness's own):
    - no region; road user a = track 1, a bicycle of half-extent 1 m × 30 cm × 1 m at (0,0)
      heading east (standing beside the curb), the subject; no rider is supplied (not read).
    - six scenes, one per second (t = 0 … 5000 ms); each scenario speaks about t = 3000 … 5000 ms,
      where the 2 s window behind lies wholly inside the trace.
  Instance: speed_tol = 0.1 m/s (100000 µm/s), min_duration = 2 s.
    - holds: sampled speed 0 at every scene — at rest at every observation of each window.
    - fails: the bicycle rides at 2 m/s at t = 0, 1000, halts (speed 0) at t = 2000, 3000 and
      rides off at 2 m/s at t = 4000, 5000: the window behind t = 3000 holds a speed above the
      tolerance (t = 1000), so it is not parked there (nor at 4000, 5000).
    - blind: as holds, but kin.speed is masked: every window is unknown.
-/
import TrafficSpec.Concepts.motion.parked
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.parked

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.motion.parked@w"
    concept := "drv.motion.parked"
    literals := []
    nats := []
    params := [("speed_tol", .lit (Units.micrometresPerSecond 100000) .metrePerSecond),
               ("min_duration", .lit (Units.seconds 2) .second)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The bicycle a at a position heading east with a sampled speed. -/
def bike (x : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.bicycle] (x, m 0) Build.east speed (m 1, cm 30, m 1)

/-- `holds` (compliant): A bicycle stands at rest beside the curb at every observation of the window behind, with no rider on it. -/
def holdsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [bike (m 0) (Units.metresPerSecond 0)] [] []

/-- The fails bicycle's speed at scene k: riding, a brief halt, riding off. -/
def failsSpeed (k : Nat) : Q :=
  if k == 2 || k == 3 then Units.metresPerSecond 0 else Units.metresPerSecond 2

/-- The fails bicycle's position at scene k (2 m per riding second). -/
def failsX (k : Nat) : Q :=
  match k with
  | 0 => m 0
  | 1 => m 2
  | 2 => m 4
  | 3 => m 4
  | 4 => m 6
  | _ => m 8

/-- `fails` (violated): A bicycle halts briefly and moves off again within the window behind: its speed is above the tolerance at some observation of the window. -/
def failsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [bike (failsX k) (failsSpeed k)] [] []

/-- `blind` (unknown): The source supplies no speed for the bicycle during the window. -/
def blindTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [bike (m 0) (Units.metresPerSecond 0)] [] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected
    window := some (3000, 5000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.parked
