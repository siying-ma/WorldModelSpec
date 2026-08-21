/-
  Rule R0026 — entering the lane a red signal controls without having stopped.

  Law text (EX-SIGNAL-001, "Steady red signal"):
    "A driver facing a steady red signal shall stop before the marked stop line
     and shall not enter the intersection until the signal turns green, unless
     already within the intersection when the signal changed."

  Scope — WHICH LIMB THIS FILE COVERS, AND THE DIVISION OF LABOUR
  --------------------------------------------------------------
  This file formalizes the FIRST limb only: "shall stop before the marked stop
  line". `Signal/R0010_red_light_in_junction` formalizes the second limb ("shall
  not enter the intersection until the signal turns green") and the statutory
  exception. So a driver who *does* stop and then creeps into the junction while
  the light is still red is **acquitted here and convicted by R0010**; a driver
  who never stops at all and rolls straight through is convicted here. All three
  files (R0010, R0018, this one) cite EX-SIGNAL-001, and `capture_eval.py`
  aggregates a law as violated if ANY rule covering it is violated, so the
  overlap collapses into one verdict rather than double counting.

  Why a THIRD route to the same limb, when Signal/R0018 already exists
  -------------------------------------------------------------------
  R0018 formalizes the same duty but anchors it on `at_traffic_light` — the ego
  being inside the signal's trigger volume — held together with a downstream red
  for `redHoldFrames = secondsToFrames 1 = 20` frames. That rule was MEASURED
  INERT on the only capture that exercises the law: in `database/red_light_violation`
  the state R0018 needs holds for exactly 15 frames (74–88 inclusive), because
  `at_traffic_light` turns on at frame 74 while the RSV already places the ego in
  the junction at frame 89. R0018's bounded window therefore never closes, and it
  reports *compliant* on a capture the CARLA-server oracle labels violated.

  This rule is an independent grounding route for the same limb. It reads no
  `at_traffic_light` at all, and it contains **no duration constant** — see the
  first formalization choice.

  The formula
  -----------
  The governed state, all of it evaluated while the ego is still short of the
  junction:

      approachOnRed :=
        isEgo v ⋀ ¬ₛ inAnyJunction v
              ⋀ inLane v lApproach ⋀ laneTravelsTo lApproach lControlled
              ⋀ controlsLane d lControlled ⋀ signalRed d

  The forbidden continuation from such a position:

      (signalRed d ⋀ ¬ₛ stopHere) 𝒰 (inLane v lControlled ⋀ signalRed d)

  read as: the light stays red and no qualifying stop happens, until the ego
  occupies the very lane that light controls, with the light still red. That is
  "passed the point of no return on a red that never released, without stopping".

  Four things about it are deliberate.

  * **NO DURATION CONSTANT.** R0018's 20-frame hold exists to acquit the driver
    whose signal releases to green as they arrive; it is also the reason R0018 is
    inert (above). This rule gets the same protection from the statute's own
    words instead: `signalRed d` sits on the LEFT arm of the until as well as in
    the anchor, so the light must be red *continuously* from the anchor frame
    through to the entry frame. A signal that releases to green on approach
    breaks the left arm and no conviction follows — `red_releases_to_green_before_entry`
    is the discriminating scenario. Do not reintroduce a frame count.

  * **THE APPROACH HOP IS LOAD-BEARING.** `inLane v lApproach ⋀
    laneTravelsTo lApproach lControlled` must stay. Measured: deleting it still
    returns the right verdict on all four captures, but from an anchor at frame 0
    whose witness is the ego entering a *different* lane 146 frames later — a
    long-range coincidence, and a false positive waiting for the first capture
    where a distant light happens to hold red.

  * **THE ENTRY TEST IS `inLane v lControlled`, NOT `inAnyJunction v`.** The lane
    the ego enters must be the lane `d` controls; that is what ties the red
    signal to the intersection the ego is actually entering. With
    `inAnyJunction v` any red light anywhere in the graph could discharge the
    until — see `cross_direction_red_is_not_the_egos_signal`.

  * **THE STOP THAT COUNTS is `stopped v ⋀ ¬ₛ inAnyJunction v`** — at rest, and
    still short of the junction. A vehicle that first comes to rest with its lane
    assignment already flipped into the junction has not stopped *before*
    entering. This matches `Stop/R0007`, `Signal/R0018` and `Stop/R0019`.

  DEVIATION FROM THE PLANNED FORMULA — the anchor is the ONSET, not every frame
  ----------------------------------------------------------------------------
  The node spec suggested `□ ¬ₛ (approachOnRed ⋀ until …)`, i.e. re-asking the
  obligation at every frame of the governed state. That shape **convicts a driver
  who has already discharged the duty**, and it fails this node's own
  `stops_before_entering` scenario for any trace in which at least one moving
  approach frame follows the standstill: pick an anchor after the stop, and no
  stop lies between that anchor and the entry, so the until finds its witness.
  The only traces on which the every-frame shape acquits such a driver are ones
  where the standstill is immediately followed by the entry frame — i.e. traces
  contrived to agree with the formula.

  What is written here instead is the onset shape `Stop/R0007` and `Signal/R0018`
  already use, which is the past-free way to name the FIRST frame of a governed
  episode:

      (approachOnRed ⟹ obligation)
        ⋀ □ ((¬ₛ approachOnRed ⋀ ◯ approachOnRed) ⟹ ◯ obligation)

  The first conjunct covers a capture that already begins inside a governed
  approach; the box covers every later frame at which one begins. This is
  strictly weaker than `□ ¬ₛ (…)` — it convicts a subset — and every case in
  that difference is a driver who stopped, or a red that released, between the
  onset and the entry. Those are precisely the cases this rule is meant to
  acquit and hand to R0010. In particular, on a capture where the governed state
  holds continuously from its onset to the entry with no stop, the two shapes
  agree, so the measurement reported in the node spec is unaffected.

  Other formalization choices the text did not dictate
  ---------------------------------------------------
  * **"Steady red" is `light_state = "Red"`.** `"Yellow"`, `"Off"` and
    `"Unknown"` are outside this rule; `str(carla.TrafficLightState)` has no
    separate flashing-red state.

  * **"A complete stop" is ONE frame of `Pred.stopped` (≤ 0.1 m/s), not a dwell.**
    This limb demands a complete stop and says nothing about remaining stopped;
    the one-second standstill belongs to EX-STOP-001 (`Stop/R0007`).

  * **`isEgo v` is a data restriction, not a reading of the law.** The statute
    binds every driver, but `speed` exists on the ego node alone
    (`copy_carla_actor_state` / `copy_carla_control` are called for the ego only;
    `carla/schema.json` → `unavailable.non_ego_dynamics`), so `stopped` is false
    at every frame for any other binder — which would make the *left* arm of the
    until true forever and turn the rule into a red-light-entry detector for
    other vehicles, duplicating R0010 from data that cannot support it. The gate
    on `isEgo` keeps the rule silent about other drivers rather than wrong.

  * **The signal is an explicit binder** rather than `Pred.facingRedSignal v`.
    `facingRedSignal` / `governs` reduce to the ego's OWN `controls` edge, which
    for a traffic light exists only once the vehicle is already inside the
    junction (`Core/Vocab.lean` § 8; `carla/schema.json` →
    `relation_labels.notes.controls_is_the_only_governance_edge`), so conjoining
    either with `¬ₛ inAnyJunction v` is empty on real data — the mistake that
    made the deleted `Signal/R0004` unsatisfiable. Naming the light and reading
    its `controls` edge one lane DOWNSTREAM of the ego is what keeps the
    antecedent satisfiable on the approach.

  Residues
  --------
  (a) **No stop line exists** (`carla/schema.json` →
      `unavailable.stop_line_and_junction_geometry`), so "before the marked stop
      line" becomes "before occupying the lane the signal controls". Measured:
      the RSV grants that occupancy 16 frames (0.8 s) EARLIER than the CARLA
      server's centre-based entry (RSV frame 89 vs oracle 105 in
      `red_light_violation`; 123 vs 140 in `red_light_compliant`), because `isIn`
      is bounding-box overlap. The deadline for the stop is therefore 0.8 s
      earlier than a human would judge it — the *safe* direction for this rule
      (it can only acquit a driver a human would convict on the margin) and the
      unsafe direction for R0007/R0019.

  (b) **The `controls` edge carries an unrecorded tolerance.** `controlsTrafficOf`
      is built with `get_distance(...) < segment_length * 0.5` = 0.5 m
      (`carla/schema.json` → `capture_preconditions.segment_length`), which no
      capture records. Measured, the edge is plentiful one hop downstream of the
      ego: 84 of 240 frames in `red_light_violation` and 119 of 240 in
      `red_light_compliant`, against 36 and 38 frames for the inside-the-junction
      edge R0010 needs.

  (c) **Nothing ties the light this formula binds to the light actually facing the
      ego.** `carla/schema.json` → `unavailable.traffic_light_grouping`:
      `carla_parent_id` is MEASURED absent from every traffic-light node in 480
      frames. The formula requires only that SOME red light controls the lane the
      ego's lane leads into — which is why the cross-direction scenario tests the
      `travelsTo` hop rather than the light's identity.

  (d) **The onset anchor re-arms if the governed state flickers.** Because (b)
      supplies the `controls` edge on only some frames, `approachOnRed` can drop
      and return mid-approach. Each return is a fresh onset, and a stop that
      happened before the gap does not discharge the obligation asked at the
      later one. This can convict a driver who stopped early on a long approach.
      R0018 carries the same limitation.

  (e) **No capture rate is assumed.** The formula contains no `SFProp.bounded`
      and no frame count, so `carla/schema.json` →
      `capture_preconditions.capture_rate` is irrelevant to this rule. That is
      the point of the first formalization choice.

  Span and trace length
  ---------------------
  `SFProp.frameSpan` is 2 — the two `◯`s of the onset conjunct, over atoms of
  span 1; there is no `.bounded` operator, so `TRACE_TOO_SHORT` cannot bite and
  there is no trailing blind zone beyond the last frame. Traces are still built
  long enough for the approach frames plus the entry frame each scenario
  describes.

  UNVALIDATED against real data
  -----------------------------
  The scenarios below are hand-built and contain exactly the structure this file
  bets on. The numbers quoted above come from the plan phase's measurement script
  (`iter_008/PLAN.md`), not from this rule having been run by `run_spec monitor`.
  Read this rule's GROUND count on the first capture containing a signalled
  junction: zero groundings, or groundings whose antecedent never fires, means
  the rule is untested — NOT that the driving was lawful.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Signal.R0026

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- Quantified over vehicles, traffic lights, and the two lanes of the
    approach → junction hop; gated on the ego, the only node carrying `speed`. -/
