/-
  NRS_484B_250_2 — NRS-484B-250-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): When two vehicles enter an intersection from different highways
    s2 (standard): at approximately the same time,
    s3 (subject): the driver of the vehicle on the left
    s4 (obligation): shall yield the right-of-way to the vehicle on the right.
    s5 (reference): Except as otherwise provided in subsection 4 [NRS-484B-250-4],
    s6 (exception): this section does not apply at intersections controlled by official traffic-control devices
    s7 (exception): or to vehicles approaching each other from opposite directions,
    s8 (exception): when the driver of one of the vehicles is intending to
    s9 (exception): or is making a left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.on_way', 'st.highway'], derived ['drv.lane.enters_region']
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.bearing'], derived []
    s4: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived []
    s6: atoms ['dev.governs', 'dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.regulatory_sign', 'dev.lane_control_signal', 'st.intersection', 'rel.occupies'], derived []
    s7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.lane_enters', 'st.travel_region', 'st.lane_direction', 'rel.occupies', 'st.intersection'], derived ['drv.road.opposed_approach_directions']
    s9: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.leftward_course_change']

  Compositions (span → node, as, map):
    s5: NRS_484B_250_4_o1 as unless map {'subject': 'subject'} scopes s6
    s5: NRS_484B_250_4_o2 as unless map {'subject': 'subject'} scopes s6

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written
  ------------------------
  The intersection entered is not read as one of its own approach carriers (`approaches` states
  `c ≠ j`): `st.lane_enters` relates a carrier — a lane, roadway, one-way roadway, shoulder or
  bicycle lane or path the source records as a directed approach segment — to the intersection its
  entrance end lies at, and it is expressly not a stand-in for the subject's presence in that
  intersection. The exclusion restates the atom's contract and withholds nothing the span says.

  s1 — `entryPair`. The junction is a region quantified over `st.intersection` and tied to the
  subject by `drv.lane.enters_region` (the entry event) and `rel.occupies` (the footprint in it).
  "two vehicles" is the subject (binder class) and a second road user quantified over the scene's
  road users, `same` excluding the subject, each a member of the admitted aggregate
  `DEF-NRS-484A-320::vehicle` through `ru.aggregate`. "from different highways" is read through
  the approach each comes in on, exactly as `st.lane_enters` directs: a carrier the vehicle
  occupies (`rel.occupies`) whose entrance end is that junction (`st.lane_enters`), quantified
  over the abstract kind `st.travel_region`; the two carriers lie on different highways when some
  `st.highway` region the subject's carrier lies on (`st.on_way`) is one the other's carrier does
  not lie on. The carriers keep their own kind and only their ways are compared.

  s2 — `otherEntersWithinWindow`, the node's operationalization. The duty is read at the
  observation of the subject's entry; the second vehicle's entry into the same junction falls
  within `p.simultaneous_entry_window` of it, ahead (`within`) or behind (`atLast`). Both windows
  are windows of time, so the interval between the two entry observations is read from `kin.time`,
  as the operationalization states.

  s3 — `rel.bearing` of the other vehicle in the subject's own frame, side `right`: the subject is
  the vehicle on the left exactly where the other bears to its right. "the driver of" is the
  blueprint's observable reading (the vehicle's own conduct), already on its record.

  s4 — `noPredictedConflict`, under the blueprint's reading of the duty to yield: at the
  observations at which the duty applies the subject brings about no predicted conflict with the
  vehicle on its right — under the velocities observed at the instant the two centres do not
  approach within `p.yield_conflict_horizon` (`prim.closest_approach_within`), or the centre
  distance at their closest approach is at least `p.yield_min_clearance`
  (`prim.closest_approach_distance`). The obligation restates the whole selection of the junction
  (`st.intersection`, the entry, `rel.occupies`) and of the vehicle on the right, so that it
  speaks of the region and the vehicle the applicability selected, and owes the duty to every such
  vehicle, not to one of them.

  s5 + s6 — `deviceException`. The exception is the subject at a junction (`rel.occupies` on the
  `st.intersection` selected) which some traffic signal, stop sign, yield sign, regulatory sign or
  lane-control signal is recorded as governing (`dev.governs`, read as control of the junction
  itself, each device kind quantified over separately). The two `unless` compositions of
  NRS-484B-250-4 are conjoined into this exception, the span they scope, as
  `.not (.ruleApplies …)`: where either node of subsection 4 applies to the subject, the
  exception does not hold and the applicability is untouched elsewhere.

  s7 + s8 + s9 — `oppositeDirectionException`. The two approach carriers are read again as in s1
  (`rel.occupies`, `st.lane_enters`, `st.travel_region`) and their designated directions are
  opposed through `drv.road.opposed_approach_directions` with `p.opposite_direction_tolerance`;
  s8 is the declared intention `int.left_turn` of either vehicle at that junction, read at the
  judged observation, and s9 is the manoeuvre itself,
  `drv.motion.leftward_course_change` of either vehicle.

  The reading chosen here (declared as a narrowing on s4)
  ------------------------------------------------------
  s4's "while the two are in or at the junction", which the blueprint's reading of the yield
  anchors with `rel.occupies` and `st.intersection`, is written as the subject's own footprint
  overlapping that junction at the observation judged, the vehicle on the right being the one
  whose entry into the same junction falls inside the simultaneity window: the duty is owed at the
  subject's entry, and the other vehicle is at the junction by that entry, whether its own entry
  is that observation, earlier or later within the window.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The variables the formulas quantify: the second vehicle, the junction, the two approach
    carriers, a public way, a device. -/
