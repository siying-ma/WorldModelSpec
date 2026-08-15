/-
  Rule R0004 — entry into an intersection against a steady red signal.

  Law text (laws/example/laws.jsonl, id EX-SIGNAL-001, "Steady red signal"):
    "A driver facing a steady red signal shall stop before the marked stop line
     and shall not enter the intersection until the signal turns green, unless
     already within the intersection when the signal changed."

  Formalization notes
  -------------------
  * **"Stop before the marked stop line" is not formalized as a position test,
    and this is the largest residue in the rule.** The abstraction keeps no
    coordinates for structure nodes, so there is no stop line, no give-way line
    and no junction boundary to compare a position against
    (`carla/schema.json` → `not_available.stop_line_and_junction_geometry`).
    The clause therefore degrades to its second, observable half: *do not enter
    the junction*. A driver who overruns the painted line but stops short of the
    junction lane is compliant under this formalization and would not be under
    the statute. That is a weakening, and it is recorded here rather than hidden:
    closing it needs junction/stop-line geometry in the adapter, not a different
    formula.
  * **"Enter the intersection" is the *transition* into junction lane
    occupancy**, i.e. `¬ₛ inAnyJunction v` now and `inAnyJunction v` at the next
    frame. Occupancy itself (`inAnyJunction v`) is deliberately *not* the
    forbidden state: the statutory exception says a vehicle already inside may
    clear the junction, so being inside on red is lawful whenever the entry was
    lawful. Only the crossing of the boundary is policed.
  * **The exception needs no past operator, and none is used.** The formula is
    purely future:
    `□ ((facing red ⋀ outside) ⟹ ¬ next inside)`.
    A vehicle that was already inside when the signal changed is never at a
    position satisfying "facing red **and** outside the junction", so its
    obligation is discharged vacuously at every frame —
    `already_inside_when_signal_changed` is the regression test for exactly this.
    Encoding the exception as an explicit past-time carve-out would have needed
    an operator the formula language does not have; it is unnecessary.
  * **"Until the signal turns green" is read as "while it is red", not as
    "until green specifically".** The antecedent is `signalRed d`, so amber, Off
    and Unknown are outside this clause. Entering on amber is a different
    obligation (a different clause of the code) and entering on Off or Unknown
    is not something this rule should accuse a driver of; both are left to
    other nodes rather than folded in here by reading `¬ green` for `red`.
  * **"Steady" is not distinguished from flashing.** `light_state` is
    `str(carla.TrafficLightState)` and has no flashing value, so a steady red
    and a hypothetical flashing red are indistinguishable in the data. Every red
    is treated as steady.
  * **"The signal facing me" is the `.controls` edge**, via
    `Pred.governs d v`: the light governs a lane the vehicle occupies. This is
    the only sound association available. The generator emits no proximity or
    angular edge to any signal, and a signal's `isIn` edge is bounding-box
    overlap — equally true of the head facing the cross street. The residue is
    that the abstraction drops `carla_parent_id`
    (`carla/schema.json` → `partially_available.traffic_light_grouping`), so if
    two heads of one junction both `controls` the ego's lane they are separate,
    interchangeable bindings; the rule is checked against each, which is
    conservative in the right direction.
  * **The signal is a bound entity (`trafficLightBinder "d"`), not hidden behind
    `Pred.facingRedSignal`.** Naming it makes the grounding report say *which*
    signal the obligation was checked against, and makes a trace with no traffic
    light node ground zero times — loudly vacuous — instead of passing silently.
  * **Colour is read with `Pred.signalRed`, never `attrEq` on a raw string**, so
    the spelling of the `light_state` enum lives in `Core/Vocab.lean` alone.
  * **The formula is gated on `Pred.isEgo v`.** This is a data restriction, not
    a reading of the law, which binds every driver. Junction occupancy is
    readable for any actor, so an ungated rule would not be *vacuous* — it would
    be *wrong*: the abstraction gives no reliable evidence of which head of a
    junction's signal group faces a non-ego vehicle, and a cross-traffic car
    entering on its own green would be accused of running the ego's red. The
    monitored driver is also the only one the exception can be checked for.
  * **The obligation is per frame, with no grace window.** A single unlawful
    entry anywhere in the trace fails the rule; there is no "already committed"
    allowance for a driver who could not stop in time. The statute states none,
    and the abstraction carries no braking-distance information that would let
    one be justified.
  * **No timing assumption is made.** The rule uses only `◯`, so it is
    insensitive to the capture rate; the 20 Hz reference rate matters only in
    that a signal change occurring between two captured frames is unobservable
    (`carla/schema.json` → `partially_available.signal_change_event`).
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Signal.R0004

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The rule, quantified over (vehicle, traffic light) pairs, effective on the
    ego vehicle. Read: whenever the ego is outside every junction and the signal
    governing its lane is red, it must not be inside a junction at the next
    frame. -/
