/-
  NRS_484B_250_4_o1 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (trigger): When a vehicle enters an intersection controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,
    s1 (subject): the driver of the vehicle
    ob1 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    sib1 (sibling): After making such a stop, the driver shall proceed cautiously, yielding to vehicles which have previously completed a stop or are within the intersection.

  Elements (span → atoms, derived):
    t1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'dev.traffic_signal', 'dev.governs', 'dev.inoperative'], derived ['drv.motion.region_entry']
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    ob1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'st.travel_region', 'st.lane_direction', 'st.lane_enters', 'st.intersection', 'st.on_way', 'st.highway', 'st.sight_along_way', 'prim.region_offset_along'], derived ['drv.motion.standstill']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written
  ------------------------
  s1 — the subject binder `v` is the admitted aggregate `DEF-NRS-484A-320::vehicle`, one atom
  (`clsV`); the driver is read through the vehicle's conduct, as the record's narrowing states.

  t1 — `applicability`: a junction `x` of kind `st.intersection` which the subject occupies
  (`rel.occupies`, the anchor the region quantifier needs) and which it comes to overlap at this
  observation (`drv.motion.region_entry`), and over which a signal head of kind
  `dev.traffic_signal` has control (`dev.governs`), its faces uncovered
  (`dev.traffic_signal`'s uncovered attribute) and showing no valid indication
  (`dev.inoperative`). All three device facts are read at that entry observation. No fact of the
  trigger is weakened: the trigger holds only where every one of them is decided true.

  ob1 — `obligation`: the same junction, selected again by the record's whole selection
  (`junctionSelection`), and then, for every approach carrier `l` the subject occupies whose
  entrance end is that junction (`st.travel_region` as the carrier kind, `rel.occupies` as the
  anchor, `st.lane_enters` as the entrance end; `.not (.same l x)` keeps the junction itself out of
  the carrier range, since `st.lane_enters` admits as carriers only lanes and the kinds refining
  them, roadways, shoulders and bicycle lanes or paths, never an intersection), the halt the words
  require must be found in the past (`dutyOnCarrier`). Every carrier is read, never the one that
  favours the subject.

  The place is read in the words' order (`haltedAtPlace`): the stop line recorded as marking that
  carrier (`st.stop_line`, `st.entrance_of`); where the carrier's stop lines are observed and none
  marks it, the crosswalk recorded as marking it (`st.crosswalk`, `st.entrance_of`); where neither
  is marked, the view point on that carrier. A halt counts at a mark when the subject is at rest
  (`drv.motion.standstill` with `p.standstill_speed_tolerance`), on that carrier, its footprint not
  yet over the junction, the distance from its body to the mark at most `p.stop_point_tolerance`
  (`st.region_geometry`) and the mark not yet passed — the sign of `prim.region_offset_along`
  along the carrier's designated direction (`st.lane_direction`, the direction that primitive
  measures along). At the view point the halt counts where the sight along the crossing way
  reaches `p.intersecting_way_view_distance` (`st.sight_along_way`), the crossing way being a
  `st.highway` the junction lies on and the carrier does not (`st.on_way`).

  The search for the halt runs back from the entry observation (`dutyOnCarrier` reads the search at
  the observation before the judged one, the only way the language has to look back from an event
  that is itself the judged instant) and ends at the start of that approach — the subject on the
  carrier, off the mark, short of it and farther from it than `p.stop_point_tolerance`
  (`startOfApproach`) — or at its own earlier presence in that junction (`searchEnd`). Where the
  search finds the halt the duty is met, where it reaches an end without it the duty is violated,
  and where it reaches neither (the history begins before the recording, or an association or a
  direction is unobserved) it is unknown.

  Readings chosen here are declared as narrowings on ob1 and explained there.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o1

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantified entities: the junction entered, the approach carrier, the signal head, the mark
    at the entrance, the way the sight is read along. -/
