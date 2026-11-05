/-
  Witnesses for NRS_484B_413_2.

  The geometry. One car (track 1, a motor vehicle, half extents 2 m × 0.9 m × 0.75 m) on a
  two-lane highway, observed 35 times at half-second spacing (t = 0 … 17000 ms). No leaf of the
  rule reads a region or a device, so no structure is built; the stretch's district is what the
  trace declares as the assumption `asm.way_within_business_or_residential_district`.

    k = 0 … 27   the approach, due east at 15 m/s, yaw rate zero: 7.5 m per step, 202.5 m in all,
                 so the car reaches the junction at k = 27 having travelled far more than the 300
                 feet (91.44 m) the longer bound asks for.
    k = 28 … 30  the quarter turn, at 5 m/s and 60 deg/s to the hand of the turn (positive left,
                 negative right): the heading change over the 10 s window behind is 30° at k = 28,
                 60° at k = 29 and 90° at k = 30. The course-change concept therefore rises at
                 k = 29 (60° is clear of the 45° smallest course change read as a turn and of the
                 135° largest), and at no other observation: k = 29 is the one judged observation.
    k = 31 … 34  the exit on the new heading at 10 m/s.

  Every witness names the instants it speaks about (`window` = 10000 … 17000 ms, k = 20 … 34):
  the rule looks back through a 10 s manoeuvre window and through the path the signal was given
  over, and before k = 20 the manoeuvre window is truncated at the start of the recording.

  The travelled path at the judged observation k = 29 is 207.5 m. The signal runs are set so that
  each bound is broken or kept by a clear margin:
    indicator from k = 12 (path 90 m)    → a run of 117.5 m at k = 29: past 300 ft by 26 m;
    indicator from k = 20 (path 150 m)   → a run of  57.5 m: past 100 ft by 27 m, short of 300 ft
                                           by 34 m — the witness that tells the two bounds apart;
    indicator from k = 26 (path 195 m)   → a run of  12.5 m: short of 100 ft by 18 m;
    no signal at all                     → a run of zero.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_413_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_413_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

/-- Half extents of a passenger car. -/
def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- The spacing of the observations. -/
def dtStep : Q := Units.milliseconds 500
/-- The number of observations: k = 0 … 34. -/
def obsN : Nat := 35
/-- An observation index no trace reaches: "this signal is never given". -/
def never : Nat := obsN

/-- Distance travelled since the first observation: 7.5 m per step on the approach (k ≤ 27),
    2.5 m per step through the turn (k = 28 … 30), 5 m per step after it. -/
def pathAt (k : Nat) : Q :=
  let i : Int := k
  if k ≤ 27 then Q.mk' (15 * i) 2
  else if k ≤ 30 then Q.mk' (405 + 5 * (i - 27)) 2
  else Q.mk' (420 + 10 * (i - 30)) 2

/-- 15 m/s on the approach, 5 m/s through the turn, 10 m/s on the exit. -/
def speedAt (k : Nat) : Q :=
  if k ≤ 27 then mps 15 else if k ≤ 30 then mps 5 else mps 10

/-- The yaw rate: zero but for the three observations of the quarter turn, where it is 60 deg/s to
    the hand of the turn (`sgn` is 1 for left, -1 for right). -/
def yawAt (sgn : Int) (k : Nat) : Q :=
  if k ≤ 27 then Q.zero
  else if k ≤ 30 then Units.degrees (sgn * 60)
  else Q.zero

/-- The heading: east on the approach, 30° and 60° off east through the turn, the new course after
    it (north for a left turn, south for a right one). -/
def hdgAt (sgn : Int) (k : Nat) : Vec :=
  let side (q : Q) : Q := Q.mul (Q.ofInt sgn) q
  if k ≤ 27 then (Q.ofInt 1, Q.zero)
  else if k = 28 then (Q.mk' 866 1000, side (Q.mk' 500 1000))
  else if k = 29 then (Q.mk' 500 1000, side (Q.mk' 866 1000))
  else (Q.zero, side (Q.ofInt 1))

/-- The position: the approach runs along y = 0 to the junction at the origin, the turn follows a
    quarter arc of about 5 m radius, the exit runs along the new course. -/
def posAt (sgn : Int) (k : Nat) : Vec :=
  let side (q : Q) : Q := Q.mul (Q.ofInt sgn) q
  let i : Int := k
  if k ≤ 27 then (Q.sub (pathAt k) (Q.mk' 405 2), Q.zero)
  else if k = 28 then (Q.mk' 12 10, side (Q.mk' 6 10))
  else if k = 29 then (Q.mk' 22 10, side (Q.mk' 17 10))
  else if k = 30 then (Q.mk' 27 10, side (Q.mk' 31 10))
  else (Q.mk' 27 10, side (Q.add (Q.mk' 31 10) (m (5 * (i - 30)))))

/-- The car at observation `k`, with the indicator state and arm-signal meaning the source
    observes there. -/
def car (sgn : Int) (ind : TurnIndicatorState) (hand : HandSignal) (k : Nat) : RoadUser :=
  let u := Build.user 1 [.motorVehicle] (posAt sgn k) (hdgAt sgn k) (speedAt k) carExtent
             (some (pathAt k))
  let u := Build.withKin u fun kin => { kin with yawRate := some (yawAt sgn k) }
  Build.withSignals u fun s => { s with turnIndicator := some ind, handSignal := some hand }

