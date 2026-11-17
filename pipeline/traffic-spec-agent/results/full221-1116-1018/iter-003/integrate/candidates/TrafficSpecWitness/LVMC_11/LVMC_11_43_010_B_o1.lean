/-
  Witnesses for LVMC_11_43_010_B_o1.

  Geometry (the witness's own figures; none appears in the rule). The roundabout is region 10, a
  square of kind roundabout from (-20, -20) to (20, 20). Three observations at 0, 1000, 2000 ms.
  The subject (track 1, a motor vehicle, half-extent 2.5 m × 1 m) comes up from the south heading
  north at 5 m/s: (0, -24) at k = 0 (outside), (0, -19) at k = 1 (inside: the entry), (0, -14) at
  k = 2. Each witness judges the instants 1000–2000 ms (`window`): `rises` reads the observation
  before, which the first observation lacks.

  With the reading (horizon 3 s, clearance 3 m):
  - forbid: car 2 heading west at 5 m/s along y = -15, at (6, -15) at the entry; relative position
    (6, 4), relative velocity (-5, -5): closest approach at 1 s, centres √2 ≈ 1.4 m apart (< 3 m).
  - permit: car 2 heading west at 5 m/s along y = 15 at (-10, 15) at the entry: closest approach at
    2.4 s, about 31 m apart (> 3 m); no contact.
  - idle: the subject circulates west along y = -15 inside the roundabout at every instant.
  - blind: the forbid scene with rel.occupies unobserved.
  - branch_1: the subject enters with no other road user in the scene.
  - branch_2: a stopped bus (half-length 6 m) already in the roundabout at (6, -17), heading west;
    its body overlaps the subject's at the entry (contact), centres 6.3 m apart, closest approach
    6 m (> 3 m): violated by contact alone.
  - branch_3: the forbid scene with road user 2 a pedestrian, not of the aggregate: compliant.
  - branch_4: car 2 is itself entering (outside at k = 0, inside at k = 1, heading west at 12 m/s,
    at (10, -15) at the entry): in conflict (closest approach ≈ 0.15 m at 0.83 s) but not already in
    the roundabout: compliant.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_B_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_B_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 250, m 1, cm 75)
def busExtent : Q × Q × Q := (m 6, cm 150, cm 150)

def roundabout : Structure := Build.rect 10 .roundabout (m (-20)) (m (-20)) (m 20) (m 20)

/-- The subject's position at instant k: outside at k = 0, entering at k = 1. -/
def subjectY (k : Nat) : Int :=
  match k with
  | 0 => -24
  | 1 => -19
  | _ => -14

def subjectAt (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m (subjectY k)) Build.north (Units.metresPerSecond 5) carExtent

/-- A road user heading west along a line at constant speed, at x positions per instant. -/
def westbound (track : TrackId) (classes : List RoadUserClass) (x : Nat → Int) (y : Int) (speed : Int)
    (ext : Q × Q × Q) (k : Nat) : RoadUser :=
  Build.user track classes (m (x k), m y) Build.west (Units.metresPerSecond speed) ext

def scene3 (users : Nat → List RoadUser) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (users k) [roundabout] []

def circX (k : Nat) : Int :=
  match k with
  | 0 => 11
  | 1 => 6
  | _ => 1

/-- `forbid` (violated): A car enters the roundabout while a circulating car, already in it, is on a course whose closest approach to the entering car falls within the conflict horizon and below the clearance. -/
def forbidTrace : Trace :=
  scene3 fun k => [subjectAt k, westbound 2 [.motorVehicle] circX (-15) 5 carExtent k]

def farX (k : Nat) : Int :=
  match k with
  | 0 => -5
  | 1 => -10
  | _ => -15

/-- `permit` (compliant): A car enters the roundabout while the only circulating car is on the far side, its closest approach above the clearance. -/
def permitTrace : Trace :=
  scene3 fun k => [subjectAt k, westbound 2 [.motorVehicle] farX 15 5 carExtent k]

def idleX (k : Nat) : Int :=
  match k with
  | 0 => 5
  | 1 => 0
  | _ => -5

/-- `idle` (not_applicable): A car circulates inside the roundabout throughout the recording without entering it. -/
def idleTrace : Trace :=
  scene3 fun k => [westbound 1 [.motorVehicle] idleX (-15) 5 carExtent k]

/-- `blind` (unknown): A car near the roundabout's edge beside a circulating car, where the source does not observe which regions the cars occupy. -/
def blindTrace : Trace :=
  scene3 fun k => [subjectAt k, westbound 2 [.motorVehicle] circX (-15) 5 carExtent k]

/-- `branch_1` (compliant): A car enters an empty roundabout: no other vehicle is in the scene, and the duty is met. -/
def branch_1Trace : Trace :=
  scene3 fun k => [subjectAt k]

/-- `branch_2` (violated): A car enters the roundabout and runs into a stopped bus already in it,
    whose centre stays beyond the conflict clearance: contact alone breaks the duty. -/
def branch_2Trace : Trace :=
  scene3 fun k =>
    [subjectAt k, Build.user 2 [.bus, .motorVehicle] (m 6, m (-17)) Build.west Q.zero busExtent]

/-- `branch_3` (compliant): A car enters the roundabout on a conflicting course with a pedestrian
    already in it: a pedestrian is not a vehicle already in the roundabout. -/
def branch_3Trace : Trace :=
  scene3 fun k => [subjectAt k, westbound 2 [.pedestrian] circX (-15) 5 (cm 30, cm 30, cm 90) k]

def enteringX (k : Nat) : Int :=
  match k with
  | 0 => 22
  | 1 => 10
  | _ => -2

/-- `branch_4` (compliant): Two cars enter the roundabout at the same observation on conflicting
    courses: the other is not already in the roundabout. -/
def branch_4Trace : Trace :=
  scene3 fun k => [subjectAt k, westbound 2 [.motorVehicle] enteringX (-15) 12 carExtent k]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_43_010_B_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (1000, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.LVMC_11_43_010_B_o1