def xV : Arg := .var "x"
def lV : Arg := .var "l"
def dV : Arg := .var "d"
def mV : Arg := .var "m"
def wV : Arg := .var "w"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pIntersectingWayViewDistance : Term := .param "p.intersecting_way_view_distance"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

-- The occupancy leaves: the subject's footprint over the junction, over the carrier, over the mark.
def occupiesJunction : Formula := .atom "rel_occupies" [vV, xV] []
def occupiesCarrier : Formula := .atom "rel_occupies" [vV, lV] []
def occupiesMark : Formula := .atom "rel_occupies" [vV, mV] []

/-- The event: the subject's footprint comes to overlap the junction at this observation. -/
def entersJunction : Formula := .derived "drv_motion_region_entry" [vV, xV] []

/-- A signal head governing the junction, installed with its faces uncovered and inoperative. -/
def deadSignalGoverns : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.atom "dev_governs" [dV, xV] [])
      (.and (.atom "dev_traffic_signal_uncovered" [dV] [])
        (.atom "dev_inoperative" [dV] [])))

/-- The junction the words select: the one the subject enters, under such a signal. The obligation
    repeats this whole selection, so both formulas speak of the same region. -/
def junctionSelection : Formula :=
  .and occupiesJunction (.and entersJunction deadSignalGoverns)

/-- Applicability: t1 (trigger): When a vehicle enters an intersection controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "x" junctionSelection

/-- The approach: a travel region other than the junction itself, which the subject occupies and
    whose entrance end is that junction. -/
def onApproach : Formula :=
  .and (.not (.same lV xV))
    (.and occupiesCarrier (.atom "st_lane_enters" [lV, xV] []))

/-- The mark marks that carrier's entrance (the source's own record). -/
def marksApproach : Formula := .atom "st_entrance_of" [mV, lV] []

/-- The halt itself: complete cessation from movement, at the standstill tolerance. -/
def atRest : Formula := .derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance]

/-- The distance from the subject's body outline to the mark. -/
def bodyToMark : Term := .measure "st_region_geometry_distance" [vV, mV]
/-- The signed distance to the mark along the carrier's designated direction. -/
def offsetToMark : Term := .quantity "prim_region_offset_along" [vV, mV, lV] []

/-- A halt at the mark: at rest on that carrier, its footprint not yet over the junction, within
    the stop-point tolerance of the mark and not past it. -/
def haltedAtMark : Formula :=
  .and atRest
    (.and occupiesCarrier
      (.and (.not occupiesJunction)
        (.and (.cmp bodyToMark .le pStopPointTolerance)
          (.cmp offsetToMark .ge zeroMetres))))

/-- The view of the crossing way: a highway the junction lies on and the carrier does not, along
    which the sight from the subject reaches the view distance. -/
def viewOfCrossingWay : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "st_on_way" [xV, wV] [])
      (.and (.not (.atom "st_on_way" [lV, wV] []))
        (.cmp (.measure "st_sight_along_way" [vV, wV]) .ge pIntersectingWayViewDistance)))

/-- A halt at the view point: at rest on that carrier, short of the junction, with that view. -/
def haltedAtViewPoint : Formula :=
  .and atRest
    (.and occupiesCarrier (.and (.not occupiesJunction) viewOfCrossingWay))

/-- Whether the carrier's stop lines / crosswalks are observed to mark it. -/
def someStopLineMarks : Formula := .existsRegion (.lit "stop_line") "m" marksApproach
def someCrosswalkMarks : Formula := .existsRegion (.lit "crosswalk") "m" marksApproach

def haltedAtStopLine : Formula :=
  .existsRegion (.lit "stop_line") "m" (.and marksApproach haltedAtMark)
def haltedAtCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "m" (.and marksApproach haltedAtMark)

/-- The halt at the place the words name, in their order. -/
def haltedAtPlace : Formula :=
  .or haltedAtStopLine
    (.and (.not someStopLineMarks)
      (.or haltedAtCrosswalk
        (.and (.not someCrosswalkMarks) haltedAtViewPoint)))

