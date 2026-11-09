/-
  Witnesses for NRS_484B_253_o1.

  The geometry, once, for every scene below (metres, +x east, +y north; figures in centimetres
  through `cm`). Two 7 m roads cross:

    * region 10, the junction: the square from (−3.5, −3.5) to (3.5, 3.5), kind `intersection`;
    * region 11, the south approach: the lane x ∈ [0, 3.5], y ∈ [−40, −3.5], designated direction
      north, entrance end region 10 — the carrier the subject car reaches the junction by;
    * region 12, the north approach: the lane x ∈ [−3.5, 0], y ∈ [3.5, 200], designated direction
      south, entrance end region 10 — the opposing carrier. Its direction is the exact opposite of
      region 11's, so their normalised dot product is −1, well below −0.866.

  Two bodies: the subject car, track 1 (half-extents 2.5 × 0.9 × 0.8 m), and a van, track 2
  (3.0 × 1.0 × 1.2 m). The car stands at (0.8, −2.8) heading west, mid-left-turn: its body covers
  x ∈ [−1.7, 3.3], y ∈ [−3.7, −1.9], so it straddles the junction's south edge and overlaps both
  region 10 and region 11. The van runs south at x = −1.75 and is placed at the y the scene needs;
  where its body crosses y = 3.5 it overlaps both region 12 and region 10. Occupancy is stated,
  since each body lies across two regions and a reference point lies in one.

  Every trace is three instants one second apart at the same geometry: the rule looks nowhere into
  the past, so no witness names a window. Nothing a formula can compute from the scene is supplied:
  the surface gap, the contact and the closest approach are all Core's, from the positions,
  headings, extents and velocities below.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

/-- The junction, with its outline. -/
def junction : Structure := Build.rect 10 .intersection (cm (-350)) (cm (-350)) (cm 350) (cm 350)
/-- The subject's approach: northbound, entering the junction. -/
def southApproach : Structure :=
  Build.lane 11 [(cm 0, cm (-4000)), (cm 350, cm (-4000)), (cm 350, cm (-350)), (cm 0, cm (-350))]
    Build.north (enters := some 10)
/-- The opposing approach: southbound, entering the same junction. -/
def northApproach : Structure :=
  Build.lane 12 [(cm (-350), cm 350), (cm 0, cm 350), (cm 0, cm 20000), (cm (-350), cm 20000)]
    Build.south (enters := some 10)

def crossing : List Structure := [junction, southApproach, northApproach]

def carHalf : Q × Q × Q := (cm 250, cm 90, cm 80)
def vanHalf : Q × Q × Q := (cm 300, cm 100, cm 120)

/-- The subject car within the junction, heading west through its left turn. -/
def turningCar (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm 80, cm (-280)) Build.west speed carHalf
/-- The subject car within the junction, still heading north up its approach. -/
def straightCar : RoadUser :=
  Build.user 1 [.motorVehicle] (cm 175, cm (-280)) Build.north (m 2) carHalf
/-- The van on the opposing approach, southbound, at the given y. -/
def oncomingVan (y speed : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm (-175), y) Build.south speed vanHalf

/-- The same van as a source reports it with its body and place but no motion at all: neither its
    speed nor its velocity is observed. -/
def motionlessVan : RoadUser :=
  Build.withKin (oncomingVan (cm 80) (m 0)) fun k => { k with speed := none, velocity := none }

/-- The source's current plan for the car: a left turn at the junction. -/
def leftTurn : List DeclaredIntent := [{ vehicle := 1, target := 10, values := [("int.left_turn", true)] }]
/-- The source's current plan for the car: not a left turn at the junction. -/
def straightOn : List DeclaredIntent := [{ vehicle := 1, target := 10, values := [("int.left_turn", false)] }]

def sceneOf (t : Timestamp) (users : List RoadUser) (structures : List Structure)
    (occupies : List (TrackId × RegionId)) (intents : List DeclaredIntent) : Scene :=
  Build.scene t (some 1) users structures [] (occupies := some occupies) (intents := intents)

/-- `forbid` (violated): A car stands within a junction with the source declaring its plan to be a left turn there. A van occupies the opposing approach lane, which enters the same junction with the opposite designated direction, and is already within the junction. The car turns across its path and the two bodies touch. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [turningCar (m 4), oncomingVan (cm 80) (m 8)] crossing
      [(1, 10), (1, 11), (2, 10), (2, 12)] leftTurn

