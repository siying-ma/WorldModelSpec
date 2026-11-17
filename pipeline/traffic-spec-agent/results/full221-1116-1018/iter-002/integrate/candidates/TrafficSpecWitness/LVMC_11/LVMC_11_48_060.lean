/-
  Witnesses for LVMC_11_48_060.

  Geometry (metres, +x east, +y north), shared by every witness:
  - highway W1 (id 10): x ∈ [-500, 0], y ∈ [0, 20], an east-west truck route. Lane A (20, eastbound)
    y ∈ [0, 10] and lane A2 (21, westbound) y ∈ [10, 20], both lying on W1 and governed by the
    truck_route sign 101.
  - highway WS (11): residential street S, x ∈ [0, 20], y ∈ [0, 500]; its roadway S (22) lies on WS
    and no truck_route sign governs it (only the keep_right sign 104 does, so its code is what
    keeps S off the truck routes).
  - highway W2 (12): x ∈ [20, 520], y ∈ [480, 500]; lane B (23, eastbound) lies on W2 and is governed
    by the truck_route sign 102.
  The truck (track 1, half-extent 6 m × 1.25 m × 2 m) is sampled every 5 s at 10 m/s (50 m per
  sample) unless halted (speed 0). Every reference point lies well inside one lane/roadway and one
  highway polygon. The first instant is not judged (`window` starts at 5 s): the rise onto a truck
  route there would read the unobserved previous observation.
  The parked reading's window (p.delivery_halt_min_duration = 60 s) is 12 samples; its speed
  tolerance (0.1 m/s) is broken by 10 m/s and kept by 0.
  - forbid: A for k = 0..4, S northbound k = 5..13, B from k = 14 (entry onto B judged at 70 s).
  - permit: A for k = 0..4, S north k = 5..9, back south k = 10..14, onto A2 (also on W1) from k = 15.
  - idle: the forbid trip by a passenger car (motor_vehicle only).
  - blind: forbid, with dev.governs masked.
  - branch_1: forbid, but halted on S at (10, 250) for k = 9..27 (95 s) before driving on to B.
  - branch_2: branch_1, plus a truck-route junction X (24, on W1 and W2, sign 103) at y ∈ [100, 120]
    which the truck is on at k = 6 only: the trigger rises there (compliant: X shares W1 with A),
    and at the entry onto B the exception's stretch must run back through that rise to A.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_48_060
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_48_060

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def structures : List Structure :=
  [ Build.rect 10 .highway (m (-500)) (m 0) (m 0) (m 20)
  , Build.rect 11 .highway (m 0) (m 0) (m 20) (m 500)
  , Build.rect 12 .highway (m 20) (m 480) (m 520) (m 500)
  , { Build.rect 20 .lane (m (-500)) (m 0) (m 0) (m 10) with ways := some [10] }
  , { Build.rect 21 .lane (m (-500)) (m 10) (m 0) (m 20) with ways := some [10] }
  , { Build.rect 22 .roadway (m 0) (m 0) (m 20) (m 500) with ways := some [11] }
  , { Build.rect 23 .lane (m 20) (m 480) (m 520) (m 500) with ways := some [12] } ]

def devices : List Device :=
  [ { Build.sign 101 .regulatorySign [20, 21] with code := some .truckRoute, conditions := some {} }
  , { Build.sign 102 .regulatorySign [23] with code := some .truckRoute, conditions := some {} }
  , { Build.sign 104 .regulatorySign [22] with code := some .keepRight, conditions := some {} } ]

/-- branch_2: a truck-route junction X (24) on S at y ∈ [100, 120], lying on both W1 and W2,
    governed by the truck_route sign 103. -/
def structures2 : List Structure :=
  structures ++ [ { Build.rect 24 .intersection (m 0) (m 100) (m 20) (m 120) with ways := some [10, 12] } ]

def devices2 : List Device :=
  devices ++ [ { Build.sign 103 .regulatorySign [24] with code := some .truckRoute, conditions := some {} } ]

def ext : Q × Q × Q := (m 6, cm 125, m 2)
def v10 : Q := Units.metresPerSecond 10

