/-
  Rule R0018 — the complete stop before entering on a held red.

  Law text (EX-SIGNAL-001, "Steady red signal"):
    "A driver facing a steady red signal shall stop before the marked stop line
     and shall not enter the intersection until the signal turns green, unless
     already within the intersection when the signal changed."

  Scope — WHICH LIMB THIS FILE COVERS, AND HOW IT OVERLAPS Signal/R0010
  --------------------------------------------------------------------
  This file formalizes the FIRST limb only: "shall stop before the marked stop
  line". `Signal/R0010_red_light_in_junction` formalizes the second limb ("shall
  not enter the intersection until the signal turns green") together with the
  statutory exception, and its header explicitly declines this one. Both files
  cite EX-SIGNAL-001 and that is deliberate.

  The overlap is real and is not double counting. A driver who enters while the
  light is still red is convicted by both rules; `scripts/capture_eval.py`
  aggregates a law as violated if ANY rule covering it is violated, so the two
  verdicts collapse into one. What this rule ADDS, and what nothing in the
  library convicts today, is the driver who **never stopped at all** and entered
  after the release to green: R0010 acquits that driver by construction, because
  its forbidden object is an outside-to-inside transition taken on red.

  Why `at_traffic_light` is the anchor, and why the earlier "unreachable" verdict was wrong
  ----------------------------------------------------------------------------------------
  Iterations 1–3 recorded this limb as blocked on `carla/schema.json` →
  `unavailable.stop_line_and_junction_geometry`. That fact is true — no
  coordinates survive for structure nodes, so a painted stop line has no
  position — but it is not the whole story. The capture carries one
  position-derived anchor that no other rule in this library reads: the ego
  attribute `at_traffic_light`, which `carla/schema.json` sources to
  `ego.is_at_traffic_light()` and describes as "inside a governing signal's
  trigger volume". That trigger volume is CARLA's own stopping zone for the
  signal, and it is the closest thing the abstraction has to "before the marked
  stop line". `Pred.atTrafficLight` reads it today; no vocabulary or adapter
  extension is needed for this rule.

  Why the lane chain, and NOT `Pred.facingRedSignal` / `Pred.governs`
  ------------------------------------------------------------------
  `Pred.facingRedSignal v` and `Pred.governs d v` both reduce to the same
  `controls`-edge lookup, and that edge points at the lane the vehicle occupies
  **right now**. For a traffic light it exists only once the vehicle is already
  inside the junction (`Core/Vocab.lean` § 8; `carla/schema.json` →
  `relation_labels.notes.controls_is_the_only_governance_edge`). Conjoining
  either of them with `¬ₛ inAnyJunction v` is therefore an empty conjunction on
  real data — the mistake that made the deleted `Signal/R0004` unsatisfiable and
  that R0010's header records. Neither predicate appears anywhere in this file.

  What appears instead is an explicit two-hop chain that puts the `controls`
  edge one lane DOWNSTREAM of the ego, which is where it is known to exist:

      inLane v lApproach ⋀ laneTravelsTo lApproach lControlled
                         ⋀ controlsLane d lControlled ⋀ signalRed d

  read as: the ego occupies `lApproach`, `lApproach` leads into `lControlled`,
  and a red light `d` controls `lControlled`. Every conjunct is evaluated while
  the ego is still on the approach, so the antecedent stays satisfiable there.

  Why the colour conjunct is essential, and the one ambiguity it rests on
  ----------------------------------------------------------------------
  `at_traffic_light` carries no colour. A rule built on it alone would convict a
  driver who does not stop at a GREEN light, which is not the statute, so
  `signalRed d` is load-bearing rather than decorative.

  The ambiguity, recorded because it changes what a zero grounding count means:
  `carla/schema.json` describes `is_at_traffic_light()` as saying **nothing about
  the light's colour**, while CARLA's own API documentation is sometimes read as
  "affected only while the light is red". This formula is sound under either
  reading — under the second the `signalRed d` conjunct is redundant rather than
  wrong. But under the second reading a capture in which the ego passes only
  green lights produces `at_traffic_light = false` throughout, and the resulting
  empty antecedent must not be mistaken for lawful driving.

  Formalization choices the text did not dictate
  ---------------------------------------------
  * **`redHoldFrames := TrafficSpec.secondsToFrames 1` = 20 frames.** The statute
    names no duration. This window is OURS, and it exists for exactly one
    purpose: to acquit the driver whose signal releases to green as they arrive
    in the trigger volume. Without it the rule convicts ordinary
    traffic-manager driving on every capture that contains a signal — the
    discriminating case is `red_releases_before_the_hold_completes`. A reviewer
    who disagrees with one second should be able to change this one number and
    nothing else.

  * **"A complete stop" is ONE frame of `Pred.stopped` (≤ 0.1 m/s), not a dwell.**
    This limb of EX-SIGNAL-001 demands a complete stop and says nothing about
    remaining stopped; the one-second standstill belongs to EX-STOP-001 and is
    formalized in `Stop/R0007`. Using a dwell here would import a duty the
    signal clause does not impose.

  * **The stop must lie outside the junction.** `stopHere := stopped v ⋀
    ¬ₛ inAnyJunction v`. A vehicle that first comes to rest with its lane
    assignment already flipped into the junction has not stopped *before*
    entering, so that frame must not discharge the duty.

  * **The obligation attaches to the ONSET of the governed hold, not to every
    frame of it.** This follows `Stop/R0007`, whose header measures why the
    every-frame shape is unsound: `.bounded n φ` holds only where a *fresh*
    n-frame window starts, so re-asking the obligation under `□` interrogates
    positions in the middle of and after the driver's own stop, from which no new
    stop is still to come, and convicts compliant drivers. The shape used here:

      (atLightRed ⟹ obligation) ⋀ □ ((¬ₛ atLightRed ⋀ ◯ atLightRed) ⟹ ◯ obligation)

    The first conjunct covers a capture that already begins inside a held red;
    the box covers every later frame at which the held red *begins*, which is the
    past-free way to name a first frame.

  * **The obligation is a negated STRONG until.**
    `obligation := ¬ₛ ((¬ₛ stopHere) 𝒰 inAnyJunction v)`, read as: it must not
    happen that the ego reaches a junction without having stopped on the way.
    `Core/Semantics.lean::loopUntil` is a strong until, false when its right arm
    never comes true, so a driver who is still on the approach when the trace
    ends is reported compliant rather than convicted for an entry that never
    happened. Scenario `never_reaches_the_junction` fails if that polarity is
    inverted, or if the obligation is weakened to "must stop".

  * **"Steady red" is `light_state = "Red"`.** `"Yellow"`, `"Off"` and
    `"Unknown"` are outside this rule; `str(carla.TrafficLightState)` has no
    separate flashing-red state.

  * **`isEgo v` is a data restriction, not a reading of the law.** The statute
    binds every driver. Both channels this rule needs — `at_traffic_light` and
    `speed` — exist on the ego node alone (`copy_carla_actor_state` /
    `copy_carla_control` are called for the ego only; `carla/schema.json` →
    `unavailable.non_ego_dynamics`), so on any other binder the antecedent is
    false at every frame. Ungated, the rule would be silently vacuous for other
    vehicles rather than lenient. It speaks about the ego's driver only, and
    makes no claim either way about anyone else.

  Residues
  --------
  (1) **The trigger volume is simulator geometry, not a painted line.** How far
      back from the intersection the duty attaches is a CARLA constant that no
      capture records, so "before the marked stop line" is really "somewhere
      inside whatever box CARLA associates with this signal". A driver who stops
      well past the painted line but still inside the volume is credited here and
      would not be by the statute.

  (2) **Nothing ties the light in the ego's volume to the light this formula
      binds.** `carla/schema.json` → `unavailable.traffic_light_grouping`:
      `carla_parent_id` is MEASURED absent from every traffic-light node in 480
      frames, and no adapter change can lift it. So the formula requires only
      that SOME red light `d` controls the lane the ego's lane leads into. At a
      multi-signal junction the ego can be paired with a sibling head whose
      colour differs from the one actually facing it, in either direction.

  (3) **`redHoldFrames = 20` is one second only at 20 Hz.** `carla/schema.json` →
      `capture_preconditions.capture_rate`: frames carry no timestamp by
      construction, so the rate is unverifiable from the data. At 40 Hz this rule
      demands only a half-second hold before the duty attaches.

  (4) **The stop threshold is ≤ 0.1 m/s, not zero** — that is `Pred.stopped`
      (`speedLe e 100` in milli-units). A vehicle creeping at 0.09 m/s discharges
      the duty. And because one frame suffices (see above), a single 0.05 s
      sample below the threshold is a complete stop as far as this rule is
      concerned.

  (5) **Entry is quantised to lane-node granularity.** `Pred.inAnyJunction` walks
      the entity → lane → road → junction chain, so "entering" is observed at the
      frame the lane assignment flips (`SGG(segment_length=1.0)`), and which
      junction lanes the light is recorded as governing depends on the
      generator's own untested tolerance, `get_distance(...) < segment_length * 0.5`
      (`carla/schema.json` → `capture_preconditions.segment_length`).

  (6) **UNVALIDATED against real data — read this before trusting a green
      verdict.** The scenarios below are hand-built and contain exactly the
      structure this file bets on: the light's `controls` edge on the junction's
      inner lane, a `travelsTo` edge from the approach lane to it, and
      `at_traffic_light` true on the approach. They are not evidence that a real
      capture has that structure. The first `run_spec monitor` on a capture
      containing a signalled junction must read this rule's GROUND count and
      check that the antecedent actually engages. **Zero groundings, or
      groundings with an antecedent that never fires, means this rule is
      untested — NOT that the driving was lawful.**

  Span and trace length
  ---------------------
  `SFProp.frameSpan` of this formula is 21: the `.bounded 20` hold contributes 20
  and the `◯` in front of the onset obligation adds one. Every scenario trace is
  60 frames, and every violating stretch begins at position 0, well clear of the
  trailing blind zone (`Core/Formula.lean`: a violation confined to the last 20
  frames cannot be reported, because the hold window would overrun the trace and
  `loopBounded` reads that as false).
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Signal.R0018

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- How long the light must have been red, with the ego already inside its
    trigger volume, before the duty to stop attaches: 20 frames, one second at
    the 20 Hz reference capture rate. Ours, not the statute's — see the header's
    formalization choices and residue (3). This is the one number a reviewer
    should be able to change on its own. -/
