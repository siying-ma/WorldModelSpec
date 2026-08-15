/-
  Rule R0002 — speed in a junction.

  Law text (laws/example/laws.jsonl, id EX-SPEED-002):
    "A driver shall reduce speed to not more than thirty kilometres per hour
     while within an intersection."

  Formalization notes
  -------------------
  * **"reduce speed to not more than thirty" is read as a state obligation, not
    as a duty to decelerate.** The formula is `□ (inside ⟹ speed ≤ 30 km/h)`,
    with no conjunct requiring `accel < 0` on the approach. The abstraction does
    carry `accel` for the ego vehicle, so the deceleration reading is
    expressible; it is rejected because the operative legal content is the
    bound, and a driver who was already below thirty on the approach has nothing
    to reduce — an `accel`-requiring formula would convict them. A reviewer who
    disagrees should look here first: this is the one choice in the file that
    changes which traces are violations.
  * **"within an intersection" is `Pred.inJunction v j`**, the graph's
    entity → lane → road → junction `isIn` walk. There is no stop-line or
    junction-boundary geometry in the abstraction
    (`carla/schema.json` → `unavailable.stop_line_and_junction_geometry`: no
    coordinates survive for structure nodes), so "within" can only mean
    *occupancy of a lane whose road is in the junction*. A vehicle physically
    inside the painted box but still mapped to an approach lane reads as outside
    the rule, and one whose lane assignment has flipped reads as inside even if
    its bumper is still short of the line. That residue is unremovable with the
    present data.
  * **The junction is a bound entity, not existentially hidden.** The schema
    quantifies `junctionBinder "j"` and uses `inJunction v j` rather than
    `Pred.inAnyJunction v`, so the grounding report names which intersection the
    obligation was checked against, and a trace containing no junction node
    grounds zero times — loudly vacuous — instead of passing silently. The cost
    is one grounding per (vehicle, junction) pair; for a pair where ego is not
    inside *that* junction the antecedent is false and the obligation is
    discharged vacuously, which is the intended reading: the clause speaks only
    about the intersection you are actually in.
  * **Thirty km/h is `Pred.speedLeKph v 30`**, i.e. `30 * 1000000 / 3600 = 8333`
    milli-m/s after truncation. So 8.333 m/s (29.9988 km/h) is the greatest
    permitted speed and 8.334 m/s is already a violation: the truncation makes
    the bound about 0.1 mm/s *stricter* than exactly thirty km/h. Recorded so a
    reviewer sees it rather than discovers it.
    `just_under_thirty_in_junction` / `just_over_thirty_in_junction` are the
    minimal pair straddling that boundary (8300 ≤ 8333 < 8400).
  * **"not more than" is non-strict**: travelling at exactly the bound complies,
    so the obligation is `≤`, not `<`.
  * **No entry or exit grace window.** "while within an intersection" names a
    state, not an event, so the formalization is `□ (antecedent ⟹ bound)` with no
    `.bounded` persistence window. One frame inside the junction above the bound
    is a violation.
  * **The obligation is gated on `Pred.isEgo v`. This is a data restriction, not
    a reading of the law.** The statute binds every driver, but `speed` is copied
    into the graph for the ego node alone (`copy_carla_actor_state`;
    `carla/schema.json` → `unavailable.non_ego_dynamics`) and `Pred.attrMilli*`
    reads a missing attribute as `false`. An ungated
    `□ (inJunction v j ⟹ speedLeKph v 30)` would therefore report a violation
    for every other vehicle in the junction — not because it was speeding but
    because its speed is unobservable. `other_vehicle_in_junction_is_ignored`
    pins this down. This rule makes no claim, either way, about a non-ego
    vehicle's speed.
  * **The fifty km/h general limit of `Speed/R0001_max_speed` is not folded in.**
    The two clauses are independent obligations over the same channel; this one
    binds only inside the junction, so a lawful 46.8 km/h approach is not a
    violation of *this* node — `fast_on_approach_is_not_a_violation` exists to
    pin that down, and would fail if the `inJunction` antecedent were dropped.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Speed.R0002

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The rule, quantified over (vehicle, junction) pairs, effective on the ego
    vehicle — the only one carrying a `speed` channel. -/
