/-
  NRS_484B_250_4_o1 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (trigger): When a vehicle enters an intersection
    a2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,
    a3 (condition): but is inoperative at the time the vehicle enters the intersection,
    a4 (subject): the driver of the vehicle
    a5 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop
    a6 (condition): at a clearly marked stop line
    a7 (condition): or, if there is none, before entering the crosswalk on the near side of the intersection
    a8 (condition): or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    a9 (sibling): After making such a stop,
    a10 (sibling): the driver
    a11 (sibling): shall proceed cautiously,
    a12 (sibling): yielding to vehicles
    a13 (sibling): which have previously completed a stop or are within the intersection.

  Elements (span → atoms, derived):
    a1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'rel.occupies'], derived []
    a2: atoms ['dev.traffic_signal', 'dev.governs'], derived []
    a3: atoms ['dev.inoperative'], derived []
    a4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    a5: atoms [], derived ['drv.motion.at_rest']
    a6: atoms ['st.stop_line', 'st.entrance_of', 'st.region_geometry', 'st.lane_direction', 'prim.region_offset_along'], derived []
    a7: atoms ['st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'rel.occupies', 'st.lane_direction', 'prim.region_offset_along'], derived []
    a8: atoms ['st.intersection', 'st.region_geometry', 'rel.occupies', 'st.lane_enters'], derived []

  How each span is written:
    a1/a4: ego is in the admitted aggregate (`ru_aggregate`). The entry into intersection i
      (`existsRegion intersection`) through carrier c (`existsRegion travel_region`): ego's footprint
      overlaps i here and did not at the observation before (`rises (rel_occupies ego i)`), and at that
      observation ego occupied c, did not occupy i, and c's entrance end is i (`st_lane_enters c i`).
      "At the observation before" is `beforeEntry`: `since (occ i) (φ ∧ ¬occ i)` read at an
      observation where occupancy of i has just risen is exactly φ at the previous observation.
    a2/a3: at the entry, some `traffic_signal` head governs c or i (`dev_governs`), and every such head
      is inoperative (`dev_inoperative`). Installed and uncovered are read through the head's presence
      and `dev.inoperative`'s own contract ("installed and uncovered but showing no valid indication").
    a5: the halt is `drv_motion_at_rest` with p.rest_speed_tolerance, on c, at the place a6–a8 select.
    a6: a stop line s with `st_entrance_of s c`: halt with body within p.stop_point_tolerance of s
      (`st_region_geometry_distance`) and not past it (`prim_region_offset_along ego s c ≥ 0`, the
      offset read along c's designated direction, `st.lane_direction`).
    a7: where no stop line marks c (the source's list decides it; an unobserved list leaves it
      unknown), a crosswalk w with `st_entrance_of w c`: as a6, and ego's footprint not over w.
    a8: where neither marks c, the entrance end of c at i: as a7 with i for the place.
    Search (the record's obligation): from the observation before the entry back, the halt is found
      by `since`, which stops where ego, on a carrier the place marks (`st_entrance_of`, or
      `st_lane_enters` for i's edge), is off the place, short of it along c (offset > 0) and farther
      from it than p.stop_point_tolerance (the approach start), or at ego's previous entry into i
      (`rises (rel_occupies ego i)`); its head before the recording is unknown (`windowTruncated`).
    Several carriers entering i at once: the verdict is decided where it is the same through each
      selected carrier, unknown where it differs (`definedWhen`, per st.lane_enters' contract: a rule
      never picks the carrier that favours the road user).
  Choices the text did not dictate:
    - "not past" a stop line is offset ≥ 0 (a reference point on the line is not past it); for a
      crosswalk and the intersection edge the footprint is off the place as well, so the offset is > 0.
    - where several stop lines (or crosswalks) are recorded as marking c, a halt at any one of them
      counts (existential over the marks of c).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o1

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantified variables: the intersection entered, the approach carrier, a signal head, a stop
    line, a crosswalk, and a carrier ego is on during the search. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vD : Arg := .var "d"
def vS : Arg := .var "s"
def vW : Arg := .var "w"
def vC2 : Arg := .var "c2"

/-- Ego's footprint overlaps region `r`. -/
def occ (r : Arg) : Formula := .atom "rel_occupies" [vEgo, r] []

/-- Carrier `c`'s entrance end is intersection `i`. -/
def entersInto (c i : Arg) : Formula := .atom "st_lane_enters" [c, i] []

/-- Line or crossing `p` marks carrier `c`'s entrance. -/
def marks (p c : Arg) : Formula := .atom "st_entrance_of" [p, c] []

def atRest : Formula := .derived "drv_motion_at_rest" [vEgo] [pRestSpeedTolerance]

/-- Ground distance from ego's body to region `p`. -/
def distTo (p : Arg) : Term := .measure "st_region_geometry_distance" [vEgo, p]

/-- Signed distance from ego to `p` along the approach carrier's designated direction. -/
def offsetAlong (p : Arg) : Term := .quantity "prim_region_offset_along" [vEgo, p, vC] []

/-- φ at the observation before, read where occupancy of i has just risen. -/
def beforeEntry (φ : Formula) : Formula := .since (occ vI) (.and φ (.not (occ vI)))

/-- a1: ego enters i here, having been on c, whose entrance end is i, at the observation before. -/
def entry : Formula :=
  .and (.rises (occ vI)) (beforeEntry (.and (occ vC) (entersInto vC vI)))

/-- a2: head `d` controls the approach: it governs c or i. -/
def governsApproach : Formula :=
  .or (.atom "dev_governs" [vD, vC] []) (.atom "dev_governs" [vD, vI] [])

/-- a2/a3: some signal head governs c or i, and every such head is inoperative. -/
def signalInoperative : Formula :=
  .and (.existsDevice (.lit "traffic_signal") "d" governsApproach)
       (.forallDevice (.lit "traffic_signal") "d" (.implies governsApproach (.atom "dev_inoperative" [vD] [])))

/-- The judged entry: the selection of i and c. -/
def selected : Formula := .and entry signalInoperative

/-- Ego on a carrier the place marks (`admits` reads `c2`). -/
def onMarkedCarrier (admits : Formula) : Formula :=
  .existsRegion (.lit "travel_region") "c2" (.and (.atom "rel_occupies" [vEgo, vC2] []) admits)

/-- The approach start: ego, on a carrier the place marks, outside the stopping zone upstream. -/
def outsideUpstream (p : Arg) (admits : Formula) : Formula :=
  .and (onMarkedCarrier admits)
    (.and (.not (occ p))
      (.and (.cmp (offsetAlong p) .gt zeroMetres) (.cmp (distTo p) .gt pStopPointTolerance)))

/-- A halt at the place: at rest on c, body within the tolerance of `p`, not past it. -/
def haltAt (p : Arg) : Formula :=
  .and atRest
    (.and (occ vC)
      (.and (.cmp (distTo p) .le pStopPointTolerance) (.cmp (offsetAlong p) .ge zeroMetres)))

/-- A halt short of `p`, ego's footprint not over it. -/
def haltShortOf (p : Arg) : Formula := .and (haltAt p) (.not (occ p))

/-- From the observation before the entry back to the approach start or ego's previous entry into i:
    a halt there. -/
def search (outside halt : Formula) : Formula :=
  beforeEntry (.since (.and (.not outside) (.not (.rises (occ vI)))) halt)

/-- a6: at the stop line marking c. -/
def viaStopLine : Formula :=
  .existsRegion (.lit "stop_line") "s"
    (.and (marks vS vC) (search (outsideUpstream vS (marks vS vC2)) (haltAt vS)))

def stopLineMarksC : Formula := .existsRegion (.lit "stop_line") "s" (marks vS vC)

/-- a7: before the crosswalk marking c. -/
def viaCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "w"
    (.and (marks vW vC) (search (outsideUpstream vW (marks vW vC2)) (haltShortOf vW)))

def crosswalkMarksC : Formula := .existsRegion (.lit "crosswalk") "w" (marks vW vC)

/-- a8: at the entrance end of c, outside i. -/
def viaEdge : Formula :=
  search (outsideUpstream vI (entersInto vC2 vI)) (haltShortOf vI)

/-- a5–a8: the halt at the place that governs. -/
def halted : Formula :=
  .or viaStopLine
    (.and (.not stopLineMarksC)
      (.or viaCrosswalk (.and (.not crosswalkMarksC) viaEdge)))

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: a1 (trigger): When a vehicle enters an intersection; a2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,; a3 (condition): but is inoperative at the time the vehicle enters the intersection,; a6 (condition): at a clearly marked stop line; a7 (condition): or, if there is none, before entering the crosswalk on the near side of the intersection; a8 (condition): or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" selected)

/-- The halt made through every selected carrier, and missed through every one. -/
def haltedThroughEach : Formula :=
  .forallRegion (.lit "intersection") "i" (.forallRegion (.lit "travel_region") "c" (.implies selected halted))
def missedThroughEach : Formula :=
  .forallRegion (.lit "intersection") "i" (.forallRegion (.lit "travel_region") "c" (.implies selected (.not halted)))

/-- Obligation: a5 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop -/
def obligation : Formula :=
  .definedWhen (.or haltedThroughEach missedThroughEach) haltedThroughEach

def rule : Rule :=
  { id := "NRS_484B_250_4_o1"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o1
