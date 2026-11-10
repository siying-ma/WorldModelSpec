/-
  NRS_484B_250_4_o1 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): When a vehicle
    s2 (trigger): enters an intersection
    s3 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,
    s4 (condition): but is inoperative at the time the vehicle enters the intersection,
    s5 (subject): the driver of the vehicle
    s6 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection
    s7 (standard): where the driver has a view of approaching traffic on the through highway.
    s8 (sibling): After making such a stop, the driver shall proceed cautiously, yielding to vehicles which have previously completed a stop or are within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.intersection'], derived []
    s3: atoms ['dev.traffic_signal', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    s4: atoms ['dev.inoperative'], derived []
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'prim.region_offset_along'], derived ['drv.motion.stopped']

  How each span is written.
    s1, s5: the class of x is `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s2: the entry of x into an intersection i is `rises (rel_occupies x i)` — x's footprint overlaps
        i here and did not at the observation before.
    s3: a head d of kind traffic_signal, `dev_traffic_signal_uncovered d` (the atom's uncovered
        attribute: installed, faces not covered), controls i where `dev_governs d i`, or where it
        governs a travel region c with `st_lane_enters c i`.
    s4: every uncovered head that governs i or x's approach carrier is `dev_inoperative` at the
        entry observation (the applicability is read at that observation).
    The applicability is: some intersection i is entered and selected so (`selected`). The
    obligation re-states that whole selection for every intersection (`forallRegion`), so it
    speaks of the same i.
    s6: the approach carrier c is a travel region x occupies at the observation before the entry
        (`prev`) with `st_lane_enters c i`. Where several such carriers give different verdicts the
        duty is unknown (`definedWhen`), and it is unknown where no such carrier is found. The place,
        in order: a stop line s with `st_entrance_of s c`; where every stop line's association with
        c is observed and none marks c, a crosswalk w with `st_entrance_of w c`, the halt made with
        x's footprint not overlapping w; where neither marks c, the entrance end of c at i, the halt
        made outside i where the s7 standard holds. The act is `drv_motion_stopped x` with
        p.motion_speed_tolerance while x occupies c and not i, with
        `prim_region_offset_along x place c` at least zero (upstream of the place, on it counting)
        and `st_region_geometry_distance x place` at most p.stop_point_tolerance.
        The search runs back from the observation before the entry (`prev` of a `since`): it is met
        at an observation of the act, and ends where x occupies i (the previous visit to i) or at
        the approach start — x on a carrier the place marks (for the entrance end: a carrier that
        enters i), with the place ahead along that carrier (offset above zero) and its body farther
        from the place than p.stop_point_tolerance. Reaching the trace start without either is
        unknown (`since`'s unobserved past).
    s7: `st_sight_along_way x h` at least p.approach_view_sight_distance for some highway h with
        `st_on_way i h` and not `st_on_way c h`, at the halt observation.

  Choices the record left open (declared as narrowings):
    s6: the search's end at x's previous entry is read as any earlier observation at which x
        occupies i, whichever place that visit came through.
    s6: where several stop lines (or crosswalks) are recorded as marking c, a halt at any of them
        meets the duty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pApproachViewSightDistance : Term := .param "p.approach_view_sight_distance"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

-- ---------------------------------------------------------------------------------------------
-- Leaves
-- ---------------------------------------------------------------------------------------------

/-- x's footprint overlaps region `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vX, .var r] []

/-- φ at the observation before: φ false here after true, or true here and not newly so. -/
def prev (φ : Formula) : Formula := .or (.rises (.not φ)) (.and φ (.not (.rises φ)))

