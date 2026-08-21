/-
  Rule R0010 — entering an intersection against a steady red signal.

  Law text (EX-SIGNAL-001, "Steady red signal"):
    "A driver facing a steady red signal shall stop before the marked stop line
     and shall not enter the intersection until the signal turns green, unless
     already within the intersection when the signal changed."

  Scope — EX-SIGNAL-001 IS ONLY PARTLY COVERED BY THIS FILE
  --------------------------------------------------------
  This file formalizes ONE limb of the clause: "shall not enter the intersection
  until the signal turns green", together with its own exception, "unless
  already within the intersection when the signal changed".

  It does NOT formalize "shall stop before the marked stop line". There is no
  stop line anywhere in the abstraction — `carla/schema.json` →
  `unavailable.stop_line_and_junction_geometry`: no coordinates survive for
  structure nodes, so a painted line has no position to test a vehicle against.
  The approach-side reading of that limb ("stopped, on the approach, facing the
  red") is additionally blocked by the governance-edge fact recorded below, and
  would need a vocabulary/adapter extension to become checkable. A separate node
  is needed for it; this rule makes no claim about it either way.

  Why the formula is an ENTRY TRANSITION and not the obvious state formula
  -----------------------------------------------------------------------
  The obvious formalization of "shall not enter … while red" is

      □ ¬ₛ (facingRedSignal v ⋀ ¬ₛ inAnyJunction v ⋀ …)

  and it is **an empty conjunction on real data**. `Pred.facingRedSignal` and
  `Pred.governs` both reduce to the same `controls` edge, and `controls`
  (`controlsTrafficOf`, built from the light's affected waypoints) exists only
  once the vehicle is already *inside* the junction — see `Core/Vocab.lean` § 8
  and `carla/schema.json` → `relation_labels.notes.controls_is_the_only_governance_edge`.
  So "governed by a red light AND not yet in the junction" is never satisfied on
  a capture, and a rule of that shape reports **compliant on every red-light
  runner**. The deleted `Signal/R0004` was written that way.

  What is written here instead is a transition:

      □ ¬ₛ ( isEgo v ⋀ ¬ₛ (inJunction v j)
                     ⋀ ◯ .bounded redPersistFrames
                            (inJunction v j ⋀ signalRed d ⋀ governs d v) )

  read as: at this position the ego is outside junction `j`, and at the *next*
  position it is inside `j` with a light `d` governing the lane it now occupies
  showing red, and that state persists for `redPersistFrames` frames.

  Two things follow, and they are the whole reason for the shape:

  * `governs d v` and `signalRed d` are evaluated at the frames where the ego is
    **inside** the junction, which is exactly where the `controls` edge does
    exist. The antecedent is therefore satisfiable on a real capture. There is
    deliberately **no** `¬ₛ inAnyJunction v` conjunct on the governed side.

  * **The statutory exception comes for free.** A vehicle already within the
    intersection when the signal changed never produces an outside-to-inside
    transition on red anywhere in the trace, so nothing convicts it — no extra
    conjunct encodes the exception. Scenario
    `already_inside_when_signal_changed` is the discriminating case: the state
    formula "in the junction while facing red" convicts there, and this shape
    does not.

  Formalization choices the text did not dictate
  ---------------------------------------------
  * **"Enter the intersection" = the frame at which the ego's lane assignment
    flips from a lane outside `j` to a lane of `j`.** `Pred.inJunction` walks the
    graph's entity → lane → road → junction chain, so entry is quantised to
    lane-node granularity (`SGG(segment_length=1.0)`) and to the frame rate.

  * **`redPersistFrames := 4`.** The statute names no duration. This window is
    ours: it is there so that a single-frame lane-assignment or light-state
    artefact at the junction boundary is not a conviction. Its cost is stated as
    residue (3).

  * **"Steady red" is read as `light_state = "Red"`.** `"Yellow"`, `"Off"` and
    `"Unknown"` are all outside this rule; there is no separate flashing-red
    state in `str(carla.TrafficLightState)`.

  * **The signal and the junction are explicit binders rather than
    `Pred.facingRedSignal`.** `governs d v ⋀ signalRed d` performs exactly the
    same `controls` lookup that `facingRedSignal v` performs, so nothing is lost,
    and naming `d` makes the report's `GROUND` line say *which* signal was read —
    and makes a capture with no traffic light or no junction ground **zero**
    times, which the gate's vacuity check catches, instead of quietly reporting
    compliance.

  * **`isEgo v` is a data restriction, not a reading of the law.** The statute
    binds every driver. The obligation is gated on the ego because this
    specification speaks about the ego driver; the rule makes **no claim** about
    any other vehicle's red-light behaviour, in either direction. (Unlike a
    dynamics-based rule, the structural predicates here would in fact hold for a
    non-ego vehicle, so this gate genuinely narrows the rule rather than merely
    avoiding vacuity.)

  Residues
  --------
  (1) **The stop-line limb is not covered** (see Scope). A driver who rolls past
      the painted line and stops half inside the box on red is not convicted by
      this rule unless the map's lane assignment actually flips to a junction
      lane and stays flipped for `redPersistFrames`.

  (2) **Entry timing is quantised.** It is observed only at the frame the lane
      assignment flips, and a signal change is observed only if both adjacent
      frames were captured — 50 ms granularity at the 20 Hz reference rate, which
      no capture records (`carla/schema.json` →
      `capture_preconditions.capture_rate`).

  (3) **The four-frame persistence window lets a fast crossing escape.** A
      vehicle that crosses on red and is clear of the junction — or whose light
      leaves `"Red"` — again within 0.2 s produces no conviction. Symmetrically,
      per `Core/Formula.lean`, the last `redPersistFrames - 1` frames of any
      capture are a blind zone: a violating entry confined to them cannot be
      reported, because the window would overrun the trace and `loopBounded`
      reads that as false.

  (4) **The `controls` edge carries an unstated tolerance.** The generator's own
      test is `get_distance(...) < self.segment_length * 0.5`
      (`carla/schema.json` → `capture_preconditions.segment_length`), so which
      junction lanes a light is recorded as governing depends on a capture
      parameter this contract never states. If a real capture's light governs a
      *different* inner lane than the one the ego traverses, this rule grounds
      but its antecedent stays empty and it reports compliant. The scenarios
      below cannot detect that — they are hand-built and contain the edge this
      file puts in them. The first `run_spec monitor` on a capture containing a
      signalled junction must read the GROUND count for this rule; **zero
      groundings, or groundings with no engaged antecedent, means the rule is
      untested, not that the driving was lawful.**

  Span and trace length
  ---------------------
  `SFProp.frameSpan` of this formula is 5: the `.bounded 4` window contributes 4
  and the `◯` in front of it adds one. Every scenario trace is 16 frames, and the
  violating transition in `enters_on_red` sits at position 7 → 8 with eight
  further red-in-junction frames after it, well clear of the blind zone.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Signal.R0010

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- How many consecutive frames the "inside the junction, governed, red" state
    must persist for an entry to count as a violation. Ours, not the statute's —
    see residue (3). -/
def redPersistFrames : Nat := 4

/-- Quantified over vehicles, traffic lights and junctions; gated on the ego
    vehicle, the driver this specification speaks about. -/
def schema : PropertySchema where
  name    := "red_light_in_junction"
  binders := [vehicleBinder "v", trafficLightBinder "d", junctionBinder "j"]
  formula := fun env =>
    let v := arg env 0
    let d := arg env 1
    let j := arg env 2
    -- Inside junction `j`, under a red light governing the lane now occupied.
    -- Every conjunct is evaluated where the `controls` edge exists.
    let redInside := inJunction v j ⋀ signalRed d ⋀ governs d v
    -- The forbidden entry transition: outside `j` now, inside `j` on red at the
    -- next frame, and still so for `redPersistFrames` frames.
    □ (¬ₛ (isEgo v ⋀ ¬ₛ (inJunction v j)
                   ⋀ ◯ (SFProp.bounded redPersistFrames redInside)))

def entry : RuleEntry where
  nodeId  := "Signal/R0010_red_light_in_junction"
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

/-- Road structure shared by every trace: one lane inside a road inside the
    junction, one approach lane on an ordinary road that `travelsTo` it, and the
    traffic light. Only the junction road carries an `isIn` edge to the junction
    node, so `Pred.inJunction` is true exactly for a vehicle in `junctionLane`.

    The light's `.controls` edge goes to the **junction's inner lane only, never
    to the approach lane**. That mirrors the structure a real capture has (see
    the header): giving these traces an approach-side governance edge they will
    not have in the field would make them agree with a formalization that cannot
    ground. -/
private def structureEntities (state : String) : List Entity :=
  [ mkLane approachLane "Lane 7_-1",   mkRoad approachRoad "Road 7"
  , mkLane junctionLane "Lane 100_-1", mkRoad junctionRoad "Road 100"
  , mkJunction junctionId "Junction 5"
  , mkTrafficLight lightId "traffic_light_0" state ]

private def structureRels : List Relation :=
  [ mkRel approachLane .isIn approachRoad
  , mkRel junctionLane .isIn junctionRoad
  , mkRel junctionRoad .isIn junctionId
  , mkRel approachLane .travelsTo junctionLane
  , mkRel lightId      .controls  junctionLane ]

/-- One frame with the ego on the approach lane at `speed` m/s and the light
    showing `state`: approaching the junction, not yet in it, and — as on a real
    capture — *not* governed by the light, whose `controls` edge reaches the
    inner lane only. -/
private def approachFrame (state : String) (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: structureEntities state)
    (structureRels ++ [mkRel egoId .isIn approachLane])

/-- One frame with the ego in the junction's inner lane at `speed` m/s and the
    light showing `state` — the lane → road → junction chain `Pred.inJunction`
    walks, and the lane the light governs. -/
private def insideFrame (state : String) (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: structureEntities state)
    (structureRels ++ [mkRel egoId .isIn junctionLane])

/-- 16 frames. Positions 0–9: the ego waits at a standstill on the approach with
    the light red. Positions 10–15: the light is green and the ego is inside the
    junction, moving. The single entry transition (9 → 10) happens on green, so
    nothing is convicted. Lawful conduct. -/
def traceWaitsAtRedThenEntersOnGreen : Trace :=
  List.replicate 10 (approachFrame "Red" "0.000")
  ++ List.replicate 6 (insideFrame "Green" "5.000")

/-- 16 frames. Positions 0–5: the ego is already inside the junction's inner lane
    with the light green. Positions 6–15: still inside, the light now red.

    **The discriminating scenario.** This is the statute's own exception — the
    ego was already within the intersection when the signal changed — and there
    is no outside-to-inside transition anywhere in the trace. A rule written as
    the state formula "in the junction while facing red" convicts here; this
    trace is what forces the entry-transition shape. -/
def traceAlreadyInsideWhenSignalChanged : Trace :=
  List.replicate 6 (insideFrame "Green" "5.000")
  ++ List.replicate 10 (insideFrame "Red" "4.000")

/-- 16 frames. Positions 0–7 on the approach at 6.000 m/s with the light green,
    positions 8–15 inside the junction, still green. The minimal-pair partner of
    `enters_on_red`: identical but for the `light_state` string. -/
def traceEntersOnGreen : Trace :=
  List.replicate 8 (approachFrame "Green" "6.000")
  ++ List.replicate 8 (insideFrame "Green" "5.000")

/-- 16 frames. Positions 0–7 on the approach at 6.000 m/s with the light red,
    positions 8–15 inside the junction with the light still red and its
    `controls` edge to that inner lane present. The offending transition is
    7 → 8 and the red-in-junction state then holds for eight frames, so the
    four-frame persistence window closes well clear of the trace's end. -/
def traceEntersOnRed : Trace :=
  List.replicate 8 (approachFrame "Red" "6.000")
  ++ List.replicate 8 (insideFrame "Red" "5.000")

def scenarios : List Scenario :=
  [ { name := "waits_at_red_then_enters_on_green"
    , trace := traceWaitsAtRedThenEntersOnGreen
    , expected := true }
  , { name := "already_inside_when_signal_changed"
    , trace := traceAlreadyInsideWhenSignalChanged
    , expected := true }
  , { name := "enters_on_green"
    , trace := traceEntersOnGreen
    , expected := true }
  , { name := "enters_on_red"
    , trace := traceEntersOnRed
    , expected := false } ]

end TrafficSpec.Rules.Signal.R0010
