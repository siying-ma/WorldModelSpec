/-
  Rule R0023 — progressing against a lane's own direction of travel while
  ANOTHER VEHICLE OF ANY BASE CLASS occupies that lane.

  Law text (EX-LANE-001, "Driving on the right"):
    "A vehicle shall be driven upon the right half of the roadway, except when
     overtaking. A vehicle shall not occupy a lane that opposes the flow of
     traffic while another vehicle is approaching in that lane."

  SCOPE — SECOND SENTENCE ONLY
  ---------------------------
  This file formalizes the **second** sentence of EX-LANE-001 and nothing else.
  The keep-right obligation of the first sentence and its overtaking exception
  are `Lane/R0008_keep_right_of_roadway`. A trace this rule reports compliant may
  still violate the first sentence, and vice versa; an application enforcing the
  clause must register both.

  WHY A FOURTH DETECTOR FOR THIS SENTENCE: THE VAN BLIND SPOT
  ----------------------------------------------------------
  `Lane/R0016_crossing_into_opposing_lane`,
  `Lane/R0017_wrong_way_progress_with_oncoming` and
  `Lane/R0022_occupying_lane_against_observed_flow` all formalize this sentence,
  and every one of them conjoins `Pred.oncoming`, which is
  `inFrontOf a b ⋀ inFrontOf b a` — two ANGULAR edges. The generator emits
  angular and proximity edges only for the ordered pairs of
  `sgg_abstractor.py::DEFAULT_PROXIMITY_RELATIONS`, which names the base classes
  `person` / `bicycle` / `car` / `motorcycle` / `bus` / `truck` and **not**
  `van`; `Core/Scene.lean::proximityVehicleTypes` transcribes exactly that list
  and deliberately omits `.van`. So all three existing rules are structurally
  silent whenever the other vehicle in the lane is a van — and CARLA's ambulance
  is `vehicle.ford.ambulance`, base class `van`.

  This rule reads NOTHING but `isIn` edges and one `travelsTo` edge, both of
  which a van carries like any other actor, so its binders are `vehicleBinder`
  (which admits `.van` and `.vehicle`) and **not** `proximityVehicleBinder`.

  * No `Pred.withinMetres` conjunct and no `Pred.oncoming` conjunct appear
    anywhere below, and neither may be added "for extra safety": either one
    re-introduces precisely the blindness this node exists to remove. The price
    of that omission is residue (1).

  Formalization notes — choices the text did not dictate
  -----------------------------------------------------
  * **THE DIRECTION OF `laneTravelsTo` IS THE WHOLE RULE.**
    `Pred.laneTravelsTo l₁ l₂` is the edge `l₁ --travelsTo--> l₂`: traffic in
    `l₁` flows onward into `l₂`. The ego is observed in `lNow` now and in
    `lNext` on the next frame, and the forbidden pattern requires
    `laneTravelsTo lNext lNow` — flow runs from the lane the ego is moving
    **into** back towards the lane it is **leaving**, so the ego ran
    `lNow → lNext` against the lane chain. This is R0017's orientation and the
    OPPOSITE of R0022's, where it is the other vehicle whose progression
    supplies the flow evidence. Writing `laneTravelsTo lNow lNext` instead
    describes exactly lawful progression and would convict every driver on the
    road; `lawful_progress_with_a_van_in_the_lane` below is the minimal pair
    that fails the instant the arguments are swapped (the violating scenario
    keeps passing, so it is the only scenario that catches the inversion).

  * **`w`'s only role is to witness that the lane is occupied — never to
    establish direction.** All of the asymmetry comes from the ego's own
    observed lane-node progression relative to the connectivity edge, which
    names the ego as the misplaced vehicle. The symmetric-`Pred.oncoming` trap
    (`Lane/R0009`'s failure mode: convicting the lawful driver into whose lane a
    wrong-way vehicle strayed) therefore cannot arise here, because no symmetric
    predicate appears in the formula.

  * **Nothing in this file touches `lane_id`.** The deleted `Lane/R0009` decided
    this same sentence by reading a legal side of the road off the OpenDRIVE
    lane-id sign — a map authoring convention, not a direction of travel — and
    convicted 50 frames of lawful driving in the bundled capture.
    `Pred.laneRightOfReference` / `laneLeftOfReference` /
    `inLaneRightOfReference` / `inLaneLeftOfReference` appear nowhere below.
    Direction here is the `travelsTo` edge, which is a statement about the flow
    of traffic, tested against the vehicle's own observed motion.

  * **`Pred.isEgo v` gates the formula, and that is a data restriction, not a
    reading of the statute.** The clause binds every driver, but the
    connectivity test needs a vehicle's lane membership on two consecutive
    frames and `carla/schema.json` → `partially_available.wrong_way_driving`
    records (route 2 residue) that only the ego reliably carries it. This rule
    makes no claim about a non-ego wrong-way driver.

  * **`¬ₛ (isEgo w)` spells out "ANOTHER vehicle".** `Grounding.distinctIds`
    already drops any binding with `v = w`, so on these traces the conjunct is
    defensive rather than load-bearing; it is kept because the statute's
    "another vehicle" is part of what the formula is supposed to say, and
    because a capture in which two nodes both answer `isEgo` (the adapter keys
    entities by name, and `isEgo` matches `special_class = "ego"` OR
    `name = "ego"`) would otherwise let the ego witness its own lane.

  * **The shared-lane conjunct is `inLane v lNow ⋀ inLane w lNow`, not
    `sameLane v w`.** The rule must name the *same* lane node that carries the
    connectivity edge; otherwise a vehicle sharing some other lane with the ego
    could satisfy the occupancy condition for a lane it is not in.

  * **No persistence window, and that is a choice.** The forbidden pattern is a
    single lane-node transition, so `SFProp.frameSpan` is 2 — the position plus
    one `◯` — and the last frame of any trace is the `◯` blind zone. Every
    scenario below puts the transition in the middle of a 12-frame trace, never
    at its end. See residue (4) for the cost of the short window.

  RESIDUES
  --------
  (1) **"another vehicle is APPROACHING in that lane" degrades to "another
      vehicle OCCUPIES that lane".** `carla/schema.json` →
      `unavailable.non_ego_dynamics`: speed / accel / throttle / brake / steer /
      reverse are copied for the ego node only, so `w`'s motion is unobservable;
      and without an angular edge — the whole point of this node — `w`'s heading
      is unobservable too. A stationary or parked van in the lane therefore
      satisfies the antecedent. This is a genuine widening over R0022, which at
      least gets `oncoming`, and it is the price of van visibility.

  (2) **The ego must cross a lane-node boundary inside the capture to be seen at
      all.** `process_to_junction_rsv` collapses each waypoint run into one lane
      node per road-and-lane-id, so an ego driving the wrong way while holding a
      single lane node for the whole trace is invisible here, exactly as it is
      to R0017. Consequently the quadrant **"the ego holds one lane node AND the
      other vehicle is a van"** is covered by NO rule in this library: R0016 /
      R0017 / R0022 all need `oncoming`, which no van carries, and this rule
      needs the ego's transition. It is also not reachable with today's
      vocabulary — with neither the ego's motion nor an angular edge there is no
      observable that says which of the two vehicles is the misplaced one, and
      `unavailable.heading_relative_to_lane` records that a lane node keeps no
      direction vector to compare an absolute heading against.

  (3) **The `¬ₛ (inReverse v)` exclusion is a modelling choice the statute does
      not state.** A driver reversing along a lane occupies it facing the lawful
      way and is not "driven upon" the wrong half of the roadway, and convicting
      one is a false positive R0017 currently produces. The cost is that this
      rule acquits a driver who reverses the wrong way down a lane for any
      distance. A reviewer who reads the clause as covering that conduct should
      drop the conjunct and expect `reversing_with_a_van_in_the_lane` to flip.

  (4) **The one-frame `◯` window means a single frame of lane-membership noise
      in `carla/adapter.py` reads as wrong-way progress.** If the grounding
      count on a real capture is high and the verdicts look wrong, a two-frame
      confirmation — `◯ (inLane v lNext) ⋀ ◯ ◯ (inLane v lNext)`, span 3 — is
      the first thing to try.

  * **Not validated against real data.** The scenarios below were written from
    the same reading of the clause as the formula, so they cannot catch a
    misreading of it. `run_spec monitor` against a human-labelled capture is the
    only independent check; until then treat this rule as unvalidated. What they
    do catch is the three ways this construction goes wrong: an inverted
    `laneTravelsTo`, a dropped occupancy conjunct, and a dropped reverse
    exclusion.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Lane.R0023

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- Quantified over the ego vehicle, the vehicle occupying the lane, the lane
    the ego occupies now and the lane it occupies on the next frame.

    `vehicleBinder`, NOT `proximityVehicleBinder`: this rule reads only `isIn`
    and `travelsTo`, so it must admit `.van` — see the header. -/
