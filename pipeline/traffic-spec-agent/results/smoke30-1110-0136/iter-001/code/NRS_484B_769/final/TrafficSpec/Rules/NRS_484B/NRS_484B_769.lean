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

  How each is written:
    c1–c3: the class of x is the disjunction of the three admitted aggregates, each one
      `ru_aggregate x <aggregate id>`; "an operator of" is the plan's observable reading (the
      machine's controlled motion), so the binder is the machine's track.
    c4: some region of kind `roadway` (st.roadway; a one-way roadway refines it and is covered)
      that x's footprint overlaps (rel_occupies x r), at the observation.
    c5 + c6: every turn signal x gives by lamp is a signal by hand and arm of the same meaning:
      turn indicator left → arm signal left, and turn indicator right → arm signal right. The
      borrowed manner ("extended horizontally") is the posture whose meaning the source reads into
      sig.hand_signal; no posture beyond the meaning is read (the record's narrowing on c5).
    c7: the exception is carried by the right-turn conjunct: an arm signal of meaning right meets
      the duty whichever arm gives it, since sig.hand_signal carries the meaning only. It adds no
      conjunct to the applicability.
  An arm signal with no lamp, and no signal at all, leave both implications true (compliant).
  No choice beyond the record's was made: `narrowings` is empty.

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

/-- c4: x's footprint overlaps a roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vX, .var "r"] [])

/-- Applicability: c4 (condition): upon a roadway; c7 (exception): except that the operator may give a signal for a right turn by extending his or her right hand and arm horizontally and to the right side of the bicycle, electric bicycle or electric scooter. -/
def applicability : Formula := onRoadway

/-- c5/c6: a lamp signal of meaning `k` is matched by an arm signal of meaning `k`. -/
def byHandAndArm (k : String) : Formula :=
  .implies (.atom "sig_turn_indicator" [vX, .lit k] []) (.atom "sig_hand_signal" [vX, .lit k] [])

/-- Obligation: c5 (obligation): shall give all signals by hand and arm; c7: a right-turn arm
    signal meets the duty whichever arm gives it (sig.hand_signal reads the meaning). -/
def obligation : Formula := .and (byHandAndArm "left") (byHandAndArm "right")

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
