/-
  Rule R0008 — occupying a lane against oncoming traffic.

  Law text (laws/example/laws.jsonl, id EX-LANE-001):
    "A vehicle shall be driven upon the right half of the roadway, except when
     overtaking. A vehicle shall not occupy a lane that opposes the flow of
     traffic while another vehicle is approaching in that lane."

  SCOPE — SECOND SENTENCE ONLY
  ---------------------------
  EX-LANE-001 states two separate obligations and this node formalizes only the
  **second**. Sentence 1 ("shall be driven upon the right half of the roadway,
  except when overtaking") is deliberately **out of scope here**:

    * it carries its own antecedent — an overtaking carve-out — which is a
      distinct obligation with a distinct violation condition, not a conjunct of
      this one;
    * its central term degrades to the OpenDRIVE lane-id **sign**
      (`Pred.inLaneRightOfReference`; `carla/schema.json` →
      `partially_available.which_half_of_the_roadway`), which is a map
      convention: every lane carrying one direction of travel shares a sign, so
      the sign names a side of the road's *reference line*, not the legal side
      of the road for my direction of travel.

  It is planned as a sibling node. Despite this file's name, **R0008 says
  nothing about which half of the roadway the ego is on**: a trace in which the
  ego drives on the wrong half of an empty road satisfies this rule.

  Formalization notes
  -------------------
  * **"a lane that opposes the flow of traffic while another vehicle is
    approaching in that lane" is read as: the ego shares a lane with a vehicle
    that is head-on to it.** The offence is the *same-lane* head-on pairing:

        headOnInOwnLane v w = isEgo v ⋀ isVehicle w ⋀ sameLane v w ⋀ oncoming v w

    `Pred.oncoming v w` unfolds to `inFrontOf v w ⋀ inFrontOf w v`. The
    generator computes each angular edge from the *source* actor's forward
    vector, splitting the circle into a front and a rear half-plane, so two
    actors are each in the other's front half-plane only when their headings
    differ by more than 90° — same-direction traffic always yields one front
    edge and one rear edge. That mutual pattern **is** the head-on evidence, and
    it is the route `carla/schema.json` names under
    `partially_available.wrong_way_driving`.
  * **`Pred.opposingLanes` is deliberately NOT used.** It relates two *different*
    adjacent lanes of the same road carrying an `opposes` edge — i.e. ordinary
    two-way traffic, which is lawful. `oncoming_vehicle_in_a_different_lane`
    pins that down: it is head-on and on opposing lanes and must come out
    COMPLIANT. The offence is being in the **same** lane as head-on traffic, so
    the conjunct is `sameLane`, and `wrong_lane_into_oncoming_traffic` differs
    from that scenario in exactly that one respect.
  * **`w` is bound with `proximityVehicleBinder`, not `vehicleBinder`.** Angular
    and proximity edges are emitted only for the base classes
    `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck`
    (`carla/schema.json` → `relation_coverage`), so a `vehicleBinder` would
    admit vans and the generic `vehicle` class and manufacture groundings whose
    antecedent can never fire — inflating the grounding count while testing
    nothing. `v` keeps `vehicleBinder` because it is pinned to the ego by
    `isEgo` anyway, and the ego is always a covered base class.
  * **PERSISTENCE: a three-frame window, not a per-frame prohibition.** The
    obligation is `□ ¬ₛ (.bounded 3 headOnInOwnLane)` — "at no position does the
    same-lane head-on pairing hold for three consecutive frames" — the same
    idiom as `Following/R0001` and `Emergency/R0007`. Both readings pass the
    five declared scenarios (`brief_flicker_then_sustained_headon` is built to
    fire under either), so the gate does not decide this; the reasons for the
    window are:
      - both conjuncts of the antecedent are *per-frame quantised* readings. The
        angular edge is a half-plane test on a forward vector, so on a bend, or
        while a vehicle is yawing, a single frame can read mutually-in-front for
        two vehicles that are not converging; and lane membership is a
        nearest-waypoint assignment, so during a lane change two vehicles can
        map to one lane node for a frame or two.
      - three frames is 0.15 s at the reference 20 Hz capture rate
        (`TrafficSpec.secondsToFrames`; frames carry no clock — see
        `carla/schema.json` → `unavailable.timestamps`). That is short enough
        that no real head-on occupancy escapes it and long enough to reject a
        single-frame artefact.
    The cost, and a reviewer's ground for objecting: a genuine one- or two-frame
    same-lane head-on encounter is **not** reported, and by strong-next
    semantics (`Core/Semantics.lean`, `loopBounded`) a violation beginning in
    the last two frames of a trace is not reported either. A reviewer who thinks
    the statute forbids the occupancy instant-by-instant should set
    `persistenceFrames := 1`, which is the whole change.

  Residues — what this rule does not measure
  ------------------------------------------
  1. **`Pred.oncoming` is SYMMETRIC, and this is the largest residue in the
     rule.** It establishes that a *pair* is converging head-on; it does not
     say which of the two is in the lane that opposes the flow. The `isEgo v`
     conjunct is what assigns the fault to the monitored driver, and that is an
     **assumption, not a measurement**: a lawful ego holding its own lane while
     a wrong-way driver bears down on it is reported by this rule as the
     violator. This is also the reason sentence 1 cannot simply be folded in —
     deciding *who* is misplaced needs the lawful side of the road, which the
     abstraction does not have (see 2).
  2. **`heading_relative_to_lane` is genuinely absent** (`carla/schema.json` →
     `unavailable.heading_relative_to_lane`): the junction-RSV abstraction keeps
     no direction vector for a lane node, so "a lane that opposes the flow of
     traffic" is never tested against the lane's own direction of travel.
     Relative heading between two actors is the only heading evidence there is.
  3. **The rule cannot fire on an empty wrong-way stretch.** It needs a second
     vehicle to witness the direction of flow, so it under-reports the statute,
     which forbids the occupancy itself regardless of whether anyone is coming.
     `no_other_vehicle_in_the_lane` records that as intended behaviour.
  4. **Absence of an oncoming vehicle is not evidence that none was there.**
     Render distance and occlusion filtering both drop entities
     (`carla/schema.json` → `pitfalls`).
  5. **Check the grounding and antecedent-firing counts on a real capture.** The
     mutual-`inFrontOf` pattern is narrow — it needs both directed angular edges
     between the same ordered pair in the same frame — and a rule whose
     antecedent never fires is indistinguishable from one that is satisfied.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Lane.R0008

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The forbidden state: the ego shares a lane with a vehicle that is head-on to
    it. `oncoming` is the mutual-`inFrontOf` pattern, the only heading evidence
    the abstraction preserves; `sameLane` is what distinguishes the offence from
    lawful two-way traffic on opposing lanes. -/
def headOnInOwnLane (v w : EntityId) : SFProp :=
  isEgo v ⋀ isVehicle w ⋀ sameLane v w ⋀ oncoming v w

/-- Persistence window, in frames: 3 frames = 0.15 s at the reference 20 Hz
    capture rate. A formalization choice, not something the text states — see the
    PERSISTENCE note in the header. Set to `1` for the per-frame reading. -/
def persistenceFrames : Nat := 3

/-- The rule, quantified over ordered (vehicle, proximity-vehicle) pairs and
    effective on the ego — the only actor whose fault the symmetric `oncoming`
    predicate can be made to name. -/
def schema : PropertySchema where
  name    := "opposing_lane_oncoming"
  binders := [vehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    □ (¬ₛ (.bounded persistenceFrames (headOnInOwnLane v w)))

def entry : RuleEntry where
  nodeId  := "Lane/R0008_opposing_lane_oncoming"
  lawRefs := ["EX-LANE-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- Road structure shared by every trace: one road carrying two adjacent lanes
-- of opposite sign, L1 (`lane_id -1`) and L2 (`lane_id +1`), joined by the
-- `opposes` edges the generator emits between adjacent lane ids of the same
-- road, plus the singleton `Off Road` node the adapter creates for an actor
-- with no driving-lane edge. Both lanes and the off-road node are present in
-- every frame of every trace so that the structure a scenario does not use is
-- never the reason a verdict changes.
----------------------------------------------------------------------

private def laneL1 : Nat := 10
private def laneL2 : Nat := 11
private def road   : Nat := 20
private def offRd  : Nat := 30

private def structureEntities : List Entity :=
  [ mkLane laneL1 "Lane 7_-1"
  , mkLane laneL2 "Lane 7_1"
  , mkRoad road   "Road 7"
  , mkOffRoad offRd ]

private def structureRels : List Relation :=
  [ mkRel laneL1 .isIn road
  , mkRel laneL2 .isIn road
  , mkRel laneL1 .opposes laneL2
  , mkRel laneL2 .opposes laneL1 ]

/-- Ego (id 1) and `car_0` (id 2), each `isIn` the lane given, at proximity
    `band`, with the angular edges passed explicitly — the whole point of every
    trace below is *which* angular edges hold. -/
private def pairFrame (egoLane otherLane : Nat) (band : RelLabel)
    (angular : List Relation) : Scene :=
  frame
    ([mkEgo 1 .car "8.0" "0.0" "0.3" "0.0", mkActor 2 "car_0" .car]
      ++ structureEntities)
    (structureRels
      ++ [ mkRel 1 .isIn egoLane, mkRel 2 .isIn otherLane, mkRel 1 band 2 ]
      ++ angular)

/-- Same-direction traffic: `car_0` ahead of the ego, the ego at its rear. One
    front edge and one rear edge, so the mutual-`inFrontOf` pattern is absent. -/
private def sameHeadingEdges : List Relation :=
  [ mkRel 2 .inDFrontOf 1, mkRel 1 .atDRearOf 2 ]

/-- Head-on: each actor lies in the other's front half-plane, which the
    generator can only emit when the two forward vectors differ by more than
    90°. -/
private def headOnEdges : List Relation :=
  [ mkRel 2 .inDFrontOf 1, mkRel 1 .inDFrontOf 2 ]

/-- Ordinary car-following in one lane for six frames: `car_0` is `inDFrontOf`
    the ego and the ego is `atDRearOf` `car_0`, so `oncoming` never holds. -/
def traceFollowingSameLaneSameHeading : Trace :=
  List.replicate 6 (pairFrame laneL1 laneL1 .near sameHeadingEdges)

/-- Normal two-way traffic: the ego holds L1 and `car_0` holds the adjacent
    opposing lane L2 for six frames. The pair is genuinely head-on throughout —
    mutually `inDFrontOf` — but they are not in the same lane, so nothing is
    violated. This isolates the `sameLane` conjunct: it is the only respect in
    which this differs from `traceWrongLaneIntoOncomingTraffic`, and a formula
    using `opposingLanes` instead of `sameLane` would convict here. -/
def traceOncomingVehicleInADifferentLane : Trace :=
  List.replicate 6 (pairFrame laneL1 laneL2 .veryNear headOnEdges)

/-- The ego holds L1 for six frames. `car_0` is present in every frame, so the
    `w` binder grounds, but it is `isIn` the `Off Road` node rather than any
    lane, so `sameLane` is false and no angular edge relates the pair. An empty
    lane cannot be violated — residue 3 in the header. -/
def traceNoOtherVehicleInTheLane : Trace :=
  List.replicate 6 (pairFrame laneL1 offRd .visible [])

/-- The offence: the ego and `car_0` share L1 for all six frames and are
    mutually `inDFrontOf` each other throughout. The ego is head-on to traffic
    in its own lane for the whole trace. -/
def traceWrongLaneIntoOncomingTraffic : Trace :=
  List.replicate 6 (pairFrame laneL1 laneL1 .veryNear headOnEdges)

/-- Eight frames in L1. The mutual-`inFrontOf` pattern is absent in frame 1,
    present in frames 2–3, absent in frame 4, then present continuously in
    frames 5–8. The two-frame burst alone would not trip a three-frame window;
    the sustained run of four frames at the end does, so this violates under the
    per-frame reading *and* under the persistence window chosen in the header. -/
def traceBriefFlickerThenSustainedHeadon : Trace :=
  let headOn := pairFrame laneL1 laneL1 .veryNear headOnEdges
  let clear  := pairFrame laneL1 laneL1 .veryNear sameHeadingEdges
  [ clear, headOn, headOn, clear, headOn, headOn, headOn, headOn ]

def scenarios : List Scenario :=
  [ { name := "following_same_lane_same_heading",   trace := traceFollowingSameLaneSameHeading,   expected := true }
  , { name := "oncoming_vehicle_in_a_different_lane", trace := traceOncomingVehicleInADifferentLane, expected := true }
  , { name := "no_other_vehicle_in_the_lane",       trace := traceNoOtherVehicleInTheLane,        expected := true }
  , { name := "wrong_lane_into_oncoming_traffic",   trace := traceWrongLaneIntoOncomingTraffic,   expected := false }
  , { name := "brief_flicker_then_sustained_headon", trace := traceBriefFlickerThenSustainedHeadon, expected := false } ]

end TrafficSpec.Rules.Lane.R0008
