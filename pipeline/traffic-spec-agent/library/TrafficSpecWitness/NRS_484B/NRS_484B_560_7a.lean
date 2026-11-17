/-
  Witnesses for NRS_484B_560_7a.

  Geometry (the witness's own figures): a road along +x (east). The railway crossing is region 10,
  the rectangle x ∈ [0, 10] m, y ∈ [-5, 5] m. In `idle` an intersection (region 20) lies at
  x ∈ [290, 310] m, far from the crossing. Every trace has three instants 1 s apart (t = 0, 1000,
  2000 ms). The subject (track 1) heads east. Occupancy is stated per scene from the bodies.

  - forbid: truck, half-length 6 m: x = -30 (5 m/s, 24 m short of the crossing), x = 5 (5 m/s, on
    it), x = 18 (at rest, rear end at 12 m: 2 m past the crossing outline, below 15 ft = 4.572 m).
  - permit: car, half-length 2.5 m: x = -30 (10 m/s), x = 5 (10 m/s, on it), x = 20.5 (at rest,
    rear end 8 m past the crossing outline, beyond 15 ft).
  - idle: car halts in the intersection at x = 300, 287.5 m and more from the crossing.
  - blind: car, x = -30, then on the crossing at x = 4 and x = 5, with no speed observed.
  - branch_1: car, x = -30 (10 m/s), then at rest at x = 5 on the crossing.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_560_7a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_560_7a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def crossing : Structure := Build.rect 10 .railwayCrossing (m 0) (m (-5)) (m 10) (m 5)
def intersection : Structure := Build.rect 20 .intersection (m 290) (m (-10)) (m 310) (m 10)

def truckExtent : Q × Q × Q := (m 6, cm 125, cm 200)
def carExtent : Q × Q × Q := (cm 250, m 1, cm 75)

/-- One scene with the subject at `x` (centimetres) moving at `v` (m/s), with stated occupancy. -/
def sceneAt (t : Timestamp) (cls : RoadUserClass) (ext : Q × Q × Q) (xcm : Int) (v : Q)
    (structs : List Structure) (occ : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some 1)
    [ Build.user 1 [cls] (cm xcm, m 0) Build.east v ext ]
    structs [] (some occ)

/-- `forbid` (violated): The subject truck enters the railway crossing (rel.occupies), the queue ahead stops it, and it comes to rest (kin.speed 0) with its body 2 m past the crossing outline, below 15 ft. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t .truck truckExtent (-3000) (Units.metresPerSecond 5) [crossing] []
    | 1 => sceneAt t .truck truckExtent 500 (Units.metresPerSecond 5) [crossing] [(1, 10)]
    | _ => sceneAt t .truck truckExtent 1800 Q.zero [crossing] []

/-- `permit` (compliant): The subject car traverses the crossing without halting and halts in the queue with its body 8 m past the crossing outline. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t .motorVehicle carExtent (-3000) (Units.metresPerSecond 10) [crossing] []
    | 1 => sceneAt t .motorVehicle carExtent 500 (Units.metresPerSecond 10) [crossing] [(1, 10)]
    | _ => sceneAt t .motorVehicle carExtent 2050 Q.zero [crossing] []

/-- `idle` (not_applicable): The subject car never overlaps a railway crossing; it halts at an intersection far from any track. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t .motorVehicle carExtent 27000 (Units.metresPerSecond 10) [crossing, intersection] []
    | 1 => sceneAt t .motorVehicle carExtent 29500 (Units.metresPerSecond 5) [crossing, intersection] [(1, 20)]
    | _ => sceneAt t .motorVehicle carExtent 30000 Q.zero [crossing, intersection] [(1, 20)]

/-- A car whose speed the source does not supply. -/
def blindScene (t : Timestamp) (xcm : Int) (occ : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some 1)
    [ Build.withKin (Build.user 1 [.motorVehicle] (cm xcm, m 0) Build.east Q.zero carExtent)
        (fun k => { k with speed := none }) ]
    [crossing] [] (some occ)

/-- `blind` (unknown): The subject car is on the crossing (rel.occupies true) but the source does not supply kin.speed, so whether it halts is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => blindScene t (-3000) []
    | 1 => blindScene t 400 [(1, 10)]
    | _ => blindScene t 500 [(1, 10)]

/-- `branch_1` (violated): The subject car comes to rest while its footprint still overlaps the crossing. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t .motorVehicle carExtent (-3000) (Units.metresPerSecond 10) [crossing] []
    | _ => sceneAt t .motorVehicle carExtent 500 Q.zero [crossing] [(1, 10)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_560_7a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484B_560_7a
