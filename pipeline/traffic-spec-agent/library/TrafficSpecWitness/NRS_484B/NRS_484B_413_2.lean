/-
  Witnesses for NRS_484B_413_2.

  One roadway (region 10, x from -10 m to 400 m, y from -60 m to 60 m). Ego (track 1, a motor
  vehicle, 2.3 m × 0.9 m half-extent) runs at 10 m/s, observed every 50 ms (instant k at 50·k ms),
  so its path length at instant k is 0.5·k m. Ego drives east (yaw rate 0) until instant 240 (12 s,
  120 m of path); from instant 240 to instant 299 its heading turns by the exact rational rotation
  (1624/1625, ±57/1625), 2.010° per instant, with the yaw rate ±40.203 deg/s, a 60 deg turn being
  reached about 1.5 s after the onset; from instant 300 it drives straight again. Each position is
  the previous one advanced 0.5 m along the instant's heading. The trace has 320 instants. The onset is instant 240: the
  last 100 ft (30.48 m) behind it are instants 180 … 240 (path 90 m … 120 m), the last 300 ft
  (91.44 m) instants 58 … 240 (path 29 m … 120 m); both windows are covered and sampled every
  0.5 m of path. Position and heading stay on the roadway's axis; the rule reads neither.

  Signals, by the first instant from which the signal on the turn's side is shown (off before):
    forbid    left indicator from instant 230 (the last 5 m), no arm signal; district declared.
    permit    left indicator from instant 100 (70 m before the onset); district declared.
    idle      no yaw at all, indicator off.
    blind     as forbid, the turn indicator unobserved; no arm signal.
    branch_1  right turn, right indicator from instant 140 (50 m before the onset); the
              district declared false, so the 300 ft window (back to 29 m) holds unlit instants.
    branch_2  left turn, indicator off, arm signal meaning left from instant 100; district declared.
    branch_3  right turn, indicator off, arm signal meaning right from instant 100; district declared.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_413_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_413_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: ego ↦ 1

def asmDistrict : AsmId := "asm.business_or_residence_district"

def roadway : Structure := Build.rect 10 .roadway (m (-10)) (m (-60)) (m 400) (m 60)

/-- Instants 240 … 299 are the turn. -/
def turning (k : Nat) : Bool := 240 ≤ k && k < 300

/-- The turn's heading step per instant: the exact rational rotation (cos, sin) = (1624/1625, 57/1625),
    2.01017° per 50 ms, i.e. a yaw rate of 40.203 deg/s. `dir` is 1 for left, -1 for right. -/
def rotate (dir : Int) (h : Vec) : Vec :=
  let c := Units.ratio 1624 1625
  let s := Units.ratio (57 * dir) 1625
  (Q.sub (Q.mul h.1 c) (Q.mul h.2 s), Q.add (Q.mul h.1 s) (Q.mul h.2 c))

/-- Yaw rate (deg/s) at instant k: the rate at a scene is held over the interval before it. -/
def yawAt (dir : Int) (k : Nat) : Q :=
  if turning k then Units.millidegrees (40203 * dir) else Q.zero

/-- Position and heading at every instant: heading turned by the step at each turning instant,
    position advanced 0.5 m along the instant's heading. -/
def poses (dir : Int) : Array (Vec × Vec) :=
  (List.range 319).foldl (fun (acc : Array (Vec × Vec)) i =>
    let (p, h) := acc[i]!
    let k := i + 1
    let h' := if turning k && dir != 0 then rotate dir h else h
    acc.push ((Q.add p.1 (Q.mul h'.1 (cm 50)), Q.add p.2 (Q.mul h'.2 (cm 50))), h'))
    #[((m 0, m 0), Build.east)]

def posesLeft : Array (Vec × Vec) := poses 1
def posesRight : Array (Vec × Vec) := poses (-1)
def posesStraight : Array (Vec × Vec) := poses 0

def posesOf (dir : Int) : Array (Vec × Vec) :=
  if dir > 0 then posesLeft else if dir < 0 then posesRight else posesStraight

/-- Ego at instant k: 10 m/s, 0.5 m of path per instant; `dir` the turn's side (0: no turn). -/
def ego (k : Nat) (dir : Int) (ind : Option TurnIndicatorState) (hand : HandSignal) : RoadUser :=
  let (p, h) := (posesOf dir)[k]!
  let u := Build.user 1 [.motorVehicle] p h (Units.metresPerSecond 10)
    (cm 230, cm 90, cm 75) (some (cm (50 * k)))
  Build.withSignals (Build.withKin u fun kn => { kn with yawRate := some (if dir = 0 then Q.zero else yawAt dir k) })
    fun s => { s with turnIndicator := ind, handSignal := some hand }

/-- The trace: 320 instants 50 ms apart; `f k` gives ego at instant k. -/
def drive (district : Bool) (f : Nat → RoadUser) : Trace :=
  Build.trace 320 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1) [f k] [roadway] [] (assumptions := [(asmDistrict, district)])

/-- The indicator on `side` from instant `from`, off before. -/
def lit (side : TurnIndicatorState) (from_ : Nat) (k : Nat) : Option TurnIndicatorState :=
  if from_ ≤ k then some side else some .off

/-- The arm signal `meaning` from instant `from`, none before. -/
def arm (meaning : HandSignal) (from_ : Nat) (k : Nat) : HandSignal :=
  if from_ ≤ k then meaning else .noSignal

/-- `forbid` (violated): ego, a passenger car, with the business-or-residence-district assumption declared, drives along a straight roadway and turns left at an intersection; its left indicator lights only over the final few metres before the turn begins, so at the onset the window of the last 100 ft holds observations with the indicator off and no arm signal. -/
def forbidTrace : Trace :=
  drive true fun k => ego k 1 (lit .left 230 k) .noSignal

/-- `permit` (compliant): as in forbid, but the left indicator is lit at every observation over well more than the last 100 ft travelled before the turn's onset. -/
def permitTrace : Trace :=
  drive true fun k => ego k 1 (lit .left 100 k) .noSignal

/-- `idle` (not_applicable): ego drives straight along a straight roadway and makes no turn. -/
def idleTrace : Trace :=
  drive true fun k => ego k 0 (some .off) .noSignal

/-- `blind` (unknown): as in forbid, but the source does not observe turn indicators and observes no arm signal, so whether a signal was given is unknown. -/
def blindTrace : Trace :=
  drive true fun k => ego k 1 none .noSignal

/-- `branch_1` (violated): ego turns right with the assumption declared false (any other area); its right indicator is lit over the last 100 ft before the onset but not over the last 300 ft. -/
def branch_1Trace : Trace :=
  drive false fun k => ego k (-1) (lit .right 140 k) .noSignal

/-- `branch_2` (compliant): ego, the assumption declared, turns left with its indicator off but its arm signal meaning left at every observation over the last 100 ft before the onset. -/
def branch_2Trace : Trace :=
  drive true fun k => ego k 1 (some .off) (arm .left 100 k)

/-- `branch_3` (compliant): ego, the assumption declared, turns right with its indicator off but its arm signal meaning right at every observation over the last 100 ft before the onset. -/
def branch_3Trace : Trace :=
  drive true fun k => ego k (-1) (some .off) (arm .right 100 k)

/-- The instants the witnesses speak about: from 1 s to the end of the trace. -/
def judged : Option (Timestamp × Timestamp) := some (1000, 15950)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_413_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.NRS_484B_413_2
