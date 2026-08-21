/-
  Rule R0008 — driving on the right: keep out of the left-hand lanes, except
  for as long as an overtake lasts.

  Law text (EX-LANE-001, "Driving on the right"):
    "A vehicle shall be driven upon the right half of the roadway, except when
     overtaking. A vehicle shall not occupy a lane that opposes the flow of
     traffic while another vehicle is approaching in that lane."

  SCOPE — THIS FILE IS ONLY THE FIRST SENTENCE
  --------------------------------------------
  This rule formalizes the **first** sentence — the keep-right obligation and
  its overtaking exception — and nothing else. The second sentence ("shall not
  occupy a lane that opposes the flow of traffic while another vehicle is
  approaching in that lane") is a separate obligation with a different
  antecedent: it is about an *opposing* lane and it is conditioned on an
  approaching vehicle, neither of which appears below. It is deferred to a
  sibling node. Do not read this file as the whole of EX-LANE-001: a trace this
  rule reports as compliant may still violate the second sentence, and a
  monitoring application that registers only this rule under-enforces the
  clause.

  Formalization notes
  -------------------
  * **"the right half of the roadway" is read relative to the vehicle's own
    direction of travel, via `Pred.hasLaneToTheRight`, and NOT off the
    OpenDRIVE lane-id sign.** This is the central soundness decision of the
    file and it is not a stylistic preference: it is a regression fix.

    The lane-id sign records which side of the road's reference line the map
    author drew a lane. Every lane of one direction of travel shares that sign,
    so the lawful carriageway of a divided road — or any one-way street the map
    numbers positively — is entirely "left of reference". The deleted rule
    `Lane/R0009` formalized this same sentence with
    `Pred.inLaneRightOfReference`, passed every one of its own scenarios, and
    then convicted **50 frames of lawful driving** in the bundled sceneflow
    capture (`carla/schema.json` →
    `partially_available.which_half_of_the_roadway.do_not_use`;
    `Core/Vocab.lean` carries the warning on all four sign predicates).
    `Pred.laneRightOfReference`, `laneLeftOfReference`,
    `inLaneRightOfReference` and `inLaneLeftOfReference` therefore appear
    nowhere below, and `two_way_road_rightmost_lane` exists as the regression
    scenario.

    `Pred.hasLaneToTheRight` needs no map convention. It reads the lane-to-lane
    `toRightOf` edge, which the generator computes in the **target** lane's own
    forward frame (`sgg_abstractor.py`), so the *pattern* of edges between two
    lanes is itself the evidence of whether they carry traffic the same way:
    asymmetric (`r toRightOf l`, `l toLeftOf r`) means same direction, mutual
    `toLeftOf` means opposite. `Vocab.lean`'s `opposedLanes` already excludes
    the opposing case, so an oncoming carriageway to the driver's right is not
    a lane the driver is required to move into.

  * **The positive form `hasLaneToTheRight` is used rather than
    `¬ₛ inRightmostLane`, and the two are not interchangeable.**
    `inRightmostLane` is false for a vehicle occupying no lane at all, so its
    negation convicts a vehicle that has left the carriageway entirely — which
    is not what "shall be driven upon the right half of the roadway" forbids,
    and is a different offence in any case. `off_roadway_is_not_convicted`
    fails if that substitution is ever made.

  * **THE OVERTAKING EXCEPTION IS FORMALIZED AS A DURATION. This is the
    weakest step in the file and the one most worth challenging.**

    The statute's exception is existential over other vehicles — "except when
    overtaking" presupposes a vehicle being overtaken — and the vocabulary has
    no predicate for "there is a same-direction vehicle to my right that I am
    passing". It cannot be recovered with a binder either: binders are
    quantified **universally** over the trace's entities, so adding a conjunct
    `¬ₛ overtaking v w` would still convict on the binding to some other,
    irrelevant vehicle `w` that the ego was never passing.

    So the exception is approximated by its *shape* instead. An overtake is a
    bounded manoeuvre: a driver pulls out, passes, and returns. What this rule
    forbids is therefore not being out of the rightmost lane, but **remaining**
    there for `overtakeGraceFrames` consecutive frames. Residues, all of which
    are real and none of which this rule's own scenarios can detect:

      (a) a slow overtake — a long queue, a heavy vehicle, an uphill pass —
          lasting more than three seconds is convicted, though the statute
          excuses it;
      (b) a driver who dips back into the right-hand lane for a single frame
          every three seconds is never convicted, though the statute does not
          excuse that at all;
      (c) the exception is granted to *every* stay in a left-hand lane under
          three seconds, whether or not anything was being overtaken. A brief
          unexcused excursion is acquitted.

  * **`overtakeGraceFrames := secondsToFrames 3 = 60`, and the number is ours,
    not the statute's.** Three seconds is chosen as roughly the shortest
    complete lane-out/pass/lane-in manoeuvre at ordinary road speeds; it is
    open to challenge in both directions, and residues (a) and (b) above move
    in opposite directions as it is changed. `brief_overtake_allowed` pins it
    from below — it holds the left lane for 36 frames, so any value at or below
    36 convicts a completed overtake.

    The window also inherits the capture-rate residue recorded in
    `carla/schema.json` → `capture_preconditions.capture_rate`: frames carry no
    timestamp, so 60 frames is 3 s only if the capture really ran at the 20 Hz
    that `Core/Scene.lean` freezes as `captureHz`. At 40 Hz the same formula
    grants only 1.5 s of grace.

  * **`hasLaneToTheRight` is slightly stricter than "the right half".** On a
    carriageway of three same-direction lanes it demands the rightmost lane,
    not merely the right-hand half, so a driver lawfully in the middle lane of
    three is convicted after three seconds. `Core/Vocab.lean` records this on
    `inRightmostLane`; the graph carries no count of a carriageway's lanes that
    would let the rule say "right half" instead. Recorded rather than patched —
    narrowing it would need lane-width or carriageway geometry, which
    `process_to_junction_rsv` collapses away
    (`carla/schema.json` → `unavailable.lane_width_and_markings`).

  * **`Pred.isEgo v` gates the formula, and that is a data restriction.** The
    statute binds every driver, but a non-ego vehicle's lane membership is the
    only structural fact available about it and the rule is only meaningful
    where the vehicle's own direction of travel is observable across frames.
    More importantly, leaving the gate off would let the rule convict any
    traffic-manager vehicle the capture happens to render in a left-hand lane,
    with no way to tell an overtake from a violation. This rule therefore makes
    no claim about a non-ego vehicle.

  * **The lane binder `l` is a grounding witness, not part of the test.** The
    offence is decided by `hasLaneToTheRight v`, which quantifies over lanes
    internally. `l` is bound, and pinned honest by the conjunct `inLane v l`,
    so that the GROUND count reports which lane the ego was convicted in and so
    that a capture containing no lane nodes at all grounds zero times — the
    vacuity guard catches it — instead of passing silently.

  * **Shape and trace length.** `□ (¬ₛ .bounded overtakeGraceFrames offending)`:
    the safety shape, "at no position does the forbidden state hold for 60
    consecutive frames". `SFProp.frameSpan` is therefore 60, and
    `Core/Semantics.lean::loopBounded` reads a window running off the end of
    the trace as false — so a trace shorter than 60 frames reports compliant
    whatever it contains (`tools/check_spec.py` rejects those as
    `TRACE_TOO_SHORT`), and the last 59 frames of any trace are a blind zone in
    which a violation cannot be reported. Every scenario below is 80 frames,
    and `sustained_left_lane_violates` holds the forbidden state from frame 0
    so its verdict does not sit in the blind zone.

  * **Not validated against real data, and this is the rule in the library
    where that matters most.** The scenarios below were written from the same
    reading of the clause as the formula, so they cannot catch a misreading —
    and R0009 is the proof that this exact sentence can pass a full scenario
    set and still convict lawful driving on a capture. Until `run_spec monitor`
    has compared this rule against a human-labelled capture, treat it as
    unvalidated; it is the first rule that comparison should be pointed at.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Lane.R0008

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- How long the ego may stay in a lane that has a same-direction lane to its
    right before the stay stops being an overtake. 3 s = 60 frames at the
    reference 20 Hz capture rate. A formalization choice: the statute states no
    duration, and states an exception this vocabulary cannot express directly. -/
def overtakeGraceFrames : Nat := TrafficSpec.secondsToFrames 3

/-- Quantified over the ego vehicle and the lane it occupies. The lane binder
    is a grounding witness — see the header. -/
def schema : PropertySchema where
  name    := "keep_right_of_roadway"
  binders := [vehicleBinder "v", laneBinder "l"]
  formula := fun env =>
    let v := arg env 0
    let l := arg env 1
    -- "the ego is in lane `l`, and some same-direction lane lies to its right"
    -- — the forbidden state, held for `overtakeGraceFrames` consecutive frames.
    □ (¬ₛ (SFProp.bounded overtakeGraceFrames
             (isEgo v ⋀ inLane v l ⋀ hasLaneToTheRight v)))

def entry : RuleEntry where
  nodeId  := "Lane/R0008_keep_right_of_roadway"
  lawRefs := ["EX-LANE-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

private def egoId       : Nat := 1
private def laneRightId : Nat := 10
private def laneLeftId  : Nat := 11
private def roadId      : Nat := 20
private def offRoadId   : Nat := 30

private def egoEntity : Entity := mkEgo egoId .car "8.000"

/-- One two-lane, one-way carriageway: `Lane 7_-1` is the right-hand lane and
    `Lane 7_-2` the left-hand one. The lane-id numbers are incidental — nothing
    below reads them — and both lanes share a sign precisely because they carry
    traffic the same way, which is why the sign cannot decide this rule. -/
private def oneWayEntities : List Entity :=
  [ egoEntity
  , mkLane laneRightId "Lane 7_-1"
  , mkLane laneLeftId  "Lane 7_-2"
  , mkRoad roadId "Road 7" ]

/-- The **asymmetric** edge pattern, which is how the generator marks two lanes
    of the SAME direction of travel: each left/right edge is computed in the
    target lane's own forward frame, so a consistent pair of headings yields one
    `toRightOf` and one `toLeftOf`. -/
private def oneWayStructureRels : List Relation :=
  [ mkRel laneRightId .isIn roadId
  , mkRel laneLeftId  .isIn roadId
  , mkRel laneRightId .toRightOf laneLeftId
  , mkRel laneLeftId  .toLeftOf  laneRightId ]

/-- One frame of the one-way carriageway with the ego in `lane`. -/
private def oneWayFrame (lane : Nat) : Scene :=
  frame oneWayEntities (oneWayStructureRels ++ [ mkRel egoId .isIn lane ])

private def inRight : Scene := oneWayFrame laneRightId
private def inLeft  : Scene := oneWayFrame laneLeftId

/-- Eighty frames in the right-hand lane. No same-direction lane lies to the
    right of it, so the forbidden state never holds for a single frame. -/
def traceRightmostThroughout : Trace :=
  List.replicate 80 inRight

/-- A completed overtake: ten frames in the right-hand lane, thirty-six in the
    left-hand one (frames 10–45), then thirty-four back on the right. Thirty-six
    consecutive offending frames is short of the sixty-frame grace window, so
    the manoeuvre is excused. Set `overtakeGraceFrames` to 36 or less and this
    scenario convicts a lawful overtake. -/
def traceBriefOvertake : Trace :=
  List.replicate 10 inRight ++ List.replicate 36 inLeft ++ List.replicate 34 inRight

/-- Eighty frames in the left-hand lane save for the last nine: frames 0–70 are
    seventy-one consecutive offending frames, so a full sixty-frame window fits
    starting at frame 0, well clear of the trailing fifty-nine-frame blind zone.
    The ego eventually returns to the right, which does not undo the offence. -/
def traceSustainedLeftLane : Trace :=
  List.replicate 71 inLeft ++ List.replicate 9 inRight

/-- The same carriageway plus the singleton `Off Road` node, with the ego on it
    and in no lane at all. -/
private def offRoadFrame : Scene :=
  frame (oneWayEntities ++ [ mkOffRoad offRoadId ])
        (oneWayStructureRels ++ [ mkRel egoId .isIn offRoadId ])

/-- Eighty frames with the ego off the carriageway entirely. A vehicle in no
    lane is not occupying a lane that has another lane to its right, so the
    first sentence has nothing to say about it. Write the offence as
    `¬ₛ inRightmostLane v` instead of `hasLaneToTheRight v` and this scenario
    convicts. -/
def traceOffRoadway : Trace :=
  List.replicate 80 offRoadFrame

----------------------------------------------------------------------
-- The R0009 regression: an ordinary two-way road
----------------------------------------------------------------------

private def twoWayEgoLaneId : Nat := 12
private def twoWayOppLaneId : Nat := 13
private def twoWayRoadId    : Nat := 21

/-- A two-way road. The ego's lane is `Lane 5_-1` and the oncoming lane is
    `Lane 5_1`, so the two carry **opposite** lane-id signs — exactly the
    configuration `Lane/R0009` read as "the ego is on the right half". -/
private def twoWayEntities : List Entity :=
  [ egoEntity
  , mkLane twoWayEgoLaneId "Lane 5_-1"
  , mkLane twoWayOppLaneId "Lane 5_1"
  , mkRoad twoWayRoadId "Road 5" ]

/-- The **mutual** edge pattern, which is how the generator marks two lanes of
    OPPOSITE direction: each lane is judged from its own heading, so each comes
    out `toLeftOf` the other. The explicit `opposes` edge the generator emits
    between adjacent lane ids of one road is included as well. -/
private def twoWayFrame : Scene :=
  frame twoWayEntities
    [ mkRel twoWayEgoLaneId .isIn twoWayRoadId
    , mkRel twoWayOppLaneId .isIn twoWayRoadId
    , mkRel twoWayEgoLaneId .toLeftOf twoWayOppLaneId
    , mkRel twoWayOppLaneId .toLeftOf twoWayEgoLaneId
    , mkRel twoWayEgoLaneId .opposes  twoWayOppLaneId
    , mkRel twoWayOppLaneId .opposes  twoWayEgoLaneId
    , mkRel egoId .isIn twoWayEgoLaneId ]

/-- Eighty frames of ordinary lawful driving on a two-way road: the only other
    lane opposes, so it is not a same-direction lane to the right and the ego is
    already as far right as its direction of travel goes.

    This is the scenario the deleted `Lane/R0009` could not have survived on
    real data — it read the sentence off the lane-id sign and convicted fifty
    frames of exactly this situation in the bundled sceneflow capture. -/
def traceTwoWayRightmost : Trace :=
  List.replicate 80 twoWayFrame

def scenarios : List Scenario :=
  [ { name := "rightmost_lane_throughout"
    , trace := traceRightmostThroughout
    , expected := true }
  , { name := "brief_overtake_allowed"
    , trace := traceBriefOvertake
    , expected := true }
  , { name := "two_way_road_rightmost_lane"
    , trace := traceTwoWayRightmost
    , expected := true }
  , { name := "off_roadway_is_not_convicted"
    , trace := traceOffRoadway
    , expected := true }
  , { name := "sustained_left_lane_violates"
    , trace := traceSustainedLeftLane
    , expected := false } ]

end TrafficSpec.Rules.Lane.R0008