def vOther : Arg := .var "other"
def vJunction : Arg := .var "junction"
def vSubjectApproach : Arg := .var "subjectApproach"
def vOtherApproach : Arg := .var "otherApproach"
def vWay : Arg := .var "way"
def vDevice : Arg := .var "device"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pOppositeDirectionTolerance : Term := .param "p.opposite_direction_tolerance"
def pSimultaneousEntryWindow : Term := .param "p.simultaneous_entry_window"
def pTurnMaxCourseChange : Term := .param "p.turn_max_course_change"
def pTurnMinCourseChange : Term := .param "p.turn_min_course_change"
def pTurnWindow : Term := .param "p.turn_window"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Membership of the admitted aggregate the node claims. -/
def isVehicle (who : Arg) : Formula :=
  .atom "ru_aggregate" [who, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1, s2: the road user's footprint first overlaps the region at this observation. -/
def entersRegion (who r : Arg) : Formula := .derived "drv_lane_enters_region" [who, r] []

/-- s1, s7: `c` is the approach carrier `who` comes in on — a carrier it occupies whose entrance
    end is the junction `j`. The junction is not among its own approaches: `st.lane_enters` holds
    of a lane, roadway, one-way roadway, shoulder or bicycle lane or path the source records as a
    directed approach segment, never of the intersection the segment runs into, and a region the
    source records no approach for leaves the relation unknown. -/
def approaches (who c j : Arg) : Formula :=
  .and (.not (.same c j))
    (.and (.atom "rel_occupies" [who, c] []) (.atom "st_lane_enters" [c, j] []))

/-- s1: the two approach carriers lie on different highways — some way the subject's carrier lies
    on is one the other's carrier does not. -/
def differentHighways : Formula :=
  .existsRegion (.lit "travel_region") "subjectApproach"
    (.and (approaches vSubject vSubjectApproach vJunction)
      (.existsRegion (.lit "travel_region") "otherApproach"
        (.and (approaches vOther vOtherApproach vJunction)
          (.existsRegion (.lit "highway") "way"
            (.and (.atom "st_on_way" [vSubjectApproach, vWay] [])
                  (.not (.atom "st_on_way" [vOtherApproach, vWay] [])))))))

/-- s2 (the node's operationalization): the other vehicle's entry into the same junction lies
    within the simultaneity window of this observation, ahead of it or behind it. -/
def otherEntersWithinWindow : Formula :=
  .or (.within .time pSimultaneousEntryWindow "subject" (entersRegion vOther vJunction))
      (.atLast .time pSimultaneousEntryWindow "subject" (entersRegion vOther vJunction) .tt)

/-- s6: a device of the given kind is recorded as governing the junction. -/
def governsJunction (kind : String) : Formula :=
  .existsDevice (.lit kind) "device" (.atom "dev_governs" [vDevice, vJunction] [])

/-- s6, scoped by the two `unless` compositions of s5. -/
def deviceException : Formula :=
  .and (.atom "rel_occupies" [vSubject, vJunction] [])
    (.and
      (.or (governsJunction "traffic_signal")
        (.or (governsJunction "stop_sign")
          (.or (governsJunction "yield_sign")
            (.or (governsJunction "regulatory_sign") (governsJunction "lane_control_signal")))))
      (.and (.not (.ruleApplies "NRS_484B_250_4_o1" [("subject", "subject")]))
            (.not (.ruleApplies "NRS_484B_250_4_o2" [("subject", "subject")]))))

/-- s7: the two approach carriers carry opposed designated directions. -/
def opposedApproaches : Formula :=
  .existsRegion (.lit "travel_region") "subjectApproach"
    (.and (approaches vSubject vSubjectApproach vJunction)
      (.existsRegion (.lit "travel_region") "otherApproach"
        (.and (approaches vOther vOtherApproach vJunction)
          (.derived "drv_road_opposed_approach_directions" [vSubjectApproach, vOtherApproach]
            [pOppositeDirectionTolerance]))))

/-- s9: the vehicle is making a change of course to the left. -/
def makingLeftTurn (who : Arg) : Formula :=
  .derived "drv_motion_leftward_course_change" [who]
    [pTurnWindow, pTurnMinCourseChange, pTurnMaxCourseChange, pMotionSpeedTolerance]

/-- s8 ∨ s9, of either of the two vehicles. -/
def leftTurnOfEither : Formula :=
  .or (.or (.intent "int.left_turn" vSubject vJunction) (.intent "int.left_turn" vOther vJunction))
      (.or (makingLeftTurn vSubject) (makingLeftTurn vOther))

/-- s7 + s8 + s9. -/
def oppositeDirectionException : Formula := .and opposedApproaches leftTurnOfEither

/-- s1 + s2 + s3: the junction, the second vehicle and the entries the subsection speaks of, with
    `inner` read of that pair at that junction. -/
def entryPair (inner : Formula) : Formula :=
  .existsRegion (.lit "intersection") "junction"
    (.and (entersRegion vSubject vJunction)
      (.and (.atom "rel_occupies" [vSubject, vJunction] [])
        (.existsUser "other"
          (.and (.not (.same vOther vSubject))
            (.and (isVehicle vOther)
              (.and (.atom "rel_bearing" [vSubject, vOther, .lit "right"] [])
                (.and differentHighways
                  (.and otherEntersWithinWindow inner))))))))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- Applicability: s1 (trigger): When two vehicles enter an intersection from different highways; s6 (exception): this section does not apply at intersections controlled by official traffic-control devices; s7 (exception): or to vehicles approaching each other from opposite directions,; s8 (exception): when the driver of one of the vehicles is intending to; s9 (exception): or is making a left turn. -/
def applicability : Formula :=
  entryPair (.and (.not deviceException) (.not oppositeDirectionException))

/-- s4: the subject brings about no predicted conflict with the vehicle on its right. -/
def noPredictedConflict : Formula :=
  .or (.not (.derived "prim_closest_approach_within" [vSubject, vOther] [pYieldConflictHorizon]))
      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pYieldConflictHorizon])
            .ge pYieldMinClearance)

