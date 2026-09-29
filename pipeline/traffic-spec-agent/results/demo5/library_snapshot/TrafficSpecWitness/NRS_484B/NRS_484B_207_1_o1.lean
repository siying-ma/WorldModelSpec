/-
  Witnesses for NRS_484B_207_1_o1.

  The carriageway is a straight two-lane roadway running east: the right lane (region 10) is the
  strip -4 m ≤ y ≤ 0, the left lane (region 11) the strip 0 ≤ y ≤ 4 m. Both bodies are 5 m long
  and 2 m wide (half-extents 2.5 m, 1 m, 0.75 m) and hold an east heading throughout; a lane
  change is written as a lateral displacement at that heading, which is the witness's own
  simplification of the manoeuvre.

  The overtaking traces run for eleven instants one second apart. The overtaken body (track 2)
  holds y = -2 m at 10 m/s from x = 60 m; the subject (track 1) runs at 15 m/s from x = 40 m, so
  the overtaken body is 20 m ahead at the first instant, level at the fifth (k = 4) and 30 m
  behind at the last. The bodies overlap along the subject's axis at k = 3, 4, 5.

  In `forbid` the subject squeezes by at y = 0.5 m — 2.5 m between the centrelines, a lateral
  clearance of 0.5 m, well below the three feet of the reading. In `permit` it moves into the left
  lane at y = 2 m — 4 m between the centrelines, a clearance of 2 m — and returns only once the
  longitudinal gap is 15 m, leaving the overtaken body a 2.5 s headway at the last instant.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_207_1_o1
import TrafficSpec.Core.Builders

namespace TrafficSpecWitness.NRS_484B_207_1_o1

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n

/-- Half-length, half-width, half-height of both bodies. -/
private def car : Q × Q × Q := (cm 250, m 1, cm 75)

private def lanes : List Structure :=
  [ Build.lane 10 [(m (-200), m (-4)), (m 400, m (-4)), (m 400, Q.zero), (m (-200), Q.zero)]
      Build.east (left := some 11)
  , Build.lane 11 [(m (-200), Q.zero), (m 400, Q.zero), (m 400, m 4), (m (-200), m 4)]
      Build.east (right := some 10) ]

-- Binders ↦ tracks: d ↦ 1, overtaken ↦ 2

-- The overtaking geometry, shared by `forbid`, `permit` and `blind`.
private def subjectX (k : Nat) : Q := m (40 + 15 * (k : Int))
private def overtakenX (k : Nat) : Q := m (60 + 10 * (k : Int))
private def overtakenY : Q := m (-2)

/-- The subject squeezing past inside the clearance bound. -/
private def forbidY (k : Nat) : Q :=
  match k with
  | 0 => m (-2)
  | 1 => m (-1)
  | 8 => cm (-50)
  | 9 | 10 => m (-2)
  | _ => cm 50

/-- The subject passing from the left lane. -/
private def permitY (k : Nat) : Q :=
  match k with
  | 0 => m (-2)
  | 1 => m (-1)
  | 2 => cm 50
  | 7 => m 1
  | 8 => cm (-50)
  | 9 | 10 => m (-2)
  | _ => m 2

private def passUsers (y : Nat → Q) (k : Nat) : List RoadUser :=
  [ Build.user 1 [.motorVehicle] (subjectX k, y k) Build.east (mps 15) car
  , Build.user 2 [.motorVehicle] (overtakenX k, overtakenY) Build.east (mps 10) car ]

private def passTrace (y : Nat → Q) : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (passUsers y k) lanes []

/-- `forbid` (violated): Two vehicles in the same direction on a two-lane roadway. The subject closes on a slower vehicle ahead and passes it with a lateral surface gap well below the clearance bound throughout the overlap, emerging ahead of it: `drv.overtaking` holds, the passing side is left, and the lateral clearance is below `p.lateral_clearance`. -/
private def forbidTrace : Trace := passTrace forbidY

/-- `permit` (compliant): The same approach, but the subject moves fully into the adjacent left lane, holds a lateral surface gap comfortably above the clearance bound through the overlap and returns with a time gap above `p.headway`. -/
private def permitTrace : Trace := passTrace permitY

/-- `idle` (not_applicable): The subject follows the same vehicle for the whole trace at a constant distance and never comes alongside it: `drv.overtaking` never holds, so the rule does not judge the subject. -/
private def idleTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (40 + 10 * (k : Int)), overtakenY) Build.east (mps 10) car
      , Build.user 2 [.motorVehicle] (m (65 + 10 * (k : Int)), overtakenY) Build.east (mps 10) car ]
      lanes []

-- The `blind` source reports the clearance between two bodies as a measurement and has no extent
-- for either, so the atom it does not report cannot be recomputed from the kinematics.
private def blindLongGap (k : Nat) : Q :=
  Q.sub (Q.abs (Q.sub (overtakenX k) (subjectX k))) (m 5)
private def blindLatGap (k : Nat) : Q :=
  Q.sub (Q.abs (Q.sub overtakenY (forbidY k))) (m 2)

private def blindGaps (k : Nat) : List MeasuredRelation :=
  [ { a := 1, b := 2, surfaceGap := some (blindLongGap k, blindLatGap k) }
  , { a := 2, b := 1, surfaceGap := some (blindLongGap k, blindLatGap k) } ]

/-- `blind` (unknown): The forbid scene with the source declaring `rel.surface_gap` absent: the clearance between the two bodies is not observed, so the safe-distance operationalization cannot be decided and the rule reports unknown rather than compliance. -/
private def blindTrace : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    { Build.scene t (some 1)
        ((passUsers forbidY k).map fun u => Build.withKin u fun kin => { kin with extent := none })
        lanes []
      with relations := blindGaps k }

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_207_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("d", 1), ("overtaken", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"] ]

end TrafficSpecWitness.NRS_484B_207_1_o1
