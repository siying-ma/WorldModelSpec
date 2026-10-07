/-
  NRS_484B_407 — NRS-484B-407

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (obligation): shall not be turned so as to proceed in the opposite direction
    s3 (condition): upon any curve,
    s4 (boilerplate): or
    s5 (standard): upon the approach to or near
    s6 (condition): the crest of a grade,
    s7 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=vehicle'], derived []
    s2: atoms [], derived ['drv.motion.direction_reversal']
    s3: atoms ['st.curvature', 'st.roadway', 'rel.occupies'], derived []
    s6: atoms ['st.crest', 'st.region_geometry'], derived []
    s7: atoms ['st.sight_distance', 'st.roadway', 'rel.occupies'], derived []

  Literals the text states (each written through its Units constructor):
    s7: 500 ft — 500 feet

  How each span is written.

  s1 — the binder's class: `ru_aggregate veh "vehicle"`, the aggregate word the text uses and never
  the classes the reading lists under it. The word is not narrowed here by any class of its own.

  s2 — the obligation is the negation of the act: `drv.motion.direction_reversal` of the subject,
  taken with the node's three parameters in the concept's own order (`p.turn_window`, the window
  the heading change is integrated over; `p.direction_reversal_angle`, the magnitude at which the
  body counts as proceeding the other way; `p.motion_speed_min`, the speed above which it is
  proceeding and not standing). The subject complies where the concept does not hold of it. The
  concept's own atoms (kin.speed, kin.yaw_rate through prim.heading_change, rel.occupies on
  st.roadway) are the concept's: this file claims the concept whole and restates none of them.

  s3 — the condition, quantified over the roadway the subject is on: for some region `rd` of kind
  roadway, `st_roadway rd` and `rel_occupies veh rd` and the bend at that place stands clear of
  zero at the source's resolution. "Clear of zero at the source's resolution" is the span's own
  reading, which the record states: the radius of curvature there, 1/|st.curvature|, below
  `p.curve_radius_resolution`, the largest radius the map source still tells a bend apart from a
  straight road by. The comparison is written without a division: `1/|κ| < R` is multiplied through
  by `|κ| · R` (both positive wherever the way bends) and stated as `|κ| · R · R > R`. The two are
  the same bound wherever the roadway bends; where it runs straight, κ is zero and the bound as
  written is passed by no road — which is the reading intended, a bend being what the span names.
  Nothing is divided by a measured quantity, and the parameter carries the whole magnitude.

  s5 + s6 — the standard and the condition it qualifies, written together as the
  operationalization declares: for some region `cr` of kind crest, `st_crest cr` and the ground
  distance `st_region_geometry_distance veh cr` — the accessor of st.region_geometry that measures
  from the subject's body outline to the region — below `p.crest_approach_distance`. The crest is
  tied to the subject by that distance alone, which is the only relation the ontology carries
  between a road user and a crest; the record's narrowing on s5 is declared below.

  s7 — the condition, read at the place the subject occupies, as on s3: for some region `sd` of
  kind roadway, `st_roadway sd` and `rel_occupies veh sd` and `st_sight_distance sd` less than the
  text's own 500 feet. The sight distance is the atom's revised contract — the view of approaching
  traffic from that point and its being seen from either direction, whether or not any road user is
  there — so no second vehicle is quantified over and rel.visible is not read.

  The applicability is `(s3 or s6) and s7`, the text's own structure: upon a curve, or upon the
  approach to or near the crest of a grade, where the vehicle cannot be seen within 500 feet.

  The occasion. The node records the act as `drv.motion.direction_reversal` over `p.turn_window`
  and reads each of s3, s6 and s7 `at_recognition`: each condition is stated as it is, at the
  observation at which the reversal is recognized, and no span is read over the window behind.
  The `under_way` condition therefore governs no span and appears in no formula.

  Narrowings declared below are the record's two, on s2 and s5 — the duty's span and the standard's.
  Nothing is narrowed on s1, s3, s6 or s7: they decide when the rule applies and are carried as
  the node maps them. The curve bound's algebra above changes no case and is a restatement, not a
  reading.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_407