def schema : PropertySchema where
  name    := "wrong_way_with_vehicle_in_lane"
  binders := [ vehicleBinder "v", vehicleBinder "w"
             , laneBinder "lNow", laneBinder "lNext" ]
  formula := fun env =>
    let v     := arg env 0
    let w     := arg env 1
    let lNow  := arg env 2
    let lNext := arg env 3
    -- "the ego is in `lNow`, another vehicle is in `lNow` too, and on the next
    --  frame the ego is in `lNext` — from which traffic flows *back into*
    --  `lNow`, so the ego moved against the flow — and it is not reversing."
    □ (¬ₛ ( isEgo v
          ⋀ inLane v lNow
          ⋀ inLane w lNow
          ⋀ ¬ₛ (isEgo w)
          ⋀ ◯ (inLane v lNext)
          ⋀ laneTravelsTo lNext lNow
          ⋀ ¬ₛ (inReverse v) ))

def entry : RuleEntry where
  nodeId  := "Lane/R0023_wrong_way_with_vehicle_in_lane"
  lawRefs := ["EX-LANE-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- Two consecutive lane nodes of ONE direction of travel: `Lane 7_-1` (of
-- `Road 7`) and `Lane 9_-1` (of `Road 9`), joined by a single `travelsTo` edge
-- whose direction is the only thing that differs between the violating trace
-- and its lawful minimal pair. A third lane node `Lane 7_-2` (also of `Road 7`)
-- exists in every trace and carries NO `travelsTo` edge to either of the
-- others; it is where the van sits in `wrong_way_but_no_vehicle_in_that_lane`.
--
-- The other vehicle is a `.van` (`base_class` `"van"`) throughout, and NO
-- proximity band and NO angular edge appears anywhere in any trace — that is
-- the whole point of the node, since it is exactly the geometry R0016, R0017
-- and R0022 cannot report.
--
-- Twelve frames each, with the ego's lane transition at 2 → 3: far from the
-- last frame, which is the `◯` blind zone.
----------------------------------------------------------------------

