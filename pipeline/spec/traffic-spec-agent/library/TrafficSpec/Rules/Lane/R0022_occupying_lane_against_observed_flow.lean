/-
  Rule R0022 — occupying a lane against a flow of traffic established by
  ANOTHER vehicle's observed progression along that lane's own connectivity.

  Law text (EX-LANE-001, "Driving on the right"):
    "A vehicle shall be driven upon the right half of the roadway, except when
     overtaking. A vehicle shall not occupy a lane that opposes the flow of
     traffic while another vehicle is approaching in that lane."

  SCOPE — SECOND SENTENCE ONLY
  ---------------------------
  This file formalizes the **second** sentence of EX-LANE-001 and nothing else.
  The keep-right obligation of the first sentence and its overtaking exception
  are `Lane/R0008_keep_right_of_roadway`. A trace this rule reports compliant
  may still violate the first sentence, and vice versa; an application enforcing
  the clause must register both.

  WHY A FOURTH DETECTOR FOR THIS SENTENCE, AND WHAT IT SEES
  --------------------------------------------------------
  `Lane/R0016_crossing_into_opposing_lane` and
  `Lane/R0017_wrong_way_progress_with_oncoming` both formalize this sentence,
  and both need **the ego to move**: R0016 needs the crossing frame to fall
  inside the capture window, R0017 needs the ego to change lane *node* against
  the `travelsTo` connectivity. `process_to_junction_rsv` collapses each
  waypoint run into a single lane node per road-and-lane-id, so an ego that is
  already established the wrong way when the capture opens, or that holds one
  lane node for the whole encounter, is invisible to both — and "already in the
  wrong lane, holding it" is the ordinary shape of the offence.

  This rule moves the evidential burden onto the OTHER vehicle. If a vehicle
  shares the ego's lane node and is observed moving **with** that lane's
  direction of travel while coming at the ego head-on, then the lane's flow is
  established independently of anything the ego does, and the ego is the vehicle
  opposing it. Nothing about the ego's own motion is required. The three rules
  are complementary, not redundant, and a compliant verdict from any one of them
  is not evidence that the ego was travelling with the flow.

  Formalization notes — choices the text did not dictate
  -----------------------------------------------------
  * **THE DIRECTION OF `laneTravelsTo` IS THE WHOLE RULE, AND IT IS THE
    OPPOSITE OF R0017'S.** `Pred.laneTravelsTo l₁ l₂` is the edge
    `l₁ --travelsTo--> l₂`: traffic in `l₁` flows onward into `l₂`. Here `w`
    goes `lNow → lNext` while `lNow travelsTo lNext`, so **`w` moves WITH the
    flow** and the ego, sharing `lNow` and facing `w`, is the one opposing it.
    R0017 writes `laneTravelsTo lNext lNow` because there it is the *ego* whose
    progression runs against the edge. Inverting this conjunct turns this rule
    into a duplicate of R0017 with the wrong binder, and
    `victim_of_a_wrong_way_vehicle` below is the regression test that fails the
    moment the arguments are swapped.

  * **`Pred.oncoming` is symmetric, so it can never by itself name the
    offender.** `oncoming a b` is `inFrontOf a b ⋀ inFrontOf b a`; each angular
    edge is computed in the source actor's forward frame, so a mutual
    front-edge pair means only that the two headings differ by more than 90° —
    that the pair is converging, not which of the two is misplaced. A rule
    written as `□ ¬ₛ (oncoming v w ⋀ sameLane v w)` convicts the *lawful*
    driver into whose lane a wrong-way vehicle has strayed. That is the
    `Lane/R0009` failure mode: it passed every scenario its own author wrote and
    then convicted 50 frames of compliant driving on the bundled capture. All of
    the asymmetry in this rule comes from attaching the with-the-flow evidence
    to `w` and never to `v`.

  * **"while another vehicle is approaching in that lane" is read as
    `oncoming v w` together with both vehicles in the same lane node at the
    observation frame, with NO distance threshold and NO closing sequence.**
    The statute states no separation and the abstraction has none to offer:
    `carla/schema.json` → `unavailable.exact_distance` records that
    `process_to_junction_rsv` copies no metric distance off the edges, only a
    band label. Render distance (50 m by default) is therefore the de facto
    bound, and that is a capture parameter, not a legal one. A consequence of
    the single-frame reading is that a *stationary* head-on vehicle in the lane
    also counts as "approaching"; that is the wider reading and it is
    deliberate, since the statute conditions the offence on another vehicle
    being in the lane coming the other way and a stopped one is at least as much
    at risk.

  * **The shared-lane conjunct is `inLane v lNow ⋀ inLane w lNow`, not
    `sameLane v w`.** The rule must name the *same* lane node that carries the
    connectivity edge, otherwise a vehicle sharing some other lane with the ego
    could supply the flow evidence for a lane it is not in.
    `oncoming_traffic_in_the_adjacent_opposing_lane` is the regression test for
    dropping `inLane w lNow`, and it is the situation that makes up most of any
    real capture — ordinary two-way traffic must not be convicted.

  * **No persistence window, and that is a choice, not an oversight.** The
    evidence is a single lane-node transition by `w`, so `SFProp.frameSpan` is 2
    (the observation position plus one `◯`). R0017 is built the same way. The
    cost is residue (4) below: one frame of graph artefact convicts. A reviewer
    who disagrees can wrap the consequent in `SFProp.bounded`, at most 6 frames
    given the 12-frame scenario traces, since a window overrunning the trace
    silently reports compliant (`Core/Semantics.lean::loopBounded`).

  * **`Pred.isEgo v` gates the formula: a data restriction, not a reading of the
    statute.** The clause binds every driver. But lane membership and the
    angular edges are reliable only for the ego —
    `carla/schema.json` → `partially_available.wrong_way_driving` (residue on
    route 2) and `relation_coverage`. This rule therefore makes no claim about a
    non-ego vehicle occupying a lane against the flow; `w`'s lane membership is
    used, but `w` is never convicted.

  * **The lane-id sign predicates appear nowhere in this file.**
    `Pred.laneRightOfReference`, `laneLeftOfReference`,
    `inLaneRightOfReference` and `inLaneLeftOfReference` read which side of the
    OpenDRIVE reference line a lane was *authored* on — a map convention, not a
    direction of travel, since every lane of one direction shares the sign. The
    deleted `Lane/R0009` decided this same sentence that way and convicted
    lawful driving. Direction here is read only off the `travelsTo` edge, which
    is a statement about the flow of traffic.

  * **Binder choices.** `v` and `w` are `proximityVehicleBinder`: `oncoming`
    needs angular edges, which the generator emits only for the base classes
    `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck`, so a `vehicleBinder`
    would admit `van` and the abstract `vehicle` type and manufacture groundings
    that can never fire. `lNow` and `lNext` are `laneBinder`, and they are
    distinct entities by construction because `Grounding.distinctIds` drops any
    binding that repeats an id — which is also why `travelsTo` need never be
    excluded as a self-edge. Scenario lane nodes carry distinct names because
    `carla/adapter.py` keys entities by name and two same-named nodes collapse
    into one entity.

  Residue — what this rule cannot see, and what it assumes
  -------------------------------------------------------
  1. **It needs `w` to cross a lane-node boundary during the encounter.** Lane
     nodes are whole collapsed waypoint runs, so a head-on pair that both sit
     inside a single lane node for the entire capture is invisible to this rule
     — and to every other rule in the library, since R0016 needs a crossing and
     R0017 needs an ego lane-node change. No vocabulary available today closes
     that gap. It is recorded as the scenario
     `head_on_but_nobody_crosses_a_lane_boundary`, expected *compliant*, so the
     blind spot is visible in the test set rather than assumed away.
  2. **An approaching van is invisible.** `Pred.oncoming` rests on the angular
     edges, which the generator emits only between the ego and a
     `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck`
     (`carla/schema.json` → `relation_coverage`). CARLA's ambulance is
     `vehicle.ford.ambulance`, base class **van**, so this rule — exactly like
     R0016 and R0017 — cannot see an ambulance or a delivery van coming head-on.
  3. **The 90° heading split behind `Pred.oncoming` is a capture
     precondition.** It is `DEFAULT_DIRECTIONAL_THRESHOLDS` (45/90/135), an
     overridable parameter of the generator that no frame records, so nothing
     downstream can confirm the capture this rule is judged on used it.
  4. **One frame of evidence convicts.** With no persistence window, a
     single-frame graph artefact — a spurious angular edge, or a one-frame
     flicker of `w`'s lane membership — produces a violation. This matches
     R0017 and is the deliberate choice recorded above.
  5. **Not validated against real data.** The scenarios below were written from
     the same reading of the clause as the formula, so they cannot catch a
     misreading of it. `run_spec monitor` against a human-labelled capture is
     the only independent check; until then treat this rule as unvalidated.
     What the scenarios *do* catch is the three ways this construction goes
     wrong: inverting or dropping `laneTravelsTo`
     (`victim_of_a_wrong_way_vehicle`), dropping `oncoming`
     (`lawful_pair_travelling_together`), and dropping either the shared-lane
     conjunct (`oncoming_traffic_in_the_adjacent_opposing_lane`) or the
     with-the-flow conjunct (`head_on_but_nobody_crosses_a_lane_boundary`).
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Lane.R0022

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- Quantified over the ego vehicle, the vehicle coming head-on, the lane both
    occupy at the observation frame, and the lane the other vehicle moves into
    on the next frame. -/
