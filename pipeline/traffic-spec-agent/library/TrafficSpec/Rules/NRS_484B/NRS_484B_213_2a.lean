/-
  NRS 484B.213(2)(a) — when approaching the crest of a grade, or upon a curve in the highway,
  where the driver's view is obstructed within such distance as to create a hazard in the event
  another vehicle might approach from the opposite direction, a vehicle must not be driven to the
  left side of the highway; subsection 2 does not apply upon a one-way highway.

  THE READING (the blueprint's, not this file's):
  - s1 subject    — the binder `a`: the subject track, of one of the classes the node lists for
                    the corpus's word "vehicle". `c` is the vehicle that might approach from the
                    opposite direction: a vehicle, and not the subject.
  - s8 exception  — the applicability, negated: the appended subsection 3 lifts the duty upon a
                    one-way highway.
  - s4, s5 trigger — the applicability, as a disjunction: a approaches the crest of a grade, or
                    is upon a curve.
  - s6, s7 standard — the applicability: the two operationalized standards, exactly the concepts
                    and parameters the node declares on each span.
  - s2 obligation — a's footprint neither lies left of, nor across, the centre line.
  - s3            — boilerplate ("at any time"); it carries no element and appears nowhere below.

  CHOICES THE TEXT DID NOT DICTATE (each one is a reading of a span, not an invention):

  1. "the crest of a grade" (s4) is read as the ontology defines it: `st.grade` is "the
     longitudinal slope of the roadway; a crest is its SIGN CHANGE". So the crest is a region of
     positive grade the subject is on and a region of negative grade beyond it, and "approaching"
     is `drv.approaching` at `p.approach_distance`. `drv.approaching` takes a structure KIND, and
     it is false whenever the subject already occupies a region of that kind, so the stretch
     beyond the crest cannot be named by the same kind as the stretch the subject is on. It is
     named by the kind the statute itself uses for the place — `highway`, the whole public way,
     which s5 also names ("a curve in the highway") — and the near stretch, which the subject
     occupies and which carries the sight distance, by `roadway`. A scene that maps the near
     stretch as a roadway and the stretch past the crest as a highway states nothing false; it
     states less than it could. CONSEQUENCE, stated plainly: a source that maps one single
     region across the crest cannot engage this trigger. See task_result.md.
  2. "a curve in the highway" (s5) is `st.curvature` away from zero. The node declares no
     literal, so no minimum curvature may be written here: the only comparison available is
     against zero, and it is written on the absolute value, because a curve bends either way.
  3. s6, "the driver's view is obstructed within such distance", is the node's two concepts, and
     both do work. `drv.sight_distance_adequate` at `p.stopping_decel` and `p.reaction_time` is
     negated: the sight distance where a is falls short of what the model requires at a's speed.
     `st.sight_distance` is then read for what the ontology says it is — "the distance within
     which another vehicle would be visible from a point" — and held against the distance at
     which the other vehicle actually is: the view of c is obstructed when c lies beyond it. The
     comparison is written on the SQUARES of the two distances, because the language has no
     square root and the separation of two `kin.position` values is only available squared. No
     parameter but the two the node names on s6 enters this span.
  4. s7, "as to create a hazard …", is the node's single concept with the node's two parameters:
     `drv.time_to_conflict` with c, projected over `p.ttc_horizon`, below `p.ttc_bound`. The
     concept returns the horizon when it predicts no conflict inside it, so `<` is "a conflict is
     predicted". `rel.oncoming` and `p.oncoming_cos`, which the node's convention mentions in
     prose, are NOT claimed by any element or operationalization of the node, so they do not
     appear here and `p.oncoming_cos` is named nowhere: c's opposition is what the witness
     builds, not what the rule tests. See task_result.md.
  5. s8, "upon a one-way highway", is a region of kind `st.one_way_roadway` together with the
     agreement of every `st.lane_direction` in the scene — no two lanes oppose (a non-negative
     dot product, the only comparison this needs). Both atoms are the node's, and the second is
     what the narrative of the `idle` scenario names. It enters the applicability negated.
  6. "the left side of the highway" (s2) has two limbs, and their disjunction is what the
     obligation forbids:
       (a) a's body lies ACROSS the dividing line — `drv.straddles_marking`, a occupying two
           lanes at once; the scene must carry a `st.centre_line` region for the limb to speak.
       (b) a's body has reached the space of the traffic coming the other way: twice the signed
           lateral offset of a from c is at least MINUS the sum of their two full widths
           (`kin.position`, `kin.extent`) — the two bodies overlap laterally, or a is further
           left still.
     "Left" is the left of the centre line's own recorded direction (`st.lane_direction` read on
     the `st.centre_line` region). CONSEQUENCE, stated plainly: the reference for limb (b) is the
     opposing vehicle c, not the line, because the node claims neither `st.region_geometry` nor
     `rel.occupies` on s2 and the line's POSITION is therefore unreadable here; and for a subject
     travelling against the line's recorded direction the rule's "left" is that subject's right.
     This is the same convention NRS_484B_213_1 adopted, for the same reason. See task_result.md.

  No number below is a value this file chose: every magnitude is a parameter of the run's reading
  or a measured quantity, and the only literals are zero.