private def egoId   : Nat := 1
private def vanId   : Nat := 2
private def lane7Id : Nat := 10   -- Lane 7_-1
private def lane9Id : Nat := 11   -- Lane 9_-1
private def laneXId : Nat := 12   -- Lane 7_-2, off to one side
private def road7Id : Nat := 20
private def road9Id : Nat := 21

/-- A delivery van: `vehicle.ford.ambulance` has this base class too, which is
    why no angular or proximity edge is ever emitted for it. -/
private def entities : List Entity :=
  [ mkEgo egoId .car "8.000"
  , mkActor vanId "van_0" .van (semClass := "vehicle.carlamotors.carlacola")
  , mkLane lane7Id "Lane 7_-1"
  , mkLane lane9Id "Lane 9_-1"
  , mkLane laneXId "Lane 7_-2"
  , mkRoad road7Id "Road 7"
  , mkRoad road9Id "Road 9" ]

/-- The same entity list with `reverse = "true"` on the ego. -/
private def entitiesReversing : List Entity :=
  [ (mkEgo egoId .car "8.000").withAttr "reverse" "true"
  , mkActor vanId "van_0" .van (semClass := "vehicle.carlamotors.carlacola")
  , mkLane lane7Id "Lane 7_-1"
  , mkLane lane9Id "Lane 9_-1"
  , mkLane laneXId "Lane 7_-2"
  , mkRoad road7Id "Road 7"
  , mkRoad road9Id "Road 9" ]

/-- Lane-to-road structure, identical in every frame of every trace. -/
private def structureRels : List Relation :=
  [ mkRel lane7Id .isIn road7Id
  , mkRel laneXId .isIn road7Id
  , mkRel lane9Id .isIn road9Id ]

/-- One frame: the ego in `egoLane`, the van in `vanLane`, and the single
    connectivity edge `flowSrc --travelsTo--> flowTgt`. -/
