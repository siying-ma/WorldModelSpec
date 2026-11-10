/-
  Witnesses for NRS_484B_769.

  Geometry: a roadway `1` from x = 0 to 200 m, y = -5 to 5 m, and a sidewalk `2` beside it from
  y = 5 to 8 m. x (track 1) rides east at 5 m/s along y = 0 (on the roadway) or y = 6.5 m (on the
  sidewalk), from x = 10 m, over three instants one second apart; half-length 1 m, half-width
  30 cm, half-height 1 m. Its turn indicator and arm signal are set per scene and held throughout.
  Every figure here is the witness's own and appears nowhere in the rule; the rule reads no
  parameter.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_769
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_769

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def roadway : Structure := Build.rect 1 .roadway (m 0) (m (-5)) (m 200) (m 5)
def sidewalk : Structure := Build.rect 2 .sidewalk (m 0) (m 5) (m 200) (m 8)

/-- x at instant `k`, at lateral position `y`, with its indicator and arm signal. -/
def rider (cls : RoadUserClass) (k : Nat) (y : Q) (ti : TurnIndicatorState) (hs : HandSignal)
    : RoadUser :=
  Build.withSignals
    (Build.user 1 [cls] (m (10 + 5 * (k : Int)), y) Build.east (Units.metresPerSecond 5)
      (m 1, cm 30, m 1))
    fun s => { s with turnIndicator := some ti, handSignal := some hs }

/-- A three-instant ride of x with the given signals. -/
def ride (cls : RoadUserClass) (y : Q) (ti : TurnIndicatorState) (hs : HandSignal) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [rider cls k y ti hs] [roadway, sidewalk] []

/-- `forbid` (violated): x, an electric scooter, rides on a roadway with its right turn indicator flashing and no arm signal (sig.hand_signal no_signal). -/
def forbidTrace : Trace := ride .electricScooter (m 0) .right .noSignal

/-- `permit` (compliant): x, a bicycle, rides alone on a roadway and signals a left turn by arm (sig.hand_signal left); it has no turn indicator lit. -/
def permitTrace : Trace := ride .bicycle (m 0) .off .left

/-- `idle` (not_applicable): x, a bicycle, rides on a sidewalk with its turn indicator lit and no arm signal; it never occupies a roadway. -/
def idleTrace : Trace := ride .bicycle (Q.mk' 13 2) .left .noSignal

/-- `blind` (unknown): x, an electric bicycle on a roadway, shows its left turn indicator; the source declares sig.hand_signal absent. -/
def blindTrace : Trace := ride .electricBicycle (m 0) .left .noSignal

/-- `branch_1` (compliant): x, an electric bicycle on a roadway, shows its right turn indicator and extends its right arm horizontally to the right, which the source reads as sig.hand_signal right. -/
def branch_1Trace : Trace := ride .electricBicycle (m 0) .right .right

/-- `branch_2` (compliant): x, a bicycle on a roadway, gives no signal of any kind and has no indicator lit. -/
def branch_2Trace : Trace := ride .bicycle (m 0) .off .noSignal

/-- `branch_3` (compliant): x, a bicycle on a roadway, shows its left indicator and gives the left-turn arm signal. -/
def branch_3Trace : Trace := ride .bicycle (m 0) .left .left

/-- `branch_4` (violated): x, an electric bicycle on a roadway, shows its left indicator and gives no arm signal. -/
def branch_4Trace : Trace := ride .electricBicycle (m 0) .left .noSignal

/-- `branch_5` (violated): x, a bicycle on a roadway, shows its right indicator and gives no arm signal. -/
def branch_5Trace : Trace := ride .bicycle (m 0) .right .noSignal

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
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_769
