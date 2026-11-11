/-
  NRS_484B_769 — NRS-484B-769

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): An operator of a bicycle, an electric bicycle or an electric scooter
    s2 (condition): upon a roadway
    s3 (obligation): shall give all signals by hand and arm
    s4 (reference): in the manner required by NRS 484B.420 [DEF-NRS-484B-420],
    s5 (exception): except that the operator may give a signal for a right turn by extending his or her right hand and arm horizontally and to the right side of the bicycle, electric bicycle or electric scooter.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    s2: atoms ['rel.occupies', 'st.roadway'], derived []
    s3: atoms ['sig.hand_signal', 'sig.turn_indicator'], derived [], borrowing ['s4']
    s5: atoms ['sig.hand_signal'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    s4: DEF-NRS-484B-420: (1) Left turn: Hand and arm extended horizontally. (2) Right turn: Hand and arm extended upward. (3) Stop or decrease speed: Hand and arm extended downward. (4) Reentering lane of traffic from parked position: Hand and arm extended horizontally.

  How each span is written:
    s1: the class of x is the disjunction of the three admitted aggregates, each `ru_aggregate` with
        the aggregate id as its literal argument.
    s2: "upon a roadway" is some region of kind `roadway` (st.roadway) that x occupies
        (rel_occupies x r); the quantifier ranges over regions of that kind only.
    s3 (with s4's borrowed words): the rule engages when x shows a signal, a lit indicator
        (sig_turn_indicator left or right) or an arm signal (sig_hand_signal other than no_signal);
        the obligation is an arm signal given (not no_signal), and where an indicator is lit, an
        arm signal of the same meaning: left ↦ left or re_enter (both "extended horizontally"),
        right ↦ right.
    s5: the permitted right-arm form is an arm signal whose recorded meaning is right, accepted by
        the same `sig_hand_signal x right` leaf as the 484B.420 form; it adds no leaf of its own.

  No choice beyond the record's own narrowings was made here: `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_769

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

def zeroMetres : Term := .lit Q.zero .metre

/-- x's turn indicator in the given state (sig.turn_indicator). -/
def indicator (state : String) : Formula := .atom "sig_turn_indicator" [vX, .lit state] []

/-- x's arm signal of the given meaning (sig.hand_signal). -/
def armSignal (meaning : String) : Formula := .atom "sig_hand_signal" [vX, .lit meaning] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
         (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- s2: x's footprint overlaps a roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vX, .var "r"] [])

/-- s3: x shows a signal — an indicator lit, or an arm signal given. -/
def givesSignal : Formula :=
  .or (.or (indicator "left") (indicator "right")) (.not (armSignal "no_signal"))

/-- Applicability: s2 (condition): upon a roadway; s5 (exception): except that the operator may give a signal for a right turn by extending his or her right hand and arm horizontally and to the right side of the bicycle, electric bicycle or electric scooter. -/
def applicability : Formula := .and onRoadway givesSignal

/-- Obligation: s3 (obligation): shall give all signals by hand and arm, in the manner of s4;
    s5's right-arm form is an arm signal of meaning right. -/
def obligation : Formula :=
  .and (.not (armSignal "no_signal"))
    (.and (.implies (indicator "left") (.or (armSignal "left") (armSignal "re_enter")))
          (.implies (indicator "right") (armSignal "right")))

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
