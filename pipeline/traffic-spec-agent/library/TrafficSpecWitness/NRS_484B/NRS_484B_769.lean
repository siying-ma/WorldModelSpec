/-
  Witnesses for NRS_484B_769.

  Geometry: a roadway 100 m long and 10 m wide (x 0…100, y −5…5) with a sidewalk 3 m wide along
  its north edge (y 5…8). Track 1, the rider (half-extents 90 cm × 30 cm × 60 cm), heads east at
  5 m/s; on the roadway its centre is at y = 2 m, on the sidewalk at y = 6.5 m, well inside either
  polygon. Three instants, one second apart; the signals are held throughout. Every figure here
  is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_769
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_769

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def roadway : Structure := Build.rect 10 .roadway (m 0) (m (-5)) (m 100) (m 5)
def sidewalk : Structure := Build.rect 11 .sidewalk (m 0) (m 5) (m 100) (m 8)

/-- The rider: its class, the lateral position of its centre, its indicator and its arm signal. -/
def rider (cls : RoadUserClass) (y : Q) (ti : TurnIndicatorState) (hs : HandSignal) (k : Nat) : RoadUser :=
  Build.withSignals
    (Build.user 1 [cls] (Q.add (m 40) (m (5 * k)), y) Build.east (Units.metresPerSecond 5) (cm 90, cm 30, cm 60))
    fun s => { s with turnIndicator := some ti, handSignal := some hs }

/-- A three-instant trace of the rider alone beside the roadway and the sidewalk. -/
def riderTrace (cls : RoadUserClass) (y : Q) (ti : TurnIndicatorState) (hs : HandSignal) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider cls y ti hs k ]
      [ roadway, sidewalk ]
      [ ]

def onRoad : Q := m 2
def onSidewalk : Q := cm 650

/-- `forbid` (violated): An electric bicycle rider on a roadway shows a lit right turn indicator and gives no arm signal (sig.hand_signal no_signal). -/
def forbidTrace : Trace := riderTrace .electricBicycle onRoad .right .noSignal

/-- `permit` (compliant): A bicycle rider on a roadway gives an arm signal of meaning left, with no indicator lit. -/
def permitTrace : Trace := riderTrace .bicycle onRoad .off .left

/-- `idle` (not_applicable): A bicycle rider on a roadway gives no signal: no indicator lit and no arm signal. -/
def idleTrace : Trace := riderTrace .bicycle onRoad .off .noSignal

/-- `blind` (unknown): As forbid, but the source does not observe arm signals. -/
def blindTrace : Trace := riderTrace .electricBicycle onRoad .right .noSignal

/-- `branch_1` (compliant): An electric bicycle rider on a roadway shows a lit right indicator and extends the right arm horizontally to the right side; the source decodes the arm signal as meaning right. -/
def branch_1Trace : Trace := riderTrace .electricBicycle onRoad .right .right

/-- `branch_2` (violated): An electric bicycle rider on a roadway shows a lit right indicator while giving an arm signal of meaning left. -/
def branch_2Trace : Trace := riderTrace .electricBicycle onRoad .right .left

/-- `branch_3` (not_applicable): An electric bicycle rider on a sidewalk, not on the roadway, shows a lit right indicator with no arm signal. -/
def branch_3Trace : Trace := riderTrace .electricBicycle onSidewalk .right .noSignal

/-- `branch_4` (compliant): A bicycle rider on a roadway shows a lit left indicator and gives the reentering arm signal (left horizontal). -/
def branch_4Trace : Trace := riderTrace .bicycle onRoad .left .reEnter

/-- `branch_5` (violated): A bicycle rider on a roadway shows a lit left indicator while giving the stop-or-slow arm signal. -/
def branch_5Trace : Trace := riderTrace .bicycle onRoad .left .stopOrSlow

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
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_769
