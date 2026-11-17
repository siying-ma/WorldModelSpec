/-
  Witnesses for NRS_484B_270_2a_o1.

  Geometry (the witness's own figures, nowhere in the rule): no structures are needed; the rule
  reads only the two bodies. Instants t = 0 … 16 s at 1 s spacing. The subject car (track 1,
  half-extents 2.5 × 1 m) drives east along y = 0 at 10 m/s, x = 10·t. The overtaken road user
  (track 2, half-extents 1 × 0.3 m) rides east at 5 m/s, x = 65 + 5·t, on the car's right at
  y = −2 m (lateral clearance 0.7 m between the bodies) or, in `forbid`, at y = −1.2 m (the bodies
  overlap laterally by 0.1 m). Its offset ahead of the car is 65 − 5·t: 5 m at t = 12 (ahead, the
  projections 1.5 m apart), 0 at t = 13 (side by side, projections sharing 2 m), −5 m at t = 14
  (behind): the pass is recognized at t = 14, whose 10 s window behind [4, 14] lies inside the
  trace. Both move at 5 or 10 m/s (≫ 0.1 m/s), headings identical (cosine 1 > 0.9). The rider's
  longitudinal acceleration is 0, except in `branch_1` where it is −3 m/s² at t = 13 (below −2).
  The witnesses speak about t ∈ [11, 16] s, where every look-back of 10 s is covered.

  Classes. Under the run's reading ru.motor_vehicle is unresolved for the electric-bicycle and
  electric-scooter aggregates, and ru.electric_scooter is unresolved (nothing is included) for
  DEF-NRS-484B-018::electric_scooter; so a car overtaken stays of unknown class, and an electric
  scooter can never make the rule apply. `idle` therefore overtakes a moped (a motor vehicle,
  decided outside all three aggregates), and `branch_1` overtakes an electric bicycle (see
  task_result.md).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_2a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_2a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The subject car at instant `k`. -/
def car (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m (10 * (k : Int)), Q.zero) Build.east
      (Units.metresPerSecond 10) (cm 250, m 1, cm 75))
    (fun z => { z with accelLongitudinal := some Q.zero })

/-- The overtaken road user at instant `k`: classes, lateral place, and the instant it brakes hard. -/
def other (cls : List RoadUserClass) (y : Q) (brakeAt : Option Nat) (halfExt : Q × Q × Q) (k : Nat) :
    RoadUser :=
  let acc := if brakeAt == some k then Units.metresPerSecondSq (-3) else Q.zero
  Build.withKin
    (Build.user 2 cls (m (65 + 5 * (k : Int)), y) Build.east (Units.metresPerSecond 5) halfExt)
    (fun z => { z with accelLongitudinal := some acc })

def riderExt : Q × Q × Q := (m 1, cm 30, cm 90)

def passTrace (cls : List RoadUserClass) (y : Q) (brakeAt : Option Nat)
    (halfExt : Q × Q × Q := riderExt) : Trace :=
  Build.trace 17 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k, other cls y brakeAt halfExt k] [] []

/-- `forbid` (violated): A bicycle is ridden ahead of the subject car in the same direction; the subject car overtakes it and its side touches the bicycle while the two are side by side. -/
def forbidTrace : Trace := passTrace [.bicycle] (cm (-120)) none

/-- `permit` (compliant): Same pass, made without contact; the bicyclist keeps its speed. -/
def permitTrace : Trace := passTrace [.bicycle] (m (-2)) none

/-- `idle` (not_applicable): The subject car overtakes another motor vehicle (a moped, decided
    outside the three aggregates); no bicycle, electric bicycle or electric scooter is in the scene. -/
def idleTrace : Trace := passTrace [.moped] (m (-2)) none (m 1, cm 40, cm 70)

/-- The measured overlap of the projections on the car's heading at instant `k`: the car covers
    [−2.5, 2.5] m and the rider [d − 1, d + 1] m about the car's centre, d = 65 − 5·k. -/
def measuredOverlap (k : Nat) : Q :=
  let d : Int := 65 - 5 * (k : Int)
  if d == 0 then m 2 else Q.sub (cm 350) (m (Int.ofNat d.natAbs))

/-- `blind` (unknown): As in permit, but the source does not observe contact between bodies. Core
    computes contact from the two footprints wherever it can, so this source does not measure the
    rider's extent (no footprint, hence no contact) and supplies the longitudinal overlap it measures,
    which Core cannot compute without that footprint. -/
def blindTrace : Trace :=
  Build.trace 17 0 (Units.seconds 1) fun k t =>
    let rider := other [.bicycle] (m (-2)) none riderExt k
    let rider := { rider with kin := { rider.kin with extent := none } }
    -- without a footprint the rider's occupancy is not observed either
    let s := Build.scene t (some 1) [car k, rider] [] []
    Build.withRelations { s with occupancyObserved := [1] }
      [Build.relation 1 2 fun r => { r with longitudinalOverlap := some (measuredOverlap k) }]

/-- `branch_1` (violated): The subject car overtakes an electric bicycle without touching it, but
    while they are side by side the rider brakes harder than the evasive deceleration. -/
def branch_1Trace : Trace := passTrace [.electricBicycle] (m (-2)) (some 13)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_2a_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (11000, 16000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.contact"]
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484B_270_2a_o1