private def mkFrame (ents : List Entity) (egoLane vanLane flowSrc flowTgt : Nat) :
    Scene :=
  frame ents
    (structureRels
      ++ [ mkRel egoId .isIn egoLane
         , mkRel vanId .isIn vanLane
         , mkRel flowSrc .travelsTo flowTgt ])

/-- Frames 0-2 with the ego in `Lane 9_-1`, frames 3-11 with the ego in
    `Lane 7_-1`: the ego moves 9_-1 → 7_-1. -/
private def egoMoves9to7 (ents : List Entity) (vanLane flowSrc flowTgt : Nat) :
    Trace :=
  List.replicate 3 (mkFrame ents lane9Id vanLane flowSrc flowTgt)
    ++ List.replicate 9 (mkFrame ents lane7Id vanLane flowSrc flowTgt)

----------------------------------------------------------------------
-- 1. The offence
----------------------------------------------------------------------

/-- `Lane 7_-1 travelsTo Lane 9_-1`, so traffic flows 7_-1 → 9_-1. The van sits
    in `Lane 9_-1` for the whole trace. The ego is in `Lane 9_-1` for frames 0-2
    and in `Lane 7_-1` from frame 3 on — BACKWARDS up the chain, against the
    flow.

    The forbidden pattern is observed at frame 2 with its `◯` conjunct at frame
    3: `lNow = Lane 9_-1`, `lNext = Lane 7_-1`, and
    `laneTravelsTo lNext lNow` holds. No proximity band and no angular edge
    anywhere, so R0016, R0017 and R0022 are all silent on this trace. -/
def traceWrongWayWithVan : Trace :=
  egoMoves9to7 entities lane9Id lane7Id lane9Id

----------------------------------------------------------------------
-- 2. The minimal pair: the same motion, the flow edge reversed
----------------------------------------------------------------------

/-- Trace 1 with the single `travelsTo` edge reversed — `Lane 9_-1 travelsTo
    Lane 7_-1` — and nothing else changed. Same van in the same lane, same
    frame counts, same ego motion 9_-1 → 7_-1, which is now WITH the flow.

    This is the regression test for the direction of the connectivity conjunct.
    Write `laneTravelsTo lNow lNext` and this scenario convicts while trace 1
    still does, so it is the only scenario that catches the inversion. -/
def traceLawfulProgressWithVan : Trace :=
  egoMoves9to7 entities lane9Id lane9Id lane7Id

----------------------------------------------------------------------
-- 3. Wrong way, but nobody in the lane being opposed
----------------------------------------------------------------------

/-- Trace 1 with the van moved to `Lane 7_-2` — a third lane node on `Road 7`
    carrying no `travelsTo` edge to either of the others — for the whole trace.
    The ego's motion is wrong-way exactly as in trace 1.

    Sentence 2 of EX-LANE-001 conditions the offence on another vehicle being in
    THAT lane; bare lane discipline with nobody there is sentence 1's business
    and belongs to `Lane/R0008`. Drop the `inLane w lNow` conjunct and this
    scenario convicts. -/
def traceWrongWayNoVehicleInLane : Trace :=
  egoMoves9to7 entities laneXId lane7Id lane9Id

----------------------------------------------------------------------
-- 4. Wrong way, but reversing
----------------------------------------------------------------------

/-- Trace 1 with one attribute added: the ego carries `reverse = "true"` on
    every frame.

    A driver reversing along a lane occupies it facing the lawful way, so this
    is the false positive residue (3) exists to avoid. Drop the
    `¬ₛ (inReverse v)` conjunct and this scenario convicts. -/
def traceReversingWithVan : Trace :=
  egoMoves9to7 entitiesReversing lane9Id lane7Id lane9Id

def scenarios : List Scenario :=
  [ { name := "wrong_way_with_a_van_in_the_lane"
    , trace := traceWrongWayWithVan
    , expected := false }
  , { name := "lawful_progress_with_a_van_in_the_lane"
    , trace := traceLawfulProgressWithVan
    , expected := true }
  , { name := "wrong_way_but_no_vehicle_in_that_lane"
    , trace := traceWrongWayNoVehicleInLane
    , expected := true }
  , { name := "reversing_with_a_van_in_the_lane"
    , trace := traceReversingWithVan
    , expected := true } ]

end TrafficSpec.Rules.Lane.R0023