/-- The stretch of the approach upstream of the mark: on the carrier, off the mark, short of it
    and farther from it than the stop-point tolerance. -/
def upstreamOfMark : Formula :=
  .and occupiesCarrier
    (.and (.not occupiesMark)
      (.and (.cmp offsetToMark .gt zeroMetres)
        (.cmp bodyToMark .gt pStopPointTolerance)))

/-- The stretch of the approach upstream of the view point: on the carrier, short of the junction,
    with the view of the crossing way not yet reaching the view distance. -/
def upstreamOfViewPoint : Formula :=
  .and occupiesCarrier (.and (.not occupiesJunction) (.not viewOfCrossingWay))

def upstreamOfStopLine : Formula :=
  .existsRegion (.lit "stop_line") "m" (.and marksApproach upstreamOfMark)
def upstreamOfCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "m" (.and marksApproach upstreamOfMark)

/-- The start of the approach, read at the place that governs, in the words' order. -/
def startOfApproach : Formula :=
  .or upstreamOfStopLine
    (.and (.not someStopLineMarks)
      (.or upstreamOfCrosswalk
        (.and (.not someCrosswalkMarks) upstreamOfViewPoint)))

/-- Where the search into the past ends: the start of that approach, or the subject's own earlier
    presence in that junction (no halt at the place is possible while its footprint overlaps the
    junction, so this is the earlier entry of the same subject into the same junction). -/
def searchEnd : Formula := .or startOfApproach occupiesJunction

/-- The halt found, searching back: the halt at the place, with no end of the search since. -/
def haltFound : Formula := .since (.not searchEnd) haltedAtPlace

/-- The value of a formula at the observation before the judged one: true where it held there,
    false where it did not, unknown where that observation is not in the recording. -/
def atPreviousObservation (φ : Formula) : Formula :=
  .or (.and φ (.not (.rises φ))) (.rises (.not φ))

/-- The duty on one carrier: before the entry, the halt had been found. -/
def dutyOnCarrier : Formula := atPreviousObservation haltFound

/-- Obligation: ob1 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway. -/
def obligation : Formula :=
  .existsRegion (.lit "intersection") "x"
    (.and junctionSelection
      (.forallRegion (.lit "travel_region") "l" (.implies onApproach dutyOnCarrier)))

def rule : Rule :=
  { id := "NRS_484B_250_4_o1"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "ob1"
          why := "'the point nearest the intersection where the driver has a view of approaching traffic' is written as: at rest on the approach carrier, its footprint not yet over the junction, with the sight along the crossing way at least p.intersecting_way_view_distance. No region of a scene marks that point, and a trace carries sampled positions only, so the place is not stated as the minimum over the points of the carrier at which the view holds; every point of the carrier, short of the junction, from which the way is visible that far counts as the place."
          kind := "reading" }
      , { span := "ob1"
          why := "'the through highway' on which the traffic approaches is written as a highway region the junction lies on (st.on_way) that the subject's carrier does not lie on — the way the approach crosses there. Where the source records several such ways, the view along any one of them satisfies the place; a way the source does not record leaves no view, so the place is not reached."
          kind := "reading" }
      , { span := "ob1"
          why := "Where the place is the view point, the start of the approach that ends the search back has no mark to be measured from: it is written as the stretch of the carrier, short of the junction, at which the sight along the crossing way does not yet reach p.intersecting_way_view_distance — the same relation to the place that the mark's upstream zone has to a mark."
          kind := "reading" }
      , { span := "ob1"
          why := "The end of the search at 'the previous entry of the same subject into the same intersection' is written as the subject's own presence in that junction (rel.occupies), read at an observation before the judged entry: a formula read at the judged entry cannot tell that entry from an earlier one, and the two bounds decide this duty alike, because no halt at the place can be found while the subject's footprint overlaps the junction. The duty is judged at the observation before the entry for the same reason."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o1
