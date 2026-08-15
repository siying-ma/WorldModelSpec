/-
  Rule R0005 — the complete stop at a stop sign, and the one-second dwell.

  Law text (laws/example/laws.jsonl, id EX-STOP-001, "Complete stop"):
    "A driver approaching a stop sign shall bring the vehicle to a complete stop
     before entering the intersection, and shall remain stopped for not less
     than one second."

  One node, not two. "Bring the vehicle to a complete stop" and "remain stopped
  for not less than one second" read as two obligations, but the second entails
  the first: a trace satisfying `bounded (secondsToFrames 1) (stopped v)`
  satisfies `stopped v`. Splitting them would produce a child rule with no
  content of its own.

  Formalization notes
  -------------------
  * **The formula is anchored at position 0 and is deliberately NOT under `□`.**
    This is the central choice, and the reason is that the formula language has
    no past operator. Writing
      `□ (onGovernedApproach ⟹ (dwell ℛ ¬ enter))`
    re-imposes the obligation at *every* frame of the approach, including the
    frames after the dwell has already happened. In
    `full_stop_then_proceeds` the ego is still on the approach at frame 7, by
    which point no fresh twenty-frame stopped window can begin before it enters
    the junction — so the `□` form convicts a driver who did exactly what the
    statute asks. The obligation attaches once, to the whole approach, and the
    only way to say that without a past operator is to evaluate the release from
    the start of the trace. `satisfies` evaluates at position 0, so that is what
    this schema does.
  * **`ℛ` (release), not `𝒰` (until), and that is what makes the rule
    truncation-safe.** `dwell ℛ ¬ enter` reads: the ego does not enter the
    intersection until a frame at which a full one-second stopped interval
    begins, and if no such frame ever comes it must simply never enter. A strong
    `𝒰` would additionally *demand* the dwell occur somewhere in the trace, and
    would report a violation on `approach_truncated_before_junction`, where the
    capture merely stops recording while the driver is still slowing down.
    Nothing obliges a driver to have finished stopping by the last captured
    frame. (Equivalently: this is `¬ₛ ((¬ₛ dwell) 𝒰 enter)`; `loopRelease` is
    exactly the De Morgan dual of `loopUntil`, and its `fuel = 0` case is `true`
    where `loopUntil`'s is `false` — that is the truncation safety.)
  * **The obligation re-arms after the ego has passed through a junction.**
    Release discharges permanently once the dwell is seen, so on a trace
    containing two stop-controlled junctions a lawful stop at the first would
    excuse a rolling stop at the second. `□ (inAnyJunction v ⟹ guarded)` adds
    the obligation back at every frame at which the ego occupies a junction
    lane, which is the observable boundary between one approach and the next.
    Junction occupancy is used as the re-arm trigger rather than "the ego is not
    on the governed approach", because the latter also fires on a single dropped
    `controls` edge mid-approach and would then demand a second dwell. The
    residue that remains: two stop-controlled approaches with no intervening
    junction occupancy — which the road network does not produce.
  * **"Before entering the intersection" is "before occupying a junction lane".**
    There is no stop line: no coordinates survive for structure nodes, so a stop
    line, a give-way line and a junction boundary have no position to test
    against (`carla/schema.json` → `not_available.stop_line_and_junction_
    geometry`). A driver who overruns the painted line but stops short of the
    junction lane is compliant here and would not be under the statute. That is
    a weakening, recorded rather than hidden; closing it needs junction geometry
    in the adapter, not a different formula.
  * **"Entering" is the transition, not the occupancy.** `entersJunction` is
    "on the governed approach now, inside junction `j` at the next frame". The
    entry event is what the rule polices, so a vehicle that is already inside the
    junction when the trace opens is never accused.
  * **One second is `secondsToFrames 1` = 20 frames.** Frames carry no
    timestamp, so a statutory duration can only be a frame count, and the count
    is correct only at the 20 Hz reference capture rate
    (`capture_sensor_data.py`, `FPS = 20`). A capture taken at a different rate
    silently changes the threshold; this is an assumption about the data, not a
    reading of the law.
  * **The dwell window is not merely "stopped" — the ego must be stopped *on the
    governed approach, outside the junction*, for all twenty frames.** Without
    that conjunct a vehicle stopped for a second anywhere earlier in the trace
    (in a queue on the previous block, say) would discharge the obligation.
  * **"A complete stop" is `Pred.stopped`, i.e. speed ≤ 0.1 m/s**, not exactly
    zero. Nothing in the abstraction distinguishes a true zero from sensor
    residue at rest, and the vocabulary's threshold is the one place that
    decision should live.
  * **The stop sign is a bound entity (`stopSignBinder "d"`), not hidden behind
    `Pred.facingStopSign`.** Naming the device makes the grounding report say
    *which* sign the obligation was checked against, and makes a capture with no
    stop sign ground zero times — loudly vacuous — instead of passing silently.
    The association is `Pred.governs d v`, the `controls` edge, which is defined
    over any device carrying one and not only over traffic lights. The sign's
    `isIn` edges are bounding-box overlap and would be equally true of the sign
    facing the cross street; `no_stop_sign_governing_this_lane` is the
    regression test for that distinction.
  * **`Pred.isEgo v` is a data restriction, not a reading of the law**, which
    binds every driver. `speed` exists on the ego vehicle alone
    (`copy_carla_actor_state` is called for the ego node only), so `stopped w`
    for a non-ego `w` is always false and an ungated rule would convict every
    other vehicle at the junction of never having stopped.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Stop.R0005

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The statutory dwell, as a frame count: one second at the 20 Hz reference
    capture rate. -/
def dwellFrames : Nat := secondsToFrames 1

/-- The ego vehicle is on a lane the stop sign `d` governs, that lane leads into
    junction `j`, and it has not yet entered any junction. -/
def onGovernedApproach (v j d : EntityId) : SFProp :=
  isEgo v ⋀ governs d v ⋀ approachingJunction v j ⋀ ¬ₛ (inAnyJunction v)

/-- A full one-second stopped interval *begins here*: the ego is stationary on
    the governed approach, outside the junction, for `dwellFrames` consecutive
    frames. `bounded` has strong-next semantics, so a window that runs off the
    end of the trace is false. -/
def dwellBegins (v j d : EntityId) : SFProp :=
  .bounded dwellFrames (onGovernedApproach v j d ⋀ stopped v)

/-- The ego enters the intersection: on the governed approach now, occupying a
    lane of junction `j` at the next frame. -/
def entersJunction (v j d : EntityId) : SFProp :=
  onGovernedApproach v j d ⋀ ◯ (inJunction v j)

/-- The obligation: the intersection is not entered until — and unless — a full
    one-second dwell begins. -/
def guarded (v j d : EntityId) : SFProp :=
  (dwellBegins v j d) ℛ (¬ₛ (entersJunction v j d))

/-- The rule, quantified over (vehicle, junction, stop sign) triples and
    effective on the ego vehicle: it must not cross into the junction before a
    complete stop of at least one second has begun on the approach the sign
    governs, and the obligation is re-armed each time it passes through a
    junction. -/
def schema : PropertySchema where
  name    := "stop_sign_complete_stop_dwell"
  binders := [vehicleBinder "v", junctionBinder "j", stopSignBinder "d"]
  formula := fun env =>
    let v := arg env 0
    let j := arg env 1
    let d := arg env 2
    guarded v j d ⋀ □ (inAnyJunction v ⟹ guarded v j d)

def entry : RuleEntry where
  nodeId  := "Stop/R0005_stop_sign_dwell"
  lawRefs := ["EX-STOP-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- Road structure shared by every trace, in the shape of the bundled CARLA
-- sample: an approach road and an exit road that are plain roads, plus one road
-- that `isIn` Junction 5, so only the junction lane satisfies `inAnyJunction`.
-- `travelsTo` wires approach → junction → exit, and a cross-street lane also
-- `travelsTo` the junction lane, so there is a second stop-controlled approach
-- for the sign to be attached to.
--
-- The stop sign `controls` exactly one lane, passed per scene. In four of the
-- five scenarios that is the ego's approach lane; in
-- `no_stop_sign_governing_this_lane` it is the cross-street lane, which is what
-- the generator's `controlsTrafficOf` produces for the sign facing the other
-- arm of the intersection.
----------------------------------------------------------------------

private def ego          : Nat := 1
private def sign         : Nat := 2
private def approachLane : Nat := 10
private def junctionLane : Nat := 11
private def exitLane     : Nat := 12
private def crossLane    : Nat := 13
private def approachRoad : Nat := 20
private def junctionRoad : Nat := 21
private def exitRoad     : Nat := 22
private def crossRoad    : Nat := 23
private def junction     : Nat := 30

private def structureEntities : List Entity :=
  [ mkLane approachLane "Lane 7_-1"
  , mkLane junctionLane "Lane 8_-1"
  , mkLane exitLane     "Lane 9_-1"
  , mkLane crossLane    "Lane 6_-1"
  , mkRoad approachRoad "Road 7"
  , mkRoad junctionRoad "Road 8"
  , mkRoad exitRoad     "Road 9"
  , mkRoad crossRoad    "Road 6"
  , mkJunction junction "Junction 5" ]

private def structureRels : List Relation :=
  [ mkRel approachLane .isIn approachRoad
  , mkRel junctionLane .isIn junctionRoad
  , mkRel exitLane     .isIn exitRoad
  , mkRel crossLane    .isIn crossRoad
  , mkRel junctionRoad .isIn junction
  , mkRel approachLane .travelsTo junctionLane
  , mkRel crossLane    .travelsTo junctionLane
  , mkRel junctionLane .travelsTo exitLane ]

/-- One frame: the ego (id 1) occupying `lane` with the given control channels,
    and the stop sign (id 2) governing `signLane`. The sign is present in every
    frame, so the `d` binder grounds even when it governs the cross street. -/
private def sceneAt (lane signLane : Nat) (speed accel throttle brake : String) :
    Scene :=
  frame
    ([ mkEgo ego .car speed accel throttle brake
     , mkStopSign sign "stop_sign_0" ] ++ structureEntities)
    (structureRels ++ [mkRel sign .controls signLane, mkRel ego .isIn lane])

/-- A frame in which the sign governs the ego's approach lane. -/
private def governedAt (lane : Nat) (speed accel throttle brake : String) : Scene :=
  sceneAt lane approachLane speed accel throttle brake

/-- The same frame with the sign attached to the cross-street approach instead. -/
private def crossSignAt (lane : Nat) (speed accel throttle brake : String) : Scene :=
  sceneAt lane crossLane speed accel throttle brake

/-- Thirty frames. Four of deceleration on the governed approach, then
    twenty-two consecutive frames at 0.0 m/s — comfortably more than the twenty
    the statute demands — then four frames accelerating through the junction
    lane. The dwell window opens at frame 4 and closes at frame 23, before the
    entry at frame 25, so the release is discharged. Compliant. -/
def traceFullStopThenProceeds : Trace :=
  [ governedAt approachLane "8.0" "-6.0" "0.0" "0.6"
  , governedAt approachLane "5.0" "-6.0" "0.0" "0.8"
  , governedAt approachLane "2.0" "-6.0" "0.0" "0.9"
  , governedAt approachLane "0.5" "-6.0" "0.0" "1.0" ]
  ++ List.replicate 22 (governedAt approachLane "0.0" "0.0" "0.0" "1.0")
  ++ [ governedAt junctionLane "1.0" "3.0" "0.5" "0.0"
     , governedAt junctionLane "2.5" "3.0" "0.5" "0.0"
     , governedAt junctionLane "4.0" "3.0" "0.5" "0.0"
     , governedAt junctionLane "5.5" "3.0" "0.5" "0.0" ]

/-- Eight frames: the ego rolls through the junction without ever stopping,
    exactly as in `traceRollingStop`, but the stop sign `controls` the
    cross-street approach rather than the ego's lane. The sign is in the graph
    throughout, so the `d` binder still grounds; `governs d v` is false, so the
    obligation never attaches and the ego breaks nothing *this* sign says.

    The planner's sketch describes the driving as "rolls through at 5.0 m/s".
    It is written here as the *identical* speed profile to
    `traceRollingStop` — which passes through 5.0 m/s — so that the single
    difference between the compliant and the violating trace is which lane
    carries the `controls` edge. That is what isolates the governance conjunct:
    if `governs` were dropped from the antecedent, or replaced by
    `Pred.facingStopSign`, only this scenario would notice. -/
def traceNoStopSignGoverningThisLane : Trace :=
  [ crossSignAt approachLane "9.0" "-3.0" "0.0" "0.3"
  , crossSignAt approachLane "7.5" "-3.0" "0.0" "0.3"
  , crossSignAt approachLane "5.0" "-3.0" "0.0" "0.3"
  , crossSignAt approachLane "3.0" "-3.0" "0.0" "0.3"
  , crossSignAt approachLane "1.5" "-3.0" "0.0" "0.3"
  , crossSignAt junctionLane "1.5" "0.0"  "0.2" "0.0"
  , crossSignAt junctionLane "2.5" "2.0"  "0.4" "0.0"
  , crossSignAt junctionLane "4.0" "2.0"  "0.4" "0.0" ]

/-- Six frames on the governed approach, decelerating from 8.0 m/s to 2.0 m/s.
    The capture ends while the ego is still moving and still outside the
    junction: it has not yet stopped, and it has not yet entered, so it has not
    yet broken the law. This is the trap the encoding is built around — a strong
    `𝒰` would demand the dwell be witnessed inside the trace and would convict
    here. Compliant. -/
def traceApproachTruncated : Trace :=
  [ governedAt approachLane "8.0" "-6.0" "0.0" "0.5"
  , governedAt approachLane "6.8" "-6.0" "0.0" "0.5"
  , governedAt approachLane "5.6" "-6.0" "0.0" "0.5"
  , governedAt approachLane "4.4" "-6.0" "0.0" "0.5"
  , governedAt approachLane "3.2" "-6.0" "0.0" "0.5"
  , governedAt approachLane "2.0" "-6.0" "0.0" "0.5" ]

/-- Eight frames: the ego slows from 9.0 m/s to 1.5 m/s on the governed
    approach — never at or below the 0.1 m/s threshold, so never *stopped* at
    all — and then occupies the junction lane for three frames. The entry at
    frame 4 is reached with no dwell behind it. Violated. -/
def traceRollingStop : Trace :=
  [ governedAt approachLane "9.0" "-3.0" "0.0" "0.3"
  , governedAt approachLane "7.5" "-3.0" "0.0" "0.3"
  , governedAt approachLane "5.0" "-3.0" "0.0" "0.3"
  , governedAt approachLane "3.0" "-3.0" "0.0" "0.3"
  , governedAt approachLane "1.5" "-3.0" "0.0" "0.3"
  , governedAt junctionLane "1.5" "0.0"  "0.2" "0.0"
  , governedAt junctionLane "2.5" "2.0"  "0.4" "0.0"
  , governedAt junctionLane "4.0" "2.0"  "0.4" "0.0" ]

/-- Sixteen frames. The ego does come to a complete stop on the governed
    approach, but holds it for exactly ten frames — half a second at 20 Hz —
    before accelerating into the junction lane. It differs from
    `traceFullStopThenProceeds` in the length of the dwell alone, which is the
    only respect this clause cares about. No twenty-frame window is ever
    stationary, so the entry at frame 12 is unlawful. Violated. -/
def traceBriefStop : Trace :=
  [ governedAt approachLane "6.0" "-6.0" "0.0" "0.7"
  , governedAt approachLane "3.0" "-6.0" "0.0" "0.9"
  , governedAt approachLane "0.8" "-6.0" "0.0" "1.0" ]
  ++ List.replicate 10 (governedAt approachLane "0.0" "0.0" "0.0" "1.0")
  ++ [ governedAt junctionLane "1.5" "3.0" "0.5" "0.0"
     , governedAt junctionLane "3.0" "3.0" "0.5" "0.0"
     , governedAt junctionLane "4.5" "3.0" "0.5" "0.0" ]

def scenarios : List Scenario :=
  [ { name := "full_stop_then_proceeds",
      trace := traceFullStopThenProceeds,        expected := true }
  , { name := "no_stop_sign_governing_this_lane",
      trace := traceNoStopSignGoverningThisLane, expected := true }
  , { name := "approach_truncated_before_junction",
      trace := traceApproachTruncated,           expected := true }
  , { name := "rolling_stop_violates",
      trace := traceRollingStop,                 expected := false }
  , { name := "brief_stop_violates",
      trace := traceBriefStop,                   expected := false } ]

end TrafficSpec.Rules.Stop.R0005
