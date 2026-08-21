/-
  Rule R0007 — the complete stop at a stop sign.

  Law text (EX-STOP-001, "Complete stop"):
    "A driver approaching a stop sign shall bring the vehicle to a complete stop
     before entering the intersection, and shall remain stopped for not less
     than one second."

  Formalization notes
  -------------------
  * **The obligation is attached to the ONSET of the governed approach, not to
    every frame of it, and that is a correction to the planned shape.** The plan
    specified `□ (approach ⟹ ¬ₛ ((¬ₛ dwell) 𝒰 inJunction v j))`. That formula is
    unsound in the direction that matters — it convicts a *compliant* driver —
    and it was measured doing so before this file was rewritten: with the plan's
    own `full_stop_then_proceeds` trace (stopped over positions 6–27, junction
    entered at 32) the gate reported `expected true, got false`, and likewise for
    `dwell_exactly_twenty_frames`.

    The reason is structural, not a detail of the traces. `.bounded 20 (stopped v)`
    holds at a position only if a *fresh* twenty-frame standstill starts there,
    so in that trace it is true only at positions 6, 7 and 8. `□` then re-asks the
    question at position 9, which is in the middle of the driver's stop, and at
    positions 28–31, which are after it: from any of those the future contains no
    new complete dwell before the junction, so the inner until succeeds and the
    implication fails. A future-only formula evaluated at position 9 cannot
    distinguish "stopped since 6, nineteen frames of standstill still to come"
    from "stopped at 9 for nineteen frames and then went", because the difference
    between them lies entirely in the past and this fragment has no past
    operators. Any formula of the plan's shape convicts every driver who does
    stop and then spends even one frame on the approach afterwards.

    What is written here instead states the same obligation once per approach:

      (approach ⟹ obligation) ⋀ □ ((¬ₛ approach ⋀ ◯ approach) ⟹ ◯ obligation)

    The first conjunct covers a capture that already begins with the ego on the
    governed approach; the box covers every later frame at which the ego *enters*
    the governed approach, which is the past-free way to say "the first frame of
    an approach" — a position whose predecessor is not an approach frame. The
    obligation is then evaluated from that onset, looking forward over the whole
    approach, which is where the driver's whole opportunity to stop lies.

  * **The obligation itself.** `obligation := ¬ₛ ((¬ₛ dwell) 𝒰 inJunction v j)`,
    read as: it must not happen that the ego reaches junction `j` without a
    complete one-second standstill having *begun* somewhere on the way. The
    until must sit under the negation, and `Core/Semantics.lean::loopUntil` is
    why: it is a strong until, false when its right arm never comes true, so a
    driver who is still on the approach when the trace ends is reported
    compliant rather than convicted for an entry that never happened. Scenario
    `approaches_but_never_enters` fails if that polarity is inverted.

  * **The dwell is `.bounded 20 (stopped v ⋀ ¬ₛ inAnyJunction v)`, and the second
    conjunct is a tightening the plan did not ask for.** Without it, the window
    that clears the driver may straddle the junction entry: five frames stopped
    on the approach and fifteen stopped inside the box would satisfy a bare
    `.bounded 20 (stopped v)` evaluated just before entry. The statute requires
    the second of standstill *before* entering, so the whole window is required
    to lie outside the junction. This cannot weaken the rule — it only removes
    ways to be acquitted — and it changes no scenario here, since in all five the
    ego is only ever stopped on the approach.

  * **`isEgo v` is a data restriction, not a reading of the law.** The statute
    binds every driver, but `speed` exists on the ego node only
    (`copy_carla_actor_state` is called for the ego alone; `carla/schema.json` →
    `unavailable.non_ego_dynamics`), so `Pred.stopped` on any other binder is
    false at every frame and every other vehicle would read as never having
    stopped at all. Ungated, this rule would convict every non-ego vehicle that
    crosses a stop-sign junction. It makes no claim either way about them.

  * **The sign and the junction are explicit binders, not `Pred.facingStopSign`
    and `Pred.inAnyJunction`.** `Pred.governs s v` performs exactly the same
    `controls`-edge lookup that `facingStopSign` performs, so nothing is lost,
    and binding them makes a capture with no stop sign — or no junction — ground
    *zero* times, which the gate's vacuity check catches, rather than quietly
    reporting compliance for the whole trace.

  Residues
  --------
  (1) **There is no stop line.** `carla/schema.json` →
      `unavailable.stop_line_and_junction_geometry`: no coordinates survive for
      structure nodes, so "before entering the intersection" degrades to "while
      occupying a lane that `travelsTo` a lane of the junction, and not yet
      occupying a lane of the junction". A driver who stops well past the painted
      line but short of the junction lane is credited by this rule and would not
      be by the statute; so is one whose nose is over the line while the map still
      maps the vehicle to the approach lane. The granularity of that error is the
      lane-node granularity of the abstraction, `SGG(segment_length=1.0)`.

  (2) **The dwell is a frame count, not a duration.** `dwellFrames :=
      TrafficSpec.secondsToFrames 1` is 20 frames, and 20 frames is one second
      only if the capture ran at 20 Hz. No capture records its rate
      (`carla/schema.json` → `capture_preconditions.capture_rate`; frames carry no
      timestamp by construction), so this is unverifiable from the data. At 40 Hz
      this rule accepts a half-second stop.

  (3) **"A complete stop" is ≤ 0.1 m/s, not zero.** That is `Pred.stopped`'s
      threshold (`speedLe e 100` in milli-units). A vehicle creeping at 0.09 m/s
      for a second is credited with a complete stop.

  (4) **The governance edge is UNVERIFIED — read this before trusting a green
      verdict.** The whole antecedent rests on `Pred.governs s v`, the stop sign's
      `controls` edge to the lane the ego occupies, holding while the ego is still
      *outside* the junction. This is the same shape that made the earlier
      `Signal/R0004` unsatisfiable: a traffic light's `controls` edge exists only
      once the vehicle is already inside the junction, so "governed ⋀ not yet in
      the junction" was an empty conjunction and that rule reported compliant on
      every red-light runner. A stop sign's `controls` edge is built from its
      TRIGGER VOLUME, which sits on the approach, so the conjunction is expected
      to be satisfiable here — but that is PROBABLE and UNVERIFIED, and the
      generator's own test carries an unstated tolerance
      (`get_distance(...) < self.segment_length * 0.5`).

      **The scenarios below are not evidence either way.** They are hand-built and
      contain whatever edge this file puts in them, which is deliberately the
      structure the rule is betting on: `controls` from the sign to the APPROACH
      lane, not to the junction's inner lane. The first run of `run_spec monitor`
      must read the GROUND count for this rule on a capture that contains a stop
      sign. **A grounding count of zero there means the antecedent is empty and
      this rule is worthless — it does not mean the driving was lawful.**

  * **Span and trace length.** `SFProp.frameSpan` of this formula is 21: the
    `.bounded 20` window contributes 20 and the `◯` in front of the onset
    obligation adds one. Every scenario trace is 40 frames, comfortably above the
    gate's `TRACE_TOO_SHORT` threshold. Note the corollary from
    `Core/Formula.lean`: a violation confined to the last 20 frames of a capture
    cannot be reported, because the dwell window would overrun the trace and
    `loopBounded` reads that as false.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Stop.R0007

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- One second of standstill as a frame count: 20 frames at the 20 Hz reference
    capture rate. See residue (2) — no capture records its own rate. -/
