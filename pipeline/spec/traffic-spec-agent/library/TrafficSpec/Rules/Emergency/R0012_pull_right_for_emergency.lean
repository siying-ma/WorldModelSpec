/-
  Rule R0012 — yield to an approaching emergency vehicle: pull to the right and
  clear the intersection.

  Law text (EX-EMERGENCY-001, "Emergency vehicles"):
    "Upon the approach of an authorised emergency vehicle, the driver of every
     other vehicle shall yield the right of way and shall drive to the
     right-hand edge of the roadway, clear of any intersection."

  Shape
  -----
  One antecedent ("upon the approach of an authorised emergency vehicle") and a
  compound consequent with two observable limbs ("drive to the right-hand edge
  of the roadway" and "clear of any intersection"). Both limbs share the one
  antecedent and the one window, so this is one rule with a two-limb consequent:

      □ (¬ₛ .bounded graceFrames
             (isEgo v ⋀ isEmergency w ⋀ inProximity v w
              ⋀ (hasLaneToTheRight v ⋁ inAnyJunction v)))

  Read positively: the ego must not **remain**, for `graceFrames` consecutive
  frames, in a state where an emergency vehicle is within 25 m while the ego is
  either not pulled as far right as its direction of travel allows, or still
  inside an intersection.

  READ THIS FIRST — AN AMBULANCE IS INVISIBLE TO THIS RULE
  -------------------------------------------------------
  CARLA's ambulance is `vehicle.ford.ambulance`, whose base class is **van**,
  and the generator emits no proximity or angular edge for a van
  (`carla/schema.json` → `relation_coverage`; `Core/Scene.lean`, `RelLabel`).
  The antecedent needs a distance edge, so `isEmergency w ⋀ inProximity v w`
  can only ever ground on the police car (`car`) and the firetruck (`truck`).

  An approaching ambulance is therefore **outside what this rule can see**, and
  this rule's silence about one is not a finding of compliance. A monitoring
  application must not read a `compliant` verdict here as "the driver yielded";
  it means at most "the driver yielded to every emergency vehicle the graph
  carries a distance to". `w` is bound with `proximityVehicleBinder`, which
  admits exactly the classes that can carry a distance edge, so the grounding
  count reports honestly how many emergency vehicles the rule could see rather
  than counting vans it could never fire on.

  Formalization notes — the readings the text did not settle
  ---------------------------------------------------------
  * **"Upon the approach" is read as "within 25 m", i.e. `Pred.inProximity` —
    the widest band the graph carries.** There is no siren, no light-bar state
    and no exact distance (`carla/schema.json` → `unavailable.exact_distance`,
    which records that `process_to_junction_rsv` drops the metric edge distance
    and keeps only the band label), and the emergency vehicle's own speed is not
    observable at all (`unavailable.non_ego_dynamics`: `copy_carla_actor_state`
    runs for the ego node only).

    So *approach* degrades to *presence nearby*: an emergency vehicle parked
    stationary 20 m away triggers the duty exactly as one closing at speed
    does. This over-enforces, and it is a real residue, not a rounding.

    **An available refinement, deliberately not taken:** approach *is*
    expressible as a proximity band tightening across frames — `withinMetres 25`
    now and `withinMetres 16` later — because band changes over time are the one
    piece of dynamic evidence a non-ego actor carries. This rule does not do
    that, because a band pair only says the gap closed, not that the vehicle was
    responding to a call, and because it would silently acquit a driver who
    failed to yield to an emergency vehicle already alongside. Recorded as the
    first refinement to try if over-enforcement here proves to matter.

  * **"Yield the right of way" contributes no independent content.** The graph
    carries no priority or right-of-way annotation whatsoever
    (`unavailable.right_of_way`), so the yielding duty is discharged entirely by
    the two limbs that *are* observable — pulling right and clearing the
    junction. A driver who stayed in the rightmost lane, clear of the junction,
    and still obstructed the emergency vehicle is not convicted by this rule.

  * **"The right-hand edge of the roadway" degrades to "the rightmost lane of my
    own direction of travel".** There is no kerb, no carriageway edge and no
    lane width in the abstraction: `process_to_junction_rsv` collapses each
    waypoint run into a bare lane node (`unavailable.lane_width_and_markings`).
    A driver who pulled onto the shoulder and one who merely took the rightmost
    lane are indistinguishable here.

  * **`Pred.hasLaneToTheRight` is used, NOT `¬ₛ Pred.inRightmostLane`, and the
    two are not interchangeable.** `inRightmostLane` is false for a vehicle
    occupying no lane at all, so negating it would convict a driver who pulled
    *fully off the carriageway* — the most complete compliance available in this
    abstraction. `hasLaneToTheRight` is the positive form of the offence and is
    false for an off-road vehicle, which is the correct direction here.

  * **The lane-id sign predicates appear nowhere below.**
    `Pred.laneRightOfReference` / `laneLeftOfReference` /
    `inLaneRightOfReference` / `inLaneLeftOfReference` read which side of the
    OpenDRIVE *reference line* a lane was authored on, not a legal side of the
    road: every lane of one direction of travel shares the sign. The deleted
    rule `Lane/R0009` formalized "the right half of the roadway" that way,
    passed all four of its own scenarios, and then convicted 50 frames of
    lawful driving in the bundled sceneflow capture
    (`carla/schema.json` → `which_half_of_the_roadway.do_not_use`, and the
    warning on all four predicates in `Core/Vocab.lean`).
    `hasLaneToTheRight` needs no map convention: it reads the lane-to-lane
    `toRightOf` edge, which the generator computes in the *target* lane's own
    forward frame, so an asymmetric edge pair means same direction and a mutual
    `toLeftOf` pair means opposite — and `Vocab.lean`'s `opposedLanes` excludes
    the opposing case, so an oncoming carriageway to the driver's right is never
    a lane this rule demands they move into.

  * **`hasLaneToTheRight` is slightly stricter than "the right-hand edge" on a
    wide carriageway.** On three same-direction lanes it demands the rightmost,
    which here is what the statute asks for anyway ("the right-hand edge"), so
    unlike `Lane/R0008` this strictness is a feature rather than a residue.

  * **`graceFrames := secondsToFrames 2 = 40`, and the number is ours, not the
    statute's.** The statute implies immediate compliance and states no
    duration; two seconds is chosen as a plausible allowance for a driver to
    perceive the emergency vehicle and complete a lane change or clear the
    junction. It is 2 s **only at the assumed 20 Hz** — frames carry no
    timestamp (`unavailable.timestamps`) and `capture_hz = 20` is a caller-chosen
    simulator setting no capture records
    (`capture_preconditions.capture_rate`), so at 40 Hz the same formula grants
    only 1 s of grace. `pulls_right_within_the_grace_window` pins the value from
    below: it holds the offending state for 30 frames, so any `graceFrames` at
    or below 30 convicts a driver who did pull over promptly.

    Residues of expressing the duty as a duration, both real and neither
    detectable by the scenarios below: a driver boxed in by traffic for longer
    than two seconds is convicted though they could not comply, and a driver who
    dips into the rightmost lane for a single frame every two seconds is never
    convicted at all.

  * **`Pred.isEgo v` gates the formula, so this rule makes no claim about any
    other driver's duty to yield.** The statute binds "the driver of every other
    vehicle", but no proximity or angular edge is ever emitted between two
    non-ego actors (`relation_coverage`), so an ungated rule could not fire for a
    non-ego driver in the first place — `inProximity v w` would simply be false
    for every such pair. The gate makes that restriction explicit rather than
    leaving it as an accident of the data, and `ordinary_vehicle_alongside`
    would still pass without it.

  * **Shape and trace length.** `SFProp.frameSpan` of `.bounded 40 φ` is
    `39 + 1 = 40`, and `Core/Semantics.lean::loopBounded` reads a window that
    runs off the end of the trace as false — so on a trace shorter than 40
    frames this rule reports *compliant* whatever the trace contains
    (`tools/check_spec.py` rejects those as `TRACE_TOO_SHORT`), and the last 39
    frames of any trace are a blind zone in which a violation cannot be
    reported. Every scenario below is 60 frames, and both violating stretches
    start at frame 0 so their verdicts sit clear of that blind zone.

  * **Not validated against real data.** The scenarios below were written from
    the same reading of the clause as the formula, so they cannot catch a
    misreading of it — `Lane/R0009` is the standing proof that a full scenario
    set can pass while the rule convicts lawful driving. Until `run_spec
    monitor` has compared this rule against a human-labelled capture, treat it
    as unvalidated. The two things that comparison should look at first are the
    grounding count (is there any emergency vehicle in the capture that is not a
    van?) and whether the 25 m antecedent over-fires on parked emergency
    vehicles.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Emergency.R0012

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- How long the ego may remain un-pulled-over, or inside a junction, while an
    emergency vehicle is within 25 m, before the stay becomes a failure to
    yield. 2 s = 40 frames at the reference 20 Hz capture rate. A formalization
    choice: the statute states no duration — see the header. -/
def graceFrames : Nat := TrafficSpec.secondsToFrames 2

/-- Quantified over vehicles that carry proximity edges, because the antecedent
    needs a distance; effective on the ego vehicle only — see the header. -/
def schema : PropertySchema where
  name    := "pull_right_for_emergency"
  binders := [proximityVehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    -- "an emergency vehicle `w` is within 25 m of the ego `v`, and `v` is
    -- either not as far right as its direction of travel allows or still inside
    -- an intersection" — the forbidden state, held for `graceFrames`
    -- consecutive frames.
    □ (¬ₛ (SFProp.bounded graceFrames
             (isEgo v ⋀ isEmergency w ⋀ inProximity v w
              ⋀ (hasLaneToTheRight v ⋁ inAnyJunction v))))

def entry : RuleEntry where
  nodeId  := "Emergency/R0012_pull_right_for_emergency"
  lawRefs := ["EX-EMERGENCY-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- Every trace shares one map: a two-lane, one-way carriageway (`Road 7`) and a
-- separate junction road (`Road 8`, inside `Junction 5`) carrying one lane.
-- The junction is present in all of them so that the structure the second limb
-- reads is never absent by accident; only the last trace puts the ego in it.
----------------------------------------------------------------------

private def egoId       : Nat := 1
private def otherId     : Nat := 2
private def laneRightId : Nat := 10
private def laneLeftId  : Nat := 11
private def roadId      : Nat := 20
private def junLaneId   : Nat := 12
private def junRoadId   : Nat := 21
private def junctionId  : Nat := 30

private def egoEntity : Entity := mkEgo egoId .car "8.000"

/-- The police car: base class `car`, `special_class = "emergency"`. It has to
    be a car or a truck — an ambulance is a van and carries no distance edge,
    so a trace built with one would ground and never fire. -/
private def policeEntity : Entity := mkEmergency otherId "car_0" .car

/-- The minimal pair partner: the same car with **no** `special_class` at all. -/
private def ordinaryEntity : Entity := mkActor otherId "car_0" .car

/-- Lane and road nodes. `Lane 7_-1` is the right-hand lane of the carriageway
    and `Lane 7_-2` the left-hand one; the lane-id numbers are incidental —
    nothing below reads them, and they share a sign precisely because they carry
    traffic the same way. `Lane 8_-1` is the junction's inner lane. -/
private def structureEntities : List Entity :=
  [ mkLane laneRightId "Lane 7_-1"
  , mkLane laneLeftId  "Lane 7_-2"
  , mkRoad roadId "Road 7"
  , mkLane junLaneId "Lane 8_-1"
  , mkRoad junRoadId "Road 8"
  , mkJunction junctionId "Junction 5" ]

/-- The **asymmetric** left/right pair is how the generator marks two lanes of
    the SAME direction of travel: each edge is computed in the target lane's own
    forward frame, so consistent headings yield one `toRightOf` and one
    `toLeftOf`. The junction road's `isIn` edge to `Junction 5` is what
    `Pred.inAnyJunction` walks, over the lane → road → junction chain. -/
private def structureRels : List Relation :=
  [ mkRel laneRightId .isIn roadId
  , mkRel laneLeftId  .isIn roadId
  , mkRel laneRightId .toRightOf laneLeftId
  , mkRel laneLeftId  .toLeftOf  laneRightId
  , mkRel junLaneId .isIn junRoadId
  , mkRel junRoadId .isIn junctionId ]

/-- One frame: the ego in lane `lane`, the other vehicle `w` in the same lane at
    the ego's rear, and — when `near` is true — a `.near` distance edge (the
    10–16 m band, comfortably inside the 25 m the antecedent asks for).

    The generator computes each angular edge from the source actor's forward
    vector, so a vehicle behind the ego yields `w atDRearOf ego` and
    `ego inDFrontOf w`; the single distance edge is emitted ego-first, as the
    default relation table does. The angular edges are scene-setting only —
    nothing in the formula reads them. -/
private def emergencyFrame (w : Entity) (lane : Nat) (near : Bool) : Scene :=
  frame
    ([egoEntity, w] ++ structureEntities)
    (structureRels ++
      [ mkRel egoId .isIn lane
      , mkRel otherId .isIn lane
      , mkRel otherId .atDRearOf egoId
      , mkRel egoId .inDFrontOf otherId ] ++
      (if near then [ mkRel egoId .near otherId ] else []))

/-- The police car within `.near`, ego in the given lane. -/
private def police (lane : Nat) : Scene := emergencyFrame policeEntity lane true

/-- The police car present but no longer carrying a distance edge — it has moved
    beyond 25 m, so the antecedent is false however the ego is placed. -/
private def policeAway (lane : Nat) : Scene := emergencyFrame policeEntity lane false

/-- An ordinary car within `.near`, ego in the given lane. -/
private def ordinary (lane : Nat) : Scene := emergencyFrame ordinaryEntity lane true

/-- Sixty frames fully compliant: the emergency vehicle is within `.near` of the
    ego throughout, and the ego sits in the rightmost lane of its direction of
    travel — no same-direction lane lies to its right — and never in a junction
    lane. The forbidden state never holds for a single frame. -/
def tracePulledRightAndClear : Trace :=
  List.replicate 60 (police laneRightId)

/-- A driver who reacted: thirty frames in the left-hand lane with the emergency
    vehicle already close, then thirty in the right-hand lane. Thirty
    consecutive offending frames is short of the forty-frame grace window, so
    the manoeuvre is excused.

    This scenario pins `graceFrames` from below — set it to 30 or less and a
    driver who pulled over within a second and a half is convicted. -/
def tracePullsRightWithinGrace : Trace :=
  List.replicate 30 (police laneLeftId) ++ List.replicate 30 (police laneRightId)

/-- The minimal pair of `traceRemainsInLeftLane`: an identical sixty frames in
    the left-hand lane, with an ordinary car — no `special_class` — at the
    ego's rear the whole time. No emergency vehicle is approaching, so the
    clause has nothing to say and no other rule's business is decided here.

    Drop the `isEmergency w` antecedent and this scenario convicts. -/
def traceOrdinaryVehicleAlongside : Trace :=
  List.replicate 60 (ordinary laneLeftId)

/-- Failure of the first limb: the emergency vehicle is within `.near` for
    frames 0–55, and the ego holds the left-hand lane for frames 0–49 before
    finally moving right for the last ten. Fifty consecutive offending frames
    from frame 0, so a complete forty-frame window fits at position 0 — well
    clear of the trailing thirty-nine-frame blind zone. Pulling over at last
    does not undo the failure to yield. -/
def traceRemainsInLeftLane : Trace :=
  List.replicate 50 (police laneLeftId)
  ++ List.replicate 6 (police laneRightId)
  ++ List.replicate 4 (policeAway laneRightId)

/-- Failure of the second limb, isolated: the emergency vehicle is within
    `.near` for frames 0–55, and the ego is inside `Junction 5` — via the
    lane → road → junction `isIn` chain — for frames 0–49 before clearing it.

    The junction's inner lane has no same-direction lane to its right, so
    `hasLaneToTheRight` is false in every frame of this trace and the ego is as
    far right as its direction of travel allows throughout. Only
    `inAnyJunction` convicts here: drop that disjunct and this scenario stops
    reporting a violation. -/
def traceRemainsInJunction : Trace :=
  List.replicate 50 (police junLaneId)
  ++ List.replicate 6 (police laneRightId)
  ++ List.replicate 4 (policeAway laneRightId)

def scenarios : List Scenario :=
  [ { name := "pulled_right_and_clear_of_junction"
    , trace := tracePulledRightAndClear
    , expected := true }
  , { name := "pulls_right_within_the_grace_window"
    , trace := tracePullsRightWithinGrace
    , expected := true }
  , { name := "ordinary_vehicle_alongside"
    , trace := traceOrdinaryVehicleAlongside
    , expected := true }
  , { name := "remains_in_left_lane_with_emergency_near"
    , trace := traceRemainsInLeftLane
    , expected := false }
  , { name := "remains_in_junction_with_emergency_near"
    , trace := traceRemainsInJunction
    , expected := false } ]

end TrafficSpec.Rules.Emergency.R0012
