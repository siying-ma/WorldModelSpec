/-
  Witnesses for NRS_484B_307_4a_o1.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - approach lane 10: x ∈ [-40, 0] m, y ∈ [-2, 2] m, direction east, entering intersection 20;
  - intersection 20: x ∈ [0, 10] m, y ∈ [-10, 10] m;
  - traffic signal 30 governing lane 10; what it displays is the scenario's.
  - subject, track 1, a motor vehicle, half-length 2 m, half-width 1 m; sampled every 50 ms
    (the carla_scene_graph rate), 25 scenes, t = 0 … 1200 ms. Its reference point advances
    0.72 m a scene, x = -3.44 + 0.72·k m: front reaches the intersection at k = 2 (entry: it
    occupies the lane and the intersection), rear leaves the lane after k = 7 and the
    intersection after k = 21 (exit at k = 22, t = 1100 ms). Occupancy is stated per scene, since
    the body spans two regions at the entry.
  - The heading change through the intersection is carried by the yaw rate, set at every scene
    after the entry up to the exit (k = 3 … 22, 20 intervals of 50 ms, 1 s): 0 deg/s straight
    through, 90 deg/s for a 90° left turn, -90 deg/s for a 90° right turn, 180 deg/s for a
    reversal. The heading vector follows that rate (each interval turned by the rate of the scene
    that ends it; unit vectors from a Taylor series, floored to 10⁻⁹) and the position advances
    0.72 m a scene along it. The stated occupancy follows the straight passage; on a turning one
    it is the witness's schedule (entry at k = 2, exit at k = 22).
  - Every witness speaks about t = 50 … 1200 ms (`window`): the exit and entry edges (`rises`) are
    unobserved at the first scene.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_4a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_4a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneId : RegionId := 10
def interId : RegionId := 20
def signalId : DeviceId := 30

def approach : Structure :=
  Build.lane laneId [(m (-40), m (-2)), (m 0, m (-2)), (m 0, m 2), (m (-40), m 2)] Build.east
    (enters := some interId)

def intersection : Structure := Build.rect interId .intersection (m 0) (m (-10)) (m 10) (m 10)

/-- π to seven digits (355/113), for the heading vectors only. -/
def piQ : Q := Q.mk' 355 113

/-- (sin x, cos x) by their Taylor series, x in radians, |x| ≤ π. -/
def sinCos (x : Q) : Q × Q := Id.run do
  let x2 := Q.mul x x
  let mut c := Q.ofInt 1
  let mut s := x
  let mut tc := Q.ofInt 1
  let mut ts := x
  for n in [1:16] do
    tc := Q.neg (Q.div (Q.mul tc x2) (Q.ofInt (Int.ofNat ((2 * n - 1) * (2 * n)))))
    ts := Q.neg (Q.div (Q.mul ts x2) (Q.ofInt (Int.ofNat ((2 * n) * (2 * n + 1)))))
    c := Q.add c tc
    s := Q.add s ts
  return (s, c)

/-- A quantity floored to 10⁻⁹. -/
def roundNano (q : Q) : Q := Q.mk' ((q.num * 1000000000) / (q.den : Int)) 1000000000

/-- The unit heading at `deg` degrees counter-clockwise from east. -/
def headingAt (deg : Q) : Vec :=
  let sc := sinCos (Q.div (Q.mul deg piQ) (Q.ofInt 180))
  (roundNano sc.2, roundNano sc.1)

/-- The yaw rate at scene `k`: held over the interval before the scene, from the one after the
    entry (k = 3) to the exit (k = 22). -/
def yawAt (yaw : Q) (k : Nat) : Q := if 3 ≤ k && k ≤ 22 then yaw else Q.zero

/-- The heading angle at scene `k` (degrees from east): the yaw rate integrated over 50 ms
    intervals, each interval taking the rate of the scene that ends it. -/
def angleAt (yaw : Q) (k : Nat) : Q :=
  let turned : Nat := if k ≤ 2 then 0 else if k ≤ 22 then k - 2 else 20
  Q.mul yaw (Q.mul (Units.milliseconds 50) (Q.ofInt (Int.ofNat turned)))

/-- The subject's reference point at scene `k`: 0.72 m a scene along the heading of the scene
    that ends each interval. -/
