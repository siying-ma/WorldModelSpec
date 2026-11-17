/-
  Witnesses for NRS_484B_253_o2.

  The map (static, every scene): intersection X = [-10, 10] × [-10, 10]; lane c1 (x 0..4,
  y -40..-10), direction north, entering X; lane c2 (x -4..0, y 10..120), direction south,
  entering X. c1 and c2 are opposed (dot product -1).

  Bodies: half-length 2.5 m, half-width 1 m, motor vehicles. Track 1 is the subject, southbound
  on c2 at x = -2; track 2 is t, northbound from below c1 (off every region at k0), on c1 at
  k1, k2, entering X at k3 (the onset of its movement in X), then turning left (diagonal heading at
  k4, westbound from k5) and creeping through the subject's path at 1 m/s. Instants are 1 s apart
  from t = 10 s; each trace is padded by 3 s of its first and last scene, and `window` names the
  unpadded instants.

  forbid: the subject keeps 12 m/s; at the onset (k3) it is 61 m off (closest approach 4.2 s
  ahead, outside the 3 s horizon); at k5..k7 its closest approach to t is about 2 s ahead at a
  centre distance of about 2 m (below 3 m) while it is still on c2 short of X.
  permit: the subject slows from 12 m/s and is at rest on c2 at y = 55 from k6 until t has left X.
  branch_1: the subject is 20 m off at t's onset (closest approach 1.6 s ahead at 2 m): t did not
  yield under NRS_484B_253_o1 at its onset, so it had not 'so yielded'.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1; the turning vehicle t is track 2

def X : RegionId := 100
def c1 : RegionId := 101
def c2 : RegionId := 102

def mapStructures : List Structure :=
  [ Build.rect X .intersection (m (-10)) (m (-10)) (m 10) (m 10)
  , Build.lane c1 [(m 0, m (-40)), (m 4, m (-40)), (m 4, m (-10)), (m 0, m (-10))] Build.north
      (enters := some X)
  , Build.lane c2 [(m (-4), m 10), (m 0, m 10), (m 0, m 120), (m (-4), m 120)] Build.south
      (enters := some X) ]

def body : Q × Q × Q := (cm 250, m 1, cm 75)

/-- A unit heading between north and west (-0.6, 0.8). -/
def northWest : Vec := (Units.ratio (-3) 5, Units.ratio 4 5)

abbrev Pose := Vec × Vec × Q

/-- t: onto c1, into X at k3, turning left and creeping west through the subject's path. -/
def turnLeft : Nat → Pose
  | 0 => ((m 2, m (-44)), Build.north, mps 8)
  | 1 => ((m 2, m (-30)), Build.north, mps 8)
  | 2 => ((m 2, m (-18)), Build.north, mps 7)
  | 3 => ((m 1, m (-6)), Build.north, mps 4)
  | 4 => ((m 0, m (-2)), northWest, mps 2)
  | 5 => ((m (-1), m 1), Build.west, mps 1)
  | 6 => ((m (-2), m 1), Build.west, mps 1)
  | 7 => ((m (-3), m 1), Build.west, mps 1)
  | 8 => ((m (-8), m 1), Build.west, mps 5)
  | _ => ((m (-15), m 1), Build.west, mps 5)

/-- t in branch_1: enters X at k3 close in front of the approaching subject. -/
def turnLeftLate : Nat → Pose
  | 3 => ((m 0, m (-6)), Build.north, mps 4)
  | 4 => ((m (-1), m (-2)), northWest, mps 2)
  | 5 => ((m (-2), m 0), Build.west, mps 1)
  | k => turnLeft k

/-- t in branch_2: straight on through X. -/
def straightOn : Nat → Pose
  | 3 => ((m 2, m (-6)), Build.north, mps 5)
  | 4 => ((m 2, m 0), Build.north, mps 6)
  | 5 => ((m 2, m 6), Build.north, mps 6)
  | 6 => ((m 2, m 14), Build.north, mps 6)
  | 7 => ((m 2, m 22), Build.north, mps 6)
  | k => turnLeft k

/-- The subject keeps 12 m/s southbound on c2. -/
def subjProceeds (y0 : Int) (k : Nat) : Pose :=
  ((m (-2), m (y0 - 12 * (k : Int))), Build.south, mps 12)

