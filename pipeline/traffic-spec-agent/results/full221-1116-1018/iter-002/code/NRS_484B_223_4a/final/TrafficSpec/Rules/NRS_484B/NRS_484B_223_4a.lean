/-
  NRS_484B_223_4a — NRS-484B-223-4a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): If a highway has been designed to provide a single right lane to be used only for turning,
    s2 (subject): a vehicle must:
    s3 (obligation): Be driven in the right turn lane
    s4 (exception): only for the purpose of making a right turn.

  Elements (span → atoms, derived):
    s1: atoms ['st.turn_lane', 'rel.occupies'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['rel.occupies', 'st.turn_lane', 'st.intersection', 'st.driveway_or_alley_entrance'], derived []

  How each span is written:
    s2: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s1: some region `t` of kind `turn_lane` (st.turn_lane) whose side is `right`
        (`st_turn_lane_side t "right"`) and which the subject occupies (`rel_occupies subject t`).
        "Designed to provide" is the lane's presence on the road (the record's observable reading).
    s3/s4: for every region `t` selected as in s1 (the whole selection restated, rule 3c), the
        subject's declared intention `int.right_turn` holds at some region of kind `intersection`
        or of kind `driveway_or_alley_entrance` (st.intersection, st.driveway_or_alley_entrance),
        read at the judged observation. False at every such region: violated; undeclared at one
        and false at the others: unknown.

  Choices the record left open: none beyond the above — the intention is read at the judged
  observation (never ahead), and the two target kinds are joined by `or` as the element states.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_4a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

def vLane : Arg := .var "t"
def vTarget : Arg := .var "r"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: `t` is a right turn lane the subject occupies (the region bound by the caller's quantifier
    over kind `turn_lane`). -/
def inRightTurnLane : Formula :=
  .and (.atom "st_turn_lane_side" [vLane, .lit "right"] [])
       (.atom "rel_occupies" [vSubject, vLane] [])

/-- Applicability: s1 (condition): If a highway has been designed to provide a single right lane to be used only for turning,; s4 (exception): only for the purpose of making a right turn. -/
def applicability : Formula :=
  .existsRegion (.lit "turn_lane") "t" inRightTurnLane

/-- s3/s4: the subject's declared right turn at some intersection or driveway/alley entrance. -/
def rightTurnDeclared : Formula :=
  .or (.existsRegion (.lit "intersection") "r" (.intent "int.right_turn" vSubject vTarget))
      (.existsRegion (.lit "driveway_or_alley_entrance") "r" (.intent "int.right_turn" vSubject vTarget))

/-- Obligation: s3 (obligation): Be driven in the right turn lane -/
def obligation : Formula :=
  .forallRegion (.lit "turn_lane") "t" (.implies inRightTurnLane rightTurnDeclared)

def rule : Rule :=
  { id := "NRS_484B_223_4a"
    laws := ["NRS-484B-223-4a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.right_turn"]
    operationalizations := []
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_4a
