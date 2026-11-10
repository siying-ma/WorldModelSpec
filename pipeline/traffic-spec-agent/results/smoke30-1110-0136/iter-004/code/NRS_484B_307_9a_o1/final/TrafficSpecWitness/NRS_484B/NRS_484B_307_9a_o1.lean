/-
  Witnesses for NRS_484B_307_9a_o1.

  Geometry (the witness's own figures, nowhere in the rule): an intersection I (region 20) is the
  square x, y ∈ [-10, 10] m. The approach lane L1 (10), x ∈ [0, 4], y ∈ [-40, -10], runs north and
  enters I. Exit lanes: L2 (11) north, x ∈ [0, 4], y ∈ [10, 40]; L3 (12) west, x ∈ [-40, -10],
  y ∈ [0, 4]; L4 (13) east, x ∈ [10, 40], y ∈ [-4, 0]. Signal 30 governs L1 (or, in branch_4, I).

  The car (track 1) is a motor_vehicle. NOTE: the run's reading leaves motor_vehicle (and every
  other class but their own members) unresolved in the aggregates paragraph (b)'s nodes read
  (motorcycle, moped, electric bicycle, electric scooter), so whether (b) applies to the car is
  unknown and forbid / blind / branch_2 … 4 come out unknown; see task_result.md. Its body
  is 2 m × 1 m, every sampled position at least 2 m from a region edge, so its footprint lies in one
  region at a time and occupancy follows from the positions.
  It is sampled every 50 ms (the step bound's value) over 12 scenes: k = 0, 1 in L1,
  k = 2 … 9 in I (entry at t = 100 ms), k = 10, 11 in the exit lane (exit at t = 500 ms). A turn
  yaws at ±225 deg/s at k = 3 … 10 (a scene's rate held over the interval before it): 11.25° per
  interval, 90° from the entry to the exit, well inside the turn band [60°, 150°); the heading
  follows the yaw (rational unit vectors to 1e-6). A through movement does not yaw (0° < 30°). Each
  witness speaks about the instants from the entry to the end (`window`), since the entry is read
  back from the exit.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def laneIn : Structure := Build.lane 10 [(m 0, m (-40)), (m 4, m (-40)), (m 4, m (-10)), (m 0, m (-10))] Build.north (enters := some 20)
def isect : Structure := Build.rect 20 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def laneNorth : Structure := Build.lane 11 [(m 0, m 10), (m 4, m 10), (m 4, m 40), (m 0, m 40)] Build.north
def laneWest : Structure := Build.lane 12 [(m (-40), m 0), (m (-10), m 0), (m (-10), m 4), (m (-40), m 4)] Build.west
def laneEast : Structure := Build.lane 13 [(m 10, m (-4)), (m 40, m (-4)), (m 40, m 0), (m 10, m 0)] Build.east

def structures : List Structure := [laneIn, isect, laneNorth, laneWest, laneEast]

/-- A movement through I: the position at scene k and the turn's sense (1 left, -1 right, 0 none). -/
structure Move where
  pos : Nat → Vec
  turn : Int

def kq (k : Nat) : Int := Int.ofNat k

def u6 (n : Int) : Q := Units.ratio n 1000000

/-- (cos, sin) of n · 11.25°, n = 0 … 8. -/
def rot : Nat → Q × Q
  | 0 => (u6 1000000, u6 0)
  | 1 => (u6 980785, u6 195090)
  | 2 => (u6 923880, u6 382683)
  | 3 => (u6 831470, u6 555570)
  | 4 => (u6 707107, u6 707107)
  | 5 => (u6 555570, u6 831470)
  | 6 => (u6 382683, u6 923880)
  | 7 => (u6 195090, u6 980785)
  | _ => (u6 0, u6 1000000)

/-- Steps of 11.25° turned by scene k: none up to the entry, one per interval inside I. -/
def steps (k : Nat) : Nat := if k ≤ 2 then 0 else if k ≤ 10 then k - 2 else 8

/-- The heading at scene k: north rotated by the steps turned, to the left or to the right. -/
def headingAt (mv : Move) (k : Nat) : Vec :=
  let (c, s) := rot (steps k)
  if mv.turn > 0 then (Q.neg s, c) else if mv.turn < 0 then (s, c) else Build.north

/-- The yaw rate at scene k, held over the interval before it. -/
def yawAt (mv : Move) (k : Nat) : Q :=
  if 3 ≤ k ∧ k ≤ 10 then Units.degrees (225 * mv.turn) else Units.degrees 0

def approachPos (k : Nat) : Vec := (cm 200, cm (-1600 + 300 * kq k))

def straight : Move :=
  { pos := fun k => if k < 2 then approachPos k
                    else if k < 10 then (cm 200, cm (-800 + 200 * (kq k - 2)))
                    else (cm 200, cm (1300 + 300 * (kq k - 10)))
    turn := 0 }

def left : Move :=
  { pos := fun k => if k < 2 then approachPos k
                    else if k < 10 then (cm (200 - 100 * (kq k - 2)), cm (-800 + 100 * (kq k - 2)))
                    else (cm (-1300 - 300 * (kq k - 10)), cm 200)
    turn := 1 }

def right : Move :=
  { pos := fun k => if k < 2 then approachPos k
                    else if k < 10 then (cm (200 + 85 * (kq k - 2)), cm (-800 + 100 * (kq k - 2)))
                    else (cm (1300 + 300 * (kq k - 10)), cm (-200))
    turn := -1 }

/-- The trace: one road user of `classes` making `mv`, the signal `sig` constant throughout. -/
def crossing (classes : List RoadUserClass) (mv : Move) (sig : Device) : Trace :=
  Build.trace 12 0 (Units.milliseconds 50) fun k t =>
    let u := Build.withKin
      (Build.user 1 classes (mv.pos k) (headingAt mv k) (Units.metresPerSecond 10) (m 1, cm 50, cm 50))
      fun kin => { kin with yawRate := some (yawAt mv k) }
    Build.scene t (some 1) [u] structures [sig]

def redLeft : Device := Build.signal 30 [10] [.circularRed, .greenArrow .left]

/-- `forbid` (violated): A car on an approach lane governed by a signal showing circular_red with green_arrow(left) enters the intersection and leaves it with a heading change below the straight-through bound. -/
def forbidTrace : Trace := crossing [.motorVehicle] straight redLeft

/-- `permit` (compliant): The same car enters on circular_red with green_arrow(left) and leaves with a left turn. -/
def permitTrace : Trace := crossing [.motorVehicle] left redLeft

/-- `idle` (not_applicable): The car enters on circular_green and goes straight through. -/
def idleTrace : Trace := crossing [.motorVehicle] straight (Build.signal 30 [10] [.circularGreen])

/-- `blind` (unknown): A car enters on circular_red with green_arrow(left) and leaves the intersection; the source supplies no yaw rate, so the movement made is unknown. -/
def blindTrace : Trace := crossing [.motorVehicle] straight redLeft

/-- `branch_1` (not_applicable): A motorcycle enters on circular_red with green_arrow(left) and goes straight through: paragraph (b) applies to it, so this duty does not. -/
def branch_1Trace : Trace := crossing [.motorcycle] straight redLeft

/-- `branch_2` (violated): a car turns left on circular_red with green_arrow(right) only. -/
def branch_2Trace : Trace := crossing [.motorVehicle] left (Build.signal 30 [10] [.circularRed, .greenArrow .right])

/-- `branch_3` (violated): a car turns right on circular_red with green_arrow(left) only. -/
def branch_3Trace : Trace := crossing [.motorVehicle] right redLeft

/-- `branch_4` (compliant): a signal governing the intersection itself shows circular_red with
    green_arrow(left) and green_arrow(straight); the car goes straight through. -/
def branch_4Trace : Trace :=
  crossing [.motorVehicle] straight (Build.signal 30 [20] [.circularRed, .greenArrow .left, .greenArrow .straight])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9a_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (100, 550)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_484B_307_9a_o1
