/-
  Witnesses for NRS_484B_307_9a_o1.

  One junction for every scene: a northbound approach lane 10 (x 0…4 m, y −40…0 m) whose entrance
  end is intersection 20 (x −10…10 m, y 0…10 m); signal head 30 governs lane 10 (in branch_5 the
  intersection 20 instead). Track 1, a body of
  20 × 20 cm footprint (small, so that its footprint and its reference point lie in the same
  regions), is sampled every 50 ms for 40 scenes (0…1950 ms) and moves 50 cm along its heading each
  scene, from (2 m, −0.75 m) heading north: on the lane at scenes 0–1, inside the intersection from
  scene 2 (entry at 100 ms).
  - Through: the heading stays north and the yaw rate zero; it leaves the far edge at scene 22.
  - Turns: from scene 4 to scene 19 the heading turns by one step per scene, the rotation with
    cosine 399/401 and sine 40/401 (2·atan(1/20) ≈ 5.7248°), to the left or to the right, and the
    yaw rate is that step over 50 ms (≈ 114.496 deg/s, signed); zero elsewhere. The 16 steps make
    ≈ 91.6° between entry and exit, well inside the 60–150° turn band; the body then runs west
    (left) or east (right) out of the intersection's side edge.
  Each witness speaks about 50…1950 ms, after the first observation, where `rises` has no previous
  scene. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def approachLane : Structure :=
  Build.lane 10 [(m 0, m (-40)), (m 4, m (-40)), (m 4, m 0), (m 0, m 0)] Build.north
    (enters := some 20)
def junction : Structure := Build.rect 20 .intersection (m (-10)) (m 0) (m 10) (m 10)

/-- One heading step: the rotation with cosine 399/401 and sine 40/401 (exactly unit). -/
def stepCos : Q := Units.ratio 399 401
def stepSin : Q := Units.ratio 40 401
/-- The yaw rate that turns the heading by one step in 50 ms: 2·atan(1/20) = 5.7248104522…°
    over 0.05 s, in deg/s. -/
def stepYaw : Q := Units.ratio 114496209044 1000000000

/-- Turn a heading by one step, to the left for `dir = 1`, to the right for `dir = -1`. -/
def turn (dir : Int) (h : Vec) : Vec :=
  let s := Q.mul (Q.ofInt dir) stepSin
  (Q.sub (Q.mul stepCos h.1) (Q.mul s h.2), Q.add (Q.mul s h.1) (Q.mul stepCos h.2))

/-- North turned by `n` steps. -/
def turns (dir : Int) : Nat → Vec
  | 0 => Build.north
  | n + 1 => turn dir (turns dir n)

/-- The heading at scene `k`: one step per scene from scene 4 to scene 19 (`dir = 0`: none). -/
def headingAt (dir : Int) (k : Nat) : Vec := turns dir (min (k - 3) 16)

/-- The yaw rate at scene `k`, held over the interval before it. -/
def yawAt (dir : Int) (k : Nat) : Q :=
  if 4 ≤ k && k ≤ 19 then Q.mul (Q.ofInt dir) stepYaw else Units.degrees 0

/-- The reference point at scene `k`: 50 cm along the heading per scene. -/
def posAt (dir : Int) : Nat → Vec
  | 0 => (m 2, cm (-75))
  | k + 1 =>
    let p := posAt dir k
    let h := headingAt dir (k + 1)
    (Q.add p.1 (Q.mul (cm 50) h.1), Q.add p.2 (Q.mul (cm 50) h.2))

/-- A crossing by track 1 of the given classes under signal 30 showing `shows`: straight on for
    `dir = 0`, a left turn for `1`, a right turn for `-1`. Position, heading, extent and yaw rate
    are observed; the speed and velocity, which the rule does not read, are not. -/
def crossing (classes : List RoadUserClass) (shows : List SignalIndication) (dir : Int)
    (governs : List RegionId := [10]) : Trace :=
  Build.trace 40 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (Build.sparseUser 1 classes (posAt dir k))
          (fun kin => { kin with heading := some (headingAt dir k)
                                 extent := some (cm 10, cm 10, cm 10)
                                 yawRate := some (yawAt dir k) }) ]
      [ approachLane, junction ]
      [ Build.signal 30 governs shows ]

/-- `forbid` (violated): A car (ru.motor_vehicle) on an approach lane governed by a signal showing circular_red with green_arrow(u_turn) and no other arrow enters the intersection and leaves it with a left turn (drv.motion.left_turn_through_region). Paragraph (b)'s nodes read only a left or a right arrow, so their applicability is false whatever the car's class and the exception is decided not to hold. -/
def forbidTrace : Trace :=
  crossing [.motorVehicle] [.circularRed, .greenArrow .uTurn] 1

/-- `permit` (compliant): A car (ru.motor_vehicle) enters on circular_red with green_arrow(left) and no other arrow and leaves with a left turn; a left turn under a left arrow is neither a through movement nor a turn opposite the arrow, so paragraph (b)'s applicability is false whatever the car's class. -/
def permitTrace : Trace :=
  crossing [.motorVehicle] [.circularRed, .greenArrow .left] 1

/-- `idle` (not_applicable): The car enters on circular_green and goes straight through. -/
def idleTrace : Trace :=
  crossing [.motorVehicle] [.circularGreen] 0

/-- `blind` (unknown): A car (ru.motor_vehicle) enters on circular_red with green_arrow(u_turn) and no other arrow and leaves the intersection; the source supplies no yaw rate, so the movement made is unknown. Paragraph (b) reads no u_turn arrow, so its exception is decided not to hold and the unknown comes from the yaw rate alone. -/
def blindTrace : Trace :=
  crossing [.motorVehicle] [.circularRed, .greenArrow .uTurn] 1

/-- `branch_1` (not_applicable): A road user carrying ru.motorcycle and no other class enters on circular_red with green_arrow(left) and goes straight through: paragraph (b) applies to it, so this duty does not. -/
def branch_1Trace : Trace :=
  crossing [.motorcycle] [.circularRed, .greenArrow .left] 0

/-- `branch_2` (violated): A car (ru.motor_vehicle) enters on circular_red with green_arrow(u_turn) and no other arrow and goes straight through (drv.motion.straight_through_region). -/
def branch_2Trace : Trace :=
  crossing [.motorVehicle] [.circularRed, .greenArrow .uTurn] 0

/-- `branch_3` (violated): A car (ru.motor_vehicle) enters on circular_red with green_arrow(u_turn) and no other arrow and leaves with a right turn (drv.motion.right_turn_through_region). -/
def branch_3Trace : Trace :=
  crossing [.motorVehicle] [.circularRed, .greenArrow .uTurn] (-1)

/-- `branch_4` (compliant): A car (ru.motor_vehicle) enters on circular_red with green_arrow(right) and no other arrow and leaves with a right turn; paragraph (b)'s applicability is false (a right turn under a right arrow is neither through nor opposite). -/
def branch_4Trace : Trace :=
  crossing [.motorVehicle] [.circularRed, .greenArrow .right] (-1)

/-- `branch_5` (violated): the signal governs the intersection itself, not the approach lane
    (dev.governs(s, i)); a car enters on circular_red with green_arrow(u_turn) and no other arrow
    and goes straight through. -/
def branch_5Trace : Trace :=
  crossing [.motorVehicle] [.circularRed, .greenArrow .uTurn] 0 [20]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9a_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, 1950)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_9a_o1
