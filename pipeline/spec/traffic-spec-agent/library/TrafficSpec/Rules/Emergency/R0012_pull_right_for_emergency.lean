/-
  Rule R0012 — drive to the right-hand edge of the roadway for an approaching
  emergency vehicle.

  Law text (laws/example/laws.jsonl, id EX-EMERGENCY-001):
    "Upon the approach of an authorised emergency vehicle, the driver of every
     other vehicle shall yield the right of way and shall drive to the
     right-hand edge of the roadway, clear of any intersection."

  SCOPE — THE LATERAL OBLIGATION ONLY
  -----------------------------------
  The sentence states three things. This node formalizes exactly one of them:
  **"shall drive to the right-hand edge of the roadway"**.

    * "shall yield the right of way" is NOT a conjunct here. The abstraction
      carries no priority annotation of any kind
      (`carla/schema.json` → `unavailable.right_of_way`), so there is nothing to
      test; adding a conjunct that is unmeasurable would only weaken the
      antecedent. The rule therefore formalizes the observable half of the
      clause and is silent about priority.
    * "clear of any intersection" is the sibling node
      `Emergency/R0013_clear_junction_for_emergency` and is deliberately NOT
      folded in. It is a separate forbidden state (`inAnyJunction`) with a
      separate defence, and conjoining the two would make one verdict
      unattributable to one failure.

  THIS IS A REBUILD OF THE WITHDRAWN `Emergency/R0007_yield_to_emergency_vehicle`
  ------------------------------------------------------------------------------
  R0007 read "the right-hand edge of the roadway" off the OpenDRIVE **lane-id
  sign** (`Pred.inLaneRightOfReference`, 24 occurrences in its build transcript).
  That is the same defect that was *measured* on `Lane/R0009`, which passed all
  of its own scenarios and then convicted 50 frames of lawful driving in the
  bundled sceneflow capture, whose carriageway is numbered positively
  (`carla/schema.json` → `partially_available.which_half_of_the_roadway.do_not_use`;
  the warning on `Pred.laneRightOfReference` in `Core/Vocab.lean`). The lane-id
  sign records which side of the map's *reference line* a lane was authored on —
  every lane of one direction of travel shares it — not a legal side of the road.

  None of `inLaneRightOfReference` / `inLaneLeftOfReference` /
  `laneRightOfReference` / `laneLeftOfReference` appears below. R0007's id is
  retired and is not reused. The scenario traces below all use a carriageway
  numbered **positive** (`Lane 7_1`, `Lane 7_2`), so the lane-id-sign reading
  would convict `ego_already_at_the_right_hand_edge` — that scenario doubles as
  the regression test that keeps the sign out.

  Formalization notes — every choice the text did not dictate
  ----------------------------------------------------------
  * **"the right-hand edge of the roadway" is read as "no same-direction lane
    lies to my right"** (`Pred.hasLaneToTheRight` is the forbidden state).
    The generator computes each lane-to-lane `toLeftOf` / `toRightOf` edge in
    the *target* lane's own forward frame (`sgg_abstractor.py`), so the edge
    pattern between two lanes reveals their relative direction of travel:
    asymmetric means same direction, mutual `toLeftOf` means opposite. The test
    is therefore relative to the vehicle's own direction of travel and involves
    no map convention.
  * **The offence is stated POSITIVELY, as `hasLaneToTheRight v`, and NOT as
    `¬ₛ inRightmostLane v`.** The two differ on exactly one case: a vehicle
    occupying no lane at all. `inRightmostLane` is false for such a vehicle, so
    the negated form would report a VIOLATION against a driver who has pulled
    fully onto the verge — which is the *most* compliant response the statute
    contemplates. `ego_pulled_off_the_roadway` is the scenario that pins this
    down and is the discriminating test between the two readings.
  * **"Upon the approach of" is read as presence within 25 m**
    (`Pred.withinMetres 25`), not as a sequence of tightening proximity bands.
    Proximity is quantised into six bands and nothing in the graph distinguishes
    an emergency vehicle closing on the ego from one holding station beside it,
    so a "closing" test would be a guess dressed as a measurement. 25 m is the
    outermost band boundary the generator emits, i.e. the widest reading of
    "approach" the data supports; it is named once, in `approachMetres`.
  * **The forbidden state must be SUSTAINED for `graceFrames` = `secondsToFrames
    1` = 20 frames = 1 s at the reference 20 Hz capture rate**, rather than
    being prohibited per frame. A driver cannot teleport into the kerbside lane
    the instant a siren registers; a per-frame prohibition would convict every
    lawful, prompt lane change. Frames carry no clock
    (`carla/schema.json` → `unavailable.timestamps`), so the allowance is a
    frame count. Both the 1 s figure and the choice of a duration proxy for a
    reaction allowance are open to challenge: `graceFrames` is the whole change
    a reviewer who disagrees has to make.
    `brief_delay_then_moves_right` and `stays_in_the_left_lane_as_it_approaches`
    differ in exactly this one respect.
  * **`w` is bound with `proximityVehicleBinder`, not `vehicleBinder`.**
    Proximity edges exist only for the base classes `person`, `bicycle`, `car`,
    `motorcycle`, `bus`, `truck` (`carla/schema.json` → `relation_coverage`), so
    a `vehicleBinder` would manufacture groundings whose antecedent can never
    fire and inflate the grounding count without testing anything.
  * **The obligation is gated on `Pred.isEgo v`**, as every rule in this library
    is: it is a monitor on the conduct of the driver being observed, and takes
    no position on third parties. Every scenario below carries a second vehicle
    that also grounds `v`, so that gate is exercised rather than assumed.

  Residues — what this rule does not measure
  ------------------------------------------
  1. **`special_class = "emergency"` is a CARLA blueprint attribute, not a siren
     and not a light bar.** The graph records what the vehicle *is*, never
     whether it is *responding*. An off-duty police car parked at the kerb fires
     the antecedent exactly as a responding one does, so the rule over-reports
     against the statute's "upon the approach of an authorised emergency
     vehicle". There is no channel that would fix this: the emergency light bar
     is not among the lifted per-vehicle light booleans.
  2. **This rule can only ever ground on the police car and the firetruck.**
     CARLA's ambulance is `vehicle.ford.ambulance`, whose base type is `van`,
     and **no** proximity or angular edge is emitted for a van
     (`carla/schema.json` → `relation_coverage`; `Core/Builders.lean`, the note
     on `mkEmergency`). An approaching ambulance is therefore invisible to this
     rule — a silent under-report, and the single largest gap in its coverage.
  3. **"Shall yield the right of way" is not formalized at all** — see SCOPE.
     A driver who moves right but cuts the emergency vehicle up is reported
     compliant here.
  4. **"The right-hand edge" is lane adjacency, never a distance to a kerb.**
     The junction-RSV abstraction collapses the waypoint runs and keeps no
     carriageway width, no lane-marking type and no kerb
     (`carla/schema.json` → `unavailable.lane_width_and_markings`), so a driver
     who reaches the kerbside lane but not the kerb itself is compliant, and a
     hard shoulder is invisible. Correspondingly, `hasLaneToTheRight` is
     stricter than "the right-hand half" on a carriageway of three or more
     lanes: the middle lane is convicted.
  5. **A violation shorter than 1 s is not reported**, and by strong-next
     semantics (`Core/Semantics.lean`, `loopBounded`) neither is one that begins
     within the last 19 frames of a trace. Under-reporting, chosen so the
     reaction allowance is honoured.
  6. **Check the grounding count and the verdict on a real capture before
     believing this rule.** The scenarios below were written by the same reading
     that wrote the formula, which is precisely how R0007 and R0009 passed their
     gates; only `run_spec monitor` against a human-labelled capture is
     independent of it.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Emergency.R0012

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- How close an emergency vehicle must be before "upon the approach of" is
    taken to hold. 25 m is the outermost proximity band boundary the generator
    emits (`visible`, 16–25 m), so this is the widest reading the data supports.
    A formalization choice — see the header. -/
