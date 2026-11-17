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
    s4: atoms ['rel.occupies', 'st.roadway', 'st.highway', 'st.on_way', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'dev.governs'], derived []

  Compositions (span → node, as, map):
    s5: NRS_484B_283_1d1 as exception map {'subject': 'subject'}
    s5: NRS_484B_283_1d2 as exception map {'subject': 'subject'}
    s5: NRS_484B_283_1d3_o2 as exception map {'subject': 'subject'}
    s5: NRS_484B_283_1d4_o2 as exception map {'subject': 'subject'}

  How each span is written:
    s2: the binder's class is `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    s1: a head `s` (`existsDevice traffic_signal`) that shows green_arrow(left), green_arrow(right)
        or green_arrow(u_turn), and shows none of the other states of the enumeration
        (circular_*, flashing_red, flashing_yellow, dark, unknown, green_arrow(straight), and every
        yellow, red or flashing-yellow arrow): "alone".
    s3: with d = dev_position(s) − kin_position(subject) and h = kin_heading(subject):
        |d|² ≤ reach·reach, and h·d ≥ cos·|d| written without a root as the signed square
        (h·d)·|h·d| ≥ cos·|cos|·|d|² (x ↦ x·|x| is increasing, so the two are the same statement
        for every sign of the cosine bound).
    s4: the head controls an intersection x (`existsRegion intersection`): dev_governs(s, x), or
        dev_governs(s, l) for a travel region l with st_lane_enters(l, x); x lies on a highway w
        (`existsRegion highway`, st_on_way(x, w)). Ψ(w) := some roadway r (`existsRegion roadway`)
        with st_on_way(r, w) and rel_occupies(subject, r). "At the previous observation Ψ(w) did
        not hold" is written with `rises` only (the language has no previous-observation
        operator): ¬Ψ_prev ⇔ rises Ψ ∨ (¬Ψ ∧ ¬ rises ¬Ψ) — where Ψ holds now, Ψ was false before
        exactly when it rose; where Ψ fails now, it was false before exactly when ¬Ψ did not rise.
        The obligation repeats the whole selection of s, x and w (for every such triple) and
        requires, for every roadway r on w, ¬ rel_occupies(subject, r).
    s5: each composed rule as an exception: `.not (.ruleApplies id [("subject","subject")])` in the
        applicability.
  No choice beyond the record's own narrowing (s4) was made; no narrowing is added.

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

/-- Quantifier variables. -/
def vS : Arg := .var "s"
def vX : Arg := .var "x"
def vW : Arg := .var "w"
def vL : Arg := .var "l"
def vR : Arg := .var "r"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s1: head `s` shows a green turn arrow. -/
def showsTurnArrow : Formula :=
  .or (.atom "dev_traffic_signal_shows" [vS, .lit "green_arrow(left)"] [])
    (.or (.atom "dev_traffic_signal_shows" [vS, .lit "green_arrow(right)"] [])
         (.atom "dev_traffic_signal_shows" [vS, .lit "green_arrow(u_turn)"] []))

/-- The states other than a green turn arrow. -/
def otherStates : List String :=
  [ "circular_green", "circular_yellow", "circular_red", "flashing_red", "flashing_yellow",
    "dark", "unknown", "green_arrow(straight)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)",
    "flashing_yellow_arrow(straight)", "flashing_yellow_arrow(u_turn)" ]

/-- s1: head `s` shows none of the other states. -/
def showsNothingElse : Formula :=
  otherStates.foldr (fun k acc => .and (.not (.atom "dev_traffic_signal_shows" [vS, .lit k] [])) acc) .tt

/-- s1: a green turn arrow alone. -/
def greenTurnArrowAlone : Formula := .and showsTurnArrow showsNothingElse

/-- s3: the components of the line from the subject to the head, and of its heading. -/
def dX : Term := .sub (.measure "dev_position" [vS, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dY : Term := .sub (.measure "dev_position" [vS, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
def distSq : Term := .add (.mul dX dX) (.mul dY dY)
def dotHD : Term :=
  .add (.mul (.measure "kin_heading" [vSubject, .lit "x"]) dX)
       (.mul (.measure "kin_heading" [vSubject, .lit "y"]) dY)

/-- s3: the subject faces head `s`. -/
def faces : Formula :=
  .and (.cmp distSq .le (.mul pPedTrafficSignalFacingReach pPedTrafficSignalFacingReach))
       (.cmp (.mul dotHD (.abs dotHD)) .ge
             (.mul (.mul pPedTrafficSignalFacingCos (.abs pPedTrafficSignalFacingCos)) distSq))

/-- s4: head `s` controls intersection `x`. -/
def controls : Formula :=
  .or (.atom "dev_governs" [vS, vX] [])
      (.existsRegion (.lit "travel_region") "l"
        (.and (.atom "dev_governs" [vS, vL] []) (.atom "st_lane_enters" [vL, vX] [])))

/-- s4: Ψ(w) — the subject's footprint overlaps some roadway lying on `w`. -/
def onRoadwayOfW : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (.atom "st_on_way" [vR, vW] []) (.atom "rel_occupies" [vSubject, vR] []))

/-- s4: at the previous observation Ψ(w) did not hold (¬Ψ_prev ⇔ rises Ψ ∨ (¬Ψ ∧ ¬ rises ¬Ψ)). -/
def offRoadwayBefore : Formula :=
  .or (.rises onRoadwayOfW)
      (.and (.not onRoadwayOfW) (.not (.rises (.not onRoadwayOfW))))

/-- The whole selection of `s`, `x`, `w` (s1, s3, s4). -/
def selection : Formula :=
  .and faces
    (.and greenTurnArrowAlone
      (.and controls
        (.and (.atom "st_on_way" [vX, vW] []) offRoadwayBefore)))

def subjectMap : List (String × String) := [("subject", "subject")]

/-- Applicability: s1 (trigger): Where the signal is a green turn arrow alone:; s3 (condition): facing such a signal -/
def applicability : Formula :=
  .and
    (.existsDevice (.lit "traffic_signal") "s"
      (.existsRegion (.lit "intersection") "x"
        (.existsRegion (.lit "highway") "w" selection)))
    (.and (.not (.ruleApplies "NRS_484B_283_1d1" subjectMap))
      (.and (.not (.ruleApplies "NRS_484B_283_1d2" subjectMap))
        (.and (.not (.ruleApplies "NRS_484B_283_1d3_o2" subjectMap))
              (.not (.ruleApplies "NRS_484B_283_1d4_o2" subjectMap)))))

/-- Obligation: s4 (obligation): shall not enter the highway -/
def obligation : Formula :=
  .forallDevice (.lit "traffic_signal") "s"
    (.forallRegion (.lit "intersection") "x"
      (.forallRegion (.lit "highway") "w"
        (.implies selection
          (.forallRegion (.lit "roadway") "r"
            (.implies (.atom "st_on_way" [vR, vW] [])
              (.not (.atom "rel_occupies" [vSubject, vR] [])))))))

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
