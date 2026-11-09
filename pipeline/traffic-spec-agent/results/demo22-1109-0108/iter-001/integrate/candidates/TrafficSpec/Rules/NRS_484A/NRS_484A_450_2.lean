/-
  NRS_484A_450_2 — NRS-484A-450-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every driver of a vehicle
    s2 (trigger): approaching a stop intersection indicated by a stop sign
    s3 (obligation): shall stop before entering the crosswalk on the near side of the intersection or, if there is no crosswalk, shall stop at a clearly marked stop line, or if none, then at the point nearest the intersecting highway
    s4 (standard): where the driver has a view of approaching traffic on the intersecting highway
    s5 (condition): before entering the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.intersection', 'st.travel_region', 'rel.occupies', 'st.lane_enters', 'dev.stop_sign', 'dev.governs'], derived []
    s3: atoms ['st.crosswalk', 'st.stop_line', 'st.travel_region', 'st.entrance_of', 'st.lane_direction', 'st.region_geometry', 'rel.occupies', 'st.intersection', 'st.highway', 'st.on_way', 'prim.region_offset_along'], derived ['drv.motion.standstill']
    s5: atoms ['st.intersection', 'rel.occupies'], derived []

  How each span is written:

  s1 — `clsV` is `ru_aggregate` of the binder with the admitted aggregate id, nothing else: the
  vehicle whose motion is controlled is the bound road user (the record's agency narrowing).

  s2 — `approachCarrier`: a travel region (`st_travel_region`) the vehicle occupies
  (`rel_occupies`) whose entrance end is the intersection (`st_lane_enters` on that carrier and
  that junction), with a stop sign (`dev_stop_sign`) the source records as governing that same
  carrier (`dev_governs`). The region quantifier ranges over `travel_region`, the kind
  `st_lane_enters` admits, so every region argument carries a claimed kind; the junction is bound
  by its own `intersection` quantifier and `st_intersection` is read on it.

  s5 — `entersNow`: `.rises (rel_occupies v X)`, the observation at which the footprint first
  overlaps the junction. The applicability holds at that observation only, so the duty below is
  judged once per entry.

  s3 — the act is `drv.motion.standstill` with `p.standstill_speed_tolerance`. The place is read
  from the words in their order by `dutyThroughCarrier`:
    * every crosswalk the source records as marking that carrier's entrance (`st_crosswalk` with
      `st_entrance_of` on the same carrier `st_lane_enters` relates to the junction) must have the
      halt made at it (`dutyAtMark`);
    * where no crosswalk marks it (`someCrosswalkMarks` decided false, which `st_entrance_of`
      gives only where the crossing's entrances are observed), every stop line that marks it
      (`st_stop_line` with `st_entrance_of`) must have the halt made at it;
    * where neither marks it, the halt must be made at a point of the carrier at which the view of
      s4 is met (`dutyAtViewPoint`).
  A mark whose association with the carrier is unobserved leaves `st_entrance_of` unknown, and the
  implication leaves the duty unknown on that ground.
  `atMark` is the place: the body off the mark and off the junction (`rel_occupies`), the mark
  ahead along the carrier's designated direction (the sign of `prim.region_offset_along`, with
  `st_lane_direction` read on its own in `carrierDirected`), and the distance from the body to the
  mark (`st_region_geometry`) within `p.stop_point_tolerance`.
  `haltSearch` is the history bound: `.since (.not bound) halt` runs back from the entry event and
  ends at the record's two boundaries only — `zoneOutsideMark` (the vehicle on a carrier the mark
  marks, off the mark, short of it and farther from it than the tolerance: the start of the
  approach) and `inJunctionBefore` (the first observation after any observation at which the
  vehicle occupied that junction: the previous entry, whose own halt discharged that entry). The
  recording's start is no boundary: a search that reaches it is unknown, which is what the
  history-boundary witness shows. Crossing the mark, moving on, a change of carrier, a lateral
  move or a reverse inside the zone end nothing.

  s4 — the operationalization: `st_sight_along_way` of the vehicle along the intersecting highway
  (`st_highway` with `st_on_way`: a way the junction lies on and the carrier does not) at least
  `p.intersecting_way_view_distance`, and every other road user on that way visible from the
  vehicle (`rel_visible`). It bounds the third place only, as the words place it.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484A_450_2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantifier variables: the junction entered, the carrier approached through, the sign, the
    crossing, the stop line, the intersecting way, another road user on it. -/
