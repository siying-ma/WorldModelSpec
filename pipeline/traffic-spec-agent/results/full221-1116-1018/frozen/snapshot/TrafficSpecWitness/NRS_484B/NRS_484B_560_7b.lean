/-
  Witnesses for NRS_484B_560_7b.

  Geometry (the witness's own figures; none appears in the rule):
  - lane 10: x ∈ [-100, 100], y ∈ [-2, 2], traffic eastbound;
  - railway crossing 20: x ∈ [0, 6], y ∈ [-2, 2], laid across the lane;
  - subject (track 1): a motor vehicle heading east, half-extents 2 m × 1 m, so its front is at x + 2;
    its distance to the crossing is −(x + 2) while x + 2 < 0, and it overlaps the crossing from x = −2.
  - Occupancy is stated: the subject always occupies lane 10, and crossing 20 only at its entry,
    the last observation of each trace (front at x = 1).
  - Three-observation approach (1 s apart): front at −20 m (beyond the 15.2 m reach), −8 m, then +1 m
    (entry), at 10 m/s.
  - Stop-sign approaches (branch_1, branch_2): front at −60, −30, −6, −3 m, then the entry.
  - history_boundary: the recording starts with the front 10 m from the crossing (inside the reach),
    3 m/s, never halting: −10, −7, −4 m, then the entry.
  - branch_8: a rail vehicle (track 2) 8 m north of the lane at x = 4, heading south at 20 m/s at the
    entry: closest approach of the centres after 0.42 s at about 0.9 m (horizon 3 s, clearance 3 m).

  Devices (all govern lane 10): railway signal 30, traffic signal 31, police officer 32, stop sign 33,
  yield sign 34.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_560_7b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_560_7b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneL : Structure := Build.rect 10 .lane (m (-100)) (m (-2)) (m 100) (m 2)
def crossingX : Structure := Build.rect 20 .railwayCrossing (m 0) (m (-2)) (m 6) (m 2)

/-- The subject car, centre at (x, 0), heading east at speed v. -/
def car (x v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, m 0) Build.east v (m 2, m 1, cm 75)

def occ (entered : Bool) : List (TrackId × RegionId) :=
  if entered then [(1, 10), (1, 20)] else [(1, 10)]

def sceneAt (t : Timestamp) (x v : Q) (entered : Bool) (structures : List Structure)
    (devices : List Device) (others : List RoadUser := []) : Scene :=
  Build.scene t (some 1) (car x v :: others) structures devices (occupies := some (occ entered))

/-- The three-observation approach: front at −20, −8, then +1 m (entry), at 10 m/s. -/
def approach3 (devices : List Device) (others : Nat → List RoadUser := fun _ => []) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let x := match k with | 0 => m (-22) | 1 => m (-10) | _ => m (-1)
    sceneAt t x (Units.metresPerSecond 10) (k == 2) [laneL, crossingX] devices (others k)

/-- An approach through the listed (centre x, speed) pairs; the last one is the entry. -/
def approachList (pts : List (Q × Q)) (devices : List Device) : Trace :=
  Build.trace pts.length 0 (Units.seconds 1) fun k t =>
    let p := pts.getD k (m 0, m 0)
    sceneAt t p.1 p.2 (k + 1 == pts.length) [laneL, crossingX] devices

def railway (lights : RailLights) (gate : GateState) : Device :=
  { Build.device 30 .railwaySignalOrGate [10] with railLights := some lights, gate := some gate }

/-- `forbid` (violated): Railway signal lights flashing, gate down, governing the subject's approach lane; the subject car drives around the gate and its footprint comes to overlap the railway crossing. -/
def forbidTrace : Trace := approach3 [railway .flashing .down]

/-- `permit` (compliant): Railway signal lights dark, gate up, governing the subject's lane; the subject car enters the crossing. -/
def permitTrace : Trace := approach3 [railway .dark .up]

/-- `idle` (not_applicable): The subject car drives along a street with no railway crossing; it never overlaps one. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let x := match k with | 0 => m (-22) | 1 => m (-10) | _ => m (-1)
    sceneAt t x (Units.metresPerSecond 10) false [laneL] []

/-- `blind` (unknown): The subject car enters a crossing; a railway signal with lights flashing stands at the crossing but the source does not observe which regions it governs. -/
def blindTrace : Trace :=
  approach3 [{ Build.device 30 .railwaySignalOrGate [] with
               governsObserved := false, railLights := some .flashing, gate := some GateState.none }]

/-- `branch_1` (compliant): A stop sign governs the subject's lane at the crossing; the subject car approaches from 60 m, halts 6 m from the crossing (kin.speed 0), then enters. -/
def branch_1Trace : Trace :=
  approachList [(m (-62), m 10), (m (-32), m 10), (m (-8), m 0), (m (-5), m 3), (m (-1), m 3)]
    [Build.sign 33 .stopSign [10]]

/-- `branch_2` (violated): A stop sign governs the subject's lane; the subject approaches from 60 m and enters the crossing at 8 m/s without halting. -/
def branch_2Trace : Trace :=
  approachList [(m (-62), m 8), (m (-32), m 8), (m (-8), m 8), (m (-5), m 8), (m (-1), m 8)]
    [Build.sign 33 .stopSign [10]]

/-- `branch_3` (violated): A police officer (dev.human_direction role police_officer, indication stop) governs the subject's lane; the subject enters the crossing. -/
def branch_3Trace : Trace :=
  approach3 [{ Build.device 32 .humanDirection [10] with
               humanRole := some .policeOfficer, humanIndication := some .stop }]

/-- `branch_4` (compliant): The subject enters an unsignalled crossing with no device governing its lane; no other road user in the scene. -/
def branch_4Trace : Trace := approach3 []

/-- `history_boundary` (unknown): A stop sign governs the subject's lane; the recording begins with the subject 10 m from the crossing moving at 3 m/s, no halt is observed, and it enters the crossing. -/
def history_boundaryTrace : Trace :=
  approachList [(m (-12), m 3), (m (-9), m 3), (m (-6), m 3), (m (-1), m 3)]
    [Build.sign 33 .stopSign [10]]

/-- `branch_5` (violated): railway lights flashing, no gate; the subject enters. -/
def branch_5Trace : Trace := approach3 [railway .flashing GateState.none]

/-- `branch_6` (violated): railway lights dark, gate lowering; the subject enters. -/
def branch_6Trace : Trace := approach3 [railway .dark .lowering]

/-- `branch_7` (violated): a traffic signal showing circular red governs the lane; the subject enters. -/
def branch_7Trace : Trace := approach3 [Build.signal 31 [10] [.circularRed]]

/-- The train of branch_8: 8 m north of the lane at the entry, heading south at 20 m/s. -/
def train (k : Nat) : RoadUser :=
  let y := match k with | 0 => m 48 | 1 => m 28 | _ => m 8
  Build.user 2 [.railVehicle] (m 4, y) Build.south (m 20) (m 3, cm 150, m 2)

/-- `branch_8` (violated): a yield sign governs the lane; the subject enters while a train closes to
    about 0.9 m centre to centre within 0.42 s. -/
def branch_8Trace : Trace := approach3 [Build.sign 34 .yieldSign [10]] (fun k => [train k])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_560_7b"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the subject's approach to the crossing from beyond p.railroad_crossing_approach_reach, which lies before the recording's first observation")
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated ]

end TrafficSpecWitness.NRS_484B_560_7b