-/
import TrafficSpec.Core.Rule

namespace TrafficSpec.Rules.NRS_484B_213_2a

/-- The binders, as arguments. -/
private def subj : Arg := .var "a"
private def onc : Arg := .var "c"

/-- The reading's parameters; no value of any of them lives in this file. -/
private def pReaction : Term := .param "p.reaction_time"
private def pDecel : Term := .param "p.stopping_decel"
private def pTtcBound : Term := .param "p.ttc_bound"
private def pTtcHorizon : Term := .param "p.ttc_horizon"
private def pApproach : Term := .param "p.approach_distance"

private def zeroRatio : Term := .lit Q.zero .ratio

/-- The classes the node's s1 element lists for the corpus's word "vehicle". -/
private def vehicleClasses : List String :=
  ["ru_motor_vehicle", "ru_motorcycle", "ru_moped", "ru_bus", "ru_transit_bus", "ru_taxicab",
   "ru_tour_bus_or_limousine", "ru_truck", "ru_commercial_motor_vehicle",
   "ru_trailer_or_combination", "ru_bicycle", "ru_animal_or_animal_drawn",
   "ru_emergency_vehicle", "ru_official_vehicle", "ru_procession_vehicle"]

/-- One of the classes the word "vehicle" covers. -/
private def isVehicle (x : Arg) : Formula :=
  vehicleClasses.foldr (fun n acc => .or (.atom n [x] []) acc) .ff

-- ---------------------------------------------------------------------------------------------
-- s8: the one-way highway the appended subsection 3 excepts
-- ---------------------------------------------------------------------------------------------

/-- The dot product of two lane directions. -/
private def directionsDot (l n : String) : Term :=
  .add (.mul (.measure "st_lane_direction" [.var l, .lit "x"])
             (.measure "st_lane_direction" [.var n, .lit "x"]))
       (.mul (.measure "st_lane_direction" [.var l, .lit "y"])
             (.measure "st_lane_direction" [.var n, .lit "y"]))

/-- No two lanes of the scene oppose: every recorded direction agrees with every other. -/
private def laneDirectionsAgree : Formula :=
  .forallRegion .lane "l" (.forallRegion .lane "n" (.cmp (directionsDot "l" "n") .ge zeroRatio))

/-- s8: a one-way roadway, whose lanes all run the one way. -/
private def oneWayHighway : Formula :=
  .existsRegion .oneWayRoadway "ow"
    (.and (.atom "st_one_way_roadway" [.var "ow"] []) laneDirectionsAgree)

-- ---------------------------------------------------------------------------------------------
-- s4, s5: the crest and the curve
-- ---------------------------------------------------------------------------------------------

/-- s4: the sign change of `st.grade` the ontology calls a crest — the stretch a is on rises,
    the stretch past the crest falls. -/
private def gradeSignChange : Formula :=
  .and (.existsRegion .roadway "up" (.cmp (.measure "st_grade" [.var "up"]) .gt zeroRatio))
       (.existsRegion .highway "over" (.cmp (.measure "st_grade" [.var "over"]) .lt zeroRatio))

/-- s4: a is within `p.approach_distance` of the stretch beyond the crest, and moving onto it. -/
private def approachingCrest : Formula :=
  .and (.derived "drv_approaching" [subj, .lit "highway"] [pApproach]) gradeSignChange

/-- s5: the roadway bends, either way. -/
private def uponCurve : Formula :=
  .existsRegion .roadway "cv" (.cmp (.abs (.measure "st_curvature" [.var "cv"])) .gt zeroRatio)

-- ---------------------------------------------------------------------------------------------
-- s6, s7: the two standards the node operationalizes
-- ---------------------------------------------------------------------------------------------

