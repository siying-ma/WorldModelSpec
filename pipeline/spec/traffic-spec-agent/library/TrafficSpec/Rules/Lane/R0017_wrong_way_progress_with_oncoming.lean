/-
  Rule R0017 — progressing against the lane's own direction of travel while a
  vehicle is approaching head-on in the lane occupied.

  Law text (EX-LANE-001, "Driving on the right"):
    "A vehicle shall be driven upon the right half of the roadway, except when
     overtaking. A vehicle shall not occupy a lane that opposes the flow of
     traffic while another vehicle is approaching in that lane."

  SCOPE — THIS FILE IS ONLY THE SECOND SENTENCE, AND ONLY ITS CONNECTIVITY ROUTE
  -----------------------------------------------------------------------------
  This rule formalizes the **second** sentence of EX-LANE-001 and nothing else.
  The first sentence — the keep-right obligation and its overtaking exception —
  is `Lane/R0008_keep_right_of_roadway`. A trace this rule reports as compliant
  may still violate the first sentence, and vice versa; a monitoring application
  must register both to enforce the clause.

  WHY THIS EXISTS ALONGSIDE `Lane/R0016_crossing_into_opposing_lane`
  -----------------------------------------------------------------
  Both nodes formalize the same sentence and neither subsumes the other; they
  are the two routes `carla/schema.json` → `partially_available.wrong_way_driving`
  lists, applied to different observable events.

  * `R0016` reads opposition **between two lanes** (`opposes` / the mutual
    `toLeftOf` pattern) and needs the frame in which the ego *crossed over* to
    be inside the capture window. It is blind to a capture that opens with the
    ego already established in the opposing lane.
  * This rule reads direction off **lane connectivity over time**: the ego moves
    from lane node `lNow` to lane node `lNext` while the graph says traffic
    flows from `lNext` towards `lNow`. No crossing frame is needed, so sustained
    wrong-way driving is convicted at every lane-node boundary it passes. It is
    in turn blind to a wrong-way run that never leaves a single lane node.

  A single wrong-way run may therefore be convicted by both rules, and a
  compliant verdict from either one is not evidence that the ego was travelling
  with the flow.

  Formalization notes
  -------------------
  * **THE DIRECTION OF `laneTravelsTo` IS THE WHOLE RULE. READ IT CAREFULLY.**
    `Pred.laneTravelsTo l₁ l₂` is the edge `l₁ --travelsTo--> l₂`: traffic flows
    *from* `l₁` *into* `l₂`. The forbidden pattern uses
    `laneTravelsTo lNext lNow` — flow runs from the lane the ego is moving
    **into** towards the lane it is **leaving**, so the ego is moving against
    it. Writing `laneTravelsTo lNow lNext` instead describes exactly lawful
    progression and would convict every driver on the road. That inversion is
    not a subtle degradation, it is a total one, and the two positive scenarios
    below are its regression tests: `with_flow_progress_with_oncoming` fails
    the moment the arguments are swapped.

  * **"while another vehicle is approaching in that lane" is read as
    `oncoming v w ⋀ sameLane v w` at the transition frame, with NO distance
    requirement and NO closing sequence.** `Pred.oncoming` is
    `inFrontOf a b ⋀ inFrontOf b a`: each angular edge is computed in the source
    actor's forward frame, so a mutual front-edge pair means the two headings
    differ by more than 90° — the pair is converging. Residue (c): because this
    is a single-frame test rather than a sequence of tightening bands, a
    *stationary* head-on vehicle in the lane also counts as "approaching". That
    is the wider reading, and it is deliberate: the statute conditions the
    offence on another vehicle being in the lane coming the other way, and a
    stopped one is at least as much at risk. No band threshold is imposed
    because the statute states no separation and the abstraction has none to
    offer — `carla/schema.json` → `unavailable.exact_distance` records that
    `process_to_junction_rsv` copies no metric distance. Render distance (50 m
    by default) is the de facto bound, and that is a capture parameter, not a
    legal one.

  * **`Pred.oncoming` is symmetric, so it cannot by itself say who is in the
    wrong lane.** A rule written as `□ ¬ₛ (oncoming v w ⋀ sameLane v w)` would
    convict the *lawful* driver into whose lane a wrong-way vehicle has
    strayed — the `Lane/R0009` failure mode, which passed every scenario its own
    author wrote and then convicted 50 frames of compliant driving on a real
    capture. The asymmetry here is supplied entirely by the connectivity
    conjunct: only the vehicle whose own lane-node progression runs against the
    `travelsTo` edge is convicted. `victim_of_wrong_way_intruder` below is the
    regression scenario — 40 frames of someone driving head-on at the ego in the
    ego's own lane, expected verdict *compliant*, because the offender is not
    the ego.

  * **No persistence window, and that is a choice.** The forbidden pattern is a
    single lane-node transition, so `SFProp.frameSpan` is 2 (the position plus
    one `◯`). Unlike `R0016`, which needs a dwell to distinguish a genuine
    incursion from the transient overlap the graph renders during any lane
    change, a transition *against* the connectivity edge is not something a
    lawful manoeuvre produces even momentarily, and residue (a) below already
    makes the event coarse. A reviewer who disagrees can wrap the consequent in
    `SFProp.bounded`; at most 20 frames, since the scenario traces are 40 and a
    window that overruns the trace silently reports compliant
    (`Core/Semantics.lean::loopBounded`).

  * **Residue (a): a lane-node transition is a coarse event.**
    `process_to_junction_rsv` collapses each waypoint run into one lane node per
    road-and-lane-id, so the ego changes lane node only at a road boundary. A
    short wrong-way excursion that begins and ends inside one lane node is
    invisible to this rule. This is the mirror image of `R0016`'s blind spot,
    not a redundancy with it.

  * **Residue (b): `Pred.isEgo v` gates the formula, and that is a data
    restriction, not a reading of the statute.** The clause binds every driver.
    But the connectivity test needs the vehicle's lane membership on two
    consecutive frames, and `carla/schema.json` →
    `partially_available.wrong_way_driving` records (residue on route 2) that
    only the ego reliably carries it. `oncoming` compounds this: angular edges
    exist only between the ego and another actor (`relation_coverage`). This
    rule therefore makes no claim about a non-ego wrong-way driver — see
    `victim_of_wrong_way_intruder`, where the offender goes unconvicted for
    exactly this reason.

  * **The lane-id sign predicates appear nowhere in this file.**
    `Pred.laneRightOfReference`, `laneLeftOfReference`,
    `inLaneRightOfReference` and `inLaneLeftOfReference` read which side of the
    OpenDRIVE reference line a lane was *authored* on — a map convention, not a
    direction of travel, since every lane of one direction shares the sign. The
    deleted `Lane/R0009` decided this same sentence that way. Direction here is
    read off the `travelsTo` edge, which is a statement about the flow of
    traffic.

  * **Binder choices.** `v` and `w` are `proximityVehicleBinder`: `oncoming`
    needs angular edges, which the generator emits only for the base classes
    `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck`, so a `vehicleBinder`
    would admit vans and the abstract `vehicle` type and produce groundings that
    can never fire. `lNow` and `lNext` are `laneBinder`, and they are distinct by
    construction because `Grounding.distinctIds` drops bindings that repeat an
    id. The scenario traces give the two lane nodes distinct names because
    `carla/adapter.py` keys entities by name and two same-named nodes would
    collapse into one entity.

  * **Not validated against real data.** The scenarios below were written from
    the same reading of the clause as the formula, so they cannot catch a
    misreading of it. `run_spec monitor` against a human-labelled capture is the
    only independent check; until then treat this rule as unvalidated. What they
    *can* and do catch is the two ways this construction goes wrong:
    `with_flow_progress_with_oncoming` and `victim_of_wrong_way_intruder` fail
    the moment `laneTravelsTo`'s arguments are inverted or the conjunct dropped,
    and `wrong_way_progress_no_oncoming` fails the moment the oncoming conjunct
    is dropped.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Lane.R0017

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- Quantified over the ego vehicle, the vehicle approaching head-on, the lane
    the ego occupies now and the lane it occupies on the next frame. -/