/-- Obligation: s2 (standard): at approximately the same time,; s4 (obligation): shall yield the right-of-way to the vehicle on the right. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "junction"
    (.implies
      (.and (entersRegion vSubject vJunction) (.atom "rel_occupies" [vSubject, vJunction] []))
      (.forallUser "other"
        (.implies
          (.and (.not (.same vOther vSubject))
            (.and (isVehicle vOther)
              (.and (.atom "rel_bearing" [vSubject, vOther, .lit "right"] [])
                (.and differentHighways otherEntersWithinWindow))))
          noPredictedConflict)))

def rule : Rule :=
  { id := "NRS_484B_250_2"
    laws := ["NRS-484B-250-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "at approximately the same time"
          concepts := ["drv.lane.enters_region", "kin.time", "rel.occupies", "st.intersection"]
          params := ["p.simultaneous_entry_window"]
          convention := "simultaneity convention of junction conflict analysis: two entries into one junction count as made at approximately the same time when the interval between the two entry observations, read from kin.time, is at most the window, set to the time a passenger car takes to clear a junction from its entry at ordinary entry speed, since entries farther apart than that leave no conflict to resolve"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s4"
          why := "\"while the two are in or at the junction\", with which the record's reading of the yield anchors the duty (rel.occupies on the st.intersection entered), is written as the subject's own footprint overlapping that junction at the observation judged, the vehicle on the right being the one whose entry into the same junction falls inside the simultaneity window: the duty is owed at the subject's entry, and the other vehicle counts as at the junction by that entry, whether it enters at that observation, earlier or later within the window, rather than by occupying the junction at the same observation."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_2
