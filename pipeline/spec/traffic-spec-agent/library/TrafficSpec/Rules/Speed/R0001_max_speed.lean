/-
  Rule R0001 — maximum speed.

  Law text (laws/example/laws.jsonl, id EX-SPEED-001):
    "No person shall drive a vehicle at a speed exceeding fifty kilometres
     per hour."

  Formalization notes
  -------------------
  * The bound is the **literal** fifty km/h the text states, via
    `Pred.speedLeKph v 50`, not `Pred.withinPostedSpeedLimit`. The posted-limit
    predicate is false whenever no OpenDRIVE speed-limit landmark is within the
    capture's render distance of the ego's lane, so using it here would report a
    violation on every unsigned road — the opposite reading of a general
    statutory limit, which applies whether or not a sign is visible.
  * `speedLeKph 50` is `speed ≤ 50 * 1000000 / 3600 = 13888` milli-m/s, i.e.
    13.888 m/s, truncated down. The truncation makes the bound very slightly
    *stricter* than exactly 50 km/h (by 0.4 mm/s); that is a rounding choice the
    text does not dictate, recorded here.
  * "exceeding" is read as strict: driving *at* exactly fifty km/h complies, so
    the obligation is `≤`, not `<`.
  * **The formula is gated on `Pred.isEgo v`.** This is a data restriction, not
    a reading of the law. The law binds every driver, but `speed` is copied into
    the scene graph for the ego vehicle only (`copy_carla_actor_state` is called
    for the ego node alone), and `Pred.attrMilli*` reads a missing attribute as
    `false`. An ungated `□ (speedLeKph v 50)` would therefore report a violation
    for every other car on the road — not because it was speeding, but because
    its speed is unobservable. `isEgo v ⟹ …` restricts the obligation to the
    only vehicle whose compliance the data can actually witness. A capture
    contains no evidence either way about any other vehicle's speed, and this
    rule accordingly makes no claim about it.
  * The obligation is instantaneous and has no persistence window: the law
    forbids driving above the limit at all, so a single frame over the bound is
    a violation. `□ φ` reads: at every frame position, φ holds.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Speed.R0001

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The rule, quantified over vehicles, effective on the ego vehicle — the only
    one carrying a `speed` channel. -/
def schema : PropertySchema where
  name    := "max_speed"
  binders := [vehicleBinder "v"]
  formula := fun env =>
    let v := arg env 0
    □ (isEgo v ⟹ speedLeKph v 50)

def entry : RuleEntry where
  nodeId  := "Speed/R0001_max_speed"
  lawRefs := ["EX-SPEED-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

/-- Road structure shared by every scenario trace: one lane inside one road. -/
private def lane : Nat := 10
private def road : Nat := 20

private def structureEntities : List Entity :=
  [mkLane lane "Lane 7_-1", mkRoad road "Road 7"]

private def structureRels : List Relation :=
  [mkRel lane .isIn road]

/-- One frame: the ego (id 1) alone in the lane, travelling at `speed` m/s. -/
private def egoFrame (speed : String) : Scene :=
  frame
    (mkEgo 1 .car speed :: structureEntities)
    (structureRels ++ [mkRel 1 .isIn lane])

/-- One frame: the ego at `speed` m/s, with a non-ego car (id 2) in the same
    lane ahead of it. `mkActor` gives it no dynamics channels at all, exactly as
    the adapter does — the point of the scenario. -/
private def egoAndOtherFrame (speed : String) : Scene :=
  frame
    ([mkEgo 1 .car speed, mkActor 2 "car_0" .car] ++ structureEntities)
    (structureRels
      ++ [ mkRel 1 .isIn lane, mkRel 2 .isIn lane
         , mkRel 1 .near 2, mkRel 1 .atDRearOf 2, mkRel 2 .inDFrontOf 1 ])

/-- 12.0 m/s = 43.2 km/h, comfortably inside the limit. -/
def traceCompliantCruise : Trace :=
  [ egoFrame "12.0", egoFrame "12.0", egoFrame "12.0"
  , egoFrame "12.0", egoFrame "12.0", egoFrame "12.0" ]

/-- 13.8 m/s = 49.68 km/h — just inside, and the boundary test for the km/h to
    milli-m/s conversion (13800 ≤ 13888). -/
def traceJustUnder : Trace :=
  [ egoFrame "13.8", egoFrame "13.8", egoFrame "13.8"
  , egoFrame "13.8", egoFrame "13.8", egoFrame "13.8" ]

/-- Ego compliant at 12.0 m/s with another car present. The other car has no
    `speed` attribute, so an ungated formula would call this a violation. -/
def traceOtherVehiclePresent : Trace :=
  [ egoAndOtherFrame "12.0", egoAndOtherFrame "12.0", egoAndOtherFrame "12.0"
  , egoAndOtherFrame "12.0", egoAndOtherFrame "12.0", egoAndOtherFrame "12.0" ]

/-- 14.0 m/s = 50.4 km/h — barely over, and a violation throughout. -/
def traceJustOver : Trace :=
  [ egoFrame "14.0", egoFrame "14.0", egoFrame "14.0"
  , egoFrame "14.0", egoFrame "14.0", egoFrame "14.0" ]

/-- Ego starts compliant at 12.0 m/s and accelerates to 16.0 m/s (57.6 km/h) by
    the third frame, holding it — compliant early, a violation from frame 2 on. -/
def traceAccelerates : Trace :=
  [ egoFrame "12.0", egoFrame "13.5", egoFrame "16.0"
  , egoFrame "16.0", egoFrame "16.0", egoFrame "16.0" ]

def scenarios : List Scenario :=
  [ { name := "compliant_cruise",                 trace := traceCompliantCruise,   expected := true }
  , { name := "just_under_limit",                 trace := traceJustUnder,         expected := true }
  , { name := "other_vehicle_present_is_ignored", trace := traceOtherVehiclePresent, expected := true }
  , { name := "just_over_limit",                  trace := traceJustOver,          expected := false }
  , { name := "accelerates_past_limit",           trace := traceAccelerates,       expected := false } ]

end TrafficSpec.Rules.Speed.R0001