/-- The subject slows and rests on c2 at y = 55, short of X. -/
def subjStops : Nat → Pose
  | 0 => ((m (-2), m 97), Build.south, mps 12)
  | 1 => ((m (-2), m 85), Build.south, mps 10)
  | 2 => ((m (-2), m 75), Build.south, mps 8)
  | 3 => ((m (-2), m 67), Build.south, mps 6)
  | 4 => ((m (-2), m 61), Build.south, mps 4)
  | 5 => ((m (-2), m 57), Build.south, mps 2)
  | _ => ((m (-2), m 55), Build.south, mps 0)

def indicatorLeft : Signals := { turnIndicator := some .left, handSignal := some .noSignal }
def handLeft : Signals := { turnIndicator := some .off, handSignal := some .left }
def noSignal : Signals := { turnIndicator := some .off, handSignal := some .noSignal }
def signalUnobserved : Signals := {}

def mkScene (t : Timestamp) (subj tp : Pose) (sig : Signals) (leftTurn : Bool) : Scene :=
  let (sp, sh, sv) := subj
  let (tpos, th, tv) := tp
  Build.scene t (some 1)
    [ Build.user 1 [.motorVehicle] sp sh sv body
    , Build.withSignals (Build.user 2 [.motorVehicle] tpos th tv body) (fun _ => sig) ]
    mapStructures []
    (intents := [{ vehicle := 2, target := X, values := [("int.left_turn", leftTurn)] }])

def t0 : Timestamp := 10000

def episode (n : Nat) (subj : Nat → Pose) (tp : Nat → Pose) (sig : Signals)
    (leftTurn : Bool := true) : Trace :=
  Build.pad (Build.trace n t0 (Units.seconds 1) fun k t => mkScene t (subj k) (tp k) sig leftTurn)
    (Units.seconds 3) (Units.seconds 3) (Units.seconds 1)

/-- `forbid` (violated): t entered X from c1 showing sig.turn_indicator left, declares int.left_turn at X, and began moving into its turn when the subject, approaching on c2 (direction opposed to c1's), was far and not in conflict; t keeps moving; the subject keeps kin.speed above p.halt_speed_tolerance and its closest approach to t lies within p.conflict_horizon at a centre distance below p.conflict_centre_clearance. -/
def forbidTrace : Trace := episode 8 (subjProceeds 97) turnLeft indicatorLeft

/-- `permit` (compliant): Same scene; the subject slows and comes to rest on c2 short of X until t has completed its turn. -/
def permitTrace : Trace := episode 10 subjStops turnLeft indicatorLeft

/-- `idle` (not_applicable): t turns left in X but showed no left signal (sig.turn_indicator off, sig.hand_signal no_signal) since it came onto c1. -/
def idleTrace : Trace := episode 8 (subjProceeds 97) turnLeft noSignal

/-- `blind` (unknown): t turning left in X, the subject approaching opposite in conflict; sig.turn_indicator and sig.hand_signal are absent, so whether t gave a signal is unknown. -/
def blindTrace : Trace := episode 8 (subjProceeds 97) turnLeft signalUnobserved

/-- `branch_1` (not_applicable): t, signalled, began its turn while the subject was already within the hazard bound of t (t did not comply with NRS_484B_253_o1 at its onset); the subject proceeds in conflict: t had not so yielded. -/
def branch_1Trace : Trace := episode 6 (subjProceeds 56) turnLeftLate indicatorLeft

/-- `branch_2` (not_applicable): The subject approaches X with no vehicle turning left in X. -/
def branch_2Trace : Trace := episode 8 (subjProceeds 97) straightOn indicatorLeft (leftTurn := false)

/-- `branch_3` (violated): as forbid, but t signals by arm (sig.hand_signal left, indicator off). -/
def branch_3Trace : Trace := episode 8 (subjProceeds 97) turnLeft handLeft

def witness (name : String) (τ : Trace) (n : Nat) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (t0, t0 + 1000 * (n - 1))
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace 8 .violated
  , witness "permit" permitTrace 10 .compliant
  , witness "idle" idleTrace 8 .notApplicable
  , witness "blind" blindTrace 8 (.unknown []) ["sig.turn_indicator", "sig.hand_signal"]
  , witness "branch_1" branch_1Trace 6 .notApplicable
  , witness "branch_2" branch_2Trace 8 .notApplicable
  , witness "branch_3" branch_3Trace 8 .violated ]

end TrafficSpecWitness.NRS_484B_253_o2