def schema : PropertySchema where
  name    := "occupying_lane_against_observed_flow"
  binders := [ proximityVehicleBinder "v", proximityVehicleBinder "w"
             , laneBinder "lNow", laneBinder "lNext" ]
  formula := fun env =>
    let v     := arg env 0
    let w     := arg env 1
    let lNow  := arg env 2
    let lNext := arg env 3
    -- "the ego occupies `lNow`; `w` is in `lNow` too and coming head-on; on the
    --  next frame `w` is in `lNext`, and traffic in `lNow` flows onward into
    --  `lNext` — so `w` moves WITH the lane and the ego opposes it."
    □ (¬ₛ ( isEgo v
          ⋀ inLane v lNow
          ⋀ inLane w lNow
          ⋀ oncoming v w
          ⋀ ◯ (inLane w lNext)
          ⋀ laneTravelsTo lNow lNext ))

def entry : RuleEntry where
  nodeId  := "Lane/R0022_occupying_lane_against_observed_flow"
  lawRefs := ["EX-LANE-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- One route, taken as a two-way road. `Lane 9_-1` (of `Road 9`) is LANE A and
-- `Lane 12_-1` (of `Road 12`) is LANE B, joined by the single connectivity edge
-- `A --travelsTo--> B`, present in EVERY frame of EVERY trace including the
-- compliant ones, so that no scenario passes merely because the structure was
-- missing. Travelling with the flow of lane A means moving A → B.
--
-- The opposing-carriageway scenario adds LANE C (`Lane 9_1`, the other side of
-- `Road 9`: mutual `toLeftOf` with A plus an `opposes` edge, which is how the
-- generator renders two lanes of opposite direction) and its downstream
-- neighbour LANE D (`Lane 5_1`), with `C --travelsTo--> D`.
--
-- Only the stated `travelsTo` edges are emitted, each in one direction: the
-- generator's `travelsTo` records the direction of travel, and a lane node
-- carrying traffic both ways would not be a wrong-way test at all.
--
-- Every trace is 12 frames. `SFProp.frameSpan` is 2, so the last frame is the
-- only blind position, and every scenario's decisive frame is far from it.
----------------------------------------------------------------------

private def egoId   : Nat := 1
private def carId   : Nat := 2
private def laneAId : Nat := 10
private def laneBId : Nat := 11
private def laneCId : Nat := 12
private def laneDId : Nat := 13
private def roadAId : Nat := 20
private def roadBId : Nat := 21
private def roadDId : Nat := 22

private def oneWayEntities : List Entity :=
  [ mkEgo egoId .car "8.000"
  , mkActor carId "car_0" .car
  , mkLane laneAId "Lane 9_-1"
  , mkLane laneBId "Lane 12_-1"
  , mkRoad roadAId "Road 9"
  , mkRoad roadBId "Road 12" ]

private def oneWayStructure : List Relation :=
  [ mkRel laneAId .isIn roadAId
  , mkRel laneBId .isIn roadBId
  , mkRel laneAId .travelsTo laneBId ]

private def twoWayEntities : List Entity :=
  oneWayEntities
    ++ [ mkLane laneCId "Lane 9_1"
       , mkLane laneDId "Lane 5_1"
       , mkRoad roadDId "Road 5" ]

/-- Lane C is the opposite carriageway of Road 9: the MUTUAL `toLeftOf` pattern
    (each edge computed in the target lane's own forward frame, so mutual means
    opposite directions of travel) plus the explicit `opposes` edge. -/
private def twoWayStructure : List Relation :=
  oneWayStructure
    ++ [ mkRel laneCId .isIn roadAId
       , mkRel laneDId .isIn roadDId
       , mkRel laneCId .travelsTo laneDId
       , mkRel laneAId .opposes laneCId
       , mkRel laneCId .opposes laneAId
       , mkRel laneAId .toLeftOf laneCId
       , mkRel laneCId .toLeftOf laneAId ]

/-- One frame on the one-way structure: the ego in `egoLane`, `car_0` in
    `carLane`, plus the angular and proximity edges of the situation. -/
private def mkFrame (egoLane carLane : Nat) (edges : List Relation) : Scene :=
  frame oneWayEntities
    (oneWayStructure
      ++ [ mkRel egoId .isIn egoLane, mkRel carId .isIn carLane ]
      ++ edges)

/-- The same, on the structure that also carries the opposing carriageway. -/
private def mkFrame2 (egoLane carLane : Nat) (edges : List Relation) : Scene :=
  frame twoWayEntities
    (twoWayStructure
      ++ [ mkRel egoId .isIn egoLane, mkRel carId .isIn carLane ]
      ++ edges)

/-- Converging head-on: the MUTUAL front-edge pair the generator renders when
    two headings differ by more than 90°. `Pred.oncoming` holds. -/
private def headOnAt (band : RelLabel) : List Relation :=
  [ mkRel egoId .inDFrontOf carId
  , mkRel carId .inDFrontOf egoId
  , mkRel egoId band carId ]

/-- Same direction of travel, `car_0` ahead of the ego: the ASYMMETRIC pattern
    — one front edge and one rear edge. `Pred.oncoming` is false. -/
private def trailingAt (band : RelLabel) : List Relation :=
  [ mkRel carId .inDFrontOf egoId
  , mkRel egoId .atDRearOf carId
  , mkRel egoId band carId ]

/-- The pair has passed each other and is separating: still opposite headings,
    so each now sees the other at its rear. `Pred.oncoming` is false. -/
private def separatingAt (band : RelLabel) : List Relation :=
  [ mkRel egoId .atDRearOf carId
  , mkRel carId .atDRearOf egoId
  , mkRel egoId band carId ]

----------------------------------------------------------------------
-- 1. The offence: the ego holds lane A while traffic flows past it
----------------------------------------------------------------------

/-- Twelve frames. The ego is in lane A for the WHOLE trace and never changes
    lane node, so R0016 and R0017 are both blind to it. `car_0` is in lane A for
    frames 0–5 and in lane B for frames 6–11, i.e. it moves the way lane A's
    `travelsTo` edge points. While both are in lane A the pair carries the
    mutual head-on pattern and a `near` band; after `car_0` has passed, the two
    separate.

    The forbidden pattern is observed at frame 5, with its `◯` conjunct at
    frame 6: both are in lane A, coming head-on, and on the next frame `car_0`
    is in lane B — downstream of A. The flow of lane A is thereby established
    without reference to anything the ego did, and the ego is the vehicle
    opposing it. -/
def traceEgoHoldsLaneAgainstFlow : Trace :=
  List.replicate 6 (mkFrame laneAId laneAId (headOnAt .near))
    ++ List.replicate 6 (mkFrame laneAId laneBId (separatingAt .near))

----------------------------------------------------------------------
-- 2. The mirror image: the ego is the VICTIM
----------------------------------------------------------------------

/-- Twelve frames, the exact mirror of scenario 1 and the discriminator this
    rule exists to pass. The EGO moves with the flow — lane A for frames 0–5,
    lane B for frames 6–11 — while `car_0` sits in lane A for the whole trace
    and never changes lane node. The head-on angular edges and the `near` band
    are identical to scenario 1.

    `Pred.oncoming` is symmetric, so a rule that read the sentence off the
    heading pair alone would convict the lawful driver here. It must not: the
    with-the-flow evidence attaches to `w`, and `car_0` never moves between lane
    nodes, so no `lNext` satisfies `◯ (inLane w lNext)` with
    `laneTravelsTo lNow lNext`. THIS SCENARIO FAILS if the arguments of
    `laneTravelsTo` are inverted, or if the conjunct is dropped, or if the
    with-the-flow evidence is ever attached to `v`. The offender here is
    `car_0`, and this rule does not convict it — residue on `isEgo` above. -/
def traceVictimOfWrongWayVehicle : Trace :=
  List.replicate 6 (mkFrame laneAId laneAId (headOnAt .near))
    ++ List.replicate 6 (mkFrame laneBId laneAId (separatingAt .near))

----------------------------------------------------------------------
-- 3. Minimal pair against scenario 1: same lane motion, same headings
----------------------------------------------------------------------

/-- Twelve frames. The ego is in lane A throughout and `car_0` is in lane A for
    frames 0–5 and lane B for frames 6–11 — exactly the lane motion of
    scenario 1. The only difference is the angular pattern: same-direction
    traffic, so `car_0 inDFrontOf ego` with `ego atDRearOf car_0` (asymmetric),
    never mutual, and `Pred.oncoming` is false throughout.

    A vehicle moving with the flow in the ego's lane is simply traffic ahead;
    the second sentence conditions the offence on one *approaching*. Drop the
    `oncoming` conjunct and this scenario convicts. -/
def traceLawfulPairTravellingTogether : Trace :=
  List.replicate 6 (mkFrame laneAId laneAId (trailingAt .near))
    ++ List.replicate 6 (mkFrame laneAId laneBId (trailingAt .near))

----------------------------------------------------------------------
-- 4. Ordinary two-way driving
----------------------------------------------------------------------

/-- Twelve frames of the case that makes up most of any real capture. The ego is
    in lane A throughout; `car_0` comes the other way down the opposing
    carriageway — lane C for frames 0–5, lane D for frames 6–11 — with mutual
    head-on angular edges and a `near` band the whole time.

    `car_0` does move with the flow of the lane it is in, and it is coming
    head-on, but it is never in the ego's lane node, so the antecedent must not
    fire. Drop `inLane w lNow` and this scenario convicts every lawful driver on
    a two-way road. -/
def traceOncomingInAdjacentOpposingLane : Trace :=
  List.replicate 6 (mkFrame2 laneAId laneCId (headOnAt .near))
    ++ List.replicate 6 (mkFrame2 laneAId laneDId (headOnAt .near))

----------------------------------------------------------------------
-- 5. The rule's own blind spot, recorded as a test
----------------------------------------------------------------------

/-- Twelve frames. Both vehicles are in lane A for the whole trace, head-on,
    with a `near` band, and lane A still `travelsTo` lane B. One of the two is
    driving the wrong way — but neither crosses a lane-node boundary, so nothing
    in the graph says which, and this rule reports COMPLIANT.

    That is residue (1) above, written down as a scenario so the blind spot is
    visible in the test set rather than assumed away. It also guards the
    with-the-flow conjunct: drop `◯ (inLane w lNext)` and this scenario
    convicts, which would make the rule symmetric again and reintroduce the
    `Lane/R0009` failure mode. -/
def traceHeadOnNobodyCrossesBoundary : Trace :=
  List.replicate 12 (mkFrame laneAId laneAId (headOnAt .near))

def scenarios : List Scenario :=
  [ { name := "ego_holds_the_lane_while_traffic_flows_past"
    , trace := traceEgoHoldsLaneAgainstFlow
    , expected := false }
  , { name := "victim_of_a_wrong_way_vehicle"
    , trace := traceVictimOfWrongWayVehicle
    , expected := true }
  , { name := "lawful_pair_travelling_together"
    , trace := traceLawfulPairTravellingTogether
    , expected := true }
  , { name := "oncoming_traffic_in_the_adjacent_opposing_lane"
    , trace := traceOncomingInAdjacentOpposingLane
    , expected := true }
  , { name := "head_on_but_nobody_crosses_a_lane_boundary"
    , trace := traceHeadOnNobodyCrossesBoundary
    , expected := true } ]

end TrafficSpec.Rules.Lane.R0022
