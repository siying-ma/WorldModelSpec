/-
  Witnesses for NRS_484B_413_2.

  Geometry: one eastbound lane (region 10), x from 0 to 400 m, y from 0 to 4 m, direction east.
  Vehicle 1 (a motor vehicle) drives along y = 2 m at 10 m/s, one observation a second for 16
  observations (t = 0 … 15 s), so its path length is 10·k m at observation k. Up to observation 14
  its heading is east (offset 0); at observation 15 (path 150 m) it points (5, ±1), an offset of
  about ±0.196 against the lane direction, well beyond the tolerance either way: the change of
  course is judged there. 150 m of path lies behind it, more than the 300 ft (91.44 m) window, so
  no window is truncated; `window` excludes the first observation, which has no predecessor.
  Signals per observation k: the "last 10 m" is k ≥ 14 (140 m, 150 m); the "last 50 m" is
  k ≥ 10 (100 m … 150 m), which covers 100 ft (30.48 m) but not 300 ft (91.44 m).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_413_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_413_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def laneE : Structure := Build.lane 10 [(m 0, m 0), (m 400, m 0), (m 400, m 4), (m 0, m 4)] Build.east

def headingLeft : Vec := (m 5, m 1)
def headingRight : Vec := (m 5, m (-1))

/-- The run: 16 observations, the heading departs at observation `change` (none past 15). -/
def run (change : Nat) (heading : Vec) (sigs : Nat → Signals → Signals) (district : Bool) : Trace :=
  Build.trace 16 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withSignals
          (Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 2)
            (if k ≥ change then heading else Build.east) (m 10) (m 2, m 1, m 1)
            (some (m (10 * (k : Int)))))
          (sigs k) ]
      [ laneE ]
      [ ]
      (assumptions := [("asm.business_or_residence_district", district)])

/-- Indicator of `side` from observation `onset` on, off before; no arm signal. -/
def indicator (side : TurnIndicatorState) (onset : Nat) (k : Nat) (s : Signals) : Signals :=
  { s with turnIndicator := some (if k ≥ onset then side else .off), handSignal := some .noSignal }

/-- `forbid` (violated): A vehicle in a lane with a designated direction, asm.business_or_residence_district declared true, lights sig.turn_indicator left only over the last 10 m of path before its heading departs to the left of the lane direction beyond the tolerance; the trace covers more than 100 ft behind the change. -/
def forbidTrace : Trace := run 15 headingLeft (indicator .left 14) true

/-- `permit` (compliant): The same vehicle and district, with sig.turn_indicator left lit at every observation of the last 50 m of path before the heading departs to the left. -/
def permitTrace : Trace := run 15 headingLeft (indicator .left 10) true

/-- `idle` (not_applicable): A vehicle drives along its lane with its heading aligned with the lane direction throughout; no change of course occurs. -/
def idleTrace : Trace := run 99 headingLeft (indicator .left 99) true

/-- `blind` (unknown): A vehicle changes course to the left in its lane in a district; the source observes neither turn indicators nor arm signals. -/
def blindTrace : Trace := run 15 headingLeft (indicator .left 10) true

/-- `branch_1` (violated): asm.business_or_residence_district declared false; the vehicle signals right over the last 50 m of path (above 100 ft but below 300 ft) before its heading departs to the right of the lane direction. -/
def branch_1Trace : Trace := run 15 headingRight (indicator .right 10) false

/-- `branch_2` (compliant): in a district, the driver gives the left arm signal over the last 50 m
    of path, the indicator off, before the heading departs to the left. -/
def branch_2Trace : Trace :=
  run 15 headingLeft
    (fun k s => { s with turnIndicator := some .off,
                         handSignal := some (if k ≥ 10 then .left else .noSignal) }) true

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
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_413_2
