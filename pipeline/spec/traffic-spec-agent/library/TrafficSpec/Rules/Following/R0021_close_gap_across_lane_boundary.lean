/-
  Rule R0021 — the four-metre bright line, stated without `sameLane`.

  Law text (EX-FOLLOW-001, "Following too closely"):
    "The driver of a motor vehicle shall not follow another vehicle more closely
     than is reasonable and prudent. A vehicle shall not remain within four
     metres of the vehicle it is following."

  SCOPE — THE SECOND SENTENCE, AND A GROUNDING GAP IN HOW IT IS ALREADY STATED
  ----------------------------------------------------------------------------
  This file formalizes the **second** sentence, the four-metre bright line, and
  nothing else; the first sentence's open-textured "reasonable and prudent"
  standard is a separate obligation carried by sibling nodes. It is not a new
  duty. `Following/R0003` already states this exact threshold. This node exists
  because of *where* R0003 goes silent.

  R0003, and both of the prudent-gap rules R0014 and R0015, are built on
  `Pred.followingWithin`, which `Core/Vocab.lean` § 5 defines as
  `sameLane a b ⋀ behind a b ⋀ withinMetres m a b`. The `sameLane` conjunct is a
  single point of failure shared by all three. `process_to_junction_rsv`
  collapses each run of waypoints into **one** lane node, so two vehicles
  nose-to-tail across a lane-node boundary — the follower still on the approach
  lane while the lead has already entered the junction lane, or a pair
  straddling a road boundary — do not share a lane node, `Pred.sameLane` is
  false, and every following rule in this library reports compliant. That is the
  tailgate-up-to-a-junction geometry, which is squarely the conduct the clause
  addresses. This rule restates the same bright line through the angular edges
  alone, so the duty survives the lane-node boundary.

  Formalization notes
  -------------------
  * **"the vehicle it is following" is `Pred.sameHeading w v`, not
    `Pred.sameLane`.** `Core/Vocab.lean` § 5 defines
    `sameHeading a b := inFrontOf a b ⋀ behind b a`, so `sameHeading w v` reads
    "w is in front of v and v is behind w" — **the ego v is the follower**. The
    argument order is the whole content of the rule: `sameHeading v w` is the
    opposite situation, the ego being tailgated, which this clause does not
    forbid. The scenario `ego_is_the_lead` exists to fail if the arguments are
    ever swapped.

    `sameHeading` and not a bare `behind`, and certainly not a bare
    `withinMetres`: it demands the *mutual* pair of edges the generator emits
    for same-direction traffic (one `inDFrontOf`/`inSFrontOf` together with one
    `atDRearOf`/`atSRearOf`), which is asymmetric and therefore names which of
    the two vehicles is the follower. Reduced to `withinMetres 4 v w` alone the
    rule would convict the ego for passing an oncoming vehicle at three metres,
    which is not this clause; `head_on_pass_at_three_metres` fails if that
    happens. `Pred.withinMetres` is symmetric by construction (it checks both
    edge orientations), so its argument order carries no meaning; it is written
    `v w` for readability only.

  * **RESIDUE — this rule is deliberately looser than R0003, and in a direction
    that can only produce false positives.** Dropping `sameLane` trades one
    source of false negatives for one source of false positives: `Pred.behind`
    admits `atSRearOf`, a *side*-rear sector, so a vehicle four metres away in
    an adjacent lane can satisfy `sameHeading` without the ego following it at
    all. The mutual-edge requirement and the tight 4 m band bound the exposure,
    but they do not eliminate it, and the exposure is asymmetric in consequence:
    `scripts/capture_eval.py` marks a law violated if **any** rule covering it
    is violated, so this node can only add recall to EX-FOLLOW-001, and every
    false positive it emits becomes the law's verdict for the whole capture. A
    reviewer who finds this rule over-convicting on real data should narrow the
    orientation test (e.g. `Pred.directlyBehind`/`Pred.directlyInFrontOf`, the
    `.atDRearOf`/`.inDFrontOf` pair only) rather than reinstate `sameLane`,
    which is the conjunct this node exists to avoid.

  * **"remain" is given a persistence window of 4 frames, and that number is
    ours, not the statute's.** The text fixes no duration. `persistFrames := 4`
    is 0.2 s at the reference 20 Hz capture rate (`Core/Scene.lean`,
    `captureHz := 20`) and is deliberately the same number as
    `R0003.persistFrames`, so the two rules differ only in the lane conjunct and
    a discrepancy between their verdicts is attributable to that and nothing
    else. Raise it and a fifth-of-a-second tailgate escapes; lower it to 1 and a
    momentary compression during a cut-in is convicted. Nothing in the law text
    settles it.

  * **The capture rate is an unrecorded assumption.** Frames carry no timestamp
    (`carla/schema.json` → `unavailable.timestamps`), and
    `capture_preconditions.capture_rate` records that 20 Hz is a caller-supplied
    default of the capture script that no capture stores. At 40 Hz these 4
    frames are 0.1 s.

  * **The band-to-metres mapping is likewise unrecorded.** Four metres is the
    band union `safetyHazard` (<2 m) + `nearCollision` (2–4 m), so the threshold
    happens to fall exactly on a band boundary and `Pred.withinMetres 4` is not
    lossy here — a coincidence of this threshold, not a general property. The
    mapping is hard-coded in `Core/Scene.lean::distanceBands` from
    `DEFAULT_PROXIMITY_THRESHOLDS`, an overridable parameter of
    `process_to_junction_rsv` (`capture_preconditions.proximity_band_metres`).
    Inclusive at the boundary: a vehicle at exactly 4.0 m reads `nearCollision`
    and is inside the line.

  * **Ego-only, by the shape of the data.** No proximity or angular edge is ever
    emitted between two non-ego actors (`carla/schema.json` →
    `relation_coverage`), so the rule is gated on `Pred.isEgo v` and makes no
    claim whatever about one non-ego vehicle following another. Ungated it would
    additionally read the reversed grounding as a candidate violation. Both
    binders are `proximityVehicleBinder`, since the proximity and angular tables
    cover only `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck`: a `van` (the
    ambulance, among others) carries neither an angular nor a distance edge and
    is out of reach for this rule exactly as it is for R0003.

  * **"Following" stays a geometric relation, not an intention.** A vehicle that
    has just moved in behind another, and two vehicles halted nose-to-tail in a
    queue, both satisfy it. The lead vehicle's speed is unobservable
    (`unavailable.non_ego_dynamics`), so the stopped-queue over-conviction
    cannot be narrowed away here; it is inherited from R0003 and recorded rather
    than patched.

  * **Shape and trace length.** `□ (¬ₛ .bounded persistFrames tailgating)` — "at
    no position does the forbidden state hold for `persistFrames` consecutive
    frames". `SFProp.frameSpan` is therefore 4, and
    `Core/Semantics.lean::loopBounded` reads a window running off the end of the
    trace as false, so the last 3 frames of any trace are a blind zone and a
    trace shorter than 4 frames reports compliant whatever it contains. Every
    scenario below is 12 frames, and each violating one holds the forbidden
    state from frame 0.

  * **Not validated against real data.** The scenarios were written from the
    same reading of the clause as the formula and cannot catch a misreading of
    it. Until `run_spec monitor` has compared this rule against a human-labelled
    capture — and given the false-positive residue above, that check matters
    more for this rule than for R0003 — treat it as unvalidated.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Following.R0021

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The bright line the second sentence states: four metres. Same threshold as
    `R0003.gapMetres`; this rule differs only in how "following" is detected. -/
