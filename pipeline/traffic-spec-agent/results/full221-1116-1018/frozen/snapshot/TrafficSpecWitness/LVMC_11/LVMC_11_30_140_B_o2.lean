/-
  Witnesses for LVMC_11_30_140_B_o2.

  Geometry: an open ground plane, no structures (the rule reads none). Track 1 is the subject,
  track 2 the other person. A car is 5 m × 2 m (half-extents 2.5 m, 1 m), a pedestrian
  0.6 m × 0.6 m (half-extents 0.3 m). Instants every 1 s from t = 0.

  - forbid: the car drives east on y = 0 toward a white-cane pedestrian standing at (40, 0): 40 m
    at 0 s, 28 m at 1 s (the approach), halts at x = 30 (2, 3 s... at rest at 3 s and 4 s), then
    moves off at 4 m/s from x = 32 at 5 s: closest approach 0 m in 2 s.
  - permit: the same approach (40.3 m, then 28.2 m at 1 s); the pedestrian crosses north at
    1.5 m/s from (40, −4.5); the car waits at x = 30 (3 … 6 s) and moves off at 7 s (x = 31,
    2 m/s) and 8 s (x = 33, 3 m/s), when the pedestrian is 6 m and 7.5 m north of its line: the
    predicted closest approach is about 10 m.
  - idle: the permit scene with an ordinary pedestrian.
  - blind: the car is at rest at x = 0 (0 s, 1 s) beside a white-cane pedestrian whose position
    the source does not report; the source measures the centre distance (4.5, 2.7, 2.7 m) and the
    contact (none at 0 s; the pedestrian touches the car at rest at 1 s, a recorded contact event
    the halt then follows). At 2 s the car moves off at 1 m/s. With the distance observed, no new
    approach event occurred, so the rule is engaged and the persisting contact is a violation;
    with rel.centre_distance masked, whether a new approach event occurred since the halt is
    unknown, and so is the verdict — for that atom alone, no truncated history. (The planned
    narrative has no contact; without a recorded contact no event can be decided under the mask,
    so the halt's history would be unknown for the trace start as well — see task_result.md.)
  - branch_1: the car creeps at 2 m/s from x = 30 toward a white-cane pedestrian standing at
    (35, 0), halts at x = 32.5 with its front 0.3 m into the pedestrian's body (contact begins
    while at rest), then moves off at 1 m/s with the pedestrian walking ahead at 1 m/s pressed
    against the bumper: contact, and no closing course (equal velocities).
  - branch_2: an ordinary pedestrian walks east at 1.5 m/s from (0, 0) toward a white-cane
    pedestrian walking west at 1.5 m/s from (31, 0): 31 m, then 28 m at 1 s; the subject halts at
    x = 12 (8 s, 9 s), then walks on at 10 s with 2.5 m between centres: closest approach 0 m.
  - branch_3: branch_2 with the subject itself a white-cane pedestrian (outside the subject class).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_140_B_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_140_B_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 250, cm 100, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

/-- The subject car on y = 0, heading east. -/
def car (x : Q) (speed : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, m 0) Build.east speed carExtent

/-- A pedestrian of the given classes. -/
def walker (track : TrackId) (classes : List RoadUserClass) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track classes pos heading speed pedExtent

def scn (t : Timestamp) (users : List RoadUser) : Scene :=
  Build.scene t (some 1) users [] []

/-- `forbid` (violated): A motor vehicle comes within the reach of a ru.pedestrian_with_white_cane_or_guide_animal crossing ahead, halts, then moves off toward the pedestrian: prim.closest_approach_within holds over p.conflict_horizon with prim.closest_approach_distance below p.conflict_centre_clearance. -/
def forbidCar : Nat → RoadUser
  | 0 => car (m 0) (Units.metresPerSecond 12)
  | 1 => car (m 12) (Units.metresPerSecond 10)
  | 2 => car (m 20) (Units.metresPerSecond 6)
  | 3 => car (m 30) (Units.metresPerSecond 0)
  | 4 => car (m 30) (Units.metresPerSecond 0)
  | _ => car (m 32) (Units.metresPerSecond 4)

def forbidTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    scn t
      [ forbidCar k
      , walker 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (m 40, m 0) Build.north (Units.metresPerSecond 0) ]

/-- The permit car: approaches, waits at rest from 3 s to 6 s, moves off at 7 s. -/
def permitCar : Nat → RoadUser
  | 0 => car (m 0) (Units.metresPerSecond 12)
  | 1 => car (m 12) (Units.metresPerSecond 10)
  | 2 => car (m 20) (Units.metresPerSecond 6)
  | 3 => car (m 30) (Units.metresPerSecond 0)
  | 4 => car (m 30) (Units.metresPerSecond 0)
  | 5 => car (m 30) (Units.metresPerSecond 0)
  | 6 => car (m 30) (Units.metresPerSecond 0)
  | 7 => car (m 31) (Units.metresPerSecond 2)
  | _ => car (m 33) (Units.metresPerSecond 3)

