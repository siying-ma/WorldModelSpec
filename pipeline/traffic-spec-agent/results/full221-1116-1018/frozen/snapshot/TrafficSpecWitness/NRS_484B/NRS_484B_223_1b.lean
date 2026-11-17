/-
  Witnesses for NRS_484B_223_1b.

  Geometry (the witness's own figures, none of them in the rule):
  - An eastbound carriageway with two lanes in its direction: lane 10, the right lane
    (y 0 … 3.5 m, ordinal 2 of 2, left neighbour 11), and lane 11, the left lane (y 3.5 … 7 m,
    ordinal 1 of 2, right neighbour 10); x −50 … 200 m. The `idle` scene has a single eastbound
    lane 20 (y 0 … 3.5 m, ordinal 1 of 1).
  - The subject, track 1, a motor vehicle 4 m × 2 m, heads east at 10 m/s, at x = 10·k m at
    instant k (1 s apart). Its centre is at y 1.75 m (in lane 10 only) before the move, at
    y 3.5 m at the instant of the move (its body across both lanes; occupancy stated), and at
    y 5.25 m (in lane 11 only) after it; a move to the right mirrors this.
  - The lane-change concept reads the previous observation, so each witness judges the instants
    from the second one on (`window`).
  - branch_1: track 2, a motor vehicle in lane 11 at (−12 + 16·k, 4.5) m, 16 m/s east: at the move
    (k = 1) its centre is 6 m behind and 1 m to the left of the subject's, closing at 6 m/s, so the
    closest approach is in 1 s at a centre distance of 1 m (horizon 3 s, clearance 3 m).
  - branch_3: track 2, in lane 11 alongside at (10·k, 5) m at the subject's speed: at the move the
    bodies overlap (contact) while the centres do not approach.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_1b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_1b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The right lane of the two eastbound lanes. -/
def laneRight : Structure :=
  Build.lane 10 [(m (-50), m 0), (m 200, m 0), (m 200, cm 350), (m (-50), cm 350)] Build.east
    (some 11) none (some 2) (some 2)

/-- The left lane of the two eastbound lanes. -/
def laneLeft : Structure :=
  Build.lane 11 [(m (-50), cm 350), (m 200, cm 350), (m 200, m 7), (m (-50), m 7)] Build.east
    none (some 10) (some 1) (some 2)

/-- The only lane of a one-lane eastbound direction. -/
def laneOnly : Structure :=
  Build.lane 20 [(m (-50), m 0), (m 200, m 0), (m 200, cm 350), (m (-50), cm 350)] Build.east
    none none (some 1) (some 1)

def subjectAt (x y : Q) (ind : TurnIndicatorState) (hand : HandSignal) : RoadUser :=
  Build.withSignals
    (Build.user 1 [.motorVehicle] (x, y) Build.east (Units.metresPerSecond 10) (m 2, m 1, cm 75))
    (fun s => { s with turnIndicator := some ind, handSignal := some hand })

/-- A move from lane 10 into lane 11 (left) at instant j: centre y and occupancy at instant k. -/
def leftPhase (j k : Nat) : Q × List (TrackId × RegionId) :=
  if k < j then (cm 175, [(1, 10)])
  else if k = j then (cm 350, [(1, 10), (1, 11)])
  else (cm 525, [(1, 11)])

/-- A move from lane 11 into lane 10 (right) at instant j. -/
def rightPhase (j k : Nat) : Q × List (TrackId × RegionId) :=
  if k < j then (cm 525, [(1, 11)])
  else if k = j then (cm 350, [(1, 11), (1, 10)])
  else (cm 175, [(1, 10)])

def noOthers (_k : Nat) : List RoadUser × List (TrackId × RegionId) := ([], [])

/-- A trace of n instants 1 s apart on the two-lane carriageway, the move at instant j. -/
def moveTrace (n j : Nat) (phase : Nat → Nat → Q × List (TrackId × RegionId))
    (ind : Nat → TurnIndicatorState) (hand : Nat → HandSignal)
    (others : Nat → List RoadUser × List (TrackId × RegionId)) : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    let p := phase j k
    let o := others k
    Build.scene t (some 1)
      (subjectAt (m (10 * Int.ofNat k)) p.1 (ind k) (hand k) :: o.1)
      [laneRight, laneLeft]
      []
      (some (p.2 ++ o.2))

/-- `forbid` (violated): On a carriageway with two lanes in its direction the subject, in the right lane, comes to overlap the left lane while sig.turn_indicator is off and sig.hand_signal no_signal. -/
def forbidTrace : Trace :=
  moveTrace 3 1 leftPhase (fun _ => .off) (fun _ => .noSignal) noOthers

/-- `permit` (compliant): The subject's left indicator is on for 3 s before and during its move into the left lane; no other road user is in the scene. -/
def permitTrace : Trace :=
  moveTrace 5 3 leftPhase (fun _ => .left) (fun _ => .noSignal) noOthers

/-- `idle` (not_applicable): The subject occupies a lane whose direction has one lane (st.lane_adjacency count 1) and keeps to it. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (m (10 * Int.ofNat k)) (cm 175) .off .noSignal ]
      [ laneOnly ]
      []
      (some [(1, 20)])

/-- `blind` (unknown): The subject moves into the left neighbouring lane; sig.turn_indicator is not observed and sig.hand_signal reads no_signal; no other road user. -/
def blindTrace : Trace :=
  moveTrace 3 1 leftPhase (fun _ => .left) (fun _ => .noSignal) noOthers

/-- `branch_1` (violated): The subject signals left and moves into the left lane while a faster vehicle there has a closest approach to it in 1 s at a centre distance of 1 m. -/
def branch_1Trace : Trace :=
  moveTrace 3 1 leftPhase (fun _ => .left) (fun _ => .noSignal) fun k =>
    ([Build.user 2 [.motorVehicle] (m (-12 + 16 * Int.ofNat k), cm 450) Build.east
        (Units.metresPerSecond 16) (m 2, m 1, cm 75)], [(2, 11)])

/-- `branch_2` (compliant): the subject's indicator is off, but its arm signals left at the
    observation before the move and at the move into the left lane; no other road user. -/
def branch_2Trace : Trace :=
  moveTrace 3 1 leftPhase (fun _ => .off) (fun _ => .left) noOthers

/-- `branch_3` (violated): the subject signals left and moves into the left lane while a vehicle
    alongside there, at its own speed, is in contact with its body. -/
def branch_3Trace : Trace :=
  moveTrace 3 1 leftPhase (fun _ => .left) (fun _ => .noSignal) fun k =>
    ([Build.user 2 [.motorVehicle] (m (10 * Int.ofNat k), cm 500) Build.east
        (Units.metresPerSecond 10) (m 2, m 1, cm 75)], [(2, 11)])

/-- `branch_4` (compliant): the subject, in the left lane, signals right before and during its
    move into the right lane; no other road user. -/
def branch_4Trace : Trace :=
  moveTrace 3 1 rightPhase (fun _ => .right) (fun _ => .noSignal) noOthers

/-- `branch_5` (violated): the subject's left indicator comes on only at the observation of its
    move into the left lane, not at the one before. -/
def branch_5Trace : Trace :=
  moveTrace 3 1 leftPhase (fun k => if k = 0 then .off else .left) (fun _ => .noSignal) noOthers

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (1000, 2000)) : Scenario :=
  { name := name
    rule := "NRS_484B_223_1b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant (window := some (1000, 4000))
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_223_1b