def posAt (yaw : Q) : Nat → Vec
  | 0 => (cm (-344), m 0)
  | k + 1 =>
    let p := posAt yaw k
    let u := headingAt (angleAt yaw (k + 1))
    (Q.add p.1 (Q.mul (cm 72) u.1), Q.add p.2 (Q.mul (cm 72) u.2))

/-- What the subject occupies at scene `k`. -/
def occAt (k : Nat) : List (TrackId × RegionId) :=
  (if k ≤ 7 then [(1, laneId)] else []) ++ (if 2 ≤ k && k ≤ 21 then [(1, interId)] else [])

/-- A passage through the intersection under a signal displaying `showsAt k`, with yaw rate `yaw`
    from the entry to the exit. -/
def passage (showsAt : Nat → List SignalIndication) (yaw : Q) : Trace :=
  Build.trace 25 0 (Units.milliseconds 50) fun k t =>
    let u := Build.withKin
      (Build.user 1 [.motorVehicle] (posAt yaw k) (headingAt (angleAt yaw k)) (cm 1440) (m 2, m 1, cm 75))
      fun kn => { kn with yawRate := some (yawAt yaw k) }
    Build.scene t (some 1) [u] [approach, intersection] [Build.signal signalId [laneId] (showsAt k)]
      (occupies := some (occAt k))

/-- `forbid` (violated): The subject vehicle enters an intersection from an approach lane whose dev.traffic_signal displays green_arrow(left) alone and drives straight through: at its exit drv.motion.left_turn_through_region does not hold (heading change about 0 degrees). No other road user is in the scene. -/
def forbidTrace : Trace := passage (fun _ => [.greenArrow .left]) (Units.degrees 0)

/-- `permit` (compliant): The same subject turns left through the intersection on the green left arrow alone: at its exit the heading change since its entry is about 90 degrees to the left. -/
def permitTrace : Trace := passage (fun _ => [.greenArrow .left]) (Units.degrees 90)

/-- `idle` (not_applicable): The signal governing the subject's approach displays circular_green alone throughout its passage; the subject drives straight through. -/
def idleTrace : Trace := passage (fun _ => [.circularGreen]) (Units.degrees 0)

/-- `blind` (unknown): The subject passes through the intersection on a green left arrow alone, but its yaw rate is not observed: the turn concepts cannot be decided at its exit. -/
def blindTrace : Trace := passage (fun _ => [.greenArrow .left]) (Units.degrees 0)

/-- `occasion_s1` (violated): The signal displays green_arrow(left) alone when the subject enters the intersection and changes to yellow_arrow(left) while the subject is inside; the subject drives straight through: the arrow was displayed alone for part of the passage only. -/
def occasion_s1Trace : Trace :=
  passage (fun k => if k ≤ 5 then [.greenArrow .left] else [.yellowArrow .left]) (Units.degrees 0)

/-- `occasion_s1_outside` (not_applicable): The signal displays green_arrow(left) alone only before the subject enters the intersection and circular_red from its entry to its exit; the subject drives straight through: the arrow held only before the passage began. -/
def occasion_s1_outsideTrace : Trace :=
  passage (fun k => if k ≤ 1 then [.greenArrow .left] else [.circularRed]) (Units.degrees 0)

/-- `branch_1` (compliant): green_arrow(right) alone; the subject turns 90° right through the intersection. -/
def branch_1Trace : Trace := passage (fun _ => [.greenArrow .right]) (Units.degrees (-90))

/-- `branch_2` (compliant): green_arrow(u_turn) alone; the subject reverses direction (180°) through the intersection. -/
def branch_2Trace : Trace := passage (fun _ => [.greenArrow .uTurn]) (Units.degrees 180)

/-- `branch_3` (not_applicable): green_arrow(left) shown together with circular_red, so not alone; the subject drives straight through. -/
def branch_3Trace : Trace := passage (fun _ => [.greenArrow .left, .circularRed]) (Units.degrees 0)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_4a_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (50, 1200)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "occasion_s1" occasion_s1Trace .violated
  , witness "occasion_s1_outside" occasion_s1_outsideTrace .notApplicable
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_4a_o1
