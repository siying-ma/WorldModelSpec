/-
  NRS_484B_769 — NRS-484B-769

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (subject): An operator of a bicycle,
    c2 (subject): an electric bicycle
    c3 (subject): or an electric scooter
    c4 (condition): upon a roadway
    c5 (obligation): shall give all signals by hand and arm
    c6 (reference): in the manner required by NRS 484B.420 [DEF-NRS-484B-420],
    c7 (exception): except that the operator may give a signal for a right turn by extending his or her right hand and arm horizontally and to the right side of the bicycle, electric bicycle or electric scooter.

  Elements (span → atoms, derived):
    c1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle'], derived []
    c2: atoms ['ru.aggregate=DEF-NRS-484B-017::electric_bicycle'], derived []
    c3: atoms ['ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    c4: atoms ['rel.occupies', 'st.roadway'], derived []
    c5: atoms ['sig.hand_signal', 'sig.turn_indicator'], derived [], borrowing ['c6']
    c7: atoms ['sig.hand_signal'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    c6: DEF-NRS-484B-420: extended horizontally

  How each span is written:
    c1–c3: the class of x is the disjunction of the three admitted aggregates, each the atom
      `ru_aggregate` with x and the aggregate id; 'an operator of' is the plan's observable reading
      (the controlled motion of the machine), so the binder is the machine's track.
    c4: some region of kind `roadway` (the quantifier kind carries st.roadway, refinements such as
      a one-way roadway included) that x occupies (`rel_occupies x r`).
    c5 + c6: for each lamp turn signal, an arm signal of the same meaning: indicator left → arm
      signal left, and indicator right → arm signal right. The borrowed posture ('extended
      horizontally') is what the source reads into the meaning of `sig_hand_signal`; no posture is
      read beyond the meaning (the plan's narrowing).
    c7: the right-arm posture for a right turn reads as `sig_hand_signal right`, the same leaf as
      the borrowed manner's right-turn posture; so the exception is carried by the obligation's
      right limb, which accepts a right arm signal whichever arm gives it. It adds no
      applicability condition.
  No choice beyond the record's own narrowings was made; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_769

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
         (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- Applicability: c4 (condition): upon a roadway — x's footprint overlaps some roadway.
    c7 (exception) is a permission on the manner of the right-turn signal, carried by the
    obligation's right limb; it narrows nothing here. -/
def applicability : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vX, .var "r"] [])

/-- A lamp turn signal of meaning `dir` is matched by an arm signal of the same meaning. -/
def byHandAndArm (dir : String) : Formula :=
  .implies (.atom "sig_turn_indicator" [vX, .lit dir] [])
    (.atom "sig_hand_signal" [vX, .lit dir] [])

/-- Obligation: c5 (obligation): shall give all signals by hand and arm (c6 the manner;
    c7: a right arm signal meets the right limb whichever arm gives it). -/
def obligation : Formula :=
  .and (byHandAndArm "left") (byHandAndArm "right")

def rule : Rule :=
  { id := "NRS_484B_769"
    laws := ["NRS-484B-769"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_769
