/-
  Witnesses for NRS_484B_413_2.

  Geometry: one lane (region 10), 6 m wide, from x = -20 m to x = 300 m, designated direction east.
  The subject (track 1, a motor vehicle) drives along y = 0 at 10 m/s, observed every second for
  13 instants (k = 0 … 12): at instant k it is at x = 10·k m with path length 10·k m. At k = 12
  (path 120 m) its heading turns off the lane's direction, to (10, 1) for a left departure or
  (10, -1) for a right one: a sine of about 0.0995 against the reading's 0.035. Before that it heads
  east (sine 0). The 300 ft (91.44 m) window behind k = 12 reaches back to path 28.56 m (k = 3 …
  12), the 100 ft (30.48 m) window to path 89.52 m (k = 9 … 12); samples 10 m apart are adequate
  for both, and both are covered (the trace starts at path 0).
  Signals: "on from k = 6" puts the signal on over 60 m before the departure: longer than 100 ft,
  shorter than 300 ft. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_413_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_413_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def asmId : AsmId := "asm.business_or_residence_district"

def laneL : Structure :=
  Build.lane 10 [(m (-20), m (-3)), (m 300, m (-3)), (m 300, m 3), (m (-20), m 3)] Build.east

def headLeft : Vec := (m 10, m 1)
def headRight : Vec := (m 10, m (-1))

/-- The instant of the course change. -/
def departAt : Nat := 12

def subjectAt (k : Nat) (h : Vec) (ti : Option TurnIndicatorState) (hs : Option HandSignal) :
    RoadUser :=
  Build.withSignals
    (Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 0) h (Units.metresPerSecond 10)
      (m 2, m 1, m 1) (some (m (10 * (k : Int)))))
    (fun s => { s with turnIndicator := ti, handSignal := hs })

/-- A run of 13 instants; `dep` the heading from `departAt` on (east before), `sig k` the signals. -/
def run (dep : Vec) (sig : Nat → Option TurnIndicatorState × Option HandSignal)
    (asmv : Bool) : Trace :=
  Build.trace (departAt + 1) 0 (Units.seconds 1) fun k t =>
    let h := if k ≥ departAt then dep else Build.east
    Build.scene t (some 1) [subjectAt k h (sig k).1 (sig k).2] [laneL] []
      (assumptions := [(asmId, asmv)])

def noSignal : Nat → Option TurnIndicatorState × Option HandSignal :=
  fun _ => (some .off, some .noSignal)
def indicatorAlways (side : TurnIndicatorState) : Nat → Option TurnIndicatorState × Option HandSignal :=
  fun _ => (some side, some .noSignal)
def indicatorFrom (n : Nat) (side : TurnIndicatorState) :
    Nat → Option TurnIndicatorState × Option HandSignal :=
  fun k => (some (if k ≥ n then side else .off), some .noSignal)

/-- `forbid` (violated): asm.business_or_residence_district false; the subject moves in its lane with sig.turn_indicator off and sig.hand_signal no_signal, then its heading turns left of the lane's direction beyond p.course_departure_sin_tol (a lane change to the left). -/
def forbidTrace : Trace := run headLeft noSignal false

/-- `permit` (compliant): asm.business_or_residence_district false; the subject shows sig.turn_indicator left at every observation over the last stated 300 feet of its path before its heading departs to the left of its lane. -/
def permitTrace : Trace := run headLeft (indicatorAlways .left) false

/-- `idle` (not_applicable): The subject keeps its heading along its lane's designated direction throughout; no course change begins. -/
def idleTrace : Trace := run Build.east noSignal false

/-- `blind` (unknown): The subject's heading departs to the right of its lane; neither sig.turn_indicator nor sig.hand_signal is observed on the source. -/
def blindTrace : Trace := run headRight (fun _ => (none, none)) false

/-- `branch_1` (compliant): asm.business_or_residence_district true; the subject shows sig.turn_indicator right over a stretch of its path longer than the stated 100 feet but shorter than the stated 300 feet before its heading departs to the right of its lane. -/
def branch_1Trace : Trace := run headRight (indicatorFrom 6 .right) true

/-- `branch_2` (violated): As branch_1 with asm.business_or_residence_district false: the indicator was not shown over the last stated 300 feet. -/
def branch_2Trace : Trace := run headRight (indicatorFrom 6 .right) false

/-- `branch_3` (violated): asm.business_or_residence_district false; the subject shows sig.turn_indicator right over the last stated 300 feet and its heading departs to the left of its lane: the signal shows the wrong side. -/
def branch_3Trace : Trace := run headLeft (indicatorAlways .right) false

/-- `branch_4` (compliant): asm.business_or_residence_district false; the indicator stays off but the
    driver gives the left arm signal over the whole stated 300 feet before departing to the left. -/
def branch_4Trace : Trace := run headLeft (fun _ => (some .off, some .left)) false

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_413_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, 12000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator", "sig.hand_signal"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_484B_413_2
