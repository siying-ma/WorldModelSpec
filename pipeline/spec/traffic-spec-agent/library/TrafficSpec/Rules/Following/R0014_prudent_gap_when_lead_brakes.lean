/-
  Rule R0014 — following too closely: the brake-light route into the
  "reasonable and prudent" standard.

  Law text (EX-FOLLOW-001, "Following too closely"):
    "The driver of a motor vehicle shall not follow another vehicle more closely
     than is reasonable and prudent. A vehicle shall not remain within four
     metres of the vehicle it is following."

  SCOPE — THIS FILE IS ONLY ONE ROUTE INTO THE FIRST SENTENCE
  ----------------------------------------------------------
  This rule formalizes the **first** sentence, and only one sufficient condition
  under it: holding a gap of under ten metres behind a vehicle whose brake light
  is on. The second sentence — the four-metre bright line — is a sibling node,
  `Following/R0003_following_distance`, and is not restated here. The two rules
  are deliberately non-overlapping in the band range they convict: R0003 fires
  inside four metres (`safetyHazard` + `nearCollision`), this rule fires
  anywhere inside ten metres, so a trace inside four metres behind a braking
  lead is convicted by both, and the violating scenario below stays in the 4–10 m
  bands precisely so that it is convicted by this rule and acquitted by R0003.

  Neither rule is the whole of EX-FOLLOW-001. The first sentence is an
  open-textured standard whose content depends on speed, surface, visibility and
  traffic; this file picks out the one configuration the scene graph can see and
  makes no claim that a trace it reports compliant is prudent. In particular a
  driver who tailgates a lead that never touches its brakes is not convicted
  here at all (see `close_gap_lead_not_braking`, which is *expected true*).

  Formalization notes — every number below is ours, not the statute's
  --------------------------------------------------------------------
  * **Why braking is the route in.** The statute gives no metric for "reasonable
    and prudent", and the graph carries no speed, accel or brake channel for any
    vehicle but the ego (`carla/schema.json` → `unavailable.non_ego_dynamics`:
    `copy_carla_actor_state` / `copy_carla_control` are called for the ego node
    alone). The one piece of dynamic evidence about the lead vehicle is its
    light state. A lead vehicle showing a brake light is shedding speed, so the
    gap ahead is closing and the follower's stopping distance requirement is
    rising: a gap that would be adequate behind a steady lead is not adequate
    behind that one. That is the reading of "more closely than is reasonable and
    prudent" this rule commits to, and it is challengeable — it convicts only on
    the conjunction of closeness *and* observed braking, so it under-enforces a
    clause that also covers closing on a steady lead at speed.

  * **`gapMetres := 10`, and ten metres is a choice.** It is the band union
    `safetyHazard` (<2 m) + `nearCollision` (2–4 m) + `superNear` (4–7 m) +
    `veryNear` (7–10 m), expressed as `Pred.withinMetres 10` and never as a band
    name: `.near` is the 10–16 m band, the second *farthest*, and naming it here
    would silently mean "10 to 16 metres away". Ten metres is roughly two car
    lengths, i.e. under a second of headway at 40 km/h — comfortably inside any
    stopping distance behind a decelerating vehicle, and comfortably outside the
    four-metre line the second sentence already draws, so the rule adds
    something rather than restating R0003. Raise it to 16 and ordinary
    town-traffic following distances are convicted; lower it to 7 and the rule
    collapses towards R0003.

    Residue, from `carla/schema.json` → `unavailable.exact_distance` and
    `capture_preconditions.proximity_band_metres`: proximity is quantised into
    six bands and only the band *label* survives `process_to_junction_rsv`, so
    "ten metres" is exactly "at or inside the `veryNear` band" and nothing
    finer. The band-to-metres mapping is hard-coded in
    `Core/Scene.lean::distanceBands` from the generator's overridable
    `DEFAULT_PROXIMITY_THRESHOLDS`, which no capture records.

  * **`persistFrames := 6`, and "remain" has no duration in the text.** Six
    frames is 0.3 s at the reference 20 Hz capture rate
    (`Core/Scene.lean`, `captureHz := 20`) — the shortest window that still
    distinguishes a transient compression of the gap, as happens for a moment
    when a lead vehicle first brakes and the follower has not yet responded,
    from a gap that is being *held*. Lower it to 4 and
    `transient_close_while_braking` is convicted; raise it and a driver who sits
    inside ten metres of a braking lead for a fifth of a second escapes. Nothing
    in the clause settles it.

    This inherits the capture-rate residue in
    `capture_preconditions.capture_rate`: frames carry no timestamp, so 6 frames
    is 0.3 s only if the capture really ran at 20 Hz, which no capture records.
    At 40 Hz the same formula demands 0.15 s.

  * **RESIDUE on the brake light itself — read the GROUND count, not the verdict.**
    From `carla/schema.json` → `partially_available.another_vehicle_braking_or_signalling`:
    `light_brake` is evidence of the *driver's action*, not of the resulting
    deceleration, and it stays `false` if the simulated traffic manager never
    actuates it. So zero convictions on a real capture is **not** evidence of
    prudent driving — it is equally consistent with a capture in which no lead
    vehicle's brake light was ever set. On the first `run_spec monitor` run
    against a human-labelled capture, the number to read is how often this rule
    is engaged and grounded, not how often it reports compliant.

  * **`brakeLightOn` is applied to `w`, never to `v`.** `light_brake` exists on
    every vehicle *except* the ego (`carla/schema.json` → `attribute_keys`),
    because the ego's braking is published as the `brake` control channel
    instead. Applied to the ego binder the predicate is silently false and the
    whole antecedent — and therefore the whole rule — becomes vacuously true.

  * **The formula is gated on `Pred.isEgo v`.** The statute binds every driver,
    but no proximity or angular edge is ever emitted between two non-ego actors
    (`carla/schema.json` → `relation_coverage`, from
    `DEFAULT_PROXIMITY_RELATIONS` / `DEFAULT_DIRECTIONAL_RELATIONS`), so a
    non-ego follower's distance to a non-ego lead is unobservable and this
    antecedent could never hold for it on real data. Ungated, the rule would
    also admit the reversed grounding in which the ego is the vehicle *being*
    followed. This rule therefore makes no claim about one non-ego vehicle
    following another.

  * **"the vehicle it is following" is `Pred.followingWithin`**, i.e.
    `sameLane v w ⋀ behind v w ⋀ withinMetres gapMetres v w`. Relation direction
    reads "src is ⟨rel⟩ tgt" (`Core/Vocab.lean` §5), so `behind v w` says **v is
    the follower** and w is the vehicle being followed; inverting the arguments
    would convict the vehicle in front for being tailgated by a braking car.
    `being_tailgated_by_braking_vehicle` exists to fail if that inversion, or the
    loss of the `isEgo` gate, is ever introduced.

    Residue carried from R0003: "following" here is geometric, not intentional.
    Two vehicles stopped nose-to-tail in a queue with the lead's brake light on
    satisfy the antecedent, and that is an over-conviction of this
    formalization — the graph carries no speed for the lead
    (`unavailable.non_ego_dynamics`), so the antecedent cannot be narrowed to a
    *moving* lead without conditioning on ego speed alone, which would be a
    different rule. Recorded rather than patched.

  * **Both binders use `proximityVehicleBinder`, not `vehicleBinder`.** The
    proximity and angular tables cover only the base classes
    `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck`, so a `van` or a bare
    `vehicle` carries no distance edge and binding one would ground and then
    report compliance forever.

  * **Shape and trace length.** `□ (¬ₛ .bounded persistFrames forbidden)`: the
    safety shape, "at no position does the forbidden state hold for
    `persistFrames` consecutive frames". `SFProp.frameSpan` is therefore 6, and
    `Core/Semantics.lean::loopBounded` reads a window running off the end of the
    trace as false — so the last 5 frames of any trace are a blind zone in which
    a violation cannot be reported, and any trace shorter than 6 frames reports
    compliant whatever it contains. Every scenario below is 16 frames, and the
    violating one holds the forbidden state from frame 0, clear of the blind
    zone.

  * **Not validated against real data.** The scenarios below were written from
    the same reading of the clause as the formula, so they cannot catch a
    misreading of it. Until `run_spec monitor` has compared this rule against a
    human-labelled capture, treat it as unvalidated.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Following.R0014

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The gap this rule treats as imprudent behind a braking lead: ten metres,
    i.e. the band union `safetyHazard` + `nearCollision` + `superNear` +
    `veryNear`. A formalization choice — the first sentence states no distance.
    Written as `Pred.withinMetres 10`, never as the band name `.near`, which is
    the 10–16 m band. -/