/-- One sample of the forbid trip with the halt inserted after the k = 8 sample for `halt` samples. -/
def forbidPose (halt : Nat) (k : Nat) : Vec × Vec × Q :=
  if k < 5 then ((m (-250 + 50 * (k : Int)), m 5), Build.east, v10)
  else if k < 9 then ((m 10, m (50 * ((k : Int) - 4))), Build.north, v10)
  else if k < 9 + halt then ((m 10, m 250), Build.north, Q.zero)
  else
    let j : Int := (k : Int) - (halt : Int)   -- the forbid index once the halt is over
    if j < 14 then ((m 10, m (50 * (j - 4))), Build.north, v10)
    else ((m (70 + 50 * (j - 14)), m 490), Build.east, v10)

def permitPose (k : Nat) : Vec × Vec × Q :=
  if k < 5 then ((m (-250 + 50 * (k : Int)), m 5), Build.east, v10)
  else if k < 10 then ((m 10, m (50 * ((k : Int) - 4))), Build.north, v10)
  else if k < 15 then ((m 10, m (250 - 50 * ((k : Int) - 10))), Build.south, v10)
  else ((m (-50 - 50 * ((k : Int) - 15)), m 15), Build.west, v10)

def tripTrace (n : Nat) (classes : List RoadUserClass) (pose : Nat → Vec × Vec × Q)
    (sts : List Structure := structures) (devs : List Device := devices) : Trace :=
  Build.trace n 0 (Units.seconds 5) fun k t =>
    let (p, h, v) := pose k
    Build.scene t (some 1) [ Build.user 1 classes p h v ext ] sts devs

/-- branch_1's trip with the k = 6 sample on the junction X instead of S alone. -/
def branch2Pose (k : Nat) : Vec × Vec × Q :=
  if k = 6 then ((m 10, m 110), Build.north, v10) else forbidPose 19 k

/-- `forbid` (violated): A truck (ru.truck) travels on lane A governed by a truck_route regulatory sign and lying on highway W1, turns onto residential street S (no truck_route sign governs its lanes), drives along S without halting, and comes onto lane B governed by a truck_route sign and lying on highway W2, which A does not lie on. -/
def forbidTrace : Trace := tripTrace 18 [.truck] (forbidPose 0)

/-- `permit` (compliant): The truck leaves lane A on W1 for street S, drives along S, and comes back onto a truck-route lane lying on W1. -/
def permitTrace : Trace := tripTrace 19 [.truck] permitPose

/-- `idle` (not_applicable): A passenger car (ru.motor_vehicle) makes the forbid trip from A over S to B. -/
def idleTrace : Trace := tripTrace 18 [.motorVehicle] (forbidPose 0)

/-- `blind` (unknown): As in forbid, but the source does not observe what signs govern (dev.governs absent): which regions are truck routes is unknown. -/
def blindTrace : Trace := tripTrace 18 [.truck] (forbidPose 0)

/-- `branch_1` (not_applicable): As in forbid, but on S the truck halts at the curb for longer than the delivery dwell before driving on to B. -/
def branch_1Trace : Trace := tripTrace 37 [.truck] (forbidPose 19)

/-- `branch_2` (compliant): As branch_1, but before the halt the truck passes in one sample over
    a truck-route junction X lying on W1 and W2: the rule engages there and holds (X shares W1 with
    A); at the entry onto B the stretch from A runs through that brief rise, and the halt on it
    exempts the trip (without the exception it would be violated). -/
def branch_2Trace : Trace := tripTrace 37 [.truck] branch2Pose structures2 devices2

def witness (name : String) (τ : Trace) (expected : Verdict) (last : Nat)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_48_060"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (5000, 5000 * last)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 17
  , witness "permit" permitTrace .compliant 18
  , witness "idle" idleTrace .notApplicable 17
  , witness "blind" blindTrace (.unknown []) 17 ["dev.governs"]
  , witness "branch_1" branch_1Trace .notApplicable 36
  , witness "branch_2" branch_2Trace .compliant 36 ]

end TrafficSpecWitness.LVMC_11_48_060
