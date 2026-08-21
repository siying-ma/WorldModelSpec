/-
  Rule R0016 — crossing into an opposing lane while a vehicle is approaching
  head-on in it.

  Law text (EX-LANE-001, "Driving on the right"):
    "A vehicle shall be driven upon the right half of the roadway, except when
     overtaking. A vehicle shall not occupy a lane that opposes the flow of
     traffic while another vehicle is approaching in that lane."

  SCOPE — THIS FILE IS ONLY THE SECOND SENTENCE, AND ONLY ITS CROSSING ROUTE
  --------------------------------------------------------------------------
  This rule formalizes the **second** sentence of EX-LANE-001 and nothing else.
  The first sentence — the keep-right obligation and its overtaking exception —
  is `Lane/R0008_keep_right_of_roadway`. A trace this rule reports as compliant
  may still violate the first sentence, and vice versa; a monitoring application
  must register both to enforce the clause.

  Within the second sentence this file covers the **crossing** route only: the
  ego is convicted because it was observed *moving* out of the lane it occupied
  into a lane opposing that lane, and then staying there with a vehicle coming
  head-on. A capture that opens with the ego already in the opposing lane — the
  crossing having happened before frame 0, or outside the render window — is
  never convicted here, because the antecedent needs a frame in which the ego is
  still in the lane it leaves. That gap is deliberate and is the residue of the
  asymmetry argument below; `Lane/R0017` is the sibling node that covers the
  already-in-the-opposing-lane case. Do not read a compliant verdict from this
  rule as "the ego was never in the wrong lane".

  Formalization notes
  -------------------
  * **THE CROSSING CONJUNCT IS THE POINT OF THE RULE AND IS NOT OPTIONAL.**
    `Pred.oncoming` is `inFrontOf a b ⋀ inFrontOf b a`: the generator computes
    each angular edge in the *source* actor's forward frame, so a mutual
    front-edge pair means only that two actors' headings differ by more than 90°
    — that they are converging. It is **symmetric**, and therefore says nothing
    about which of the two is in the wrong lane (`carla/schema.json` →
    `partially_available.wrong_way_driving`, residue on route 1).

    A rule written as `□ ¬ₛ (oncoming v w ⋀ sameLane v w)` would convict the
    *lawful* driver whose lane a wrong-way vehicle has entered. That is the
    R0009 failure mode exactly: such a rule passes every scenario its own author
    writes and then convicts lawful driving on a capture. `victim_of_wrong_way_driver`
    below is the regression scenario — it is 40 frames in which someone is
    driving head-on at the ego in the ego's own lane, and the expected verdict
    is *compliant*, because the offender is not the ego.

    The asymmetry is supplied by the lane transition. Only the vehicle that
    moved out of a lane into a lane opposing it can satisfy
    `inLane v lFrom ⋀ lanesOppose lFrom lOpp ⋀ ◯ (inLane v lOpp)`; the driver
    whose lane was invaded never changes lane at all. This is route (2) of
    `wrong_way_driving` — lane connectivity over time — used to disambiguate
    route (1).

  * **The lane-id sign predicates appear nowhere in this file.**
    `Pred.laneRightOfReference`, `laneLeftOfReference`, `inLaneRightOfReference`
    and `inLaneLeftOfReference` read which side of the OpenDRIVE reference line
    a lane was *authored* on, which is a map convention and not a direction of
    travel: every lane of one direction shares the sign. The deleted
    `Lane/R0009` decided this same sentence that way and convicted 50 frames of
    lawful driving in the bundled sceneflow capture. Opposition is instead read
    off the `opposes` edge and the mutual-`toLeftOf` pattern, both of which are
    statements about direction of travel.

  * **`lanesOppose` is symmetric and also accepts the mutual-`toLeftOf`
    pattern, deliberately widening `Pred.rel lFrom .opposes lOpp`.** The
    generator emits `opposes` only between *adjacent* lane ids of one road, and
    `Core/Vocab.lean`'s own private `opposedLanes` therefore treats the mutual
    `toLeftOf` pattern (each lane judged "left of" the other, because each is
    judged from its own heading) as the general test. Requiring one directed
    `opposes` edge would make the rule silently miss a crossing whenever the
    capture happened to carry the edge only the other way round. Widening an
    antecedent risks false convictions, so note what is being trusted: that a
    mutual `toLeftOf` pair really does mean opposite directions of travel
    (`sgg_abstractor.py`; `Core/Vocab.lean` § 3a, and `Lane/R0008` relies on the
    same reading).

  * **"while another vehicle is approaching in that lane" is read as
    `oncoming v w ⋀ sameLane v w` — converging headings plus shared lane
    occupancy — with NO distance requirement.** The statute sets no separation,
    and the abstraction has none to offer: proximity is quantised into six bands
    and `carla/schema.json` → `unavailable.exact_distance` records that no
    metric separation survives `process_to_junction_rsv`. Adding a band
    threshold would be inventing a number the text does not contain and would
    acquit a driver who crossed in front of a vehicle still 30 m away. The
    residue is that a vehicle far up the opposing lane but rendered by the
    capture counts as "approaching"; render distance (50 m by default) is the de
    facto bound, and that is a capture parameter, not a legal one.

  * **`persistFrames := TrafficSpec.secondsToFrames 1 = 20`, and the number is
    ours, not the statute's.** The text says "occupy", which is not
    instantaneous, and a rule that convicted on a single frame in the opposing
    lane would convict the transient overlap of any lane change the graph
    happens to render across a lane boundary. One second is chosen as the
    shortest stay that cannot be read as a transition artefact. It is open to
    challenge in both directions: shorter convicts brief clipping of the
    centre line, longer acquits a genuine one-second incursion. The window also
    inherits the capture-rate residue (`carla/schema.json` →
    `capture_preconditions.capture_rate`): frames carry no timestamp, so 20
    frames is 1 s only if the capture ran at the 20 Hz `Core/Scene.lean` freezes
    as `captureHz`. At 40 Hz this grants half a second.

  * **`Pred.isEgo v` gates the formula, and that is a data restriction, not a
    reading of the statute.** The clause binds every driver. But the crossing
    test needs the vehicle's lane membership on two consecutive frames, and
    `carla/schema.json` → `partially_available.wrong_way_driving` records that
    only the ego reliably carries the lane membership needed to observe a lane
    change. `oncoming` needs angular edges as well, and those exist only between
    the ego and another actor (`relation_coverage`). This rule therefore makes
    no claim about a non-ego vehicle — see `victim_of_wrong_way_driver`, where
    the offender goes unconvicted for exactly this reason.

  * **Binder choices.** `v` and `w` are `proximityVehicleBinder`: `oncoming`
    needs angular edges, which the generator emits only for the base classes
    `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck`, so a `vehicleBinder`
    would admit vans and the abstract `vehicle` type and produce groundings that
    can never fire. `lFrom` and `lOpp` are `laneBinder`; they are distinct by
    construction because `Grounding.distinctIds` drops bindings that repeat an
    id, and the scenario traces give the two lanes distinct names because
    `carla/adapter.py` keys entities by name and two same-named nodes would
    collapse into one.

  * **Shape and trace length.** `□ (¬ₛ (crossing ⋀ ◯ (.bounded persistFrames
    staying)))` — the safety shape. `SFProp.frameSpan` is `1 + 20 = 21`, so
    `Core/Semantics.lean::loopBounded` reads the window as false on any trace
    shorter than 21 frames and the rule would report compliant whatever such a
    trace contained (`tools/check_spec.py` rejects those as `TRACE_TOO_SHORT`).
    The last 20 frames of any trace are likewise a blind zone. Every scenario
    below is 40 frames, and `crosses_into_opposing_lane_with_oncoming` puts the
    crossing at frame 4 so the window covers frames 5–24, clear of the blind
    zone.

  * **Not validated against real data.** The scenarios below were written from
    the same reading of the clause as the formula, so they cannot catch a
    misreading of it. `run_spec monitor` against a human-labelled capture is the
    only independent check; until then treat this rule as unvalidated. What the
    scenarios *can* and do catch is the specific R0009-class error above:
    `victim_of_wrong_way_driver` fails the moment the crossing conjunct is
    dropped, and `crossing_with_empty_opposing_lane` fails the moment the
    oncoming conjunct is dropped.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Lane.R0016

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- How long the ego must remain in the opposing lane, with a vehicle coming
    head-on in it, before the incursion counts as "occupying" it. 1 s = 20
    frames at the reference 20 Hz capture rate. A formalization choice: the
    statute states no duration. -/
