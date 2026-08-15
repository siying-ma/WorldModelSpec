/-
  Rule R0011 — driving upon the right half of the roadway.

  Law text (laws/example/laws.jsonl, id EX-LANE-001):
    "A vehicle shall be driven upon the right half of the roadway, except when
     overtaking. A vehicle shall not occupy a lane that opposes the flow of
     traffic while another vehicle is approaching in that lane."

  SCOPE — FIRST SENTENCE ONLY
  --------------------------
  EX-LANE-001 states two separate obligations; this node formalizes only the
  **first** ("shall be driven upon the right half of the roadway, except when
  overtaking"). Sentence 2 is `Lane/R0008_opposing_lane_oncoming` and is
  deliberately out of scope: R0008 needs a second vehicle to witness the
  direction of flow, so it cannot fire on an empty wrong-half stretch, and it
  says nothing about which half of the roadway anyone is on. The two rules
  overlap on a trace where both hold, and neither subsumes the other.

  THIS IS A REBUILD OF THE WITHDRAWN `Lane/R0009_right_half_of_roadway`
  --------------------------------------------------------------------
  R0009 read "the right half of the roadway" off the OpenDRIVE **lane-id sign**
  (`Pred.inLaneRightOfReference`). It passed all four of its own scenarios and a
  clean gate, and then convicted all 50 frames of lawful driving in the bundled
  sceneflow capture, whose carriageway is numbered positively. The lane-id sign
  records which side of the map's reference line a lane was *authored* on — every
  lane of one direction of travel shares it — not a legal side of the road
  (`carla/schema.json` → `partially_available.which_half_of_the_roadway.do_not_use`;
  `Core/Vocab.lean`, the warning on `laneRightOfReference`). None of
  `inLaneRightOfReference` / `inLaneLeftOfReference` / `laneRightOfReference` /
  `laneLeftOfReference` appears below, and `rightmost_lane_positive_lane_id` is
  the regression test that keeps them out.

  Formalization notes — every choice the text did not dictate
  ----------------------------------------------------------
  * **"the right half of the roadway" is read as same-direction lane adjacency,
    from the vehicle's own direction of travel.** The generator computes each
    lane-to-lane `toLeftOf` / `toRightOf` edge in the *target* lane's own forward
    frame (`sgg_abstractor.py`), so the edge pattern between two lanes reveals
    their relative direction of travel: asymmetric (`a toLeftOf b`, `b toRightOf
    a`) means same direction, mutual `toLeftOf` means opposite. A driver keeping
    right therefore has no *same-direction* lane to the right, and no map
    convention is involved.
  * **The offence is stated POSITIVELY, as `hasLaneToTheRight v`, not as
    `¬ₛ inRightmostLane v`.** The two differ on exactly one case: a vehicle that
    occupies no lane at all. `inRightmostLane` is false for it, so the negated
    form convicts a vehicle that has left the carriageway entirely — a different
    obligation, with its own antecedent and its own defences.
    `off_the_roadway_is_not_this_offence` pins that case down.
  * **The overtaking carve-out is a PERSISTENCE WINDOW, not a conjunct.** The
    statute excepts overtaking, and the vocabulary cannot express it directly:
    binders are universally quantified grounding-by-grounding and there is no
    existential binder, so `hasLaneToTheRight v ⋀ ¬ₛ overtaking v w` would
    convict the ego as soon as *any* vehicle in the trace is not the one being
    passed. Instead, an inner-lane occupancy is an offence only when it persists
    for `persistenceFrames` = `secondsToFrames 4` = **80 frames = 4 s** at the
    reference 20 Hz capture rate (frames carry no clock —
    `carla/schema.json` → `unavailable.timestamps`). A completed overtake
    reoccupies the kerbside lane well inside that; a cruise does not.
    `brief_overtake_in_the_left_lane` and `sustained_left_lane_cruise` differ in
    exactly this one respect. Both the 4 s figure and the choice of a duration
    proxy over an intent test are open to challenge: 4 s is the whole change a
    reviewer needs to make, and it is named once, below.
  * **The obligation is gated on `Pred.isEgo v`.** The rule is a monitor on the
    conduct of the driver being observed. It is not that another vehicle's lane
    membership is unavailable — `isIn` lane edges are emitted for every actor —
    but that this specification takes no position on third parties, exactly as
    the other rules in the library do. A non-ego vehicle cruising the inner lane
    is reported compliant here; every scenario below carries such a vehicle so
    that the gate is exercised rather than assumed.

  Residues — what this rule does not measure
  ------------------------------------------
  1. **Stricter than the statute on three or more lanes.** `hasLaneToTheRight`
     is the complement of "rightmost lane of my direction", so on a
     three-lane carriageway the middle lane is convicted even though it is
     within the right-hand *half*. The statute's line is at the half; the
     graph's is at the lane. Recorded in `Core/Vocab.lean` on `inRightmostLane`.
  2. **"Half of the roadway" is never measured as a width.** The junction-RSV
     abstraction collapses the waypoint runs and keeps no carriageway width, no
     lane-marking type and no kerb (`carla/schema.json` →
     `unavailable.lane_width_and_markings`), so the reading is purely
     lane-adjacency. A single wide lane, a hard shoulder, or a lane straddled
     rather than occupied are all invisible to it.
  3. **Every sustained lawful reason to hold the inner lane is convicted.** The
     window cannot tell an overtake from a left-turn approach, from passing a
     stationary obstruction, from a lane closure, or from a driver told to hold
     that lane by a sign — none of which the graph distinguishes from a cruise.
     This is the price of proxying the carve-out by duration, and it is the
     largest source of false convictions to expect on a real capture.
  4. **A genuine violation shorter than 4 s is not reported**, and by strong-next
     semantics (`Core/Semantics.lean`, `loopBounded`) neither is one that begins
     within the last 79 frames of a trace. Under-reporting, chosen so the
     carve-out is honoured.
  5. **Lane membership is a nearest-waypoint assignment.** Mid-lane-change the
     ego may map to either lane node for a frame or two; the window absorbs
     that, but the boundary of an occupancy is not sharp.
  6. **Check the grounding count and the verdict on a real capture before
     believing this rule.** The scenarios below were written by the same reading
     that wrote the formula, which is precisely how R0009 passed its gate; only
     `run_spec monitor` against a human-labelled capture is independent of it.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Lane.R0011

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The forbidden state: the monitored driver occupies a lane that has another
    **same-direction** lane to its right, i.e. is not keeping right.

    `hasLaneToTheRight` is false for a vehicle in no lane at all, so leaving the
    carriageway is not this offence — see the header. -/
def notKeepingRight (v : EntityId) : SFProp :=
  isEgo v ⋀ hasLaneToTheRight v

/-- The overtaking carve-out, proxied by duration: 4 s = 80 frames at the
    reference 20 Hz capture rate. A formalization choice, not something the text
    states — see the PERSISTENCE note in the header. This `def` is the whole
    change a reviewer who wants a different threshold has to make. -/
def persistenceFrames : Nat := TrafficSpec.secondsToFrames 4

/-- At no position does the ego hold a lane with a same-direction lane to its
    right for `persistenceFrames` consecutive frames. -/
def schema : PropertySchema where
  name    := "keep_right_of_roadway"
  binders := [vehicleBinder "v"]
  formula := fun env =>
    let v := arg env 0
    □ (¬ₛ (.bounded persistenceFrames (notKeepingRight v)))

def entry : RuleEntry where
  nodeId  := "Lane/R0011_keep_right_of_roadway"
  lawRefs := ["EX-LANE-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- Two road structures, each carrying the lane-to-lane edge pattern the
-- generator actually emits, because that pattern is the entire evidence this
-- rule reads:
--
--   same direction  asymmetric — `kerbside toRightOf inner`,
--                   `inner toLeftOf kerbside`
--   opposite        mutual     — each lane is `toLeftOf` the other, since each
--                   is judged in its own forward frame
--
-- Both lanes, the road and the singleton `Off Road` node are present in every
-- frame of every trace, so structure a scenario does not use is never the
-- reason a verdict changes. Every trace also carries a non-ego car, which
-- grounds the `v` binder a second time and must always come out compliant.
--
-- Trace lengths are all longer than the 80-frame window: the window is stated
-- in seconds and the traces are `List.replicate`, so the traces were built to
-- fit the window rather than the window shrunk to fit the traces.
----------------------------------------------------------------------

-- One-way carriageway, both lanes numbered POSITIVE — the bundled sceneflow
-- capture's geometry, and what R0009 died on. On the left of an OpenDRIVE
-- reference line the ids grow away from the centre, so `Lane 7_2` is the
-- kerbside lane and `Lane 7_1` the inner one.
private def laneKerb  : Nat := 10
private def laneInner : Nat := 11
private def road7     : Nat := 12

-- Two-way road, one lane each way.
private def laneOwn : Nat := 20
private def laneOpp : Nat := 21
private def road9   : Nat := 22

private def offRd : Nat := 30

private def oneWayEntities : List Entity :=
  [ mkLane laneKerb  "Lane 7_2"
  , mkLane laneInner "Lane 7_1"
  , mkRoad road7     "Road 7"
  , mkOffRoad offRd ]

/-- The asymmetric pattern: the kerbside lane is to the right of the inner lane
    and the inner lane is to the left of the kerbside one, which is what the
    generator emits when both carry traffic the same way. The `laneChange` edges
    are what makes the overtake in `traceBriefOvertakeInTheLeftLane` a lawful
    manoeuvre; nothing in the formula reads them. -/
private def oneWayRels : List Relation :=
  [ mkRel laneKerb  .isIn road7
  , mkRel laneInner .isIn road7
  , mkRel laneKerb  .toRightOf laneInner
  , mkRel laneInner .toLeftOf  laneKerb
  , mkRel laneKerb  .laneChange laneInner
  , mkRel laneInner .laneChange laneKerb ]

private def twoWayEntities : List Entity :=
  [ mkLane laneOwn "Lane 9_-1"
  , mkLane laneOpp "Lane 9_1"
  , mkRoad road9   "Road 9"
  , mkOffRoad offRd ]

/-- The mutual-`toLeftOf` pattern, plus the `opposes` edges the generator emits
    between adjacent lane ids of opposite heading. No `toRightOf` edge exists
    between lanes of opposite heading, which is why the oncoming carriageway is
    not a lane to the ego's right. -/
private def twoWayRels : List Relation :=
  [ mkRel laneOwn .isIn road9
  , mkRel laneOpp .isIn road9
  , mkRel laneOwn .opposes  laneOpp
  , mkRel laneOpp .opposes  laneOwn
  , mkRel laneOwn .toLeftOf laneOpp
  , mkRel laneOpp .toLeftOf laneOwn ]

/-- Ego (id 1) `isIn` `egoNode`, plus `car_0` (id 2) `isIn` `otherNode`, on the
    one-way carriageway. Cruising: 12 m/s under light throttle. -/
private def oneWayFrame (egoNode otherNode : Nat) : Scene :=
  frame
    ([ mkEgo 1 .car "12.0" "0.0" "0.4" "0.0", mkActor 2 "car_0" .car ]
      ++ oneWayEntities)
    (oneWayRels ++ [ mkRel 1 .isIn egoNode, mkRel 2 .isIn otherNode ])

/-- The same pair on the two-way road. -/
private def twoWayFrame (egoNode otherNode : Nat) : Scene :=
  frame
    ([ mkEgo 1 .car "12.0" "0.0" "0.4" "0.0", mkActor 2 "car_0" .car ]
      ++ twoWayEntities)
    (twoWayRels ++ [ mkRel 1 .isIn egoNode, mkRel 2 .isIn otherNode ])

/-- REGRESSION TEST for the withdrawn R0009 — do not remove or weaken it.

    A one-way carriageway of two same-direction lanes, both numbered
    **positive** (`lane_id` +1 and +2), which is the bundled sceneflow capture's
    geometry. The ego holds the kerbside lane `Lane 7_2` for all 100 frames. No
    lane is `toRightOf` `Lane 7_2`, so the ego is keeping right and the driving
    is lawful.

    The lane-id-sign reading convicts this trace on every frame: both lanes are
    `laneLeftOfReference`, so `inLaneRightOfReference` is false throughout. The
    correct reading must report it COMPLIANT. `car_0` holds the inner lane and
    is not the ego, so it is compliant too. -/
def traceRightmostLanePositiveLaneId : Trace :=
  List.replicate 100 (oneWayFrame laneKerb laneInner)

/-- A two-way road, one lane each way. The ego holds its own lane `Lane 9_-1`
    for all 100 frames and `car_0` holds the opposing lane. The two lanes are
    joined by `opposes` and by the mutual-`toLeftOf` pattern, so the oncoming
    carriageway is not counted as a lane to the ego's right and ordinary two-way
    driving is lawful. -/
def traceTwoWayRoadSingleLaneEachWay : Trace :=
  List.replicate 100 (twoWayFrame laneOwn laneOpp)

/-- The ego is `isIn` the `Off Road` node and occupies no lane for all 100
    frames, while the two-lane same-direction carriageway is present in every
    frame. `hasLaneToTheRight` is false for a vehicle in no lane, so this rule
    stays silent: leaving the carriageway is a different obligation.

    This is the scenario that distinguishes the positive offence form from
    `¬ₛ inRightmostLane`, which is false here and would convict. -/
def traceOffTheRoadwayIsNotThisOffence : Trace :=
  List.replicate 100 (oneWayFrame offRd laneInner)

/-- The overtaking carve-out. 120 frames on the same carriageway: the ego holds
    the kerbside lane for 20 frames, moves into the inner (left) lane for 40
    frames — half the 80-frame window — then returns to the kerbside lane for
    the remaining 60 and stays there. The longest run of inner-lane occupancy is
    40 frames, so `.bounded 80` never closes and the manoeuvre is lawful.

    Differs from `traceSustainedLeftLaneCruise` only in how long the left-lane
    occupancy lasts. -/
def traceBriefOvertakeInTheLeftLane : Trace :=
  List.replicate 20 (oneWayFrame laneKerb  laneInner)
    ++ List.replicate 40 (oneWayFrame laneInner laneKerb)
    ++ List.replicate 60 (oneWayFrame laneKerb  laneInner)

/-- The offence. The same carriageway with the same edge pattern, but the ego
    holds the INNER lane `Lane 7_1` — the one with a same-direction lane
    (`Lane 7_2`, `toRightOf` it) to its right — for all 100 frames, comfortably
    longer than the 80-frame window. No overtake lasts five seconds.

    Differs from `traceRightmostLanePositiveLaneId` in exactly one respect:
    which of the two lanes the ego occupies. `car_0` sits in the kerbside lane
    and is compliant, so the failing grounding is the ego's alone. -/
def traceSustainedLeftLaneCruise : Trace :=
  List.replicate 100 (oneWayFrame laneInner laneKerb)

def scenarios : List Scenario :=
  [ { name := "rightmost_lane_positive_lane_id",  trace := traceRightmostLanePositiveLaneId,  expected := true }
  , { name := "two_way_road_single_lane_each_way", trace := traceTwoWayRoadSingleLaneEachWay, expected := true }
  , { name := "off_the_roadway_is_not_this_offence", trace := traceOffTheRoadwayIsNotThisOffence, expected := true }
  , { name := "brief_overtake_in_the_left_lane",  trace := traceBriefOvertakeInTheLeftLane,   expected := true }
  , { name := "sustained_left_lane_cruise",       trace := traceSustainedLeftLaneCruise,      expected := false } ]

end TrafficSpec.Rules.Lane.R0011
