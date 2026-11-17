/-
  Witnesses for NRS_484B_400_1_o2.

  Geometry (all figures the witness's own). The intersection 10 is the rectangle x ∈ [-20, 20],
  y ∈ [0, 30]. The subject's approach runs north below it: lane 11 (x ∈ [0, 4]) and lane 12
  (x ∈ [4, 8]), both northbound, both entering 10, ordinals 1 and 2 of 2 (ordinal 1 is the leftmost
  looking north). Variants add a right turn lane 14 (x ∈ [8, 12]), a second one 15 (x ∈ [12, 16]),
  a right turn lane 16 of the opposite (southbound) approach north of the intersection, a left turn
  lane 17 (x ∈ [-4, 0]), a northbound right turn lane 18 (x ∈ [30, 34]) entering a second
  intersection 20 (x ∈ [30, 60], y ∈ [0, 30]), or replace the lanes by an unlaned roadway segment
  13 (x ∈ [0, 8]).

  The subject (track 1, a motor vehicle) drives north at 15 m/s: y = -20, -5, 10 at t = 0, 1, 2 s,
  so it enters the intersection at t = 2 s and occupies its approach carrier at t = 1 s. The
  declared intention (target 10) is current at every scene. Cosines: northbound with northbound is
  1 (≥ 0.9); southbound with northbound is -1 (< 0.9), each a clear margin from the reading's value.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- An axis-aligned polygon from two corners, in metres. -/
def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

/-- The subject's northing at instant k: -20, -5, 10 m. -/
def yAt (k : Nat) : Q := m (-20 + 15 * (Int.ofNat k))

def intersection : Structure := Build.rect 10 .intersection (m (-20)) (m 0) (m 20) (m 30)

/-- A northbound approach lane entering the intersection. -/
def approachLane (id : Nat) (x0 x1 : Int) (left right : Option Nat) (ordinal count : Nat) : Structure :=
  Build.lane id (box x0 (-60) x1 0) Build.north left right (some ordinal) (some count) none (some 10)

def asTurnLane (s : Structure) (side : TurnSide) : Structure :=
  { s with kind := .turnLane, turnSide := some side }

def twoLanes : List Structure :=
  [ intersection
  , approachLane 11 0 4 none (some 12) 1 2
  , approachLane 12 4 8 (some 11) none 2 2 ]

def rightTurnIntent : List (IntId × Bool) := [("int.right_turn", true)]

def sceneWith (x : Q) (structures : List Structure) (values : List (IntId × Bool)) (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1)
    [ Build.user 1 [.motorVehicle] (x, yAt k) Build.north (Units.metresPerSecond 15) (m 2, cm 90, cm 75) ]
    structures
    []
    (intents := [{ vehicle := 1, target := 10, values := values }])

/-- `forbid` (violated): Two lanes of the subject's direction enter the intersection and no right turn lane; the subject, with int.right_turn declared at the intersection, occupies the lane of ordinal 1 of 2 at the observation before it enters. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneWith (m 2) twoLanes rightTurnIntent k t

/-- `permit` (compliant): Same layout; the subject occupies the lane of ordinal 2 of 2 at the observation before it enters, with int.right_turn declared. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneWith (m 6) twoLanes rightTurnIntent k t

/-- `idle` (not_applicable): Same layout; the subject enters from the lane of ordinal 1 with int.left_turn declared and no int.right_turn. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith (m 2) twoLanes [("int.left_turn", true), ("int.right_turn", false)] k t

/-- `blind` (unknown): Same as forbid, but the source declares st.lane_adjacency absent, so which lane is the extreme right lane is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneWith (m 2) twoLanes rightTurnIntent k t

/-- `branch_1` (compliant): The approach is an unlaned roadway recorded as a directed approach segment entering the intersection; the subject occupies it at the observation before entry with int.right_turn declared. -/
def roadwaySegment : Structure :=
  { Build.rect 13 .roadway (m 0) (m (-60)) (m 8) (m 0) with
    lane := some { direction := some Build.north, entersIntersection := some 10 } }

def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith (m 4) [intersection, roadwaySegment] rightTurnIntent k t

/-- `branch_2` (not_applicable): A single right turn lane enters the intersection on the subject's approach: the right turn lane alternative (the sibling node) governs, not this one. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith (m 2)
      [ intersection
      , approachLane 11 0 4 none (some 12) 1 3
      , approachLane 12 4 8 (some 11) (some 14) 2 3
      , asTurnLane (approachLane 14 8 12 (some 12) none 3 3) .right ]
      rightTurnIntent k t

/-- `branch_3` (violated): two right turn lanes enter the intersection on the subject's approach,
    so the highway has no single right turn lane; the subject is in lane 1 of 4. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith (m 2)
      [ intersection
      , approachLane 11 0 4 none (some 12) 1 4
      , approachLane 12 4 8 (some 11) (some 14) 2 4
      , asTurnLane (approachLane 14 8 12 (some 12) (some 15) 3 4) .right
      , asTurnLane (approachLane 15 12 16 (some 14) none 4 4) .right ]
      rightTurnIntent k t

/-- `branch_4` (violated): the only right turn lane entering the intersection serves the opposite
    (southbound) approach, cosine -1 with the subject's lane; the subject is in lane 1 of 2. -/
def oppositeRightTurnLane : Structure :=
  asTurnLane (Build.lane 16 (box (-8) 30 (-4) 90) Build.south none none (some 1) (some 2) none (some 10)) .right

def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith (m 2) (twoLanes ++ [oppositeRightTurnLane]) rightTurnIntent k t

/-- `branch_5` (violated): a single left turn lane on the subject's approach is no right turn lane;
    the subject is in through lane 2 of 3, the extreme right lane being 3. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith (m 2)
      [ intersection
      , asTurnLane (approachLane 17 (-4) 0 none (some 11) 1 3) .left
      , approachLane 11 0 4 (some 17) (some 12) 2 3
      , approachLane 12 4 8 (some 11) none 3 3 ]
      rightTurnIntent k t

/-- `branch_6` (violated): a northbound right turn lane exists, but it enters another
    intersection (20, east of the first), not the one the subject enters; the subject is in lane 1
    of 2 of its own approach. -/
def otherIntersection : Structure := Build.rect 20 .intersection (m 30) (m 0) (m 60) (m 30)

def otherRightTurnLane : Structure :=
  asTurnLane (Build.lane 18 (box 30 (-60) 34 0) Build.north none none (some 1) (some 1) none (some 20)) .right

def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith (m 2) (twoLanes ++ [otherIntersection, otherRightTurnLane]) rightTurnIntent k t

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_1_o2"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.NRS_484B_400_1_o2
