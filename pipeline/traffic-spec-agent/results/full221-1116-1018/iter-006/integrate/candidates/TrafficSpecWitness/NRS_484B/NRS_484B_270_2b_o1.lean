/-
  Witnesses for NRS_484B_270_2b_o1.

  Geometry (the witness's own figures): a straight road running east, one lane in the subject's
  direction. Sixteen instants one second apart (t = 0 … 15 s).
  - Subject car, track 1: at (10·k m, 0), heading east, 10 m/s; half-extent 2.5 m × 1 m.
  - Overtaken road user, track 2: at (60 + 5·k m, y), heading east, 5 m/s (well above the halt
    tolerance); half-extent 1 m × 0.3 m. Its longitudinal offset from the car is 60 − 5·k m:
    ahead with a clear gap for k ≤ 11, side by side at k = 12 (offset 0), behind with a clear gap
    from k = 13, where the pass is recognized (t = 13 s). The 10 s window behind that recognition
    (3 … 13 s) lies inside the trace; the witnesses speak about 11 … 15 s.
  - forbid: a bicycle at y = 1 m: at k = 12 its body overlaps the car's laterally (contact).
  - permit / blind: a bicycle at y = 2.5 m (1.2 m clear of the car's side), steady (acceleration 0).
    Core computes contact from the bodies' outlines when no measured contact is given, so masking
    rel.contact alone leaves it decided; in blind the source also lacks the bicycle's outline
    (its extent is unobserved) and supplies the longitudinal overlap as measured (3.5 m − |offset|,
    2 m when side by side), which Core can then no longer compute.
  - idle: a moped at y = 3.5 m — the only motor-vehicle class that is neither a member nor an
    unresolved class of any of the three rider aggregates in the run's reading.
  - branch_1: an electric bicycle at y = 2.5 m, braking at −4 m/s² at k = 12 (side by side).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_2b_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_2b_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def subjectCar (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m (10 * (k : Int)), Q.zero) Build.east (Units.metresPerSecond 10)
      (cm 250, m 1, cm 75))
    fun kin => { kin with accelLongitudinal := some Q.zero }

/-- The overtaken road user: class, lateral position, and its acceleration at step `k`. -/
def other (cls : List RoadUserClass) (y : Q) (accel : Nat → Q) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 2 cls (m (60 + 5 * (k : Int)), y) Build.east (Units.metresPerSecond 5)
      (m 1, cm 30, cm 80))
    fun kin => { kin with accelLongitudinal := some (accel k) }

def steady (_k : Nat) : Q := Q.zero
def brakesAlongside (k : Nat) : Q := if k == 12 then Units.metresPerSecondSq (-4) else Q.zero

def passTrace (u : Nat → RoadUser) : Trace :=
  Build.trace 16 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectCar k, u k] [] []

/-- `forbid` (violated): On a road with one lane in the subject's direction, a bicycle is ridden ahead of the subject car; the subject car overtakes it and its mirror touches the bicyclist while side by side. -/
def forbidTrace : Trace := passTrace (other [.bicycle] (m 1) steady)

/-- `permit` (compliant): Same pass, made without contact; the bicyclist keeps its speed. -/
def permitTrace : Trace := passTrace (other [.bicycle] (cm 250) steady)

/-- `idle` (not_applicable): The subject car overtakes another car; no bicycle, electric bicycle or electric scooter is in the scene. The duty binds the subject alone. -/
def idleTrace : Trace := passTrace (other [.moped] (cm 350) steady)

/-- `blind` (unknown): As in permit, but the source does not observe contact between bodies. -/
def blindTrace : Trace :=
  Build.trace 16 0 (Units.seconds 1) fun k t =>
    let rider := Build.withKin (other [.bicycle] (cm 250) steady k) fun kin => { kin with extent := none }
    let off : Int := 60 - 5 * (k : Int)
    let overlap : Q := if k == 12 then m 2 else cm (350 - 100 * off.natAbs)
    let s := Build.scene t (some 1) [subjectCar k, rider] [] []
    -- without an outline the bicycle's occupancy is not observed either
    Build.withRelations { s with occupancyObserved := [1] }
      [Build.relation 1 2 fun r => { r with longitudinalOverlap := some overlap }]

/-- `branch_1` (violated): The subject car overtakes an electric bicycle without touching it, but while they are side by side the rider brakes harder than the evasive deceleration. -/
def branch_1Trace : Trace := passTrace (other [.electricBicycle] (cm 250) brakesAlongside)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_2b_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (11000, 15000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.contact"]
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484B_270_2b_o1
