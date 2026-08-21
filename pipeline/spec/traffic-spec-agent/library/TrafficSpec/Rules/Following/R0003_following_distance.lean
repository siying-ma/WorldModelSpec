/-
  Rule R0003 — following too closely: the four-metre bright line.

  Law text (EX-FOLLOW-001, "Following too closely"):
    "The driver of a motor vehicle shall not follow another vehicle more closely
     than is reasonable and prudent. A vehicle shall not remain within four
     metres of the vehicle it is following."

  SCOPE — THIS FILE IS ONLY THE SECOND SENTENCE
  ---------------------------------------------
  This rule formalizes the **second** sentence, the four-metre bright line, and
  nothing else. The first sentence ("more closely than is reasonable and
  prudent") is a separate, open-textured obligation with no metric threshold —
  it is a standard whose content depends on speed, surface, visibility and
  traffic, none of which this rule reads — and it is deferred to a sibling node.
  Do not read this file as the whole of EX-FOLLOW-001: a trace this rule reports
  as compliant may still violate the first sentence, and a monitoring
  application that registers only this rule under-enforces the clause.

  Formalization notes
  -------------------
  * **"remain" is given a persistence window of 4 frames, and that number is
    ours, not the statute's.** The text says "shall not remain within four
    metres" without saying for how long, so a literal single-frame reading would
    convict a driver whose gap momentarily compressed — during another vehicle's
    cut-in, or a lead vehicle's sudden brake — which "remain" plainly does not
    cover. `persistFrames := 4` is 0.2 s at the reference 20 Hz capture rate
    (`Core/Scene.lean`, `captureHz := 20`), chosen as the shortest window that
    still distinguishes a transient compression from a held gap while keeping
    the required trace length small. It is a formalization choice open to
    challenge in both directions: raise it and a driver who tailgates for a
    fifth of a second escapes; lower it to 1 and the transient-compression case
    is convicted. Nothing in the law text settles it.

    The window also inherits the capture-rate residue recorded in
    `carla/schema.json` → `capture_preconditions.capture_rate`: frames carry no
    timestamp, so 4 frames is 0.2 s only if the capture really ran at 20 Hz,
    which no capture records. At 40 Hz the same formula demands only 0.1 s.

  * **"within four metres" is `Pred.withinMetres 4`, i.e. the band union
    `safetyHazard` (<2 m) + `nearCollision` (2–4 m).** Proximity is quantised
    into six bands (`carla/schema.json` → `unavailable.exact_distance`: the
    metric `distance` on the base graph's edges is not copied by
    `process_to_junction_rsv`), so four metres happens to fall exactly on the
    `nearCollision` upper bound and the reading is not lossy at this threshold —
    a coincidence of the threshold, not a general property. The band-to-metres
    mapping itself is hard-coded in `Core/Scene.lean::distanceBands` from the
    generator's `DEFAULT_PROXIMITY_THRESHOLDS`, which is an overridable
    parameter of `process_to_junction_rsv` that no capture records
    (`capture_preconditions.proximity_band_metres`). Inclusive at the boundary:
    a vehicle at exactly 4.0 m reads as `nearCollision` and is inside the line.

  * **"the vehicle it is following" is same-lane-plus-behind, via
    `Pred.followingWithin`.** That is `sameLane v w ⋀ behind v w ⋀
    withinMetres 4 v w`. Relation direction reads "src is ⟨rel⟩ tgt"
    (`Core/Vocab.lean` §5), so `behind v w` says **v is the follower** and w is
    the vehicle being followed; swapping the arguments would convict the vehicle
    in front for being tailgated. The scenario
    `being_tailgated_is_not_a_violation` exists to fail if that inversion is
    ever introduced.

    Residue: "following" here is a geometric relation, not an intention. A
    vehicle that has just changed into the lane behind another, or two vehicles
    stopped nose-to-tail in a queue, satisfy it. The stopped-queue case is a
    genuine over-conviction of this formalization — the graph carries no speed
    for the lead vehicle (`unavailable.non_ego_dynamics`), so "the vehicle it is
    following" cannot be narrowed to a *moving* lead without conditioning on ego
    speed alone, which would be a different rule. Recorded rather than patched.

  * **The formula is gated on `Pred.isEgo v`, and that is both a data
    restriction and a soundness requirement here.** The statute binds every
    driver, but no proximity or angular edge is ever emitted between two non-ego
    actors (`carla/schema.json` → `relation_coverage`, from
    `DEFAULT_PROXIMITY_RELATIONS` / `DEFAULT_DIRECTIONAL_RELATIONS`), so a
    non-ego follower's distance to a non-ego lead is unobservable and
    `followingWithin` would be false for it on every real capture. Ungated, the
    rule would additionally read the reversed grounding (v = the vehicle in
    front, w = the ego behind it) as a candidate violation whenever the ego's
    own rear edge happened to point the other way. This rule therefore makes no
    claim about a non-ego vehicle following another non-ego vehicle.

  * **Both binders use `proximityVehicleBinder`, not `vehicleBinder`.** The
    proximity and angular tables cover only the base classes
    `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck`, so a `van` or a bare
    `vehicle` carries no distance edge at all; binding one would ground and then
    report compliance forever. `bicycle` is admitted deliberately — the
    vocabulary comment on `proximityVehicleTypes` records that omitting it once
    made a following-distance rule unable to convict a driver tailgating a
    cyclist. The ego's own entity type is `.car`
    (`carla/adapter.py`: the ego blueprint is not in the abstraction and the
    adapter defaults its base class to `"car"`), so it is admitted by this
    binder.

  * **Shape and trace length.** `□ (¬ₛ .bounded persistFrames tailgating)`:
    the safety shape, "at no position does the forbidden state hold for
    `persistFrames` consecutive frames". `SFProp.frameSpan` is therefore 4, and
    `Core/Semantics.lean::loopBounded` reads a window running off the end of the
    trace as false — so the last 3 frames of any trace are a blind zone in which
    a violation cannot be reported, and a trace shorter than 4 frames reports
    compliant whatever it contains. Every scenario below is 8 frames, and the
    violating scenario holds the forbidden state from frame 0 so the verdict
    does not sit in the blind zone.

  * **Not validated against real data.** The scenarios below were written from
    the same reading of the clause as the formula, so they cannot catch a
    misreading. Until `run_spec monitor` has compared this rule against a
    human-labelled capture, treat it as unvalidated.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Following.R0003

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The bright line the second sentence states: four metres. -/
def gapMetres : Nat := 4

/-- How long the ego must hold a sub-four-metre gap before it counts as
    "remaining" there. 4 frames = 0.2 s at the reference 20 Hz capture rate.
    A formalization choice — the statute states no duration. -/
def persistFrames : Nat := 4

/-- Quantified over vehicles that carry proximity edges; effective on the ego
    vehicle, the only one whose separation from another actor is observable. -/
def schema : PropertySchema where
  name    := "following_distance_four_metres"
  binders := [proximityVehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    -- "v remains within four metres of the vehicle w it is following" —
    -- the forbidden state, held for `persistFrames` consecutive frames.
    □ (¬ₛ (SFProp.bounded persistFrames
             (isEgo v ⋀ followingWithin gapMetres v w)))

def entry : RuleEntry where
  nodeId  := "Following/R0003_following_distance"
  lawRefs := ["EX-FOLLOW-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

private def egoId   : Nat := 1
private def leadId  : Nat := 2
private def laneId  : Nat := 10
private def roadId  : Nat := 20

/-- One shared driving lane on one ordinary road. Both vehicles sit in it in
    every frame of every trace, so `sameLane` holds and both binders always
    bind — a scenario can never pass by having nothing to ground on. -/
private def structureEntities : List Entity :=
  [ mkLane laneId "Lane 7_-1", mkRoad roadId "Road 7" ]

private def structureRels : List Relation :=
  [ mkRel laneId .isIn roadId ]

private def occupants : List Entity :=
  [ mkEgo egoId .car "8.000", mkActor leadId "car_0" .car ]

private def occupantRels : List Relation :=
  [ mkRel egoId .isIn laneId, mkRel leadId .isIn laneId ]

/-- One frame with the ego at the lead car's rear at proximity band `band`.
    The generator computes each angular edge from the source actor's forward
    vector, so same-direction traffic yields one rear edge (`ego atDRearOf
    car_0`) and one front edge (`car_0 inDFrontOf ego`); the single distance
    edge is emitted ego-first, as the default relation table does. -/
private def followFrame (band : RelLabel) : Scene :=
  frame
    (occupants ++ structureEntities)
    (structureRels ++ occupantRels ++
      [ mkRel egoId .atDRearOf leadId
      , mkRel leadId .inDFrontOf egoId
      , mkRel egoId band leadId ])

/-- One frame with the roles reversed: the lead car sits at the *ego's* rear,
    so the ego is the vehicle being followed. Same distance edge, opposite
    angular edges. -/
private def tailgatedFrame (band : RelLabel) : Scene :=
  frame
    (occupants ++ structureEntities)
    (structureRels ++ occupantRels ++
      [ mkRel leadId .atDRearOf egoId
      , mkRel egoId .inDFrontOf leadId
      , mkRel leadId band egoId ])

/-- Eight frames holding the 10–16 m band. A lawful gap, never inside four
    metres — and a check that `.near` is read as the far band it is, not as
    "near" in the English sense. -/
def traceSteadyGap : Trace :=
  [ followFrame .near, followFrame .near, followFrame .near, followFrame .near
  , followFrame .near, followFrame .near, followFrame .near, followFrame .near ]

/-- Eight frames in which the gap closes to the 2–4 m band for exactly two
    consecutive frames (positions 3 and 4) and then opens again. Inside four
    metres, but not *remaining* there: two frames is short of the four-frame
    persistence window. Set `persistFrames := 2` and this scenario convicts. -/
def traceTransientClosure : Trace :=
  [ followFrame .near,         followFrame .superNear
  , followFrame .superNear,    followFrame .nearCollision
  , followFrame .nearCollision, followFrame .superNear
  , followFrame .superNear,    followFrame .near ]

/-- Eight frames with the lead car glued to the ego's rear under two metres.
    Someone is tailgating, but it is not the ego, and the ego is not the driver
    the second sentence addresses. Invert the arguments of `behind` inside
    `followingWithin`, or drop the `isEgo v` gate, and this reports a
    violation. -/
def traceBeingTailgated : Trace :=
  [ tailgatedFrame .safetyHazard, tailgatedFrame .safetyHazard
  , tailgatedFrame .safetyHazard, tailgatedFrame .safetyHazard
  , tailgatedFrame .safetyHazard, tailgatedFrame .safetyHazard
  , tailgatedFrame .safetyHazard, tailgatedFrame .safetyHazard ]

/-- Eight frames with the ego at the lead car's rear inside four metres on
    every one of them — alternating between the 2–4 m and the <2 m band, so the
    violation does not depend on a single band label. The forbidden state runs
    from frame 0, well clear of the trailing three-frame blind zone. -/
def traceSustainedTailgating : Trace :=
  [ followFrame .nearCollision, followFrame .nearCollision
  , followFrame .safetyHazard,  followFrame .safetyHazard
  , followFrame .nearCollision, followFrame .safetyHazard
  , followFrame .nearCollision, followFrame .nearCollision ]

def scenarios : List Scenario :=
  [ { name := "steady_gap_allowed"
    , trace := traceSteadyGap
    , expected := true }
  , { name := "transient_closure_allowed"
    , trace := traceTransientClosure
    , expected := true }
  , { name := "being_tailgated_is_not_a_violation"
    , trace := traceBeingTailgated
    , expected := true }
  , { name := "sustained_tailgating_violates"
    , trace := traceSustainedTailgating
    , expected := false } ]

end TrafficSpec.Rules.Following.R0003
