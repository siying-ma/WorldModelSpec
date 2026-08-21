/-
  Rule R0001 — maximum speed.

  Law text (EX-SPEED-001, "Maximum speed"):
    "No person shall drive a vehicle at a speed exceeding fifty kilometres
     per hour."

  Formalization notes
  -------------------
  * **"exceeding" is read strictly.** Driving at *exactly* fifty km/h complies,
    so the obligation is `≤ 50`, not `< 50`.

  * **The bound is the literal figure in the text**, via `Pred.speedLeKph v 50`,
    and deliberately *not* `Pred.withinPostedSpeedLimit`. The posted-limit
    predicate reads OpenDRIVE landmark / speed-limit-sign data, which reaches
    the graph only when such a landmark is inside the capture's render distance
    of the ego's lane. Substituting it would formalize a different statute — a
    duty to obey signage — and would report a violation on every unsigned road,
    whereas a general statutory limit applies whether or not a sign is visible.

  * **The 13888 milli-m/s bound is very slightly stricter than fifty km/h.**
    `speedLeKph e kph` is `speedLe e (kph * 1000000 / 3600)` in `Nat` division,
    so 50 km/h becomes 50 * 1000000 / 3600 = 13888 milli-m/s, truncated down
    from 13888.88… . The enforced bound is therefore 49.9999952 km/h — about
    0.0000048 km/h (0.9 mm/s) stricter than the text. That residue is a
    consequence of the integer milli-unit model, not a reading of the law.

  * **The formula is gated on `Pred.isEgo v`, and that is a data restriction,
    not a reading of the law.** The statute binds every driver, but `speed` is
    copied into the scene graph for the ego vehicle only
    (`copy_carla_actor_state` is called for the ego node alone; see
    `carla/schema.json` → `unavailable.non_ego_dynamics`), and `Pred.attrMilli*`
    reads a missing attribute as `false`. An ungated `□ (speedLeKph v 50)` would
    convict every other vehicle in the capture — not for speeding, but for being
    unobservable. Gating on `isEgo` confines the obligation to the one vehicle
    whose compliance the data can witness; **this rule makes no claim either way
    about any other vehicle's speed.** Scenario
    `other_vehicle_speed_is_unobservable` is the regression test for the gate.

  * **No persistence window.** The law forbids driving above the limit at all,
    so a single frame over the bound is a violation: the formula is the plain
    state obligation `□ (isEgo v ⟹ speedLeKph v 50)` with no `.bounded`
    operator. `SFProp.frameSpan` is therefore 1 and no scenario trace needs a
    minimum length, so the verdict cannot depend on how long the capture is.

  * **Scope.** EX-SPEED-002 (thirty km/h inside a junction) is a separate,
    independent obligation, formalized as `Speed/R0002_junction_speed`; it is
    not folded in here, and this rule does not exempt junctions from the
    fifty km/h limit.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Speed.R0001

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- Quantified over vehicles, effective on the ego vehicle — the only one that
    carries a `speed` channel. -/
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

/-- Road structure shared by every trace: one driving lane inside one road. -/
private def egoId  : Nat := 1
private def otherId : Nat := 2
private def laneId : Nat := 10
private def roadId : Nat := 20

private def structureEntities : List Entity :=
  [mkLane laneId "Lane 7_-1", mkRoad roadId "Road 7"]

private def structureRels : List Relation :=
  [mkRel laneId .isIn roadId]

/-- One frame: the ego alone in the lane at `speed` m/s. -/
private def egoFrame (speed : String) : Scene :=
  frame
    (mkEgo egoId .car speed :: structureEntities)
    (structureRels ++ [mkRel egoId .isIn laneId])

/-- One frame: the ego at `speed` m/s with a non-ego car `car_0` in the same
    lane directly ahead. `mkActor` gives it no dynamics channels at all, exactly
    as the adapter does — that absence is the point of the scenario. -/
private def egoAndOtherFrame (speed : String) : Scene :=
  frame
    ([mkEgo egoId .car speed, mkActor otherId "car_0" .car] ++ structureEntities)
    (structureRels
      ++ [ mkRel egoId .isIn laneId, mkRel otherId .isIn laneId
         , mkRel egoId .near otherId, mkRel egoId .atDRearOf otherId
         , mkRel otherId .inDFrontOf egoId ])

/-- 12.000 m/s = 43.2 km/h, comfortably inside the limit, six frames. -/
def traceCompliantCruise : Trace :=
  [ egoFrame "12.000", egoFrame "12.000", egoFrame "12.000"
  , egoFrame "12.000", egoFrame "12.000", egoFrame "12.000" ]

/-- 13.800 m/s = 49.68 km/h — 13800 ≤ 13888, so just inside the bound. The
    minimal-pair partner of `just_over_the_limit`: together they pin down where
    the km/h → milli-m/s conversion actually puts the threshold. -/
def traceJustUnderTheLimit : Trace :=
  [ egoFrame "13.800", egoFrame "13.800", egoFrame "13.800", egoFrame "13.800" ]

/-- Ego compliant at 10.000 m/s, with `car_0` present and carrying no `speed`
    attribute. The `car_0` grounding must be *vacuously* satisfied — `isEgo` is
    false for it, so the implication holds without ever reading its speed. Drop
    the `isEgo` gate and this scenario reports a violation. -/
def traceOtherVehicleSpeedIsUnobservable : Trace :=
  [ egoAndOtherFrame "10.000", egoAndOtherFrame "10.000", egoAndOtherFrame "10.000"
  , egoAndOtherFrame "10.000", egoAndOtherFrame "10.000" ]

/-- 13.900 m/s = 50.04 km/h — 13900 > 13888, one milli-unit band over the
    bound, and a violation on every frame. -/
def traceJustOverTheLimit : Trace :=
  [ egoFrame "13.900", egoFrame "13.900", egoFrame "13.900", egoFrame "13.900" ]

/-- Compliant at 13.000 m/s (46.8 km/h) for four frames, then 16.000 m/s
    (57.6 km/h) for two. A single frame above the bound is a violation — there
    is no persistence window to wait out. -/
def traceExceedsLimitMidRun : Trace :=
  [ egoFrame "13.000", egoFrame "13.000", egoFrame "13.000", egoFrame "13.000"
  , egoFrame "16.000", egoFrame "16.000" ]

def scenarios : List Scenario :=
  [ { name := "compliant_cruise"
    , trace := traceCompliantCruise
    , expected := true }
  , { name := "just_under_the_limit"
    , trace := traceJustUnderTheLimit
    , expected := true }
  , { name := "other_vehicle_speed_is_unobservable"
    , trace := traceOtherVehicleSpeedIsUnobservable
    , expected := true }
  , { name := "just_over_the_limit"
    , trace := traceJustOverTheLimit
    , expected := false }
  , { name := "exceeds_limit_mid_run"
    , trace := traceExceedsLimitMidRun
    , expected := false } ]

end TrafficSpec.Rules.Speed.R0001
