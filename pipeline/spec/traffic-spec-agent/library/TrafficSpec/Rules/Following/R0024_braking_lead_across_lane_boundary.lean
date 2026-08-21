/-
  Rule R0024 — the prudent-gap limb of "following too closely", stated without
  `sameLane`.

  Law text (EX-FOLLOW-001, "Following too closely"):
    "The driver of a motor vehicle shall not follow another vehicle more closely
     than is reasonable and prudent. A vehicle shall not remain within four
     metres of the vehicle it is following."

  SCOPE — THE FIRST SENTENCE, AND THE GROUNDING GAP LEFT OPEN BY R0021
  --------------------------------------------------------------------
  This file formalizes the **first** sentence — the open-textured "reasonable
  and prudent" standard — through the one route into it the scene graph can see:
  holding a gap of under ten metres behind a vehicle showing a brake light. The
  second sentence's four-metre bright line is not restated here; it is carried
  by `Following/R0003` (same lane) and `Following/R0021` (across a lane-node
  boundary).

  It is not a new duty. `Following/R0014` already states this exact reading,
  with the exact same constants. This node exists because of *where* R0014 goes
  silent. R0014, R0015 and R0003 are all built on `Pred.followingWithin`, which
  `Core/Vocab.lean` § 5 defines as
  `sameLane a b ⋀ behind a b ⋀ withinMetres m a b`. The `sameLane` conjunct is a
  single point of failure shared by all three: `process_to_junction_rsv`
  collapses each run of waypoints into **one** lane node and a lane node ends
  where the road does, so a follower still on the approach lane behind a lead
  that has already entered the junction lane does not share a lane node,
  `Pred.sameLane` is false, and every one of those rules reports compliant. That
  is the tailgate-up-to-a-junction geometry, squarely the conduct the clause
  addresses.

  Iteration 5's `Following/R0021` removed that dependency for the four-metre
  bright line only. The band this file covers is the remainder: four to ten
  metres behind a *braking* lead across a lane-node boundary, which no rule in
  the library sees.

  Deliberate duplication of R0014's constants: `gapMetres := 10` and
  `persistFrames := 6` are copied unchanged, so that the **only** difference
  between R0014 and this rule is the lane requirement, and a discrepancy between
  their verdicts on a capture is attributable to that and nothing else. A
  reviewer who disagrees with ten metres changes one constant in two files.

  Formalization notes — every number below is ours, not the statute's
  --------------------------------------------------------------------
  * **"the vehicle it is following" is the DIRECT angular pair, not
    `Pred.sameHeading` and not `Pred.sameLane`.**
    `Pred.directlyBehind v w ⋀ Pred.directlyInFrontOf w v` — the `.atDRearOf` /
    `.inDFrontOf` pair only. Relation direction reads "src is ⟨rel⟩ tgt"
    (`Core/Vocab.lean` § 5), so `directlyBehind v w` says **v is the follower**;
    inverting it would convict the vehicle being tailgated. The scenario
    `ego_is_the_lead_being_tailgated` exists to fail if that inversion is ever
    introduced.

    Requiring **both** edges is what fixes who follows whom. The generator
    computes each angular edge in the source actor's own forward frame, so
    same-direction traffic yields exactly one rear edge and one front edge — an
    asymmetric pair that names the follower — while converging headings yield a
    *mutual* `.inDFrontOf` pair and no rear edge at all
    (`carla/schema.json` → `partially_available.wrong_way_driving`; see
    `head_on_pass_at_five_metres`, which a bare `Pred.withinMetres` would
    convict).

    Why not `Pred.sameHeading`, which `R0021` uses? `sameHeading` unfolds over
    the band unions `{inDFrontOf, inSFrontOf}` and `{atDRearOf, atSRearOf}`, so
    it admits the *side*-rear and side-front sectors. R0021 can afford that
    because its threshold is four metres — the two closest bands — which bounds
    how far into a neighbouring lane a side sector can reach. At ten metres it
    is not affordable: a vehicle braking in the adjacent lane, ten metres away
    and slightly ahead, would satisfy a `sameHeading` antecedent and be
    convicted as a tailgate. The direct sectors are the narrowing R0021's own
    residue note asks for.

    Why not simply reinstate `Pred.sameLane`? That conjunct is the single point
    of failure this node exists to route around.

  * **RESIDUE — the direct front sector is still a cone.** `.inDFrontOf` is
    roughly ±45° by `DEFAULT_DIRECTIONAL_THRESHOLDS`
    (`carla/schema.json` → `capture_preconditions.directional_split_degrees`),
    so on a tight curve a lead in the adjacent lane can still fall inside it.
    Narrower than R0021's exposure, but not zero — and the 45° figure is itself
    an overridable generator default that no capture records. The consequence is
    asymmetric: `scripts/capture_eval.py` marks a law violated if **any** rule
    covering it is violated, so every false positive here becomes
    EX-FOLLOW-001's verdict for the whole capture.

  * **`gapMetres := 10`, and ten metres is a choice the statute does not make.**
    It is the band union `safetyHazard` (<2 m) + `nearCollision` (2–4 m) +
    `superNear` (4–7 m) + `veryNear` (7–10 m), written as `Pred.withinMetres 10`
    and never as a band name: `.near` is the 10–16 m band, the second
    *farthest*, and naming it would silently mean "10 to 16 metres away". Ten
    metres is roughly two car lengths, under a second of headway at 40 km/h, and
    comfortably outside the four-metre line R0003/R0021 already draw, so this
    rule adds a band rather than restating theirs.

    Residue, from `carla/schema.json` → `unavailable.exact_distance` and
    `capture_preconditions.proximity_band_metres`: proximity is quantised into
    six bands and only the band *label* survives `process_to_junction_rsv`, so
    "ten metres" is exactly "at or inside the `veryNear` band" and nothing
    finer. `Core/Scene.lean::distanceBands` hard-codes the mapping from the
    generator's overridable `DEFAULT_PROXIMITY_THRESHOLDS`.

  * **RESIDUE on the brake light — read the GROUND count, not the verdict.**
    From `carla/schema.json` →
    `partially_available.another_vehicle_braking_or_signalling`: `light_brake`
    is evidence of the *driver's action*, not of the resulting deceleration, and
    it stays `false` if the simulated traffic manager never actuates it. If the
    grounding count on a real capture is healthy but this rule never fires, that
    channel is the reason, not prudent driving. `Following/R0015` is the sibling
    that reads ego speed instead of the lead's light.

  * **`brakeLightOn` is applied to `w`, never to `v`.** `light_brake` exists on
    every vehicle *except* the ego (`carla/schema.json` → `attribute_keys`), the
    ego's braking being published as the `brake` control channel. Applied to the
    ego binder it is silently false and the whole rule becomes vacuously true.

  * **`persistFrames := 6`, and "remain" has no duration in the text.** Six
    frames is 0.3 s at the reference 20 Hz capture rate (`Core/Scene.lean`,
    `captureHz := 20`) — the shortest window that still separates a transient
    compression of the gap from a gap being *held*. Copied from
    `R0014.persistFrames` unchanged, on purpose. Frames carry no timestamp
    (`unavailable.timestamps`) and the rate is a caller-supplied default no
    capture records (`capture_preconditions.capture_rate`), so at 40 Hz these
    six frames are 0.15 s.

  * **The formula is gated on `Pred.isEgo v`.** The statute binds every driver,
    but no proximity or angular edge is ever emitted between two non-ego actors
    (`carla/schema.json` → `relation_coverage`), so a non-ego follower's
    separation from a non-ego lead is unobservable and this antecedent could
    never hold for it. Ungated, the rule would also admit the reversed grounding
    in which the ego is the vehicle *being* followed. This rule makes no claim
    about one non-ego vehicle following another.

  * **Both binders use `proximityVehicleBinder`.** A distance edge *is* required
    here, and the proximity and angular tables cover only the base classes
    `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck`, so a `van` (the
    ambulance among others) carries neither edge and is out of reach for this
    rule exactly as it is for R0014. The exclusion is correct in this node and
    must not be relaxed.

  * **"Following" stays geometric, not intentional.** Two vehicles halted
    nose-to-tail in a queue with the lead's brake light on satisfy the
    antecedent. The lead's speed is unobservable
    (`unavailable.non_ego_dynamics`), so that over-conviction cannot be narrowed
    away here; it is inherited from R0014 and recorded rather than patched.

  * **Shape and trace length.** `□ (¬ₛ .bounded persistFrames forbidden)` — the
    safety shape, "at no position does the forbidden state hold for
    `persistFrames` consecutive frames". `SFProp.frameSpan` is therefore 6, and
    `Core/Semantics.lean::loopBounded` reads a window running off the end of the
    trace as false, so the last 5 frames of any trace are a blind zone and a
    trace shorter than 6 frames reports compliant whatever it contains. Every
    scenario below is 24 frames, and the violating one holds the forbidden state
    from frame 0 through frame 17, well clear of the tail.

  * **Not validated against real data.** The scenarios below were written from
    the same reading of the clause as the formula, so they cannot catch a
    misreading of it. Until `run_spec monitor` has compared this rule against a
    human-labelled capture — and given the false-positive residue above, that
    check matters more here than for R0014 — treat it as unvalidated.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Following.R0024

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The gap this rule treats as imprudent behind a braking lead: ten metres,
    i.e. the band union `safetyHazard` + `nearCollision` + `superNear` +
    `veryNear`. Copied unchanged from `R0014.gapMetres` so that the lane
    requirement is the only difference between the two rules. Written as
    `Pred.withinMetres 10`, never as the band name `.near`, which is 10–16 m. -/
