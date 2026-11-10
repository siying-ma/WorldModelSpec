/-
  Witnesses for NRS_484B_307_9b_o3.

  The junction: intersection 10, the square from (-10, -10) to (10, 10) m. Approach lane 1 runs
  north from y = -60 to the junction's south edge (x in [0, 5]) and enters intersection 10. Exit
  lanes: 2 eastbound (x in [10, 60], y in [-5, 0]), 3 northbound (x in [0, 5], y in [10, 60]),
  4 westbound (x in [-60, -10], y in [0, 5]).

  The rider (track 1, half-extents 1 m × 0.4 m × 0.7 m) is sampled every 50 ms, 45 scenes
  (0 … 2200 ms). Scenes 0–4: on lane 1 at x = 2.5 m, heading north. Scene 5 (250 ms): the entry,
  the body across lane 1 and the intersection (occupancy stated). Scenes 6–35: the yaw rate is
  -60 deg/s for a right turn, +60 deg/s for a left turn, 0 for a straight crossing, each rate held
  over the 50 ms before its scene, so the heading turns 3° a step: 30 steps, a heading change of
  -90, +90 or 0 degrees since the entry, against the reading's 60-degree turn minima and 150-degree
  reversal bound. Elsewhere the yaw rate is 0. Positions advance along the heading at the speed of
  the move. Scenes 36–37: the body across the intersection and the exit lane. Scene 38 (1900 ms):
  the exit, on the exit lane only.

  Devices: signal 20 (circular_red with green_arrow(left) unless stated) governing lane 1, or the
  intersection; regulatory sign 30 of a turn code governing lane 1 or the intersection, its legend
  read with no restriction unless stated.

  Every witness speaks about 50 … 2000 ms: at the first scene the entry and the exit look back
  past the trace start.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def approachLane : RegionId := 1
def junction : RegionId := 10

inductive Move
  | right
  | left
  | straight

/-- Scene 5: the entry. Scenes 6–35: the yaw rate turns the heading 3° per step. Scenes 36–37:
    the body straddles the intersection and the exit lane. Scene 38: the exit. -/
def kEntry : Nat := 5
def kTurnEnd : Nat := 35
def kExit : Nat := 38
def nScenes : Nat := 45

def exitLane : Move → RegionId
  | .right => 2
  | .left => 4
  | .straight => 3

/-- Yaw rate during the turn, deg/s. -/
def yawDuring : Move → Int
  | .right => -60
  | .left => 60
  | .straight => 0

/-- Speed, chosen so the body clears the intersection between scenes 37 and 38: 8 m/s on a
    7.6 m right-turn radius, 12.5 m/s on an 11.9 m left-turn radius, 13.2 m/s straight. -/
def speedOf : Move → Q
  | .right => Units.metresPerSecond 8
  | .left => Units.centimetres 1250
  | .straight => Units.centimetres 1320

/-- Sine and cosine of `j` × 3° in fixed point (scale 10¹²), by their Taylor series. -/
def fixScale : Nat := 1000000000000
def fixScaleI : Int := 1000000000000
def angleFix (j : Nat) : Int := Int.ofNat j * 3141592653590 / 60
def sinFix (a : Int) : Int :=
  ((List.range 9).foldl (fun (acc : Int × Int) (n : Nat) =>
    let i : Int := Int.ofNat n
    let k : Int := (2 * (i + 1)) * (2 * (i + 1) + 1)
    let t : Int := -(acc.1 * a / fixScaleI * a / fixScaleI) / k
    (t, acc.2 + t)) (a, a)).2
def cosFix (a : Int) : Int :=
  ((List.range 9).foldl (fun (acc : Int × Int) (n : Nat) =>
    let i : Int := Int.ofNat n
    let k : Int := (2 * i + 1) * (2 * i + 2)
    let t : Int := -(acc.1 * a / fixScaleI * a / fixScaleI) / k
    (t, acc.2 + t)) (fixScaleI, fixScaleI)).2

/-- Steps of 3° turned by scene k. -/
def stepsTurned (k : Nat) : Nat := min (k - kEntry) (kTurnEnd - kEntry)

/-- North rotated by the turn so far: right (clockwise), left (counter-clockwise). -/
def headingAt (mv : Move) (k : Nat) : Vec :=
  let a := angleFix (stepsTurned k)
  let s := Q.mk' (sinFix a) fixScale
  let c := Q.mk' (cosFix a) fixScale
  match mv with
  | .right => (s, c)
  | .left => (Q.neg s, c)
  | .straight => Build.north

/-- Distance covered per 50 ms step. -/
def stepLength (mv : Move) : Q := Q.mul (speedOf mv) (Units.milliseconds 50)

/-- Position: on lane 1 at x = 2.5 m, reaching y = -10.5 m at the entry, then advanced each step
    along the heading at that scene. -/
def posAt (mv : Move) : Nat → Vec
  | 0 => (cm 250, Q.sub (cm (-1050)) (Q.mul (Q.ofInt 5) (stepLength mv)))
  | k + 1 =>
    let p := posAt mv k
    let h := headingAt mv (k + 1)
    (Q.add p.1 (Q.mul h.1 (stepLength mv)), Q.add p.2 (Q.mul h.2 (stepLength mv)))

