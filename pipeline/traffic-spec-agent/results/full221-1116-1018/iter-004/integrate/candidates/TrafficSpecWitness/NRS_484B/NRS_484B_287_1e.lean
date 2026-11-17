/-
  Witnesses for NRS_484B_287_1e.

  Geometry (metres, +x east, +y north). Intersection X (100) is the square (0,0)–(20,20). Two
  lanes enter it: LN (101), x 10..20, y −30..0, direction north; LE (102), x −30..0, y 0..10,
  direction east. A marked diagonal crosswalk CW (103) is the band |x − y| ≤ 2 running from the
  south-west corner to the north-east corner. A second intersection X2 (200), the square
  (100,100)–(120,120), exists only in branch_4.

  The pedestrian (track 1, class pedestrian) walks at 1.5 m/s on heading (0.6, 0.8): cosine 0.8
  with LN's north and 0.6 with LE's east, both well inside (0.26, 0.94]. Three instants 1 s apart:
  at t = 0 it stands at (−0.5, −0.5) on the corner (in CW, outside X); at t = 1 s it is at
  (0.4, 0.7), inside X and CW (the entry); at t = 2 s at (1.3, 1.9), still inside (no new entry).
  The pedestrian head P (300) stands at (15.4, 20.7): at the entry 25 m straight ahead along the
  heading (cosine 1 against 0.87, 25 m against a 40 m reach).

  idle: the pedestrian walks east at 1.5 m/s along y = 1, from (−0.5, 1) into X: along LE's
  direction and at right angles to LN's, so no diagonal crossing begins.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_287_1e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_287_1e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def xId : RegionId := 100
def x2Id : RegionId := 200
def headId : DeviceId := 300

def interX : Structure := Build.rect xId .intersection (m 0) (m 0) (m 20) (m 20)
def interX2 : Structure := Build.rect x2Id .intersection (m 100) (m 100) (m 120) (m 120)
def laneN : Structure :=
  Build.lane 101 [(m 10, m (-30)), (m 20, m (-30)), (m 20, m 0), (m 10, m 0)] Build.north
    (enters := some xId)
def laneE : Structure :=
  Build.lane 102 [(m (-30), m 0), (m 0, m 0), (m 0, m 10), (m (-30), m 10)] Build.east
    (enters := some xId)
def crosswalk : Structure :=
  { Build.region 103 .crosswalk [(m (-2), m 0), (m 0, m (-2)), (m 22, m 20), (m 20, m 22)] with
    marked := some true }

def baseStructures : List Structure := [interX, laneN, laneE, crosswalk]

/-- Heading north-east: (0.6, 0.8). -/
def diag : Vec := (Units.ratio 3 5, Units.ratio 4 5)

def pedDiag (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (cm (-50 + 90 * k), cm (-50 + 120 * k)) diag (cm 150) (cm 25, cm 25, cm 90)

def pedEast (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (cm (-50 + 150 * k), m 1) Build.east (cm 150) (cm 25, cm 25, cm 90)

/-- The pedestrian head across the diagonal, governing `governs`. -/
def head (governs : List RegionId) (st : PedSignalState) (countdown : Bool) : Device :=
  { Build.device headId .pedestrianSignal governs (some (cm 1540, cm 2070)) with
    pedState := some st, countdown := some countdown }

def diagTrace (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [pedDiag k] structures devices

/-- `forbid` (violated): At an intersection with a marked diagonal crosswalk, a pedestrian steps from the corner into the intersection walking north-east inside the marking while the pedestrian head governing that intersection, ahead of it 25 m away within the facing cone, shows dont_walk_steady. -/
def forbidTrace : Trace :=
  diagTrace baseStructures [head [xId] .dontWalkSteady false]

/-- `permit` (compliant): Same entry, while the faced head governing the intersection shows walk. -/
def permitTrace : Trace :=
  diagTrace baseStructures [head [xId] .walk false]

/-- `idle` (not_applicable): The pedestrian enters the intersection walking east, at right angles to the north-south lanes: no diagonal crossing begins. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [pedEast k] baseStructures [head [xId] .dontWalkSteady false]

/-- `blind` (unknown): Same entry as forbid, but the state of the faced pedestrian head is not observed. -/
def blindTrace : Trace :=
  diagTrace baseStructures [head [xId] .dontWalkSteady false]

/-- `branch_1` (compliant): Same entry while the faced head governing the intersection shows dont_walk_flashing with its countdown displayed. -/
def branch_1Trace : Trace :=
  diagTrace baseStructures [head [xId] .dontWalkFlashing true]

/-- `branch_2` (violated): Same entry while the faced head governing the intersection shows dont_walk_flashing without a countdown. -/
def branch_2Trace : Trace :=
  diagTrace baseStructures [head [xId] .dontWalkFlashing false]

/-- `branch_3` (compliant): Same diagonal entry, but the scene has no pedestrian signal head at all. -/
def branch_3Trace : Trace :=
  diagTrace baseStructures []

/-- `branch_4` (compliant): Same entry as forbid, and the faced head shows dont_walk_steady, but it is recorded as governing another intersection, not the one entered: it does not pertain to this crossing. -/
def branch_4Trace : Trace :=
  diagTrace (baseStructures ++ [interX2]) [head [x2Id] .dontWalkSteady false]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_287_1e"
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
  , witness "blind" blindTrace (.unknown []) ["dev.pedestrian_signal"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_484B_287_1e
