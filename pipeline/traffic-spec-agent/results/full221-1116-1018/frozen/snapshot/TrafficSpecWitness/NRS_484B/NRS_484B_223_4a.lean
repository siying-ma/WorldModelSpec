/-
  Witnesses for NRS_484B_223_4a.

  Geometry (the witness's own figures, nowhere in the rule): an eastbound carriageway on highway
  100 (x -10 … 200, y -8 … 4). Through lane 101 (y 0 … 3.5) and, to its right, lane 102
  (y -3.5 … 0), both x 0 … 50. Lane 102 enters intersection 103 (x 50 … 70); a driveway entrance
  104 (x 28 … 34, y -8 … -3.5) lies on the highway's south side; a second intersection 105
  (x 150 … 170) lies on the same highway, entered by no lane of the scene. Every region lies on
  highway 100 (`ways`). The subject, track 1, a motor vehicle 4 m × 2 m, sits at x 20 in lane 102
  (or, in `idle`, in lane 101), heading east at 8 m/s; three instants 1 s apart. Lane 102 is a
  turn lane of side right, except in `branch_3` (side left) and `blind` (labelled a plain lane,
  the source not telling turn lanes, its side unread). Intentions are declared per scenario at
  the regions 103, 104, 105.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_4a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_4a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def hwy : RegionId := 100
def throughLane : RegionId := 101
def rightLane : RegionId := 102
def xing : RegionId := 103
def drive : RegionId := 104
def otherXing : RegionId := 105

def onHwy (s : Structure) : Structure := { s with ways := some [hwy] }

/-- The right-hand lane 102: its kind and side are the scenario's. -/
def lane102 (kind : StructureKind) (side : Option TurnSide) : Structure :=
  { Build.lane rightLane [(m 0, cm (-350)), (m 50, cm (-350)), (m 50, m 0), (m 0, m 0)] Build.east
      (left := some throughLane) (enters := some xing)
    with kind := kind, turnSide := side, ways := some [hwy] }

def structuresWith (kind : StructureKind) (side : Option TurnSide) : List Structure :=
  [ Build.rect hwy .highway (m (-10)) (m (-8)) (m 200) (m 4)
  , onHwy (Build.lane throughLane [(m 0, m 0), (m 50, m 0), (m 50, cm 350), (m 0, cm 350)] Build.east
      (right := some rightLane))
  , lane102 kind side
  , onHwy (Build.rect xing .intersection (m 50) (m (-8)) (m 70) (m 4))
  , onHwy (Build.rect drive .drivewayOrAlleyEntrance (m 28) (m (-8)) (m 34) (cm (-350)))
  , onHwy (Build.rect otherXing .intersection (m 150) (m (-8)) (m 170) (m 4)) ]

def subjectAt (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 20, y) Build.east (Units.metresPerSecond 8) (m 2, m 1, m 1)

def rt (target : RegionId) (v : Bool) : DeclaredIntent :=
  { vehicle := 1, target := target, values := [("int.right_turn", v)] }

def mkTrace (kind : StructureKind) (side : Option TurnSide) (y : Q) (intents : List DeclaredIntent) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [subjectAt y] (structuresWith kind side) [] (intents := intents)

/-- `forbid` (violated): The subject occupies a st.turn_lane of side right that enters intersection X; int.right_turn is declared false at X and at the driveway entrance lying on the same highway as the lane (its plan goes straight). -/
def forbidTrace : Trace :=
  mkTrace .turnLane (some .right) (cm (-175)) [rt xing false, rt drive false]

/-- `permit` (compliant): The subject occupies the right turn lane and int.right_turn is declared true at the intersection the lane enters. -/
def permitTrace : Trace :=
  mkTrace .turnLane (some .right) (cm (-175)) [rt xing true, rt drive false]

/-- `idle` (not_applicable): The subject occupies a through st.lane; no turn lane is occupied. -/
def idleTrace : Trace :=
  mkTrace .turnLane (some .right) (cm 175) [rt xing false, rt drive false]

/-- `blind` (unknown): The source labels lanes but cannot tell a turn lane; the subject occupies the rightmost lane with int.right_turn declared false at the intersection it enters and at the driveway entrance. -/
def blindTrace : Trace :=
  mkTrace .lane none (cm (-175)) [rt xing false, rt drive false]

/-- `branch_1` (compliant): The subject in the right turn lane declares int.right_turn false at the intersection the lane enters and true at a driveway entrance lying on the same highway as the lane. -/
def branch_1Trace : Trace :=
  mkTrace .turnLane (some .right) (cm (-175)) [rt xing false, rt drive true]

/-- `branch_2` (violated): The subject in the right turn lane declares int.right_turn true only at another intersection of the scene, one the lane does not enter, and false at the intersection the lane enters and at the driveway entrance on its highway. -/
def branch_2Trace : Trace :=
  mkTrace .turnLane (some .right) (cm (-175)) [rt xing false, rt drive false, rt otherXing true]

/-- `branch_3` (not_applicable): The subject occupies a turn lane of side left, its plan going straight: no right turn lane is occupied. -/
def branch_3Trace : Trace :=
  mkTrace .turnLane (some .left) (cm (-175)) [rt xing false, rt drive false]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_223_4a"
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
  , witness "blind" blindTrace (.unknown []) ["st.turn_lane"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_223_4a