def redHoldFrames : Nat := TrafficSpec.secondsToFrames 1

/-- Quantified over vehicles, traffic lights, and the two lanes of the approach →
    junction hop; gated on the ego, the only node carrying `at_traffic_light` and
    `speed`. -/
def schema : PropertySchema where
  name    := "stop_at_red_before_entering"
  binders := [ vehicleBinder "v", trafficLightBinder "d"
             , laneBinder "lApproach", laneBinder "lControlled" ]
  formula := fun env =>
    let v          := arg env 0
    let d          := arg env 1
    let lApproach  := arg env 2
    let lControlled := arg env 3
    -- The ego, inside a signal's trigger volume and not yet in any junction, on
    -- an approach lane that leads into a lane a RED light controls. The
    -- `controls` edge is one hop downstream of the ego, where it exists.
    let inZoneOnRed :=
      isEgo v ⋀ atTrafficLight v ⋀ ¬ₛ (inAnyJunction v)
        ⋀ inLane v lApproach ⋀ laneTravelsTo lApproach lControlled
        ⋀ controlsLane d lControlled ⋀ signalRed d
    -- That state held for a full second starting here: the red is a held red,
    -- not one releasing as the driver arrives.
    let atLightRed := SFProp.bounded redHoldFrames inZoneOnRed
    -- A complete stop that counts: at rest, and still short of the junction.
    let stopHere := stopped v ⋀ ¬ₛ (inAnyJunction v)
    -- Forbidden from here on: reaching a junction with no such stop ever having
    -- happened on the way. Strong until, under the negation, so a trace that
    -- ends on the approach is compliant rather than convicted.
    let obligation := ¬ₛ ((¬ₛ stopHere) 𝒰 (inAnyJunction v))
    -- Discharged once per held red: at position 0 if the capture already begins
    -- inside one, and at every later frame at which one begins.
    (atLightRed ⟹ obligation)
      ⋀ □ ((¬ₛ atLightRed ⋀ ◯ atLightRed) ⟹ ◯ obligation)

