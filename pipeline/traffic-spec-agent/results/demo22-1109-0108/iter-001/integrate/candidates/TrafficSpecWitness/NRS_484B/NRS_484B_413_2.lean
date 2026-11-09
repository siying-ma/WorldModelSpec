/-
  Witnesses for NRS_484B_413_2.

  The geometry, once, for every scenario below (every figure here is the witness's own and appears
  nowhere in the rule):

  - One straight lane, 4 m wide, running east from x = -20 m to x = 200 m, centred on y = 0.
  - One road user, track 1, a motor vehicle (half extents 2 m x 1 m x 1 m), the subject of every
    scene and the track the binder `v` is grounded to. No other road user is ever present.
  - 26 observations, 0.5 s apart (t = 0 ... 12 500 ms). The subject runs at 10 m/s, so each
    observation is 5 m of travelled path further on: at observation k < 25 it is at (5 k, 0),
    heading due east, with a zero yaw rate, and `kin.path_length` is 5 k metres.
  - The course change is one observation long and it is carried by the atom the duty and the
    concept read, `kin.yaw_rate`: at observation 25 the rate is +-32.52 deg/s (positive to the
    left), so over the half second behind it the heading turns by 16.26 deg. The scene states that
    turn: the heading at observation 25 is the unit vector (24/25, +- 7/25), east rotated by that
    much, and the position is the previous one advanced exactly 5 m along it, (124.8, +- 1.4), with
    `kin.path_length` 125 m.
  - Integrated over the recognition window behind an observation (the reading's 3 s), the heading
    change is 0 deg at observation 24 and 16.26 deg at observation 25 -- well below and well above
    the reading's 5 deg noise floor -- so `drv.motion.turning` rises at observation 25
    (t = 12 500 ms) and nowhere else: observation 25 is the judged one.
  - The windows of travelled path behind observation 25 are therefore: 100 ft = 30.48 m reaching
    back to observation 19 (125 m - 95 m = 30 m), and 300 ft = 91.44 m reaching back to
    observation 7 (125 m - 35 m = 90 m). Both are covered by observed instants and sampled 5 m
    apart, a sixth of the shorter window.
  - Each scenario declares `asm.in_business_or_residential_district` true or false in every scene,
    and every scenario names the instants it speaks about (`window` = 10 000 ... 12 500 ms, i.e.
    observations 20 ... 25), because the recognition window and the windows of travelled path are
    truncated at the start of any finite trace.

  The signal is stated by `sig.turn_indicator` and `sig.hand_signal` on the subject at every
  observation; the scenarios differ only in the district declaration, the hand of the bend and
  those two signals.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_413_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_413_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- Observations 0.5 s apart; twenty-six of them. -/
def dtS : Q := Units.milliseconds 500
def nScenes : Nat := 26
/-- The one observation at which the heading turns, and at which the turn is recognized. -/
def bend : Nat := 25
/-- 10 m/s, so 5 m of travelled path per observation. -/
def speedV : Q := Units.metresPerSecond 10
def stepM : Q := m 5
def halfExtent : Q × Q × Q := (m 2, m 1, m 1)
/-- A bend to the left and a bend to the right, in degrees per second (left positive): over the
    half second behind the bend observation, 16.26 degrees either way. -/
def yawLeft : Q := Units.millidegrees 32520
def yawRight : Q := Units.millidegrees (-32520)

/-- East rotated by that much: the exact unit vector (24/25, 7/25), whose angle is 16.2602 deg. -/
def cosTurn : Q := Units.ratio 24 25
def sinTurn : Q := Units.ratio 7 25
def headingLeft : Vec := (cosTurn, sinTurn)
def headingRight : Vec := (cosTurn, Units.ratio (-7) 25)
/-- The previous position (120, 0) advanced exactly 5 m along that heading. -/
def bendPosLeft : Vec := (Units.centimetres 12480, Units.centimetres 140)
def bendPosRight : Vec := (Units.centimetres 12480, Units.centimetres (-140))

/-- The lane the subject runs along. -/
def laneRegion : Structure :=
  Build.lane 10 [(m (-20), m (-2)), (m 200, m (-2)), (m 200, m 2), (m (-20), m 2)] Build.east

/-- The subject at observation `k`: 5 m of path further on, with the yaw rate and the two signals
    given. Where the yaw rate is zero it runs due east along the centre of the lane; where it is
    not, the heading and the position are the turn that rate carries over the half second behind. -/
def subjectAt (k : Nat) (yaw : Q) (ind : TurnIndicatorState) (hand : HandSignal) : RoadUser :=
  let along := Q.mul (Q.ofInt (Int.ofNat k)) stepM
  let left := Q.lt Q.zero yaw
  let pos : Vec := if Q.isZero yaw then (along, Q.zero) else if left then bendPosLeft else bendPosRight
  let head : Vec := if Q.isZero yaw then Build.east else if left then headingLeft else headingRight
  Build.withKin
    (Build.withSignals
      (Build.user 1 [.motorVehicle] pos head speedV halfExtent (some along))
      (fun s => { s with turnIndicator := some ind, handSignal := some hand }))
    (fun kin => { kin with yawRate := some yaw })

def sceneAt (k : Nat) (t : Timestamp) (district : Bool) (yaw : Q)
    (ind : TurnIndicatorState) (hand : HandSignal) : Scene :=
  Build.scene t (some 1) [subjectAt k yaw ind hand] [laneRegion] []
    (assumptions := [("asm.in_business_or_residential_district", district)])

/-- A whole recording: the district declaration, the hand of the bend at observation `bend`, and
    the indicator state and the arm signal per observation. -/
def runTrace (district : Bool) (yawAtBend : Q)
    (indAt : Nat → TurnIndicatorState) (handAt : Nat → HandSignal) : Trace :=
  Build.trace nScenes 0 dtS fun k t =>
    sceneAt k t district (if k < bend then Q.zero else yawAtBend) (indAt k) (handAt k)

def noIndicator (_ : Nat) : TurnIndicatorState := .off
def indicatorAlways (s : TurnIndicatorState) : Nat → TurnIndicatorState := fun _ => s
/-- The indicator lit from observation `k0` on, and off before it. -/
def indicatorFrom (s : TurnIndicatorState) (k0 : Nat) : Nat → TurnIndicatorState :=
  fun k => if k0 ≤ k then s else .off
def noArm (_ : Nat) : HandSignal := .noSignal
def armAlways (h : HandSignal) : Nat → HandSignal := fun _ => h

/-- `forbid` (violated): The trace declares the stretch the subject occupies to lie in a business district. The subject runs straight, then bends to the right until its heading change over the recognition window reaches the noise floor; over the whole hundred feet of path travelled before that observation its indicator was off and no arm signal was given. -/
def forbidTrace : Trace := runTrace true yawRight noIndicator noArm

/-- `permit` (compliant): The trace declares the stretch to lie in no business or residential district. The subject lights its left indicator early and holds it lit over more than three hundred feet of travelled path before its heading change to the left reaches the noise floor. No other road user is present in the scene. -/
def permitTrace : Trace := runTrace false yawLeft (indicatorAlways .left) noArm

/-- `idle` (not_applicable): The subject runs along its lane for the whole recording, its heading change over the recognition window never reaching the noise floor, so no course change is recognized and no signal is owed. -/
def idleTrace : Trace := runTrace false Q.zero noIndicator noArm

/-- `blind` (unknown): The trace declares a residential district and the subject's course change to the left is recognized well after the start of the recording, but the source observes neither the indicator state nor an arm signal, so whether the signal was given over the window cannot be told. -/
def blindTrace : Trace := runTrace true yawLeft (indicatorAlways .left) (armAlways .left)

/-- `branch_1` (violated): Outside any business or residential district by the trace's declaration, the subject holds its right indicator lit over the whole three hundred feet of travelled path and then bends to the left, its heading change to the left reaching the noise floor: the signal given is of the other hand. -/
def branch_1Trace : Trace := runTrace false yawLeft (indicatorAlways .right) noArm

/-- `branch_2` (compliant): In a declared business district, the subject gives no indicator but the driver holds out an arm whose signal means left at every observation of the hundred feet of travelled path before its heading change to the left is recognized. -/
def branch_2Trace : Trace := runTrace true yawLeft noIndicator (armAlways .left)

/-- `branch_3` (violated): Outside any district by the declaration, the subject bends to the right
    with neither indicator nor arm signal over the three hundred feet behind the recognition. -/
def branch_3Trace : Trace := runTrace false yawRight noIndicator noArm

/-- `branch_4` (violated): In a declared district, the subject bends to the left with neither
    indicator nor arm signal over the hundred feet behind the recognition. -/
def branch_4Trace : Trace := runTrace true yawLeft noIndicator noArm

/-- `branch_5` (compliant): In a declared district, the left indicator is lit only from observation
    15 (75 m of travelled path) on -- the last 50 m, more than the hundred feet owed in a district
    and less than the three hundred feet owed outside one -- before the left bend is recognized. -/
def branch_5Trace : Trace := runTrace true yawLeft (indicatorFrom .left 15) noArm

/-- `branch_6` (violated): the same recording outside any district, where three hundred feet of
    signal are owed and only the last fifty metres of path carried one. -/
def branch_6Trace : Trace := runTrace false yawLeft (indicatorFrom .left 15) noArm

/-- `branch_7` (compliant): Outside any district, the right indicator is lit over the whole
    recording and the subject bends to the right. -/
def branch_7Trace : Trace := runTrace false yawRight (indicatorAlways .right) noArm

/-- `branch_8` (compliant): In a declared district, the driver's arm signal means right at every
    observation of the hundred feet behind a recognized bend to the right. -/
def branch_8Trace : Trace := runTrace true yawRight noIndicator (armAlways .right)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_413_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    -- observations 20 ... 25: the recognition window and the windows of travelled path are
    -- covered there, and the course change is recognized at the last of them
    window := some (10000, 12500)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator", "sig.hand_signal"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant ]

end TrafficSpecWitness.NRS_484B_413_2
