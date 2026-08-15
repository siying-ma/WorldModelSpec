/-
  Rule R0001 — following distance.

  Law text (laws/example/laws.jsonl, id EX-FOLLOW-001):
    "The driver of a motor vehicle shall not follow another vehicle more
     closely than is reasonable and prudent. A vehicle shall not remain
     within four metres of the vehicle it is following."

  Formalization notes
  -------------------
  * "within four metres" is the union of the `safetyHazard` (<2 m) and
    `nearCollision` (2–4 m) proximity bands — `Pred.withinMetres 4`. Writing
    `rel v .near w` would mean the 10–16 m band, which is not what the law says.
  * "follow" is same-lane occupancy with the follower at the rear:
    `Pred.following v w` = `sameLane v w ⋀ behind v w`.
  * A single frame within four metres is transient (traffic compresses at
    junctions), so the obligation is violated only when the condition *persists*
    for three consecutive frames. That threshold is a formalization choice, not
    something the text states; it is recorded here so a reviewer can challenge it.
  * `□ ¬(bounded 3 φ)` reads: at no position does φ hold for three consecutive
    frames.
-/
import TrafficSpec.Core

namespace TrafficSpec.Rules.Following.R0001

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

/-- Vehicle `v` follows vehicle `w` within four metres. -/
def tooClose (v w : EntityId) : SFProp := followingWithin 4 v w

/-- The rule, quantified over ordered pairs of vehicles. -/
def schema : PropertySchema where
  name    := "following_distance"
  binders := [vehicleBinder "v", vehicleBinder "w"]
  formula := fun env =>
    let v := arg env 0
    let w := arg env 1
    □ (¬ₛ (.bounded 3 (tooClose v w)))

def entry : RuleEntry where
  nodeId  := "Following/R0001_following_distance"
  lawRefs := ["EX-FOLLOW-001"]
  schema  := schema

----------------------------------------------------------------------
-- Scenarios
----------------------------------------------------------------------

/-- Road structure shared by the scenario traces: one lane inside one road. -/
private def lane : Nat := 10
private def road : Nat := 20

private def structureEntities : List Entity :=
  [mkLane lane "Lane 7_-1", mkRoad road "Road 7"]

private def structureRels : List Relation :=
  [mkRel lane .isIn road]

/-- One frame: ego (id 1) following `car_0` (id 2) at proximity `band`. -/
private def followFrame (band : RelLabel) : Scene :=
  frame
    ([mkEgo 1 .car "9.0" "0.0" "0.3" "0.0", mkActor 2 "car_0" .car] ++ structureEntities)
    (structureRels
      ++ [ mkRel 1 .isIn lane, mkRel 2 .isIn lane
         , mkRel 1 band 2, mkRel 1 .atDRearOf 2, mkRel 2 .inDFrontOf 1 ])

/-- Ego dips inside four metres for two frames only — reasonable and prudent. -/
def traceTransient : Trace :=
  [ followFrame .superNear
  , followFrame .nearCollision
  , followFrame .nearCollision
  , followFrame .superNear
  , followFrame .near
  , followFrame .near ]

/-- Ego sits inside four metres for four consecutive frames — a violation. -/
def tracePersistent : Trace :=
  [ followFrame .near
  , followFrame .nearCollision
  , followFrame .nearCollision
  , followFrame .safetyHazard
  , followFrame .nearCollision
  , followFrame .near ]

/-- Ego stays a comfortable distance back throughout. -/
def traceClear : Trace :=
  [ followFrame .near
  , followFrame .near
  , followFrame .visible
  , followFrame .near
  , followFrame .veryNear
  , followFrame .near ]

def scenarios : List Scenario :=
  [ { name := "transient_closure_is_allowed", trace := traceTransient,  expected := true }
  , { name := "comfortable_gap_is_allowed",   trace := traceClear,      expected := true }
  , { name := "sustained_tailgating_violates", trace := tracePersistent, expected := false } ]

end TrafficSpec.Rules.Following.R0001
