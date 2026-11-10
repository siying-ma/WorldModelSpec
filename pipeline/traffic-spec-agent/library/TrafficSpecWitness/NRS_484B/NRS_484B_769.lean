/-
  Witnesses for NRS_484B_769.

  Geometry: a roadway `10` from x = -50 m to 50 m, y = 0 to 7 m, and a sidewalk `20` beside it,
  y = 9 m to 11 m, with a 2 m verge between them that neither covers. The rider x (track 1) rides
  east at 5 m/s, half-extent 0.9 m × 0.3 m × 0.9 m, its reference point at y = 2 m on the
  roadway (or y = 10 m on the sidewalk in `idle`), three instants one second apart. Each scene
  states the rider's turn indicator and arm signal; nothing looks back in time, so no window is
  named. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_769
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_769

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def roadway : Structure := Build.rect 10 .roadway (m (-50)) (m 0) (m 50) (m 7)
def sidewalk : Structure := Build.rect 20 .sidewalk (m (-50)) (m 9) (m 50) (m 11)

/-- The rider at instant `k`, at lateral offset `y`, with its lamp and arm signals. -/
def rider (cls : RoadUserClass) (k : Nat) (y : Q) (ind : Option TurnIndicatorState)
    (hand : Option HandSignal) : RoadUser :=
  Build.withSignals
    (Build.user 1 [cls] (Q.add (m (-20)) (m (5 * (k : Int))), y) Build.east (Units.metresPerSecond 5)
      (cm 90, cm 30, cm 90))
    fun s => { s with turnIndicator := ind, handSignal := hand }

def ride (cls : RoadUserClass) (y : Q) (ind : Option TurnIndicatorState)
    (hand : Option HandSignal) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider cls k y ind hand ]
      [ roadway, sidewalk ]
      [ ]

/-- `forbid` (violated): x, an electric bicycle, rides on a roadway with its right turn indicator flashing and no arm signal (sig.hand_signal no_signal). -/
def forbidTrace : Trace := ride .electricBicycle (m 2) (some .right) (some .noSignal)

/-- `permit` (compliant): x, a bicycle, rides alone on a roadway and signals a left turn by arm (sig.hand_signal left); it has no turn indicator lit. -/
def permitTrace : Trace := ride .bicycle (m 2) (some .off) (some .left)

/-- `idle` (not_applicable): x, a bicycle, rides on a sidewalk with its turn indicator lit and no arm signal; it never occupies a roadway. -/
def idleTrace : Trace := ride .bicycle (m 10) (some .left) (some .noSignal)

/-- `blind` (unknown): x, an electric bicycle on a roadway, shows its left turn indicator; the source declares sig.hand_signal absent. -/
def blindTrace : Trace := ride .electricBicycle (m 2) (some .left) none

/-- `branch_1` (compliant): x, an electric bicycle on a roadway, shows its right turn indicator and extends its right arm horizontally to the right, which the source reads as sig.hand_signal right. -/
def branch_1Trace : Trace := ride .electricBicycle (m 2) (some .right) (some .right)

/-- `branch_2` (compliant): x, a bicycle on a roadway, gives no signal of any kind and has no indicator lit. -/
def branch_2Trace : Trace := ride .bicycle (m 2) (some .off) (some .noSignal)

/-- `branch_3` (violated): x, a bicycle on a roadway, shows its left turn indicator and gives no arm signal (sig.hand_signal no_signal). -/
def branch_3Trace : Trace := ride .bicycle (m 2) (some .left) (some .noSignal)

/-- `branch_4` (compliant): x, a bicycle on a roadway, shows its left turn indicator and signals left by arm. -/
def branch_4Trace : Trace := ride .bicycle (m 2) (some .left) (some .left)

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
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_484B_769
