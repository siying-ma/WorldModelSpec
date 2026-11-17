/-
  Witnesses for NRS_484B_223_4a.

  Geometry (the witness's own figures, none in the rule): a northbound approach, y ∈ [0, 50],
  with a through lane (id 10, x ∈ [0, 4]) and to its right a lane x ∈ [4, 8] (id 11): a right
  turn lane in most scenes, a plain lane in `blind`, a left turn lane in `branch_1`. The
  approach enters an intersection (id 100, x ∈ [-10, 20], y ∈ [50, 70]); a driveway entrance
  (id 200, x ∈ [8, 12], y ∈ [20, 26]) meets the road on the right. The subject (track 1, a motor
  vehicle, half-extents 2 × 1 × 1 m) drives north at 5 m/s along x = 6 (turn lane) or x = 2
  (through lane), y = 10, 15, 20 at the three instants (1 s apart). Declarations of
  `int.right_turn` are given per scene at the intersection and at the driveway entrance.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_4a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_4a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def throughLane : Structure :=
  Build.lane 10 [(m 0, m 0), (m 4, m 0), (m 4, m 50), (m 0, m 50)] Build.north
    (right := some 11) (enters := some 100)

/-- The rightmost lane, labelled `lane`, the kind and side set by the caller. -/
def rightLane : Structure :=
  Build.lane 11 [(m 4, m 0), (m 8, m 0), (m 8, m 50), (m 4, m 50)] Build.north
    (left := some 10) (enters := some 100)

def rightTurnLane : Structure := { rightLane with kind := .turnLane, turnSide := some .right }
def leftTurnLane : Structure := { rightLane with kind := .turnLane, turnSide := some .left }

def intersection : Structure := Build.rect 100 .intersection (m (-10)) (m 50) (m 20) (m 70)
def driveway : Structure := Build.rect 200 .drivewayOrAlleyEntrance (m 8) (m 20) (m 12) (m 26)

def subjectAt (x : Int) (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m (10 + 5 * (k : Int))) Build.north (Units.metresPerSecond 5)
    (m 2, m 1, m 1)

def declare (target : RegionId) (v : Bool) : DeclaredIntent :=
  { vehicle := 1, target := target, values := [("int.right_turn", v)] }

def sceneWith (lane11 : Structure) (x : Int) (atX : Bool) (atDriveway : Bool) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt x k ]
      [ throughLane, lane11, intersection, driveway ]
      [ ]
      (intents := [declare 100 atX, declare 200 atDriveway])

/-- `forbid` (violated): The subject occupies a st.turn_lane of side right and int.right_turn is declared false at the intersection the lane enters and at every driveway_or_alley_entrance (its plan goes straight). -/
def forbidTrace : Trace := sceneWith rightTurnLane 6 false false

/-- `permit` (compliant): The subject occupies the right turn lane and int.right_turn is declared true at the intersection ahead. -/
def permitTrace : Trace := sceneWith rightTurnLane 6 true false

/-- `idle` (not_applicable): The subject occupies a through st.lane; no turn lane is occupied. -/
def idleTrace : Trace := sceneWith rightTurnLane 2 false false

/-- `blind` (unknown): The source labels lanes but cannot tell a turn lane; the subject occupies the rightmost lane with int.right_turn declared false. -/
def blindTrace : Trace := sceneWith rightLane 6 false false

/-- `branch_1` (not_applicable): the subject occupies a turn lane of side left, its plan going
    straight: no right turn lane is occupied. -/
def branch1Trace : Trace := sceneWith leftTurnLane 6 false false

/-- `branch_2` (compliant): the subject in the right turn lane declares no right turn at the
    intersection but a right turn into the driveway entrance on its right. -/
def branch2Trace : Trace := sceneWith rightTurnLane 6 false true

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
  , witness "branch_1" branch1Trace .notApplicable
  , witness "branch_2" branch2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_223_4a
