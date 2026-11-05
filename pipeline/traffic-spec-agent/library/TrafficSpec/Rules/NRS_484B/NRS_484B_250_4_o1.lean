/-
  NRS_484B_250_4_o1 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): When a vehicle enters an intersection
    s2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,
    s3 (subject): the driver of the vehicle
    s4 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    s5 (sibling): After making such a stop,
    s6 (sibling): the driver shall proceed cautiously,
    s7 (sibling): yielding to vehicles which have previously completed a stop or are within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'rel.occupies'], derived ['drv.lane.enters_region']
    s2: atoms ['dev.traffic_signal', 'dev.inoperative', 'dev.governs', 'st.intersection'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'rel.occupies', 'st.region_geometry', 'prim.region_offset_along', 'st.sight_along_way', 'st.highway', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.halted', 'drv.lane.enters_region']

  How each span is written.

  s1 + s2 (applicability). `clsSubject` is the admitted aggregate under its id. The applicability
  binds the junction with `existsRegion "intersection" "i"`, requires the entry event
  `drv.lane.enters_region subject i` (the crossing of the boundary, not presence), and requires a
  signal head governing that junction which is uncovered and inoperative
  (`existsDevice "traffic_signal"`, `dev_governs d i`, `dev_traffic_signal_uncovered`,
  `dev_inoperative`). Reading the three device facts at the entry observation is what "at the time
  the vehicle enters the intersection" says: all four leaves are conjoined at the judged instant.
  s3 carries no fact of its own beyond the class (the plan's agency narrowing).

  s4 (obligation). The obligation re-selects the junction with the whole of the applicability's
  selection (`forallRegion "intersection"`, the entry and the governing inoperative signal), then
  the approach: a travel region `c` the subject occupies whose entrance end is that junction
  (`rel_occupies`, `st_lane_enters`), the junction itself excluded (`same`: an intersection is no
  approach carrier of itself). The duty is required through every such carrier.

  The duty is one search into the past, `count … ≥ 1`: a rising edge of "halted at the governing
  place" since the start of the latest run of observations at which the subject lay outside that
  place's stopping zone upstream, or was in the junction on an earlier visit. The place and the
  zone are the same cascade, in the words' order:
    (1) a stop line `st.entrance_of` records as marking `c` — halted with the body short of the
        line (sign of `prim.region_offset_along` along `c`'s direction) and within
        `p.stop_point_tolerance` of it (`st.region_geometry`);
    (2) where no stop line marks `c`, a crosswalk it records as marking `c` — halted short of it
        with the footprint not yet overlapping it;
    (3) where neither marks `c`, halted short of the junction's entrance end where the sight along
        the intersecting highway (`st.sight_along_way` on `st.highway`) is at least
        `p.intersection_view_sight_distance`.
  The zone upstream of a mark is: on `c`, off the mark, short of it, and farther from it than
  `p.stop_point_tolerance` — of every mark of that kind that marks `c` (`forallRegion`); upstream
  of the view place it is: on `c`, short of the junction, without the view. "halted" is
  `drv.motion.halted` with `p.motion_speed_tolerance`.

  Readings I chose on s4, declared in `narrowings` below:
    (a) the search back is the `count` operator over the run of observations outside the governing
        place's stopping zone: where that run reaches the recording's first observation the source
        cannot show that the approach began within the recording, and the duty is unknown rather
        than decided. No boundary is taken from the recording's start: the recording's start
        decides nothing, it only withholds a decision.
    (b) the second end of the search, "the previous entry of the same subject into i", is read as
        an observation at which the subject was in that junction and was not entering it there.
    (c) "the point nearest the intersection where the driver has a view" is read as any place short
        of the junction's entrance end at which that view exists, not only the nearest such place.
    (d) "the through highway" is read as every highway region along which the source reports the
        subject's sight (`forallRegion "highway"`): the record claims no relation tying a highway to
        the junction, and the duty is never read through the way that favours the subject.
    (e) where the subject occupies several carriers entering the junction, the duty is read as
        required through each of them.
    (f) the stopping zone upstream of the third place (the view point), which the record defines for
        marks only, is read as being on the carrier, short of the junction, without that view.

  Node defect (reported in task_result.md, not repaired here): s4 claims the aggregate
  `ru.aggregate=DEF-NRS-484A-285::traffic`, which the record's own obligation and narrowing do not
  read — the view of approaching traffic is read through `st.sight_along_way`, whose contract is the
  distance within which "another vehicle on that way could be seen", so no road user of the traffic
  aggregate is read anywhere in the duty. No formula below names it.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The quantified entities: the junction entered, the approach carrier, the signal head, the
    stop line and crosswalk read as places, the marks read as zones, the way looked along. -/
def vIntersection : Arg := .var "i"
def vCarrier : Arg := .var "c"
def vDevice : Arg := .var "d"
def vStopLine : Arg := .var "sl"
def vStopZone : Arg := .var "sz"
def vCrosswalk : Arg := .var "cw"
def vCrossZone : Arg := .var "cz"
def vWay : Arg := .var "w"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pIntersectionViewSightDistance : Term := .param "p.intersection_view_sight_distance"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The subject's footprint overlaps a region. -/
def occupies (r : Arg) : Formula := .atom "rel_occupies" [vSubject, r] []
/-- The subject crosses into a region at this observation. -/
def entersRegion (r : Arg) : Formula := .derived "drv_lane_enters_region" [vSubject, r] []
/-- The subject's body is not moving at this observation. -/
def halted : Formula := .derived "drv_motion_halted" [vSubject] [pMotionSpeedTolerance]

/-- Ground distance from the subject's body outline to a region (`st.region_geometry`). -/
def bodyDistanceTo (r : Arg) : Term := .measure "st_region_geometry_distance" [vSubject, r]
/-- Signed distance to a region along the approach carrier's designated direction. -/
def offsetAlongCarrierTo (r : Arg) : Term := .quantity "prim_region_offset_along" [vSubject, r, vCarrier] []

/-- The region lies ahead of the subject's reference point along the carrier's direction. -/
def shortOf (r : Arg) : Formula := .cmp (offsetAlongCarrierTo r) .gt zeroMetres
def withinStopPointOf (r : Arg) : Formula := .cmp (bodyDistanceTo r) .le pStopPointTolerance
def beyondStopPointOf (r : Arg) : Formula := .cmp (bodyDistanceTo r) .gt pStopPointTolerance

/-- s2: a signal head governing this junction, uncovered and inoperative. -/
def inoperativeSignalGoverns : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.atom "dev_governs" [vDevice, vIntersection] [])
      (.and (.atom "dev_traffic_signal_uncovered" [vDevice] [])
        (.atom "dev_inoperative" [vDevice] [])))

/-- s1 + s2: the entry into this junction, under a signal installed, uncovered and inoperative. -/
def entryUnderInoperativeSignal : Formula :=
  .and (entersRegion vIntersection) inoperativeSignalGoverns

/-- Applicability: s1 (trigger): When a vehicle enters an intersection; s2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" entryUnderInoperativeSignal

/-- A line or crossing the source records as marking the approach carrier's entrance. -/
def marksCarrier (r : Arg) : Formula := .atom "st_entrance_of" [r, vCarrier] []

/-- Some stop line marks this carrier's entrance. -/
def stopLineMarksCarrier : Formula :=
  .existsRegion (.lit "stop_line") "sz" (marksCarrier vStopZone)
/-- Some crosswalk marks this carrier's entrance. -/
def crosswalkMarksCarrier : Formula :=
  .existsRegion (.lit "crosswalk") "cz" (marksCarrier vCrossZone)

/-- (1) halted at a stop line marking this carrier: short of the line, within the stop-point
    tolerance of it. -/
def haltedAtMarkedStopLine : Formula :=
  .existsRegion (.lit "stop_line") "sl"
    (.and (marksCarrier vStopLine)
      (.and halted (.and (withinStopPointOf vStopLine) (shortOf vStopLine))))
/-- (2) halted before a crosswalk marking this carrier: short of it, the footprint not on it. -/
def haltedBeforeMarkedCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "cw"
    (.and (marksCarrier vCrosswalk)
      (.and halted (.and (.not (occupies vCrosswalk)) (shortOf vCrosswalk))))
/-- The view the words require: along every highway the source reports a sight distance for, at
    least the intersection-view sight distance. -/
def viewOfApproachingTraffic : Formula :=
  .forallRegion (.lit "highway") "w"
    (.cmp (.measure "st_sight_along_way" [vSubject, vWay]) .ge pIntersectionViewSightDistance)
/-- (3) halted short of the junction's entrance end where that view exists. -/
def haltedWhereTrafficIsInView : Formula :=
  .and halted (.and (shortOf vIntersection) viewOfApproachingTraffic)

/-- Outside a mark's stopping zone upstream: on the carrier, farther from the mark than the
    stop-point tolerance, off the mark, and short of it along the carrier's direction. -/
def outsideZoneOf (r : Arg) : Formula :=
  .and (occupies vCarrier)
    (.and (beyondStopPointOf r) (.and (.not (occupies r)) (shortOf r)))

/-- Outside the zone of every stop line marking this carrier. -/
def outsideEveryStopLineZone : Formula :=
  .forallRegion (.lit "stop_line") "sz"
    (.implies (marksCarrier vStopZone) (outsideZoneOf vStopZone))
/-- Outside the zone of every crosswalk marking this carrier. -/
def outsideEveryCrosswalkZone : Formula :=
  .forallRegion (.lit "crosswalk") "cz"
    (.implies (marksCarrier vCrossZone) (outsideZoneOf vCrossZone))
/-- Upstream of the view place: on the carrier, short of the junction, without that view. -/
def outsideViewPlaceZone : Formula :=
  .and (occupies vCarrier) (.and (shortOf vIntersection) (.not viewOfApproachingTraffic))

/-- The place the words order, read at an observation: the stop line that marks the carrier, else
    the crosswalk that marks it, else the point with the view. -/
def haltedAtGoverningPlace : Formula :=
  .and (.implies stopLineMarksCarrier haltedAtMarkedStopLine)
    (.and (.implies (.and (.not stopLineMarksCarrier) crosswalkMarksCarrier) haltedBeforeMarkedCrosswalk)
      (.implies (.and (.not stopLineMarksCarrier) (.not crosswalkMarksCarrier)) haltedWhereTrafficIsInView))

/-- Outside the governing place's stopping zone upstream, in the same order. -/
def outsideGoverningZone : Formula :=
  .and (.implies stopLineMarksCarrier outsideEveryStopLineZone)
    (.and (.implies (.and (.not stopLineMarksCarrier) crosswalkMarksCarrier) outsideEveryCrosswalkZone)
      (.implies (.and (.not stopLineMarksCarrier) (.not crosswalkMarksCarrier)) outsideViewPlaceZone))

/-- The subject was in this junction and was not entering it at that observation: its previous
    visit, the other end of the search. -/
def previousVisitToIntersection : Formula :=
  .and (occupies vIntersection) (.not (entersRegion vIntersection))

/-- Where the search back ends: the start of the approach, or the previous visit. -/
def startOfApproach : Formula := .or outsideGoverningZone previousVisitToIntersection

/-- The halt at the governing place, somewhere between the start of the approach and this entry. -/
def haltMade : Formula := .count haltedAtGoverningPlace startOfApproach .ge 1

/-- The approach the subject entered through: a travel region it occupies whose entrance end is
    this junction, the junction itself excluded. -/
def approachCarrier : Formula :=
  .and (.not (.same vCarrier vIntersection))
    (.and (occupies vCarrier) (.atom "st_lane_enters" [vCarrier, vIntersection] []))

/-- Obligation: s4 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies entryUnderInoperativeSignal
      (.forallRegion (.lit "travel_region") "c"
        (.implies approachCarrier haltMade)))

