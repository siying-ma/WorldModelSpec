/-
  Rule R0015 — following too closely: the speed-scaled route into the
  "reasonable and prudent" standard.

  Law text (EX-FOLLOW-001, "Following too closely"):
    "The driver of a motor vehicle shall not follow another vehicle more closely
     than is reasonable and prudent. A vehicle shall not remain within four
     metres of the vehicle it is following."

  SCOPE — THIS FILE IS ONE ROUTE INTO THE FIRST SENTENCE
  ------------------------------------------------------
  This rule formalizes the **first** sentence, and only one sufficient condition
  under it: remaining within sixteen metres of the vehicle being followed while
  travelling at forty km/h or more. The **second** sentence — the four-metre
  bright line — is the sibling node `Following/R0003_following_distance` and is
  not restated here.

  OVERLAP WITH `Following/R0014_prudent_gap_when_lead_brakes` IS DELIBERATE.
  R0014 is the other route into the same open-textured sentence: closeness plus
  the lead vehicle's *brake light*. The two are independent sufficient
  conditions, not a partition, and a single close-following event may be
  convicted by both — which is not double counting, because the law's verdict
  under EX-FOLLOW-001 is "violated" either way. This node exists precisely
  because R0014's evidence channel is fragile: `carla/schema.json` →
  `partially_available.another_vehicle_braking_or_signalling` warns that
  `light_brake` stays false if the simulated traffic manager never actuates it,
  in which case R0014 can never convict anything. This rule reads instead the
  only motion channel the graph carries at all — the ego's own `speed`
  (`unavailable.non_ego_dynamics`: `copy_carla_actor_state` /
  `copy_carla_control` are called for the ego node alone) — so it keeps the
  first sentence measurable on a capture where no brake light ever fires.

  Neither rule is the whole of EX-FOLLOW-001. The first sentence is a standard
  whose content depends on speed, surface, visibility and traffic; this file
  reads speed and separation only, and makes no claim that a trace it reports
  compliant was prudent.

  Formalization notes — all three numbers below are ours, none is the statute's
  ---------------------------------------------------------------------------
  * **Why speed is the route in.** "More closely than is reasonable and prudent"
    is comparative, and what it compares against is the stopping distance the
    driver needs, which grows with speed. A gap that is prudent at walking pace
    is imprudent at road speed. The graph carries no speed for any vehicle but
    the ego, so the pair that can be tested is (ego speed, quantised
    separation): the rule convicts on the conjunction of a high enough speed and
    a small enough gap, held long enough to count as *remaining*.

  * **`speedThresholdKph := 40` and `gapMetres := 16` are one joint choice, and
    the joint reading is a headway.** Sixteen metres at forty km/h (11.11 m/s)
    is about 1.4 s of headway. That is deliberately *short of* the usual
    two-second rule: the two-second figure would demand about 22 m at this
    speed, which falls in the `visible` (16–25 m) band, and convicting there
    would convict a great deal of ordinary town traffic on evidence that cannot
    distinguish 17 m from 24 m. 1.4 s leaves margin for the band quantisation
    while still being clearly less headway than a driver needs to react and
    stop. A reviewer who reads the clause more strictly should be able to raise
    `gapMetres` to 25 (the `visible` upper edge) or lower `speedThresholdKph`,
    changing one number and nothing else — which is why both are named defs and
    neither is inlined.

    `gapMetres := 16` is written as `Pred.withinMetres 16`, never as a band
    name: it is the band union `safetyHazard` (<2 m) + `nearCollision` (2–4 m) +
    `superNear` (4–7 m) + `veryNear` (7–10 m) + `near` (10–16 m), i.e.
    everything at or inside the `near` band's upper edge, and `.near` alone
    would mean "between 10 and 16 metres away".

  * **`persistFrames := TrafficSpec.secondsToFrames 1` = 20 frames, and
    "remain" carries no duration in the text.** One second is the shortest
    window that plainly distinguishes a gap being *held* from a gap that
    compresses momentarily — as it does while another vehicle cuts in, or while
    a lead vehicle brakes and the follower has not yet responded. Lower it and
    `brief_close_gap_at_speed` is convicted; raise it and a driver who sits 1.4 s
    behind a lead at road speed for nine tenths of a second escapes. Nothing in
    the clause settles it.

  * **`speedGeKph` is applied to `v`, under the `isEgo v` gate.** `speed` exists
    on the ego vehicle only (`carla/schema.json` →
    `unavailable.non_ego_dynamics`). Applied to `w` it would be silently false
    on every frame, the antecedent would never hold, and the rule would report
    compliant on every capture while still grounding — a vacuously true rule the
    vacuity guard cannot see. The `isEgo` gate is also a soundness requirement:
    no proximity or angular edge is ever emitted between two non-ego actors
    (`relation_coverage`, from `DEFAULT_PROXIMITY_RELATIONS` /
    `DEFAULT_DIRECTIONAL_RELATIONS`), so a non-ego follower's separation is
    unobservable, and ungated the rule would also read the reversed grounding in
    which the ego is the vehicle *being* followed. This rule therefore makes no
    claim about one non-ego vehicle following another.

  * **"the vehicle it is following" is `Pred.followingWithin`**, i.e.
    `sameLane v w ⋀ behind v w ⋀ withinMetres gapMetres v w`. Relation direction
    reads "src is ⟨rel⟩ tgt" (`Core/Vocab.lean` §5), so `behind v w` says **v is
    the follower** and `w` is the vehicle being followed; inverting the
    arguments would convict a vehicle for being tailgated at speed.

    Residue carried from R0003 and R0014: "following" is geometric, not
    intentional. A vehicle that has just changed into the lane behind another
    satisfies it. The stopped-queue over-conviction those rules record does not
    arise here — the speed gate excludes it — but its mirror does: the rule
    cannot tell a lead that is pulling away at the same speed from one that is
    stationary, because the lead's speed is unavailable, so a driver closing on
    a stopped obstruction and a driver holding station 16 m behind a car
    travelling at the same 40 km/h are treated alike. The second is the case
    this rule convicts and a reviewer might not; it is recorded rather than
    patched, because narrowing it needs the lead's motion.

  * **Both binders use `proximityVehicleBinder`, not `vehicleBinder`.** The
    proximity and angular tables cover only the base classes
    `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck`, so a `van` or a bare
    `vehicle` carries no distance edge and binding one would ground and then
    report compliance forever.

  * **Shape and trace length.** `□ (¬ₛ .bounded persistFrames forbidden)`: the
    safety shape, "at no position does the forbidden state hold for
    `persistFrames` consecutive frames". `SFProp.frameSpan` is therefore 20, and
    `Core/Semantics.lean::loopBounded` reads a window running off the end of the
    trace as false — so the last 19 frames of any trace are a blind zone in
    which a violation cannot be reported, and any trace shorter than 20 frames
    reports compliant whatever it contains. Every scenario below is 40 frames,
    and the violating one holds the forbidden state from frame 0, clear of the
    blind zone.

  RESIDUE — three things to read before trusting a verdict from this rule
  ----------------------------------------------------------------------
  (a) **The headway reading assumes the reference 20 Hz capture rate**, which no
      capture records (`capture_preconditions.capture_rate`; `Core/Scene.lean`
      freezes `captureHz := 20` and frames carry no timestamp by construction).
      At 40 Hz `secondsToFrames 1` = 20 frames means half a second, and this
      rule convicts twice as readily.

  (b) **Exact separation is unavailable** (`unavailable.exact_distance`: the
      base graph's metric `distance` is not copied by
      `process_to_junction_rsv`). "Sixteen metres" is the `near` band's upper
      edge, not a measured distance, and the band-to-metres mapping is
      hard-coded in `Core/Scene.lean::distanceBands` from the generator's
      overridable `DEFAULT_PROXIMITY_THRESHOLDS`
      (`capture_preconditions.proximity_band_metres`). Consequently the
      threshold cannot be tuned to any figure between the band edges.

  (c) **This is the rule in the library most likely to convict ordinary
      traffic-manager driving.** It needs no unusual event — just speed and a
      moderate gap, both of which routine simulated traffic produces. So when it
      disagrees with the human labels on the first `run_spec monitor` run, the
      first question is whether `speedThresholdKph` and `gapMetres` state a
      standard a human labeller shares, not whether the trace or the adapter is
      wrong. A high false-positive rate here is evidence about the constants.

  * **Not validated against real data.** The scenarios below were written from
    the same reading of the clause as the formula, so they cannot catch a
    misreading of it. Until `run_spec monitor` has compared this rule against a
    human-labelled capture, treat it as unvalidated.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Following.R0015

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The speed at or above which this rule treats a sixteen-metre gap as
    imprudent: forty km/h. A formalization choice — the first sentence states no
    speed. Read jointly with `gapMetres`: the pair is a ~1.4 s headway. -/