def schema : PropertySchema where
  name    := "wrong_way_progress_with_oncoming"
  binders := [ proximityVehicleBinder "v", proximityVehicleBinder "w"
             , laneBinder "lNow", laneBinder "lNext" ]
  formula := fun env =>
    let v     := arg env 0
    let w     := arg env 1
    let lNow  := arg env 2
    let lNext := arg env 3
    -- "the ego is in `lNow` with `w` coming head-on in it, and on the next
    --  frame it is in `lNext` — from which traffic flows *back into* `lNow`,
    --  so the ego moved against the flow" — forbidden at every position.
    □ (¬ₛ ( isEgo v
          ⋀ inLane v lNow
          ⋀ oncoming v w
          ⋀ sameLane v w
          ⋀ ◯ (inLane v lNext)
          ⋀ laneTravelsTo lNext lNow ))

def entry : RuleEntry where
  nodeId  := "Lane/R0017_wrong_way_progress_with_oncoming"
  lawRefs := ["EX-LANE-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- One route throughout, two lane nodes on it: `Lane 9_-1` (of `Road 9`) is
-- UPSTREAM and `Lane 12_-1` (of `Road 12`) is DOWNSTREAM, joined by the single
-- connectivity edge `upstream --travelsTo--> downstream`, present in every
-- frame. Driving with the flow means moving upstream → downstream; driving
-- against it means downstream → upstream.
--
-- Only that one edge is emitted, in that one direction: the generator's
-- `travelsTo` records the direction of travel, and a lane that carried traffic
-- both ways would not be a wrong-way test at all.
----------------------------------------------------------------------

private def egoId    : Nat := 1
private def carId    : Nat := 2
private def upId     : Nat := 10
private def downId   : Nat := 11
private def roadUpId : Nat := 20
private def roadDnId : Nat := 21

private def entities : List Entity :=
  [ mkEgo egoId .car "8.000"
  , mkActor carId "car_0" .car
  , mkLane upId "Lane 9_-1"
  , mkLane downId "Lane 12_-1"
  , mkRoad roadUpId "Road 9"
  , mkRoad roadDnId "Road 12" ]

private def structureRels : List Relation :=
  [ mkRel upId .isIn roadUpId
  , mkRel downId .isIn roadDnId
  , mkRel upId .travelsTo downId ]

/-- One frame: the ego in `egoLane`, `car_0` in `carLane`, plus whatever
    angular and proximity edges the situation calls for. -/
private def mkFrame (egoLane carLane : Nat) (edges : List Relation) : Scene :=
  frame entities
    (structureRels
      ++ [ mkRel egoId .isIn egoLane, mkRel carId .isIn carLane ]
      ++ edges)

/-- The mutual front-edge pair the generator renders for two converging actors,
    with the distance edge written ego-first. -/
private def convergingAt (band : RelLabel) : List Relation :=
  [ mkRel egoId .inDFrontOf carId
  , mkRel carId .inDFrontOf egoId
  , mkRel egoId band carId ]

/-- `car_0` is behind the ego and pointing the same way: one front edge and one
    rear edge, which is what the generator renders for same-direction traffic.
    `oncoming` is false. -/
private def trailingAt (band : RelLabel) : List Relation :=
  [ mkRel carId .atDRearOf egoId
  , mkRel egoId .inDFrontOf carId
  , mkRel egoId band carId ]

----------------------------------------------------------------------
-- 1. With the flow, with a vehicle coming head-on
----------------------------------------------------------------------

/-- The ego moves upstream → downstream, i.e. the way the `travelsTo` edge
    points, with `car_0` head-on in whichever lane the ego is in. Forty frames,
    the transition at 19/20.

    A vehicle IS approaching head-on, but the ego is travelling the way the lane
    goes, so the second sentence does not reach it — whatever the other driver
    is doing. Invert the arguments of `laneTravelsTo` and this scenario
    convicts. -/
def traceWithFlowWithOncoming : Trace :=
  List.replicate 12 (mkFrame upId upId (convergingAt .visible))
    ++ List.replicate 8  (mkFrame upId upId (convergingAt .near))
    ++ List.replicate 20 (mkFrame downId downId (convergingAt .near))

----------------------------------------------------------------------
-- 2. Against the flow, but nothing approaching in the lane
----------------------------------------------------------------------

/-- The ego moves downstream → upstream, against the `travelsTo` edge, with
    `car_0` in its lane throughout but BEHIND it and pointing the same way.
    Forty frames, the transition at 19/20.

    The connectivity conjunct fires here; the offence does not, because the
    second sentence conditions it on another vehicle approaching in the lane and
    there is none. Drop the oncoming conjunct and this scenario convicts. -/
def traceWrongWayNoOncoming : Trace :=
  List.replicate 20 (mkFrame downId downId (trailingAt .near))
    ++ List.replicate 20 (mkFrame upId upId (trailingAt .near))

----------------------------------------------------------------------
-- 3. The R0009-class regression: the ego is the VICTIM
----------------------------------------------------------------------

/-- The ego travels with the flow, upstream → downstream, while `car_0` is in
    its lane coming head-on and closing. Forty frames, the transition at 19/20.

    THIS IS THE DISCRIMINATOR. `Pred.oncoming` is symmetric, so a rule built on
    `oncoming v w ⋀ sameLane v w` alone convicts the lawful driver here. The
    ego's own progression follows the `travelsTo` edge; the intruder is the
    offender, and this rule does not convict it (residue (b)). -/
def traceVictimOfIntruder : Trace :=
  List.replicate 14 (mkFrame upId upId (convergingAt .visible))
    ++ List.replicate 6  (mkFrame upId upId (convergingAt .near))
    ++ List.replicate 10 (mkFrame downId downId (convergingAt .near))
    ++ List.replicate 10 (mkFrame downId downId (convergingAt .veryNear))

----------------------------------------------------------------------
-- 4. The offence
----------------------------------------------------------------------

/-- The ego moves downstream → upstream — against the `travelsTo` edge — with
    `car_0` in its lane, coming head-on, and closing throughout. Forty frames.

    The forbidden pattern is observed at frame 19, with its `◯` conjunct at
    frame 20: the ego is in the downstream lane, `car_0` is head-on in it, and
    on the next frame the ego is in the upstream lane, from which traffic flows
    back into the one it just left. Frame 19 is far from both ends of the
    trace. -/
def traceWrongWayTowardOncoming : Trace :=
  List.replicate 15 (mkFrame downId downId (convergingAt .visible))
    ++ List.replicate 5  (mkFrame downId downId (convergingAt .near))
    ++ List.replicate 10 (mkFrame upId upId (convergingAt .near))
    ++ List.replicate 10 (mkFrame upId upId (convergingAt .veryNear))

def scenarios : List Scenario :=
  [ { name := "with_flow_progress_with_oncoming"
    , trace := traceWithFlowWithOncoming
    , expected := true }
  , { name := "wrong_way_progress_no_oncoming"
    , trace := traceWrongWayNoOncoming
    , expected := true }
  , { name := "victim_of_wrong_way_intruder"
    , trace := traceVictimOfIntruder
    , expected := true }
  , { name := "wrong_way_progress_toward_oncoming"
    , trace := traceWrongWayTowardOncoming
    , expected := false } ]

end TrafficSpec.Rules.Lane.R0017