def schema : PropertySchema where
  name    := "junction_speed"
  binders := [vehicleBinder "v", junctionBinder "j"]
  formula := fun env =>
    let v := arg env 0
    let j := arg env 1
    □ ((isEgo v ⋀ inJunction v j) ⟹ speedLeKph v 30)

def entry : RuleEntry where
  nodeId  := "Speed/R0002_junction_speed"
  lawRefs := ["EX-SPEED-002"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- Road structure shared by every trace: a plain approach road, a road that
-- `isIn` the junction, and a plain exit road. The approach and exit roads are
-- deliberately NOT in the junction — otherwise ego would be inside the
-- junction for the whole trace and the positive scenarios could not
-- discriminate. The junction node and its lane are present in every frame of
-- every trace, including the ones where ego never enters, so that the rule
-- always grounds.
----------------------------------------------------------------------

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

/-- Lane → road → junction, plus the generator's `travelsTo` connectivity
    approach → junction lane → exit. Only `junctionRoad` is `isIn` the
    junction. -/
private def structureRels : List Relation :=
  [ mkRel approachLane .isIn approachRoad
  , mkRel junctionLane .isIn junctionRoad
  , mkRel exitLane     .isIn exitRoad
  , mkRel junctionRoad .isIn junction
  , mkRel approachLane .travelsTo junctionLane
  , mkRel junctionLane .travelsTo exitLane ]

/-- One frame: ego (id 1) occupying `lane` at `speed` m/s. -/
private def egoFrame (lane : Nat) (speed : String) (accel : String := "0.0")
    (throttle : String := "0.3") (brake : String := "0.0") : Scene :=
  frame
    (mkEgo 1 .car speed accel throttle brake :: structureEntities)
    (structureRels ++ [mkRel 1 .isIn lane])

/-- One frame: ego (id 1) occupying `lane` at `speed` m/s, with a non-ego car
    (id 2) standing in the junction lane. `mkActor` gives it no dynamics
    channels at all, exactly as the adapter does — that absence is the point of
    the scenario. The proximity and angular edges connect the ego to the other
    car, the only pairing the generator ever emits them for. -/
private def egoAndOtherFrame (lane : Nat) (speed : String) : Scene :=
  frame
    ([mkEgo 1 .car speed, mkActor 2 "car_0" .car] ++ structureEntities)
    (structureRels
      ++ [ mkRel 1 .isIn lane, mkRel 2 .isIn junctionLane
         , mkRel 1 .near 2, mkRel 1 .atDRearOf 2, mkRel 2 .inDFrontOf 1 ])

/-- Ego runs 12.0 m/s (43.2 km/h) on the plain approach lane, brakes, and
    crosses the junction lane at 7.0 m/s (25.2 km/h) for four frames before
    reaching the exit lane. Never above the bound while inside. -/
def traceSlowThroughJunction : Trace :=
  [ egoFrame approachLane "12.0" "0.0" "0.4" "0.0"
  , egoFrame approachLane "10.0" "-2.0" "0.0" "0.3"
  , egoFrame junctionLane "7.0" "-2.0" "0.0" "0.3"
  , egoFrame junctionLane "7.0" "0.0" "0.2" "0.0"
  , egoFrame junctionLane "7.0" "0.0" "0.2" "0.0"
  , egoFrame junctionLane "7.0" "0.0" "0.2" "0.0"
  , egoFrame exitLane     "11.0" "2.0" "0.6" "0.0" ]

/-- Ego holds 8.3 m/s (29.88 km/h) for the four frames it occupies the junction
    lane. The boundary test for the km/h → milli-m/s conversion:
    8300 ≤ 8333, so this complies. -/
def traceJustUnderThirtyInJunction : Trace :=
  [ egoFrame approachLane "8.3"
  , egoFrame junctionLane "8.3"
  , egoFrame junctionLane "8.3"
  , egoFrame junctionLane "8.3"
  , egoFrame junctionLane "8.3"
  , egoFrame exitLane     "8.3" ]

/-- Ego travels the approach lane at 13.0 m/s (46.8 km/h) for six frames and
    never occupies the junction lane; the junction node and its lane are present
    in every frame, so the rule grounds. Lawful under this clause — a rule that
    dropped the `inJunction` antecedent fails here. -/
def traceFastOnApproachIsNotAViolation : Trace :=
  [ egoFrame approachLane "13.0" "0.0" "0.5" "0.0"
  , egoFrame approachLane "13.0" "0.0" "0.5" "0.0"
  , egoFrame approachLane "13.0" "0.0" "0.5" "0.0"
  , egoFrame approachLane "13.0" "0.0" "0.5" "0.0"
  , egoFrame approachLane "13.0" "0.0" "0.5" "0.0"
  , egoFrame approachLane "13.0" "0.0" "0.5" "0.0" ]

/-- A non-ego car occupies the junction lane for the whole trace while the ego
    crosses at 6.0 m/s (21.6 km/h). The other car carries no `speed` attribute,
    so `speedLeKph` on it is false and a formula missing the `isEgo` gate would
    convict it — for the grounding `v := car_0`, not because it was speeding. -/
def traceOtherVehicleInJunctionIsIgnored : Trace :=
  [ egoAndOtherFrame approachLane "6.0"
  , egoAndOtherFrame approachLane "6.0"
  , egoAndOtherFrame junctionLane "6.0"
  , egoAndOtherFrame junctionLane "6.0"
  , egoAndOtherFrame exitLane     "6.0"
  , egoAndOtherFrame exitLane     "6.0" ]

/-- The tight negative counterpart of `traceJustUnderThirtyInJunction`:
    identical but for 8.4 m/s (30.24 km/h) held for the four in-junction frames.
    8400 > 8333, so every one of those frames is a violation. -/
def traceJustOverThirtyInJunction : Trace :=
  [ egoFrame approachLane "8.4"
  , egoFrame junctionLane "8.4"
  , egoFrame junctionLane "8.4"
  , egoFrame junctionLane "8.4"
  , egoFrame junctionLane "8.4"
  , egoFrame exitLane     "8.4" ]

/-- Ego approaches at 10.0 m/s and crosses the junction lane at 10.0 m/s
    (36 km/h) for three frames without slowing. 10000 > 8333 throughout the
    crossing. -/
def traceSpeedsThroughJunction : Trace :=
  [ egoFrame approachLane "10.0" "0.0" "0.4" "0.0"
  , egoFrame approachLane "10.0" "0.0" "0.4" "0.0"
  , egoFrame junctionLane "10.0" "0.0" "0.4" "0.0"
  , egoFrame junctionLane "10.0" "0.0" "0.4" "0.0"
  , egoFrame junctionLane "10.0" "0.0" "0.4" "0.0"
  , egoFrame exitLane     "10.0" "0.0" "0.4" "0.0" ]

def scenarios : List Scenario :=
  [ { name := "slow_through_junction",              trace := traceSlowThroughJunction,              expected := true }
  , { name := "just_under_thirty_in_junction",      trace := traceJustUnderThirtyInJunction,        expected := true }
  , { name := "fast_on_approach_is_not_a_violation", trace := traceFastOnApproachIsNotAViolation,   expected := true }
  , { name := "other_vehicle_in_junction_is_ignored", trace := traceOtherVehicleInJunctionIsIgnored, expected := true }
  , { name := "just_over_thirty_in_junction",       trace := traceJustOverThirtyInJunction,         expected := false }
  , { name := "speeds_through_junction",            trace := traceSpeedsThroughJunction,            expected := false } ]

end TrafficSpec.Rules.Speed.R0002
