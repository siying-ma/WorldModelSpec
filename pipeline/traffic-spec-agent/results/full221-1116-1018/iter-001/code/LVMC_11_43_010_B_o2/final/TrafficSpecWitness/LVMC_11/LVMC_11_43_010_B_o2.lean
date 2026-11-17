/-
  Witnesses for LVMC_11_43_010_B_o2.

  Geometry (the witness's own figures, none of them in the rule): +x east, +y north. The roundabout
  region `rb` is the rectangle x ∈ [0, 40], y ∈ [-20, 20]; the approach roadway `appr` is
  x ∈ [-30, 0], y ∈ [-4, 4]; a crosswalk `cw` lies inside the roundabout at x ∈ [6, 10],
  y ∈ [-10, 10]. The subject (track 1, a motor vehicle, half-extent 2 m × 0.9 m) drives east
  along y = 0. Instants are 1 s apart.

  forbid: the subject is at x = -4, -1, 2 at 3 m/s (enters at t = 2 s). A pedestrian (track 2) on
    the crosswalk walks north at 1 m/s from (8, -6) to (8, -4). At t = 2 s the relative position
    is (6, -4), relative velocity (-3, 1): closest approach at 2.2 s (< 4.5 s) at a centre
    distance of about 1.9 m (< 3 m): no gap — violated.
  permit: the subject waits at (-2, 0) for t = 0..2 s, then at t = 3 s is at (2, 0) at 4 m/s. A
    circulating car (track 3) drives north at 5 m/s along x = 10, at (10, 6) at t = 3 s: relative
    position (8, 6), relative velocity (-4, 5): closest approach at about 0.05 s at about 10 m
    (> 3 m): a gap — compliant.
  idle: a straight roadway, no roundabout anywhere; the subject drives east on it.
  blind: as permit's entry with the circulating car, but `rel.occupies` is not observed.
  branch_1: the subject enters the roundabout as in forbid, alone in the scene.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_B_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_B_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

def roundabout : Structure := Build.rect "rb" .roundabout (m 0) (m (-20)) (m 40) (m 20)
def approach : Structure := Build.rect "appr" .roadway (m (-30)) (m (-4)) (m 0) (m 4)
def crosswalk : Structure := Build.rect "cw" .crosswalk (m 6) (m (-10)) (m 10) (m 10)

/-- The subject entering at 3 m/s: x = -4, -1, 2 at k = 0, 1, 2. -/
def entering (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (-4 + 3 * (k : Int)), m 0) Build.east (Units.metresPerSecond 3) carExtent

/-- The subject waiting at the edge for k < 3, entering at 4 m/s at k = 3. -/
def waiting (k : Nat) : RoadUser :=
  if k < 3 then
    Build.user 1 [.motorVehicle] (m (-2), m 0) Build.east (Units.metresPerSecond 0) carExtent
  else
    Build.user 1 [.motorVehicle] (m 2, m 0) Build.east (Units.metresPerSecond 4) carExtent

/-- A circulating car driving north at 5 m/s along x = 10, at (10, 6) at k = 3. -/
def circulating (k : Nat) : RoadUser :=
  Build.user 3 [.motorVehicle] (m 10, m (-9 + 5 * (k : Int))) Build.north (Units.metresPerSecond 5) carExtent

/-- `forbid` (violated): A car enters the roundabout while a pedestrian on one of its crosswalks is on a course whose closest approach to the car comes within the clearance sooner than the critical gap. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k
      , Build.user 2 [.pedestrian] (m 8, m (-6 + (k : Int))) Build.north (Units.metresPerSecond 1) pedExtent ]
      [ roundabout, approach, crosswalk ]
      [ ]

/-- `permit` (compliant): A car waits at the edge and enters once no road user in the roundabout comes within the clearance of it within the critical gap. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ waiting k, circulating k ]
      [ roundabout, approach, crosswalk ]
      [ ]

/-- `idle` (not_applicable): A car drives on a street away from any roundabout. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (-20 + 10 * (k : Int)), m 0) Build.east (Units.metresPerSecond 10) carExtent ]
      [ Build.rect "street" .roadway (m (-50)) (m (-4)) (m 50) (m 4) ]
      [ ]

/-- `blind` (unknown): A car at the roundabout's edge beside circulating traffic, where the source does not observe which regions the road users occupy. -/
def blindTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ waiting k, circulating k ]
      [ roundabout, approach, crosswalk ]
      [ ]

/-- `branch_1` (compliant): A car enters an empty roundabout: no other road user is in the scene, and the duty is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k ]
      [ roundabout, approach, crosswalk ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_43_010_B_o2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant ]

end TrafficSpecWitness.LVMC_11_43_010_B_o2
