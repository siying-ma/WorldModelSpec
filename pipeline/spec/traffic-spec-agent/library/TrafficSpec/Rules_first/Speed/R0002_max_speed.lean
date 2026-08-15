/-
  Rule R0002 — maximum speed.

  Law text (laws/example/laws.jsonl, id EX-SPEED-001):
    "No person shall drive a vehicle at a speed exceeding fifty kilometres
     per hour."

  Formalization notes
  -------------------
  * The clause names a literal bound of fifty km/h, so no posted speed limit is
    consulted. That matters because the CARLA scene graph carries no
    `speed_limit` field; a rule that had to read the posted limit would be
    unsupported, and this one is not.
  * "at a speed exceeding fifty kilometres per hour" is `Pred.speedLeKph v 50`
    negated pointwise, i.e. the obligation is `speedLeKph v 50` at every frame.
    `speedLeKph` converts to milli-m/s as `50 * 1000000 / 3600 = 13888`,
    truncating, so 13.888 m/s is the greatest speed the formalization permits
    and 13.9 m/s is already a violation. The truncation makes the bound very
    slightly *stricter* than exactly 50 km/h (13.8888… m/s); this is a
    consequence of exact integer arithmetic, recorded here so a reviewer can
    see it rather than discover it.
  * **The obligation is gated on `Pred.isEgo`.** `speed` comes from the ego log
    and exists on the ego vehicle only (`Core/Vocab.lean` §6), so `speedLeKph`
    applied to any other vehicle is unconditionally false. Without the gate the
    rule would report a violation for every non-ego car in the trace — not
    because it was speeding, but because its speed is unobservable. With the
    gate a non-ego binding is vacuously satisfied. This is a limitation of the
    data source, not a reading of the statute: the statute binds every driver,
    and this formalization can only check the one vehicle whose speed CARLA
    records. `compliant_cruise` carries a second car precisely to pin that
    behaviour down.
  * **A single frame above the bound is a violation.** The statute states no
    tolerance and no persistence window, unlike the following-distance rule
    R0001 where a three-frame threshold had to be invented for "reasonable and
    prudent". Here the text is a hard bound, so the formula is `□ (…)` with no
    `bounded` window. `marginally_over_limit` tests exactly this: it differs
    from the compliant `just_under_limit` trace in one attribute of one frame.
  * **No `onRoadway` gate, and no "is driving" gate.** The clause is
    unconditional — it does not carve out parking lots, junctions, or any other
    context — so no antecedent beyond `isEgo` is added. In particular a
    stationary or off-road ego trivially satisfies the bound anyway, so a
    "driving" antecedent would change nothing observable while weakening the
    rule against traces we have not written.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Speed.R0002

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- The rule, quantified over single vehicles. `isEgo` is an antecedent, not a
    filter on the binder: the binder ranges over all vehicles and the
    obligation is discharged vacuously for the ones whose speed CARLA does not
    record. -/
def schema : PropertySchema where
  name    := "max_speed"
  binders := [vehicleBinder "v"]
  formula := fun env =>
    let v := arg env 0
    □ (isEgo v ⟹ speedLeKph v 50)

def entry : RuleEntry where
  nodeId  := "Speed/R0002_max_speed"
  lawRefs := ["EX-SPEED-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

/-- Road structure shared by the scenario traces: one straight lane in one
    road. -/
private def lane : Nat := 10
private def road : Nat := 20

private def structureEntities : List Entity :=
  [mkLane lane "Lane 7_-1", mkRoad road "Road 7"]

private def structureRels : List Relation :=
  [mkRel lane .isIn road]

/-- One frame: ego (id 1) alone in the lane at `speed` m/s. -/
private def soloFrame (speed : String) (accel : String := "0.0")
    (throttle : String := "0.3") : Scene :=
  frame
    (mkEgo 1 .car speed accel throttle "0.0" :: structureEntities)
    (structureRels ++ [mkRel 1 .isIn lane])

/-- One frame: ego (id 1) at `speed` m/s with `car_0` (id 2) ahead of it in the
    same lane, ten to sixteen metres away. `car_0` carries no dynamics
    channels, exactly as the adapter emits non-ego actors. -/
private def pairFrame (speed : String) : Scene :=
  frame
    ([mkEgo 1 .car speed "0.0" "0.3" "0.0", mkActor 2 "car_0" .car]
      ++ structureEntities)
    (structureRels
      ++ [ mkRel 1 .isIn lane, mkRel 2 .isIn lane
         , mkRel 1 .near 2, mkRel 1 .atDRearOf 2, mkRel 2 .inDFrontOf 1 ])

/-- Ego holds 13.0 m/s (46.8 km/h), with a second car ahead. The `car_0`
    grounding has no `speed` attribute at all, so it exercises the `isEgo`
    gate: it must come out satisfied, not false. -/
def traceCompliantCruise : Trace :=
  [ pairFrame "13.0", pairFrame "13.0", pairFrame "13.0"
  , pairFrame "13.0", pairFrame "13.0", pairFrame "13.0" ]

/-- Ego holds 13.8 m/s (49.68 km/h) — 13800 milli-m/s, inside the 13888 bound
    and the largest tenth-of-a-metre-per-second reading the rule permits. -/
def traceJustUnder : Trace :=
  [ soloFrame "13.8", soloFrame "13.8", soloFrame "13.8"
  , soloFrame "13.8", soloFrame "13.8", soloFrame "13.8" ]

/-- The minimal pair against `traceJustUnder`: frame 4 (index 3) reads
    13.9 m/s (50.04 km/h, 13900 > 13888) and ego returns to 13.8 m/s after. One
    frame over the bound is a violation. -/
def traceMarginallyOver : Trace :=
  [ soloFrame "13.8", soloFrame "13.8", soloFrame "13.8"
  , soloFrame "13.9", soloFrame "13.8", soloFrame "13.8" ]

/-- Ego accelerates from 14.0 to 18.0 m/s (50.4 to 64.8 km/h) under 0.8
    throttle: over the bound in every frame. -/
def traceSustainedSpeeding : Trace :=
  [ soloFrame "14.0" "2.0" "0.8", soloFrame "14.8" "2.0" "0.8"
  , soloFrame "15.6" "2.0" "0.8", soloFrame "16.4" "2.0" "0.8"
  , soloFrame "17.2" "2.0" "0.8", soloFrame "18.0" "2.0" "0.8" ]

def scenarios : List Scenario :=
  [ { name := "compliant_cruise",       trace := traceCompliantCruise,   expected := true }
  , { name := "just_under_limit",       trace := traceJustUnder,         expected := true }
  , { name := "marginally_over_limit",  trace := traceMarginallyOver,    expected := false }
  , { name := "sustained_speeding",     trace := traceSustainedSpeeding, expected := false } ]

end TrafficSpec.Rules.Speed.R0002
