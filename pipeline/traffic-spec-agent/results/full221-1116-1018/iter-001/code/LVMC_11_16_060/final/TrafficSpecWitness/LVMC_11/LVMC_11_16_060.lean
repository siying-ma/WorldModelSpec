/-
  Witnesses for LVMC_11_16_060.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - highway 1: the public way, x 0…200 m, y −10…10 m;
  - lane 2: eastbound lane, x 0…200 m, y −2…2 m; lane 3: its left neighbour, y 2…6 m;
  - subject 1: a motor vehicle (half-extents 2 × 1 × 1 m) heading east at (50 + 10k, 0), in lane 2
    and on highway 1, over three instants 1 s apart;
  - speed limit sign 10 (45 mph) governing lane 2, lane 3 or nothing observed, by scenario.
  Speeds: 35 mph breaks the 25 mph limit by 10 mph; 20 mph keeps it by 5 mph.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_16_060
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_16_060

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 1 .highway (m 0) (m (-10)) (m 200) (m 10)
def lane2 : Structure :=
  Build.lane 2 [(m 0, m (-2)), (m 200, m (-2)), (m 200, m 2), (m 0, m 2)] Build.east (some 3) none
def lane3 : Structure :=
  Build.lane 3 [(m 0, m 2), (m 200, m 2), (m 200, m 6), (m 0, m 6)] Build.east none (some 2)

def structures : List Structure := [highway, lane2, lane3]

def subjectAt (k : Nat) (y : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (Q.add (m 50) (m (10 * (k : Int))), y) Build.east speed (m 2, m 1, m 1)

def sceneWith (k : Nat) (t : Timestamp) (y : Q) (speed : Q) (devices : List Device) : Scene :=
  Build.scene t (some 1) [subjectAt k y speed] structures devices

/-- `forbid` (violated): Subject on a street lane governed by no speed limit sign travels above twenty-five mph. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneWith k t (m 0) (Units.mph 35) []

/-- `permit` (compliant): Same, at or below twenty-five mph. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneWith k t (m 0) (Units.mph 20) []

/-- `idle` (not_applicable): The subject's lane is governed by a maximum speed limit sign (45 mph posting). -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith k t (m 0) (Units.mph 35) [Build.speedLimit 10 [2] (Units.mph 45) .maximum]

/-- `blind` (unknown): A speed limit sign is present but the source does not observe what it governs; subject above twenty-five mph. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith k t (m 0) (Units.mph 35)
      [{ Build.speedLimit 10 [] (Units.mph 45) .maximum with governsObserved := false }]

/-- `branch_1` (violated): a minimum speed sign governs the subject's lane; it posts no different
    maximum, and the subject travels above twenty-five mph. -/
def branch1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith k t (m 0) (Units.mph 35) [Build.speedLimit 10 [2] (Units.mph 45) .minimum]

/-- `branch_2` (violated): a maximum speed sign governs the neighbouring lane only, not the one the
    subject occupies; the subject travels above twenty-five mph. -/
def branch2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith k t (m 0) (Units.mph 35) [Build.speedLimit 10 [3] (Units.mph 45) .maximum]

/-- `branch_3` (not_applicable): the subject is off the highway (40 m north of its boundary) and
    travels above twenty-five mph: not on a street or highway. -/
def branch3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneWith k t (m 50) (Units.mph 35) []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_16_060"
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
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .violated
  , witness "branch_3" branch3Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_16_060