def gapMetres : Nat := 10

/-- How long the ego must hold that gap behind a braking lead before it counts
    as *remaining* there: 6 frames = 0.3 s at the reference 20 Hz capture rate.
    A formalization choice — the statute states no duration. -/
def persistFrames : Nat := 6

/-- Quantified over vehicles that carry proximity edges; effective on the ego
    vehicle, the only one whose separation from another actor is observable, and
    on a non-ego lead, the only one whose brake light is published. -/
def schema : PropertySchema where
  name    := "prudent_gap_when_lead_brakes"
  binders := [proximityVehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    -- The forbidden state: the ego v is following w within ten metres while w
    -- is showing a brake light. `brakeLightOn` is on w — the ego publishes no
    -- `light_brake` — and `behind v w` inside `followingWithin` makes v the
    -- follower.
    □ (¬ₛ (SFProp.bounded persistFrames
             (isEgo v ⋀ followingWithin gapMetres v w ⋀ brakeLightOn w)))

def entry : RuleEntry where
  nodeId  := "Following/R0014_prudent_gap_when_lead_brakes"
  lawRefs := ["EX-FOLLOW-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

private def egoId  : Nat := 1
private def leadId : Nat := 2
private def laneId : Nat := 10
private def roadId : Nat := 20

/-- One shared driving lane on one ordinary road, present in every frame of
    every trace, so `sameLane` holds and both binders always bind — a scenario
    can never pass by having nothing to ground on. -/
private def structureEntities : List Entity :=
  [ mkLane laneId "Lane 7_-1", mkRoad roadId "Road 7" ]

private def structureRels : List Relation :=
  [ mkRel laneId .isIn roadId ]

/-- The ego and one other car. `braking` decides whether the other car carries
    `light_brake = "true"`; when it does not, the attribute is simply absent, as
    it is in a capture where the traffic manager never actuated the light, and
    an absent boolean reads false. -/
private def occupants (braking : Bool) : List Entity :=
  [ mkEgo egoId .car "8.000"
  , if braking then (mkActor leadId "car_0" .car).withAttr "light_brake" "true"
    else mkActor leadId "car_0" .car ]

private def occupantRels : List Relation :=
  [ mkRel egoId .isIn laneId, mkRel leadId .isIn laneId ]

/-- One frame with the ego at the other car's rear at proximity band `band`.
    The generator computes each angular edge from the source actor's forward
    vector, so same-direction traffic yields one rear edge (`ego atDRearOf
    car_0`) and one front edge (`car_0 inDFrontOf ego`); the single distance
    edge is emitted ego-first, as the default relation table does. -/
private def followFrame (band : RelLabel) (braking : Bool) : Scene :=
  frame
    (occupants braking ++ structureEntities)
    (structureRels ++ occupantRels ++
      [ mkRel egoId .atDRearOf leadId
      , mkRel leadId .inDFrontOf egoId
      , mkRel egoId band leadId ])

/-- One frame with the roles reversed: the other car sits at the *ego's* rear,
    so the ego is the vehicle being followed. Distance edge car_0-first, angular
    edges inverted. -/
private def tailgatedFrame (band : RelLabel) (braking : Bool) : Scene :=
  frame
    (occupants braking ++ structureEntities)
    (structureRels ++ occupantRels ++
      [ mkRel leadId .atDRearOf egoId
      , mkRel egoId .inDFrontOf leadId
      , mkRel leadId band egoId ])

/-- Sixteen frames at the 10–16 m band behind a lead braking on every frame.
    The lead brakes hard but the gap stays outside ten metres, so this rule has
    nothing to say — and this trace is the check that `.near` is read as the far
    band it is, not as "near" in the English sense. -/
def traceBrakingLeadAtLawfulGap : Trace :=
  List.replicate 16 (followFrame .near true)

/-- Sixteen frames at the 7–10 m band, inside the ten-metre gap on every frame,
    but the lead's `light_brake` is absent throughout. A close but steady gap
    behind a lead that is not decelerating: not convicted by this rule, whose
    reading of "reasonable and prudent" is closeness *plus* observed braking.
    The discriminating twin of `sustained_close_while_lead_brakes` — the two
    traces differ only in the lead's brake light. -/
def traceCloseGapLeadNotBraking : Trace :=
  List.replicate 16 (followFrame .veryNear false)

/-- Sixteen frames behind a lead braking throughout, with the gap compressing
    into the 7–10 m band for exactly four consecutive frames (positions 4–7) and
    then opening again. Inside ten metres, but not *remaining* there: four
    frames is short of the six-frame persistence window. Set
    `persistFrames := 4` and this scenario convicts. -/
def traceTransientCloseWhileBraking : Trace :=
  List.replicate 4 (followFrame .near true)
    ++ List.replicate 4 (followFrame .veryNear true)
    ++ List.replicate 8 (followFrame .near true)

/-- Sixteen frames with the other car glued to the *ego's* rear inside ten
    metres, its own brake light on throughout. Someone is following closely
    behind a braking vehicle, but it is the other car, not the ego, and the ego
    is not the driver this rule addresses. Invert the arguments of `behind`
    inside `followingWithin`, or drop the `isEgo v` gate, and this reports a
    violation. -/
def traceBeingTailgatedByBrakingVehicle : Trace :=
  List.replicate 16 (tailgatedFrame .veryNear true)

/-- Sixteen frames with the ego inside ten metres of a braking lead on every
    one of them, alternating between the 7–10 m and the 4–7 m band so the
    violation does not depend on a single band label. Both bands are inside ten
    metres and neither is inside four, so this trace must be convicted by this
    rule and acquitted by `Following/R0003`. The forbidden state runs from frame
    0, clear of the trailing five-frame blind zone. -/
def traceSustainedCloseWhileLeadBrakes : Trace :=
  [ followFrame .veryNear true,  followFrame .superNear true
  , followFrame .veryNear true,  followFrame .superNear true
  , followFrame .veryNear true,  followFrame .superNear true
  , followFrame .veryNear true,  followFrame .superNear true
  , followFrame .veryNear true,  followFrame .superNear true
  , followFrame .veryNear true,  followFrame .superNear true
  , followFrame .veryNear true,  followFrame .superNear true
  , followFrame .veryNear true,  followFrame .superNear true ]

def scenarios : List Scenario :=
  [ { name := "braking_lead_at_lawful_gap"
    , trace := traceBrakingLeadAtLawfulGap
    , expected := true }
  , { name := "close_gap_lead_not_braking"
    , trace := traceCloseGapLeadNotBraking
    , expected := true }
  , { name := "transient_close_while_braking"
    , trace := traceTransientCloseWhileBraking
    , expected := true }
  , { name := "being_tailgated_by_braking_vehicle"
    , trace := traceBeingTailgatedByBrakingVehicle
    , expected := true }
  , { name := "sustained_close_while_lead_brakes"
    , trace := traceSustainedCloseWhileLeadBrakes
    , expected := false } ]

end TrafficSpec.Rules.Following.R0014
