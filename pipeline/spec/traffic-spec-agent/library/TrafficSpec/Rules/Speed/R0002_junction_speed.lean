/-
  Rule R0002 — speed inside a junction.

  Law text (EX-SPEED-002, "Speed in a junction"):
    "A driver shall reduce speed to not more than thirty kilometres per hour
     while within an intersection."

  Formalization notes
  -------------------
  * **"reduce speed to not more than thirty" is read as a state bound, not as a
    duty to decelerate.** The obligation enforced is `speed ≤ 30 km/h at every
    frame the vehicle is inside the junction`, with no requirement that the
    speed ever went *down*. The deceleration reading is expressible — `accel` is
    an ego channel and `Pred.deceleratingAtLeast` exists — but it would convict
    a driver who approached the intersection already below thirty and simply
    held that speed through it, which the statute plainly permits. The cost of
    the reading taken here is the opposite: a driver who was already over thirty
    and never braked is convicted for the speed, not for the failure to reduce,
    so the "reduce" verb does no independent work.

  * **"not more than thirty" is read inclusively**, so exactly 30 km/h complies:
    the bound is `≤ 30`, via `Pred.speedLeKph v 30`.

  * **The enforced bound is 8333 milli-m/s, marginally stricter than 30 km/h.**
    `speedLeKph e kph` is `speedLe e (kph * 1000000 / 3600)` in `Nat` division,
    so 30 km/h truncates from 8333.33… to 8333 milli-m/s = 29.9988 km/h. 8.333
    m/s therefore complies and 8.334 m/s violates. That residue is a consequence
    of the integer milli-unit model, not a reading of the law.

  * **"within an intersection" can only mean lane occupancy.** `Pred.inJunction
    v j` walks the graph's `v --isIn--> lane --isIn--> road --isIn--> junction`
    chain, because `carla/schema.json` →
    `unavailable.stop_line_and_junction_geometry` records that no coordinates
    survive for structure nodes: a junction has no boundary to test a position
    against. A vehicle whose nose is physically inside the painted box while the
    map still maps it to the approach lane therefore reads as *outside*, and is
    not convicted by this rule. The residue is a slightly late start (and a
    slightly late end) to the regulated interval, bounded by the lane-node
    granularity of the abstraction (`SGG(segment_length=1.0)`).

  * **The junction is an explicit binder, not `Pred.inAnyJunction`.** Binding
    `j` with `junctionBinder` makes the grounding report name the intersection
    the verdict is about, and makes a capture that contains no junction node
    ground *zero* times — loudly vacuous, and caught by the gate's vacuity
    check — rather than quietly reporting compliance for a whole trace.

  * **The formula is gated on `Pred.isEgo v`, and that is a data restriction,
    not a reading of the law.** The statute binds every driver, but `speed`
    exists on the ego node only (`copy_carla_actor_state` is called for the ego
    alone; `carla/schema.json` → `unavailable.non_ego_dynamics`) and
    `Pred.attrMilli*` reads a missing attribute as `false`. Ungated, every other
    vehicle crossing the junction would be convicted for being unobservable.
    This rule makes no claim either way about a non-ego vehicle's speed — the
    same choice as `Speed/R0001_max_speed`.

  * **No persistence window.** "While within an intersection" names a state, not
    an event, so a single frame above the bound inside the junction is a
    violation: the formula is the plain state obligation
    `□ (isEgo v ⋀ inJunction v j ⟹ speedLeKph v 30)`. `SFProp.frameSpan` is
    therefore 1, no scenario trace has a minimum length, and the verdict cannot
    depend on how long the capture is.

  * **Scope.** The general fifty km/h limit is `Speed/R0001_max_speed`, an
    independent obligation that is not folded in here; both apply inside a
    junction, and thirty is the binding one there.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Speed.R0002

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- Quantified over vehicles and junctions; effective on the ego vehicle, the
    only one that carries a `speed` channel. -/
def schema : PropertySchema where
  name    := "junction_speed"
  binders := [vehicleBinder "v", junctionBinder "j"]
  formula := fun env =>
    let v := arg env 0
    let j := arg env 1
    □ (isEgo v ⋀ inJunction v j ⟹ speedLeKph v 30)

