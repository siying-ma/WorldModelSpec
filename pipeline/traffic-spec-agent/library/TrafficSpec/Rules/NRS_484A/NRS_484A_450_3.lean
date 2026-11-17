/-
  NRS_484A_450_3 — NRS-484A-450-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): approaching a yield sign
    s3 (standard): if required for safety to stop
    s4 (obligation): shall stop before entering the crosswalk on the nearest side of the intersection or, if there is no crosswalk, at a clearly marked stop line, or if none, then at the point nearest the intersecting highway where the driver has a view of approaching traffic on the intersecting highway.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['dev.yield_sign', 'dev.governs', 'rel.occupies', 'st.lane_enters', 'st.intersection', 'st.travel_region'], derived []
    s4: atoms ['st.crosswalk', 'st.stop_line', 'st.entrance_of', 'rel.occupies', 'st.intersection', 'st.region_geometry', 'prim.region_offset_along', 'st.lane_direction', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'st.highway'], derived ['drv.motion.complete_halt']

  How each span is written.
    s1: the class of `subject` is `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
    s2: the event is the entry into an intersection r (`st_intersection`) at the judged observation:
        `rises (rel_occupies subject r)`. "Approaching a yield sign" is read at the observation
        before the entry: the subject occupies a carrier c (`st_travel_region`) whose entrance end
        is r (`st_lane_enters c r`) and which some yield sign governs (`dev_yield_sign`,
        `dev_governs d c`).
    "At the previous observation" (`prevAtEntry χ`) is written with the operators the language
        has: `rises (occupies r ∨ ¬χ)`. At an entry (occupies r here, not at the observation before)
        it is exactly χ at the observation before; it is used only conjoined with, or under, the
        entry `rises (occupies r)`.
    s3: the record's operationalization: some road user u other than the subject (`same`), of
        traffic (`ru_aggregate(u, DEF-NRS-484A-285::traffic)`), occupying a highway
        (`rel_occupies u h`, `st_highway`), with `prim_closest_approach_within(subject, u,
        p.conflict_horizon)` and `prim_closest_approach_distance(subject, u, p.conflict_horizon) <
        p.conflict_centre_clearance`, at some observation from the approach start to t-1:
        `since (inApproach) conflict` read at t-1.
    s4: the place, in the record's order, read through c:
        (1) some crosswalk x marking c (`st_entrance_of x c`): halt off x (`¬rel_occupies`), short
            of it along c (`prim_region_offset_along subject x c > 0`, along `st_lane_direction` of
            c), body-to-x distance (`st_region_geometry_distance`) ≤ p.stop_point_tolerance;
        (2) every crosswalk observed not to mark c, and some stop line l marking c: halt not past l
            (offset ≥ 0), distance ≤ p.stop_point_tolerance;
        (3) no crosswalk and no stop line marks c: halt off r, short of r along c, distance to r ≤
            p.stop_point_tolerance.
        The halt is `drv_motion_complete_halt(subject, p.halt_speed_tolerance)`.
        History bound: the search runs back from t-1 (`since`, read at t-1) while the subject is in
        the approach — not at the approach start and not in r — and stops at the approach start
        (the subject on c, off and short of every governing mark of c and farther than
        p.stop_point_tolerance from each) or at any observation in r (the previous entry or its
        visit). Nothing else ends it; a search reaching the recording's start is unknown (Core's
        `since`).
    The obligation restates the applicability's whole selection of r and c and requires the duty
    through every selected carrier (`forallRegion`): no carrier is picked in the subject's favour.

  Choices the record left open:
    - The approach start is read with the subject on the approach carrier c itself (the record's
      "a carrier the governing mark is recorded as marking", of which c is one): an exit from the
      zone upstream observed on another carrier the mark marks does not end the search (declared
      as a narrowing on s4).
    - "Not past" a stop line (place 2) is an offset along c of at least zero; "short of" a
      crosswalk or r is an offset greater than zero.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484A_450_3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables. -/
def vR : Arg := .var "r"   -- the intersection entered
def vC : Arg := .var "c"   -- the approach carrier
def vX : Arg := .var "x"   -- a crosswalk
def vL : Arg := .var "l"   -- a stop line
def vD : Arg := .var "d"   -- a yield sign
def vU : Arg := .var "u"   -- another road user
def vH : Arg := .var "h"   -- a highway

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

-- ---------------------------------------------------------------------------------------------
-- Leaves
-- ---------------------------------------------------------------------------------------------
def occupies (a b : Arg) : Formula := .atom "rel_occupies" [a, b] []
/-- The subject's footprint overlaps the intersection r. -/
def inR : Formula := occupies vSubject vR
/-- The mark m is recorded as marking the entrance of carrier c. -/
def marksC (mk : Arg) : Formula := .atom "st_entrance_of" [mk, vC] []
/-- Signed distance from the subject's reference point to region m along c's designated direction. -/
def offsetAlongC (mk : Arg) : Term := .quantity "prim_region_offset_along" [vSubject, mk, vC] []
/-- Ground distance from the subject's body to region m. -/
def gapTo (mk : Arg) : Term := .measure "st_region_geometry_distance" [vSubject, mk]
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- φ at the observation before an entry into r (see header). -/
def prevAtEntry (χ : Formula) : Formula := .rises (.or inR (.not χ))

-- ---------------------------------------------------------------------------------------------
-- Which mark governs c
-- ---------------------------------------------------------------------------------------------
def crosswalkMarksC : Formula := .existsRegion (.lit "crosswalk") "x" (marksC vX)
def noCrosswalkMarksC : Formula := .forallRegion (.lit "crosswalk") "x" (.not (marksC vX))
def stopLineMarksC : Formula := .existsRegion (.lit "stop_line") "l" (marksC vL)
def noStopLineMarksC : Formula := .forallRegion (.lit "stop_line") "l" (.not (marksC vL))

-- ---------------------------------------------------------------------------------------------
-- s4: the halt at the governing place
-- ---------------------------------------------------------------------------------------------
/-- (1) Off a crosswalk marking c, short of it, within the tolerance. -/
def atCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "x"
    (.and (marksC vX)
      (.and (.not (occupies vSubject vX))
        (.and (.cmp (offsetAlongC vX) .gt zeroMetres)
          (.cmp (gapTo vX) .le pStopPointTolerance))))

/-- (2) No crosswalk marks c; not past a stop line marking c, within the tolerance. -/
def atStopLine : Formula :=
  .and noCrosswalkMarksC
    (.existsRegion (.lit "stop_line") "l"
      (.and (marksC vL)
        (.and (.cmp (offsetAlongC vL) .ge zeroMetres)
          (.cmp (gapTo vL) .le pStopPointTolerance))))

/-- (3) Neither marks c; off r, short of it along c, within the tolerance. -/
def atEdge : Formula :=
  .and noCrosswalkMarksC
    (.and noStopLineMarksC
      (.and (.not inR)
        (.and (.cmp (offsetAlongC vR) .gt zeroMetres)
          (.cmp (gapTo vR) .le pStopPointTolerance))))

def haltAtPlace : Formula := .and halted (.or atCrosswalk (.or atStopLine atEdge))

-- ---------------------------------------------------------------------------------------------
-- The approach start: on c, outside the governing mark's stopping zone upstream
-- ---------------------------------------------------------------------------------------------
def upstreamOfCrosswalk : Formula :=
  .and crosswalkMarksC
    (.forallRegion (.lit "crosswalk") "x"
      (.implies (marksC vX)
        (.and (.not (occupies vSubject vX))
          (.and (.cmp (offsetAlongC vX) .gt zeroMetres)
            (.cmp (gapTo vX) .gt pStopPointTolerance)))))

def upstreamOfStopLine : Formula :=
  .and noCrosswalkMarksC
    (.and stopLineMarksC
      (.forallRegion (.lit "stop_line") "l"
        (.implies (marksC vL)
          (.and (.not (occupies vSubject vL))
            (.and (.cmp (offsetAlongC vL) .gt zeroMetres)
              (.cmp (gapTo vL) .gt pStopPointTolerance))))))

def upstreamOfEdge : Formula :=
  .and noCrosswalkMarksC
    (.and noStopLineMarksC
      (.and (.not inR)
        (.and (.cmp (offsetAlongC vR) .gt zeroMetres)
          (.cmp (gapTo vR) .gt pStopPointTolerance))))

def approachStart : Formula :=
  .and (occupies vSubject vC) (.or upstreamOfCrosswalk (.or upstreamOfStopLine upstreamOfEdge))

/-- An observation the search passes through: neither the approach start nor in r. -/
def inApproach : Formula := .and (.not approachStart) (.not inR)

/-- ψ at some observation from the approach start (or the last observation in r) to t-1. -/
def searched (ψ : Formula) : Formula := prevAtEntry (.since inApproach ψ)

-- ---------------------------------------------------------------------------------------------
-- s2: the entry into r through a yield-governed approach carrier c
-- ---------------------------------------------------------------------------------------------
def yieldGovernsC : Formula :=
  .existsDevice (.lit "yield_sign") "d" (.atom "dev_governs" [vD, vC] [])

def approachCarrier : Formula :=
  .and (occupies vSubject vC) (.and (.atom "st_lane_enters" [vC, vR] []) yieldGovernsC)

def entryThroughC : Formula := .and (.rises inR) (prevAtEntry approachCarrier)

-- ---------------------------------------------------------------------------------------------
-- s3: a stop required for safety
-- ---------------------------------------------------------------------------------------------
def conflict : Formula :=
  .existsUser "u"
    (.and (.not (.same vU vSubject))
      (.and (.atom "ru_aggregate" [vU, .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.existsRegion (.lit "highway") "h" (occupies vU vH))
          (.and (.derived "prim_closest_approach_within" [vSubject, vU] [pConflictHorizon])
            (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vU] [pConflictHorizon])
              .lt pConflictCentreClearance)))))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s2 (trigger): approaching a yield sign; s3: a stop required for safety. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "r"
    (.existsRegion (.lit "travel_region") "c"
      (.and entryThroughC (searched conflict)))

/-- Obligation: s4, through every carrier the applicability's selection admits. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "r"
    (.forallRegion (.lit "travel_region") "c"
      (.implies entryThroughC (searched haltAtPlace)))

def rule : Rule :=
  { id := "NRS_484A_450_3"
    laws := ["NRS-484A-450-3"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "required for safety to stop"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: a stop is required for safety where, at some observation of the approach, some other road user of traffic (the traffic of s4, occupying a highway) and the subject approach each other within the time-to-collision threshold p.conflict_horizon (prim.closest_approach_within) to a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance), the envelope within which two bodies collide or nearly collide"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s4"
          why := "The approach start that ends the search into the past is read with the subject on the approach carrier c itself (one of the carriers the governing mark is recorded as marking): an exit from the stopping zone upstream observed while the subject is on another carrier the same mark marks does not end the search, which then runs further back (to an approach start on c, an observation in r, or the recording's start, where it is unknown)."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484A_450_3