def speedThresholdKph : Nat := 40

/-- The gap this rule treats as imprudent at or above `speedThresholdKph`:
    sixteen metres, i.e. the band union `safetyHazard` + `nearCollision` +
    `superNear` + `veryNear` + `near`. Written as `Pred.withinMetres 16`, never
    as the band name `.near`, which is the 10–16 m band alone. A formalization
    choice — the first sentence states no distance. -/
def gapMetres : Nat := 16

/-- How long the ego must hold that gap at that speed before it counts as
    *remaining* there: one second = 20 frames at the reference 20 Hz capture
    rate. A formalization choice — the statute states no duration. -/
def persistFrames : Nat := TrafficSpec.secondsToFrames 1

/-- Quantified over vehicles that carry proximity edges; effective on the ego
    vehicle, the only one whose speed is published and whose separation from
    another actor is observable. -/
def schema : PropertySchema where
  name    := "prudent_gap_at_speed"
  binders := [proximityVehicleBinder "v", proximityVehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    -- The forbidden state: the ego v, travelling at or above forty km/h, is
    -- following w within sixteen metres. `speedGeKph` is on v — no other
    -- vehicle publishes `speed` — and `behind v w` inside `followingWithin`
    -- makes v the follower.
    □ (¬ₛ (SFProp.bounded persistFrames
             (isEgo v ⋀ speedGeKph v speedThresholdKph
                      ⋀ followingWithin gapMetres v w)))

def entry : RuleEntry where
  nodeId  := "Following/R0015_prudent_gap_at_speed"
  lawRefs := ["EX-FOLLOW-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

private def egoId  : Nat := 1
private def leadId : Nat := 2
private def laneId : Nat := 10
private def roadId : Nat := 20

/-- One shared driving lane on one ordinary road, present in every frame of
    every trace, so `sameLane` holds and both binders always bind — a scenario
    can never pass by having nothing to ground on. -/
private def structureEntities : List Entity :=
  [ mkLane laneId "Lane 7_-1", mkRoad roadId "Road 7" ]

private def structureRels : List Relation :=
  [ mkRel laneId .isIn roadId ]

/-- The ego at speed `speed` (decimal m/s, exactly as the generator renders it)
    and one other car. -/
private def occupants (speed : String) : List Entity :=
  [ mkEgo egoId .car speed, mkActor leadId "car_0" .car ]

private def occupantRels : List Relation :=
  [ mkRel egoId .isIn laneId, mkRel leadId .isIn laneId ]

/-- One frame with the ego at the other car's rear at proximity band `band`,
    travelling at `speed`. The generator computes each angular edge from the
    source actor's forward vector, so same-direction traffic yields one rear
    edge (`ego atDRearOf car_0`) and one front edge (`car_0 inDFrontOf ego`);
    the single distance edge is emitted ego-first, as the default relation
    table does. -/
private def followFrame (band : RelLabel) (speed : String) : Scene :=
  frame
    (occupants speed ++ structureEntities)
    (structureRels ++ occupantRels ++
      [ mkRel egoId .atDRearOf leadId
      , mkRel leadId .inDFrontOf egoId
      , mkRel egoId band leadId ])

/-- Forty frames at 12.000 m/s (43.2 km/h) holding the 16–25 m band. Fast, but
    the gap stays outside sixteen metres on every frame, so this rule has
    nothing to say. Also the check that `.near` is read as the far band it is:
    `.visible` sits just outside `withinMetres 16`. -/
def traceHighSpeedWideGap : Trace :=
  List.replicate 40 (followFrame .visible "12.000")

/-- Forty frames at 5.000 m/s (18 km/h) in the 10–16 m band throughout. Inside
    sixteen metres on every frame but well below the forty km/h threshold —
    crawling in traffic at a car-length-and-a-half is not imprudent following.
    The discriminating twin of `sustained_close_gap_at_speed`: the two traces
    differ only in the ego's speed. -/
def traceLowSpeedCloseGap : Trace :=
  List.replicate 40 (followFrame .near "5.000")

/-- Forty frames at 12.000 m/s throughout, with the gap compressing into the
    10–16 m band for exactly ten consecutive frames (positions 0–9) and then
    reopening to 16–25 m for the rest. Inside sixteen metres at speed, but not
    *remaining* there: ten frames is half of the twenty-frame window. Set
    `persistFrames := 10` and this scenario convicts. -/
def traceBriefCloseGapAtSpeed : Trace :=
  List.replicate 10 (followFrame .near "12.000")
    ++ List.replicate 30 (followFrame .visible "12.000")

/-- Forty frames at 12.000 m/s (43.2 km/h) in the 10–16 m band on every one of
    them: roughly a 1.3 s headway held for two full seconds. The forbidden state
    runs from frame 0, clear of the trailing nineteen-frame blind zone, and the
    gap never enters the four-metre band `Following/R0003` covers, so this trace
    must be convicted by this rule and acquitted by that one. -/
def traceSustainedCloseGapAtSpeed : Trace :=
  List.replicate 40 (followFrame .near "12.000")

def scenarios : List Scenario :=
  [ { name := "high_speed_wide_gap"
    , trace := traceHighSpeedWideGap
    , expected := true }
  , { name := "low_speed_close_gap"
    , trace := traceLowSpeedCloseGap
    , expected := true }
  , { name := "brief_close_gap_at_speed"
    , trace := traceBriefCloseGapAtSpeed
    , expected := true }
  , { name := "sustained_close_gap_at_speed"
    , trace := traceSustainedCloseGapAtSpeed
    , expected := false } ]

end TrafficSpec.Rules.Following.R0015