def approachMetres : Nat := 25

/-- The driver's reaction allowance: 1 s = 20 frames at the reference 20 Hz
    capture rate. The forbidden state is an offence only once it has persisted
    this long. A formalization choice, not something the text states; this `def`
    is the whole change a reviewer who wants a different allowance has to make. -/
def graceFrames : Nat := TrafficSpec.secondsToFrames 1

/-- The forbidden state: the monitored driver is within `approachMetres` of an
    emergency vehicle and is *still* occupying a lane that has another
    **same-direction** lane to its right, i.e. has not moved to the right-hand
    edge of the roadway.

    `hasLaneToTheRight` is false for a vehicle occupying no lane at all, so a
    driver who has pulled fully onto the verge is not in the forbidden state —
    see the header, and `ego_pulled_off_the_roadway`. -/
def notYieldingLateralSpace (v w : EntityId) : SFProp :=
  isEgo v ⋀ isEmergency w ⋀ withinMetres approachMetres v w ⋀ hasLaneToTheRight v

/-- At no position does the ego hold a lane with a same-direction lane to its
    right, while an emergency vehicle is within 25 m, for `graceFrames`
    consecutive frames. -/
def schema : PropertySchema where
  name    := "pull_right_for_emergency_vehicle"
  binders := [vehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    □ (¬ₛ (.bounded graceFrames (notYieldingLateralSpace v w)))

def entry : RuleEntry where
  nodeId  := "Emergency/R0012_pull_right_for_emergency"
  lawRefs := ["EX-EMERGENCY-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- One road structure throughout: a carriageway of two same-direction lanes,
-- both numbered **positive**, which is the bundled sceneflow capture's
-- geometry and what the withdrawn R0007/R0009 reading died on. On the left of
-- an OpenDRIVE reference line the ids grow away from the centre, so `Lane 7_2`
-- is the kerbside lane and `Lane 7_1` the inner one.
--
-- The lane-to-lane edges carry the pattern the generator actually emits for
-- two lanes of the same direction — asymmetric, `kerbside toRightOf inner` and
-- `inner toLeftOf kerbside` — because that pattern is the entire evidence this
-- rule reads about which way is "right".
--
-- Both lanes, the road and the singleton `Off Road` node are present in every
-- frame of every trace, so a structure a scenario does not use is never the
-- reason a verdict changes. Every trace carries exactly two vehicles: the ego
-- and one other car, which grounds `v` a second time (and must always come out
-- compliant, since it is not the ego) and grounds `w` once.
--
-- Trace lengths are all 100 frames, comfortably longer than the 20-frame
-- window: the window is stated in seconds and the traces are `List.replicate`,
-- so the traces were built to fit the window rather than the window shrunk to
-- fit the traces.
----------------------------------------------------------------------

private def laneKerb  : Nat := 10   -- `Lane 7_2`, the kerbside lane
private def laneInner : Nat := 11   -- `Lane 7_1`, the inner (left) lane
private def road7     : Nat := 12
private def offRd     : Nat := 13

private def roadEntities : List Entity :=
  [ mkLane laneKerb  "Lane 7_2"
  , mkLane laneInner "Lane 7_1"
  , mkRoad road7     "Road 7"
  , mkOffRoad offRd ]

/-- The asymmetric pattern the generator emits for two same-direction lanes.
    The `laneChange` edges make the move in `traceBriefDelayThenMovesRight` a
    lawful manoeuvre; nothing in the formula reads them. -/
private def roadRels : List Relation :=
  [ mkRel laneKerb  .isIn road7
  , mkRel laneInner .isIn road7
  , mkRel laneKerb  .toRightOf laneInner
  , mkRel laneInner .toLeftOf  laneKerb
  , mkRel laneKerb  .laneChange laneInner
  , mkRel laneInner .laneChange laneKerb ]

/-- The ego (id 1), cruising at 12 m/s under light throttle. -/
private def egoCar : Entity := mkEgo 1 .car "12.0" "0.0" "0.4" "0.0"

/-- An emergency police car (id 2): base class `car`, `special_class`
    `"emergency"`. `car` and not `van`, because a van carries no proximity edge
    and the antecedent could never fire — residue 2 in the header. -/
private def policeCar : Entity := mkEmergency 2 "car_0" .car

/-- The same car without `special_class`, for the scenario that isolates the
    `isEmergency` conjunct. -/
private def ordinaryCar : Entity := mkActor 2 "car_0" .car

/-- The other car is within the `near` band (10–16 m, so inside 25 m) at the
    ego's rear. Distance is stored as one directed edge per ordered pair, and
    `withinMetres` checks both orientations. -/
private def proximityRels : List Relation :=
  [ mkRel 2 .near 1
  , mkRel 2 .atDRearOf 1
  , mkRel 1 .inDFrontOf 2 ]

/-- One frame: the ego `isIn` `egoNode`, the other car `isIn` `otherNode`, with
    the proximity and angular edges present only when `closeBehind`. -/
private def sceneOf (other : Entity) (egoNode otherNode : Nat)
    (closeBehind : Bool) : Scene :=
  frame
    ([egoCar, other] ++ roadEntities)
    (roadRels
      ++ [ mkRel 1 .isIn egoNode, mkRel 2 .isIn otherNode ]
      ++ (if closeBehind then proximityRels else []))

/-- The emergency police car is within the `near` band behind the ego for all
    100 frames, and the ego holds the kerbside lane `Lane 7_2` throughout. No
    lane is `toRightOf` `Lane 7_2`, so the ego is already at the right-hand edge
    of the roadway and the driving is lawful.

    Doubles as the REGRESSION TEST for the withdrawn R0007 — do not remove or
    weaken it. Both lanes are numbered **positive**, so the lane-id-sign reading
    (`inLaneRightOfReference`, which R0007 used) is false on every frame and
    convicts this entirely compliant trace. The correct reading reports
    COMPLIANT. -/
def traceEgoAlreadyAtTheRightHandEdge : Trace :=
  List.replicate 100 (sceneOf policeCar laneKerb laneKerb true)

/-- The discriminating scenario. The emergency police car is within the `near`
    band for all 100 frames while the ego is `isIn` the `Off Road` node and
    occupies NO lane: it has pulled fully onto the verge, which is maximal
    compliance with the statute.

    `hasLaneToTheRight` is false for a vehicle in no lane, so this rule reports
    COMPLIANT. A rule whose consequent were `Pred.inRightmostLane v` reports a
    VIOLATION here, because that predicate is also false for a vehicle in no
    lane — which is why the offence is stated positively. -/
def traceEgoPulledOffTheRoadway : Trace :=
  List.replicate 100 (sceneOf policeCar offRd laneKerb true)

/-- The same geometry and the same 100-frame duration as
    `traceStaysInTheLeftLaneAsItApproaches` — the ego holds the inner lane
    `Lane 7_1` throughout, with a car within the `near` band behind it — but the
    car carries no `special_class = "emergency"`.

    The antecedent never fires, so the rule is satisfied. This isolates the
    `isEmergency` conjunct: it is the ONLY respect in which this trace differs
    from the negative one. -/
def traceOrdinaryCarNotAnEmergencyVehicle : Trace :=
  List.replicate 100 (sceneOf ordinaryCar laneInner laneInner true)

/-- The reaction allowance. 100 frames: for the first 10 the ego is in the inner
    lane with no vehicle within 25 m; at frame 10 the emergency police car
    appears within the `near` band while the ego is still in the inner lane, and
    the ego stays there for 15 frames — FEWER than the 20-frame window — before
    moving to the kerbside lane for the remaining 75 and staying there.

    The longest run of the forbidden state is 15 frames, so `.bounded 20` never
    closes and the driver's prompt move right is lawful. Differs from
    `traceStaysInTheLeftLaneAsItApproaches` only in how long the inner-lane
    occupancy lasts once the emergency vehicle is in range. -/
def traceBriefDelayThenMovesRight : Trace :=
  List.replicate 10 (sceneOf policeCar laneInner laneInner false)
    ++ List.replicate 15 (sceneOf policeCar laneInner laneInner true)
    ++ List.replicate 75 (sceneOf policeCar laneKerb  laneInner true)

/-- The offence. The emergency police car is within the `near` band for all 100
    frames while the ego holds the INNER lane `Lane 7_1` — which has a
    same-direction lane (`Lane 7_2`, `toRightOf` it) to its right — throughout,
    comfortably longer than the 20-frame allowance. The driver never yields
    lateral space.

    Differs from `traceEgoAlreadyAtTheRightHandEdge` in exactly one respect:
    which of the two lanes the ego occupies. `car_0` is not the ego, so its own
    grounding of `v` is compliant and the failing grounding is the ego's
    alone. -/
def traceStaysInTheLeftLaneAsItApproaches : Trace :=
  List.replicate 100 (sceneOf policeCar laneInner laneInner true)

def scenarios : List Scenario :=
  [ { name := "ego_already_at_the_right_hand_edge",     trace := traceEgoAlreadyAtTheRightHandEdge,     expected := true }
  , { name := "ego_pulled_off_the_roadway",             trace := traceEgoPulledOffTheRoadway,           expected := true }
  , { name := "ordinary_car_not_an_emergency_vehicle",  trace := traceOrdinaryCarNotAnEmergencyVehicle, expected := true }
  , { name := "brief_delay_then_moves_right",           trace := traceBriefDelayThenMovesRight,         expected := true }
  , { name := "stays_in_the_left_lane_as_it_approaches", trace := traceStaysInTheLeftLaneAsItApproaches, expected := false } ]

end TrafficSpec.Rules.Emergency.R0012