/-- `permit` (compliant): The same junction and the same declared left turn, and no other road user anywhere in the scene: nothing is owed precedence, the duty is discharged, and the verdict is decided with the subject alone. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [turningCar (m 4)] crossing [(1, 10), (1, 11)] leftTurn

/-- `idle` (not_applicable): A car stands within the junction and the source's current plan for it is to go straight through: no left turn is declared at that junction, so the rule is not engaged even though an opposing van is within the junction. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [straightCar, oncomingVan (cm 80) (m 8)] crossing
      [(1, 10), (1, 11), (2, 10), (2, 12)] straightOn

/-- `blind` (unknown): A car within the junction is declared to intend a left turn and a van is on the opposing approach, but the source does not report the designated direction of the van's carrier, so whether it approaches from the opposite direction is unknown and the rule reports unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [turningCar (m 4), oncomingVan (cm 80) (m 8)] crossing
      [(1, 10), (1, 11), (2, 10), (2, 12)] leftTurn

/-- `branch_1` (violated): The oncoming van is not yet within the junction but is fifteen metres from it at 12 m/s, so its distance is under its speed times the headway bound: it is so close as to constitute an immediate hazard. The car turns left in front of it and their closest approach under constant velocities within the horizon falls to half a metre. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [turningCar (m 1), oncomingVan (cm 2150) (m 12)] crossing
      [(1, 10), (1, 11), (2, 12)] leftTurn

/-- `branch_2` (compliant): The oncoming van is a hundred and fifty metres from the junction at 10 m/s, neither within it nor within the headway bound, and no closest approach within the horizon comes near the clearance: the car completes its left turn with nothing owed precedence. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [turningCar (m 4), oncomingVan (cm 15650) (m 10)] crossing
      [(1, 10), (1, 11), (2, 12)] leftTurn

/-- `branch_3` (violated): the source reports the van's body and the lane it stands in but neither
    its speed nor its velocity, so neither how close it is in time to the junction nor any closest
    approach can be read; it is within the junction all the same, which is the words' own first
    limb, and the turning car's body touches it. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [turningCar (m 4), motionlessVan] crossing
      [(1, 10), (1, 11), (2, 10), (2, 12)] leftTurn

/-- `branch_4` (violated): the van is twenty-eight metres up the opposing approach at 12 m/s, so
    its distance to the junction (21.5 m) is beyond its speed times the headway bound (18 m); but
    the creeping car and the van are on paths whose closest approach within the horizon is
    centimetres, which is the immediacy of the hazard, and precedence is not granted. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [turningCar (m 1), oncomingVan (cm 2800) (m 12)] crossing
      [(1, 10), (1, 11), (2, 12)] leftTurn

/-- `branch_5` (violated): car and van stand still, touching, within the junction: the centres do
    not approach at all within the horizon, so no clearance is lost, and precedence is denied by
    the contact alone. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [turningCar (m 0), oncomingVan (cm 80) (m 0)] crossing
      [(1, 10), (1, 11), (2, 10), (2, 12)] leftTurn

/-- `branch_6` (violated): the car waits mid-turn while the van comes through the junction at
    3 m/s. Their centres never pass closer than 2.55 m, above the clearance, but the nearest points
    of the two bodies are half a metre apart: the clearance the convention measures between the
    bodies is not kept. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [turningCar (m 0), oncomingVan (cm 160) (m 3)] crossing
      [(1, 10), (1, 11), (2, 10), (2, 12)] leftTurn

/-- `branch_7` (violated): a twelve-metre truck waits mid-left-turn, its tail in its approach lane
    and its nose two and a half metres out the far side of the junction. The oncoming van, still
    2.3 m short of the junction at 2 m/s, is within its speed times the headway bound — so close
    thereto — and clips the truck's nose. Nothing else makes it owed precedence: it is not within
    the junction, and the centres, closing at 2 m/s over 9 m, do not reach their closest approach
    within the horizon, so no clearance is lost; the contact alone denies precedence. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t
      [ Build.user 1 [.truck] (cm 130, cm 0) Build.north (m 0) (m 6, cm 125, cm 160)
      , Build.user 2 [.motorVehicle] (cm (-90), cm 880) Build.south (m 2) vanHalf ]
      crossing [(1, 10), (1, 11), (2, 12)] leftTurn

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated ]

end TrafficSpecWitness.NRS_484B_253_o1