def rule : Rule :=
  { id := "NRS_484B_250_4_o1"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s4"
          why := "the search back from the entry is the `count` operator over the run of observations outside the governing place's stopping zone upstream: where that run reaches the first observation of the recording, the source cannot show that the approach began within the recording, and the duty is unknown rather than decided. The recording's start is no boundary of the search: it decides nothing, it only withholds a decision." }
      , { span := "s4"
          why := "the search's second end, \"the previous entry of the same subject into i\", is read as an observation at which the subject was in that junction and was not entering it at that observation: the search ends at the previous visit to the junction." }
      , { span := "s4"
          why := "\"the point nearest the intersection where the driver has a view of approaching traffic\" is read as any place short of the junction's entrance end at which that view exists, not only the nearest such place; with the search's history bound, the halt must still lie between the start of the approach and the entry." }
      , { span := "s4"
          why := "\"the through highway\" is read as every highway region for which the source reports the subject's sight along the way, the duty requiring the sight distance along each: the record claims no relation tying a highway to the junction, and the way that favours the subject is never the one read." }
      , { span := "s4"
          why := "where the subject occupies several carriers whose entrance end is this junction, the duty is read as required through each of them, rather than left unknown where the carriers disagree." }
      , { span := "s4"
          why := "the stopping zone upstream of the third place, which the record defines for marks only, is read as being on the carrier, short of the junction's entrance end, without the view the words require." } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o1
