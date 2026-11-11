/-
  Witnesses for NRS_484B_769.

  One straight carriageway running east: a roadway 100 m long, 10 m wide (y from -5 to 5), with a
  sidewalk 3 m wide along its north edge (y from 5 to 8). The rider x (track 1) rides east at
  4 m/s, 1 m long and 0.6 m wide; three observations one second apart. On the roadway its
  reference point is on y = 0, mid-carriageway; on the sidewalk (branch_3) it is on y = 650 cm,
  mid-sidewalk, 1.5 m from the roadway's edge. Every signal the rule reads is set in every scene:
  the turn indicator and the arm signal are decided, never left unobserved, except the arm signal
  that the blind witness masks. No figure here appears in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_769
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_769

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- The roadway and the sidewalk along its north edge. -/
def structures : List Structure :=
  [ Build.rect 10 .roadway (m 0) (m (-5)) (m 100) (m 5)
  , Build.rect 11 .sidewalk (m 0) (m 5) (m 100) (m 8) ]

/-- The rider x at instant k, of the given class, at lateral offset `y`, showing the indicator
    state and the arm signal given. -/
def rider (cls : RoadUserClass) (y : Q) (ind : TurnIndicatorState) (arm : HandSignal) (k : Nat) : RoadUser :=
  Build.withSignals
    (Build.user 1 [cls] (Q.add (m 20) (Q.mul (m 4) (Q.ofInt k)), y) Build.east (Units.metresPerSecond 4)
      (cm 50, cm 30, cm 90))
    fun s => { s with turnIndicator := some ind, handSignal := some arm }

/-- A three-instant trace of the rider alone on the carriageway. -/
def riderTrace (cls : RoadUserClass) (y : Q) (ind : TurnIndicatorState) (arm : HandSignal) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ rider cls y ind arm k ] structures [ ]

/-- `forbid` (violated): An electric scooter rider on a roadway shows a lit right turn indicator and gives no arm signal (sig.hand_signal no_signal). -/
def forbidTrace : Trace := riderTrace .electricScooter (m 0) .right .noSignal

/-- `permit` (compliant): A bicycle rider on a roadway gives an arm signal of meaning left, with no indicator lit. -/
def permitTrace : Trace := riderTrace .bicycle (m 0) .off .left

/-- `idle` (not_applicable): A bicycle rider on a roadway gives no signal: no indicator lit and no arm signal. -/
def idleTrace : Trace := riderTrace .bicycle (m 0) .off .noSignal

/-- `blind` (unknown): As forbid, but the source does not observe arm signals. -/
def blindTrace : Trace := riderTrace .electricScooter (m 0) .right .noSignal

/-- `branch_1` (compliant): An electric scooter rider on a roadway shows a lit right indicator and extends the right arm horizontally to the right side; the source decodes the arm signal as meaning right. -/
def branch_1Trace : Trace := riderTrace .electricScooter (m 0) .right .right

/-- `branch_2` (violated): An electric bicycle rider on a roadway shows a lit right indicator while giving an arm signal of meaning left. -/
def branch_2Trace : Trace := riderTrace .electricBicycle (m 0) .right .left

/-- `branch_3` (not_applicable): An electric scooter rider on a sidewalk, not on the roadway, shows a lit right indicator with no arm signal. -/
def branch_3Trace : Trace := riderTrace .electricScooter (cm 650) .right .noSignal

/-- `branch_4` (violated): A bicycle rider on a roadway shows a lit left indicator and gives no arm signal. -/
def branch_4Trace : Trace := riderTrace .bicycle (m 0) .left .noSignal

/-- `branch_5` (violated): A bicycle rider on a roadway shows a lit left indicator while giving an arm signal of meaning right. -/
def branch_5Trace : Trace := riderTrace .bicycle (m 0) .left .right

/-- `branch_6` (compliant): A bicycle rider on a roadway shows a lit left indicator and gives the horizontal arm signal decoded as reentering. -/
def branch_6Trace : Trace := riderTrace .bicycle (m 0) .left .reEnter

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_769"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.hand_signal"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant ]

end TrafficSpecWitness.NRS_484B_769
