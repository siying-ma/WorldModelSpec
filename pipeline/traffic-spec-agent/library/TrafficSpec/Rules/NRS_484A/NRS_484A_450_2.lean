/-
  NRS_484A_450_2 — NRS-484A-450-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every driver of a vehicle
    s2 (trigger): approaching a stop intersection indicated by a stop sign
    s3 (obligation): shall stop before entering the crosswalk on the near side of the intersection
    s4 (condition): or, if there is no crosswalk, shall stop at a clearly marked stop line,
    s5 (condition): or if none, then at the point nearest the intersecting highway
    s6 (standard): where the driver has a view
    s7 (condition): of approaching traffic on the intersecting highway
    s8 (condition): before entering the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['dev.stop_sign', 'dev.governs', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'rel.occupies'], derived []
    s3: atoms ['st.crosswalk', 'st.entrance_of', 'st.intersection', 'rel.occupies', 'st.region_geometry', 'prim.region_offset_along'], derived ['drv.motion.halted']
    s4: atoms ['st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'rel.occupies', 'st.region_geometry', 'prim.region_offset_along'], derived ['drv.motion.halted']
    s5: atoms ['st.stop_line', 'st.entrance_of', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'rel.occupies', 'st.highway'], derived []
    s7: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'st.sight_along_way', 'st.highway', 'rel.occupies'], derived []
    s8: atoms ['st.intersection', 'rel.occupies'], derived ['drv.lane.enters_region']

  How each span is written.

  s1 — `clsSubject`: the admitted aggregate as the one atom `ru_aggregate` of the binder with the
  aggregate's id as its literal argument. The record's observable reading of "driver of" (the
  vehicle's own controlled motion) is the plan's and is not restated in `narrowings`.

  s2 — `carrierSelected` / `junctionSelected`: a junction is an `existsRegion (.lit "intersection")`
  (st.intersection, the whole extent the kind gives the word); the approach is a travel region
  (`existsRegion (.lit "travel_region")`, st.travel_region) other than the junction itself
  (`same`: a carrier is an approach to a junction, never that junction), whose footprint the
  subject overlaps (`rel_occupies`) and whose entrance end the source records as that junction
  (`st_lane_enters`); the sign is an `existsDevice (.lit "stop_sign")` (dev.stop_sign) governing
  that carrier or the junction itself (`dev_governs`, the record's disjunction). Nothing of the
  subject's place or motion is added: the applicability does not require the subject to be off the
  junction, since the duty is decided at exactly the observation at which it enters.

  s8 — `entersJunction`: `drv.lane.enters_region` of the subject into that junction, the event the
  closing words name. The duty is judged at that observation and nowhere else: the obligation is
  `implies` of this event, so an observation at which no entry occurs meets it.

  s3, s4, s5 — the place cascade, read on the carrier s2 binds. Each place is a pair: the halt at
  the place (`haltAtCrossing`, `haltAtLine`, `haltInView`) and the start of the approach to that
  place (`startOfCrossingApproach`, `startOfLineApproach`, `startOfViewApproach`), the observation
  at which the subject lay outside that place upstream. The act is `drv.motion.halted` with
  p.motion_speed_tolerance (s3's narrowing in the record). The place conditions on a mark are the
  record's three, in this order: the footprint off the mark (`rel_occupies`), the body within
  p.stop_point_tolerance of it (`st_region_geometry_distance`) and the mark ahead along the
  carrier's designated direction (`prim_region_offset_along` positive); upstream is the same with
  the distance beyond the tolerance. Where several marks of the governing kind mark the carrier the
  conditions are required of each (`forallRegion` over the kind, guarded by `st_entrance_of`).
  The cascade's order is the words' order and its guards are the completeness clause of
  st.entrance_of: `noCrossingMarksCarrier` is true only where every crosswalk's entrances are
  observed and none lists the carrier, so where that association is unobserved the guard is
  unknown and the duty with it. Place (3), which no region of the scene carries, is the approach
  off the junction from which the view along a highway region (st.highway) reaches
  p.intersection_view_sight_distance (s6, s7).

  The history bound — `haltFoundAtCrossing`, `haltFoundAtLine`, `haltFoundInView`: the search back
  from the entry is `since (¬end) halt`, which finds the halt where one lies between now and the
  end of the search, is false where it reaches the end without one, and is unknown only where it
  reaches the first observation of the recording. The end is the record's two and nothing else:
  the start of the approach to the governing place (above) or the previous entry of the same
  subject into that junction (`previousStay`). No window, no distance travelled and no boundary
  taken from the recording's start enters the search.

  s6 — the standard, `viewAlongWay`: st.sight_along_way from the subject along a highway region at
  least p.intersection_view_sight_distance. The bound is read at the halting observation and, as
  the record's narrowing on s6 states, along the way the halt is read against: the way is bound
  outside the search (`existsRegion (.lit "highway")`), so the view that counts for the halt and
  the view that measures the upstream stretch are the view along one and the same way.

  s7 — the view's object: st.sight_along_way is the quantity that carries "within which another
  vehicle on that way could be seen", read along st.highway, with `rel_occupies` anchoring the
  subject on the carrier the view is read from. The aggregate DEF-NRS-484A-285::traffic the record
  claims on this span carries no part of the formulas: the standard is a length of view, which the
  ontology reads whether or not a road user is there, and the record's own narrowing on s6 says the
  view of the aggregate's other members "is not separately read". The claim is reported in
  task_result.md as a defect of the node's mapping, not written into the rule as a condition on
  actual traffic, which st.sight_along_way's exclusion ("not … whether an actual road user is
  seen") forbids.

  Narrowings declared below, both on s3, the obligation's span (the record's own narrowings, its
  observable readings included, are not restated):
  - several carriers: the duty is read through each selected carrier (`forallRegion`), so where the
    verdict differs between them and one of them is violated the duty is violated, where the record
    would leave it unknown; the language has no operator that reports unknown for a disagreement
    among decided branches, and the carrier that favours the subject is never the one read;
  - the previous entry: read as an observation at which the subject's footprint overlapped the
    junction and which was not itself the entry judged (`¬drv.lane.enters_region`), so a previous
    stay of a single observation does not end the search and the search runs on behind it.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484A_450_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The regions and devices the formulas quantify over, each anchored to the subject. -/
def vJunction : Arg := .var "junction"
def vCarrier : Arg := .var "carrier"
def vSign : Arg := .var "sign"
def vCrossing : Arg := .var "crossing"
def vLine : Arg := .var "line"
def vWay : Arg := .var "way"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pIntersectionViewSightDistance : Term := .param "p.intersection_view_sight_distance"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2, s5, s7: the subject's footprint overlaps the approach carrier. -/
def onCarrier : Formula := .atom "rel_occupies" [vSubject, vCarrier] []

/-- s5, s8: the subject's footprint overlaps the junction. -/
def inJunction : Formula := .atom "rel_occupies" [vSubject, vJunction] []

/-- s2: the stop sign governs this approach, or the junction itself. -/
def signGovernsApproach : Formula :=
  .or (.atom "dev_governs" [vSign, vCarrier] []) (.atom "dev_governs" [vSign, vJunction] [])

/-- s2: a travel region, other than the junction, that the subject occupies, whose entrance end
    the source records as that junction, and whose traffic a stop sign controls. -/
def carrierSelected : Formula :=
  .and (.not (.same vCarrier vJunction))
    (.and onCarrier
      (.and (.atom "st_lane_enters" [vCarrier, vJunction] [])
            (.existsDevice (.lit "stop_sign") "sign" signGovernsApproach)))

/-- s2: the junction this subject approaches through such a carrier. -/
def junctionSelected : Formula :=
  .existsRegion (.lit "travel_region") "carrier" carrierSelected

/-- Applicability: s2 (trigger): approaching a stop intersection indicated by a stop sign -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "junction" junctionSelected

/-- s3, s4: the act — the subject's body stands still at this observation. -/
def halted : Formula := .derived "drv_motion_halted" [vSubject] [pMotionSpeedTolerance]

/-- s8: the event the duty is judged at. -/
def entersJunction : Formula := .derived "drv_lane_enters_region" [vSubject, vJunction] []

/-- s3, s4: the mark marks this carrier's entrance. -/
def marksCarrier (mark : Arg) : Formula := .atom "st_entrance_of" [mark, vCarrier] []

/-- s3, s4: the subject stands at the mark — off it, within the stop-point tolerance of it, and
    with it ahead along the carrier's designated direction. -/
def atMark (mark : Arg) : Formula :=
  .and (.not (.atom "rel_occupies" [vSubject, mark] []))
    (.and (.cmp (.measure "st_region_geometry_distance" [vSubject, mark]) .le pStopPointTolerance)
          (.cmp (.quantity "prim_region_offset_along" [vSubject, mark, vCarrier] []) .gt zeroMetres))

/-- s3, s4: the subject lies outside the mark upstream — off it, short of it along the carrier's
    designated direction, and farther from it than the stop-point tolerance. -/
def upstreamOfMark (mark : Arg) : Formula :=
  .and (.not (.atom "rel_occupies" [vSubject, mark] []))
    (.and (.cmp (.measure "st_region_geometry_distance" [vSubject, mark]) .gt pStopPointTolerance)
          (.cmp (.quantity "prim_region_offset_along" [vSubject, mark, vCarrier] []) .gt zeroMetres))

/-- s8: the stay a previous entry of the same subject into that junction began. -/
def previousStay : Formula := .and inJunction (.not entersJunction)

/-- s3: the halt at the crosswalks that mark this carrier's entrance. -/
def haltAtCrossing : Formula :=
  .and halted
    (.and onCarrier
      (.forallRegion (.lit "crosswalk") "crossing"
        (.implies (marksCarrier vCrossing) (atMark vCrossing))))

/-- s3: the start of the approach to those crosswalks. -/
def startOfCrossingApproach : Formula :=
  .and onCarrier
    (.forallRegion (.lit "crosswalk") "crossing"
      (.implies (marksCarrier vCrossing) (upstreamOfMark vCrossing)))

/-- s3, s8: the search back from the entry for the halt at the crossing. -/
def haltFoundAtCrossing : Formula :=
  .since (.not (.or previousStay startOfCrossingApproach)) haltAtCrossing

/-- s4: the halt at the stop lines that mark this carrier's entrance. -/
def haltAtLine : Formula :=
  .and halted
    (.and onCarrier
      (.forallRegion (.lit "stop_line") "line"
        (.implies (marksCarrier vLine) (atMark vLine))))

/-- s4: the start of the approach to those stop lines. -/
def startOfLineApproach : Formula :=
  .and onCarrier
    (.forallRegion (.lit "stop_line") "line"
      (.implies (marksCarrier vLine) (upstreamOfMark vLine)))

/-- s4, s8: the search back from the entry for the halt at the line. -/
def haltFoundAtLine : Formula :=
  .since (.not (.or previousStay startOfLineApproach)) haltAtLine

/-- s6, s7: the view along that way is at least the intersection view sight distance. -/
def viewAlongWay : Formula :=
  .cmp (.measure "st_sight_along_way" [vSubject, vWay]) .ge pIntersectionViewSightDistance

/-- s5, s6: the halt at the point of the approach, off the junction, from which the subject has
    the view along the intersecting highway. -/
def haltInView : Formula :=
  .and halted (.and onCarrier (.and (.not inJunction) viewAlongWay))

/-- s5, s6: the start of the approach to that point — on the carrier, off the junction, the view
    along that highway still shorter than the sight distance. -/
def startOfViewApproach : Formula :=
  .and onCarrier (.and (.not inJunction) (.not viewAlongWay))

/-- s5, s6, s8: the search back from the entry for the halt at the place the view identifies, read
    along one highway region. -/
def haltFoundInView : Formula :=
  .existsRegion (.lit "highway") "way"
    (.since (.not (.or previousStay startOfViewApproach)) haltInView)

/-- s3, s4: no crosswalk marks this carrier's entrance, the crosswalks' entrances being observed. -/
def noCrossingMarksCarrier : Formula :=
  .forallRegion (.lit "crosswalk") "crossing" (.not (marksCarrier vCrossing))

/-- s4, s5: no stop line marks this carrier's entrance, the lines' entrances being observed. -/
def noLineMarksCarrier : Formula :=
  .forallRegion (.lit "stop_line") "line" (.not (marksCarrier vLine))

/-- s3, s4, s5: the cascade in the words' order — the crossing where one marks the carrier, else
    the line where the crosswalks' entrances are observed and none marks it, else the place the
    view identifies where the lines' entrances are observed and none marks it either. -/
def haltedAtGoverningPlace : Formula :=
  .and (.implies (.not noCrossingMarksCarrier) haltFoundAtCrossing)
    (.and (.implies (.and noCrossingMarksCarrier (.not noLineMarksCarrier)) haltFoundAtLine)
          (.implies (.and noCrossingMarksCarrier noLineMarksCarrier) haltFoundInView))

/-- Obligation: s3 (obligation): shall stop before entering the crosswalk on the near side of the intersection; s6 (standard): where the driver has a view -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "junction"
    (.implies (.and junctionSelected entersJunction)
      (.forallRegion (.lit "travel_region") "carrier"
        (.implies carrierSelected haltedAtGoverningPlace)))

def rule : Rule :=
  { id := "NRS_484A_450_2"
    laws := ["NRS-484A-450-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "has a view"
          concepts := ["st.highway", "st.sight_along_way"]
          params := ["p.intersection_view_sight_distance"]
          convention := "intersection-sight-distance model. How much view is a view is what the words leave open, and the bound is the length of view the subject has along the intersecting way at the halting observation: st.sight_along_way, “the distance along a way, in each direction from the point of that way nearest a road user, within which another vehicle on that way could be seen from the road user's eye at the observation … the smaller of the two directions”, read along the highway region s7 names (st.highway) and required to be at least p.intersection_view_sight_distance, the departure sight distance a passenger car entering a two-lane highway at ordinary arterial speed needs (AASHTO Green Book intersection sight distance, Case B). The bound moves with the quantity it is compared against — the longer the view the source reports, the plainer the view the words require — and it bounds one element of the duty, the third of the places the words list, not the duty itself: the act, its place and its timing are stated by s3, s4, s5 and s8, so the node is not a surrogate."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "Where the subject occupies several carriers whose entrance end is that junction, the duty is read through each of them (`forallRegion` over the selected carriers), so where the verdict differs between them and one is violated the duty is violated, where the record's words would leave which carrier governs unknown: the formula language has no operator that reports unknown for a disagreement among decided branches. The reading is the one that never picks the carrier favouring the subject; an unobserved association still leaves the duty unknown, since that branch is itself unknown."
          kind := "reading" }
      , { span := "s3"
          why := "“the previous entry of the same subject into i”, the second end of the search back from the entry, is read as an observation at which the subject's footprint overlapped the junction and which was not itself the entry judged (`rel.occupies` of the junction and not `drv.lane.enters_region`). A previous stay the recording shows at one observation only therefore does not end the search, which runs on behind it to the start of the approach or to the first observation of the recording; every stay of two observations or more ends it, as the record requires."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484A_450_2