def gapMetres : Nat := 10

/-- How long the ego must hold that gap before it counts as *remaining* there:
    6 frames = 0.3 s at the reference 20 Hz capture rate. Copied unchanged from
    `R0014.persistFrames`. A formalization choice — the clause states no
    duration. -/
def persistFrames : Nat := 6

/-- The prudent-gap limb detected through the **direct** angular edges alone, so
    it survives the lane-node boundary that silences `Pred.followingWithin`.

    `directlyBehind v w ⋀ directlyInFrontOf w v` is the asymmetric pair the
    generator emits for same-direction traffic; it makes the **ego the
    follower**. Inverting the arguments states the opposite situation, which
    this clause does not forbid. -/
def schema : PropertySchema where
  name    := "braking_lead_across_lane_boundary"
  binders := [proximityVehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    -- The forbidden state: the ego v sits directly behind w, inside ten metres,
    -- while w shows a brake light — with no requirement that the graph put the
    -- two in one lane node. `brakeLightOn` is on w; the ego publishes no
    -- `light_brake`.
    □ (¬ₛ (SFProp.bounded persistFrames
             (isEgo v ⋀ directlyBehind v w ⋀ directlyInFrontOf w v
                     ⋀ withinMetres gapMetres v w ⋀ brakeLightOn w)))

def entry : RuleEntry where
  nodeId  := "Following/R0024_braking_lead_across_lane_boundary"
  lawRefs := ["EX-FOLLOW-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

private def egoId       : Nat := 1
private def leadId      : Nat := 2
private def approachId  : Nat := 10
private def junctionLId : Nat := 11
private def opposingId  : Nat := 12
private def roadId      : Nat := 20
private def junRoadId   : Nat := 21
private def junctionId  : Nat := 30

/-- The ego and one other car. `braking` decides whether car_0 carries
    `light_brake = "true"`; when it does not, the attribute is simply absent, as
    it is in a capture where the traffic manager never actuated the light, and
    an absent boolean reads false. -/
private def occupants (braking : Bool) : List Entity :=
  [ mkEgo egoId .car "8.000"
  , if braking then (mkActor leadId "car_0" .car).withAttr "light_brake" "true"
    else mkActor leadId "car_0" .car ]

/-- The approach lane and the ordinary road carrying it. -/
private def approachStructure : List Entity :=
  [ mkLane approachId "Lane 7_-1", mkRoad roadId "Road 7" ]

private def approachStructureRels : List Relation :=
  [ mkRel approachId .isIn roadId ]

/-- The lane node inside the junction, on its own road, plus the junction. A
    separate node from `Lane 7_-1` — which is the point of this rule. -/
private def junctionStructure : List Entity :=
  [ mkLane junctionLId "Lane 100_-1", mkRoad junRoadId "Road 100"
  , mkJunction junctionId "Junction 5" ]

private def junctionStructureRels : List Relation :=
  [ mkRel junctionLId .isIn junRoadId
  , mkRel junRoadId .isIn junctionId
  , mkRel approachId .travelsTo junctionLId ]

/-- The opposing lane beside the approach lane, for the head-on pass. -/
private def opposingStructure : List Entity :=
  [ mkLane opposingId "Lane 7_1" ]

private def opposingStructureRels : List Relation :=
  [ mkRel opposingId .isIn roadId
  , mkRel approachId .opposes opposingId
  , mkRel opposingId .opposes approachId ]

/-- One frame of the boundary case: the ego is still `isIn` the approach lane
    while car_0 has already entered the junction lane, so `Pred.sameLane` is
    false and `Pred.followingWithin` — hence R0003, R0014 and R0015 — cannot
    fire. The angular pair is the one the generator emits for same-direction
    traffic: `ego atDRearOf car_0`, `car_0 inDFrontOf ego`, with one distance
    edge emitted ego-first. -/
private def acrossBoundaryFrame (band : RelLabel) (braking : Bool) : Scene :=
  frame
    (occupants braking ++ approachStructure ++ junctionStructure)
    (approachStructureRels ++ junctionStructureRels ++
      [ mkRel egoId .isIn approachId
      , mkRel leadId .isIn junctionLId
      , mkRel egoId .atDRearOf leadId
      , mkRel leadId .inDFrontOf egoId
      , mkRel egoId band leadId ])

/-- The minimal pair against `acrossBoundaryFrame` on direction: identical
    lanes, identical distance edge, angular edges inverted, so car_0 sits at the
    *ego's* rear and the ego is the vehicle being followed. Distance edge
    car_0-first. -/
private def tailgatedFrame (band : RelLabel) (braking : Bool) : Scene :=
  frame
    (occupants braking ++ approachStructure ++ junctionStructure)
    (approachStructureRels ++ junctionStructureRels ++
      [ mkRel egoId .isIn approachId
      , mkRel leadId .isIn junctionLId
      , mkRel leadId .atDRearOf egoId
      , mkRel egoId .inDFrontOf leadId
      , mkRel leadId band egoId ])

/-- One frame of a head-on pass in adjacent, opposing lanes. Each actor's
    angular edges are computed in its own forward frame, so headings differing
    by more than 90° yield the **mutual** front pattern — `ego inDFrontOf car_0`
    *and* `car_0 inDFrontOf ego` — with no rear edge either way. Close, and the
    other car is braking, but neither vehicle is following the other. -/
private def headOnFrame (band : RelLabel) (braking : Bool) : Scene :=
  frame
    (occupants braking ++ approachStructure ++ opposingStructure)
    (approachStructureRels ++ opposingStructureRels ++
      [ mkRel egoId .isIn approachId
      , mkRel leadId .isIn opposingId
      , mkRel egoId .inDFrontOf leadId
      , mkRel leadId .inDFrontOf egoId
      , mkRel egoId band leadId ])

/-- Twenty-four frames of the case this node exists for: the ego directly behind
    car_0 in the 4–7 m band while the two sit in *different* lane nodes, the
    follower on the approach and the lead already in the junction, car_0's brake
    light on throughout. `sameLane` is false, so R0003, R0014 and R0015 are all
    silent; the band is outside four metres, so R0021 is silent too. The
    forbidden state holds from frame 0 through frame 17 — well past the six-frame
    window and clear of the trailing five-frame blind zone — and the gap then
    opens to 16–25 m for the last six frames. -/
def traceCloseBehindBrakingLeadAcrossBoundary : Trace :=
  List.replicate 18 (acrossBoundaryFrame .superNear true)
    ++ List.replicate 6 (acrossBoundaryFrame .visible true)

/-- The minimal pair on distance: identical entities, lanes, angular edges and
    brake light, with the single distance edge moved to the 16–25 m `.visible`
    band. Twenty-four frames. Also the check that `.near` is read as the far
    band it is rather than as "near" in the English sense — replace
    `withinMetres 10` with a bare `.near` test and the band range this trace
    sits in changes meaning. -/
def traceWideGapBehindBrakingLeadAcrossBoundary : Trace :=
  List.replicate 24 (acrossBoundaryFrame .visible true)

/-- The minimal pair on the evidence channel: the violating trace with
    `light_brake` simply absent from car_0, as it is in any capture where the
    traffic manager never actuated the light. Four to seven metres behind a
    vehicle is close, but this rule's justification for calling it imprudent is
    the lead's observed deceleration, and that evidence is gone. Twenty-four
    frames. -/
def traceCloseBehindLeadNotBraking : Trace :=
  List.replicate 24 (acrossBoundaryFrame .superNear false)

/-- Twenty-four frames of a lawful head-on pass at 4–7 m with car_0's brake
    light on. The mutual front edges mean neither `directlyBehind ego car_0` nor
    the paired front edge in the right orientation holds, so no following
    relationship exists. Reduce the rule to a bare `withinMetres 10` and this
    convicts. -/
def traceHeadOnPassAtFiveMetres : Trace :=
  List.replicate 24 (headOnFrame .superNear true)

/-- Twenty-four frames with car_0 glued to the *ego's* rear at 4–7 m, its own
    brake light on throughout. Someone is following closely behind a braking
    vehicle, but it is car_0, and EX-FOLLOW-001 places the duty on the follower.
    Invert the argument order of the direction test, or drop the `isEgo v` gate,
    and this reports a violation. -/
def traceEgoIsTheLeadBeingTailgated : Trace :=
  List.replicate 24 (tailgatedFrame .superNear true)

def scenarios : List Scenario :=
  [ { name := "close_behind_a_braking_lead_across_the_boundary"
    , trace := traceCloseBehindBrakingLeadAcrossBoundary
    , expected := false }
  , { name := "wide_gap_behind_a_braking_lead_across_the_boundary"
    , trace := traceWideGapBehindBrakingLeadAcrossBoundary
    , expected := true }
  , { name := "close_behind_a_lead_that_is_not_braking"
    , trace := traceCloseBehindLeadNotBraking
    , expected := true }
  , { name := "head_on_pass_at_five_metres"
    , trace := traceHeadOnPassAtFiveMetres
    , expected := true }
  , { name := "ego_is_the_lead_being_tailgated"
    , trace := traceEgoIsTheLeadBeingTailgated
    , expected := true } ]

end TrafficSpec.Rules.Following.R0024