/-- The binders, as arguments (order and names are the node's). -/
private def vVeh : Arg := .var "veh"

/-- The regions the applicability quantifies over, each tied to `veh`: the roadway whose bend is
    read, the crest region, and the roadway whose sight distance is read. -/
private def vRd : Arg := .var "rd"
private def vCr : Arg := .var "cr"
private def vSd : Arg := .var "sd"

/-- The reading's parameters; no value of any of them lives in this file. -/
private def pCrestApproachDistance : Term := .param "p.crest_approach_distance"
private def pCurveRadiusResolution : Term := .param "p.curve_radius_resolution"
private def pDirectionReversalAngle : Term := .param "p.direction_reversal_angle"
private def pMotionSpeedMin : Term := .param "p.motion_speed_min"
private def pTurnWindow : Term := .param "p.turn_window"

/-- The text's own figure on s7. -/
private def fiveHundredFeet : Term := .lit (Units.feet 500) .metre

/-- s3 (condition): upon any curve — the roadway the subject occupies bends at its place, its
    radius of curvature below the largest radius the source tells apart from a straight road.
    `1/|κ| < R` multiplied through by `|κ| · R`, so nothing is divided by a measurement. -/
private def uponAnyCurve : Formula :=
  .existsRegion (.lit "roadway") "rd"
    (.and (.atom "st_roadway" [vRd] [])
      (.and (.atom "rel_occupies" [vVeh, vRd] [])
        (.cmp (.mul (.mul (.abs (.measure "st_curvature" [vRd])) pCurveRadiusResolution)
                    pCurveRadiusResolution)
              .gt pCurveRadiusResolution)))

/-- s5 (standard) + s6 (condition): upon the approach to or near the crest of a grade — the ground
    distance from the subject's body outline to a crest region is below the crest approach
    distance. -/
private def nearTheCrestOfAGrade : Formula :=
  .existsRegion (.lit "crest") "cr"
    (.and (.atom "st_crest" [vCr] [])
      (.cmp (.measure "st_region_geometry_distance" [vVeh, vCr]) .lt pCrestApproachDistance))

/-- s7 (condition): where such vehicle cannot be seen by the driver of any other vehicle
    approaching from either direction within 500 feet — the sight distance of the place the
    subject occupies is below the text's figure. -/
private def cannotBeSeenWithinFiveHundredFeet : Formula :=
  .existsRegion (.lit "roadway") "sd"
    (.and (.atom "st_roadway" [vSd] [])
      (.and (.atom "rel_occupies" [vVeh, vSd] [])
        (.cmp (.measure "st_sight_distance" [vSd]) .lt fiveHundredFeet)))

/-- Class of `veh`: ru.aggregate=vehicle -/
private def clsVeh : Formula := .atom "ru_aggregate" [vVeh, .lit "vehicle"] []

/-- Applicability: s3 (condition): upon any curve,; s6 (condition): the crest of a grade,; s7 (condition): where such vehicle cannot be seen by the driver of any other vehicle approaching from either direction within 500 feet. -/
private def applicability : Formula :=
  .and (.or uponAnyCurve nearTheCrestOfAGrade) cannotBeSeenWithinFiveHundredFeet

/-- Obligation: s2 (obligation): shall not be turned so as to proceed in the opposite direction; s5 (standard): upon the approach to or near -/
private def obligation : Formula :=
  .not (.derived "drv_motion_direction_reversal" [vVeh]
          [pTurnWindow, pDirectionReversalAngle, pMotionSpeedMin])

def rule : Rule :=
  { id := "NRS_484B_407"
    laws := ["NRS-484B-407"]
    binders :=
      [ { name := "veh", cls := clsVeh } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "upon the approach to or near"
          concepts := ["st.crest", "st.region_geometry"]
          params := ["p.crest_approach_distance"]
          convention := "crest vertical-curve sight-distance model: the length of approach ahead of a crest over which the vertical curve hides an oncoming vehicle from a driver at the subject's place, for the design speed of the road. The standard is bounded by the ground distance st.region_geometry gives from the subject's body outline to the st.crest region: the subject is upon the approach to or near the crest when that distance is below p.crest_approach_distance, and the bound moves with the design speed the reading sets it from. The standard qualifies an otherwise concrete duty, so the node is the law's own rule and not a surrogate."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s2"
          why := "The words leave the manoeuvre's duration open; the duty is read as forbidding a reversal carried out within p.turn_window, the window the heading-change primitive is integrated over, so a reversal spread over more than that window, or one whose look-back reaches back before the trace begins, is unknown rather than violated — the integration is then unobserved, and an unobserved reading is unknown. 'So as to' is read as the result and not the purpose: the rule reads the reversal the vehicle carried out, not the driver's purpose in turning, which no source observes, so a turn begun in order to proceed the other way but abandoned before the body's heading reverses is not judged. The act being one observed over time, this reading also fixes when the law's conditions are read against it: at the observation at which the reversal is recognized, the place at which the vehicle has been turned, and not at any moment of the window behind it. A reversal begun upon a curve, or upon the approach to a crest, and completed clear of it is therefore not judged by that route — the narrower side of the reading — while a bend, a crest or a blind place the vehicle merely passed earlier on its way no longer engages the duty. The act's own conditions, that the subject is in motion and that its heading has turned through the reversal angle over the window, are inside drv.motion.direction_reversal, which this rule claims whole and whose atoms (kin.speed, prim.heading_change) it does not restate as atoms of its own."
          kind := "reading" }
      , { span := "s5"
          why := "'Near' and 'the approach to' state no distance; the standard is bounded by p.crest_approach_distance, measured as the ground distance st.region_geometry gives from the subject's body outline to the crest region, so a vehicle farther from the crest than that bound is outside the duty however restricted its view — the sight-distance condition on s7 still has to be met, but it cannot by itself bring a distant approach back in. Further, the crest the bound reads is any crest region of the scene within that distance, the nearest by ground distance: the ontology carries no relation of a crest to the subject's own roadway, so a crest region of a neighbouring road lying within that distance would be read as the subject's."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_407
