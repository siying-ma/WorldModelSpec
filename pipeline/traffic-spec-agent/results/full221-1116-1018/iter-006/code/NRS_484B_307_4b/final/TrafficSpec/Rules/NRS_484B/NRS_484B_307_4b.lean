/-
  NRS_484B_307_4b — NRS-484B-307-4b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a green turn arrow alone:
    s2 (subject): Pedestrians
    s3 (condition): facing such a signal
    s4 (obligation): shall not enter the highway
    s5 (reference): until permitted to proceed by another device as provided in NRS 484B.283 [NRS-484B-283-1d1, NRS-484B-283-1d2, NRS-484B-283-1d3, NRS-484B-283-1d4].

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

  How each span is written:
    s2: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"` as the binder's class.
    s1: some device `s` of kind traffic_signal (`existsDevice "traffic_signal"`, dev.traffic_signal)
        shows green_arrow(left), green_arrow(right) or green_arrow(u_turn), and shows none of the
        other indications of the enumeration (every circular, yellow, red, flashing, dark and unknown
        state and green_arrow(straight)): "a green turn arrow alone".
    s3: on the same `s`, with d = dev_position(s) − kin_position(subject) and h the subject's
        heading (read normalised): |d|² ≤ reach² and the cosine of the angle between h and d is at
        least p.ped_traffic_signal_facing_cos, written without a square root as
        h·d ≥ 0 ∧ (h·d)² ≥ cos² · |d|² (exact for a non-negative cosine bound). The comparison reads
        both the device and the binder, which anchors `s`.
    s4: "the subject's footprint overlaps a roadway" is
        R := existsRegion "roadway" r (rel_occupies subject r). The record puts "at the previous
        observation the subject overlapped no roadway" in the applicability; with only `rises` to
        reach the previous observation it is written as
        rises R ∨ (¬R ∧ ¬rises ¬R), which is exactly ¬R at the previous observation. The obligation
        is ¬R at the judged observation.
    s5: each composition `.not (.ruleApplies id [("subject","subject")])` in the applicability.
  No choice beyond the record's own narrowing on s4 was made; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_4b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedTrafficSignalFacingCos : Term := .param "p.ped_traffic_signal_facing_cos"
def pPedTrafficSignalFacingReach : Term := .param "p.ped_traffic_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Conjunction of a list of formulas. -/
def allOf : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: ψs => .and φ (allOf ψs)

/-- Disjunction of a list of formulas. -/
def anyOf : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: ψs => .or φ (anyOf ψs)

/-- The signal head the subject faces (quantifier variable). -/
def vSig : Arg := .var "s"

/-- s1: the head shows the indication spelled `i`. -/
def shows (i : String) : Formula := .atom "dev_traffic_signal_shows" [vSig, .lit i] []

/-- The green turn arrows. -/
def greenTurnArrows : List String :=
  ["green_arrow(left)", "green_arrow(right)", "green_arrow(u_turn)"]

/-- Every other state a head may display. -/
def otherIndications : List String :=
  [ "circular_green", "circular_yellow", "circular_red", "flashing_red", "flashing_yellow", "dark",
    "unknown", "green_arrow(straight)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)",
    "flashing_yellow_arrow(straight)", "flashing_yellow_arrow(u_turn)" ]

/-- s1: a green turn arrow alone. -/
def greenTurnArrowAlone : Formula :=
  .and (anyOf (greenTurnArrows.map shows))
       (allOf (otherIndications.map fun i => .not (shows i)))

/-- s3: components of the line from the subject's position to the head, and of its heading. -/
def dx : Term := .sub (.measure "dev_position" [vSig, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dy : Term := .sub (.measure "dev_position" [vSig, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
def hx : Term := .measure "kin_heading" [vSubject, .lit "x"]
def hy : Term := .measure "kin_heading" [vSubject, .lit "y"]
def distSq : Term := .add (.mul dx dx) (.mul dy dy)
def dotHD : Term := .add (.mul hx dx) (.mul hy dy)

/-- s3: the head lies within reach of the subject. -/
def withinReach : Formula :=
  .cmp distSq .le (.mul pPedTrafficSignalFacingReach pPedTrafficSignalFacingReach)

/-- s3: the subject's heading makes with the line to the head an angle whose cosine is at least
    the bound. -/
def headingTowards : Formula :=
  .and (.cmp dotHD .ge zeroMetres)
       (.cmp (.mul dotHD dotHD) .ge
             (.mul (.mul pPedTrafficSignalFacingCos pPedTrafficSignalFacingCos) distSq))

/-- s1 + s3: the subject faces a traffic signal head displaying a green turn arrow alone. -/
def facesGreenTurnArrowAlone : Formula :=
  .existsDevice (.lit "traffic_signal") "s"
    (allOf [withinReach, headingTowards, greenTurnArrowAlone])

/-- s4: the subject's footprint overlaps a roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vSubject, .var "r"] [])

/-- s4 (applicability part): at the previous observation the subject overlapped no roadway. -/
def offRoadwayBefore : Formula :=
  .or (.rises onRoadway) (.and (.not onRoadway) (.not (.rises (.not onRoadway))))

/-- s5: the exceptions. -/
def exception (id : String) : Formula := .not (.ruleApplies id [("subject", "subject")])

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- Applicability: s1 (trigger): Where the signal is a green turn arrow alone:; s3 (condition): facing such a signal -/
def applicability : Formula :=
  allOf
    [ facesGreenTurnArrowAlone
    , offRoadwayBefore
    , exception "NRS_484B_283_1d1"
    , exception "NRS_484B_283_1d2"
    , exception "NRS_484B_283_1d3_o2"
    , exception "NRS_484B_283_1d4_o2" ]

/-- Obligation: s4 (obligation): shall not enter the highway -/
def obligation : Formula := .not onRoadway

def rule : Rule :=
  { id := "NRS_484B_307_4b"
    laws := ["NRS-484B-307-4b"]
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

end TrafficSpec.Rules.NRS_484B_307_4b