def xJ : Arg := .var "X"
def lC : Arg := .var "L"
def dSign : Arg := .var "d"
def cCross : Arg := .var "c"
def sLine : Arg := .var "s"
def wWay : Arg := .var "w"
def uOther : Arg := .var "u"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pIntersectingWayViewDistance : Term := .param "p.intersecting_way_view_distance"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre
def zeroRatio : Term := .lit Q.zero .ratio

/-- Conjunction of a list, written out so the leaves below read in the order of the words. -/
def conj : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (conj rest)

-- ---------------------------------------------------------------------------------------------
-- The leaves: each claimed atom, primitive and concept, by its contract.
-- ---------------------------------------------------------------------------------------------
def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
def isIntersection (r : Arg) : Formula := .atom "st_intersection" [r] []
def isTravelRegion (r : Arg) : Formula := .atom "st_travel_region" [r] []
def isCrosswalk (r : Arg) : Formula := .atom "st_crosswalk" [r] []
def isStopLine (r : Arg) : Formula := .atom "st_stop_line" [r] []
def isHighway (r : Arg) : Formula := .atom "st_highway" [r] []
def entersJunction (l x : Arg) : Formula := .atom "st_lane_enters" [l, x] []
def marksEntranceOf (mark l : Arg) : Formula := .atom "st_entrance_of" [mark, l] []
def liesOnWay (r w : Arg) : Formula := .atom "st_on_way" [r, w] []
def isStopSign (d : Arg) : Formula := .atom "dev_stop_sign" [d] []
def governs (d r : Arg) : Formula := .atom "dev_governs" [d, r] []
def visibleFrom (a b : Arg) : Formula := .atom "rel_visible" [a, b] []

/-- The act: a complete cessation from movement at the observation, within the reading's speed
    tolerance. -/
def standstill : Formula := .derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance]

/-- The ground distance from the vehicle's body outline to a region (`st.region_geometry`). -/
def distanceToRegion (r : Arg) : Term := .measure "st_region_geometry_distance" [vV, r]

/-- The signed distance from the vehicle's reference point to a region along a carrier's
    designated direction (`prim.region_offset_along`); its sign gives the side. -/
def offsetAlongCarrier (r l : Arg) : Term := .quantity "prim_region_offset_along" [vV, r, l] []

/-- The distance along a way, in each direction, within which another vehicle on it could be seen
    from the vehicle's eye; the smaller of the two. -/
def sightAlongWay (w : Arg) : Term := .measure "st_sight_along_way" [vV, w]

def laneDirectionComponent (l : Arg) (axis : String) : Term := .measure "st_lane_direction" [l, .lit axis]

/-- The carrier carries a designated direction at this observation: the direction a formula reads
    is normalised, so its components' magnitudes sum above zero exactly where one is recorded, and
    the side of a mark is read along it and never along the vehicle's heading. -/
def carrierDirected (l : Arg) : Formula :=
  .cmp (.add (.abs (laneDirectionComponent l "x")) (.abs (laneDirectionComponent l "y"))) .gt zeroRatio

-- ---------------------------------------------------------------------------------------------
-- s1, s2, s5: the bound vehicle, the approach, the entry event.
-- ---------------------------------------------------------------------------------------------
/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: a travel region the vehicle occupies whose entrance end is the junction `x`, governed by a
    stop sign. -/
def approachCarrier (l x : Arg) : Formula :=
  conj [ isTravelRegion l
       , occupies vV l
       , entersJunction l x
       , .existsDevice (.lit "stop_sign") "d" (.and (isStopSign dSign) (governs dSign l)) ]

/-- s5: the observation at which the vehicle's footprint first overlaps the junction. -/
def entersNow (x : Arg) : Formula := .rises (occupies vV x)

