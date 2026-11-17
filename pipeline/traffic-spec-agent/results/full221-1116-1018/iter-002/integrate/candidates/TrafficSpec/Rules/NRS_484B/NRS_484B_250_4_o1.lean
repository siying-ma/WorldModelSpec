/-
  NRS_484B_250_4_o1 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    v (subject): When a vehicle
    t1 (trigger): enters an intersection
    t2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,
    t3 (condition): but is inoperative at the time the vehicle enters the intersection,
    dr (subject): the driver of the vehicle
    o (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    p1 (sibling): After making such a stop,
    p2 (sibling): the driver shall proceed cautiously,
    p3 (sibling): yielding
    p4 (sibling): to vehicles which have previously completed a stop
    p5 (sibling): or are within the intersection.

  Elements (span → atoms, derived):
    v: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    t1: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    t2: atoms ['dev.traffic_signal', 'dev.governs'], derived []
    t3: atoms ['dev.inoperative'], derived []
    dr: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    o: atoms ['rel.occupies', 'st.lane_enters', 'st.intersection', 'st.stop_line', 'st.entrance_of', 'prim.region_offset_along', 'st.lane_direction', 'st.region_geometry', 'st.crosswalk', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.complete_halt']

  How each span is written.
    v, dr: the binder's class is `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    t1: the entry into an intersection X (`existsRegion intersection`) through a carrier c
      (`existsRegion travel_region`, `st_lane_enters c X`): `rises (occupies X)` (the footprint
      overlaps X now and did not at the previous observation) and
      `rises (occupies X ∨ ¬ occupies c)` (given the former, exactly: c occupied at the previous
      observation). An unobserved occupancy at the previous observation leaves the entry unknown.
    t2: some traffic signal d (`existsDevice traffic_signal`) whose faces are uncovered
      (`dev_traffic_signal_uncovered`) and which governs c or X (`dev_governs`).
    t3: `dev_inoperative d`, read at the entry observation.
    o: the obligation restates the whole selection of X and c (entry, governing inoperative
      signal) for every such pair, and requires the stop search to succeed at the observation
      just before the entry, read through `rises (occupies X ∨ ¬ search)`: at an entry, where X is
      occupied now and was not before, this is exactly `search` at the previous observation, so
      the current entry never counts as "the previous entry into X".
      `search` is `since (¬ previousEntry ∧ ¬ approachStart) haltAtPlace`: a halt at the place is
      found going back before either end; reaching an end first is false (violated); reaching
      the trace start with neither is Core's `windowTruncated since` (unknown). The previous entry
      is `rises (occupies X)`.
      The place, in the words' order, by the marks the source records for c (`st_entrance_of`):
      (1) some stop line marks c: a halt (`drv_motion_complete_halt`, `p.halt_speed_tolerance`)
          while occupying c, with a line marking c at or ahead of the reference point along c
          (`prim_region_offset_along ≥ 0`) and the body within `p.stop_point_tolerance` of it
          (`st_region_geometry_distance`);
      (2) no stop line marks c, some crosswalk does: the halt with the footprint off a crosswalk
          marking c, that crosswalk ahead (`offset > 0`) and the body within the tolerance;
      (3) neither: the halt with the footprint off X and the body within the tolerance of X.
      The approach start for the same place: the subject on a carrier c' (`occupies`) the place
      marks — for (1)/(2) every stop line / crosswalk marking c also marks c' and lies ahead along
      c's direction (`offset > 0`) farther than the tolerance from the body; for (3) c' enters X
      and X lies ahead farther than the tolerance. "Off the mark" is carried by the distance:
      a body farther than the tolerance from a mark does not overlap it (distance zero on overlap).
      The case split is written `(B1 ∧ ·) ∨ (¬B1 ∧ B2 ∧ ·) ∨ (¬B1 ∧ ¬B2 ∧ ·)`, so an unobserved
      association of a mark with c leaves the verdict unknown where it would select the branch.
      The record's observable readings (clarity of paint; the view of approaching traffic on the
      through highway read as c's entrance end; the driver read through the vehicle) are the
      plan's.

  Choices the record left open.
    - Several carriers c through which the subject entered X: the obligation is stated for every
      selected carrier (`forallRegion`), so the rule never picks the carrier that favours the
      subject.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The subject's footprint overlaps region `r` (rel.occupies). -/
def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- Carrier `c` is an approach to intersection `x` (st.lane_enters). -/
def laneEnters (c x : String) : Formula := .atom "st_lane_enters" [.var c, .var x] []

/-- Mark `k` (a stop line or a crosswalk) marks the entrance of carrier `c` (st.entrance_of). -/
def entranceOf (k c : String) : Formula := .atom "st_entrance_of" [.var k, .var c] []

/-- Signed distance from the subject's reference point to region `r` along carrier `c`'s direction. -/
def offsetAlong (r c : String) : Term := .quantity "prim_region_offset_along" [vSubject, .var r, .var c] []

/-- Ground distance from the subject's body to region `r` (st.region_geometry). -/
def distTo (r : String) : Term := .measure "st_region_geometry_distance" [vSubject, .var r]

/-- The subject is at rest (drv.motion.complete_halt). -/
def halt : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- t1: the entry into `x` from carrier `c`: the footprint overlaps `x` now and did not at the
    previous observation, at which it occupied `c`; `c` is an approach to `x`. -/
def entry (x c : String) : Formula :=
  .and (.rises (occ x))
    (.and (.rises (.or (occ x) (.not (occ c))))
      (laneEnters c x))

/-- t2, t3: an installed, uncovered traffic signal governing `c` or `x`, inoperative now. -/
def signalInoperative (x c : String) : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.atom "dev_traffic_signal_uncovered" [.var "d"] [])
      (.and (.or (.atom "dev_governs" [.var "d", .var c] []) (.atom "dev_governs" [.var "d", .var x] []))
        (.atom "dev_inoperative" [.var "d"] [])))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: t1 (trigger): enters an intersection; t2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,; t3 (condition): but is inoperative at the time the vehicle enters the intersection, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "X"
    (.existsRegion (.lit "travel_region") "c"
      (.and (entry "X" "c") (signalInoperative "X" "c")))

