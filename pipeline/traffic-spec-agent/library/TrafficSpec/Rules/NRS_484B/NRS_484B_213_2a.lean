/-
  NRS_484B_213_2a — NRS-484B-213-2a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (subject): A vehicle
    b2 (obligation): must not be driven to the left side of the highway at any time:
    b3 (trigger): When approaching the crest of a grade or upon a curve in the highway
    b4 (standard): where the driver’s view is obstructed within such distance as to create a hazard in the event another vehicle might approach from the opposite direction.
    b5 (exception): Subsection 2 does not apply upon a one-way highway.

  Elements (span → atoms, derived):
    b1: atoms ['ru.subject', 'ru.aggregate=vehicle'], derived []
    b2: atoms ['st.centre_line', 'st.roadway', 'rel.occupies'], derived []
    b3: atoms ['st.grade', 'st.curvature', 'st.region_geometry', 'rel.occupies'], derived ['drv.approaching']
    b5: atoms ['st.one_way_roadway', 'rel.occupies'], derived []

  How each span is written, and the consequences of the choices the text did not dictate:

  b1 — `ru.subject` and the aggregate word `vehicle`; the reading declares the classes.

  b2 — the side of the highway. The claimed atoms carry no left/right discriminator: `st.centre_line`
  is a region and `rel.occupies` is a membership. So "driven to the left side" is read as the body
  reaching the centre line — `rel.occupies` on a `st.centre_line` region. CONSEQUENCE: a body already
  wholly to the left of the line, whose footprint no longer meets it, is not caught; the duty is
  captured at the crossing, not for its duration. `st.roadway` carries the highway's travelled way
  and is quantified over on the trigger side, where the grade, the curvature and the distance the
  body still has to run are recorded; the obligation itself names only the centre line.

  b3 — the occasion, as a disjunction over one roadway region `r` within `p.approach_distance` of
  the body (`st.region_geometry`, which also anchors `r` to the binder):
    · approaching the crest of a grade: `drv.approaching` of a roadway region, with a non-zero
      grade recorded for `r`;
    · upon a curve: `rel.occupies` of `r`, with a non-zero curvature recorded for `r`.
  CONSEQUENCE: "the crest of a grade" is read as any region on a grade that the body is running up
  to; the ontology records one grade per region and the node names no parameter for a change of
  grade, so the summit is not distinguished from the climb. CONSEQUENCE: "a curve" is read as any
  non-zero recorded curvature, there being no parameter for a sharpness. CONSEQUENCE:
  `drv.approaching` is taken over the kind `st.roadway`, and Core reads it as "occupies no region
  of that kind"; the approach limb therefore speaks only while the body is on no roadway region at
  all, and the curve limb takes over once it is.

  b4 — the standard, operationalized as the node's table directs: the recorded sight distance for
  the region approached is a real reading (`st.sight_distance` above zero) and falls short of what
  the stopping-sight-distance model requires at the body's speed (`drv.sight_distance_adequate`
  with `p.stopping_decel`, `p.reaction_time`). CONSEQUENCE: "might approach from the opposite
  direction" is counterfactual and the ontology builds no hypothetical body, so the second limb of
  the table, `drv.time_to_conflict` under `p.ttc_bound`, is written as an *alternative* route to the
  same standard — a vehicle in fact within the conflict bound realizes the hazard the obstructed
  view is feared for. The disjunction only widens the occasion: it never excuses an obstructed view.
  CONSEQUENCE: the explicit `st.sight_distance` leaf only asks that a sight distance be recorded and
  positive for the region approached; the figure that decides obstruction is the same one, read by
  `drv.sight_distance_adequate` over every region the body occupies.

  b5 — the saving clause, in the applicability: the duty does not apply while the body occupies a
  `st.one_way_roadway` region.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Rule

namespace TrafficSpec.Rules.NRS_484B_213_2a

