/-
  NRS_484B_253_o2 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (sibling): The driver of a vehicle within an intersection intending to turn to the left shall yield the right-of-way to any vehicle approaching from the opposite direction which is within the intersection or so close thereto as to constitute an immediate hazard,
    t2 (condition): but such driver, having so yielded
    t3 (condition): and having given a signal when and as required,
    t4 (condition): may make such left turn and
    t5 (subject): the drivers of all other vehicles approaching the intersection from the opposite direction
    t6 (obligation): shall yield the right-of-way to the vehicle making the left turn.

  Elements (span → atoms, derived):
    t2: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance', 'kin.speed', 'st.region_geometry', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.lane_direction', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.road.opposed_approach_directions']
    t4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived ['drv.motion.leftward_course_change']
    t5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.lane_enters', 'st.travel_region', 'st.lane_direction', 'rel.occupies', 'st.intersection'], derived ['drv.position.approaching_intersection', 'drv.road.opposed_approach_directions']
    t6: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    t3: NRS_484B_413_2 as compliance map {'subject': 'turner'}

  How each span is written.

  The clause lays its duty on the subject and speaks of another vehicle — the turner — throughout:
  t2, t3 and t4 are facts about that other vehicle, t5 about the subject's relation to the junction
  the turner turns in, and t6 the subject's duty towards the turner. The node binds the subject
  only, so the turner is bound by `existsUser "turner"` in the applicability and by `forallUser` in
  the obligation, and the junction by a quantifier over `st.intersection` in each. `turnerSelection`
  holds t2, t3, t4 and t5 together on one turner and one junction, and is the whole selection the
  obligation re-states under its own quantifiers: the duty is owed to every vehicle the clause
  licenses, at every junction it turns in. "All OTHER vehicles" is `.not (.same turner subject)`:
  the subject is never its own turner.

  t4 — `turnsLeftWithinJunction`: the catalogued `drv.motion.leftward_course_change` of the turner
  with the reading's window and course-change bounds and its motion tolerance, conjoined with
  `rel.occupies` of the turner on the junction the quantifier selects (`st.intersection`), which is
  where the first sentence places the act. The turner is the admitted aggregate
  (`ru_aggregate` with `DEF-NRS-484A-320::vehicle`). The node declares no occasion and reads the act
  as a state of the manoeuvre window, not as an event, so no `.rises` is written: the duty is owed at
  every observation at which the turn is being made.

  t2 — `hasYielded`: the yield of the first sentence, carried in full, as the record's element
  states it: at every observation of the manoeuvre window behind (`p.turn_window`,
  `.holdsFor .time`), for every road user of the scene (`forallUser "other"`), if that user was an
  immediate hazard then the turner did not bring about a predicted conflict with it.
  `immediateHazardToTurner` is a vehicle other than the turner that was either within that junction
  (`rel.occupies`, the limb the element states without a direction), or on a carrier whose
  designated direction opposes the turner's approach (`drv.road.opposed_approach_directions` over the
  two carriers, each a `st.travel_region` whose `st.lane_enters` entrance end is that junction and
  whose overlap with the body is `rel.occupies`) and no further from the junction than the ground its
  speed covers in the arrival time (`st.region_geometry` as the distance from the body to the
  junction, `kin.speed` times `p.immediate_hazard_arrival_time`). "Did not bring about a predicted
  conflict" is `noPredictedConflict`, DEF-NRS-484A-210 as the node reads it: either the centres do
  not approach within `p.yield_conflict_horizon` (`prim.closest_approach_within`) or their distance at
  the closest approach is at least `p.yield_min_clearance` (`prim.closest_approach_distance`). The
  yield is stated here and not composed from NRS_484B_253_o1, as the element directs.

  t5 — `subjectApproachesOpposed`: the catalogued `drv.position.approaching_intersection` of the
  subject at that junction, which takes the junction as a region argument and so reads the junction
  the words single out; and the subject's own approach carrier — a `st.travel_region`, not the
  junction itself, that the subject's footprint overlaps (`rel.occupies`) and whose `st.lane_enters`
  entrance end is that junction — carrying a designated direction opposed to the turner's approach
  (`drv.road.opposed_approach_directions` with `p.opposite_direction_tolerance`), as rel.oncoming's
  exclusion directs.

  "The turner's approach" (`onTurnerApproach`, read by t2 and t5): the turner is within the junction
  while it turns, so the carrier it approached through is the travel region, other than the junction
  (`.not (.same …)`: a junction is no approach to itself), whose entrance end is that junction and
  whose overlap with the turner's footprint is current at some observation of the manoeuvre window
  behind — the same window `p.turn_window` the act's course change is taken over. The carrier is
  selected once, outside the yield's own window, so that t2 and t5 read one and the same approach.
  No other operator of the language states "the carrier it came in on" without reaching past the
  start of the recording, where nothing is observed. These are applicability spans, carried as the
  node maps them, so nothing here is declared as a narrowing.

  t3 — the composition, `as: compliance`: `.rule "NRS_484B_413_2"` with its binder `subject` bound to
  this rule's `turner`, placed in the selection beside t2 and t4, as the words place it ("having
  given a signal when and as required"). Its content is never inlined.

  t6 — the obligation: `noPredictedConflict` between the subject and the turner, under the velocities
  observed at the instant, with the same two primitives and the same two parameters. The record's own
  narrowing on t6 (the duty to yield read as not bringing about a predicted conflict, and the
  definition's words about proceeding "in a lawful manner" left to another rule's verdict) is the
  plan's and is not restated below.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The other vehicle the clause speaks of, and the road users and regions the formulas quantify
    over, each anchored to the subject. -/