def entry : RuleEntry where
  nodeId  := "Speed/R0002_junction_speed"
  lawRefs := ["EX-SPEED-002"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

private def egoId        : Nat := 1
private def junctionLane : Nat := 10
private def approachLane : Nat := 11
private def junctionRoad : Nat := 20
private def approachRoad : Nat := 21
private def junctionId   : Nat := 30

/-- Road structure shared by every trace: one lane inside a road inside the
    junction, and one approach lane on an ordinary road that `travelsTo` it.
    The junction node is present in every frame of every trace, so `j` always
    binds and a scenario can never pass by having nothing to ground on. -/
private def structureEntities : List Entity :=
  [ mkLane junctionLane "Lane 100_-1", mkRoad junctionRoad "Road 100"
  , mkJunction junctionId "Junction 5"
  , mkLane approachLane "Lane 7_-1", mkRoad approachRoad "Road 7" ]

private def structureRels : List Relation :=
  [ mkRel junctionLane .isIn junctionRoad
  , mkRel junctionRoad .isIn junctionId
  , mkRel approachLane .isIn approachRoad
  , mkRel approachLane .travelsTo junctionLane ]

/-- One frame with the ego in the junction lane at `speed` m/s — the two-hop
    lane → road → junction chain that `Pred.inJunction` walks. -/
private def insideFrame (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: structureEntities)
    (structureRels ++ [mkRel egoId .isIn junctionLane])

/-- One frame with the ego in the approach lane at `speed` m/s. The junction is
    present and bindable, but `inJunction` is false: `approachRoad` carries no
    `isIn` edge to it. -/
private def approachFrame (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: structureEntities)
    (structureRels ++ [mkRel egoId .isIn approachLane])

/-- 7.000 m/s = 25.2 km/h, comfortably inside the bound, six frames. -/
def traceSlowThroughJunction : Trace :=
  [ insideFrame "7.000", insideFrame "7.000", insideFrame "7.000"
  , insideFrame "7.000", insideFrame "7.000", insideFrame "7.000" ]

/-- 8.300 m/s = 29.88 km/h — 8300 ≤ 8333, just inside the bound. The minimal-
    pair partner of `just_over_thirty_in_junction`: together they pin down where
    the km/h → milli-m/s conversion actually puts the threshold. -/
def traceJustUnderThirtyInJunction : Trace :=
  [ insideFrame "8.300", insideFrame "8.300", insideFrame "8.300"
  , insideFrame "8.300" ]

/-- Three frames on the approach at 13.000 m/s (46.8 km/h) — over thirty, but
    outside the intersection, so this rule says nothing about it — then three
    frames inside at 8.000 m/s. Drop the `inJunction` antecedent and this
    scenario reports a violation. (The approach speed is a matter for
    `Speed/R0001_max_speed`, which it also satisfies.) -/
def traceFastOnApproachIsNotAViolation : Trace :=
  [ approachFrame "13.000", approachFrame "13.000", approachFrame "13.000"
  , insideFrame "8.000", insideFrame "8.000", insideFrame "8.000" ]

/-- 8.400 m/s = 30.24 km/h — 8400 > 8333, just over the bound, on every frame. -/
def traceJustOverThirtyInJunction : Trace :=
  [ insideFrame "8.400", insideFrame "8.400", insideFrame "8.400"
  , insideFrame "8.400" ]

/-- 11.000 m/s (39.6 km/h) held from the approach right through the junction:
    the driver never reduced speed. The first two frames are lawful here; the
    last three are the violation. -/
def traceSpeedingInsideJunction : Trace :=
  [ approachFrame "11.000", approachFrame "11.000"
  , insideFrame "11.000", insideFrame "11.000", insideFrame "11.000" ]

def scenarios : List Scenario :=
  [ { name := "slow_through_junction"
    , trace := traceSlowThroughJunction
    , expected := true }
  , { name := "just_under_thirty_in_junction"
    , trace := traceJustUnderThirtyInJunction
    , expected := true }
  , { name := "fast_on_approach_is_not_a_violation"
    , trace := traceFastOnApproachIsNotAViolation
    , expected := true }
  , { name := "just_over_thirty_in_junction"
    , trace := traceJustOverThirtyInJunction
    , expected := false }
  , { name := "speeding_inside_junction"
    , trace := traceSpeedingInsideJunction
    , expected := false } ]

end TrafficSpec.Rules.Speed.R0002