/-- The squared ground separation of a and c, from their two `kin.position` values. -/
private def separationSq : Term :=
  let dx := .sub (.measure "kin_position" [subj, .lit "x"]) (.measure "kin_position" [onc, .lit "x"])
  let dy := .sub (.measure "kin_position" [subj, .lit "y"]) (.measure "kin_position" [onc, .lit "y"])
  .add (.mul dx dx) (.mul dy dy)

/-- s6: the sight distance where a is falls short of what the stopping model requires at a's
    speed, and c lies beyond the distance within which a vehicle would be visible. -/
private def viewObstructed : Formula :=
  .and (.not (.derived "drv_sight_distance_adequate" [subj] [pDecel, pReaction]))
    (.existsRegion .roadway "vw"
      (.and (.atom "st_roadway" [.var "vw"] [])
        (.cmp (.mul (.measure "st_sight_distance" [.var "vw"])
                    (.measure "st_sight_distance" [.var "vw"])) .lt separationSq)))

/-- s7: a conflict with c is predicted within the horizon the node's parameters set. -/
private def hazardFromOpposite : Formula :=
  .cmp (.quantity "drv_time_to_conflict" [subj, onc] [pTtcHorizon]) .lt pTtcBound

-- ---------------------------------------------------------------------------------------------
-- s2: driven to the left side of the highway
-- ---------------------------------------------------------------------------------------------

/-- The signed lateral offset of a from c about the centre line `cl`'s own direction, positive to
    the left of that direction: the 2-D cross product of the direction with `p_a − p_c`. -/
private def leftOffsetFromOpposing : Term :=
  .sub (.mul (.measure "st_lane_direction" [.var "cl", .lit "x"])
             (.sub (.measure "kin_position" [subj, .lit "y"])
                   (.measure "kin_position" [onc, .lit "y"])))
       (.mul (.measure "st_lane_direction" [.var "cl", .lit "y"])
             (.sub (.measure "kin_position" [subj, .lit "x"])
                   (.measure "kin_position" [onc, .lit "x"])))

/-- s2: across the dividing line, or reaching into the space of the traffic coming the other way. -/
private def leftOfTheCentre : Formula :=
  .existsRegion .centreLine "cl"
    (.and (.atom "st_centre_line" [.var "cl"] [])
      (.or (.derived "drv_straddles_marking" [subj] [])
           (.cmp (.add leftOffsetFromOpposing leftOffsetFromOpposing) .ge
                 (.neg (.add (.measure "kin_extent" [subj, .lit "width"])
                             (.measure "kin_extent" [onc, .lit "width"]))))))

-- ---------------------------------------------------------------------------------------------

def rule : Rule :=
  { id := "NRS_484B_213_2a"
    laws := ["NRS-484B-213-2a"]
    binders :=
      [ { name := "a", cls := .and (.atom "ru_subject" [subj] []) (isVehicle subj) }
      , { name := "c", cls := isVehicle onc } ]
    applicability :=
      .and (.not oneWayHighway)
        (.and (.or approachingCrest uponCurve)
              (.and viewObstructed hazardFromOpposite))
    obligation := .not leftOfTheCentre
    assumptions := []
    operationalizations :=
      [ { standard := "the driver’s view is obstructed within such distance"
          concepts := ["drv.sight_distance_adequate", "st.sight_distance"]
          params := ["p.reaction_time", "p.stopping_decel"]
          convention := "Stopping-/passing-sight-distance model of the ontology's ‘clearly visible for a sufficient distance; view obstructed’ row: `st.sight_distance` at the subject's position is compared, by `drv.sight_distance_adequate`, with the distance the model gives for the subject's speed under design deceleration `p.stopping_decel` and design perception-reaction time `p.reaction_time`. The obstruction of view is read as `st.sight_distance` falling short of what the model requires at a's speed; §9 bars reading the driver's perception itself, and this is the observable the clause offers."
          surrogate := false }
      , { standard := "as to create a hazard in the event another vehicle might approach from the opposite direction"
          concepts := ["drv.time_to_conflict"]
          params := ["p.ttc_bound", "p.ttc_horizon"]
          convention := "Conflict-analysis convention of the ontology's ‘so close as to be a hazard’ row: `drv.time_to_conflict` at the conflict point, projected over `p.ttc_horizon`, below `p.ttc_bound`. The hypothetical opposing vehicle c is projected on the opposing lane direction at a's own speed, and `rel.oncoming` fixes the opposition through `p.oncoming_cos`."
          surrogate := false } ]
    residues := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_213_2a