def persistFrames : Nat := TrafficSpec.secondsToFrames 1

/-- Lanes `a` and `b` carry traffic in opposite directions.

    Symmetric in the `opposes` edge, and accepting the mutual-`toLeftOf` pattern
    as well — the general test `Core/Vocab.lean` uses internally, because
    `opposes` is emitted only between adjacent lane ids of one road. Built from
    `Pred.*` only; it defines no scene test of its own. -/
private def lanesOppose (a b : EntityId) : SFProp :=
  rel a .opposes b ⋁ rel b .opposes a ⋁ (toLeftOf a b ⋀ toLeftOf b a)

/-- Quantified over the ego vehicle, the approaching vehicle, the lane the ego
    leaves and the lane it enters. -/
def schema : PropertySchema where
  name    := "crossing_into_opposing_lane"
  binders := [ proximityVehicleBinder "v", proximityVehicleBinder "w"
             , laneBinder "lFrom", laneBinder "lOpp" ]
  formula := fun env =>
    let v    := arg env 0
    let w    := arg env 1
    let lFrom := arg env 2
    let lOpp  := arg env 3
    -- "the ego is in `lFrom`, `lOpp` opposes it, and from the very next frame
    --  the ego is in `lOpp` for a full second with `w` coming head-on in it"
    -- — the forbidden pattern, forbidden at every position.
    □ (¬ₛ ( isEgo v
          ⋀ inLane v lFrom
          ⋀ lanesOppose lFrom lOpp
          ⋀ ◯ (SFProp.bounded persistFrames
                 (inLane v lOpp ⋀ oncoming v w ⋀ sameLane v w)) ))

