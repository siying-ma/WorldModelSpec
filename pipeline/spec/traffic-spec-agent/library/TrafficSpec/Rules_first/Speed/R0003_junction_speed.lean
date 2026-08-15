/-
  Rule R0003 — speed in a junction.

  Law text (laws/example/laws.jsonl, id EX-SPEED-002):
    "A driver shall reduce speed to not more than thirty kilometres per hour
     while within an intersection."

  Formalization notes
  -------------------
  * **"within an intersection" is `Pred.inJunction v j`**, the graph's
    entity → lane → road → junction walk. The junction is a *bound* entity
    rather than existentially hidden behind `Pred.inAnyJunction`: the schema
    quantifies over `junctionBinder "j"` so that the report names which
    intersection the obligation was checked against, and so that a trace with
    no junction node grounds zero times (loudly vacuous) instead of silently
    passing. The cost is that the rule is checked once per (vehicle, junction)
    pair; for a pair where ego is not in that junction the antecedent is false
    and the obligation is discharged vacuously, which is the intended reading —
    the clause only speaks about the intersection you are actually inside.
  * **The bound is evaluated per frame, with no entry or exit grace window.**
    "while within an intersection" names a *state*, not an event, so the
    formalization is `□ (antecedent ⟹ bound)` with no `.bounded` window — unlike
    R0001, where "reasonable and prudent" forced a persistence threshold to be
    invented. One frame inside the junction above the bound is a violation.
    `accelerates_inside_junction` pins this down: entering the junction
    compliantly at 7.0 m/s does not discharge the obligation for the frames
    that follow.
  * **Thirty km/h is `Pred.speedLeKph v 30` = 8333 milli-m/s**, computed as
    `30 * 1000000 / 3600 = 8333` with truncation. 8.333 m/s (29.9988 km/h) is
    therefore the greatest speed permitted and 8.334 m/s is already a
    violation; the truncation makes the bound very slightly *stricter* than
    exactly 30 km/h. Recorded so a reviewer can see it rather than discover it.
  * **The obligation is gated on `Pred.isEgo`.** `speed` comes from the ego log
    and exists on the ego vehicle only (`Core/Vocab.lean` §6), so `speedLeKph`
    on any other vehicle is unconditionally false and an ungated rule would
    report a violation for every non-ego car that happens to be in the
    junction — not because it was speeding but because its speed is
    unobservable. This is a limitation of the data source, not a reading of the
    statute, which binds every driver.
  * **Nothing of R0002's fifty km/h bound is folded in here.** The two clauses
    are independent obligations over the same channel; this node's bound is
    conditional on junction occupancy, and a lawful 48.6 km/h approach to a
    junction is not a violation of *this* node.
    `fast_on_approach_slow_inside` exists to pin that down.
  * **The junction is entered by changing lane, not by a distance test.** The
    scene graph carries no stop-line or lane geometry, so "within" can only be
    read as occupancy of a lane whose road `isIn` the junction. A vehicle
    straddling the entry line reads as inside from the frame its lane
    assignment flips. `Pred.approachingJunction` is deliberately *not* used:
    the clause binds inside the intersection, not on the approach.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Speed.R0003

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The rule, quantified over (vehicle, junction) pairs. -/
def schema : PropertySchema where
  name    := "junction_speed"
  binders := [vehicleBinder "v", junctionBinder "j"]
  formula := fun env =>
    let v := arg env 0
    let j := arg env 1
    □ ((isEgo v ⋀ inJunction v j) ⟹ speedLeKph v 30)

