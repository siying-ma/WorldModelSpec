/-
  NRS_484B_307_9c — NRS-484B-307-9c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady red with a green turn arrow:
    s2 (subject): Pedestrians
    s3 (trigger): facing such a signal
    s4 (obligation): shall not enter the highway,
    s5 (reference): unless permitted to proceed by another device as provided in NRS 484B.283 [NRS-484B-283-1d1, NRS-484B-283-1d2, NRS-484B-283-1d3, NRS-484B-283-1d4].

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s3: atoms ['dev.position', 'kin.heading', 'kin.position'], derived []
    s4: atoms ['rel.occupies', 'st.roadway'], derived []

  Compositions (span → node, as, map):
    s5: NRS_484B_283_1d1 as exception map {'subject': 'subject'}
    s5: NRS_484B_283_1d2 as exception map {'subject': 'subject'}
    s5: NRS_484B_283_1d3_o1 as exception map {'subject': 'subject'}
    s5: NRS_484B_283_1d4_o1 as exception map {'subject': 'subject'}

  How each span is written:
    s2: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"` as the subject's class.
    s1: some device `h` of kind traffic_signal that shows circular_red, shows a green_arrow of some
        direction (the four directions as one disjunction over the enumeration) and does not show
        circular_green — the record's "circular_red with green_arrow(dir) and no circular_green".
    s3: the same `h` (one quantifier binds s1 and s3: the signal faced is "such a signal").
        With D = dev_position(h) − kin_position(subject) and H = kin_heading(subject):
        |D|² ≤ reach² (within p.ped_traffic_signal_facing_reach), and cos(H, D) ≥
        p.ped_traffic_signal_facing_cos written without a root or a division as
        H·D ≥ 0 ∧ (H·D)² ≥ cos² · |D|² (the heading is read normalised, a unit vector).
        The head's position is used for facing only.
    s4: the record's obligation: not `rises (∃ roadway r, rel_occupies subject r)` — the footprint
        overlaps some roadway here and overlapped none at the previous observation.
    s5: each composition is `.not (.ruleApplies id [("subject","subject")])` in the applicability.

  No choice beyond the record's own was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedTrafficSignalFacingCos : Term := .param "p.ped_traffic_signal_facing_cos"
def pPedTrafficSignalFacingReach : Term := .param "p.ped_traffic_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- The signal head variable. -/
def vHead : Arg := .var "h"

def shows (i : String) : Formula := .atom "dev_traffic_signal_shows" [vHead, .lit i] []

/-- s1: a steady red with a green turn arrow: circular_red, a green arrow, no circular_green. -/
def redWithGreenArrow : Formula :=
  .and (shows "circular_red")
    (.and
      (.or (shows "green_arrow(left)")
        (.or (shows "green_arrow(right)")
          (.or (shows "green_arrow(straight)") (shows "green_arrow(u_turn)"))))
      (.not (shows "circular_green")))

/-- Components of D = head position − subject position, and of the subject's heading. -/
def dx : Term := .sub (.measure "dev_position" [vHead, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dy : Term := .sub (.measure "dev_position" [vHead, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
def hx : Term := .measure "kin_heading" [vSubject, .lit "x"]
def hy : Term := .measure "kin_heading" [vSubject, .lit "y"]

def distSq : Term := .add (.mul dx dx) (.mul dy dy)
def dotHD : Term := .add (.mul hx dx) (.mul hy dy)

/-- H·D ≥ 0 written as H·(head position) ≥ H·(subject position). -/
def dotHHead : Term :=
  .add (.mul hx (.measure "dev_position" [vHead, .lit "x"])) (.mul hy (.measure "dev_position" [vHead, .lit "y"]))
def dotHSubject : Term :=
  .add (.mul hx (.measure "kin_position" [vSubject, .lit "x"])) (.mul hy (.measure "kin_position" [vSubject, .lit "y"]))

/-- s3: the subject faces the head: within reach and within the facing angle. -/
def facing : Formula :=
  .and (.cmp distSq .le (.mul pPedTrafficSignalFacingReach pPedTrafficSignalFacingReach))
    (.and (.cmp dotHHead .ge dotHSubject)
      (.cmp (.mul dotHD dotHD) .ge
        (.mul (.mul pPedTrafficSignalFacingCos pPedTrafficSignalFacingCos) distSq)))

/-- s5: exceptions — a rule of NRS 484B.283 for pedestrian signals engaged for the subject. -/
def subjMap : List (String × String) := [("subject", "subject")]

def exceptions : Formula :=
  .and (.not (.ruleApplies "NRS_484B_283_1d1" subjMap))
    (.and (.not (.ruleApplies "NRS_484B_283_1d2" subjMap))
      (.and (.not (.ruleApplies "NRS_484B_283_1d3_o1" subjMap))
        (.not (.ruleApplies "NRS_484B_283_1d4_o1" subjMap))))

/-- Applicability: s1 (trigger): Where the signal is a steady red with a green turn arrow:; s3 (trigger): facing such a signal -/
def applicability : Formula :=
  .and (.existsDevice (.lit "traffic_signal") "h" (.and redWithGreenArrow facing)) exceptions

/-- s4: the subject's footprint overlaps some roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vSubject, .var "r"] [])

/-- Obligation: s4 (obligation): shall not enter the highway, -/
def obligation : Formula := .not (.rises onRoadway)

def rule : Rule :=
  { id := "NRS_484B_307_9c"
    laws := ["NRS-484B-307-9c"]
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

end TrafficSpec.Rules.NRS_484B_307_9c