def schema : PropertySchema where
  name    := "red_light_entry"
  binders := [vehicleBinder "v", trafficLightBinder "d"]
  formula := fun env =>
    let v := arg env 0
    let d := arg env 1
    □ ((isEgo v ⋀ governs d v ⋀ signalRed d ⋀ ¬ₛ inAnyJunction v)
        ⟹ ¬ₛ ◯ (inAnyJunction v))

def entry : RuleEntry where
  nodeId  := "Signal/R0004_red_light_entry"
  lawRefs := ["EX-SIGNAL-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- Road structure shared by every trace, matching the shape of the bundled
-- CARLA sample: an approach road and an exit road that are plain roads, plus
-- one road that `isIn` Junction 5, so only the junction lane satisfies
-- `inAnyJunction`. `travelsTo` wires approach → junction → exit.
--
-- The signal `controls` both the approach lane and the junction lane, as the
-- generator's `controlsTrafficOf` does for a light whose affected waypoints run
-- through the intersection. That makes `governs d v` true both before and after
-- entry, so the scenarios discriminate on the junction-occupancy conjunct and
-- not on an accidental loss of governance.
----------------------------------------------------------------------

private def ego          : Nat := 1
private def signal       : Nat := 2
private def approachLane : Nat := 10
private def junctionLane : Nat := 11
private def exitLane     : Nat := 12
private def approachRoad : Nat := 20
private def junctionRoad : Nat := 21
private def exitRoad     : Nat := 22
private def junction     : Nat := 30

private def structureEntities : List Entity :=
  [ mkLane approachLane "Lane 7_-1"
  , mkLane junctionLane "Lane 8_-1"
  , mkLane exitLane     "Lane 9_-1"
  , mkRoad approachRoad "Road 7"
  , mkRoad junctionRoad "Road 8"
  , mkRoad exitRoad     "Road 9"
  , mkJunction junction "Junction 5" ]

private def structureRels : List Relation :=
  [ mkRel approachLane .isIn approachRoad
  , mkRel junctionLane .isIn junctionRoad
  , mkRel exitLane     .isIn exitRoad
  , mkRel junctionRoad .isIn junction
  , mkRel approachLane .travelsTo junctionLane
  , mkRel junctionLane .travelsTo exitLane
  , mkRel signal .controls approachLane
  , mkRel signal .controls junctionLane ]

/-- One frame: ego (id 1) occupying `lane` at `speed` m/s, with the junction's
    traffic light (id 2) showing `state`. `atLight` is CARLA's
    `is_at_traffic_light()`, set while the ego is on the approach — it is not
    read by this rule, but a hand-written trace should carry the channels a
    captured one carries. -/
private def sceneAt (lane : Nat) (state : String) (speed : String)
    (accel : String := "0.0") (throttle : String := "0.0")
    (brake : String := "0.0") (atLight : String := "true") : Scene :=
  frame
    ([ mkEgo ego .car speed accel throttle brake "0.0" "0.0" atLight
     , mkTrafficLight signal "traffic_light_0" state ] ++ structureEntities)
    (structureRels ++ [mkRel ego .isIn lane])

/-- Six frames on the approach lane with the governing signal red throughout;
    the ego decelerates from 8 m/s to a standstill and never occupies the
    junction lane. The antecedent fires in every frame and the entry never
    happens, so the obligation is discharged each time. Compliant. -/
def traceStopsAtRed : Trace :=
  [ sceneAt approachLane "Red" "8.0" "-3.0" "0.0" "0.3"
  , sceneAt approachLane "Red" "5.0" "-3.0" "0.0" "0.5"
  , sceneAt approachLane "Red" "2.5" "-3.0" "0.0" "0.7"
  , sceneAt approachLane "Red" "0.5" "-2.0" "0.0" "0.9"
  , sceneAt approachLane "Red" "0.0" "0.0"  "0.0" "1.0"
  , sceneAt approachLane "Red" "0.0" "0.0"  "0.0" "1.0" ]

/-- The ego waits out the red and enters after the change. Frames 1–2: red,
    stopped on the approach, outside the junction — the antecedent fires and the
    next frame is still outside, so it is discharged. Frame 3: the signal turns
    green, so the antecedent is false and the entry at frame 4 is unpoliced by
    this clause. Frames 4–6: inside the junction on green. Compliant. -/
def traceWaitsThenProceedsOnGreen : Trace :=
  [ sceneAt approachLane "Red"   "0.0" "0.0" "0.0" "1.0"
  , sceneAt approachLane "Red"   "0.0" "0.0" "0.0" "1.0"
  , sceneAt approachLane "Green" "0.0" "1.5" "0.4" "0.0"
  , sceneAt junctionLane "Green" "3.0" "2.0" "0.5" "0.0"
  , sceneAt junctionLane "Green" "5.0" "2.0" "0.5" "0.0"
  , sceneAt junctionLane "Green" "6.5" "1.5" "0.5" "0.0" ]

/-- The statutory exception. Frames 1–2: the ego is already inside the junction
    on green. Frames 3–6: the same signal shows red while the ego is still
    inside and then clears into the exit lane. It is never at a position that
    is both facing red and outside the junction, so the obligation is discharged
    vacuously at every frame and no violation is reported. This is the scenario
    that would fail if "inside the junction on red" were the forbidden state
    instead of the transition into it. -/
def traceAlreadyInsideWhenSignalChanged : Trace :=
  [ sceneAt junctionLane "Green" "6.0" "0.0" "0.4" "0.0"
  , sceneAt junctionLane "Green" "6.0" "0.0" "0.4" "0.0"
  , sceneAt junctionLane "Red"   "6.0" "0.0" "0.4" "0.0" "false"
  , sceneAt junctionLane "Red"   "6.0" "0.0" "0.4" "0.0" "false"
  , sceneAt junctionLane "Red"   "6.5" "0.5" "0.4" "0.0" "false"
  , sceneAt exitLane     "Red"   "7.0" "0.5" "0.4" "0.0" "false" ]

/-- The violation. The signal is red for all six frames. Frames 1–3: the ego is
    moving on the approach lane, outside the junction. Frames 4–6: it occupies
    the junction lane. At frame 3 the antecedent holds and the ego is inside at
    frame 4, so the entry is unlawful. Violated. -/
def traceEntersOnRed : Trace :=
  [ sceneAt approachLane "Red" "6.0" "0.0" "0.4" "0.0"
  , sceneAt approachLane "Red" "5.5" "-0.5" "0.3" "0.0"
  , sceneAt approachLane "Red" "5.0" "-0.5" "0.3" "0.0"
  , sceneAt junctionLane "Red" "5.0" "0.0" "0.3" "0.0" "false"
  , sceneAt junctionLane "Red" "5.0" "0.0" "0.3" "0.0" "false"
  , sceneAt junctionLane "Red" "5.0" "0.0" "0.3" "0.0" "false" ]

def scenarios : List Scenario :=
  [ { name := "stops_at_red",                      trace := traceStopsAtRed,                      expected := true }
  , { name := "waits_then_proceeds_on_green",      trace := traceWaitsThenProceedsOnGreen,        expected := true }
  , { name := "already_inside_when_signal_changed", trace := traceAlreadyInsideWhenSignalChanged, expected := true }
  , { name := "enters_on_red",                     trace := traceEntersOnRed,                     expected := false } ]

end TrafficSpec.Rules.Signal.R0004
