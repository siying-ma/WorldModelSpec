/-
  Rule R0020 — yield to an emergency vehicle sharing the ego's lane, for the one
  vehicle class `Emergency/R0012` is structurally blind to: the van.

  Law text (EX-EMERGENCY-001, "Emergency vehicles"):
    "Upon the approach of an authorised emergency vehicle, the driver of every
     other vehicle shall yield the right of way and shall drive to the
     right-hand edge of the roadway, clear of any intersection."

  SCOPE — WHY THIS RULE EXISTS ALONGSIDE Emergency/R0012
  -----------------------------------------------------
  `Emergency/R0012_pull_right_for_emergency` formalizes both limbs of this same
  clause, and its own header records why it cannot see an ambulance: its
  antecedent is `isEmergency w ⋀ inProximity v w`, and CARLA's ambulance is
  `vehicle.ford.ambulance`, whose base class is **van**, for which the generator
  emits no proximity and no angular edge at all
  (`carla/schema.json` → `relation_coverage`; `Core/Scene.lean`,
  `proximityVehicleTypes`). On a capture whose responding vehicle is an
  ambulance, R0012 grounds and reports `compliant` for every frame however the
  driver behaved.

  That gap is closable, because the restriction is a property of
  `DEFAULT_PROXIMITY_RELATIONS` **only**: the `isIn` lane edge is emitted for
  every actor, van included. So this rule keeps R0012's consequent verbatim and
  replaces its distance antecedent with lane membership:

      □ (¬ₛ .bounded graceFrames
             (isEgo v ⋀ isEmergency w ⋀ baseClass w "van" ⋀ sameLane v w
              ⋀ (hasLaneToTheRight v ⋁ inAnyJunction v)))

  Read positively: the ego must not **remain**, for `graceFrames` consecutive
  frames, in a state where an authorised emergency van occupies the ego's own
  lane while the ego is either not as far right as its direction of travel
  allows, or still inside an intersection.

  **`baseClass w "van"` is a deliberate restriction, not an omission.** It makes
  this rule strictly complementary to R0012 rather than a looser duplicate of
  it. `scripts/capture_eval.py` aggregates a law as violated when *any* covering
  rule reports a violation, so widening the trigger here to every emergency
  vehicle could only add false positives to conduct R0012 already convicts —
  R0012's proximity antecedent covers the police car (`car`) and the firetruck
  (`truck`) — whereas restricting it to the class R0012 cannot observe adds
  recall and nothing else. `emergency_car_is_R0012s_case_not_this_rule` below is
  the discriminating scenario: drop the conjunct and the two rules convict the
  same event twice while this one contributes nothing.

  **No proximity or angular predicate appears anywhere in this file.**
  `withinMetres`, `inProximity`, `dangerouslyClose`, `following`,
  `followingWithin`, `oncoming`, `inFrontOf` and `behind` all reduce to edges
  that are never emitted for a van, so any one of them would make the antecedent
  unsatisfiable — the exact failure this node exists to repair. For the same
  reason `w` is bound with `vehicleBinder` and **not** `proximityVehicleBinder`:
  `proximityVehicleTypes` excludes `.van`, which is the only class this rule is
  about.

  Formalization notes — the readings the text did not settle
  ---------------------------------------------------------
  * **"Upon the approach" degrades further here than in R0012, to "occupies the
    ego's lane node".** With no distance band and no angular edge available for
    a van there is nothing left to express approach with, and
    `process_to_junction_rsv` collapses a whole waypoint run into a single lane
    node, so "same lane" carries no bound on separation. An emergency van tens
    of metres ahead, or standing still, or not responding to a call at all —
    the graph has no siren channel and no light-bar state
    (`Core/Vocab.lean` §7 lists every light attribute a non-ego vehicle carries;
    none of them is an emergency beacon) — attaches the duty. This is an
    over-conviction risk of the same family R0012 records for its 25 m band, one
    step wider, and it is the **first thing to check on a labelled capture**.

  * **Silent about an ambulance in an adjacent or an opposing lane.**
    `Pred.sameRoad` would have widened the trigger and was deliberately not
    used: on an undivided road it reaches the other carriageway, so an ambulance
    travelling the opposite way — to which the "drive to the right-hand edge"
    limb responds quite differently — would attach the same duty. The residue is
    a missed violation where a driver fails to yield to an ambulance in the next
    lane over, which is the direction of error this abstraction can support.

  * **"Yield the right of way" contributes no independent content**, exactly as
    in R0012: the graph carries no priority annotation whatsoever
    (`carla/schema.json` → `unavailable.right_of_way`), so the duty is exhausted
    by the two positional limbs. A driver who stayed rightmost and clear of the
    junction and still obstructed the ambulance is not convicted here.

  * **"The right-hand edge of the roadway" degrades to "the rightmost lane of my
    own direction of travel".** There is no kerb, no carriageway width and no
    lane marking in the abstraction (`unavailable.lane_width_and_markings`), so
    a driver who pulled onto the shoulder and one who merely took the rightmost
    lane are indistinguishable.

    `Pred.hasLaneToTheRight` is used rather than `¬ₛ Pred.inRightmostLane`, for
    R0012's reason: `inRightmostLane` is false for a vehicle occupying no lane
    at all, so negating it would convict a driver who pulled fully off the
    carriageway. And no `lane_id`-sign predicate appears
    (`laneRightOfReference` / `laneLeftOfReference` / `inLaneRightOfReference` /
    `inLaneLeftOfReference`): the sign records which side of the OpenDRIVE
    reference line a lane was authored on, not a legal side of the road. The
    deleted `Lane/R0009` read it that way, passed all four of its own scenarios,
    and convicted 50 frames of lawful driving in the bundled sceneflow capture.
    `hasLaneToTheRight` reads the lane-to-lane `toRightOf` edge, computed in the
    target lane's own forward frame, and `Vocab.lean`'s `opposedLanes` excludes
    the mutual-`toLeftOf` (opposite-direction) case — so an oncoming carriageway
    to the driver's right is never a lane this rule demands they move into.

  * **`special_class` is `actors.py::get_special_type`, and whether CARLA's
    ambulance blueprint is tagged `emergency` there is not something the
    scenarios below can settle.** They assert what the predicate does given the
    attribute, not that the generator sets it. If this rule grounds on a capture
    that contains an ambulance but never fires, read that actor's
    `special_class` before concluding the driving was lawful — an untagged
    ambulance is a silent acquittal, not a compliance finding.

  * **`graceFrames := secondsToFrames 2 = 40` is ours, not the statute's**, and
    matches R0012 so that the two rules grant the same allowance for the same
    duty. The statute states no duration and implies immediate compliance; two
    seconds is a plausible allowance to perceive the vehicle and complete a lane
    change or clear the junction. It is 2 s **only at the assumed 20 Hz** —
    frames carry no timestamp (`unavailable.timestamps`) and `capture_hz = 20`
    is a caller-chosen simulator setting no capture records
    (`capture_preconditions.capture_rate`), so at 40 Hz the same formula grants
    1 s. `ego_moves_right_within_the_grace_window` pins it from below: it holds
    the offending state for 25 frames, so any `graceFrames` at or below 25
    convicts a driver who did pull over promptly. Two residues, neither
    detectable by the scenarios: a driver boxed in by traffic for more than two
    seconds is convicted though they could not comply, and one who dips into the
    rightmost lane for a single frame every two seconds is never convicted.

  * **Shape and trace length.** `SFProp.frameSpan` of `.bounded 40 φ` is 40, and
    `Core/Semantics.lean::loopBounded` reads a window running off the end of the
    trace as false — so on a trace shorter than 40 frames this rule reports
    *compliant* whatever it contains (`tools/check_spec.py` rejects those as
    `TRACE_TOO_SHORT`), and the last 39 frames of any trace are a blind zone in
    which a violation cannot be reported. Every scenario below is 80 frames,
    twice the span, and both violating states start at frame 0.

  * **Not validated against real data.** The scenarios below were written from
    the same reading of the clause as the formula, so they cannot catch a
    misreading of it. Until `run_spec monitor` has compared this rule against a
    human-labelled capture, treat it as unvalidated; the two things to look at
    first are the grounding count (does the capture contain an emergency van at
    all?) and whether the lane-membership antecedent over-fires on a stationary
    or non-responding one.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Emergency.R0020

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- How long the ego may remain un-pulled-over, or inside a junction, while an
    emergency van shares its lane, before the stay becomes a failure to yield.
    2 s = 40 frames at the reference 20 Hz capture rate, chosen to match
    `Emergency/R0012.graceFrames` for the same duty. A formalization choice: the
    statute states no duration — see the header. -/
