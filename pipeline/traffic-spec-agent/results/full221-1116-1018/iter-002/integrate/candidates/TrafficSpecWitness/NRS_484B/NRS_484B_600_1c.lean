/-
  Witnesses for NRS_484B_600_1c.

  Geometry: two parallel eastbound lanes, lane 10 (y ∈ [-2, 2]) and lane 11 (y ∈ [2, 6]), both
  x ∈ [0, 300]. The subject (track 1, a motor vehicle, half-extents 2 × 1 × 1 m) drives east on the
  centre of lane 10, starting at x = 50 and advancing 20 m per instant over 3 instants 1 s apart, so
  it stays in lane 10 and never overlaps lane 11. Sign 100 is a speed limit sign posting 45 mph
  (20.1168 m/s); in `forbid`/`blind` it is a maximum sign on lane 10, in `idle` a maximum sign on
  lane 11 only, in `branch_1` a minimum sign on lane 10. The subject's speed is 24 m/s (forbid,
  idle, branch_1), 19 m/s (permit) or not supplied (blind). Every figure is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneA : Structure := Build.rect 10 .lane (m 0) (m (-2)) (m 300) (m 2)
def laneB : Structure := Build.rect 11 .lane (m 0) (m 2) (m 300) (m 6)

def subjectAt (k : Nat) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (50 + 20 * (k : Int)), m 0) Build.east speed (m 2, m 1, m 1)

def postedValue : Q := Units.mph 45

def sceneWith (k : Nat) (t : Timestamp) (u : RoadUser) (devs : List Device) : Scene :=
  Build.scene t (some 1) [u] [laneA, laneB] devs

/-- `forbid` (violated): A maximum speed limit sign of 20.1 m/s governs the lane the subject car occupies; kin.speed is 24 m/s. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith k t (subjectAt k (Units.metresPerSecond 24))
      [Build.speedLimit 100 [10] postedValue .maximum]

/-- `permit` (compliant): Same sign; kin.speed is 19 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith k t (subjectAt k (Units.metresPerSecond 19))
      [Build.speedLimit 100 [10] postedValue .maximum]

/-- `idle` (not_applicable): No speed limit sign governs any region the subject car occupies.
    The only sign is a maximum sign governing lane 11, which the subject does not occupy. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith k t (subjectAt k (Units.metresPerSecond 24))
      [Build.speedLimit 100 [11] postedValue .maximum]

/-- `blind` (unknown): A maximum sign governs the subject's lane; the source does not supply kin.speed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith k t (Build.withKin (subjectAt k (Units.metresPerSecond 24)) fun kn => { kn with speed := none })
      [Build.speedLimit 100 [10] postedValue .maximum]

/-- `branch_1` (not_applicable): Only a minimum speed limit sign governs the subject's lane; the subject travels faster than its value. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith k t (subjectAt k (Units.metresPerSecond 24))
      [Build.speedLimit 100 [10] postedValue .minimum]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1c"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_600_1c