/-- Applicability: s2 (trigger): approaching a stop intersection indicated by a stop sign; s5 (condition): before entering the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "X"
    (conj [ isIntersection xJ
          , entersNow xJ
          , .existsRegion (.lit "travel_region") "L" (approachCarrier lC xJ) ])

-- ---------------------------------------------------------------------------------------------
-- s3, s4: the act, the place, the search back from the entry.
-- ---------------------------------------------------------------------------------------------
/-- The vehicle's body is off the mark and off the junction: the words place the halt before it
    enters either. -/
def offMarkAndJunction (mark x : Arg) : Formula :=
  .and (.not (occupies vV mark)) (.not (occupies vV x))

/-- The mark lies ahead of the vehicle's reference point along the carrier's designated direction. -/
def shortOfMark (mark l : Arg) : Formula := .cmp (offsetAlongCarrier mark l) .gt zeroMetres

/-- At the place the words name: off the mark and the junction, the mark ahead along the carrier's
    designated direction, the body within the stop-point tolerance of the mark. -/
def atMark (mark l x : Arg) : Formula :=
  conj [ offMarkAndJunction mark x
       , carrierDirected l
       , shortOfMark mark l
       , .cmp (distanceToRegion mark) .le pStopPointTolerance ]

/-- The halt the duty requires, at a mark. -/
def haltAtMark (mark l x : Arg) : Formula := .and standstill (atMark mark l x)

/-- The start of the approach: the vehicle on a carrier the mark marks, off the mark, short of it
    and farther from it than the stop-point tolerance — outside the mark's stopping zone upstream. -/
def zoneOutsideMark (mark l x : Arg) : Formula :=
  conj [ occupies vV l
       , .not (occupies vV mark)
       , carrierDirected l
       , shortOfMark mark l
       , .cmp (distanceToRegion mark) .gt pStopPointTolerance ]

/-- The previous entry of this vehicle into this junction: the first observation after any at which
    its footprint overlapped the junction. A halt made before it discharged that entry, not this
    one. -/
def inJunctionBefore (x : Arg) : Formula :=
  .or (.and (occupies vV x) (.not (.rises (occupies vV x))))
      (.rises (.not (occupies vV x)))

/-- The search back from the entry event: the halt at some observation since the last boundary;
    unknown where it reaches neither boundary (the recording begins inside the stopping zone). -/
def haltSearch (halt bound : Formula) : Formula := .since (.not bound) halt

def dutyAtMark (mark l x : Arg) : Formula :=
  haltSearch (haltAtMark mark l x) (.or (inJunctionBefore x) (zoneOutsideMark mark l x))

/-- s4: the view of approaching traffic on the intersecting highway — a way the junction lies on
    and the carrier does not. -/
def viewMet (l x : Arg) : Formula :=
  .existsRegion (.lit "highway") "w"
    (conj [ isHighway wWay
          , liesOnWay x wWay
          , .not (liesOnWay l wWay)
          , .cmp (sightAlongWay wWay) .ge pIntersectingWayViewDistance
          , .forallUser "u"
              (.implies (.and (occupies uOther wWay) (.not (.same uOther vV)))
                        (visibleFrom vV uOther)) ])

/-- The third place: a point of the carrier, outside the junction, at which the view of s4 is met. -/
def haltAtViewPoint (l x : Arg) : Formula :=
  conj [ standstill, occupies vV l, .not (occupies vV x), viewMet l x ]

/-- Outside the view point's stopping zone upstream: on the carrier, outside the junction, the view
    not met. -/
def zoneOutsideViewPoint (l x : Arg) : Formula :=
  conj [ occupies vV l, .not (occupies vV x), .not (viewMet l x) ]

def dutyAtViewPoint (l x : Arg) : Formula :=
  haltSearch (haltAtViewPoint l x) (.or (inJunctionBefore x) (zoneOutsideViewPoint l x))

def someCrosswalkMarks (l : Arg) : Formula :=
  .existsRegion (.lit "crosswalk") "c" (.and (isCrosswalk cCross) (marksEntranceOf cCross l))

def someStopLineMarks (l : Arg) : Formula :=
  .existsRegion (.lit "stop_line") "s" (.and (isStopLine sLine) (marksEntranceOf sLine l))

