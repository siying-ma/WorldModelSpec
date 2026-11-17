/-
  Witnesses for NRS_484B_280_1a.

  The street: a roadway (region 10) from x = −50 m to x = 100 m, y = −3.5 m to 3.5 m, with a
  sidewalk (region 11) along its north side, y = 3.5 m to 6.5 m. Traffic runs east. Scenes are 1 s
  apart from t = 0.

  Bodies: a car (track 1, the subject unless stated) has half-extents 2.2 × 0.9 × 0.75 m; a
  pedestrian (track 2) 0.3 × 0.3 × 0.9 m; a bicycle 0.9 × 0.3 × 0.9 m.

  Against the reading (halt tolerance 0.1 m/s, horizon 3 s, centre clearance 3 m):
  - forbid: the car keeps 10 m/s east from x = 0; a pedestrian crosses north at x = 20 m from
    y = −3 m at 1 m/s. At t = 0 the closest approach is at about 2.0 s with the centres about 1.0 m
    apart (inside 3 s, under 3 m); at t = 2 the bodies touch.
  - permit: the car slows from 4 m/s and halts at x = 10 m (front at 12.2 m) while a pedestrian
    crosses north at x = 19.2 m from y = −6 m at 1.2 m/s. At every moving instant the car's
    constant-velocity position within 3 s stays at or behind x = 12.5 m, at least 6.7 m from the
    pedestrian's line, and at t = 0 the closest approach lies beyond the horizon (≈ 4.8 s); no
    contact.
  - idle: a bicycle (subject) at 5 m/s passes a pedestrian standing 2 m to its side.
  - blind: the car at 10 m/s passes a pedestrian standing on the sidewalk 5 m to its north: the
    closest approach is inside the horizon at 5 m centre distance (above 3 m); contact is masked,
    and the source gives no body extent for the pedestrian, so contact cannot be computed from
    footprints either (Core computes rel.contact from footprints where it can; the closest-approach
    primitives read position and velocity only, and stay decided).
  - branch_1: the car alone at 10 m/s.
  - branch_2: the car creeps east at 1 m/s with a pedestrian walking beside it at the same
    velocity, 1.1 m to its south: the bodies overlap (contact) while the centres never approach.
  - branch_3: the car at 10 m/s closes on a stopped car (track 2) 25 m ahead in its lane:
    closest approach at 2.5 s, 0 m apart — but the other is no pedestrian.
  - branch_4: as blind, with contact observed: no contact, closest approach 5 m.
  - branch_5: the car stands still (speed 0) while a pedestrian walks east past its north side,
    1.6 m from its centre, at 1.2 m/s: a closest approach inside 3 s at 1.6 m, no contact; the
    car does not move, so no duty is engaged at those instants.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_280_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_280_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 220, cm 90, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 90)

def street : List Structure :=
  [ Build.rect 10 .roadway (m (-50)) (cm (-350)) (m 100) (cm 350)
  , Build.rect 11 .sidewalk (m (-50)) (cm 350) (m 100) (cm 650) ]

def car (x y : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) Build.east speed carExtent

def ped (track : TrackId) (x y : Q) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.pedestrian] (x, y) heading speed pedExtent

/-- `forbid` (violated): A moving car approaches a pedestrian crossing the roadway ahead and does not slow; their closest approach falls within p.conflict_horizon and below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (10 * (k : Int))) Q.zero (Units.metresPerSecond 10)
      , ped 2 (m 20) (m (-3 + (k : Int))) Build.north (Units.metresPerSecond 1) ]
      street
      [ ]

/-- The permit car's (x, speed) per scene, in centimetres and cm/s. -/
def permitCar : List (Int × Int) :=
  [(0, 400), (350, 300), (650, 200), (850, 120), (960, 40), (1000, 0), (1000, 0)]

/-- `permit` (compliant): The car slows and halts short of the crossing pedestrian, keeping its closest approach beyond p.conflict_centre_clearance while it moves; no contact. -/
def permitTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    let (x, v) := permitCar.getD k (1000, 0)
    Build.scene t (some 1)
      [ car (cm x) Q.zero (cm v)
      , ped 2 (cm 1920) (cm (-600 + 120 * (k : Int))) Build.north (cm 120) ]
      street
      [ ]

/-- `idle` (not_applicable): The subject is a bicycle (not a member of the motor vehicle aggregate) passing a pedestrian. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (5 * (k : Int)), m 2) Build.east (Units.metresPerSecond 5) bikeExtent
      , ped 2 (m 8) (m 4) Build.north Q.zero ]
      street
      [ ]

/-- `blind` (unknown): A moving car passes a pedestrian on the sidewalk with no conflicting closest approach; contact between bodies is not observed on this source. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s := Build.scene t (some 1)
      [ car (m (10 * (k : Int))) Q.zero (Units.metresPerSecond 10)
      , Build.withKin (ped 2 (m 20) (m 5) Build.north Q.zero) fun kn => { kn with extent := none } ]
      street
      [ ]
    -- the pedestrian has no footprint on this source, so its occupancy is not observed either
    { s with occupancyObserved := [1], occupies := [(1, 10)] }

/-- `branch_1` (compliant): A moving car drives on a street with no pedestrian in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (10 * (k : Int))) Q.zero (Units.metresPerSecond 10) ]
      street
      [ ]

/-- `branch_2` (violated): the car creeps along brushing a pedestrian walking beside it at the
    same velocity — contact, with no closest approach of the centres. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (k : Int)) Q.zero (Units.metresPerSecond 1)
      , ped 2 (m (k : Int)) (cm (-110)) Build.east (Units.metresPerSecond 1) ]
      street
      [ ]

/-- `branch_3` (compliant): the car closes fast on a stopped car ahead; no pedestrian is near. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (10 * (k : Int))) Q.zero (Units.metresPerSecond 10)
      , Build.user 2 [.motorVehicle] (m 25, Q.zero) Build.east Q.zero carExtent ]
      street
      [ ]

/-- `branch_4` (compliant): the car passes a pedestrian standing on the sidewalk 5 m aside;
    contact observed, none. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (10 * (k : Int))) Q.zero (Units.metresPerSecond 10)
      , ped 2 (m 20) (m 5) Build.north Q.zero ]
      street
      [ ]

/-- `branch_5` (compliant): the car stands still while a pedestrian walks close past it. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car Q.zero Q.zero Q.zero
      , ped 2 (cm (-300 + 120 * (k : Int))) (cm 160) Build.east (cm 120) ]
      street
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_280_1a"
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
  , witness "blind" blindTrace (.unknown []) ["rel.contact"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_280_1a
