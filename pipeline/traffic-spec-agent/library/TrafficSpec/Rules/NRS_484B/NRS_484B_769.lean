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
    s1: the class of `x` is the disjunction of the three admitted aggregates, each `ru_aggregate`
        with its id; the electric-scooter aggregate stays unknown where the run's reading leaves
        the class unresolved (the record's reading).
    s2: some region of kind `roadway` (st.roadway, quantified by its kind) that `x` occupies
        (rel_occupies).
    s3/s4: applicability adds that `x` gives a signal: its turn indicator is left or right, or its
        arm signal is other than no_signal. The obligation: an arm signal is given (not no_signal);
        with the left indicator lit, the arm signal means left or re_enter (both are the horizontal
        posture of NRS 484B.420); with the right indicator lit, it means right.
    s5: the right-arm form is an arm signal of meaning right, admitted by the same `right` literal
        that admits the upward posture; no separate leaf, since the source records the meaning only.

  Choices of this file: none beyond the record's own narrowings.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_769

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

def zeroMetres : Term := .lit Q.zero .metre

/-- `x` is a member of an admitted aggregate. -/
def member (id : String) : Formula := .atom "ru_aggregate" [vX, .lit id] []

/-- `x`'s turn indicator is in the given state. -/
def indicator (k : String) : Formula := .atom "sig_turn_indicator" [vX, .lit k] []

/-- `x`'s arm signal has the given meaning. -/
def arm (k : String) : Formula := .atom "sig_hand_signal" [vX, .lit k] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (member "DEF-NRS-484A-025::bicycle")
    (.or (member "DEF-NRS-484B-017::electric_bicycle")
      (member "DEF-NRS-484B-018::electric_scooter"))

/-- s2: `x`'s footprint overlaps a roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vX, .var "r"] [])

/-- s3: `x` shows a signal: a lit turn indicator or an arm signal. -/
def givesSignal : Formula :=
  .or (indicator "left") (.or (indicator "right") (.not (arm "no_signal")))

/-- Applicability: s2 (condition): upon a roadway; s5 (exception): except that the operator may give a signal for a right turn by extending his or her right hand and arm horizontally and to the right side of the bicycle, electric bicycle or electric scooter. -/
def applicability : Formula := .and onRoadway givesSignal

/-- Obligation: s3 (obligation): shall give all signals by hand and arm -/
def obligation : Formula :=
  .and (.not (arm "no_signal"))
    (.and (.implies (indicator "left") (.or (arm "left") (arm "re_enter")))
      (.implies (indicator "right") (arm "right")))

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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_769
