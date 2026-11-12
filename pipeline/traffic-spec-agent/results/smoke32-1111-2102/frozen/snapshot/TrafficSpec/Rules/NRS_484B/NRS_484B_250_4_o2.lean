/-
  NRS_484B_250_4_o2 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (trigger): When a vehicle enters an intersection
    a2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,
    a3 (condition): but is inoperative at the time the vehicle enters the intersection,
    a4 (subject): the driver of the vehicle
    a5 (sibling): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop
    a6 (sibling): at a clearly marked stop line
    a7 (sibling): or, if there is none, before entering the crosswalk on the near side of the intersection
    a8 (sibling): or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    a9 (condition): After making such a stop,
    a10 (subject): the driver
    a11 (standard): shall proceed cautiously,
    a12 (obligation): yielding to vehicles
    a13 (condition): which have previously completed a stop or are within the intersection.

  Elements (span → atoms, derived):
    a1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'rel.occupies'], derived []
    a2: atoms ['dev.traffic_signal', 'dev.governs'], derived []
    a3: atoms ['dev.inoperative'], derived []
    a4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    a9: atoms ['st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'rel.occupies', 'st.lane_direction', 'prim.region_offset_along'], derived ['drv.motion.at_rest']
    a10: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    a12: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.at_rest']
    a13: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived ['drv.motion.at_rest']

  How each span is written:
    a1, a4, a10: ego is of the admitted aggregate DEF-NRS-484A-320::vehicle (`ru_aggregate`). The
      intersection `i` is a region of kind intersection; the approach `c` a travel region whose
      entrance end is `i` (`st_lane_enters c i`). "Enters" is the observation at which ego occupies
      `i` and at the observation before had made the stop on `c` and still occupied `c` (read as
      `rises (not stopped)`: `stopped` held at the previous observation and fails here, and it can
      fail only where ego no longer occupies `c`).
    a2, a3: at that entry, some traffic signal head governs `c` or `i` (`dev_governs`), and every
      such head is inoperative (`dev_inoperative`, whose contract is an installed, uncovered head
      showing no valid indication).
    a9: `stopped` is `since (occupies ego c) (stop at the place)`: a stop found while ego has
      occupied `c` without a break up to the observation before entry. The stop is ego at rest
      (`drv_motion_at_rest`) on `c` at the governing place: a stop line marking `c`
      (`st_entrance_of`) with ego's body within p.stop_point_tolerance of it
      (`st_region_geometry_distance`) and its reference point not past it along `c`
      (`prim_region_offset_along` ≥ 0); where no stop line marks `c`, a crosswalk marking `c`, the
      footprint not on it (`rel_occupies`), the body within the tolerance and the crosswalk ahead
      (> 0); where neither marks `c`, outside `i`, within the tolerance of `i` and `i` ahead (> 0).
      "After": the judged observations are those from the entry while ego occupies `i` without a
      break (`since (occupies ego i) (entry ∧ signal)`).
    a13: a vehicle `b` (other than ego) has precedence where it occupies `i`, or where it occupies
      a carrier `cb` other than `c` whose entrance end is `i`, came to rest on `cb` and has occupied
      `cb` since (`since`), and the onset of that rest is earlier than the onset of ego's latest rest
      on `c` (`sinceRise` of b's rest larger than `sinceRise` of ego's).
    a11, a12: ego is at rest, or not in conflict with each such `b`: not both
      `prim_closest_approach_within` with p.conflict_horizon and
      `prim_closest_approach_distance` below p.conflict_clearance.
    The obligation restates the applicability's whole selection of `i` and `c` and judges the
    yielding duty for every selected pair.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o2

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables: the intersection, ego's approach, the other vehicle and its approach,
    a signal head, a stop line, a crosswalk. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vB : Arg := .var "b"
def vCb : Arg := .var "cb"
def vD : Arg := .var "d"
def vS : Arg := .var "s"
def vX : Arg := .var "x"

def vehicle (u : Arg) : Formula := .atom "ru_aggregate" [u, .lit "DEF-NRS-484A-320::vehicle"] []
def occupies (u r : Arg) : Formula := .atom "rel_occupies" [u, r] []
def atRest (u : Arg) : Formula := .derived "drv_motion_at_rest" [u] [pRestSpeedTolerance]
def entersInto (l r : Arg) : Formula := .atom "st_lane_enters" [l, r] []
def marks (m l : Arg) : Formula := .atom "st_entrance_of" [m, l] []
def governs (d r : Arg) : Formula := .atom "dev_governs" [d, r] []

/-- Ego's body within the stop-point tolerance of a region. -/
def nearPlace (r : Arg) : Formula :=
  .cmp (.measure "st_region_geometry_distance" [vEgo, r]) .le pStopPointTolerance
/-- The signed distance from ego to a region along `c`'s direction. -/
def offsetAlongC (r : Arg) : Term := .quantity "prim_region_offset_along" [vEgo, r, vC] []

/-- a9: a stop line, or a crosswalk, marks `c`'s entrance. -/
def lineMarksC : Formula := .existsRegion (.lit "stop_line") "s" (marks vS vC)
def crosswalkMarksC : Formula := .existsRegion (.lit "crosswalk") "x" (marks vX vC)

/-- a9 (a6): at a stop line marking `c`, not past it. -/
def atStopLine : Formula :=
  .existsRegion (.lit "stop_line") "s"
    (.and (marks vS vC) (.and (nearPlace vS) (.cmp (offsetAlongC vS) .ge zeroMetres)))

/-- a9 (a7): where no line marks `c`, short of the crosswalk marking `c`, the footprint not on it. -/
def beforeCrosswalk : Formula :=
  .and (.not lineMarksC)
    (.existsRegion (.lit "crosswalk") "x"
      (.and (marks vX vC)
        (.and (.not (occupies vEgo vX))
          (.and (nearPlace vX) (.cmp (offsetAlongC vX) .gt zeroMetres)))))

/-- a9 (a8): where neither marks `c`, outside `i` at `c`'s entrance end. -/
def beforeIntersection : Formula :=
  .and (.not lineMarksC)
    (.and (.not crosswalkMarksC)
      (.and (.not (occupies vEgo vI))
        (.and (nearPlace vI) (.cmp (offsetAlongC vI) .gt zeroMetres))))

/-- a9: ego at rest on `c` at the governing place. -/
def stopAtPlace : Formula :=
  .and (atRest vEgo) (.and (occupies vEgo vC) (.or atStopLine (.or beforeCrosswalk beforeIntersection)))

/-- a9: such a stop made, ego occupying `c` without a break since. -/
def stopped : Formula := .since (occupies vEgo vC) stopAtPlace

/-- a1: ego comes to occupy `i`, having occupied `c` after the stop at the observation before. -/
def entry : Formula := .and (occupies vEgo vI) (.rises (.not stopped))

/-- a2, a3: at least one traffic signal head governs `c` or `i`, and every such head is inoperative. -/
def signalInoperative : Formula :=
  .and (.existsDevice (.lit "traffic_signal") "d" (.or (governs vD vC) (governs vD vI)))
    (.forallDevice (.lit "traffic_signal") "d"
      (.implies (.or (governs vD vC) (governs vD vI)) (.atom "dev_inoperative" [vD] [])))

/-- The selection of `i` and `c`: `c` enters `i`, and ego has occupied `i` without a break since
    an entry from `c` after the stop, at which the signal was inoperative. -/
def selected : Formula :=
  .and (entersInto vC vI) (.since (occupies vEgo vI) (.and entry signalInoperative))

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := vehicle vEgo

/-- Applicability: a1 (trigger): When a vehicle enters an intersection; a2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,; a3 (condition): but is inoperative at the time the vehicle enters the intersection,; a9 (condition): After making such a stop,; a13 (condition): which have previously completed a stop or are within the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" selected)

/-- a13: b's rest on `cb`, and ego's on `c`. -/
def bRestOnCb : Formula := .and (atRest vB) (occupies vB vCb)
def egoRestOnC : Formula := .and (atRest vEgo) (occupies vEgo vC)

/-- a13: b occupies a carrier `cb` other than `c` entering `i`, came to rest there before ego's
    halt on `c` began, and has occupied `cb` since. -/
def stoppedFirst : Formula :=
  .existsRegion (.lit "travel_region") "cb"
    (.and (entersInto vCb vI)
      (.and (.not (.same vCb vC))
        (.and (occupies vB vCb)
          (.and (.since (occupies vB vCb) bRestOnCb)
            (.cmp (.sinceRise bRestOnCb) .gt (.sinceRise egoRestOnC))))))

/-- a13: b has completed a stop first, or is within the intersection. -/
def hasPrecedence : Formula := .or (occupies vB vI) stoppedFirst

/-- a11: projected at constant velocities, the centres approach within the horizon below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vEgo, vB] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vEgo, vB] [pConflictHorizon]) .lt pConflictClearance)

/-- a11, a12: ego at rest, or not in conflict with each vehicle it yields to. -/
def yields : Formula :=
  .forallUser "b"
    (.implies (.and (vehicle vB) (.and (.not (.same vB vEgo)) hasPrecedence))
      (.or (atRest vEgo) (.not conflict)))

/-- Obligation: a11 (standard): shall proceed cautiously,; a12 (obligation): yielding to vehicles -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c" (.implies selected yields))

def rule : Rule :=
  { id := "NRS_484B_250_4_o2"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "proceed cautiously"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_clearance"]
          convention := "Traffic-conflict technique: ego proceeds cautiously toward a vehicle it yields to where, projected at their current velocities, their centres do not approach within the time-to-collision horizon to a distance below the clearance at which their bodies would touch; the positions and velocities enter by degree."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o2
