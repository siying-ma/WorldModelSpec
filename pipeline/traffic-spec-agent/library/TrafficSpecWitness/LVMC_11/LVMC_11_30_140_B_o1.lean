/-
  Witnesses for LVMC_11_30_140_B_o1.

  Geometry (every figure here is the witness's own and appears nowhere in the rule). Ten scenes,
  one per second (t = 0 … 9 s). The subject is track 1, the other road user track 2.

  * Vehicle scenes (forbid, permit, idle, blind): a car (half-extents 2.3 × 0.9 × 0.75 m) drives
    east along y = 0 from x = −55 m at 10 m/s; a pedestrian (0.3 × 0.3 × 0.9 m) stands at the kerb
    at (0, 8). Centre distances at t = 0…3 s: 55.6, 45.7, 35.9, 26.2 m — with a 30 m reach the
    approach is first at t = 3 s, clear of the bound on both sides. No contact (8 m laterally).
    - forbid: the car keeps 10 m/s throughout; the 4 s window after t = 3 s has no halt.
    - permit: the car brakes after t = 3 s (x = −17, −13, −12; 6, 2, 0 m/s) and is at rest from
      t = 6 s, 3 s after the approach.
    - idle: the pedestrian is an ordinary pedestrian (no cane, not led).
    - blind: as forbid, with rel.centre_distance masked; the pedestrian's position is not
      observed either (Core would otherwise compute the centre distance from the two positions),
      and the source reports that the bodies are not in contact (contact := false), which Core
      cannot compute without that position.
  * branch_1: the subject is itself a white-cane pedestrian walking east at 1 m/s from (−5, 0)
    towards another white-cane pedestrian at (0, 0).
  * branch_2: an ordinary pedestrian walks east at 1 m/s from (−3, 0) into a white-cane pedestrian
    standing at (0, 0): bodies first overlap at t = 3 s and it keeps walking. The centre distance is
    below the reach from the first scene, so only the contact begins inside the judged window.
  * branch_3 (not_applicable): the car stands at rest at (0, 0); a white-cane pedestrian walks
    towards it at 3 m/s from (−37, 8): 37.9, 35.0, 32.0, 29.1 m — the distance falls to the reach
    at t = 3 s while the car is at rest, so it has not approached.

  Every scenario judges t = 1 … 9 s (`window`): the first scene has no previous observation for
  the rule's `rises`.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_140_B_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_140_B_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

/-- The car moving east at constant 10 m/s from x = −55 m. -/
def cruisingCar (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (-55 + 10 * (k : Int)), m 0) Build.east (mps 10) carExtent

/-- A pedestrian standing at the kerb, of the given classes. -/
def kerbPedestrian (classes : List RoadUserClass) : RoadUser :=
  Build.user 2 classes (m 0, m 8) Build.east (mps 0) pedExtent

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): A motor vehicle (ru.motor_vehicle) moving at 10 m/s comes within p.blind_person_approach_reach (rel.centre_distance) of a ru.pedestrian_with_white_cane_or_guide_animal at the kerb and keeps moving: no observation of the window p.immediate_stop_window ahead has kin.speed at or below p.halt_speed_tolerance. -/
def forbidTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ cruisingCar k, kerbPedestrian [.pedestrianWithWhiteCaneOrGuideAnimal] ]
      [ ]
      [ ]

def permitX : List Int := [-55, -45, -35, -25, -17, -13, -12, -12, -12, -12]
def permitV : List Int := [10, 10, 10, 10, 6, 2, 0, 0, 0, 0]

/-- `permit` (compliant): The same vehicle decelerates and is at rest (drv.motion.complete_halt) within p.immediate_stop_window after the centre distance first falls to the reach. -/
def permitTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (permitX.getD k (-12)), m 0) Build.east
          (mps (permitV.getD k 0)) carExtent
      , kerbPedestrian [.pedestrianWithWhiteCaneOrGuideAnimal] ]
      [ ]
      [ ]

/-- `idle` (not_applicable): A vehicle drives past an ordinary pedestrian (ru.pedestrian, no cane, not led); no road user of class ru.pedestrian_with_white_cane_or_guide_animal is in the scene. -/
def idleTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ cruisingCar k, kerbPedestrian [.pedestrian] ]
      [ ]
      [ ]

/-- `blind` (unknown): A ru.pedestrian_with_white_cane_or_guide_animal stands near the vehicle's path; rel.centre_distance is not observed and no contact occurs, so whether the vehicle approached is unknown; the vehicle does not halt. -/
def blindTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      { Build.scene t (some 1)
          [ cruisingCar k
          , { track := 2, classes := some [.pedestrianWithWhiteCaneOrGuideAnimal] } ]
          [ ]
          [ ]
        with occupancyObserved := [1] }
      [ Build.relation 1 2 fun r => { r with contact := some false } ]

/-- `branch_1` (not_applicable): The subject is itself a ru.pedestrian_with_white_cane_or_guide_animal walking toward another such pedestrian. -/
def branch_1Trace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrianWithWhiteCaneOrGuideAnimal] (m (-5 + (k : Int)), m 0) Build.east
          (mps 1) pedExtent
      , Build.user 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (m 0, m 0) Build.east (mps 0) pedExtent ]
      [ ]
      [ ]

/-- `branch_2` (violated): A pedestrian (ru.pedestrian, no cane) walking comes into rel.contact with a ru.pedestrian_with_white_cane_or_guide_animal and keeps walking, never at rest within p.immediate_stop_window. -/
def branch_2Trace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (m (-3 + (k : Int)), m 0) Build.east (mps 1) pedExtent
      , Build.user 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (m 0, m 0) Build.east (mps 0) pedExtent ]
      [ ]
      [ ]

/-- `branch_3` (not_applicable): the vehicle is at rest when a white-cane pedestrian walks to
    within the reach of it — the distance falls, but the vehicle has not approached. -/
def branch_3Trace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (mps 0) carExtent
      , Build.user 2 [.pedestrianWithWhiteCaneOrGuideAnimal] (m (-37 + 3 * (k : Int)), m 8)
          Build.east (mps 3) pedExtent ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_30_140_B_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (1000, 9000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.centre_distance"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_30_140_B_o1
