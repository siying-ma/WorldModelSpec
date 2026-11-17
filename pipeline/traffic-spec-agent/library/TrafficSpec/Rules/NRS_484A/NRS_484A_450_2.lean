/-
  NRS_484A_450_2 — NRS-484A-450-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every driver of a vehicle
    s2 (trigger): approaching a stop intersection indicated by a stop sign
    s3 (obligation): shall stop before entering the crosswalk on the near side of the intersection or, if there is no crosswalk, shall stop at a clearly marked stop line, or if none, then at the point nearest the intersecting highway where the driver has a view of approaching traffic on the intersecting highway
    s9 (trigger): before entering the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['dev.stop_sign', 'dev.governs', 'rel.occupies', 'st.lane_enters', 'st.intersection', 'st.travel_region'], derived []
    s3: atoms ['st.crosswalk', 'st.stop_line', 'st.entrance_of', 'rel.occupies', 'st.intersection', 'st.region_geometry', 'prim.region_offset_along', 'st.lane_direction'], derived ['drv.motion.complete_halt']
    s9: atoms ['rel.occupies', 'st.intersection'], derived []

  How each span is written.
    s1: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` (the binder's class).
    s2 + s9 (applicability): for some intersection r the subject occupies at t, and some travel
      region c, `rises (occ r ∨ ¬P(c, r))` holds, where P(c, r) = occ c ∧ st_lane_enters(c, r) ∧
      some stop sign governs c. Together with occ r at t this is exactly "occ r at t, not occ r at
      t-1, and P(c, r) at t-1" (the entry into r at t through the approach carrier c occupied at
      t-1 and governed by a stop sign). The language has no "previous observation" operator; the
      `rises` of that disjunction is how the value at t-1 is read.
    s3 (obligation): for every intersection r and travel region c selected as in the
      applicability (the whole selection is written again), the search for the halt is
      `since (¬start ∧ ¬rises(occ r)) halted` read at t-1, through the same `rises` device:
      `rises (occ r ∨ ¬(P(c, r) ∧ search))`, which, where the selection holds, equals the search at
      t-1.
      - halted: drv.motion.complete_halt (speed_tol = p.halt_speed_tolerance) at a place of the
        governing kind, in the record's order: (1) some crosswalk x with st_entrance_of(x, c),
        footprint off x, offset along c's direction (prim_region_offset_along subject x c) > 0 and
        st_region_geometry_distance ≤ p.stop_point_tolerance; (2) no crosswalk marks c and some
        stop line l with st_entrance_of(l, c), offset ≥ 0 and distance ≤ tolerance; (3) neither
        marks c, footprint off r, offset to r along c > 0 and distance to r ≤ tolerance. Several
        marks of the governing kind: any of them (existential).
      - start (the approach start): the subject, on a travel region c2 it occupies that a mark of
        the governing kind is recorded as marking, is outside the zone upstream of every mark of
        that kind marking c (off it, offset > 0, distance > tolerance). For branch (3), where no
        mark exists, the carrier is one entering r (st_lane_enters(c2, r)) and the zone is r's.
      - the previous entry into r: `rises (occ r)` inside the search ends it.
      - The recording's start ends nothing: `since` is unknown there (the unobserved past).
    st.lane_direction is read through prim.region_offset_along (its contract reads the carrier's
    direction as `st_lane_direction`); st.region_geometry through its ground-distance accessor.

  Choices the record left open: the approach start of branch (3) (no mark) is read on a carrier
  entering r, since no mark marks any carrier there; nothing else.

  Kleene note: an unobserved dev.governs of c leaves the applicability unknown, and Core's
  `verdictAt` then reports unknown whatever the obligation.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484A_450_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

-- ---------------------------------------------------------------------------------------------
-- Leaves
-- ---------------------------------------------------------------------------------------------

/-- rel.occupies: the subject's footprint overlaps region `v`. -/
def occ (v : String) : Formula := .atom "rel_occupies" [vSubject, .var v] []

/-- st.entrance_of: mark `l` is recorded as marking carrier `a`'s entrance. -/
def marks (l a : String) : Formula := .atom "st_entrance_of" [.var l, .var a] []

/-- st.lane_enters: carrier `c` is an approach to intersection `r`. -/
def entersInto (c r : String) : Formula := .atom "st_lane_enters" [.var c, .var r] []

/-- prim.region_offset_along: signed distance from the subject to region `y` along `c`'s direction. -/
def offsetAlong (y c : String) : Term := .quantity "prim_region_offset_along" [vSubject, .var y, .var c] []

/-- st.region_geometry: ground distance from the subject's body to region `y`. -/
def gap (y : String) : Term := .measure "st_region_geometry_distance" [vSubject, .var y]

/-- drv.motion.complete_halt of the subject. -/
def atRest : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

-- ---------------------------------------------------------------------------------------------
-- The approach: carrier c, occupied, entering r, governed by a stop sign
-- ---------------------------------------------------------------------------------------------

/-- P(c, r): the subject occupies c, c is an approach to r, and a stop sign governs c. -/
def approach (c r : String) : Formula :=
  .and (occ c)
    (.and (entersInto c r)
      (.existsDevice (.lit "stop_sign") "d" (.atom "dev_governs" [.var "d", .var c] [])))

/-- The entry at t into r through c: occ r at t, and at t-1 not occ r and P(c, r). -/
def entryThrough (c r : String) : Formula :=
  .and (occ r) (.rises (.or (occ r) (.not (approach c r))))

-- ---------------------------------------------------------------------------------------------
-- The places, read through c (and r)
-- ---------------------------------------------------------------------------------------------

/-- Some crosswalk is recorded as marking c. -/
def crosswalkMarks (c : String) : Formula := .existsRegion (.lit "crosswalk") "xq" (marks "xq" c)

/-- Some stop line is recorded as marking c. -/
def stopLineMarks (c : String) : Formula := .existsRegion (.lit "stop_line") "lq" (marks "lq" c)

/-- The crosswalk stopping zone of `y`: off it, short of it along c, within the tolerance. -/
def crosswalkZone (y c : String) : Formula :=
  .and (.not (occ y))
    (.and (.cmp (offsetAlong y c) .gt zeroMetres) (.cmp (gap y) .le pStopPointTolerance))

/-- The stop-line stopping zone of `y`: not past it along c, within the tolerance. -/
def stopLineZone (y c : String) : Formula :=
  .and (.cmp (offsetAlong y c) .ge zeroMetres) (.cmp (gap y) .le pStopPointTolerance)

/-- Outside the zone of `y` upstream: off it, short of it along c, farther than the tolerance. -/
def upstreamOf (y c : String) : Formula :=
  .and (.not (occ y))
    (.and (.cmp (offsetAlong y c) .gt zeroMetres) (.cmp (gap y) .gt pStopPointTolerance))

/-- The act: a complete halt at the governing place. -/
def haltedAtPlace (c r : String) : Formula :=
  .and atRest
    (.or (.existsRegion (.lit "crosswalk") "xh" (.and (marks "xh" c) (crosswalkZone "xh" c)))
      (.or (.and (.not (crosswalkMarks c))
              (.existsRegion (.lit "stop_line") "lh" (.and (marks "lh" c) (stopLineZone "lh" c))))
        (.and (.not (crosswalkMarks c))
          (.and (.not (stopLineMarks c)) (crosswalkZone r c)))))

/-- On a carrier `c2` that a mark of kind `k` marking c is also recorded as marking. -/
def onMarkedCarrier (k : String) (c : String) : Formula :=
  .existsRegion (.lit "travel_region") "cm"
    (.and (occ "cm")
      (.existsRegion (.lit k) "ym" (.and (marks "ym" c) (marks "ym" "cm"))))

/-- The approach start: on a carrier the governing mark marks, outside the zone upstream of every
    governing mark; with no mark, on a carrier entering r, outside r's zone upstream. -/
def approachStart (c r : String) : Formula :=
  .or (.and (onMarkedCarrier "crosswalk" c)
        (.forallRegion (.lit "crosswalk") "xs" (.implies (marks "xs" c) (upstreamOf "xs" c))))
    (.or (.and (.not (crosswalkMarks c))
          (.and (onMarkedCarrier "stop_line" c)
            (.forallRegion (.lit "stop_line") "ls" (.implies (marks "ls" c) (upstreamOf "ls" c)))))
      (.and (.not (crosswalkMarks c))
        (.and (.not (stopLineMarks c))
          (.and (.existsRegion (.lit "travel_region") "ce" (.and (occ "ce") (entersInto "ce" r)))
            (upstreamOf r c)))))

/-- The search back: the halt found with no approach start and no entry into r after it. -/
def search (c r : String) : Formula :=
  .since (.and (.not (approachStart c r)) (.not (.rises (occ r)))) (haltedAtPlace c r)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s2 (trigger): approaching a stop intersection indicated by a stop sign; s9 (trigger): before entering the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "r"
    (.existsRegion (.lit "travel_region") "c" (entryThrough "c" "r"))

/-- Obligation: s3 (obligation): shall stop before entering the crosswalk on the near side of the intersection or, if there is no crosswalk, shall stop at a clearly marked stop line, or if none, then at the point nearest the intersecting highway where the driver has a view of approaching traffic on the intersecting highway -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "r"
    (.forallRegion (.lit "travel_region") "c"
      (.implies (entryThrough "c" "r")
        (.rises (.or (occ "r") (.not (.and (approach "c" "r") (search "c" "r")))))))

def rule : Rule :=
  { id := "NRS_484A_450_2"
    laws := ["NRS-484A-450-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484A_450_2
