/-
  NRS_484A_450_2 — NRS-484A-450-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every driver of a vehicle
    s2 (trigger): approaching a stop intersection indicated by a stop sign
    s3 (obligation): shall stop before entering the crosswalk on the near side of the intersection or, if there is no crosswalk, shall stop at a clearly marked stop line, or if none, then at the point nearest the intersecting highway
    s4 (standard): where the driver has a view of approaching traffic on the intersecting highway
    s5 (trigger): before entering the intersection

  Elements (span → atoms, derived):
    s1: atoms ['ru.subject', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['dev.stop_sign', 'dev.governs', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'rel.occupies'], derived []
    s3: atoms ['st.crosswalk', 'st.stop_line', 'st.entrance_of', 'st.intersection', 'st.highway', 'st.on_way', 'st.travel_region', 'st.lane_enters', 'st.lane_direction', 'st.region_geometry', 'kin.position', 'rel.occupies', 'prim.region_offset_along'], derived ['drv.motion.standstill']
    s5: atoms ['st.intersection', 'rel.occupies', 'st.travel_region', 'st.lane_enters'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
  The only literal here is zero metres, the side a signed offset along the carrier's designated
  direction is read by.

  How each span is written.

    s1 — the subject. Both atoms of the element are the binder's class: `ru_subject veh`, the road
    user whose conduct the rule judges, and `ru_aggregate veh "DEF-NRS-484A-320::vehicle"`,
    membership of the admitted aggregate, written with the aggregate's id and never with the
    classes the reading puts under it. The record's observable reading of 'every driver of a
    vehicle' through the vehicle's controlled motion is the plan's and is not restated in
    `narrowings`.

    s2 / s5 — the applicability. The two triggers are one situation: an entry into a junction the
    subject approached through a carrier a stop sign governs. `entersJunction` is
    `rises (rel_occupies veh junc)` — the footprint overlaps the junction region here and did not
    at the observation before, which is span s5's event, read at the judged observation and the
    one before it. `approachCarrier` binds the carrier: a region of the kind `st.travel_region`
    (`existsRegion "travel_region"`, which covers every kind that refines it and excludes none the
    record does not exclude) whose entrance end is that junction (`st_lane_enters carrier junc`,
    entry topology, never inferred from motion), which the subject occupies at the entry or
    occupied at the observation before it (`onCarrier`, the record's reading of 'approaching'), and
    which a stop sign governs — `existsDevice "stop_sign"` with `dev_governs sign carrier` or
    `dev_governs sign junc`, the second being the contract's reading of a device that governs the
    junction itself. The junction is `existsRegion "intersection"`. Nothing here is narrowed: a
    trigger is carried as the node maps it.

    'At the observation before' needs the value of a formula one observation back, and the language
    has no `prev`: `previously φ` is written from the two rising edges it does give,
    `rises (¬φ) ∨ (φ ∧ ¬ rises φ)`, which is exactly φ at the previous observation (and unknown at
    the first observation of a trace, where the past is unobserved). This is an encoding of the
    record's words, not a reading of them.

    s3 — the duty, and s4 the standard inside its third place. The obligation binds the junction
    and the carrier again with the whole selection that fixes them (`entersJunction`,
    `approachCarrier`), so that the place of the halt is read on the carrier the subject approached
    through, and it is owed at each junction entered and through each carrier so selected
    (`forallRegion` over both: the st.lane_enters contract forbids picking the carrier that favours
    the road user).

    The halt itself is `drv_motion_standstill veh p.standstill_speed_tolerance` — the body's own
    complete cessation from movement, DEF-NRS-484A-255, and never a lamp or a control input.

    The three places are read in the order the words give them, each on that carrier, as a cascade
    whose guards are the marks' association with the carrier (`st_entrance_of`, the source's
    record): where a crosswalk marks it (`crosswalkMarks`), the crosswalk place governs; where the
    crosswalk entrances are observed and exclude it, a stop line marking it (`stopLineMarks`)
    governs; where those are excluded too, the point nearest the intersecting highway governs.
    Written as three guarded disjuncts, so that an unobserved association leaves the duty unknown
    exactly where the verdict turns on it, and an observed exclusion passes to the next place.

      The crosswalk place (`haltBeforeCrosswalk`): the halt is made at an observation at which the
      footprint does not overlap that crosswalk (`¬ rel_occupies veh cross` — a halt made with the
      body already on the crossing is not one made before entering it), the crosswalk lies at or
      ahead of the reference point along the carrier's designated direction
      (`prim_region_offset_along veh cross carrier ≥ 0`, the only name that writes 'before' and
      'short of' a mark along a carrier, which reads `kin.position`, `st.region_geometry` and
      `st.lane_direction` and establishes nothing else), and the body is within
      `p.stop_point_tolerance` of it (`st_region_geometry_distance veh cross`, the ground distance
      from the body outline, which carries the distance the primitive may not).

      The stop-line place (`haltAtStopLine`): the line marks the carrier, it lies at or ahead of
      the reference point or behind it by no more than `p.stop_point_tolerance`
      (`prim_region_offset_along ≥ − p.stop_point_tolerance`, the record's 'at or before that
      line'), and the body is within `p.stop_point_tolerance` of it.

      The nearest-point place (`haltAtNearestPoint`): the junction is not yet entered
      (`¬ rel_occupies veh junc`), the body is within `p.stop_point_tolerance` of the intersecting
      highway and that way is not beyond the reference point along the carrier's designated
      direction, and the view standard of s4 is met there. The intersecting highway is
      `intersectingWay`: a region of `st.highway` the subject's own carrier does not lie on
      (`¬ st_on_way carrier way`) on which some carrier entering that junction lies
      (`st_lane_enters approach junc` and `st_on_way approach way`).

      s4, the operationalization: `viewOfApproachingTraffic` is `st_sight_along_way veh way ≥
      p.approach_view_sight_distance`, the sight along the intersecting highway itself. The
      convention's words put that sight 'on a carrier' of the way; the atom is a distance along a
      way, and a trace records it per way (a highway region), never per carrier, so the sight is
      read on the intersecting highway and the carrier that `st_lane_enters` records as entering
      the junction and `st_on_way` records as lying on that way is what identifies the way
      (`intersectingWay`) rather than what carries the sight. Declared below as a reading on s4.
      No road user is read: the view is of the way, as the atom's own words state, and never
      `rel.visible` or `env.visibility`.

    The search into the past (`haltSearch`): the duty is `since (¬ end) halt` — the halt at this or
    some earlier observation with no end of the search between. The ends are the record's two and
    no others: the previous occurrence of this entry (`previousEntry`, the subject's footprint
    overlapping that junction at the observation before — written one observation after the earlier
    visit, since `since` reads the judged observation too, and the judged entry is itself an
    occupancy), and the start of the approach (`approachStartAt…`): the subject on that carrier and
    outside the stopping zone upstream of every mark of the governing kind that marks it — off the
    mark, short of it along the carrier's designated direction, and farther from it than
    `p.stop_point_tolerance`. Nothing else ends it: no distance travelled, no first observation, no
    other junction or mark. Where the search reaches the start of the trace without either end and
    without the halt, `since` is unknown, which is the duty's unknown the record asks for.

  Choices this session made on carried spans, declared in `narrowings`:
    - s3: in the third place the words name no mark, so the start of the approach there is read
      about the intersecting highway region itself, the place's own reference region.
    - s4: the view is read as met where the sight along some one carrier of the intersecting
      highway entering the junction reaches the parameter.
  Everything else — the places and their order, the stop-point tolerance about each mark, the
  reading of 'approaching' at the entry or the observation before it, the halt clear of the
  crossing, the ends of the search — is the record's own narrowing or its obligation verbatim.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484A_450_2

/-- The binders, as arguments (order and names are the node's). -/
def vVeh : Arg := .var "veh"

/-- The quantifier variables: the junction entered, the carrier approached through, the stop sign
    that governs it, the marks of its entrance, the intersecting highway and a carrier of it. -/
def vJunc : Arg := .var "junc"
def vCarrier : Arg := .var "carrier"
def vSign : Arg := .var "sign"
def vCross : Arg := .var "cross"
def vLine : Arg := .var "line"
def vWay : Arg := .var "way"
def vApproach : Arg := .var "approach"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pApproachViewSightDistance : Term := .param "p.approach_view_sight_distance"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

/-- The side a signed offset along the carrier's designated direction is read by. -/
def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `veh`: ru.subject, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsVeh : Formula :=
  .and (.atom "ru_subject" [vVeh] [])
       (.atom "ru_aggregate" [vVeh, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- The subject's footprint overlaps a region. -/
def occupies (r : Arg) : Formula := .atom "rel_occupies" [vVeh, r] []

/-- φ at the observation before this one, from the two rising edges the language gives: unknown at
    the first observation of a trace, where the past is unobserved. -/
def previously (φ : Formula) : Formula :=
  .or (.rises (.not φ)) (.and φ (.not (.rises φ)))

-- -------------------------------------------------------------------------------------------
-- s2, s5: the entry into a stop-sign-governed junction through a carrier of the approach.
-- -------------------------------------------------------------------------------------------

/-- s5: the subject's footprint comes to overlap the junction region here and did not before. -/
def entersJunction : Formula := .rises (occupies vJunc)

/-- s2: the subject approaches through the carrier — it occupies it at the entry, or occupied it at
    the observation before. -/
def onCarrier : Formula := .or (occupies vCarrier) (previously (occupies vCarrier))

/-- s2: a stop sign controls the carrier's traffic, or controls the junction itself. -/
def governedCarrier : Formula :=
  .existsDevice (.lit "stop_sign") "sign"
    (.or (.atom "dev_governs" [vSign, vCarrier] [])
         (.atom "dev_governs" [vSign, vJunc] []))

/-- s2: the whole selection of the carrier — its entrance end is that junction, the subject
    approached through it, and a stop sign governs it or the junction. -/
def approachCarrier : Formula :=
  .and (.atom "st_lane_enters" [vCarrier, vJunc] [])
       (.and onCarrier governedCarrier)

/-- Applicability: s2 (trigger): approaching a stop intersection indicated by a stop sign; s5 (trigger): before entering the intersection -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "junc"
    (.and entersJunction
          (.existsRegion (.lit "travel_region") "carrier" approachCarrier))

-- -------------------------------------------------------------------------------------------
-- s3: the halt, and the three places the words select, each read on that carrier.
-- -------------------------------------------------------------------------------------------

/-- The halt the corpus defines for a required stop: complete cessation from movement. -/
def standstill : Formula := .derived "drv_motion_standstill" [vVeh] [pStandstillSpeedTolerance]

/-- The signed distance from the subject's reference point to a region along the carrier's
    designated direction: positive where the region lies ahead. -/
def offsetTo (r : Arg) : Term := .quantity "prim_region_offset_along" [vVeh, r, vCarrier] []

/-- The ground distance from the subject's body outline to a region. -/
def distanceTo (r : Arg) : Term := .measure "st_region_geometry_distance" [vVeh, r]

/-- The body is within the stop-point tolerance of the place. -/
def atMark (r : Arg) : Formula := .cmp (distanceTo r) .le pStopPointTolerance
/-- The place lies at or ahead of the reference point along the carrier's direction. -/
def markAhead (r : Arg) : Formula := .cmp (offsetTo r) .ge zeroMetres
/-- The place lies at or ahead of the reference point, or behind it within the tolerance. -/
def markNotPassed (r : Arg) : Formula := .cmp (offsetTo r) .ge (.neg pStopPointTolerance)
/-- The place lies strictly ahead: the subject is short of it. -/
def markShortOf (r : Arg) : Formula := .cmp (offsetTo r) .gt zeroMetres
/-- The body is farther from the place than the stop-point tolerance. -/
def beyondTolerance (r : Arg) : Formula := .cmp (distanceTo r) .gt pStopPointTolerance

/-- The source records the line or crossing as marking that carrier's entrance. -/
def marksCarrier (r : Arg) : Formula := .atom "st_entrance_of" [r, vCarrier] []

/-- Some crosswalk marks the carrier's entrance. -/
def crosswalkMarks : Formula :=
  .existsRegion (.lit "crosswalk") "cross" (marksCarrier vCross)
/-- Some stop line marks the carrier's entrance. -/
def stopLineMarks : Formula :=
  .existsRegion (.lit "stop_line") "line" (marksCarrier vLine)

/-- The first place: a halt made before entering a crosswalk that marks the carrier — the footprint
    clear of the crossing, the crossing at or ahead of the reference point, the body within the
    stop-point tolerance of it. -/
def haltBeforeCrosswalk : Formula :=
  .and standstill
    (.existsRegion (.lit "crosswalk") "cross"
      (.and (marksCarrier vCross)
        (.and (.not (occupies vCross))
          (.and (markAhead vCross) (atMark vCross)))))

/-- The second place: a halt made at or before a stop line that marks the carrier. -/
def haltAtStopLine : Formula :=
  .and standstill
    (.existsRegion (.lit "stop_line") "line"
      (.and (marksCarrier vLine)
        (.and (markNotPassed vLine) (atMark vLine))))

/-- The intersecting highway: a public way the subject's own carrier does not lie on, on which a
    carrier entering that junction lies. -/
def intersectingWay : Formula :=
  .and (.not (.atom "st_on_way" [vCarrier, vWay] []))
    (.existsRegion (.lit "travel_region") "approach"
      (.and (.atom "st_lane_enters" [vApproach, vJunc] [])
            (.atom "st_on_way" [vApproach, vWay] [])))

/-- s4: the view of approaching traffic on the intersecting highway — the sight along that way,
    in each direction from the point of it nearest the subject, reaches the departure-sight
    distance. The way is the one `intersectingWay` selects through the carrier that enters the
    junction and lies on it. -/
def viewOfApproachingTraffic : Formula :=
  .cmp (.measure "st_sight_along_way" [vVeh, vWay]) .ge pApproachViewSightDistance

/-- The third place: a halt made at the point of the carrier nearest the intersecting highway —
    the junction not yet entered, the body within the stop-point tolerance of that way and not
    beyond it along the carrier's direction, and the view standard met there. -/
def haltAtNearestPoint : Formula :=
  .and standstill
    (.and (.not (occupies vJunc))
      (.existsRegion (.lit "highway") "way"
        (.and intersectingWay
          (.and (atMark vWay)
            (.and (markAhead vWay) viewOfApproachingTraffic)))))

-- -------------------------------------------------------------------------------------------
-- s3: the search back from the entry, and the two ends the record gives it.
-- -------------------------------------------------------------------------------------------

/-- Outside the stopping zone upstream of a place: off it, short of it along the carrier's
    designated direction, and farther from it than the stop-point tolerance. -/
def outsideStoppingZone (r : Arg) : Formula :=
  .and (.not (occupies r)) (.and (markShortOf r) (beyondTolerance r))

/-- The start of the approach where crosswalks govern: on the carrier, outside the stopping zone of
    every crosswalk that marks it. -/
def approachStartAtCrosswalk : Formula :=
  .and (occupies vCarrier)
    (.forallRegion (.lit "crosswalk") "cross"
      (.implies (marksCarrier vCross) (outsideStoppingZone vCross)))

/-- The start of the approach where stop lines govern. -/
def approachStartAtStopLine : Formula :=
  .and (occupies vCarrier)
    (.forallRegion (.lit "stop_line") "line"
      (.implies (marksCarrier vLine) (outsideStoppingZone vLine)))

/-- The start of the approach where no mark marks the carrier: read about the intersecting highway
    itself, the third place's own reference region (this session's reading, declared below). -/
def approachStartAtWay : Formula :=
  .and (occupies vCarrier)
    (.forallRegion (.lit "highway") "way"
      (.implies intersectingWay (outsideStoppingZone vWay)))

/-- The previous occurrence of this entry: the subject's footprint overlapped that junction at the
    observation before. -/
def previousEntry : Formula := previously (occupies vJunc)

/-- The halt, searched for backwards from the entry, the search ending at the previous occurrence
    of the entry or at the start of the approach and nowhere else. -/
def haltSearch (halt start : Formula) : Formula :=
  .since (.not (.or previousEntry start)) halt

/-- The places in the order the words give them: the crosswalk marking the carrier, else a stop
    line marking it, else the point nearest the intersecting highway. -/
def dutyOnCarrier : Formula :=
  .or (.and crosswalkMarks (haltSearch haltBeforeCrosswalk approachStartAtCrosswalk))
    (.or (.and (.not crosswalkMarks)
           (.and stopLineMarks (haltSearch haltAtStopLine approachStartAtStopLine)))
         (.and (.not crosswalkMarks)
           (.and (.not stopLineMarks)
             (haltSearch haltAtNearestPoint approachStartAtWay))))

/-- Obligation: s3 (obligation): shall stop before entering the crosswalk on the near side of the intersection or, if there is no crosswalk, shall stop at a clearly marked stop line, or if none, then at the point nearest the intersecting highway; s4 (standard): where the driver has a view of approaching traffic on the intersecting highway -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "junc"
    (.implies entersJunction
      (.forallRegion (.lit "travel_region") "carrier"
        (.implies approachCarrier dutyOnCarrier)))

def rule : Rule :=
  { id := "NRS_484A_450_2"
    laws := ["NRS-484A-450-2"]
    binders :=
      [ { name := "veh", cls := clsVeh } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "where the driver has a view of approaching traffic on the intersecting highway"
          concepts := ["rel.occupies", "st.highway", "st.intersection", "st.lane_enters", "st.on_way", "st.region_geometry", "st.sight_along_way", "st.travel_region"]
          params := ["p.approach_view_sight_distance"]
          convention := "Intersection sight distance, departure sight triangle: the length of the intersecting highway a stopped driver must be able to see, in each direction, to judge approaching traffic - the distance a vehicle on that highway covers at its design speed during the time a stopped vehicle needs to depart. The standard is bounded by st.sight_along_way, 'the distance along a way, in each direction from the point of that way nearest a road user, within which another vehicle on that way could be seen from the road user's eye at the observation; the smaller of the two directions', taken on a carrier (a region of the kind st.travel_region) that st.lane_enters records as entering the junction (st.intersection) and that st.on_way records as lying on the intersecting highway (st.highway) - the way the subject's own carrier does not lie on - with rel.occupies anchoring the subject's own place on its carrier and st.region_geometry the distance from it to that way; the point qualifies where that sight distance is at least p.approach_view_sight_distance. 'approaching traffic' is a legal aggregate in the law's words, and the standard reads no road user at all: the view is of the way whether or not a member of the aggregate is present, as st.sight_along_way's own words ('another vehicle on that way could be seen') state; it is not read as rel.visible, whether an actual road user was seen, nor as env.visibility, the clarity of the air, both of which those contracts exclude."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "The third place names no mark, so the start of the approach there - the end of the search the record defines by a mark's stopping zone upstream - is read about the intersecting highway region itself, the place's own reference region: the subject on that carrier, off that way, short of it along the carrier's designated direction and farther from it than p.stop_point_tolerance. The words leave what bounds the approach where there is neither crosswalk nor stop line open; every other end of the search is the record's."
          kind := "reading" }
      , { span := "s4"
          why := "The sight distance the standard is bounded by is read on the intersecting highway region itself (st.sight_along_way of that way, at the subject's observation), not on a carrier of it: the atom is the distance along a way, in each direction from the point of that way nearest the road user, and a trace records it per way - a highway region - so no carrier carries a sight distance at all. The carrier of the intersecting highway that enters the junction (st.travel_region with st.lane_enters and st.on_way) is accordingly read as what identifies the way whose view is required - the way the subject's own carrier does not lie on and a carrier entering the same junction does - and the operationalization's words 'taken on a carrier' are read as that selection. Nothing about the bound or the parameter is relaxed."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484A_450_2
