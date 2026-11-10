/-
  Witnesses for NRS_484B_307_9a_o1.

  One crossing, sampled at 20 Hz (50 ms, the acquisition standard's step), 28 scenes (0 … 1350 ms).
  An approach lane 10 (x 0…4 m, y −30…0 m, northbound) enters the intersection 20 (x −10…14 m,
  y 0…20 m); lane 30 leaves it. Signal 100 governs lane 10 (or, in branch_2, the intersection).
  Track 1 (half-extents 2.25 × 0.90 × 0.75 m, 5 m/s) occupies lane 10 at scenes 0–3, lane 10 and
  the intersection at scene 4 (the entry), the intersection alone at scenes 5–24 and lane 30 from
  scene 25 (the exit). Occupancy is stated, not derived. Yaw rate is 0 deg/s outside scenes 5–24;
  a turn holds ±90 deg/s over those 20 scenes (≈ 90°, inside the turn bands [60°, 150°)); a through
  movement holds 0 (below 30°). `window` starts at scene 1, since `rises` at scene 0 has no past.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def laneIn : Structure :=
  Build.lane 10 [(m 0, m (-30)), (m 4, m (-30)), (m 4, m 0), (m 0, m 0)] Build.north (enters := some 20)
def isec : Structure := Build.rect 20 .intersection (m (-10)) (m 0) (m 14) (m 20)
def laneOut : Structure :=
  Build.lane 30 [(m 0, m 20), (m 4, m 20), (m 4, m 50), (m 0, m 50)] Build.north

def occupancyAt (k : Nat) : List (TrackId × RegionId) :=
  if k < 4 then [(1, 10)]
  else if k == 4 then [(1, 10), (1, 20)]
  else if k < 25 then [(1, 20)]
  else [(1, 30)]

/-- Yaw rate during the turn (scenes 5–24), zero elsewhere. -/
def turnYaw (deg : Int) (k : Nat) : Option Q :=
  if 5 ≤ k && k ≤ 24 then some (Units.degrees deg) else some Q.zero

def straightYaw (_k : Nat) : Option Q := some Q.zero
def noYaw (_k : Nat) : Option Q := none

/-- The crossing, with the subject's classes, the signal's faces, what it governs and the yaw rate. -/
def crossing (classes : List RoadUserClass) (shows : List SignalIndication) (governs : List RegionId)
    (yaw : Nat → Option Q) : Trace :=
  Build.trace 28 0 (Units.milliseconds 50) fun k t =>
    let u := Build.user 1 classes (m 2, cm (25 * (k : Int) - 500)) Build.north
      (Units.metresPerSecond 5) (cm 225, cm 90, cm 75)
    Build.scene t (some 1)
      [ Build.withKin u fun kn => { kn with yawRate := yaw k } ]
      [ laneIn, isec, laneOut ]
      [ Build.signal 100 governs shows ]
      (occupies := some (occupancyAt k))

def redLeft : List SignalIndication := [.circularRed, .greenArrow .left]

/-- `forbid` (violated): A car on an approach lane governed by a signal showing circular_red with green_arrow(left) enters the intersection and leaves it with a heading change below the straight-through bound. -/
def forbidTrace : Trace := crossing [.motorVehicle] redLeft [10] straightYaw

/-- `permit` (compliant): The same car enters on circular_red with green_arrow(left) and leaves with a left turn. -/
def permitTrace : Trace := crossing [.motorVehicle] redLeft [10] (turnYaw 90)

/-- `idle` (not_applicable): The car enters on circular_green and goes straight through. -/
def idleTrace : Trace := crossing [.motorVehicle] [.circularGreen] [10] straightYaw

/-- `blind` (unknown): A car enters on circular_red with green_arrow(left) and leaves the intersection; the source supplies no yaw rate, so the movement made is unknown. -/
def blindTrace : Trace := crossing [.motorVehicle] redLeft [10] noYaw

/-- `branch_1` (not_applicable): A motorcycle enters on circular_red with green_arrow(left) and goes straight through: paragraph (b) applies to it, so this duty does not. -/
def branch_1Trace : Trace := crossing [.motorcycle] redLeft [10] straightYaw

/-- `branch_2` (violated): the signal governs the intersection itself (no approach carrier); a car
    on circular_red with green_arrow(left) goes straight through. -/
def branch_2Trace : Trace := crossing [.motorVehicle] redLeft [20] straightYaw

/-- `branch_3` (compliant): circular_red with green_arrow(right); the car turns right. -/
def branch_3Trace : Trace := crossing [.motorVehicle] [.circularRed, .greenArrow .right] [10] (turnYaw (-90))

/-- `branch_4` (violated): circular_red with green_arrow(left); the car turns right. -/
def branch_4Trace : Trace := crossing [.motorVehicle] redLeft [10] (turnYaw (-90))

/-- `branch_5` (compliant): circular_red with green_arrow(left) and green_arrow(straight); the car
    goes straight through. -/
def branch_5Trace : Trace :=
  crossing [.motorVehicle] [.circularRed, .greenArrow .left, .greenArrow .straight] [10] straightYaw

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9a_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, 1350)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_307_9a_o1
