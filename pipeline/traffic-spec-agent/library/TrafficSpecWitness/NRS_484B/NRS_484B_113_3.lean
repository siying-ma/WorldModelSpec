/-
  Witnesses for NRS_484B_113_3.

  Geometry (the witness's own figures; none appears in the rule). A highway region 100 covers
  x ∈ [-50, 50], y ∈ [-20, 20] m; a sidewalk region 101 lies within it at y ∈ [5, 8] m. The
  subject (track 1) is a passenger car, half-extents 2.25 × 1.0 × 0.75 m, pointing east; when it
  backs, its velocity points west while its heading stays east. Pedestrians have half-extents
  0.3 × 0.3 × 0.9 m. Instants are 1 s apart from t = 0.

  Against the reading (p.conflict_horizon 3 s, p.conflict_centre_clearance 3 m,
  p.halt_speed_tolerance 0.1 m/s):
  - forbid: car backs at 2 m/s from (10, 0); a pedestrian walks north at 1.5 m/s from (8.3, -1.9):
    at t = 0 the centres' closest approach is 1 s ahead at 0.5 m (danger); at t = 1, 2 the bodies touch.
  - permit: the car backs alone; nothing to yield to.
  - idle: the car drives forward at 10 m/s; a pedestrian walks on the sidewalk 6.5 m to its left.
  - blind: forbid with the car's velocity absent.
  - branch_1: the car backs at 1 m/s toward a parked car at rest whose body is 6 m behind
    (centres 10.5 m apart): at rest, so not moving traffic, and no pedestrian.
  - branch_2: the car backs at 2 m/s toward a pedestrian standing still about 2 m behind its rear
    bumper, 0.5 m off its centre line: closest approach 2.25 s ahead at 0.5 m; at t = 1 the bodies touch.
  - branch_3 (added; rel_contact): the car backs at 1 m/s with its rear touching a pedestrian who
    walks away west at 2 m/s: the centres separate (no closest approach ahead), the bodies touch.
  - branch_4 (added; moving traffic): the car backs at 2 m/s while a car drives north at 4 m/s
    across the road behind it, from (4, -8): closest approach 2.2 s ahead at about 1.79 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_113_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_113_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExt : Q × Q × Q := (cm 225, cm 100, cm 75)
def pedExt : Q × Q × Q := (cm 30, cm 30, cm 90)

def highway : Structure := Build.rect 100 .highway (m (-50)) (m (-20)) (m 50) (m 20)
def sidewalk : Structure := Build.rect 101 .sidewalk (m (-50)) (m 5) (m 50) (m 8)

/-- The subject car pointing east and moving west (backing) at `speed`. -/
def backingCar (pos : Vec) (speed : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos Build.east speed carExt)
    (fun k => { k with velocity := some (Build.scale Build.west speed) })

/-- The pedestrian of forbid and blind: walking north at 1.5 m/s behind the backing car. -/
def walkingPed (k : Nat) : RoadUser :=
  Build.user 2 [.pedestrian] (cm 830, cm (-190 + 150 * (k : Int))) Build.north (cm 150) pedExt

/-- `forbid` (violated): A car backs out of a driveway at 2 m/s while a pedestrian walks behind it; their centres are on a closest approach 1 s ahead at 0.5 m. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backingCar (m (10 - 2 * (k : Int)), Q.zero) (Units.metresPerSecond 2)
      , walkingPed k ]
      [ highway ]
      [ ]

/-- `permit` (compliant): A car backs along an empty street at 2 m/s; no other road user is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backingCar (m (10 - 2 * (k : Int)), Q.zero) (Units.metresPerSecond 2) ]
      [ highway ]
      [ ]

/-- `idle` (not_applicable): A car drives forward past a pedestrian on the sidewalk; it never backs. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (10 * (k : Int)), Q.zero) Build.east (Units.metresPerSecond 10) carExt
      , Build.user 2 [.pedestrian] (cm (2000 - 120 * (k : Int)), cm 650) Build.west (cm 120) pedExt ]
      [ highway, sidewalk ]
      [ ]

/-- `blind` (unknown): As in forbid, but the source supplies no velocity for the car, so whether it is backing is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (backingCar (m (10 - 2 * (k : Int)), Q.zero) (Units.metresPerSecond 2))
          (fun kn => { kn with velocity := none })
      , walkingPed k ]
      [ highway ]
      [ ]

/-- `branch_1` (compliant): A car backs toward a parked car at rest 6 m behind it, closing at 1 m/s; the parked car is not moving traffic and not a pedestrian. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backingCar (m (10 - (k : Int)), Q.zero) (Units.metresPerSecond 1)
      , Build.user 2 [.motorVehicle] (cm (-50), Q.zero) Build.east Q.zero carExt ]
      [ highway ]
      [ ]

/-- `branch_2` (violated): A car backs at 2 m/s toward a pedestrian standing still 2 m behind it: the closest approach is 1 s ahead at under 1 m. -/
def branch_2Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backingCar (m (10 - 2 * (k : Int)), Q.zero) (Units.metresPerSecond 2)
      , Build.user 2 [.pedestrian] (cm 550, cm 50) Build.north Q.zero pedExt ]
      [ highway ]
      [ ]

/-- `branch_3` (violated): the backing car's rear touches a pedestrian who hurries away from it;
    no danger ahead, but contact. -/
def branch_3Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ backingCar (m 10, Q.zero) (Units.metresPerSecond 1)
      , Build.user 2 [.pedestrian] (cm 760, Q.zero) Build.west (Units.metresPerSecond 2) pedExt ]
      [ highway ]
      [ ]

/-- `branch_4` (violated): the car backs while another car, moving traffic on the highway, drives
    across behind it into a closest approach within the horizon. -/
def branch_4Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ backingCar (m 10, Q.zero) (Units.metresPerSecond 2)
      , Build.user 2 [.motorVehicle] (m 4, m (-8)) Build.north (Units.metresPerSecond 4) carExt ]
      [ highway ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_113_3"
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.NRS_484B_113_3
