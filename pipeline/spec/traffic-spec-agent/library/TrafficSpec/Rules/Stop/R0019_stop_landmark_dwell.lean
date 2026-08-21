/-
  Rule R0019 — the complete stop at a stop sign, grounded through the MAP's own
  stop record rather than through a stop-sign actor's trigger volume.

  Law text (EX-STOP-001, "Complete stop"):
    "A driver approaching a stop sign shall bring the vehicle to a complete stop
     before entering the intersection, and shall remain stopped for not less
     than one second."

  Why this file exists alongside `Stop/R0007_stop_sign_dwell`
  ----------------------------------------------------------
  Both rules formalize the same limb of the same clause, and that duplication is
  deliberate insurance, not an oversight. R0007's own residue (4) records that
  its entire antecedent rests on an UNVERIFIED bet: that a stop-sign actor's
  `controls` edge — built from the sign's trigger volume, with the undocumented
  tolerance `get_distance(...) < self.segment_length * 0.5` in the generator —
  reaches a vehicle that is still *outside* the junction. That is the same shape
  which made the earlier `Signal/R0004` unsatisfiable, and R0007 states in as
  many words that a grounding count of zero on a real capture would mean the
  rule is worthless rather than the driving lawful. The bundled sceneflow capture
  cannot settle it: its junction is signal-controlled, so no stop sign appears.

  If that bet fails, EX-STOP-001 is measured by nothing. This rule reaches the
  same conduct through independent evidence: the OpenDRIVE **landmark** node
  (`landmark_type == "206"`, a stop) and the **`mayAffect`** edge, which
  `carla/schema.json` calls the authoritative source for posted restrictions and
  which the map author — not a runtime trigger volume — attaches to the approach
  lane. Whichever of the two routes grounds on real data carries the law; see
  residue (6) for the experiment that decides.

  Formalization notes
  -------------------
  * **The construction mirrors R0007 exactly so the two can be diffed.** Only
    the antecedent's governance conjuncts differ:

      R0007:  isEgo v ⋀ governs s v            ⋀ approachingJunction v j ⋀ ¬ₛ inAnyJunction v
      R0019:  isEgo v ⋀ landmarkApplies lm v ⋀ landmarkType lm "206"
                                                ⋀ approachingJunction v j ⋀ ¬ₛ inAnyJunction v

    Everything downstream — the dwell, the until, and where the obligation is
    discharged — is character-for-character the same reading.

  * **`governs` / `facingStopSign` are deliberately NOT used here.** They perform
    the same `controls`-edge lookup as each other and as R0007, so reusing either
    would reproduce R0007's risk instead of insuring against it. A landmark's
    `isIn` edge is likewise not used: for a sign, `isIn` is bounding-box overlap,
    not governance. `mayAffect` is the only landmark governance edge.

  * **The obligation is attached to the ONSET of the governed approach, not to
    every frame of it.** This is R0007's correction, and it applies here for the
    same structural reason. `.bounded 20 φ` holds at a position only if a *fresh*
    twenty-frame window of φ starts there, so in a trace where the ego stands
    still over positions 5–27 the dwell is true only at positions 5–8. A `□` over
    the approach would re-ask the obligation at position 9 — in the middle of the
    driver's own stop — and at positions 28–34, after it; from any of those the
    future contains no *new* complete dwell before the junction, the inner until
    succeeds, and a compliant driver is convicted. A future-only formula
    evaluated at position 9 cannot distinguish "stopped since 5, nineteen frames
    of standstill still to come" from "stopped at 9 and then went", because the
    difference lies entirely in the past and this fragment has no past operators.

    What is written instead states the obligation once per approach:

      (approach ⟹ obligation) ⋀ □ ((¬ₛ approach ⋀ ◯ approach) ⟹ ◯ obligation)

    The first conjunct covers a capture that already begins on the governed
    approach; the box covers every later frame at which the ego *enters* one,
    which is the past-free way to say "the first frame of an approach" — a
    position whose predecessor is not an approach frame.

  * **The obligation itself.** `obligation := ¬ₛ ((¬ₛ dwell) 𝒰 inJunction v j)`:
    it must not happen that the ego reaches junction `j` without a complete
    one-second standstill having *begun* somewhere on the way. The until must sit
    under the negation, and `Core/Semantics.lean::loopUntil` is why — it is a
    strong until, false when its right arm never comes true, so a driver still on
    the approach when the trace ends is reported compliant rather than convicted
    for an entry that never happened.

  * **The dwell is `.bounded 20 (stopped v ⋀ ¬ₛ inAnyJunction v)`.** The second
    conjunct stops the acquitting window from straddling the junction entry: five
    frames stopped on the approach and fifteen stopped inside the box would
    otherwise satisfy a bare `.bounded 20 (stopped v)` evaluated just before
    entry, and the statute requires the second of standstill *before* entering.
    It can only remove ways to be acquitted, never add one.

  Residues
  --------
  (1) **`mayAffect` carries no position, so the duty attaches anywhere along the
      affected lane node.** It is a map-authored lane association: the landmark
      applies to the whole lane node, with nothing to say how far up it the sign
      stands. That is tolerable *only because the obligation bites solely on
      entering the junction* — and it is the reason this formula is an until over
      the approach rather than a state bound on any single frame. A state-bound
      reading ("be stopped while the landmark applies") would convict every
      driver who is merely travelling along an affected lane, hundreds of metres
      from the sign.

  (2) **A landmark's absence is not evidence there is no stop sign, and its
      presence cannot be narrowed to some lanes.** A landmark reaches the graph
      only within the capture's render distance of a driving node
      (`generate_graph_for_frame(render_dist=50)`; `carla/schema.json` →
      `capture_preconditions.render_distance`), so a stop sign further away
      simply is not there. In the other direction,
      `landmark_lane_validities` is in the capture but not lifted into Lean
      (`carla/schema.json` → `partially_lifted.landmark_geometry_and_validity`),
      so a landmark that legally applies to only some lanes of a road cannot be
      restricted to them here: this rule will read it as applying to every lane
      the `mayAffect` edges reach.

  (3) **The dwell is a frame count, not a duration.** `dwellFrames :=
      TrafficSpec.secondsToFrames 1` is 20 frames, and 20 frames is one second
      only if the capture ran at 20 Hz. No capture records its own rate — frames
      carry no timestamp by construction (`carla/schema.json` →
      `capture_preconditions.capture_rate`, `unavailable.timestamps`) — so this
      is unverifiable from the data. At 40 Hz this rule accepts a half-second
      stop, which is exactly the conduct scenario `rolling_stop_of_half_a_second`
      below convicts.

  (4) **Ego only.** The statute binds every driver, but `speed` exists on the ego
      node alone (`copy_carla_actor_state` is called for the ego only;
      `carla/schema.json` → `unavailable.non_ego_dynamics`), so `Pred.stopped` is
      false at every frame for any other vehicle and every one of them would read
      as never having stopped at all. The `isEgo v` conjunct is a data
      restriction, not a reading of the law: ungated, this rule would convict
      every non-ego vehicle crossing a stop-controlled junction. It makes no
      claim either way about them.

  (5) **Deliberate overlap with R0007.** On a capture where both ground, a single
      rolling stop is reported as a violation by both rules.
      `scripts/capture_eval.py` aggregates a law as violated if any covering rule
      convicts, so the double report does not double-count the law; it does mean
      the two counts in a monitor report are not independent samples of driving,
      only of grounding.

  (6) **UNVALIDATED against real data, and the validation is a comparison.** No
      capture has yet exercised this rule. On the first capture that contains a
      stop sign, read this rule's GROUND count *next to R0007's*: that pair of
      counts is the experiment which settles whether the map-authored `mayAffect`
      route or the trigger-volume `controls` route survives the abstraction. A
      zero here means the landmark route is empty and this rule is worthless — it
      does not mean the driving was lawful.

  (7) **The catalogue is not checked.** `"206"` is an OpenDRIVE type code and the
      codes are only meaningful within a sign catalogue
      (`Pred.landmarkCountry`'s docstring). This rule reads `landmark_type`
      without pinning `landmark_country`, because the shipped towns report
      `"OpenDRIVE"` while other maps report a national catalogue such as
      `"DEU"` — pinning either would make the rule silently vacuous on the other.
      A map whose catalogue reuses `206` for something that is not a stop would
      be misread.

  (8) **"A complete stop" is ≤ 0.1 m/s, not zero** — `Pred.stopped` is
      `speedLe e 100` in milli-units. A vehicle creeping at 0.09 m/s for a second
      is credited with a complete stop. And "before entering the intersection"
      has no stop line to refer to
      (`carla/schema.json` → `unavailable.stop_line_and_junction_geometry`), so it
      degrades to "while occupying a lane that `travelsTo` a lane of the
      junction, and not yet occupying a lane of the junction", at the lane-node
      granularity of `SGG(segment_length=1.0)`.

  * **Span and trace length.** `SFProp.frameSpan` of this formula is 21 — the
    `.bounded 20` window contributes 20 and the `◯` before the onset obligation
    adds one. Every scenario trace below is 60 frames, and each violation begins
    early, well clear of the trailing 20-frame blind zone in which a dwell window
    would overrun the trace and `Core/Semantics.lean::loopBounded` would read it
    as false.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Stop.R0019

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- One second of standstill as a frame count: 20 frames at the 20 Hz reference
    capture rate. See residue (3) — no capture records its own rate. -/
def dwellFrames : Nat := TrafficSpec.secondsToFrames 1

/-- Quantified over vehicles, OpenDRIVE landmarks and junctions; effective on
    the ego vehicle, the only one carrying a `speed` channel. -/
def schema : PropertySchema where
  name    := "stop_landmark_dwell"
  binders := [vehicleBinder "v", landmarkBinder "lm", junctionBinder "j"]
  formula := fun env =>
    let v  := arg env 0
    let lm := arg env 1
    let j  := arg env 2
    -- The governed approach: the ego, on a lane the map's own stop record
    -- affects, where that lane leads into junction `j`, and not yet inside any
    -- junction. `mayAffect` (via `landmarkApplies`) is the landmark's only
    -- governance edge — see the header on why `governs` is not used here.
    let approach :=
      isEgo v ⋀ landmarkApplies lm v ⋀ landmarkType lm "206"
        ⋀ approachingJunction v j ⋀ ¬ₛ (inAnyJunction v)
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
  nodeId  := "Stop/R0019_stop_landmark_dwell"
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
private def landmarkId   : Nat := 50

/-- Road structure shared by every trace: one lane inside a road inside the
    junction, and one approach lane on an ordinary road that `travelsTo` it.
    Only the junction road carries an `isIn` edge to the junction node, so
    `Pred.inJunction` is true exactly for a vehicle in `junctionLane` and
    `Pred.approachingJunction` exactly for one in `approachLane`. -/
private def structureEntities : List Entity :=
  [ mkLane approachLane "Lane 7_-1",   mkRoad approachRoad "Road 7"
  , mkLane junctionLane "Lane 100_-1", mkRoad junctionRoad "Road 100"
  , mkJunction junctionId "Junction 5" ]

private def structureRels : List Relation :=
  [ mkRel approachLane .isIn approachRoad
  , mkRel junctionLane .isIn junctionRoad
  , mkRel junctionRoad .isIn junctionId
  , mkRel approachLane .travelsTo junctionLane ]

/-- The map's stop record: OpenDRIVE type `206`, attached to the **approach**
    lane by `mayAffect`. This is the structure the rule is betting on, and the
    scenarios below are not evidence that a real capture contains it — see
    residue (6). -/
private def stopLandmark : Entity :=
  mkLandmark landmarkId "Landmark DEU 206 -1" "206"
    (country := "DEU")

/-- A posted speed limit, OpenDRIVE type `274`, on the same lane and by the same
    edge. Used by the negative-control scenario: the governance edge is present
    and identical, only the type code differs. -/
private def speedLimitLandmark : Entity :=
  mkLandmark landmarkId "Landmark DEU 274 50" "274"
    (value := "50") (unit := "km/h") (country := "DEU")

private def landmarkRels : List Relation :=
  [ mkRel landmarkId .mayAffect approachLane ]

/-- One frame with the ego on the approach lane at `speed` m/s, governed by
    landmark `lm`: the landmark applies to the lane it occupies, that lane leads
    into the junction, and the ego is not yet inside it. -/
private def approachFrame (lm : Entity) (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: lm :: structureEntities)
    (structureRels ++ landmarkRels ++ [mkRel egoId .isIn approachLane])

/-- One frame with the ego in the junction's inner lane at `speed` m/s — the
    two-hop lane → road → junction chain `Pred.inJunction` walks. The landmark
    does not affect this lane, so the approach antecedent is false here, but the
    landmark node itself stays present so `lm` binds in every frame. -/
private def insideFrame (lm : Entity) (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: lm :: structureEntities)
    (structureRels ++ landmarkRels ++ [mkRel egoId .isIn junctionLane])

/-- 60 frames. Positions 0–4: decelerating on the approach, 5.000 → 1.000 m/s.
    Positions 5–27: standstill at 0.000 m/s — 23 consecutive frames, three more
    than the 20-frame dwell. Positions 28–34: accelerating away, still on the
    approach. Positions 35–59: inside the junction.

    **This is the discriminating scenario for where the obligation is
    discharged.** Positions 9–27 and 28–34 are approach frames from which no
    *fresh* twenty-frame standstill is still to come, so re-asking the obligation
    at every approach frame — the shape this file's header rejects — convicts
    this compliant driver. -/
def traceStopsOneSecondThenEnters : Trace :=
  [ approachFrame stopLandmark "5.000", approachFrame stopLandmark "4.000"
  , approachFrame stopLandmark "3.000", approachFrame stopLandmark "2.000"
  , approachFrame stopLandmark "1.000" ]
  ++ List.replicate 23 (approachFrame stopLandmark "0.000")
  ++ [ approachFrame stopLandmark "1.000", approachFrame stopLandmark "2.000"
     , approachFrame stopLandmark "3.000", approachFrame stopLandmark "4.000"
     , approachFrame stopLandmark "5.000", approachFrame stopLandmark "6.000"
     , approachFrame stopLandmark "7.000" ]
  ++ List.replicate 25 (insideFrame stopLandmark "7.000")

/-- 60 frames. Positions 0–24 on the affected approach at 4.000 m/s — the ego
    never slows below 4 m/s anywhere — and positions 25–59 inside the junction.
    It entered with no complete dwell anywhere on the approach. The entry sits
    early, so the verdict is nowhere near the trailing 20-frame blind zone. -/
def traceEntersWithoutStopping : Trace :=
  List.replicate 25 (approachFrame stopLandmark "4.000")
  ++ List.replicate 35 (insideFrame stopLandmark "4.000")

/-- 60 frames. Positions 0–7 on the approach at 4.000 m/s, positions 8–17 at a
    genuine standstill of 0.000 m/s but for only ten frames, positions 18–29
    accelerating on the approach, entry at position 30.

    **This is the discriminating scenario for the dwell length.** Half a second
    is not the one second the statute requires; set `dwellFrames` to 10 and this
    wrongly passes. It is also the concrete form of residue (3): at a 40 Hz
    capture rate these same ten frames *would* be a quarter of a second and the
    twenty-frame window would be half a second, so the rule's threshold is only
    as good as the assumed rate. -/
def traceRollingStopOfHalfASecond : Trace :=
  List.replicate 8 (approachFrame stopLandmark "4.000")
  ++ List.replicate 10 (approachFrame stopLandmark "0.000")
  ++ [ approachFrame stopLandmark "1.000", approachFrame stopLandmark "2.000"
     , approachFrame stopLandmark "3.000", approachFrame stopLandmark "4.000"
     , approachFrame stopLandmark "4.500", approachFrame stopLandmark "5.000"
     , approachFrame stopLandmark "5.500", approachFrame stopLandmark "6.000"
     , approachFrame stopLandmark "6.500", approachFrame stopLandmark "7.000"
     , approachFrame stopLandmark "7.500", approachFrame stopLandmark "8.000" ]
  ++ List.replicate 30 (insideFrame stopLandmark "8.000")

/-- 60 frames with the **same governance edge** but a posted speed limit instead
    of a stop: `Landmark DEU 274 50` `mayAffect`s the approach lane and no `206`
    landmark exists anywhere. The ego never stops (4.000 m/s throughout) and
    enters the junction at position 25.

    Must be compliant: no stop duty exists on this approach. **This is the
    discriminating scenario for the `landmarkType lm "206"` check** — drop that
    conjunct and every posted sign becomes a stop sign, since `mayAffect` says
    only that *some* restriction applies to the lane. The landmark is still
    present in every frame, so `lm` binds and the scenario is not passing by
    grounding zero times. -/
def traceSpeedLimitLandmarkIsNotAStop : Trace :=
  List.replicate 25 (approachFrame speedLimitLandmark "4.000")
  ++ List.replicate 35 (insideFrame speedLimitLandmark "4.000")

def scenarios : List Scenario :=
  [ { name := "stops_one_second_then_enters"
    , trace := traceStopsOneSecondThenEnters
    , expected := true }
  , { name := "enters_without_stopping"
    , trace := traceEntersWithoutStopping
    , expected := false }
  , { name := "rolling_stop_of_half_a_second"
    , trace := traceRollingStopOfHalfASecond
    , expected := false }
  , { name := "speed_limit_landmark_is_not_a_stop"
    , trace := traceSpeedLimitLandmarkIsNotAStop
    , expected := true } ]

end TrafficSpec.Rules.Stop.R0019