/-- The places in the order of the words: the crossing that marks the carrier's entrance; where
    none marks it, the clearly marked stop line; where neither marks it, the view point. -/
def dutyThroughCarrier (l x : Arg) : Formula :=
  .and
    (.forallRegion (.lit "crosswalk") "c"
      (.implies (.and (isCrosswalk cCross) (marksEntranceOf cCross l)) (dutyAtMark cCross l x)))
    (.implies (.not (someCrosswalkMarks l))
      (.and
        (.forallRegion (.lit "stop_line") "s"
          (.implies (.and (isStopLine sLine) (marksEntranceOf sLine l)) (dutyAtMark sLine l x)))
        (.implies (.not (someStopLineMarks l)) (dutyAtViewPoint l x))))

/-- Obligation: s3 (obligation): shall stop before entering the crosswalk on the near side of the intersection or, if there is no crosswalk, shall stop at a clearly marked stop line, or if none, then at the point nearest the intersecting highway; s4 (standard): where the driver has a view of approaching traffic on the intersecting highway -/
def obligation : Formula :=
  .existsRegion (.lit "intersection") "X"
    (conj [ isIntersection xJ
          , entersNow xJ
          , .forallRegion (.lit "travel_region") "L"
              (.implies (approachCarrier lC xJ) (dutyThroughCarrier lC xJ)) ])

def rule : Rule :=
  { id := "NRS_484A_450_2"
    laws := ["NRS-484A-450-2"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "where the driver has a view of approaching traffic on the intersecting highway"
          concepts := ["rel.occupies", "rel.visible", "st.highway", "st.intersection", "st.on_way", "st.sight_along_way", "st.travel_region"]
          params := ["p.intersecting_way_view_distance"]
          convention := "Intersection sight-distance convention (AASHTO Green Book intersection sight distance, the departure-sight-triangle cases): a driver halted at the stopping point must be able to see along the major way at least the distance an approaching vehicle travels in the time needed to judge a gap and clear the junction. The point is adequate where st.sight_along_way, “the distance along a way, in each direction from the point of that way nearest a road user, within which another vehicle on that way could be seen from the road user's eye at the observation … the smaller of the two directions”, taken for the intersecting highway the junction lies on (st.highway with st.on_way and st.intersection), is at least p.intersecting_way_view_distance, and where a road user is on that way approaching the junction, that road user is visible from the vehicle (rel.visible, “b is visible from a: an unobstructed line of sight”). “approaching traffic” is read as the road users travelling on that way, with no class narrowing which of them must be seen, the posted definition of traffic covering “pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel”; the sight atom carries the view itself, since rel.visible “is not a stand-in for … the sight distance of a place” and st.sight_along_way is “not a stand-in for … whether an actual road user is seen”: the two together read the span's words where a road user is present and where none is. p.intersecting_way_view_distance is the only magnitude, and it is the reading's, not the words'."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "The record bounds the search for the halt by the mark's stopping zone (off the mark, short of it, farther from it than p.stop_point_tolerance) and leaves the third place — the point at which the view of s4 is met — without a zone for the search to end at. The zone of that place is read as the stretch of the carrier, outside the junction, on which that view is met: the search back from the entry ends at the last observation at which the vehicle was on the carrier, outside the junction, and the view was not met. Nothing else ends it, as with a mark."
          kind := "reading" }
      , { span := "s3"
          why := "st.lane_direction, which the record claims beside prim.region_offset_along for the side of the mark, is read on its own as the carrier carrying a designated direction at the observation judged: the magnitude of the direction a formula reads (normalised, so at least one) is above zero exactly where the source records one, and is unknown where it records none. The place of the halt is read only where that direction is recorded, since the side of the mark is read along it."
          kind := "reading" }
      , { span := "s3"
          why := "“the carrier the vehicle approaches through” is written as every carrier the vehicle occupies whose entrance end is the junction entered and which the stop sign governs: the duty must be met through each of them, as st.lane_enters directs (“a rule never picks the carrier that favours the road user”). Where the vehicle occupies one such carrier, the ordinary case, this reading and a reading that picks one agree."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484A_450_2