def gapMetres : Nat := 4

/-- How long the ego must hold a sub-four-metre gap before it counts as
    "remaining" there. 4 frames = 0.2 s at the reference 20 Hz capture rate,
    deliberately the same number as `R0003.persistFrames`. A formalization
    choice — the statute states no duration. -/
def persistFrames : Nat := 4

/-- The four-metre bright line detected through the angular edges alone, so it
    survives the lane-node boundary that silences `Pred.followingWithin`.

    `sameHeading w v` — w in front of v, v behind w — is what makes the **ego
    the follower**; inverting it states the opposite situation. -/
def schema : PropertySchema where
  name    := "close_gap_across_lane_boundary"
  binders := [proximityVehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    -- The forbidden state: the ego v travels behind w, same direction, inside
    -- four metres — with no requirement that the graph put them in one lane.
    □ (¬ₛ (SFProp.bounded persistFrames
             (isEgo v ⋀ sameHeading w v ⋀ withinMetres gapMetres v w)))

def entry : RuleEntry where
  nodeId  := "Following/R0021_close_gap_across_lane_boundary"
  lawRefs := ["EX-FOLLOW-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

private def egoId       : Nat := 1
private def leadId      : Nat := 2
private def approachId  : Nat := 10
private def junctionLId : Nat := 11
private def adjacentId  : Nat := 12
private def roadId      : Nat := 20
private def junRoadId   : Nat := 21
private def junctionId  : Nat := 30

private def occupants : List Entity :=
  [ mkEgo egoId .car "8.000", mkActor leadId "car_0" .car ]

/-- The approach lane and the ordinary road carrying it. -/
private def approachStructure : List Entity :=
  [ mkLane approachId "Lane 7_-1", mkRoad roadId "Road 7" ]

private def approachStructureRels : List Relation :=
  [ mkRel approachId .isIn roadId ]

/-- The lane node inside the junction, on its own road, plus the junction.
    A separate node from `Lane 7_-1` — which is the point of this rule. -/
private def junctionStructure : List Entity :=
  [ mkLane junctionLId "Lane 100_-1", mkRoad junRoadId "Road 100"
  , mkJunction junctionId "Junction 5" ]

private def junctionStructureRels : List Relation :=
  [ mkRel junctionLId .isIn junRoadId
  , mkRel junRoadId .isIn junctionId
  , mkRel approachId .travelsTo junctionLId ]

/-- The lane beside the approach lane, for the head-on pass. -/
private def adjacentStructure : List Entity :=
  [ mkLane adjacentId "Lane 7_1" ]

private def adjacentStructureRels : List Relation :=
  [ mkRel adjacentId .isIn roadId
  , mkRel approachId .opposes adjacentId
  , mkRel adjacentId .opposes approachId ]

/-- One frame of the boundary case: the ego is still `isIn` the approach lane
    while car_0 has already entered the junction lane, so `Pred.sameLane` is
    false and `Pred.followingWithin` — hence R0003, R0014 and R0015 — cannot
    fire. The angular pair is unchanged: `car_0 inDFrontOf ego`,
    `ego atDRearOf car_0`, with one distance edge emitted ego-first. -/
private def acrossBoundaryFrame (band : RelLabel) : Scene :=
  frame
    (occupants ++ approachStructure ++ junctionStructure)
    (approachStructureRels ++ junctionStructureRels ++
      [ mkRel egoId .isIn approachId
      , mkRel leadId .isIn junctionLId
      , mkRel egoId .atDRearOf leadId
      , mkRel leadId .inDFrontOf egoId
      , mkRel egoId band leadId ])

/-- One frame with both vehicles in the one approach lane, the ego at car_0's
    rear — the ordinary same-lane tailgate that R0003 also sees. -/
private def sameLaneFollowFrame (band : RelLabel) : Scene :=
  frame
    (occupants ++ approachStructure)
    (approachStructureRels ++
      [ mkRel egoId .isIn approachId
      , mkRel leadId .isIn approachId
      , mkRel egoId .atDRearOf leadId
      , mkRel leadId .inDFrontOf egoId
      , mkRel egoId band leadId ])

/-- The minimal pair against `sameLaneFollowFrame`: identical lane, identical
    distance edge, opposite angular edges. The ego is the vehicle being
    followed. -/
private def sameLaneTailgatedFrame (band : RelLabel) : Scene :=
  frame
    (occupants ++ approachStructure)
    (approachStructureRels ++
      [ mkRel egoId .isIn approachId
      , mkRel leadId .isIn approachId
      , mkRel leadId .atDRearOf egoId
      , mkRel egoId .inDFrontOf leadId
      , mkRel egoId band leadId ])

/-- One frame of a head-on pass in adjacent, opposing lanes. Each actor's
    angular edges are computed in its own forward frame, so headings differing
    by more than 90° yield the **mutual** front pattern — `ego inDFrontOf car_0`
    *and* `car_0 inDFrontOf ego` — with no rear edge either way. Close, but no
    following relationship. -/
private def headOnFrame (band : RelLabel) : Scene :=
  frame
    (occupants ++ approachStructure ++ adjacentStructure)
    (approachStructureRels ++ adjacentStructureRels ++
      [ mkRel egoId .isIn approachId
      , mkRel leadId .isIn adjacentId
      , mkRel egoId .inDFrontOf leadId
      , mkRel leadId .inDFrontOf egoId
      , mkRel egoId band leadId ])

private def repeat12 (s : Scene) : Trace := List.replicate 12 s

/-- Twelve frames of the case this node exists for: the ego nose-to-tail with
    car_0 in the 2–4 m band while the two sit in *different* lane nodes, the
    follower on the approach and the lead already in the junction. `sameLane` is
    false throughout, so no `followingWithin`-based rule can convict; the
    forbidden state nevertheless holds from frame 0, well past the four-frame
    window. -/
def traceAcrossBoundary : Trace := repeat12 (acrossBoundaryFrame .nearCollision)

/-- Twelve frames of the ordinary same-lane tailgate under two metres.
    Deliberate overlap with R0003: this rule must still convict the plain case,
    not only the exotic one. -/
def traceSameLaneTailgating : Trace := repeat12 (sameLaneFollowFrame .safetyHazard)

/-- Twelve frames in which car_0 is glued to the *ego's* rear at 2–4 m. Someone
    is tailgating, but it is not the ego, and this clause addresses the
    follower. Write `sameHeading v w` instead of `sameHeading w v`, or drop the
    `isEgo v` gate, and this reports a violation. -/
def traceEgoIsTheLead : Trace := repeat12 (sameLaneTailgatedFrame .nearCollision)

/-- Twelve frames of a head-on pass at three metres. Inside the four-metre band
    on every frame, but the mutual front edges mean `sameHeading` is false and
    neither vehicle is following the other. Reduce the rule to a bare
    `withinMetres 4` and this convicts. -/
def traceHeadOnPass : Trace := repeat12 (headOnFrame .nearCollision)

/-- Twelve frames, one lane, car_0 ahead throughout. The gap sits in the 2–4 m
    band for frames 0–2 and opens to the 7–10 m band for frames 3–11: three
    consecutive offending frames, one short of the four-frame window. The ego
    closed up briefly and dropped back rather than *remaining* within four
    metres. Lower `persistFrames` to 3 and this convicts. -/
def traceBriefApproach : Trace :=
  [ sameLaneFollowFrame .nearCollision
  , sameLaneFollowFrame .nearCollision
  , sameLaneFollowFrame .nearCollision ]
  ++ List.replicate 9 (sameLaneFollowFrame .veryNear)

def scenarios : List Scenario :=
  [ { name := "tailgating_across_a_junction_boundary"
    , trace := traceAcrossBoundary
    , expected := false }
  , { name := "tailgating_within_one_lane"
    , trace := traceSameLaneTailgating
    , expected := false }
  , { name := "ego_is_the_lead"
    , trace := traceEgoIsTheLead
    , expected := true }
  , { name := "head_on_pass_at_three_metres"
    , trace := traceHeadOnPass
    , expected := true }
  , { name := "brief_close_approach_then_falls_back"
    , trace := traceBriefApproach
    , expected := true } ]

end TrafficSpec.Rules.Following.R0021
