/-
  NRS_484B_287_1d — NRS-484B-287-1d

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (reference): Except as provided in NRS 484B.290 [LVMC-11-30-140-B]:
    s2 (subject): A pedestrian
    s3 (obligation): shall not cross an intersection diagonally
    s4 (exception): unless authorized by official traffic-control devices.

  Elements (span → atoms, derived):
    s2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s3: atoms ['rel.occupies', 'st.intersection', 'st.lane', 'st.lane_enters'], derived ['drv.motion.moving_across_carrier']
    s4: atoms ['rel.occupies', 'st.crosswalk'], derived []

  Compositions (span → node, as, map):
    s1: LVMC_11_30_140_B_o1 as exception map {'subject': 'subject'}
    s1: LVMC_11_30_140_B_o2 as exception map {'subject': 'subject'}

  How each is written:
    s2: the binder class is `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
    s3: the intersection is a region `x` of kind `intersection` the subject occupies
        (`rel_occupies`) into which some region `l` of kind `lane` runs (`st_lane_enters(l, x)`);
        that selection is the applicability and is written again, whole, in the obligation, which
        holds the duty at every such intersection. "Diagonally" is, for every lane `l` entering `x`,
        `drv_motion_moving_across_carrier(subject, l)` at (p.halt_speed_tolerance,
        p.crossing_motion_cos) and not at (p.halt_speed_tolerance, p.right_angle_crossing_cos).
    s4: a region `c` of kind `crosswalk` the subject occupies (`rel_occupies`) with
        `st_crosswalk_marked(c)` true; the record's own observable reading of "official".
    s1: each composed rule as `.not (.ruleApplies …)` in the applicability.

  No choice beyond the record's was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_287_1d

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrossingMotionCos : Term := .param "p.crossing_motion_cos"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pRightAngleCrossingCos : Term := .param "p.right_angle_crossing_cos"

def zeroMetres : Term := .lit Q.zero .metre

def vX : Arg := .var "x"
def vL : Arg := .var "l"
def vC : Arg := .var "c"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s3: the subject's footprint overlaps intersection `x`, into which at least one lane runs. -/
def inIntersection : Formula :=
  .and (.atom "rel_occupies" [vSubject, vX] [])
       (.existsRegion (.lit "lane") "l" (.atom "st_lane_enters" [vL, vX] []))

/-- s3: the subject moves diagonally across `x`: oblique to every lane that runs into it. -/
def diagonally : Formula :=
  .forallRegion (.lit "lane") "l"
    (.implies (.atom "st_lane_enters" [vL, vX] [])
      (.and (.derived "drv_motion_moving_across_carrier" [vSubject, vL]
               [pHaltSpeedTolerance, pCrossingMotionCos])
            (.not (.derived "drv_motion_moving_across_carrier" [vSubject, vL]
               [pHaltSpeedTolerance, pRightAngleCrossingCos]))))

/-- s4: the subject's footprint overlaps a marked crosswalk. -/
def inMarkedCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "c"
    (.and (.atom "rel_occupies" [vSubject, vC] [])
          (.atom "st_crosswalk_marked" [vC] []))

/-- Applicability: s2/s3 the pedestrian inside an intersection; s1 exceptions. -/
def applicability : Formula :=
  .and (.existsRegion (.lit "intersection") "x" inIntersection)
    (.and (.not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")]))
          (.not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")])))

/-- Obligation: s3 (obligation): shall not cross an intersection diagonally, s4 unless in a
    marked crosswalk. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "x"
    (.implies inIntersection
      (.implies diagonally inMarkedCrosswalk))

def rule : Rule :=
  { id := "NRS_484B_287_1d"
    laws := ["NRS-484B-287-1d"]
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

end TrafficSpec.Rules.NRS_484B_287_1d
