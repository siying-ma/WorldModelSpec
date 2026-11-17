/-
  Witnesses for NRS_484B_400_1_o1.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
    - intersection 1: the rectangle x ∈ [0, 20] m, y ∈ [-20, 20] m.
    - approach from the west, eastbound, two lanes each 4 m wide and 60 m long ending at x = 0,
      both entering intersection 1, both designated east:
        lane 2 (through lane): y ∈ [0, 4];
        lane 3: y ∈ [-4, 0], a turn lane of side right in forbid/permit/blind/branch_1, a plain
        lane in idle (no right turn lane there).
      The cosine between the two designated directions is 1, clear of the 0.9 bound.
    - subject 1, a motor vehicle (half extents 2 m × 1 m × 0.75 m), eastbound at 12 m/s, at
      x = -20, -8, 4 m at t = 0, 1, 2 s: it enters the intersection at t = 2 s, and at t = 1 s it
      is in lane 2 (y = 2 m: forbid, idle, blind, branch_1) or lane 3 (y = -2 m: permit).
    - the declaration current at every instant, for vehicle 1 at target 1: int.right_turn true,
      except branch_1 (int.left_turn true, int.right_turn false).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def intersection : Structure := Build.rect 1 .intersection (m 0) (m (-20)) (m 20) (m 20)

def throughLane : Structure :=
  Build.lane 2 [(m (-60), m 0), (m 0, m 0), (m 0, m 4), (m (-60), m 4)] Build.east
    (enters := some 1)

def rightLaneBase : Structure :=
  Build.lane 3 [(m (-60), m (-4)), (m 0, m (-4)), (m 0, m 0), (m (-60), m 0)] Build.east
    (enters := some 1)

def rightTurnLane : Structure :=
  { rightLaneBase with kind := .turnLane, turnSide := some .right }

def xAt (k : Nat) : Q := if k == 0 then m (-20) else if k == 1 then m (-8) else m 4

def subjectAt (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (xAt k, y) Build.east (Units.metresPerSecond 12) (m 2, m 1, cm 75)

def rightIntent : List DeclaredIntent :=
  [{ vehicle := 1, target := 1, values := [("int.right_turn", true)] }]

def leftIntent : List DeclaredIntent :=
  [{ vehicle := 1, target := 1, values := [("int.left_turn", true), ("int.right_turn", false)] }]

def mkTrace (y : Q) (laneThree : Structure) (intents : List DeclaredIntent) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k y ]
      [ intersection, throughLane, laneThree ]
      [ ]
      (intents := intents)

/-- `forbid` (violated): A single right st.turn_lane enters the intersection on the subject's approach; the subject, with int.right_turn declared at the intersection, occupies the adjacent through lane (same direction) at the observation before it enters the intersection. -/
def forbidTrace : Trace := mkTrace (m 2) rightTurnLane rightIntent

/-- `permit` (compliant): Same layout; the subject occupies the right turn lane at the observation before it enters the intersection, with int.right_turn declared. -/
def permitTrace : Trace := mkTrace (m (-2)) rightTurnLane rightIntent

/-- `idle` (not_applicable): The subject enters the intersection with int.right_turn declared, but no right turn lane enters the intersection from its approach (only through lanes). -/
def idleTrace : Trace := mkTrace (m 2) rightLaneBase rightIntent

/-- `blind` (unknown): Same as forbid, but the source declares st.lane_direction absent, so whether the right turn lane belongs to the subject's approach is unknown and the subject is not in it. -/
def blindTrace : Trace := mkTrace (m 2) rightTurnLane rightIntent

/-- `branch_1` (not_applicable): A right turn lane enters the intersection on the subject's approach; the subject enters from the through lane with int.left_turn declared and no int.right_turn: the duty does not arise. -/
def branch_1Trace : Trace := mkTrace (m 2) rightTurnLane leftIntent

/-- A second right turn lane on the subject's approach, y ∈ [-8, -4], eastbound, entering 1. -/
def secondRightTurnLane : Structure :=
  { Build.lane 4 [(m (-60), m (-8)), (m 0, m (-8)), (m 0, m (-4)), (m (-60), m (-4))] Build.east
      (enters := some 1)
    with kind := .turnLane, turnSide := some .right }

/-- The right turn lane of the southern approach, x ∈ [10, 14], y ∈ [-60, -20], northbound,
    entering 1: its direction makes a cosine of 0 with the subject's lane. -/
def southRightTurnLane : Structure :=
  { Build.lane 5 [(m 10, m (-60)), (m 14, m (-60)), (m 14, m (-20)), (m 10, m (-20))] Build.north
      (enters := some 1)
    with kind := .turnLane, turnSide := some .right }

def mkTraceWith (y : Q) (extra : List Structure) (intents : List DeclaredIntent) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k y ]
      ([ intersection, throughLane, rightTurnLane ] ++ extra)
      [ ]
      (intents := intents)

/-- `branch_2` (not_applicable): two right turn lanes enter the intersection on the subject's
    approach (no single right turn lane); the subject, int.right_turn declared, enters from the
    through lane. -/
def branch_2Trace : Trace := mkTraceWith (m 2) [secondRightTurnLane] rightIntent

/-- `branch_3` (violated): as forbid, and the southern approach's right turn lane also enters the
    intersection; it points north, so it is not the subject's highway's and the subject's approach
    still has a single right turn lane, which it is not in. -/
def branch_3Trace : Trace := mkTraceWith (m 2) [southRightTurnLane] rightIntent

/-- A left turn lane on the subject's approach, y ∈ [4, 8], eastbound, entering 1. -/
def leftTurnLane : Structure :=
  { Build.lane 6 [(m (-60), m 4), (m 0, m 4), (m 0, m 8), (m (-60), m 8)] Build.east
      (enters := some 1)
    with kind := .turnLane, turnSide := some .left }

/-- A second intersection upstream, x ∈ [-200, -180], which the subject never reaches. -/
def upstreamIntersection : Structure :=
  Build.rect 9 .intersection (m (-200)) (m (-20)) (m (-180)) (m 20)

/-- An eastbound right turn lane x ∈ [-260, -200], y ∈ [-4, 0], entering intersection 9. -/
def upstreamRightTurnLane : Structure :=
  { Build.lane 8 [(m (-260), m (-4)), (m (-200), m (-4)), (m (-200), m 0), (m (-260), m 0)] Build.east
      (enters := some 9)
    with kind := .turnLane, turnSide := some .right }

/-- `branch_4` (violated): as forbid, with a left turn lane on the same approach also entering the
    intersection; it is no right turn lane, so the single right turn lane stands and the subject is
    not in it. -/
def branch_4Trace : Trace := mkTraceWith (m 2) [leftTurnLane] rightIntent

/-- `branch_5` (violated): as forbid, with an eastbound right turn lane entering another
    intersection upstream; it is no lane of this intersection's approach, so the single right turn
    lane stands and the subject is not in it. -/
def branch_5Trace : Trace :=
  mkTraceWith (m 2) [upstreamIntersection, upstreamRightTurnLane] rightIntent

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_1_o1"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_400_1_o1