def rider (cls : RoadUserClass) (mv : Move) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [cls] (posAt mv k) (headingAt mv k) (speedOf mv) (cm 100, cm 40, cm 70))
    fun kn => { kn with
      yawRate := some (if kEntry < k ∧ k ≤ kTurnEnd then Units.degrees (yawDuring mv) else Q.zero) }

/-- The body straddles lane 1 and the intersection at the entry, and the intersection and the
    exit lane just before the exit. -/
def occAt (mv : Move) (k : Nat) : List (TrackId × RegionId) :=
  if k < kEntry then [(1, approachLane)]
  else if k = kEntry then [(1, approachLane), (1, junction)]
  else if k ≤ kTurnEnd then [(1, junction)]
  else if k < kExit then [(1, junction), (1, exitLane mv)]
  else [(1, exitLane mv)]

def structures : List Structure :=
  [ Build.rect junction .intersection (m (-10)) (m (-10)) (m 10) (m 10)
  , Build.lane approachLane [(m 0, m (-60)), (m 5, m (-60)), (m 5, m (-10)), (m 0, m (-10))] Build.north
      (enters := some junction)
  , Build.lane 2 [(m 10, m (-5)), (m 60, m (-5)), (m 60, m 0), (m 10, m 0)] Build.east
  , Build.lane 3 [(m 0, m 10), (m 5, m 10), (m 5, m 60), (m 0, m 60)] Build.north
  , Build.lane 4 [(m (-60), m 0), (m (-10), m 0), (m (-10), m 5), (m (-60), m 5)] Build.west ]

def redWithArrow (dir : ArrowDir) (governs : List RegionId) : Device :=
  Build.signal 20 governs [.circularRed, .greenArrow dir]

def turnSign (code : SignCode) (governs : List RegionId) (conditions : Conditions := {}) : Device :=
  { Build.sign 30 .regulatorySign governs with code := some code, conditions := some conditions }

def crossingTrace (cls : RoadUserClass) (mv : Move) (devices : List Device) : Trace :=
  Build.trace nScenes 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1) [rider cls mv k] structures devices (occupies := some (occAt mv k))

/-- `forbid` (violated): A motorcycle on an approach governed by a signal showing circular_red with green_arrow(left) and by a no_right_turn sign with empty conditions enters and turns right. -/
def forbidTrace : Trace :=
  crossingTrace .motorcycle .right [redWithArrow .left [approachLane], turnSign .noRightTurn [approachLane]]

/-- `permit` (compliant): The same right turn at an approach with no regulatory sign of a turn code. -/
def permitTrace : Trace :=
  crossingTrace .motorcycle .right [redWithArrow .left [approachLane]]

/-- `idle` (not_applicable): The motorcycle goes straight through on red with a green left arrow: no turn is made, so the requirement is not applicable. -/
def idleTrace : Trace :=
  crossingTrace .motorcycle .straight [redWithArrow .left [approachLane], turnSign .noRightTurn [approachLane]]

/-- `blind` (unknown): A bicycle turns right on red with a green left arrow; the source does not observe regulatory signs.
    Under the mask no device is known not to be a regulatory sign, the signal head included; its
    face carries no legend restriction (`conditions := some {}`), so what stays unknown is the
    masked kind and the sign code, not an unread legend. -/
def blindTrace : Trace :=
  crossingTrace .bicycle .right
    [{ redWithArrow .left [approachLane] with conditions := some {} }, turnSign .noRightTurn [approachLane]]

/-- `branch_1` (violated): a left turn under circular_red with green_arrow(right), the signal and a
    no_left_turn sign governing the intersection itself. -/
def branch1Trace : Trace :=
  crossingTrace .motorcycle .left [redWithArrow .right [junction], turnSign .noLeftTurn [junction]]

/-- `branch_2` (not_applicable): a left turn under green_arrow(left), the turn the arrow permits,
    neither straight through nor opposite the arrow. -/
def branch2Trace : Trace :=
  crossingTrace .motorcycle .left [redWithArrow .left [approachLane], turnSign .noLeftTurn [approachLane]]

/-- `branch_3` (compliant): the forbid turn, the no_right_turn sign restricted to trucks. -/
def branch3Trace : Trace :=
  crossingTrace .motorcycle .right
    [redWithArrow .left [approachLane], turnSign .noRightTurn [approachLane] { vehicleClass := some .truck }]

/-- `branch_4` (not_applicable): the forbid turn under circular_green with green_arrow(left): no steady red. -/
def branch4Trace : Trace :=
  crossingTrace .motorcycle .right
    [Build.signal 20 [approachLane] [.circularGreen, .greenArrow .left], turnSign .noRightTurn [approachLane]]

/-- `branch_5` (compliant): the forbid turn with a no_left_turn sign, which does not prohibit a right turn. -/
def branch5Trace : Trace :=
  crossingTrace .motorcycle .right [redWithArrow .left [approachLane], turnSign .noLeftTurn [approachLane]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b_o3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, 2200)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.regulatory_sign"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .notApplicable
  , witness "branch_3" branch3Trace .compliant
  , witness "branch_4" branch4Trace .notApplicable
  , witness "branch_5" branch5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_307_9b_o3