def vTurner : Arg := .var "turner"
def vOther : Arg := .var "other"
def vJunction : Arg := .var "junction"
def vTurnerCarrier : Arg := .var "turner_carrier"
def vSubjectCarrier : Arg := .var "subject_carrier"
def vOtherCarrier : Arg := .var "other_carrier"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pImmediateHazardArrivalTime : Term := .param "p.immediate_hazard_arrival_time"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pOppositeDirectionTolerance : Term := .param "p.opposite_direction_tolerance"
def pTurnMaxCourseChange : Term := .param "p.turn_max_course_change"
def pTurnMinCourseChange : Term := .param "p.turn_min_course_change"
def pTurnWindow : Term := .param "p.turn_window"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

/-- Membership of the admitted aggregate, by its id. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- DEF-NRS-484A-210 as the node reads it: `a` does not bring about a predicted conflict with `b` —
    under the velocities observed at this instant either the two centres do not approach within the
    conflict horizon, or the centre distance at their closest approach is at least the minimum
    clearance. -/
def noPredictedConflict (a b : Arg) : Formula :=
  .or (.not (.derived "prim_closest_approach_within" [a, b] [pYieldConflictHorizon]))
      (.cmp (.quantity "prim_closest_approach_distance" [a, b] [pYieldConflictHorizon])
            .ge pYieldMinClearance)

/-- t4: the turner is making a change of course to the left within that junction. -/
def turnsLeftWithinJunction : Formula :=
  .and (.atom "rel_occupies" [vTurner, vJunction] [])
       (.derived "drv_motion_leftward_course_change" [vTurner]
          [pTurnWindow, pTurnMinCourseChange, pTurnMaxCourseChange, pMotionSpeedTolerance])

/-- t2: `other` was an immediate hazard to the turner at this observation — a vehicle other than the
    turner that was within that junction, or on a carrier whose designated direction opposes the
    turner's approach and no further from the junction than the ground its speed covers in the
    arrival time. -/
def immediateHazardToTurner : Formula :=
  .and (isVehicle vOther)
    (.and (.not (.same vOther vTurner))
      (.or (.atom "rel_occupies" [vOther, vJunction] [])
        (.and (.existsRegion (.lit "travel_region") "other_carrier"
                (.and (.not (.same vOtherCarrier vJunction))
                  (.and (.atom "rel_occupies" [vOther, vOtherCarrier] [])
                    (.and (.atom "st_lane_enters" [vOtherCarrier, vJunction] [])
                          (.derived "drv_road_opposed_approach_directions"
                             [vOtherCarrier, vTurnerCarrier] [pOppositeDirectionTolerance])))))
              (.cmp (.measure "st_region_geometry_distance" [vOther, vJunction])
                    .le (.mul (.measure "kin_speed" [vOther]) pImmediateHazardArrivalTime)))))

/-- t2: the yield of the first sentence, carried in full over the manoeuvre window behind. -/
def hasYielded : Formula :=
  .holdsFor .time pTurnWindow "turner"
    (.forallUser "other"
      (.implies immediateHazardToTurner (noPredictedConflict vTurner vOther)))

/-- t5: the subject is approaching that same junction on a carrier whose designated direction is
    opposed to the turner's approach. -/
def subjectApproachesOpposed : Formula :=
  .and (.derived "drv_position_approaching_intersection" [vSubject, vJunction] [])
    (.existsRegion (.lit "travel_region") "subject_carrier"
      (.and (.not (.same vSubjectCarrier vJunction))
        (.and (.atom "rel_occupies" [vSubject, vSubjectCarrier] [])
          (.and (.atom "st_lane_enters" [vSubjectCarrier, vJunction] [])
                (.derived "drv_road_opposed_approach_directions"
                   [vSubjectCarrier, vTurnerCarrier] [pOppositeDirectionTolerance])))))

/-- The turner's approach carrier: a travel region, not the junction itself, whose entrance end is
    that junction and whose overlap with the turner's footprint is current at some observation of
    the manoeuvre window behind. `φ` is read under that carrier. -/
def onTurnerApproach (φ : Formula) : Formula :=
  .existsRegion (.lit "travel_region") "turner_carrier"
    (.and (.not (.same vTurnerCarrier vJunction))
      (.and (.atom "st_lane_enters" [vTurnerCarrier, vJunction] [])
        (.and (.not (.holdsFor .time pTurnWindow "turner"
                      (.not (.atom "rel_occupies" [vTurner, vTurnerCarrier] []))))
              φ)))

/-- t2, t3, t4 and t5 on one other vehicle and one junction: the selection the obligation
    re-states. -/
def turnerSelection : Formula :=
  .and (.not (.same vTurner vSubject))
    (.and (isVehicle vTurner)
      (.and turnsLeftWithinJunction
        (.and (.rule "NRS_484B_413_2" [("subject", "turner")])
              (onTurnerApproach (.and hasYielded subjectApproachesOpposed)))))

/-- Applicability: t2 (condition): but such driver, having so yielded; t3 (condition): and having given a signal when and as required,; t4 (condition): may make such left turn and -/
def applicability : Formula :=
  .existsUser "turner" (.existsRegion (.lit "intersection") "junction" turnerSelection)

/-- Obligation: t6 (obligation): shall yield the right-of-way to the vehicle making the left turn. -/
def obligation : Formula :=
  .forallUser "turner"
    (.forallRegion (.lit "intersection") "junction"
      (.implies turnerSelection (noPredictedConflict vSubject vTurner)))

def rule : Rule :=
  { id := "NRS_484B_253_o2"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o2