def schema : PropertySchema where
  name    := "entry_on_red_without_stopping"
  binders := [ vehicleBinder "v", trafficLightBinder "d"
             , laneBinder "lApproach", laneBinder "lControlled" ]
  formula := fun env =>
    let v           := arg env 0
    let d           := arg env 1
    let lApproach   := arg env 2
    let lControlled := arg env 3
    -- The governed approach: the ego is not yet in any junction, occupies
    -- `lApproach`, `lApproach` leads into `lControlled`, and a RED light `d`
    -- controls `lControlled`. The `controls` edge is read one hop downstream of
    -- the ego, which is where it exists.
    let approachOnRed :=
      isEgo v ⋀ ¬ₛ (inAnyJunction v)
        ⋀ inLane v lApproach ⋀ laneTravelsTo lApproach lControlled
        ⋀ controlsLane d lControlled ⋀ signalRed d
    -- A complete stop that counts: at rest, and still short of the junction.
    let stopHere := stopped v ⋀ ¬ₛ (inAnyJunction v)
    -- The point of no return: occupying the very lane `d` controls, `d` still red.
    let entryOnRed := inLane v lControlled ⋀ signalRed d
    -- Forbidden from a governed position: the red holds and no qualifying stop
    -- happens, until the ego occupies the controlled lane. Strong until under the
    -- negation, so a trace that ends on the approach is compliant rather than
    -- convicted for an entry that never happened.
    let obligation := ¬ₛ ((signalRed d ⋀ ¬ₛ stopHere) 𝒰 entryOnRed)
    -- Asked once per governed episode: at position 0 if the capture already
    -- begins inside one, and at every later frame at which one begins.
    (approachOnRed ⟹ obligation)
      ⋀ □ ((¬ₛ approachOnRed ⋀ ◯ approachOnRed) ⟹ ◯ obligation)

