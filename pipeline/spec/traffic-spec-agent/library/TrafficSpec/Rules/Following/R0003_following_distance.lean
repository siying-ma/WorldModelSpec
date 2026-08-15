/-
  Rule R0003 — following distance.

  Law text (laws/example/laws.jsonl, id EX-FOLLOW-001, "Following too closely"):
    "The driver of a motor vehicle shall not follow another vehicle more
     closely than is reasonable and prudent. A vehicle shall not remain
     within four metres of the vehicle it is following."

  SCOPE. This rule formalizes the **second sentence only** — the four-metre
  bright line. The first sentence ("more closely than is reasonable and
  prudent") is a separate obligation, an open-textured standard with no metric
  threshold, and is formalized separately as
  `Following/R0010_prudent_gap_when_lead_brakes`. Do not read this file as the
  whole of EX-FOLLOW-001: satisfying the bright line does not discharge the
  reasonable-and-prudent duty.

  Formalization notes
  -------------------
  * "within four metres" is the union of the `safetyHazard` (<2 m) and
    `nearCollision` (2–4 m) proximity bands, which is exactly what
    `Pred.withinMetres 4` computes. Writing `rel v .near w` instead would mean
    the 10–16 m band — the second *farthest* — and would invert the rule.
  * "the vehicle it is following" is same-lane occupancy with the follower at the
    rear: `Pred.following v w` = `sameLane v w ⋀ behind v w`. The relation
    direction reads "src is ⟨rel⟩ tgt" (`Core/Vocab.lean` §5), so
    `behind v w` says **v** is behind **w** and therefore **v is the follower**.
    Swapping the arguments would convict the vehicle *being* followed; the
    `being_tailgated_is_not_a_violation` scenario is the test for that.
  * The antecedent is gated on `Pred.isEgo v`. Two reasons, one legal and one
    about the data. Legally, the obligation falls on the driver of the following
    vehicle, and the ego vehicle is the only driver this specification speaks
    about. In the data, proximity and angular edges are only ever emitted between
    the ego and another actor, so an ungated rule would read the ego's own
    proximity edge in the `v = car_0, w = ego` grounding and convict the ego of
    another car's tailgating.
  * `w` is bound with `proximityVehicleBinder`, not `vehicleBinder`: the
    generator emits proximity and angular edges only for the base classes
    `person` / `bicycle` / `car` / `motorcycle` / `bus` / `truck`, so a `van`
    (CARLA's ambulance) or a bare `vehicle` would ground into an antecedent that
    can never fire, inflating the grounding count without testing anything.
    A van tailgated by the ego is therefore outside what this rule can observe —
    a data limitation, not a reading of the statute.
  * **"Remain" is a persistence threshold the text does not state.** Traffic
    legitimately compresses — a single frame inside four metres during braking or
    at a junction is not "remaining". This rule reads "remain" as the condition
    holding for **4 consecutive frames**, i.e. **0.2 s at the 20 Hz reference
    capture rate** (0.05 s per frame; frames carry no timestamp, so a duration
    can only be a frame count). Nothing in the statute fixes this number: 4 is a
    choice made to separate a momentary compression from a sustained one, and a
    reviewer who thinks the line belongs elsewhere should change the `4` in
    `persistFrames` and nothing else. Any value from 3 to 8 agrees with the
    declared scenarios, so the scenarios do not pin it down either.
  * `□ ¬ₛ (.bounded n φ)` reads: at no position of the trace does φ hold for `n`
    consecutive frames. `bounded` has strong-next semantics, so a window that
    runs off the end of the trace is false — a trace shorter than `n` frames can
    never violate this rule.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Following.R0003

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The persistence window for "remain": 4 frames = 0.2 s at 20 Hz. A
    formalization choice, not something the law text states. -/
def persistFrames : Nat := 4

/-- The ego vehicle `v` is following `w` in the same lane, within four metres. -/
def tailgating (v w : EntityId) : SFProp :=
  isEgo v ⋀ followingWithin 4 v w

/-- The rule, quantified over ordered pairs of vehicles: at no point does the
    ego remain within four metres of the vehicle it is following. -/
def schema : PropertySchema where
  name    := "following_distance_four_metres"
  binders := [vehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    □ (¬ₛ (.bounded persistFrames (tailgating v w)))

def entry : RuleEntry where
  nodeId  := "Following/R0003_following_distance"
  lawRefs := ["EX-FOLLOW-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

/-- Road structure shared by every scenario trace: one lane inside one road, so
    `sameLane` holds for both vehicles throughout. -/
private def lane : Nat := 10
private def road : Nat := 20

private def structureEntities : List Entity :=
  [mkLane lane "Lane 7_-1", mkRoad road "Road 7"]

private def structureRels : List Relation :=
  [mkRel lane .isIn road]

/-- Ego (id 1) and `car_0` (id 2), both in the shared lane. -/
private def actors : List Entity :=
  [mkEgo 1 .car "9.0" "0.0" "0.3" "0.0", mkActor 2 "car_0" .car]

private def laneRels : List Relation :=
  structureRels ++ [mkRel 1 .isIn lane, mkRel 2 .isIn lane]

/-- One frame with the ego following `car_0` at proximity `band`: ego at the rear
    of `car_0`, `car_0` directly ahead of the ego. -/
private def egoFollows (band : RelLabel) : Scene :=
  frame (actors ++ structureEntities)
    (laneRels ++ [ mkRel 1 band 2, mkRel 1 .atDRearOf 2, mkRel 2 .inDFrontOf 1 ])

/-- One frame with the roles reversed: `car_0` at the rear of the ego at
    proximity `band`, ego directly ahead. The ego is the vehicle *being*
    followed. -/
private def egoIsFollowed (band : RelLabel) : Scene :=
  frame (actors ++ structureEntities)
    (laneRels ++ [ mkRel 2 band 1, mkRel 2 .atDRearOf 1, mkRel 1 .inDFrontOf 2 ])

/-- Eight frames in the `near` band (10–16 m): never inside four metres. -/
def traceSteadyGap : Trace :=
  [ egoFollows .near, egoFollows .near, egoFollows .near, egoFollows .near
  , egoFollows .near, egoFollows .near, egoFollows .near, egoFollows .near ]

/-- Eight frames, mostly `superNear` (4–7 m) or `near`, dipping into
    `nearCollision` (2–4 m) for exactly two consecutive frames in the middle and
    then opening up again. A momentary compression is not remaining. -/
def traceTransientClosure : Trace :=
  [ egoFollows .near
  , egoFollows .superNear
  , egoFollows .superNear
  , egoFollows .nearCollision
  , egoFollows .nearCollision
  , egoFollows .superNear
  , egoFollows .superNear
  , egoFollows .near ]

/-- Eight frames with `car_0` sitting within two metres of the ego's rear
    (`safetyHazard`). The ego is being tailgated, not tailgating; the ego driver
    breaks nothing. This trace fails if the relation direction is inverted or the
    `isEgo` gate is dropped. -/
def traceBeingTailgated : Trace :=
  [ egoIsFollowed .safetyHazard, egoIsFollowed .safetyHazard
  , egoIsFollowed .safetyHazard, egoIsFollowed .safetyHazard
  , egoIsFollowed .safetyHazard, egoIsFollowed .safetyHazard
  , egoIsFollowed .safetyHazard, egoIsFollowed .safetyHazard ]

/-- Eight frames with the ego inside four metres of the vehicle it is following
    for all eight — remaining within four metres, a violation. -/
def traceSustainedTailgating : Trace :=
  [ egoFollows .nearCollision, egoFollows .nearCollision
  , egoFollows .safetyHazard,  egoFollows .safetyHazard
  , egoFollows .nearCollision, egoFollows .safetyHazard
  , egoFollows .nearCollision, egoFollows .nearCollision ]

def scenarios : List Scenario :=
  [ { name := "steady_gap_allowed",
      trace := traceSteadyGap,            expected := true }
  , { name := "transient_closure_allowed",
      trace := traceTransientClosure,     expected := true }
  , { name := "being_tailgated_is_not_a_violation",
      trace := traceBeingTailgated,       expected := true }
  , { name := "sustained_tailgating_violates",
      trace := traceSustainedTailgating,  expected := false } ]

end TrafficSpec.Rules.Following.R0003
