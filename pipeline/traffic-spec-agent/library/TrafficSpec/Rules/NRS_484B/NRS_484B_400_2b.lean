/-
  NRS_484B_400_2b — NRS-484B-400-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    i1 (subject): If the driver of a vehicle
    i2 (condition): intends to turn
    i3 (condition): at an intersection and:
    i4 (condition): Both intersecting highways are two-directional:
    i5 (trigger): After entering the intersection,
    i6 (obligation): the left turn must be made so as to leave the intersection to the right of the centerline of the highway being entered.

  Elements (span → atoms, derived):
    i1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    i3: atoms ['st.intersection', 'rel.occupies'], derived []
    i4: atoms ['st.highway', 'st.on_way', 'st.intersection'], derived ['drv.road.two_directional_way']
    i5: atoms ['rel.occupies', 'st.intersection'], derived ['drv.lane.enters_region']
    i6: atoms ['rel.occupies', 'st.intersection', 'st.centre_line', 'st.highway', 'st.on_way', 'st.roadway', 'st.lane_enters', 'st.travel_region', 'prim.region_lateral_offset', 'ru.aggregate=DEF-NRS-484A-320::vehicle']
        derived ['drv.motion.leftward_course_change', 'drv.lane.exits_region']

  How each span is written.

  i1 — `clsSubject`: the admitted aggregate, as the one atom `ru_aggregate` of the binder with the
  aggregate's id as its literal argument. The record's observable reading of "the driver of" (the
  vehicle's controlled motion) is the plan's and is not restated in `narrowings`.

  i2 — `intendsLeftTurnThere`: the declaration current at the judged observation, `int.left_turn`
  of the subject at the junction i3 binds. Read at the judged observation and never ahead of it.

  i3 — `occupiesJunction` under `existsRegion (.lit "intersection") "junction"`: the quantifier's
  kind is `st.intersection` (the whole extent the kind gives the word) and `rel.occupies` anchors
  the subject at that junction. The same junction is the region i5's entry event and i6's
  departure event are read on, so the obligation re-selects it with this whole selection again
  (`atSuchJunction`), under a `forallRegion`: the duty is owed at each junction the applicability
  selects.

  i4 — `intersectingWaysTwoDirectional`: for every highway the junction lies on (`st.on_way`,
  "an intersection lies on every way that meets there", the quantifier's kind `st.highway`), the
  co-proposed `drv.road.two_directional_way` holds of it, with the reading's opposition tolerance.
  The condition is read at the observation at which the act is recognized, as the occasion directs.

  i5 — `hasEnteredJunction`: the entry event `drv.lane.enters_region` on that junction, read over
  the window behind the judged observation that the occasion gives the act (`p.turn_window`): the
  entry lies at or before the observation at which the turn is recognized, within the window over
  which the act's course change is itself taken. The bound is the occasion's own window, not a
  bound of this file's choosing; no other operator of the language states "at or before" without
  reaching past the start of the recording, where nothing is observed.

  i6 — the obligation. The act is `drv.motion.leftward_course_change` with the reading's window and
  course-change bounds; the occasion reads the act as an event, so the applicability carries
  `.rises` of it and each turn is judged once, at its recognition. The occasion's `under_way`
  element (`drv.motion.turning` over `kin.yaw_rate`, with the reading's yaw-rate tolerance) is
  conjoined there: the observation judged is an observation inside the act, which the subject's own
  motion tells from one before the act began, and i3, i4 and i5 are read at it, as the occasion's
  `at_recognition` directs. The duty itself is read at the
  departure: there is no observation in the window ahead at which the subject's footprint ceases to
  overlap that junction (`drv.lane.exits_region`) while the centreline of the highway being entered
  fails to lie to its left. The highway being entered is a highway (quantifier kind `st.highway`)
  other than the one the subject's approach carrier lies on (`same`), on which lies a region the
  subject occupies at the departure that is a roadway (`st.roadway`, the improved part it travels
  on) among the travel regions (quantifier kind `st.travel_region`), by `st.on_way`. The approach
  carrier is a travel region whose entrance end is that junction (`st.lane_enters`) and that the
  subject's footprint overlaps; its highway is read by `st.on_way`. "To the right of the
  centerline" is the subject's own left: for every centreline (`st.centre_line`) on the highway
  being entered, `prim.region_lateral_offset` of that centreline from the subject is positive
  (left positive).

  Narrowings declared below, both on i6, the obligation's span:
  - the departure is read in the window ahead that the occasion gives the act, so a subject that
    has not left the junction within that window is not judged;
  - "its approach carrier" is read as a carrier whose entrance end is that junction and whose
    overlap with the subject's footprint is current at some observation in the occasion's window
    behind the judged observation.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_2b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The regions the formulas quantify over, each anchored to the subject. -/
def vJunction : Arg := .var "junction"
def vWay : Arg := .var "way"
def vApproachWay : Arg := .var "approach_way"
def vEnteredWay : Arg := .var "entered_way"
def vApproachCarrier : Arg := .var "approach_carrier"
def vDepartureRegion : Arg := .var "departure_region"
def vCentreLine : Arg := .var "centre_line"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pOppositeDirectionTolerance : Term := .param "p.opposite_direction_tolerance"
def pTurnMaxCourseChange : Term := .param "p.turn_max_course_change"
def pTurnMinCourseChange : Term := .param "p.turn_min_course_change"
def pTurnWindow : Term := .param "p.turn_window"
def pYawRateTolerance : Term := .param "p.yaw_rate_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- i6's act: the change of course to the left, with the reading's window and bounds. -/
def makesLeftwardCourseChange : Formula :=
  .derived "drv_motion_leftward_course_change" [vSubject]
    [pTurnWindow, pTurnMinCourseChange, pTurnMaxCourseChange, pMotionSpeedTolerance]

/-- The occasion's `under_way` element: at this observation the subject's body is turning to one
    hand or the other, read from its rate of change of heading above the reading's resolution. The
    judged observation is an observation inside the act, which the subject's own motion tells from
    one before the act began. -/
def turnUnderWay : Formula := .derived "drv_motion_turning" [vSubject] [pYawRateTolerance]

/-- i3: the subject's footprint overlaps that junction. -/
def occupiesJunction : Formula := .atom "rel_occupies" [vSubject, vJunction] []

/-- i2: the declaration current here is a turn to the left at that junction. -/
def intendsLeftTurnThere : Formula := .intent "int.left_turn" vSubject vJunction

/-- i4: every highway the junction lies on is two-directional. -/
def intersectingWaysTwoDirectional : Formula :=
  .forallRegion (.lit "highway") "way"
    (.implies (.atom "st_on_way" [vJunction, vWay] [])
              (.derived "drv_road_two_directional_way" [vWay] [pOppositeDirectionTolerance]))

/-- i5: the subject entered that junction at or before this observation, within the window the
    occasion gives the act. -/
def hasEnteredJunction : Formula :=
  .not (.holdsFor .time pTurnWindow "subject"
    (.not (.derived "drv_lane_enters_region" [vSubject, vJunction] [])))

/-- i2, i3, i4 and i5 on one junction: the selection the obligation re-states. -/
def atSuchJunction : Formula :=
  .and occupiesJunction
    (.and intendsLeftTurnThere
      (.and intersectingWaysTwoDirectional hasEnteredJunction))

/-- Applicability: i2 (condition): intends to turn; i3 (condition): at an intersection and:; i4 (condition): Both intersecting highways are two-directional:; i5 (trigger): After entering the intersection, -/
def applicability : Formula :=
  .and (.rises makesLeftwardCourseChange)
    (.and turnUnderWay
      (.existsRegion (.lit "intersection") "junction" atSuchJunction))

/-- i6: the highway the subject's approach carrier to that junction lies on. -/
def approachCarrierOnWay : Formula :=
  .not (.holdsFor .time pTurnWindow "subject"
    (.not (.existsRegion (.lit "travel_region") "approach_carrier"
      (.and (.not (.same vApproachCarrier vJunction))
        (.and (.atom "rel_occupies" [vSubject, vApproachCarrier] [])
          (.and (.atom "st_lane_enters" [vApproachCarrier, vJunction] [])
                (.atom "st_on_way" [vApproachCarrier, vApproachWay] [])))))))

/-- i6: every centreline of the highway being entered lies to the subject's left. -/
def centreLineToTheLeft : Formula :=
  .forallRegion (.lit "centre_line") "centre_line"
    (.implies (.atom "st_on_way" [vCentreLine, vEnteredWay] [])
              (.cmp (.quantity "prim_region_lateral_offset" [vSubject, vCentreLine] [])
                    .gt zeroMetres))

/-- i6: the subject occupies, at the departure, a roadway lying on that highway. -/
def departsOnWay : Formula :=
  .existsRegion (.lit "travel_region") "departure_region"
    (.and (.atom "st_roadway" [vDepartureRegion] [])
      (.and (.atom "rel_occupies" [vSubject, vDepartureRegion] [])
            (.atom "st_on_way" [vDepartureRegion, vEnteredWay] [])))

/-- i6: at the departure, the centreline of the highway being entered — the highway, other than
    the approach carrier's, that the region the subject then occupies lies on — is to its left. -/
def leavesRightOfCentreLine : Formula :=
  .forallRegion (.lit "highway") "entered_way"
    (.implies (.and (.not (.same vEnteredWay vApproachWay)) departsOnWay)
              centreLineToTheLeft)

/-- Obligation: i6 (obligation): the left turn must be made so as to leave the intersection to the right of the centerline of the highway being entered. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "junction"
    (.implies atSuchJunction
      (.forallRegion (.lit "highway") "approach_way"
        (.implies approachCarrierOnWay
          (.not (.within .time pTurnWindow "subject"
            (.and (.derived "drv_lane_exits_region" [vSubject, vJunction] [])
                  (.not leavesRightOfCentreLine)))))))

def rule : Rule :=
  { id := "NRS_484B_400_2b"
    laws := ["NRS-484B-400-2b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "i6"
          why := "the departure from the junction is read in the window ahead of the judged observation that the occasion gives the act (`p.turn_window`): the duty is broken by a departure, inside that window, at which the centreline of the highway being entered does not lie to the subject's left, and a subject that has not left the junction within that window is not judged."
          kind := "reading" }
      , { span := "i6"
          why := "\"its approach carrier\" is read as a travel region whose entrance end is that junction (`st.lane_enters`) and whose overlap with the subject's footprint is current at some observation in the occasion's window behind the judged observation; where the source records no such carrier, the words name no highway being entered and the duty is not judged."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_400_2b