/-- Some stop line marks `c`'s entrance. -/
def lineMarks (c : String) : Formula :=
  .existsRegion (.lit "stop_line") "L" (entranceOf "L" c)

/-- Some crosswalk marks `c`'s entrance. -/
def walkMarks (c : String) : Formula :=
  .existsRegion (.lit "crosswalk") "W" (entranceOf "W" c)

/-- (1) at a stop line marking `c`: the line at or ahead of the reference point along `c`, the
    body within the stop-point tolerance of it. -/
def atLine (c : String) : Formula :=
  .existsRegion (.lit "stop_line") "L"
    (.and (entranceOf "L" c)
      (.and (.cmp (offsetAlong "L" c) .ge zeroMetres)
        (.cmp (distTo "L") .le pStopPointTolerance)))

/-- (2) before a crosswalk marking `c`: the footprint off it, the crosswalk ahead along `c`, the
    body within the stop-point tolerance of it. -/
def beforeWalk (c : String) : Formula :=
  .existsRegion (.lit "crosswalk") "W"
    (.and (entranceOf "W" c)
      (.and (.not (occ "W"))
        (.and (.cmp (offsetAlong "W" c) .gt zeroMetres)
          (.cmp (distTo "W") .le pStopPointTolerance))))

/-- (3) at `c`'s entrance end: the footprint off `x`, the body within the stop-point tolerance of it. -/
def atEntranceEnd (x : String) : Formula :=
  .and (.not (occ x)) (.cmp (distTo x) .le pStopPointTolerance)

/-- The place for `c`, in the words' order. -/
def atPlace (x c : String) : Formula :=
  .or (.and (lineMarks c) (atLine c))
    (.or (.and (.not (lineMarks c)) (.and (walkMarks c) (beforeWalk c)))
      (.and (.not (lineMarks c)) (.and (.not (walkMarks c)) (atEntranceEnd x))))

/-- A complete halt while occupying `c` at the place for `c`. -/
def haltAtPlace (x c : String) : Formula :=
  .and halt (.and (occ c) (atPlace x c))

/-- Outside the stop lines' stopping zone upstream: every line marking `c` also marks `a`, lies
    ahead along `c` and farther from the body than the stop-point tolerance. -/
def upstreamOfLines (c a : String) : Formula :=
  .forallRegion (.lit "stop_line") "L"
    (.implies (entranceOf "L" c)
      (.and (entranceOf "L" a)
        (.and (.cmp (offsetAlong "L" c) .gt zeroMetres)
          (.cmp (distTo "L") .gt pStopPointTolerance))))

/-- Outside the crosswalks' stopping zone upstream, likewise. -/
def upstreamOfWalks (c a : String) : Formula :=
  .forallRegion (.lit "crosswalk") "W"
    (.implies (entranceOf "W" c)
      (.and (entranceOf "W" a)
        (.and (.cmp (offsetAlong "W" c) .gt zeroMetres)
          (.cmp (distTo "W") .gt pStopPointTolerance))))

/-- Outside the entrance end's stopping zone upstream: `a` enters `x`, `x` ahead along `c` and
    farther from the body than the stop-point tolerance. -/
def upstreamOfEntrance (x c a : String) : Formula :=
  .and (laneEnters a x)
    (.and (.cmp (offsetAlong x c) .gt zeroMetres)
      (.cmp (distTo x) .gt pStopPointTolerance))

/-- The approach start: the subject on a carrier the place marks, outside its stopping zone upstream. -/
def approachStart (x c : String) : Formula :=
  .existsRegion (.lit "travel_region") "cA"
    (.and (occ "cA")
      (.or (.and (lineMarks c) (upstreamOfLines c "cA"))
        (.or (.and (.not (lineMarks c)) (.and (walkMarks c) (upstreamOfWalks c "cA")))
          (.and (.not (lineMarks c)) (.and (.not (walkMarks c)) (upstreamOfEntrance x c "cA"))))))

/-- The search back for the halt, ending at the approach start or the previous entry into `x`. -/
def search (x c : String) : Formula :=
  .since (.and (.not (.rises (occ x))) (.not (approachStart x c))) (haltAtPlace x c)

/-- Obligation: o (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "X"
    (.forallRegion (.lit "travel_region") "c"
      (.implies (.and (entry "X" "c") (signalInoperative "X" "c"))
        (.rises (.or (occ "X") (.not (search "X" "c"))))))

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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o1
