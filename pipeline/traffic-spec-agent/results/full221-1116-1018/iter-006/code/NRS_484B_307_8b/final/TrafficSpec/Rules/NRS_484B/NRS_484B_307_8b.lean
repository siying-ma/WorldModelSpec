/-
  NRS_484B_307_8b — NRS-484B-307-8b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady red signal alone:
    s2 (subject): Pedestrians
    s3 (condition): facing such a signal
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
    s5: NRS_484B_283_1d3_o2 as exception map {'subject': 'subject'}
    s5: NRS_484B_283_1d4_o2 as exception map {'subject': 'subject'}

  How each is written:
    s2: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`, the binder's class.
    s1+s3: one head bound by `existsDevice traffic_signal`: it shows circular_red and none of the
      other indications of dev.traffic_signal (every arrow in every direction, the flashing ones,
      dark, unknown) — 'alone'; and the subject faces it: |head − position|² ≤ reach², and
      heading · (head − position) ≥ 0 with its square ≥ cos² · |head − position|² · |heading|²
      (the cosine bound without a root or a measured divisor). The comparison reads both the
      head's and the subject's positions, which anchors the device variable.
    s4: R = some roadway the subject occupies. The record puts 'off the roadway at the previous
      observation' in the applicability and 'no roadway now' in the obligation. There is no
      'previous' operator; prev(¬R) is written `rises R ∨ (¬R ∧ ¬ rises ¬R)`, exact at every
      observation after the first (at the first it is unknown, truncated).
    s5: four exceptions, `¬ ruleApplies <id> {subject ↦ subject}` in the applicability.
  No choice beyond the record's was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_8b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedTrafficSignalFacingCos : Term := .param "p.ped_traffic_signal_facing_cos"
def pPedTrafficSignalFacingReach : Term := .param "p.ped_traffic_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject` (s2): ru.aggregate=DEF-NRS-484A-165::pedestrian, the admitted aggregate. -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- The head bound by the device quantifier. -/
def vHead : Arg := .var "head"

/-- Components of the vector from the subject's position (kin.position) to the head's position
    (dev.position). -/
def dx : Term := .sub (.measure "dev_position" [vHead, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dy : Term := .sub (.measure "dev_position" [vHead, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
/-- The subject's heading (kin.heading), as read: normalised. -/
def hx : Term := .measure "kin_heading" [vSubject, .lit "x"]
def hy : Term := .measure "kin_heading" [vSubject, .lit "y"]

def dist2 : Term := .add (.mul dx dx) (.mul dy dy)
def head2 : Term := .add (.mul hx hx) (.mul hy hy)
def dot : Term := .add (.mul hx dx) (.mul hy dy)

/-- s3, 'facing such a signal': the head lies within p.ped_traffic_signal_facing_reach of the
    subject (squared distances compared), and the cosine of the angle between the subject's heading
    and the line to the head is at least p.ped_traffic_signal_facing_cos (written without a root or
    a division: the dot product is non-negative and its square is at least cos² · |d|² · |h|²). -/
def facing : Formula :=
  .and (.cmp dist2 .le (.mul pPedTrafficSignalFacingReach pPedTrafficSignalFacingReach))
    (.and (.cmp dot .ge zeroMetres)
      (.cmp (.mul dot dot) .ge
        (.mul (.mul pPedTrafficSignalFacingCos pPedTrafficSignalFacingCos) (.mul dist2 head2))))

def shows (i : String) : Formula := .atom "dev_traffic_signal_shows" [vHead, .lit i] []

/-- Every indication of a signal head other than circular_red. -/
def otherIndications : List String :=
  [ "circular_green", "circular_yellow", "flashing_red", "flashing_yellow", "dark", "unknown" ] ++
  ([ "green_arrow", "yellow_arrow", "red_arrow", "flashing_yellow_arrow" ].flatMap fun a =>
    [ "left", "right", "straight", "u_turn" ].map fun d => s!"{a}({d})")

def anyOf : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (anyOf rest)

/-- s1, 'a steady red signal alone': the head displays circular_red and no other state. -/
def steadyRedAlone : Formula :=
  .and (shows "circular_red") (.not (anyOf (otherIndications.map shows)))

/-- s4: the subject's footprint overlaps a roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vSubject, .var "r"] [])

/-- At the previous observation the subject's footprint overlapped no roadway. The language has no
    'previous' operator; with R = onRoadway, prev(¬R) is exactly `rises R` where R holds now, and
    `¬ rises ¬R` where R does not hold now. -/
def offRoadwayBefore : Formula :=
  .or (.rises onRoadway) (.and (.not onRoadway) (.not (.rises (.not onRoadway))))

def subj : List (String × String) := [("subject", "subject")]

/-- Applicability: s1 (trigger) and s3 (condition) on one head; the subject off the roadway at the
    previous observation; s5, the four exceptions of NRS 484B.283. -/
def applicability : Formula :=
  .and (.existsDevice (.lit "traffic_signal") "head" (.and facing steadyRedAlone))
    (.and offRoadwayBefore
      (.and (.not (.ruleApplies "NRS_484B_283_1d1" subj))
        (.and (.not (.ruleApplies "NRS_484B_283_1d2" subj))
          (.and (.not (.ruleApplies "NRS_484B_283_1d3_o2" subj))
            (.not (.ruleApplies "NRS_484B_283_1d4_o2" subj))))))

/-- Obligation: s4 (obligation), 'shall not enter the highway': the subject's footprint overlaps no
    roadway at the judged observation. -/
def obligation : Formula := .not onRoadway

def rule : Rule :=
  { id := "NRS_484B_307_8b"
    laws := ["NRS-484B-307-8b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_8b
