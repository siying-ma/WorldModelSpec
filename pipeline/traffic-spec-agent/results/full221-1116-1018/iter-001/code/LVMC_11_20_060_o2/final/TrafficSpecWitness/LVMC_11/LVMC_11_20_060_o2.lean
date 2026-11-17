/-
  Witnesses for LVMC_11_20_060_o2.

  Geometry (x east, y north, metres): a roadway y ∈ [-10, 0]; a sidewalk y ∈ [0, 4] along it; a
  driveway (driveway_or_alley_entrance) x ∈ [-3, 3], y ∈ [0, 20] meeting the roadway across the
  sidewalk, so the sidewalk area across the driveway lies in both regions.
  The subject (track 1) is a motor vehicle, half-extent 2.0 m × 0.9 m, heading south out of the
  driveway. The pedestrian (track 2), half-extent 0.3 m × 0.3 m, walks west along the sidewalk at
  1.5 m/s toward the driveway.

  forbid: subject at (0, 3.5) then (0, 2.5), 1 m/s south; pedestrian at (4, 0.5) then (2.5, 0.5).
    Closest approach of centres at ≈ 2.8 s then ≈ 1.8 s (within 3 s), ≈ 0.3 m apart (below 3 m);
    the subject moves at 1 m/s (above 0.1 m/s). The bodies never touch at a sampled instant.
  permit: subject halted (0 m/s) at (0, 3.6), its front 1.6 m north of the roadway edge; the
    pedestrian walks along y = 0.9 from x = 4 to x = -2 across five instants: closest approach
    2.7 m within 2.7 s while it approaches, then it moves away; bodies never touch.
  idle: subject on the roadway at y = -5, heading east at 10 m/s; it occupies no driveway, alley
    or sidewalk.
  blind: the forbid trace with kin.speed unobserved.
  branch_1: the forbid trace with no pedestrian.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_20_060_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_20_060_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def district : List (AsmId × Bool) := [("asm.business_or_residence_district", true)]

def structures : List Structure :=
  [ Build.rect 10 .roadway (m (-50)) (m (-10)) (m 50) (m 0)
  , Build.rect 11 .sidewalk (m (-50)) (m 0) (m 50) (m 4)
  , Build.rect 12 .drivewayOrAlleyEntrance (m (-3)) (m 0) (m 3) (m 20) ]

def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

/-- The subject crossing the sidewalk southward at 1 m/s. -/
def movingCar (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, cm (350 - 100 * (k : Int))) Build.south (Units.metresPerSecond 1) carExtent

/-- A pedestrian walking west along the sidewalk at 1.5 m/s on line y. -/
def walker (k : Nat) (y : Q) : RoadUser :=
  Build.user 2 [.pedestrian] (cm (400 - 150 * (k : Int)), y) Build.west (cm 150) pedExtent

/-- `forbid` (violated): District assumed; the subject crosses the sidewalk out of a driveway while a pedestrian walks toward its path; the closest approach falls below the clearance within the horizon and the subject keeps moving. -/
def forbidTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ movingCar k, walker k (cm 50) ]
      structures
      [ ]
      (assumptions := district)

/-- `permit` (compliant): Same, but the subject waits halted at the sidewalk edge until the pedestrian has passed. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, cm 360) Build.south Q.zero carExtent
      , walker k (cm 90) ]
      structures
      [ ]
      (assumptions := district)

/-- `idle` (not_applicable): The subject travels on the roadway, nowhere near a driveway or sidewalk. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (-20 + 10 * (k : Int)), m (-5)) Build.east (Units.metresPerSecond 10) carExtent ]
      structures
      [ ]
      (assumptions := district)

/-- `blind` (unknown): District assumed; the subject crosses the sidewalk with a pedestrian approaching, but the subject's speed is not observed. -/
def blindTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ movingCar k, walker k (cm 50) ]
      structures
      [ ]
      (assumptions := district)

/-- `branch_1` (compliant): District assumed; the subject crosses the sidewalk out of a driveway with no other road user in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ movingCar k ]
      structures
      [ ]
      (assumptions := district)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_20_060_o2"
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
  , witness "branch_1" branch_1Trace .compliant ]

end TrafficSpecWitness.LVMC_11_20_060_o2