/-- A pedestrian crossing north at 1.5 m/s on x = 40 from y = −4.5 m. -/
def crosser (classes : List RoadUserClass) (k : Nat) : RoadUser :=
  walker 2 classes (m 40, cm (-450 + 150 * (k : Int))) Build.north (cm 150)

def permitLike (classes : List RoadUserClass) : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    scn t [ permitCar k, crosser classes k ]

/-- `permit` (compliant): The vehicle halts, waits until the pedestrian has left its path, then moves off; the centres do not approach below the clearance within the horizon and no rel.contact occurs. -/
def permitTrace : Trace := permitLike [.pedestrianWithWhiteCaneOrGuideAnimal]

/-- `idle` (not_applicable): A vehicle halts and moves off near an ordinary pedestrian; no ru.pedestrian_with_white_cane_or_guide_animal is in the scene. -/
def idleTrace : Trace := permitLike [.pedestrian]

/-- `blind` (unknown): A vehicle halts and moves off near a ru.pedestrian_with_white_cane_or_guide_animal; rel.centre_distance is not observed and no contact occurs, so whether an approach event occurred is unknown. -/
def blindCar : Nat → RoadUser
  | 0 => car (m 0) (Units.metresPerSecond 0)
  | 1 => car (m 0) (Units.metresPerSecond 0)
  | _ => car (m 1) (Units.metresPerSecond 1)

/-- The source's measured centre distance car → pedestrian (the pedestrian's position is not
    observed, so Core cannot compute it): 4.5, 2.7, 2.7 m. -/
def blindDistance : Nat → Q
  | 0 => cm 450
  | _ => cm 270

/-- The source's measured contact car → pedestrian: none at 0 s, from 1 s on. -/
def blindContact : Nat → Bool
  | 0 => false
  | _ => true

def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      { scn t
          [ blindCar k
          , Build.withKin (walker 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (m 45, m 0) Build.north (Units.metresPerSecond 0))
              (fun kin => { kin with position := none }) ]
        with occupancyObserved := [1] }   -- the unplaced pedestrian's occupancy is not observed
      [ Build.relation 1 2 (fun r => { r with centreDistance := some (blindDistance k), contact := some (blindContact k) }) ]

/-- `branch_1` (violated): After halting, the vehicle moves off and its body touches the white-cane pedestrian (rel.contact). -/
def branch_1Car : Nat → RoadUser
  | 0 => car (m 30) (Units.metresPerSecond 2)
  | 1 => car (cm 3250) (Units.metresPerSecond 0)
  | 2 => car (cm 3250) (Units.metresPerSecond 0)
  | _ => car (cm 3350) (Units.metresPerSecond 1)

def branch_1Walker : Nat → RoadUser
  | 0 => walker 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (m 35, m 0) Build.east (Units.metresPerSecond 0)
  | 1 => walker 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (m 35, m 0) Build.east (Units.metresPerSecond 0)
  | 2 => walker 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (m 35, m 0) Build.east (Units.metresPerSecond 0)
  | _ => walker 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (m 36, m 0) Build.east (Units.metresPerSecond 1)

def branch_1Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    scn t [ branch_1Car k, branch_1Walker k ]

/-- The pedestrian subject of branch_2/branch_3: walks east at 1.5 m/s, at rest at x = 12 at 8 s
    and 9 s, walks on from 10 s. -/
def footSubject (classes : List RoadUserClass) (k : Nat) : RoadUser :=
  if k ≤ 7 then walker 1 classes (cm (150 * (k : Int)), m 0) Build.east (cm 150)
  else if k ≤ 9 then walker 1 classes (m 12, m 0) Build.east (Units.metresPerSecond 0)
  else walker 1 classes (cm (1200 + 150 * ((k : Int) - 9)), m 0) Build.east (cm 150)

/-- The white-cane pedestrian of branch_2/branch_3: walks west at 1.5 m/s from x = 31. -/
def caneWalker (k : Nat) : RoadUser :=
  walker 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (cm (3100 - 150 * (k : Int)), m 0) Build.west (cm 150)

def footTrace (classes : List RoadUserClass) : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    scn t [ footSubject classes k, caneWalker k ]

-- branch_2 (violated): an ordinary pedestrian approaches a white-cane pedestrian, stops, then walks on toward them on a closing course.
def branch_2Trace : Trace := footTrace [.pedestrian]

-- branch_3 (not_applicable): the same, the subject itself a white-cane pedestrian, whom the words leave out of the subject class.
def branch_3Trace : Trace := footTrace [.pedestrianWithWhiteCaneOrGuideAnimal]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "LVMC_11_30_140_B_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (1000, 5000))
  , witness "permit" permitTrace .compliant (window := some (1000, 8000))
  , witness "idle" idleTrace .notApplicable (window := some (1000, 8000))
  , witness "blind" blindTrace (.unknown []) ["rel.centre_distance"]
  , witness "branch_1" branch_1Trace .violated (window := some (1000, 3000))
  , witness "branch_2" branch_2Trace .violated (window := some (1000, 10000))
  , witness "branch_3" branch_3Trace .notApplicable (window := some (1000, 10000)) ]

end TrafficSpecWitness.LVMC_11_30_140_B_o2
