/-
  Witnesses for LVMC_11_43_010_B_o1.

  Geometry (the witness's own figures, none of them in the rule): a roundabout region 10, the
  square [0, 40] m × [0, 40] m. Three observations, 1 s apart (t = 0, 1000, 2000 ms); occupancy
  follows the reference point (`Build.scene`). Cars are 4 m × 2 m bodies.
  - The entering car (track 1) comes up the south approach at x = 20 m, heading north at 5 m/s:
    y = −8, −3, 2 m, so it enters the roundabout at t = 2000 ms.
  - forbid: a car (track 2) circulates westward at y = 7 m, 5 m/s, x = 38, 33, 28 m. At the entry
    the relative position is (8, 5) m, relative velocity (−5, −5) m/s: closest approach after
    1.3 s at about 2.1 m between centres (horizon 3 s, clearance 3 m).
  - permit: the circulating car is on the far side, westward at y = 35 m, x = 20, 15, 10 m:
    closest approach after 2.3 s at about 30 m.
  - idle: the car circulates eastward inside the roundabout at y = 5 m throughout.
  - blind: the forbid scene with rel.occupies not observed.
  - branch_1: the entering car alone.
  - branch_2: the forbid scene with a bicycle in place of the circulating car (not a vehicle).
  - branch_3: a car entering from the east approach at the same instant (x = 58, 48, 38 m at
    y = 10 m, 10 m/s westward): closest approach after 1.76 s at about 0.9 m, but it was not in the
    roundabout at the observation before the entry.
  Every witness judges the instants t = 1000 and 2000 ms (`window`), each with an observation
  before it.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_B_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_B_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carBody : Q × Q × Q := (m 2, m 1, cm 75)
def bikeBody : Q × Q × Q := (cm 90, cm 30, cm 90)

def roundabout : Structure := Build.rect 10 .roundabout (m 0) (m 0) (m 40) (m 40)

/-- The entering car, at observation k. -/
def entering (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 20, m (-8 + 5 * (k : Int))) Build.north (Units.metresPerSecond 5) carBody

/-- The circulating car of `forbid`, westward at y = 7 m. -/
def circulatingNear (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (38 - 5 * (k : Int)), m 7) Build.west (Units.metresPerSecond 5) carBody

/-- `forbid` (violated): A car enters the roundabout while a circulating car, already in it, is on a course whose closest approach to the entering car falls within the conflict horizon and below the clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k, circulatingNear k ]
      [ roundabout ]
      [ ]

/-- `permit` (compliant): A car enters the roundabout while the only circulating car is on the far side, its closest approach above the clearance. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k
      , Build.user 2 [.motorVehicle] (m (20 - 5 * (k : Int)), m 35) Build.west (Units.metresPerSecond 5) carBody ]
      [ roundabout ]
      [ ]

/-- `idle` (not_applicable): A car circulates inside the roundabout throughout the recording without entering it. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (5 + 5 * (k : Int)), m 5) Build.east (Units.metresPerSecond 5) carBody ]
      [ roundabout ]
      [ ]

/-- `blind` (unknown): A car near the roundabout's edge beside a circulating car, where the source does not observe which regions the cars occupy. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k, circulatingNear k ]
      [ roundabout ]
      [ ]

/-- `branch_1` (compliant): A car enters an empty roundabout: no other vehicle is in the scene, and the duty is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k ]
      [ roundabout ]
      [ ]

/-- `branch_2` (compliant): the road user on the conflicting course in the roundabout is a bicycle, not a vehicle of DEF-NRS-484A-320. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k
      , Build.user 2 [.bicycle] (m (38 - 5 * (k : Int)), m 7) Build.west (Units.metresPerSecond 5) bikeBody ]
      [ roundabout ]
      [ ]

/-- `branch_3` (compliant): a car on a conflicting course enters at the same instant from another approach; it was not already in the roundabout. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k
      , Build.user 2 [.motorVehicle] (m (58 - 10 * (k : Int)), m 10) Build.west (Units.metresPerSecond 10) carBody ]
      [ roundabout ]
      [ ]

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
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.LVMC_11_43_010_B_o1