def entry : RuleEntry where
  nodeId  := "Signal/R0018_stop_at_red_before_entering"
  lawRefs := ["EX-SIGNAL-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

private def egoId        : Nat := 1
private def approachLane : Nat := 10
private def junctionLane : Nat := 11
private def approachRoad : Nat := 20
private def junctionRoad : Nat := 21
private def junctionId   : Nat := 30
private def lightId      : Nat := 40

/-- Road structure shared by every trace: `Lane 100_-1` inside `Road 100` inside
    `Junction 5`, the approach lane `Lane 7_-1` on an ordinary road that
    `travelsTo` it, and the traffic light.

    Only the junction road carries an `isIn` edge to the junction node, so
    `Pred.inAnyJunction` is true exactly for a vehicle in `junctionLane`.

    The light's `.controls` edge goes to the junction's inner lane **only, never
    to the approach lane** — the structure a real capture has (see the header).
    Giving these traces an approach-side governance edge they will not have in
    the field is precisely what would make them agree with a formalization that
    cannot ground, which is why this rule reads the edge one hop downstream
    instead. -/
private def structureEntities (state : String) : List Entity :=
  [ mkLane approachLane "Lane 7_-1",   mkRoad approachRoad "Road 7"
  , mkLane junctionLane "Lane 100_-1", mkRoad junctionRoad "Road 100"
  , mkJunction junctionId "Junction 5"
  , mkTrafficLight lightId "Light 1" state ]

private def structureRels : List Relation :=
  [ mkRel approachLane .isIn approachRoad
  , mkRel junctionLane .isIn junctionRoad
  , mkRel junctionRoad .isIn junctionId
  , mkRel approachLane .travelsTo junctionLane
  , mkRel lightId      .controls  junctionLane ]

/-- One frame with the ego on the approach lane at `speed` m/s, inside the
    signal's trigger volume (`at_traffic_light = "true"`), with the light showing
    `state`: not yet in the junction, and — as on a real capture — *not* governed
    by any `controls` edge of its own. -/
private def zoneFrame (state : String) (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed (atTrafficLight := "true") :: structureEntities state)
    (structureRels ++ [mkRel egoId .isIn approachLane])

/-- One frame with the ego in the junction's inner lane at `speed` m/s and the
    light showing `state` — the lane → road → junction chain
    `Pred.inAnyJunction` walks.

    `at_traffic_light` is left true here, as the scenario descriptions specify.
    It makes no difference to any verdict: every conjunct that reads it is
    guarded by `¬ₛ inAnyJunction v`, which is false at these frames. A real
    capture would more likely report false once the ego is past the signal, and
    this rule is insensitive to which of the two it is. -/
private def insideFrame (state : String) (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed (atTrafficLight := "true") :: structureEntities state)
    (structureRels ++ [mkRel egoId .isIn junctionLane])

/-- 60 frames. Positions 0–5: decelerating in the trigger volume on red,
    6.000 → 1.000 m/s. Positions 6–29: standstill at 0.000 m/s, still red.
    Position 30: the light goes green; the ego accelerates, still on the
    approach. Positions 40–59: inside the junction on green.

    Lawful: the driver stopped inside the stopping zone before entering. The
    held red begins at position 0, so the obligation is discharged there, and the
    standstill at positions 6–29 breaks the inner until well before the junction
    entry at 40. -/
def traceStopsAtRedThenEntersOnGreen : Trace :=
  [ zoneFrame "Red" "6.000", zoneFrame "Red" "5.000", zoneFrame "Red" "4.000"
  , zoneFrame "Red" "3.000", zoneFrame "Red" "2.000", zoneFrame "Red" "1.000" ]
  ++ List.replicate 24 (zoneFrame "Red" "0.000")
  ++ [ zoneFrame "Green" "1.000", zoneFrame "Green" "2.000"
     , zoneFrame "Green" "3.000", zoneFrame "Green" "4.000"
     , zoneFrame "Green" "5.000", zoneFrame "Green" "5.000"
     , zoneFrame "Green" "5.000", zoneFrame "Green" "5.000"
     , zoneFrame "Green" "5.000", zoneFrame "Green" "5.000" ]
  ++ List.replicate 20 (insideFrame "Green" "6.000")

/-- 60 frames. Positions 0–25: in the trigger volume at 5.000 m/s with the light
    red — a held red far longer than `redHoldFrames`. Positions 26–45: inside the
    junction, still red. Positions 46–59: inside, green.

    Forbidden: the ego reached the junction without ever stopping while a held
    red governed the lane it was heading into. The offence is discharged at
    position 0 and the entry is at position 26, both well clear of the trailing
    blind zone. -/
def traceRunsTheRedWithoutStopping : Trace :=
  List.replicate 26 (zoneFrame "Red" "5.000")
  ++ List.replicate 20 (insideFrame "Red" "5.000")
  ++ List.replicate 14 (insideFrame "Green" "6.000")

/-- 60 frames. Positions 0–7: in the trigger volume at 6.000 m/s on red — eight
    frames, twelve short of `redHoldFrames`. Position 8: green. Positions 20–59:
    inside the junction. The ego never drops below 6.000 m/s anywhere.

    **The discriminating scenario for `redHoldFrames`.** The red never persisted
    for a second while the ego was in the zone, so the duty to stop never
    attached and this must be reported compliant. Drop the bounded hold — make
    the antecedent a bare state formula — and this convicts a driver whose light
    released to green as they arrived, which is ordinary traffic-manager driving
    on every capture. -/
def traceRedReleasesBeforeTheHoldCompletes : Trace :=
  List.replicate 8 (zoneFrame "Red" "6.000")
  ++ List.replicate 12 (zoneFrame "Green" "6.500")
  ++ List.replicate 40 (insideFrame "Green" "7.000")

/-- 60 frames, all of them in the trigger volume on a red that never releases,
    with the ego rolling forward at 2.000 m/s and never stopping. The trace ends
    with the ego still on the approach: it never enters `Lane 100_-1`.

    **The discriminating scenario for the strong-until polarity.** The duty
    attaches — the red is held from position 0 — but nobody entered, so nothing is
    breached within the capture and this must be compliant. A weak until here, or
    an obligation phrased positively as "must stop", convicts this driver. -/
def traceNeverReachesTheJunction : Trace :=
  List.replicate 60 (zoneFrame "Red" "2.000")

def scenarios : List Scenario :=
  [ { name := "stops_at_red_then_enters_on_green"
    , trace := traceStopsAtRedThenEntersOnGreen
    , expected := true }
  , { name := "runs_the_red_without_stopping"
    , trace := traceRunsTheRedWithoutStopping
    , expected := false }
  , { name := "red_releases_before_the_hold_completes"
    , trace := traceRedReleasesBeforeTheHoldCompletes
    , expected := true }
  , { name := "never_reaches_the_junction"
    , trace := traceNeverReachesTheJunction
    , expected := true } ]

end TrafficSpec.Rules.Signal.R0018