def entry : RuleEntry where
  nodeId  := "Speed/R0003_junction_speed"
  lawRefs := ["EX-SPEED-002"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
--
-- Road structure shared by every trace: a plain approach road, a road that
-- `isIn` the junction, and a plain exit road. The approach and exit roads are
-- deliberately NOT in the junction — otherwise ego would be inside the
-- junction for the whole trace and the positive scenarios could not
-- discriminate.
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

/-- Ego runs 12.0 m/s (43.2 km/h) on the approach, brakes to 7.0 m/s
    (25.2 km/h) for the two frames it is inside the junction, and resumes
    11.0 m/s (39.6 km/h) on the exit lane. Fast outside, slow inside. -/
def traceSlowsForJunction : Trace :=
  [ egoFrame approachLane "12.0" "0.0" "0.4" "0.0"
  , egoFrame approachLane "12.0" "-1.5" "0.0" "0.2"
  , egoFrame junctionLane "7.0" "-2.0" "0.0" "0.4"
  , egoFrame junctionLane "7.0" "0.0" "0.0" "0.4"
  , egoFrame exitLane     "11.0" "2.0" "0.6" "0.0"
  , egoFrame exitLane     "11.0" "0.0" "0.4" "0.0" ]

/-- Ego approaches at 13.5 m/s (48.6 km/h) — above this node's 30 km/h bound
    but lawful under R0002's 50 km/h — then holds 8.0 m/s (28.8 km/h) for the
    three frames inside the junction. The 30 km/h bound binds only inside. -/
def traceFastApproachSlowInside : Trace :=
  [ egoFrame approachLane "13.5" "0.0" "0.5" "0.0"
  , egoFrame approachLane "13.5" "0.0" "0.5" "0.0"
  , egoFrame approachLane "13.5" "-1.0" "0.0" "0.3"
  , egoFrame junctionLane "8.0" "-2.0" "0.0" "0.3"
  , egoFrame junctionLane "8.0" "0.0" "0.2" "0.0"
  , egoFrame junctionLane "8.0" "0.0" "0.2" "0.0" ]

/-- The minimal pair against `traceFastApproachSlowInside`: identical except
    that the in-junction frames read 9.0 m/s (32.4 km/h, 9000 > 8333). The only
    difference is the speed attribute while ego occupies the junction lane,
    which is exactly the respect the clause cares about. -/
def traceSpeedsThroughJunction : Trace :=
  [ egoFrame approachLane "13.5" "0.0" "0.5" "0.0"
  , egoFrame approachLane "13.5" "0.0" "0.5" "0.0"
  , egoFrame approachLane "13.5" "-1.0" "0.0" "0.3"
  , egoFrame junctionLane "9.0" "-2.0" "0.0" "0.3"
  , egoFrame junctionLane "9.0" "0.0" "0.2" "0.0"
  , egoFrame junctionLane "9.0" "0.0" "0.2" "0.0" ]

/-- Ego enters the junction compliantly at 7.0 m/s in frame 3, then opens the
    throttle to 0.9 and reads 8.4, 9.5 and 10.5 m/s (30.2, 34.2, 37.8 km/h)
    while still inside. Entering compliantly does not discharge the
    obligation; the first over-bound frame is index 3 (8400 > 8333). -/
def traceAcceleratesInsideJunction : Trace :=
  [ egoFrame approachLane "10.0" "0.0" "0.3" "0.0"
  , egoFrame approachLane "9.0" "-1.5" "0.0" "0.3"
  , egoFrame junctionLane "7.0" "-2.0" "0.0" "0.3"
  , egoFrame junctionLane "8.4" "1.4" "0.5" "0.0"
  , egoFrame junctionLane "9.5" "1.1" "0.7" "0.0"
  , egoFrame junctionLane "10.5" "1.0" "0.9" "0.0" ]

def scenarios : List Scenario :=
  [ { name := "slows_for_junction",           trace := traceSlowsForJunction,          expected := true }
  , { name := "fast_on_approach_slow_inside", trace := traceFastApproachSlowInside,    expected := true }
  , { name := "speeds_through_junction",      trace := traceSpeedsThroughJunction,     expected := false }
  , { name := "accelerates_inside_junction",  trace := traceAcceleratesInsideJunction, expected := false } ]

end TrafficSpec.Rules.Speed.R0003