def entry : RuleEntry where
  nodeId  := "Signal/R0026_entry_on_red_without_stopping"
  lawRefs := ["EX-SIGNAL-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

private def egoId          : Nat := 1
private def approachLane   : Nat := 10
private def controlledLane : Nat := 11
private def approachRoad   : Nat := 20
private def junctionRoad   : Nat := 21
private def junctionId     : Nat := 30
private def lightId        : Nat := 40

/-- Road structure shared by every trace: the controlled lane `Lane 100_-1`
    inside `Road 100` inside `Junction 5`, the approach lane `Lane 7_-1` on an
    ordinary road that `travelsTo` it, and the traffic light.

    Only the junction road carries an `isIn` edge to the junction node, so
    `Pred.inAnyJunction` is true exactly for a vehicle in `controlledLane`.

    The light's `.controls` edge goes to the junction lane **only, never to the
    approach lane** — the structure a real capture has (residue (b)). Giving these
    traces an approach-side governance edge they will not have in the field is
    exactly what would make them agree with a formalization that cannot ground. -/
private def structureEntities (state : String) : List Entity :=
  [ mkLane approachLane   "Lane 7_-1",   mkRoad approachRoad "Road 7"
  , mkLane controlledLane "Lane 100_-1", mkRoad junctionRoad "Road 100"
  , mkJunction junctionId "Junction 5"
  , mkTrafficLight lightId "Light 1" state ]

private def structureRels : List Relation :=
  [ mkRel approachLane   .isIn approachRoad
  , mkRel controlledLane .isIn junctionRoad
  , mkRel junctionRoad   .isIn junctionId
  , mkRel approachLane   .travelsTo controlledLane
  , mkRel lightId        .controls  controlledLane ]

/-- One frame with the ego on the approach lane at `speed` m/s and the light
    showing `state`: short of the junction, and — as on a real capture — carrying
    no `controls` edge of its own. `at_traffic_light` is left at its default
    `"false"`: unlike `Signal/R0018`, no predicate in this rule reads it. -/
private def approachFrame (state : String) (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: structureEntities state)
    (structureRels ++ [mkRel egoId .isIn approachLane])

/-- One frame with the ego in the controlled junction lane at `speed` m/s and the
    light showing `state` — the lane → road → junction chain
    `Pred.inAnyJunction` walks. -/
private def entryFrame (state : String) (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: structureEntities state)
    (structureRels ++ [mkRel egoId .isIn controlledLane])

/-- 12 frames. Positions 0–7: on the approach at a steady 6.000 m/s, `d` red.
    Positions 8–11: in the controlled junction lane, `d` still red.

    Forbidden: the ego passed from the approach into the lane a held red controls
    without ever stopping. The measured shape of `database/red_light_violation`
    frames 74–89. -/
def traceRollsThroughHeldRed : Trace :=
  List.replicate 8 (approachFrame "Red" "6.000")
  ++ List.replicate 4 (entryFrame "Red" "6.000")

/-- 12 frames, identical to `traceRollsThroughHeldRed` except that the ego
    decelerates on the approach to a minimum of 0.500 m/s before entering.

    **The minimal-pair partner of `traceStopsBeforeEntering`.** 0.500 m/s is
    above `Pred.stopped`'s 0.1 m/s threshold (`speedLe e 100` in milli-units), so
    no complete stop has happened and this must still convict. Together the two
    traces pin the threshold. -/
def traceSlowRollIsNotAStop : Trace :=
  [ approachFrame "Red" "6.000", approachFrame "Red" "5.000"
  , approachFrame "Red" "4.000", approachFrame "Red" "3.000"
  , approachFrame "Red" "2.000", approachFrame "Red" "1.000"
  , approachFrame "Red" "0.500", approachFrame "Red" "0.500" ]
  ++ List.replicate 4 (entryFrame "Red" "1.000")

/-- 12 frames. Positions 0–3: decelerating on the approach under a red.
    Positions 4–6: 0.000 m/s, still on the approach lane and outside every
    junction. Positions 7–8: moving off again, still on the approach, `d` still
    red. Positions 9–11: in the controlled lane with `d` still red.

    Lawful *under this rule*: its duty is the stop, and the stop happened. The
    entry on red itself is `Signal/R0010`'s offence, not this one.

    **The discriminating scenario for two independent choices.** Drop the stop
    conjunct from the until and this convicts, collapsing this rule into R0010.
    Keep the node spec's every-frame anchor `□ ¬ₛ (approachOnRed ⋀ …)` and this
    also convicts — from the anchor at position 7, whose witness is the entry at
    position 9 with no stop in between. Positions 7–8 are in this trace for
    exactly that reason. -/
def traceStopsBeforeEntering : Trace :=
  [ approachFrame "Red" "6.000", approachFrame "Red" "4.000"
  , approachFrame "Red" "2.000", approachFrame "Red" "1.000"
  , approachFrame "Red" "0.000", approachFrame "Red" "0.000"
  , approachFrame "Red" "0.000", approachFrame "Red" "1.000"
  , approachFrame "Red" "3.000" ]
  ++ List.replicate 3 (entryFrame "Red" "4.000")

/-- 12 frames. Positions 0–3: on the approach at 6.000 m/s under a red.
    Position 4: the light goes green, the ego still on the approach and still at
    6.000 m/s. Positions 6–11: in the controlled lane, `d` green. The ego never
    stops anywhere.

    Lawful: the signal released before the point of no return, so no duty to stop
    ever matured. **The discriminating scenario for the continuous-red
    requirement** — remove `signalRed d` from the until's left arm and this
    convicts, which is the failure that a duration constant was invented to
    avoid. -/
def traceRedReleasesToGreenBeforeEntry : Trace :=
  List.replicate 4 (approachFrame "Red" "6.000")
  ++ List.replicate 2 (approachFrame "Green" "6.000")
  ++ List.replicate 6 (entryFrame "Green" "6.000")

/-- 10 frames, all of them on the approach at 6.000 m/s under a red that never
    releases. The ego never reaches the controlled lane, and the trace ends there.

    Lawful: the strong until has no witness, so a capture that stops short of the
    junction is reported compliant rather than convicted for an entry that never
    happened. A weak until here, or an obligation phrased positively as "must
    stop", convicts this driver. -/
def traceStillOnTheApproachWhenTheTraceEnds : Trace :=
  List.replicate 10 (approachFrame "Red" "6.000")

----------------------------------------------------------------------
-- The cross-direction scenario needs a second signal and a second approach
----------------------------------------------------------------------

private def crossLane         : Nat := 12
private def crossJunctionRoad : Nat := 22
private def crossApproachLane : Nat := 13
private def crossApproachRoad : Nat := 23
private def redLightId        : Nat := 41

/-- The crossing arm of the same junction: `Lane 101_-1` inside `Road 101` inside
    `Junction 5`, reached from its own approach `Lane 8_-1`, and a SECOND traffic
    light showing red that controls it. The ego's approach lane has no
    `travelsTo` edge to `Lane 101_-1`, and the ego never occupies either crossing
    lane. -/
private def crossEntities : List Entity :=
  [ mkLane crossLane         "Lane 101_-1", mkRoad crossJunctionRoad "Road 101"
  , mkLane crossApproachLane "Lane 8_-1",   mkRoad crossApproachRoad "Road 8"
  , mkTrafficLight redLightId "Light 2" "Red" ]

private def crossRels : List Relation :=
  [ mkRel crossLane         .isIn crossJunctionRoad
  , mkRel crossJunctionRoad .isIn junctionId
  , mkRel crossApproachLane .isIn crossApproachRoad
  , mkRel crossApproachLane .travelsTo crossLane
  , mkRel redLightId        .controls  crossLane ]

/-- One frame of the two-signal junction. `Light 1` (green) controls the lane the
    ego's approach leads into; `Light 2` (red) controls the crossing arm. `egoLane`
    is the lane the ego occupies. -/
private def crossFrame (egoLane : Nat) (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: (structureEntities "Green" ++ crossEntities))
    (structureRels ++ crossRels ++ [mkRel egoId .isIn egoLane])

/-- 9 frames. Positions 0–5: the ego on its own approach at 6.000 m/s, its own
    signal green. Positions 6–8: in its own controlled lane, still green. The ego
    never stops, and never touches the crossing arm.

    Lawful: the light that controls the lane the ego enters is the green one.
    Binders are universally quantified and both lights are present in every
    frame, so `d` grounds twice per frame — the scenario cannot pass by having
    nothing to bind. It fails if the entry test is weakened to
    `inAnyJunction v`, which the crossing arm's red light would then discharge. -/
def traceCrossDirectionRedIsNotTheEgosSignal : Trace :=
  List.replicate 6 (crossFrame approachLane "6.000")
  ++ List.replicate 3 (crossFrame controlledLane "6.000")

def scenarios : List Scenario :=
  [ { name := "rolls_through_held_red"
    , trace := traceRollsThroughHeldRed
    , expected := false }
  , { name := "slow_roll_is_not_a_stop"
    , trace := traceSlowRollIsNotAStop
    , expected := false }
  , { name := "stops_before_entering"
    , trace := traceStopsBeforeEntering
    , expected := true }
  , { name := "red_releases_to_green_before_entry"
    , trace := traceRedReleasesToGreenBeforeEntry
    , expected := true }
  , { name := "still_on_the_approach_when_the_trace_ends"
    , trace := traceStillOnTheApproachWhenTheTraceEnds
    , expected := true }
  , { name := "cross_direction_red_is_not_the_egos_signal"
    , trace := traceCrossDirectionRedIsNotTheEgosSignal
    , expected := true } ]

end TrafficSpec.Rules.Signal.R0026