def dwellFrames : Nat := TrafficSpec.secondsToFrames 1

/-- Quantified over vehicles, stop signs and junctions; effective on the ego
    vehicle, the only one that carries a `speed` channel. -/
def schema : PropertySchema where
  name    := "stop_sign_dwell"
  binders := [vehicleBinder "v", stopSignBinder "s", junctionBinder "j"]
  formula := fun env =>
    let v := arg env 0
    let s := arg env 1
    let j := arg env 2
    -- The governed approach: the ego, on a lane this stop sign controls, that
    -- leads into junction `j`, and not yet inside any junction.
    let approach :=
      isEgo v ⋀ governs s v ⋀ approachingJunction v j ⋀ ¬ₛ (inAnyJunction v)
    -- One second of standstill beginning here, entirely outside the junction.
    let dwell := SFProp.bounded dwellFrames (stopped v ⋀ ¬ₛ (inAnyJunction v))
    -- Forbidden from here on: reaching the junction with no complete dwell ever
    -- beginning on the way. Strong until, under the negation, so a trace that
    -- ends on the approach is compliant rather than convicted.
    let obligation := ¬ₛ ((¬ₛ dwell) 𝒰 (inJunction v j))
    -- Discharged once per approach: at position 0 if the capture already begins
    -- on the approach, and at every later frame the ego enters one.
    (approach ⟹ obligation)
      ⋀ □ ((¬ₛ approach ⋀ ◯ approach) ⟹ ◯ obligation)

def entry : RuleEntry where
  nodeId  := "Stop/R0007_stop_sign_dwell"
  lawRefs := ["EX-STOP-001"]
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
private def stopSignId   : Nat := 40

/-- Road structure shared by every trace: one lane inside a road inside the
    junction, one approach lane on an ordinary road that `travelsTo` it, and the
    stop sign. Only the junction road carries an `isIn` edge to the junction
    node, so `Pred.inJunction` is true exactly for a vehicle in `junctionLane`
    and `Pred.approachingJunction` exactly for one in `approachLane`.

    The sign's `.controls` edge goes to the **approach** lane, which is what the
    rule bets on — see residue (4). Both the sign and the junction are present in
    every frame of every trace, so `s` and `j` always bind and no scenario can
    pass by having nothing to ground on. -/
private def structureEntities : List Entity :=
  [ mkLane approachLane "Lane 7_-1",   mkRoad approachRoad "Road 7"
  , mkLane junctionLane "Lane 100_-1", mkRoad junctionRoad "Road 100"
  , mkJunction junctionId "Junction 5"
  , mkStopSign stopSignId "stop_sign_0" ]