/-- The binders, as arguments (order and names are the node's). -/
private def vV : Arg := .var "v"

/-- The quantified variables: the roadway run up to or run on, the centre line, the one-way
    roadway, and a road user the body might meet. -/
private def rR : Arg := .var "r"
private def cC : Arg := .var "c"
private def wW : Arg := .var "w"
private def oO : Arg := .var "o"

/-- The reading's parameters; no value of any of them lives in this file. -/
private def pApproachDistance : Term := .param "p.approach_distance"
private def pReactionTime : Term := .param "p.reaction_time"
private def pStoppingDecel : Term := .param "p.stopping_decel"
private def pTtcBound : Term := .param "p.ttc_bound"

private def zeroMetres : Term := .lit Q.zero .metre
private def zeroRatio : Term := .lit Q.zero .ratio

/-- Class of `v`: ru.subject, ru.aggregate=vehicle -/
private def clsV : Formula :=
  .and (.atom "ru_subject" [vV] [])
       (.atom "ru_aggregate" [vV, .lit "vehicle"] [])

/-- b3, first limb: running up to a roadway region that lies on a grade. -/
private def approachingCrest : Formula :=
  .and (.derived "drv_approaching" [vV, .lit "roadway"] [pApproachDistance])
       (.cmp (.abs (.measure "st_grade" [rR])) .gt zeroRatio)

/-- b3, second limb: on a roadway region that curves. -/
private def uponCurve : Formula :=
  .and (.atom "rel_occupies" [vV, rR] [])
       (.cmp (.abs (.measure "st_curvature" [rR])) .gt zeroRatio)

/-- b4: the view is obstructed within such distance as to create a hazard — the model's bound on
    the sight distance recorded for `r`, or a body in fact within the conflict bound. -/
private def viewObstructed : Formula :=
  .or (.and (.cmp (.measure "st_sight_distance" [rR]) .gt zeroMetres)
            (.not (.derived "drv_sight_distance_adequate" [vV] [pStoppingDecel, pReactionTime])))
      (.existsUser "o"
        (.cmp (.quantity "drv_time_to_conflict" [vV, oO] [pTtcBound]) .lt pTtcBound))

/-- b5: the saving clause — the body is on a one-way roadway. -/
private def uponOneWay : Formula :=
  .existsRegion .oneWayRoadway "w"
    (.and (.atom "st_one_way_roadway" [wW] []) (.atom "rel_occupies" [vV, wW] []))

/-- Applicability: b3 (trigger): When approaching the crest of a grade or upon a curve in the highway; b5 (exception): Subsection 2 does not apply upon a one-way highway. -/
private def applicability : Formula :=
  .and
    (.existsRegion .roadway "r"
      (.and (.atom "st_roadway" [rR] [])
        (.and (.cmp (.measure "st_region_geometry_distance" [vV, rR]) .le pApproachDistance)
              (.and (.or approachingCrest uponCurve) viewObstructed))))
    (.not uponOneWay)

/-- Obligation: b2 (obligation): must not be driven to the left side of the highway at any time:; b4 (standard): where the driver’s view is obstructed within such distance as to create a hazard in the event another vehicle might approach from the opposite direction. -/
private def obligation : Formula :=
  .not (.existsRegion .centreLine "c"
         (.and (.atom "st_centre_line" [cC] []) (.atom "rel_occupies" [vV, cC] [])))

def rule : Rule :=
  { id := "NRS_484B_213_2a"
    laws := ["NRS-484B-213-2a"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "the driver's view is obstructed within such distance as to create a hazard in the event another vehicle might approach from the opposite direction"
          concepts := ["drv.sight_distance_adequate", "drv.time_to_conflict", "st.sight_distance"]
          params := ["p.stopping_decel", "p.reaction_time", "p.ttc_bound"]
          convention := "The table pairs 'view obstructed' with `drv.sight_distance_adequate` at the subject's speed: the view is obstructed when `st.sight_distance` at the subject's position is below what the stopping-sight-distance model gives for its speed (`p.stopping_decel`, `p.reaction_time`) taken against a vehicle approaching from the opposite direction, so that the hypothetical oncoming vehicle's `drv.time_to_conflict` would fall below `p.ttc_bound`. The hazard is bounded, not read: 'might approach' is counterfactual, so the bound is on the sight distance the model requires, not on an observed oncoming user."
          surrogate := false } ]
    residues :=
      [ "b2: 'driven to the left side of the highway' is read as the body's occupancy of a centre-line region, the only side-change the claimed atoms can decide; a body already wholly left of the line, no longer meeting it, is not caught."
      , "b3: 'the crest of a grade' is read as a roadway region with a non-zero recorded grade that the body is running up to; the summit is not distinguished from the climb."
      , "b3: 'a curve' is read as a non-zero recorded curvature of the roadway region occupied; no sharpness is required, the node naming no parameter for one."
      , "b3: `drv.approaching` is taken over the kind `st.roadway`, which Core reads as occupying no roadway region at all, so the approach limb speaks only off every roadway region."
      , "b4: 'in the event another vehicle might approach from the opposite direction' is counterfactual and is not built; the table's `drv.time_to_conflict` bound is written as an alternative route to the standard, satisfied by a body in fact within `p.ttc_bound`, which widens the occasion and never excuses an obstructed view."
      , "b4: the explicit `st.sight_distance` leaf asks only that a sight distance be recorded and positive for the region approached; the bound that decides obstruction is `drv.sight_distance_adequate`'s over the regions occupied." ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_213_2a