def graceFrames : Nat := TrafficSpec.secondsToFrames 2

/-- Quantified over `vehicleTypes`, which admits `.van`; **not** over
    `proximityVehicleTypes`, which excludes it and would leave this rule with
    nothing to bind. Effective on the ego vehicle only, via `isEgo v`. -/
def schema : PropertySchema where
  name    := "yield_to_emergency_van_in_lane"
  binders := [vehicleBinder "v", vehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    -- "an authorised emergency van `w` occupies the ego `v`'s own lane, and `v`
    -- is either not as far right as its direction of travel allows or still
    -- inside an intersection" — the forbidden state, held for `graceFrames`
    -- consecutive frames.
    □ (¬ₛ (SFProp.bounded graceFrames
             (isEgo v ⋀ isEmergency w ⋀ baseClass w "van" ⋀ sameLane v w
              ⋀ (hasLaneToTheRight v ⋁ inAnyJunction v))))

def entry : RuleEntry where
  nodeId  := "Emergency/R0020_yield_to_emergency_van_in_lane"
  lawRefs := ["EX-EMERGENCY-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- One map throughout: a two-lane, one-way carriageway `Road 7` carrying
-- `Lane 7_-1` (the rightmost lane of the direction of travel) and `Lane 7_-2`
-- (which has `Lane 7_-1` to its right), plus a separate junction road
-- `Road 100` inside `Junction 5` carrying the single lane `Lane 100_-1`. The
-- junction structure is present in every trace so that the second limb never
-- reads absent structure by accident; only the third trace puts the ego in it.
--
-- The four actors carry distinct names — `carla/adapter.py` keys entities by
-- name, so two nodes sharing one collapse into a single entity.
----------------------------------------------------------------------

private def egoId      : Nat := 1
private def emVanId    : Nat := 2
private def plainVanId : Nat := 3
private def policeId   : Nat := 4

private def laneRightId : Nat := 10
private def laneLeftId  : Nat := 11
private def roadId      : Nat := 20
private def junLaneId   : Nat := 12
private def junRoadId   : Nat := 21
private def junctionId  : Nat := 30

private def egoEntity : Entity := mkEgo egoId .car "8.000"

/-- The ambulance: base class **van**, `special_class = "emergency"`. This is the
    vehicle `Emergency/R0012` cannot see, and the whole point of this rule. -/
private def emVanEntity : Entity := mkEmergency emVanId "van_0" .van

/-- The minimal pair partner for `isEmergency`: an ordinary delivery van, same
    base class, no `special_class` at all (an absent attribute reads false). -/
private def plainVanEntity : Entity := mkActor plainVanId "van_1" .van

/-- The minimal pair partner for `baseClass w "van"`: an emergency **car**, i.e.
    the police car, which is `Emergency/R0012`'s case and not this rule's. -/
private def policeEntity : Entity := mkEmergency policeId "police_0" .car

private def structureEntities : List Entity :=
  [ mkLane laneRightId "Lane 7_-1"
  , mkLane laneLeftId  "Lane 7_-2"
  , mkRoad roadId "Road 7"
  , mkLane junLaneId "Lane 100_-1"
  , mkRoad junRoadId "Road 100"
  , mkJunction junctionId "Junction 5" ]

/-- The **asymmetric** `toRightOf` / `toLeftOf` pair is how the generator marks
    two lanes of the SAME direction of travel: each edge is computed in the
    target lane's own forward frame, so consistent headings give one `toRightOf`
    and one `toLeftOf` (a *mutual* `toLeftOf` pair would mean opposing lanes,
    which `Vocab.lean`'s `opposedLanes` filters out of `hasLaneToTheRight`).

    `Pred.inAnyJunction` walks the lane → road → junction `isIn` chain, which is
    why `Road 100` — not `Lane 100_-1` — carries the edge to `Junction 5`. -/
private def structureRels : List Relation :=
  [ mkRel laneRightId .isIn roadId
  , mkRel laneLeftId  .isIn roadId
  , mkRel laneRightId .toRightOf laneLeftId
  , mkRel laneLeftId  .toLeftOf  laneRightId
  , mkRel junLaneId .isIn junRoadId
  , mkRel junRoadId .isIn junctionId ]

/-- One frame: the ego in lane `egoLane` and the other vehicle `w` in lane
    `wLane`. No proximity or angular edge is emitted for any pair — for a van
    the generator emits none, and this rule reads none. -/
private def sceneOf (w : Entity) (egoLane wLane : Nat) : Scene :=
  frame
    ([egoEntity, w] ++ structureEntities)
    (structureRels ++
      [ mkRel egoId .isIn egoLane
      , mkRel w.id.val .isIn wLane ])

/-- A driver who reacted in time: the ambulance is in `Lane 7_-2` throughout,
    and the ego shares that lane — with `Lane 7_-1` to its right — for frames
    0–24 before moving into the rightmost lane for frames 25–79. It is never in
    a junction, so the forbidden state holds for 25 consecutive frames from
    frame 0 and then never again: short of the 40-frame grace window, so the
    manoeuvre is excused.

    This trace pins `graceFrames` from below — set it to 25 or less and a driver
    who pulled over within a second and a quarter is convicted. -/
def traceMovesRightInTime : Trace :=
  List.replicate 25 (sceneOf emVanEntity laneLeftId laneLeftId)
  ++ List.replicate 55 (sceneOf emVanEntity laneRightId laneLeftId)

/-- Failure of the first limb: 80 frames with the ambulance in `Lane 7_-2` and
    the ego beside it in the same lane, which has `Lane 7_-1` — a
    same-direction lane — to its right the whole time, and never a junction.
    The offending state starts at frame 0, so a complete 40-frame window fits at
    position 0, clear of the trailing 39-frame blind zone. -/
def traceStaysLeft : Trace :=
  List.replicate 80 (sceneOf emVanEntity laneLeftId laneLeftId)

/-- Failure of the second limb, isolated: 80 frames with both vehicles in
    `Lane 100_-1`, inside `Junction 5` via the lane → road → junction chain.
    That lane has no same-direction lane to its right, so `hasLaneToTheRight` is
    false in every frame and the ego is as far right as its direction of travel
    allows throughout — only `inAnyJunction` convicts here. Drop that disjunct
    and this scenario stops reporting a violation. -/
def traceBlocksJunction : Trace :=
  List.replicate 80 (sceneOf emVanEntity junLaneId junLaneId)

/-- The minimal pair of `traceStaysLeft` for `baseClass w "van"`: the identical
    80 frames of conduct, with an emergency **car** — the police car — in the
    ego's lane instead of the ambulance. This rule must report compliant: its
    scope is the vehicle class R0012 cannot observe, and R0012's proximity
    antecedent already convicts this conduct. Drop the `baseClass` conjunct and
    the two rules convict the same event twice while this one adds no recall. -/
def tracePoliceCarIsR0012sCase : Trace :=
  List.replicate 80 (sceneOf policeEntity laneLeftId laneLeftId)

/-- The minimal pair of `traceStaysLeft` for `isEmergency w`: the identical 80
    frames, with an ordinary delivery van in the ego's lane. No emergency
    vehicle is present, so the clause has nothing to say about staying in the
    left-hand lane. Drop the `isEmergency` conjunct and this convicts. -/
def traceOrdinaryVan : Trace :=
  List.replicate 80 (sceneOf plainVanEntity laneLeftId laneLeftId)

def scenarios : List Scenario :=
  [ { name := "ego_moves_right_within_the_grace_window"
    , trace := traceMovesRightInTime
    , expected := true }
  , { name := "ego_stays_left_with_the_ambulance_behind"
    , trace := traceStaysLeft
    , expected := false }
  , { name := "ego_rightmost_but_blocking_the_junction"
    , trace := traceBlocksJunction
    , expected := false }
  , { name := "emergency_car_is_R0012s_case_not_this_rule"
    , trace := tracePoliceCarIsR0012sCase
    , expected := true }
  , { name := "ordinary_van_creates_no_duty"
    , trace := traceOrdinaryVan
    , expected := true } ]

end TrafficSpec.Rules.Emergency.R0020