private def structureRels : List Relation :=
  [ mkRel approachLane .isIn approachRoad
  , mkRel junctionLane .isIn junctionRoad
  , mkRel junctionRoad .isIn junctionId
  , mkRel approachLane .travelsTo junctionLane
  , mkRel stopSignId   .controls  approachLane ]

/-- One frame with the ego on the approach lane at `speed` m/s: governed by the
    sign, approaching the junction, not yet in it. -/
private def approachFrame (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: structureEntities)
    (structureRels ++ [mkRel egoId .isIn approachLane])

/-- One frame with the ego in the junction's inner lane at `speed` m/s — the
    two-hop lane → road → junction chain `Pred.inJunction` walks. The sign does
    not control this lane, so the approach antecedent is false here. -/
private def insideFrame (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: structureEntities)
    (structureRels ++ [mkRel egoId .isIn junctionLane])

/-- 40 frames. Positions 0–5: decelerating on the approach, 6.000 → 1.000 m/s.
    Positions 6–27: standstill at 0.000 m/s — 22 consecutive frames, two more
    than the 20-frame dwell. Positions 28–31: accelerating away, still on the
    approach. Positions 32–39: inside the junction at 5.000 m/s.

    **This is the discriminating scenario for where the obligation is
    discharged.** Positions 9 and 28–31 are approach frames from which no *fresh*
    twenty-frame standstill is still to come, so re-asking the obligation at
    every approach frame — the shape this file's header rejects — convicts this
    compliant driver. -/
def traceFullStopThenProceeds : Trace :=
  [ approachFrame "6.000", approachFrame "5.000", approachFrame "4.000"
  , approachFrame "3.000", approachFrame "2.000", approachFrame "1.000" ]
  ++ List.replicate 22 (approachFrame "0.000")
  ++ [ approachFrame "1.000", approachFrame "2.000"
     , approachFrame "3.000", approachFrame "4.000" ]
  ++ List.replicate 8 (insideFrame "5.000")

/-- 40 frames. Positions 0–7 approaching at 5.000 m/s, positions 8–27 at
    0.050 m/s — exactly 20 frames, and 0.050 is inside `Pred.stopped`'s 0.1 m/s
    threshold, so this also pins residue (3) — then acceleration on the approach
    and entry at position 32. The minimal-pair partner of
    `dwell_twelve_frames_too_short`. -/
def traceDwellExactlyTwentyFrames : Trace :=
  List.replicate 8 (approachFrame "5.000")
  ++ List.replicate 20 (approachFrame "0.050")
  ++ [ approachFrame "1.000", approachFrame "2.000"
     , approachFrame "3.000", approachFrame "4.000" ]
  ++ List.replicate 8 (insideFrame "5.000")

/-- 40 frames on the approach at 4.000 m/s: the ego never stops and never enters
    the junction — the trace simply ends, or the driver turned off.

    **This is the discriminating scenario for the strong-until polarity.** The
    obligation attaches to entering; nobody entered. Assert the inner until
    positively instead of under the negation and this convicts a driver who never
    reached the intersection. -/
def traceApproachesButNeverEnters : Trace :=
  List.replicate 40 (approachFrame "4.000")

/-- 40 frames. Positions 0–9 at 5.000 m/s, positions 10–25 crawling at
    0.400 m/s — above `Pred.stopped`'s 0.1 m/s threshold at every frame, so no
    dwell window ever begins — then acceleration and entry at position 32. The
    classic rolling stop. -/
def traceRollingStopNoDwell : Trace :=
  List.replicate 10 (approachFrame "5.000")
  ++ List.replicate 16 (approachFrame "0.400")
  ++ [ approachFrame "1.000", approachFrame "2.000", approachFrame "3.000"
     , approachFrame "4.000", approachFrame "4.500", approachFrame "5.000" ]
  ++ List.replicate 8 (insideFrame "5.000")

/-- 40 frames. Positions 0–9 at 5.000 m/s, positions 10–21 at a genuine
    standstill of 0.000 m/s but for only 12 frames, positions 22–27 accelerating
    on the approach, entry at position 28. A real stop, eight frames short of the
    second the statute demands. -/
def traceDwellTwelveFramesTooShort : Trace :=
  List.replicate 10 (approachFrame "5.000")
  ++ List.replicate 12 (approachFrame "0.000")
  ++ [ approachFrame "1.000", approachFrame "2.000", approachFrame "3.000"
     , approachFrame "4.000", approachFrame "4.500", approachFrame "5.000" ]
  ++ List.replicate 12 (insideFrame "5.000")

def scenarios : List Scenario :=
  [ { name := "full_stop_then_proceeds"
    , trace := traceFullStopThenProceeds
    , expected := true }
  , { name := "dwell_exactly_twenty_frames"
    , trace := traceDwellExactlyTwentyFrames
    , expected := true }
  , { name := "approaches_but_never_enters"
    , trace := traceApproachesButNeverEnters
    , expected := true }
  , { name := "rolling_stop_no_dwell"
    , trace := traceRollingStopNoDwell
    , expected := false }
  , { name := "dwell_twelve_frames_too_short"
    , trace := traceDwellTwelveFramesTooShort
    , expected := false } ]

end TrafficSpec.Rules.Stop.R0007
