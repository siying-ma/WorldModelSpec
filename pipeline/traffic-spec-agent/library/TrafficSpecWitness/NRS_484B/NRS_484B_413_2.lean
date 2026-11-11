/-
  Witnesses for NRS_484B_413_2.

  The carriageway: three parallel lanes from x = -50 m to x = 300 m, all designated east —
  lane 10 (y 0 … 4 m), lane 11 on its left (y 4 … 8 m), lane 12 on its right (y -4 … 0 m).

  The body: x (track 1, a motor vehicle) drives east along lane 10 at y = 2 m, 10 m/s, one
  observation a second over 16 s (instants k = 0 … 15), so its path length is 10·k m up to the
  departure (1 m more per second of the sideways move after it). At k = 12
  (path 120 m) a departure begins: its velocity turns to (10, ±1.5) m/s (the sine to the lane's
  direction about 0.15) at k = 12 and k = 13 while it is still in lane 10 (y = 2 m, then 3.5 m or
  0.5 m), and at k = 14 it runs east again in lane 11 (y = 5 m) or lane 12 (y = -1 m).

  The windows behind k = 12: 100 ft (30.48 m) reaches back to the observations at k = 9 … 12
  (path 90 … 120 m); 300 ft (91.44 m) to those at k = 3 … 12 (path 30 … 120 m). A signal switched on
  at k = 8 (40 m before the departure) covers the first and not the second; one on from k = 1
  (110 m before) covers both; one on from k = 11 (10 m before) covers neither.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_413_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_413_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def asmDistrict : AsmId := "asm.within_business_or_residence_district"

/-- The three lanes, all designated east. -/
def lanes : List Structure :=
  [ Build.lane 10 [(m (-50), m 0), (m 300, m 0), (m 300, m 4), (m (-50), m 4)] Build.east (some 11) (some 12)
  , Build.lane 11 [(m (-50), m 4), (m 300, m 4), (m 300, m 8), (m (-50), m 8)] Build.east none (some 10)
  , Build.lane 12 [(m (-50), m (-4)), (m 300, m (-4)), (m 300, m 0), (m (-50), m 0)] Build.east (some 10) none ]

/-- The instant at which the departure begins. -/
def onset : Nat := 12

/-- Lateral offset of x: `side` is 1 for a departure to the left, -1 to the right, 0 for none. -/
def yAt (side : Int) (k : Nat) : Q :=
  if k ≤ onset then cm 200
  else if k = onset + 1 then cm (200 + 150 * side)
  else cm (200 + 300 * side)

/-- Velocity of x: east, with a lateral component of 1.5 m/s while it departs. -/
def velAt (side : Int) (k : Nat) : Vec :=
  if k = onset ∨ k = onset + 1 then (m 10, cm (150 * side)) else (m 10, Q.zero)

/-- Path length of x: 10 m a second along the lane, and 1 m more for each of the two seconds of
    the sideways move after the onset (each step then spans about 10.11 m in a straight line). -/
def pathAt (side : Int) (k : Nat) : Q :=
  if side = 0 ∨ k ≤ onset then m (10 * (k : Int))
  else if k = onset + 1 then m (10 * (k : Int) + 1)
  else m (10 * (k : Int) + 2)

/-- x at instant k, with the signals `sig k` sets. -/
def userAt (side : Int) (sig : Nat → Signals → Signals) (k : Nat) : RoadUser :=
  Build.withSignals
    (Build.withKin
      (Build.user 1 [.motorVehicle] (m (10 * (k : Int)), yAt side k) Build.east (m 10) (cm 225, cm 90, cm 75)
        (some (pathAt side k)))
      (fun kn => { kn with velocity := some (velAt side k) }))
    (sig k)

/-- A trace of 16 observations a second apart. -/
def drive (side : Int) (district : Bool) (sig : Nat → Signals → Signals) : Trace :=
  Build.trace 16 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [userAt side sig k] lanes [] (assumptions := [(asmDistrict, district)])

/-- The turn indicator showing `on` from instant `from`, off before; no arm signal. -/
def indicatorFrom (on : TurnIndicatorState) (from_ : Nat) : Nat → Signals → Signals :=
  fun k s => { s with turnIndicator := some (if k ≥ from_ then on else .off), handSignal := some .noSignal }

/-- `forbid` (violated): x (ru.motor_vehicle) on a rural road (asm.within_business_or_residence_district declared false) begins a lane change to the left; its sig.turn_indicator showed left only over a path shorter than the literal of span f6 before the departure began, off before that. -/
def forbidTrace : Trace := drive 1 false (indicatorFrom .left 8)

/-- `permit` (compliant): Same rural lane change; sig.turn_indicator showed left at every observation of a path longer than the literal of span f6 before the departure. -/
def permitTrace : Trace := drive 1 false (indicatorFrom .left 1)

/-- `idle` (not_applicable): x drives along its lane following its designated direction, never departing to either side. -/
def idleTrace : Trace := drive 0 false (indicatorFrom .left 16)

/-- `blind` (unknown): x begins a lane change to the left, but the source observes neither its turn indicator nor any arm signal. -/
def blindTrace : Trace := drive 1 false (fun _ s => s)

/-- `branch_1` (compliant): In a declared business district x begins a departure to the right with sig.turn_indicator right shown over a path longer than the literal of span f1 but shorter than that of span f6. -/
def branch_1Trace : Trace := drive (-1) true (indicatorFrom .right 8)

/-- `branch_2` (violated): x begins a departure to the right with sig.turn_indicator left shown over the whole window: the signal is not of the side of the change. -/
def branch_2Trace : Trace := drive (-1) false (indicatorFrom .left 0)

/-- `branch_3` (violated): in a declared business district x begins a departure to the left with
    the left indicator shown only over the last 10 m, shorter than the literal of span f1. -/
def branch_3Trace : Trace := drive 1 true (indicatorFrom .left 11)

/-- `branch_4` (violated): in a declared business district x begins a departure to the right with
    no signal at all. -/
def branch_4Trace : Trace := drive (-1) true (indicatorFrom .right 16)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_413_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (1000, 15000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator", "sig.hand_signal"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.NRS_484B_413_2