def entry : RuleEntry where
  nodeId  := "Lane/R0016_crossing_into_opposing_lane"
  lawRefs := ["EX-LANE-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- One two-way road throughout: `Road 9`, with `Lane 9_-1` (lane A, the ego's
-- own) and `Lane 9_1` (lane B, the opposing one). The two lanes are joined by
-- the MUTUAL `toLeftOf` pattern that marks opposite directions of travel, plus
-- the `opposes` edge in both directions, exactly as the generator emits them
-- for adjacent lane ids of one road.
----------------------------------------------------------------------

private def egoId   : Nat := 1
private def carId   : Nat := 2
private def laneAId : Nat := 10
private def laneBId : Nat := 11
private def roadId  : Nat := 20

private def entities : List Entity :=
  [ mkEgo egoId .car "9.000"
  , mkActor carId "car_0" .car
  , mkLane laneAId "Lane 9_-1"
  , mkLane laneBId "Lane 9_1"
  , mkRoad roadId "Road 9" ]

private def structureRels : List Relation :=
  [ mkRel laneAId .isIn roadId
  , mkRel laneBId .isIn roadId
  , mkRel laneAId .toLeftOf laneBId
  , mkRel laneBId .toLeftOf laneAId
  , mkRel laneAId .opposes  laneBId
  , mkRel laneBId .opposes  laneAId ]

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

----------------------------------------------------------------------
-- 1. Lawful two-way driving with oncoming traffic
----------------------------------------------------------------------

/-- The ego in its own lane, `car_0` coming the other way in the opposing lane
    — an ordinary two-way road. The pair is mutually `inSFrontOf`, which is how
    the generator renders a converging pair off to one side. -/
private def lawfulFrame : Scene :=
  mkFrame laneAId laneBId
    [ mkRel egoId .inSFrontOf carId
    , mkRel carId .inSFrontOf egoId
    , mkRel egoId .visible carId ]

/-- Forty frames in which the ego never leaves its own lane. Nothing here is an
    offence: the ego occupies no lane that opposes its flow of traffic. -/
def traceLawfulTwoWay : Trace :=
  List.replicate 40 lawfulFrame

