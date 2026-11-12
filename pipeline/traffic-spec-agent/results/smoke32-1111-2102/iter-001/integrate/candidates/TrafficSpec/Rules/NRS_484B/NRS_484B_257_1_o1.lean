/-
  NRS_484B_257_1_o1 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    g1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    g2 (condition): When proper signs have been erected,
    g3 (subject): the driver of a vehicle
    g4 (obligation): shall stop or yield
    g5 (condition): at a clearly marked stop line
    g6 (condition): or, if there is none, before entering the crosswalk on the near side of the intersection
    g7 (condition): or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    g8 (sibling): After having stopped or, in the event of a yield sign, slowed or stopped,
    g9 (sibling): the driver
    g10 (sibling): shall yield
    g11 (sibling): the right-of-way
    g12 (sibling): to other vehicles which have entered the intersection from such through highway
    g13 (sibling): or which are approaching so closely on such through highway as to constitute an immediate hazard
    g14 (sibling): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    g1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.governs', 'dev.inoperative'], derived []
    g2: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    g3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    g4: atoms ['kin.path_length'], derived ['drv.motion.at_rest', 'drv.motion.decelerating']
    g5: atoms ['st.stop_line', 'st.entrance_of', 'st.region_geometry', 'st.lane_direction', 'prim.region_offset_along'], derived []
    g6: atoms ['st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'rel.occupies', 'st.lane_direction', 'prim.region_offset_along'], derived []
    g7: atoms ['st.intersection', 'st.region_geometry', 'rel.occupies', 'st.lane_enters'], derived []

  How each span is written.
    g3: ego's class is the aggregate DEF-NRS-484A-320::vehicle (`ru_aggregate`).
    g2 + the event: the judged observation is an entry of ego into an intersection i (quantified
      over `intersection`) through a carrier c (quantified over `travel_region`) whose entrance end
      is i (`st_lane_enters c i`): ego occupies i here, and at the observation before it occupied c
      and not i. "At the observation before" is read through `rises`: `rises (occ i ∨ ¬occ c)`,
      with occ i here, holds exactly where occ i holds here and, before, occ i failed and occ c held.
      A stop sign or a yield sign governs c (`existsDevice` of the kind, `dev_governs d c`).
    g1: not where ego, a member of DEF-NRS-484A-285::traffic, is controlled at the entry by a
      human direction of role police_officer governing c or i, or by a traffic signal head
      governing c or i that is not inoperative.
    g5/g6/g7 (the place, per carrier c): the stop line recorded as marking c (`st_entrance_of s c`);
      else, where no stop line marks c (the source's list complete: an unobserved list leaves the
      negation unknown), the crosswalk marking c; else, where neither marks c, the entrance end of
      c at i. "At" the place: body distance (`st_region_geometry_distance`) within
      p.stop_point_tolerance and not past it, the side the sign of `prim_region_offset_along`
      (ego's reference point to the place along c's designated direction) at or above zero; at
      the crosswalk and at i, ego's footprint does not overlap the place (`rel_occupies` false).
    g4 (the act): ego on c, at the place, and either at rest (`drv_motion_at_rest`), or, where no
      stop sign governs c (so a yield sign alone does), decelerating (`drv_motion_decelerating`) at
      some observation of the `.path` window of length p.yield_slowing_distance behind (the
      negation of `holdsFor` of its negation).
    The search: `since (¬act) (approach start ∨ previous entry)`. The approach start is an
      observation at which ego, on a carrier the place marks (for the stop line and the crosswalk,
      a travel region c2 with `st_entrance_of place c2`; for the entrance end of c, c itself), is
      farther from the place than p.stop_point_tolerance and short of it along c (offset above
      zero). The previous entry is `rises (occ i)`. Since the judged entry is itself a rise of
      occ i, the search is read from the observation before the entry: the duty is
      `¬ rises (occ i ∨ ¬search)`, which at an entry (occ i here, not before) is exactly the
      negation of the search's value at the observation before. Nothing else ends the search: the
      start of the recording leaves it unknown (`since` carries the unobserved past).
    The obligation restates the selection of i and c (carrier entering i, the entry, the sign
      governing c) for every such pair; the exception, which decides only whether the rule is
      engaged, is not repeated there.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pDecelTolerance : Term := .param "p.decel_tolerance"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldSlowingDistance : Term := .param "p.yield_slowing_distance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The entered intersection and the approach carrier. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"

/-- Ego's footprint overlaps region `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vEgo, .var r] []

/-- Ego's body distance to region `r`. -/
def dist (r : String) : Term := .measure "st_region_geometry_distance" [vEgo, .var r]

/-- Signed distance from ego's reference point to region `r` along c's designated direction. -/
def along (r : String) : Term := .quantity "prim_region_offset_along" [vEgo, .var r, vC] []

/-- Region `r` (a stop line or a crosswalk) is recorded as marking carrier `a`'s entrance. -/
def marks (r a : String) : Formula := .atom "st_entrance_of" [.var r, .var a] []

/-- A device of kind `kind` governs c. -/
def governedBy (kind : String) : Formula :=
  .existsDevice (.lit kind) "d" (.atom "dev_governs" [.var "d", vC] [])

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Ego enters i from c: it occupies i here; before, it occupied c and not i. -/
def entry : Formula := .and (occ "i") (.rises (.or (occ "i") (.not (occ "c"))))

/-- g2: a stop sign or a yield sign governs c. -/
def signed : Formula := .or (governedBy "stop_sign") (governedBy "yield_sign")

/-- The selection of i and c: c enters i, ego enters i from c, a sign governs c. -/
def selection : Formula :=
  .and (.atom "st_lane_enters" [vC, vI] []) (.and entry signed)

/-- g1: ego's traffic is controlled by a police officer or an operating signal head at c or i. -/
def exception : Formula :=
  .and (.atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-285::traffic"] [])
    (.or
      (.existsDevice (.lit "human_direction") "h"
        (.and (.atom "dev_human_direction_role" [.var "h", .lit "police_officer"] [])
          (.or (.atom "dev_governs" [.var "h", vC] []) (.atom "dev_governs" [.var "h", vI] []))))
      (.existsDevice (.lit "traffic_signal") "g"
        (.and (.or (.atom "dev_governs" [.var "g", vC] []) (.atom "dev_governs" [.var "g", vI] []))
          (.not (.atom "dev_inoperative" [.var "g"] [])))))

/-- Applicability: g1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:; g2 (condition): When proper signs have been erected,; g5 (condition): at a clearly marked stop line; g6 (condition): or, if there is none, before entering the crosswalk on the near side of the intersection; g7 (condition): or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.and selection (.not exception)))