/-- Carrier `c`'s entrance end is intersection `i`. -/
def entersI (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []

/-- Device `d` governs region `r`. -/
def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []

/-- Stop line or crosswalk `l` is recorded as marking carrier `c`'s entrance. -/
def marks (l c : String) : Formula := .atom "st_entrance_of" [.var l, .var c] []

/-- Signed distance from x's reference point to region `r` along carrier `l`'s direction. -/
def offsetAlong (r l : String) : Term := .quantity "prim_region_offset_along" [vX, .var r, .var l] []

/-- Ground distance from x's body to region `r`. -/
def distTo (r : String) : Term := .measure "st_region_geometry_distance" [vX, .var r]

/-- x at a complete halt. -/
def stopped : Formula := .derived "drv_motion_stopped" [vX] [pMotionSpeedTolerance]

-- ---------------------------------------------------------------------------------------------
-- Applicability: s2, s3, s4
-- ---------------------------------------------------------------------------------------------

/-- s2: x enters intersection `i` at this observation. -/
def entry (i : String) : Formula := .rises (occ i)

/-- x's approach carrier `c` into `i`: occupied at the observation before, entrance end `i`. -/
def approachCarrier (c i : String) : Formula := .and (prev (occ c)) (entersI c i)

/-- s3: uncovered signal head `d` controls `i`: it governs `i`, or a carrier entering `i`. -/
def controls (d i : String) : Formula :=
  .and (.atom "dev_traffic_signal_uncovered" [.var d] [])
    (.or (governs d i)
      (.existsRegion (.lit "travel_region") "cg" (.and (governs d "cg") (entersI "cg" i))))

/-- s4's heads: uncovered head `d` governing `i` or x's approach carrier into `i`. -/
def governsApproach (d i : String) : Formula :=
  .and (.atom "dev_traffic_signal_uncovered" [.var d] [])
    (.or (governs d i)
      (.existsRegion (.lit "travel_region") "ca" (.and (approachCarrier "ca" i) (governs d "ca"))))

/-- The intersection `i` the rule is judged at: entered by x now, controlled by an uncovered signal
    head, every such head governing it or x's approach being inoperative. -/
def selected (i : String) : Formula :=
  .and (entry i)
    (.and (.existsDevice (.lit "traffic_signal") "d" (controls "d" i))
      (.forallDevice (.lit "traffic_signal") "d"
        (.implies (governsApproach "d" i) (.atom "dev_inoperative" [.var "d"] []))))

/-- Applicability: s2 (trigger): enters an intersection; s3 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered,; s4 (condition): but is inoperative at the time the vehicle enters the intersection, -/
def applicability : Formula := .existsRegion (.lit "intersection") "i" (selected "i")

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

-- ---------------------------------------------------------------------------------------------
-- Obligation: s6, s7
-- ---------------------------------------------------------------------------------------------

/-- The halt at place `p` on carrier `c`: stopped, on `c`, outside `i`, not past `p` along `c`,
    within the stop-point tolerance of `p`. -/
def haltAt (p c i : String) : Formula :=
  .and stopped
    (.and (occ c)
      (.and (.not (occ i))
        (.and (.cmp (offsetAlong p c) .ge zeroMetres)
          (.cmp (distTo p) .le pStopPointTolerance))))

/-- On carrier `k`, with place `p` ahead along it and farther than the stop-point tolerance. -/
def shortOfZone (p k : String) : Formula :=
  .and (occ k)
    (.and (.cmp (offsetAlong p k) .gt zeroMetres) (.cmp (distTo p) .gt pStopPointTolerance))

/-- Approach start for a mark `p`: x on a carrier `p` marks, outside `p`'s stopping zone upstream. -/
def startMarked (p : String) : Formula :=
  .existsRegion (.lit "travel_region") "k" (.and (marks p "k") (shortOfZone p "k"))

/-- Approach start for the entrance end at `i`: x on a carrier entering `i`, outside the zone. -/
def startEnd (i : String) : Formula :=
  .existsRegion (.lit "travel_region") "k" (.and (entersI "k" i) (shortOfZone i "k"))

/-- The search back from the observation before the entry: the act found before x is seen in `i`
    again or at the approach start. -/
def search (act start : Formula) (i : String) : Formula :=
  prev (.since (.not (.or (occ i) start)) act)

/-- s7: a through highway `h` — one `i` lies on and `c` does not — seen along at least the bound. -/
def view (i c : String) : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [.var i, .var "h"] [])
      (.and (.not (.atom "st_on_way" [.var c, .var "h"] []))
        (.cmp (.measure "st_sight_along_way" [vX, .var "h"]) .ge pApproachViewSightDistance)))

/-- No region of kind `kind` is recorded as marking `c`. -/
def noMark (kind v c : String) : Formula := .forallRegion (.lit kind) v (.not (marks v c))

/-- The duty through approach carrier `c` into `i`, its place chosen in the words' order. -/
def dutyThrough (c i : String) : Formula :=
  .or
    (.existsRegion (.lit "stop_line") "s"
      (.and (marks "s" c) (search (haltAt "s" c i) (startMarked "s") i)))
    (.or
      (.and (noMark "stop_line" "s" c)
        (.existsRegion (.lit "crosswalk") "w"
          (.and (marks "w" c)
            (search (.and (haltAt "w" c i) (.not (occ "w"))) (startMarked "w") i))))
      (.and (noMark "stop_line" "s" c)
        (.and (noMark "crosswalk" "w" c)
          (search (.and (haltAt i c i) (view i c)) (startEnd i) i))))

/-- The duty at the entry into `i`: met through every approach carrier; unknown where none is
    found, or where the carriers x occupied give different verdicts. -/
def duty (i : String) : Formula :=
  let everyC : Formula :=
    .forallRegion (.lit "travel_region") "c" (.implies (approachCarrier "c" i) (dutyThrough "c" i))
  let someC : Formula :=
    .existsRegion (.lit "travel_region") "c" (.and (approachCarrier "c" i) (dutyThrough "c" i))
  let found : Formula := .existsRegion (.lit "travel_region") "c" (approachCarrier "c" i)
  .definedWhen (.and found (.or everyC (.not someC))) everyC

/-- Obligation: s6 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection; s7 (standard): where the driver has a view of approaching traffic on the through highway. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i" (.implies (selected "i") (duty "i"))

def rule : Rule :=
  { id := "NRS_484B_250_4_o1"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "has a view of approaching traffic on the through highway"
          concepts := ["st.highway", "st.on_way", "st.sight_along_way"]
          params := ["p.approach_view_sight_distance"]
          convention := "The view of approaching traffic on the through highway is a sight distance along that way, st.sight_along_way 'the distance along a way, in each direction from the point of that way nearest a road user, within which another vehicle on that way could be seen from the road user's eye', at least the stopping sight distance of the approach-speed design convention (AASHTO stopping sight distance). The through highway is a st.highway ('the entire public way between its boundary lines') that the intersection lies on (st.on_way 'an intersection lies on every way that meets there') and the subject's approach carrier does not."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s6"
          why := "The search's end at x's previous entry into the intersection is read as any earlier observation at which x occupies the intersection, whichever place that visit came through."
          kind := "reading" }
      , { span := "s6"
          why := "Where several stop lines (or several crosswalks) are recorded as marking the approach carrier, a halt at any one of them meets the duty."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o1