----------------------------------------------------------------------
-- 2. The R0009-class regression: the ego is the VICTIM of a wrong-way driver
----------------------------------------------------------------------

/-- The ego in its own lane; `car_0` is in that same lane, coming head-on, and
    closing. -/
private def victimFrame (band : RelLabel) : Scene :=
  mkFrame laneAId laneAId (convergingAt band)

/-- Forty frames in which a vehicle is occupying a lane against the flow of
    traffic with a vehicle approaching in it — and the offender is `car_0`, not
    the ego. The ego never changes lane, so the crossing conjunct is false at
    every position and the ego is acquitted.

    THIS IS THE DISCRIMINATOR. `Pred.oncoming` is symmetric, so a rule built on
    `oncoming v w ⋀ sameLane v w` alone convicts the lawful driver here. Drop
    the crossing conjunct and this scenario fails. -/
def traceVictimOfWrongWayDriver : Trace :=
  List.replicate 15 (victimFrame .visible)
    ++ List.replicate 15 (victimFrame .near)
    ++ List.replicate 10 (victimFrame .veryNear)

----------------------------------------------------------------------
-- 3. The ego crosses, but the opposing lane is empty
----------------------------------------------------------------------

/-- `car_0` stays in the ego's original lane, behind the ego: `car_0` is at the
    ego's rear and the ego is in front of `car_0`, so the pair is travelling the
    same way and `oncoming` is false. -/
private def trailingEdges : List Relation :=
  [ mkRel carId .atDRearOf egoId
  , mkRel egoId .inDFrontOf carId
  , mkRel egoId .near carId ]

private def crossingEmptyBefore : Scene := mkFrame laneAId laneAId trailingEdges
private def crossingEmptyAfter  : Scene := mkFrame laneBId laneAId trailingEdges

/-- Forty frames: the ego crosses into the opposing lane at frame 5 and stays
    there, but nothing is approaching in it — the only other vehicle is behind
    the ego in the lane it left. The second sentence conditions the offence on
    an approaching vehicle, so this is not one. Drop the oncoming conjunct and
    this scenario convicts. -/
def traceCrossingEmptyOpposingLane : Trace :=
  List.replicate 5 crossingEmptyBefore ++ List.replicate 35 crossingEmptyAfter

----------------------------------------------------------------------
-- 4. The offence: the ego crosses into the opposing lane with a vehicle
--    approaching in it
----------------------------------------------------------------------

/-- Before the crossing the ego is in its own lane and `car_0` is merely up
    ahead in the opposing one — one front edge only, so the pair is not yet an
    `oncoming` pair. -/
private def crossingBefore : Scene :=
  mkFrame laneAId laneBId
    [ mkRel carId .inSFrontOf egoId
    , mkRel egoId .visible carId ]

/-- After the crossing both vehicles are in lane B, converging. -/
private def crossingAfter (band : RelLabel) : Scene :=
  mkFrame laneBId laneBId (convergingAt band)

/-- Forty frames. The ego is in lane A for frames 0–4 and in the opposing lane
    B from frame 5 to the end, with `car_0` in lane B throughout and coming
    head-on from frame 5 on. The forbidden pattern is observed at frame 4 — the
    ego still in lane A, the opposing lane one frame ahead of it — and the
    twenty-frame persistence window then covers frames 5–24, clear of the
    trailing blind zone. -/
def traceCrossesWithOncoming : Trace :=
  List.replicate 5 crossingBefore
    ++ List.replicate 15 (crossingAfter .visible)
    ++ List.replicate 20 (crossingAfter .near)

def scenarios : List Scenario :=
  [ { name := "lawful_lane_with_oncoming_traffic"
    , trace := traceLawfulTwoWay
    , expected := true }
  , { name := "victim_of_wrong_way_driver"
    , trace := traceVictimOfWrongWayDriver
    , expected := true }
  , { name := "crossing_with_empty_opposing_lane"
    , trace := traceCrossingEmptyOpposingLane
    , expected := true }
  , { name := "crosses_into_opposing_lane_with_oncoming"
    , trace := traceCrossesWithOncoming
    , expected := false } ]

end TrafficSpec.Rules.Lane.R0016