/-- Some stop line marks c. -/
def lineMarksC : Formula := .existsRegion (.lit "stop_line") "s0" (marks "s0" "c")
/-- Some crosswalk marks c. -/
def crosswalkMarksC : Formula := .existsRegion (.lit "crosswalk") "w0" (marks "w0" "c")

/-- Within the stopping zone of `r` and not past it along c. -/
def inZone (r : String) : Formula :=
  .and (.cmp (dist r) .le pStopPointTolerance) (.cmp (along r) .ge zeroMetres)

/-- Outside the stopping zone of `r`, short of it along c. -/
def upstreamOf (r : String) : Formula :=
  .and (.cmp (dist r) .gt pStopPointTolerance) (.cmp (along r) .gt zeroMetres)

/-- Ego on a carrier the place `r` marks. -/
def onMarked (r : String) : Formula :=
  .existsRegion (.lit "travel_region") "c2" (.and (occ "c2") (marks r "c2"))

/-- g5/g6/g7: ego is at the place that governs c. -/
def atPlace : Formula :=
  .or
    (.existsRegion (.lit "stop_line") "s" (.and (marks "s" "c") (inZone "s")))
    (.or
      (.and (.not lineMarksC)
        (.existsRegion (.lit "crosswalk") "w"
          (.and (marks "w" "c") (.and (.not (occ "w")) (inZone "w")))))
      (.and (.not lineMarksC) (.and (.not crosswalkMarksC)
        (.and (.not (occ "i")) (inZone "i")))))

/-- The approach start: ego, on a carrier the place marks, outside its stopping zone upstream. -/
def approachStart : Formula :=
  .or
    (.existsRegion (.lit "stop_line") "s"
      (.and (marks "s" "c") (.and (onMarked "s") (upstreamOf "s"))))
    (.or
      (.and (.not lineMarksC)
        (.existsRegion (.lit "crosswalk") "w"
          (.and (marks "w" "c") (.and (onMarked "w") (upstreamOf "w")))))
      (.and (.not lineMarksC) (.and (.not crosswalkMarksC)
        (.and (occ "c") (upstreamOf "i")))))

/-- g4: a halt, or, under a yield sign alone, a slowing within the distance window behind. -/
def motion : Formula :=
  .or (.derived "drv_motion_at_rest" [vEgo] [pRestSpeedTolerance])
    (.and (.not (governedBy "stop_sign"))
      (.not (.holdsFor .path pYieldSlowingDistance "ego"
        (.not (.derived "drv_motion_decelerating" [vEgo] [pDecelTolerance, pRestSpeedTolerance])))))

/-- The act: ego on c, at the place, halted or (yield) slowed. -/
def act : Formula := .and (occ "c") (.and atPlace motion)

/-- The search into the past: no act since the approach start or ego's previous entry into i. -/
def search : Formula := .since (.not act) (.or approachStart (.rises (occ "i")))

/-- At an entry, the search read from the observation before it found the act. -/
def duty : Formula := .not (.rises (.or (occ "i") (.not search)))

/-- Obligation: g4 (obligation): shall stop or yield -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.implies selection duty))

def rule : Rule :=
  { id := "NRS_484B_257_1_o1"
    laws := ["NRS-484B-257-1"]
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

end TrafficSpec.Rules.NRS_484B_257_1_o1