/-- The quarter-turn trace: `sgn` the hand of the turn (1 left, -1 right), `district` what the
    trace declares about the stretch, `indFrom` the first observation at which the indicator shows
    `indState` (`never` for an indicator off throughout), `handFrom` the first at which the arm
    signal has `handMeaning`. The car is on a straight alignment until k = 28. -/
def turnTrace (sgn : Int) (district : Bool)
    (indFrom : Nat) (indState : TurnIndicatorState)
    (handFrom : Nat) (handMeaning : HandSignal) : Trace :=
  Build.trace obsN 0 dtStep fun k t =>
    Build.scene t (some 1)
      [ car sgn (if k ≥ indFrom then indState else .off)
                (if k ≥ handFrom then handMeaning else .noSignal) k ]
      [ ]  -- no structure: no leaf of the rule reads a region
      [ ]  -- devices
      (assumptions := [("asm.way_within_business_or_residential_district", district)])

/-- `forbid` (violated): A car travels a rural two-lane highway at 15 m/s, the trace declaring that the stretch is not within a business or residential district. Over the last 300 feet it has travelled its turn indicator is off and no arm signal is given; it then swings through a quarter turn to the left into a side road, the signed heading change over the turn window rising past the smallest course change read as a turn. -/
def forbidTrace : Trace := turnTrace 1 false never .off never .noSignal

/-- `permit` (compliant): The same highway, the same declaration and the same left turn, but the car's left turn indicator has been lit at every observation of the last 300 feet it travelled before the turn is recognized. -/
def permitTrace : Trace := turnTrace 1 false 12 .left never .noSignal

/-- The car on a straight alignment for the whole trace: due east at 15 m/s, 7.5 m per step, yaw
    rate zero, neither indicator lit and no arm signal given. -/
def straightCar (k : Nat) : RoadUser :=
  let p : Q := Q.mk' (15 * (k : Int)) 2
  let u := Build.user 1 [.motorVehicle] (Q.sub p (Q.mk' 405 2), Q.zero) Build.east (mps 15)
             carExtent (some p)
  let u := Build.withKin u fun kin => { kin with yawRate := some Q.zero }
  Build.withSignals u fun s => { s with turnIndicator := some .off, handSignal := some .noSignal }

/-- `idle` (not_applicable): The car travels the same highway at 15 m/s on a straight alignment for the whole trace, its signed heading change over every turn window staying under a degree, so no change of course is recognized and the duty does not arise; no other road user is in the scene. -/
def idleTrace : Trace :=
  Build.trace obsN 0 dtStep fun k t =>
    Build.scene t (some 1)
      [ straightCar k ]
      [ ]
      [ ]
      (assumptions := [("asm.way_within_business_or_residential_district", false)])

/-- `blind` (unknown): The same highway, declaration and left turn, but the source declares no turn indicator state (the manifest masks `sig.turn_indicator`) and no arm signal is given, so whether a signal was given over the window behind cannot be decided and the rule reports unknown. -/
def blindTrace : Trace := turnTrace 1 false never .off never .noSignal

/-- `branch_1` (compliant): A city street whose stretch the trace declares to be within a business district: the car's left indicator comes on well before it begins a quarter turn to the left and stays lit until the turn is recognized, over a run of 57.5 m — past the 100 feet the shorter window asks for and short of the 300 feet the longer one would, nothing being signalled before that. -/
def branch_1Trace : Trace := turnTrace 1 true 20 .left never .noSignal

/-- `branch_2` (violated): The same rural highway, the declaration that the stretch is not within a business or residential district, and a quarter turn to the right into a driveway; the car's left indicator has been lit continuously over the last 300 feet travelled and no right signal is given, so the signal is not of the hand of the course change. -/
def branch_2Trace : Trace := turnTrace (-1) false 12 .left never .noSignal

/-- `branch_3` (compliant): The city street again, the business-district declaration and the same left turn, but the signal is the driver's arm: the left arm signal is given over a run of 57.5 m up to the turn and the indicator is off throughout, which satisfies the duty as the lamp would. -/
def branch_3Trace : Trace := turnTrace 1 true never .off 20 .left

/-- `branch_4` (compliant): The rural highway, the declaration that the stretch is not within a business or residential district, and a quarter turn to the right, with the right indicator lit continuously over the last 117.5 m travelled — past the 300 feet the longer window asks for. -/
def branch_4Trace : Trace := turnTrace (-1) false 12 .right never .noSignal

/-- `branch_5` (violated): The city street, the business-district declaration and a quarter turn to the left, but the left indicator comes on only 12.5 m before the turn is recognized, short of the 100 feet the shorter window asks for. -/
def branch_5Trace : Trace := turnTrace 1 true 26 .left never .noSignal

/-- The instants every witness speaks about: k = 20 … 34. Before k = 20 the manoeuvre window of
    the course-change concepts is truncated at the start of the recording. -/
def judged : Option (Timestamp × Timestamp) := some (10000, 17000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_413_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_413_2
