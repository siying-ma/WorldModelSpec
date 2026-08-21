/-
  Rule R0025 — driving against the direction of travel of the lane occupied,
  WITH NO OTHER VEHICLE PRESENT.

  Law text (EX-LANE-001, "Driving on the right"):
    "A vehicle shall be driven upon the right half of the roadway, except when
     overtaking. A vehicle shall not occupy a lane that opposes the flow of
     traffic while another vehicle is approaching in that lane."

  SCOPE — THE FIRST SENTENCE, AND THE CELL NO OTHER RULE REACHES
  -------------------------------------------------------------
  This file formalizes the **first** sentence: the bare keep-right obligation,
  which is unconditional and mentions no other road user. The offence it reports
  is an ego vehicle that progresses from one lane node to the next *upstream*
  along the lane chain — against the flow the graph itself records — and stays
  there.

  WHY THIS IS NOT A DUPLICATE OF `Lane/R0023_wrong_way_with_vehicle_in_lane`
  -------------------------------------------------------------------------
  R0023's formula is

      isEgo v ⋀ inLane v lNow ⋀ inLane w lNow ⋀ ¬ₛ (isEgo w)
            ⋀ ◯ (inLane v lNext) ⋀ laneTravelsTo lNext lNow
            ⋀ ¬ₛ (inReverse v)

  and it carries the witness vehicle `w` because it formalizes SENTENCE 2, whose
  own words are "while another vehicle is approaching in that lane". Sentence 1
  says no such thing. Dropping `w` here is therefore **not a loosening of
  R0023** — it is the other sentence of the same section, and it convicts
  conduct that every sentence-2 detector in this library is structurally silent
  on: an empty road. `Lane/R0016_crossing_into_opposing_lane`,
  `Lane/R0017_wrong_way_progress_with_oncoming`,
  `Lane/R0022_occupying_lane_against_observed_flow` and R0023 all require a
  second actor to be present at all; none of them reports
  `wrong_way_progress_with_no_other_vehicle` below. **Neither this rule nor
  R0023 is redundant: an application enforcing EX-LANE-001 must register both,
  and deleting either loses a distinct sentence.**

  WHY `Lane/R0008_keep_right_of_roadway` IS ALSO BLIND TO IT
  ---------------------------------------------------------
  R0008 is `bounded 60 (isEgo v ⋀ inLane v l ⋀ hasLaneToTheRight v)`, and
  `Pred.hasLaneToTheRight` is `someLaneToTheRight`, which demands a lane `r`
  with `r toRightOf l` AND `!opposedLanes s r l` — a *same-direction* lane to
  the right. On an ordinary two-way road the generator emits the MUTUAL
  `toLeftOf` pattern between the two carriageways plus an `opposes` edge (each
  lateral edge is computed in the target lane's own forward frame, so mutual
  means opposite headings — `carla/schema.json` →
  `partially_available.which_half_of_the_roadway`). A lane in the *opposing*
  carriageway therefore has no same-direction lane to its right at all, and
  R0008 acquits an ego driving straight down the oncoming lane. R0008's own
  `two_way_road_rightmost_lane` scenario builds exactly that geometry, lawfully;
  put the ego in the other lane of that frame and nothing in the library speaks.

  THE DIRECTION EVIDENCE IS ASYMMETRIC, WHICH IS WHAT KEEPS THIS CLEAR OF
  THE DELETED `Lane/R0009` FAILURE MODE
  ----------------------------------------------------------------------
  * Nothing here touches `lane_id`. `Pred.laneRightOfReference`,
    `laneLeftOfReference`, `inLaneRightOfReference` and
    `inLaneLeftOfReference` appear nowhere below. The lane-id **sign** records
    which side of the OpenDRIVE reference line a lane was authored on — a map
    convention, not a legal side of the road. R0009 decided this same sentence
    that way, passed all four of its own scenarios, and then convicted 50 frames
    of lawful driving in the bundled sceneflow capture.
  * `Pred.oncoming` also appears nowhere. It is symmetric, so it establishes
    that a pair is converging but not which vehicle is misplaced — it convicts
    the victim as readily as the offender. This rule reads the ego's OWN
    observed motion against the lane chain's OWN `travelsTo` connectivity, so it
    names the ego and no other actor is involved at all.

  WHY THE `travelsTo` DIRECTION CAN BE TRUSTED (falsifiable — check it)
  --------------------------------------------------------------------
  `sgg_abstractor.py::process_to_junction_rsv` adds a lane-node `travelsTo` edge
  only from the base graph's waypoint OUT-edges (`for u, v, a in
  graph.out_edges(node)`, ~lines 202-218), and those come from `sgg.py`'s road
  graph, which chains waypoints in travel order (`zip(nodes, nodes[1:])`,
  ~lines 222-227) and copies CARLA's directed topology edges entry → exit.
  Lateral links are labelled `laneChange`, not `travelsTo`, by the explicit
  `if a['lane_change']` branch. So `travelsTo` is **not** symmetric and a lawful
  transition does not satisfy `laneTravelsTo lNext lNow`.
  THE THING TO WATCH: if a real capture turns out to carry `travelsTo` in BOTH
  directions between a pair of lane nodes, this rule convicts every capture. The
  `GROUND` / `RESULT` counts of `run_spec monitor` say so loudly — a grounding
  count in the hundreds with almost every lane pair violating is the signature.

  THE STRADDLE GUARD, AND WHY IT LIVES INSIDE THE WINDOW
  -----------------------------------------------------
  A lane node is a whole collapsed waypoint run, and an actor gets one `isIn`
  edge per driving node its bounding box overlaps, so at a boundary the ego is
  legitimately in TWO lane nodes for many frames. Bare
  `inLane v lNow ⋀ ◯ (inLane v lNext)` is then satisfied by every lawful
  crossing, in BOTH binder orders at once, and the rule convicts all driving.
  The guard is `¬ₛ (inLane v lNow)` — a genuine, sustained departure from the
  downstream lane rather than a bounding-box overlap — and it is held for the
  WHOLE hold window.

  Two placement choices, both load-bearing:
  * The guard is INSIDE the bounded window, not at the anchor frame. It has to
    be sustained; one frame of it is exactly the noise it exists to reject
    (`boundary_straddle_is_not_convicted` fails the moment it moves out).
  * There is deliberately NO `¬ₛ (inLane v lNext)` conjunct at the anchor frame.
    A real wrong-way ego straddles too, and its only usable anchor is the last
    frame at which it is still in `lNow` — which IS a straddle frame. Adding
    that guard costs the whole detection.

  Formalization choices the text did not dictate
  ---------------------------------------------
  * **The hold window is `TrafficSpec.secondsToFrames 1` = 20 frames, and it is
    OURS, not the statute's.** The clause states no duration. One second of
    sustained upstream occupancy is the shortest window that survives
    lane-assignment jitter at a node boundary. A reviewer who wants a stricter
    rule may shorten it, at the cost of `boundary_straddle_is_not_convicted`
    becoming sensitive to how long the trace's straddle lasts.
  * **`Pred.isEgo v` gates the formula — a data restriction, not a reading of
    the statute**, which binds every driver. `reverse` is an ego-only attribute
    (`carla/schema.json` → `unavailable.non_ego_dynamics`), and
    `partially_available.wrong_way_driving` route (2) records that only the ego
    reliably carries the per-frame lane membership this construction reads. This
    rule makes no claim about a non-ego wrong-way driver.
  * **`¬ₛ (inReverse v)` acquits a driver backing along a lane.** A vehicle
    reversing occupies the lane facing the lawful way and is not "driven upon"
    the wrong half of the roadway. This is the same choice `Lane/R0023` made
    (its residue (3)); the cost is that this rule acquits a driver who reverses
    the wrong way down a lane for any distance. A reviewer reading the clause as
    covering that conduct should drop the conjunct and expect
    `reversing_along_the_lane` to flip.
  * **`vehicleBinder`, not `proximityVehicleBinder`.** No distance band and no
    angular edge is read anywhere below, so nothing restricts this rule to the
    base classes of `DEFAULT_PROXIMITY_RELATIONS`. That is deliberate, and
    neither a `Pred.withinMetres` nor a `Pred.oncoming` conjunct may be added
    "for safety": either one re-introduces a second-actor requirement and
    collapses this node back into R0023.

  RESIDUES
  --------
  (1) **The 20-frame window is a frame count at an ASSUMED 20 Hz.**
      `carla/schema.json` → `capture_preconditions.capture_rate`: `capture_hz`
      is a caller-supplied default of the capture script
      (`fixed_delta_seconds`), is not recorded in any capture, and frames carry
      no timestamp by construction. At 40 Hz this window is half a second.
  (2) **An ego that is wrong-way but never leaves one lane node is invisible
      here** — stationary, or driving inside a single long waypoint run. That
      cell needs `heading_relative_to_lane`, which `carla/schema.json` puts in
      the NOT-available tier (a lane node keeps no direction vector), or a
      witness vehicle, which is what R0022 and R0023 use. It is a residue of the
      abstraction, not a coverage gap in the law.
  (3) **The trailing 20 frames of any capture are a blind zone.** `frameSpan` is
      21 (one `◯` plus the window), `Core/Semantics.lean::loopBounded` reads a
      window that overruns the trace as false, and the shape here is
      `□ (¬ₛ …)` — so a wrong-way manoeuvre beginning in the last 21 frames
      reports compliant. Every scenario below is 60 frames with its anchor well
      clear of the end.
  (4) **Not validated against real data.** The scenarios were written from the
      same reading of the clause as the formula, so they cannot catch a
      misreading of it; `run_spec monitor` against a human-labelled capture is
      the only independent check. What they DO catch is the three ways this
      construction goes wrong: an inverted `laneTravelsTo`, a dropped or
      misplaced straddle guard, and a dropped reverse exclusion.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Lane.R0025

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- One second of sustained occupancy of the upstream lane, at the reference
    20 Hz capture rate — 20 frames. See residue (1): the rate is an assumption
    no capture records. -/
def holdFrames : Nat := TrafficSpec.secondsToFrames 1

/-- Quantified over the ego vehicle, the lane it occupies at the anchor frame,
    and the lane it moves into.

    Three binders and no witness vehicle: that absence is the whole point of the
    node — see the header on R0023. `vehicleBinder`, not
    `proximityVehicleBinder`, because no proximity or angular edge is read. -/
def schema : PropertySchema where
  name    := "travel_against_lane_flow"
  binders := [ vehicleBinder "v", laneBinder "lNow", laneBinder "lNext" ]
  formula := fun env =>
    let v     := arg env 0
    let lNow  := arg env 1
    let lNext := arg env 2
    -- "the ego is in `lNow`, is not reversing, and traffic in `lNext` flows
    --  onward INTO `lNow` — so `lNow → lNext` runs upstream — and from the next
    --  frame the ego holds `lNext` and has genuinely left `lNow` for a full
    --  second, rather than merely straddling the boundary between them."
    □ (¬ₛ ( isEgo v
          ⋀ inLane v lNow
          ⋀ ¬ₛ (inReverse v)
          ⋀ laneTravelsTo lNext lNow
          ⋀ ◯ (SFProp.bounded holdFrames
                 (inLane v lNext ⋀ ¬ₛ (inLane v lNow))) ))

def entry : RuleEntry where
  nodeId  := "Lane/R0025_travel_against_lane_flow"
  lawRefs := ["EX-LANE-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- One stretch of road in every trace: two consecutive lane nodes `Lane 5_-1`
-- (of `Road 5`) and `Lane 6_-1` (of `Road 6`), joined by the single
-- connectivity edge `Lane 5_-1 --travelsTo--> Lane 6_-1`. Traffic lawfully
-- flows laneA → laneB.
--
-- NO VEHICLE OTHER THAN THE EGO APPEARS IN ANY TRACE, and no proximity band
-- and no angular edge is emitted anywhere. That is not an economy: it is the
-- discriminator against R0016 / R0017 / R0022 / R0023, every one of which needs
-- a second actor and reports compliant on all four traces below.
--
-- Sixty frames each. `SFProp.frameSpan` is 21, so a trace must be at least 21
-- frames or `check_spec` rejects it as TRACE_TOO_SHORT; 60 also keeps every
-- anchor clear of the trailing blind zone of residue (3).
----------------------------------------------------------------------

private def egoId   : Nat := 1
private def laneAId : Nat := 10   -- Lane 5_-1, upstream
private def laneBId : Nat := 11   -- Lane 6_-1, downstream
private def roadAId : Nat := 20
private def roadBId : Nat := 21

/-- Forward gear, 8 m/s. -/
private def entities : List Entity :=
  [ mkEgo egoId .car "8.000"
  , mkLane laneAId "Lane 5_-1"
  , mkLane laneBId "Lane 6_-1"
  , mkRoad roadAId "Road 5"
  , mkRoad roadBId "Road 6" ]

/-- The same entity list with `reverse = "true"` on the ego. -/
private def entitiesReversing : List Entity :=
  [ (mkEgo egoId .car "1.500").withAttr "reverse" "true"
  , mkLane laneAId "Lane 5_-1"
  , mkLane laneBId "Lane 6_-1"
  , mkRoad roadAId "Road 5"
  , mkRoad roadBId "Road 6" ]

/-- Lane-to-road structure plus the one connectivity edge, identical in every
    frame of every trace: traffic flows `Lane 5_-1` → `Lane 6_-1`. -/
private def structureRels : List Relation :=
  [ mkRel laneAId .isIn roadAId
  , mkRel laneBId .isIn roadBId
  , mkRel laneAId .travelsTo laneBId ]

/-- One frame with the ego `isIn` each of `egoLanes` — a list, because the
    generator emits one `isIn` edge per driving node the bounding box overlaps
    and a boundary crossing really does produce two. -/
private def mkFrame (ents : List Entity) (egoLanes : List Nat) : Scene :=
  frame ents (structureRels ++ egoLanes.map (fun l => mkRel egoId .isIn l))

----------------------------------------------------------------------
-- 1. Lawful progress, with the flow
----------------------------------------------------------------------

/-- Frames 0-29 in `Lane 5_-1`, frames 30-59 in `Lane 6_-1`: the ego moves WITH
    the connectivity, forward gear, alone on the road.

    Both binder orders are acquitted, and for different reasons — which is what
    makes this the minimal pair for the direction of `laneTravelsTo`:
    * `lNow = laneA, lNext = laneB` — the motion that happens, but the required
      edge `laneB travelsTo laneA` does not exist.
    * `lNow = laneB, lNext = laneA` — that edge does hold, but the ego never
      enters `laneA` after leaving it, so the window cannot be filled.
    Write `laneTravelsTo lNow lNext` instead and this scenario convicts while
    scenario 2 keeps passing, so this is the only scenario that catches the
    inversion. -/
def traceLawfulWithFlow : Trace :=
  List.replicate 30 (mkFrame entities [laneAId])
    ++ List.replicate 30 (mkFrame entities [laneBId])

----------------------------------------------------------------------
-- 2. The offence: wrong way, and not another vehicle in sight
----------------------------------------------------------------------

/-- THE DISCRIMINATOR AGAINST THE WHOLE LIBRARY. The same stretch and the same
    `Lane 5_-1 travelsTo Lane 6_-1` edge, and again no vehicle but the ego. The
    ego is in `Lane 6_-1` for frames 0-19 and in `Lane 5_-1` from frame 20 on —
    upstream, and it stays there for forty frames.

    The forbidden pattern is observed at frame 19 with `lNow = Lane 6_-1`,
    `lNext = Lane 5_-1`: `laneTravelsTo lNext lNow` holds, and frames 20-39 all
    carry `inLane v lNext ⋀ ¬ₛ (inLane v lNow)` (19 + 21 ≤ 60, so the window is
    in bounds and clear of the blind zone).

    R0016 / R0017 / R0022 / R0023 all report compliant here for want of a second
    actor, and R0008 reports compliant because the opposing lane of a two-way
    road has no same-direction lane to its right. If this scenario ever passes,
    the rule has collapsed into R0023 and the node has failed. -/
def traceWrongWayAlone : Trace :=
  List.replicate 20 (mkFrame entities [laneBId])
    ++ List.replicate 40 (mkFrame entities [laneAId])

----------------------------------------------------------------------
-- 3. A lawful crossing that straddles the boundary for a long stretch
----------------------------------------------------------------------

/-- What a real lane-node crossing looks like: `isIn Lane 5_-1` alone for frames
    0-4, `isIn` BOTH lane nodes for frames 5-40 while the bounding box overlaps
    the boundary, then `isIn Lane 6_-1` alone for frames 41-59. Forward gear,
    no other vehicle. Lawful throughout — the ego moves laneA → laneB, with the
    flow.

    This is the regression test for the straddle guard. Drop
    `¬ₛ (inLane v lNow)` from inside the window and the binding
    `lNow = laneB, lNext = laneA` convicts thirty-six frames of ordinary lawful
    driving, because during the straddle BOTH memberships hold at once while
    `laneTravelsTo laneA laneB` holds too. With the guard, `inLane v laneA ⋀
    ¬ₛ (inLane v laneB)` is true only on frames 0-4 — five frames, nowhere near
    the twenty the window demands — so no anchor can fire. -/
def traceBoundaryStraddle : Trace :=
  List.replicate 5 (mkFrame entities [laneAId])
    ++ List.replicate 36 (mkFrame entities [laneAId, laneBId])
    ++ List.replicate 19 (mkFrame entities [laneBId])

----------------------------------------------------------------------
-- 4. Reversing back along the lane
----------------------------------------------------------------------

/-- The ego backs out of `Lane 6_-1` into `Lane 5_-1` — geometrically the same
    upstream progression as scenario 2, frames 0-29 then 30-59 — with
    `reverse = "true"` on every frame.

    A driver reversing along a lane faces the lawful way and is not "driven
    upon" the wrong half of the roadway. Drop `¬ₛ (inReverse v)` and this
    convicts: the anchor at frame 29 has its full window in frames 30-49. -/
def traceReversingAlongLane : Trace :=
  List.replicate 30 (mkFrame entitiesReversing [laneBId])
    ++ List.replicate 30 (mkFrame entitiesReversing [laneAId])

def scenarios : List Scenario :=
  [ { name := "lawful_progress_with_the_flow"
    , trace := traceLawfulWithFlow
    , expected := true }
  , { name := "wrong_way_progress_with_no_other_vehicle"
    , trace := traceWrongWayAlone
    , expected := false }
  , { name := "boundary_straddle_is_not_convicted"
    , trace := traceBoundaryStraddle
    , expected := true }
  , { name := "reversing_along_the_lane"
    , trace := traceReversingAlongLane
    , expected := true } ]

end TrafficSpec.Rules.Lane.R0025
