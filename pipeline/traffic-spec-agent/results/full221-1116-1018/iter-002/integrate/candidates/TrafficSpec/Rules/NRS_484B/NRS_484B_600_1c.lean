/-
  NRS_484B_600_1c — NRS-484B-600-1c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (subject): It is unlawful for any person to drive or operate
    f2 (subject): a vehicle of any kind or character
    f3 (boilerplate): at:
    f4 (obligation): A rate of speed greater than
    f5 (condition): that posted by a public authority
    f6 (condition): for the particular portion of highway being traversed.

  Elements (span → atoms, derived):
    f1: atoms ['kin.speed'], derived []
    f2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    f4: atoms ['kin.speed'], derived []
    f5: atoms ['dev.speed_limit_sign'], derived []
    f6: atoms ['dev.governs', 'rel.occupies', 'st.travel_region'], derived []

  How each span is written:
    f2: binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    f5: a device of kind speed_limit_sign whose `dev_speed_limit_sign_kind` is maximum,
        structure_maximum or zone (the record's three kinds; minimum is excluded by the record).
    f6: some travel region (quantifier kind `travel_region`, covering its refinements) the subject
        occupies (`rel_occupies`) and the sign governs (`dev_governs`).
    f1/f4: `kin_speed subject ≤ dev_speed_limit_sign_value sign` ("greater than" is the violation).
  Applicability: some sign selected by f5 ∧ f6. Obligation: for every sign of that same selection
  (written whole again), the comparison holds — the record's "for every such sign".
  No choice beyond the record's mapping was made: no narrowings of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

def vSign : Arg := .var "sign"
def vRegion : Arg := .var "region"

/-- Class of `subject` (f2): ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- f5: the sign states a maximum speed: kind maximum, structure_maximum or zone (a minimum sign
    posts no maximum rate). -/
def postsMaximum : Formula :=
  .or (.atom "dev_speed_limit_sign_kind" [vSign, .lit "maximum"] [])
    (.or (.atom "dev_speed_limit_sign_kind" [vSign, .lit "structure_maximum"] [])
         (.atom "dev_speed_limit_sign_kind" [vSign, .lit "zone"] []))

/-- f6: the sign governs a travel region the subject's footprint overlaps — the portion of
    highway being traversed. -/
def governsTraversedPortion : Formula :=
  .existsRegion (.lit "travel_region") "region"
    (.and (.atom "rel_occupies" [vSubject, vRegion] [])
          (.atom "dev_governs" [vSign, vRegion] []))

/-- The record's whole selection of a sign (f5 ∧ f6), used alike in applicability and obligation. -/
def selected : Formula := .and postsMaximum governsTraversedPortion

/-- Applicability: f5 (condition): that posted by a public authority; f6 (condition): for the particular portion of highway being traversed. -/
def applicability : Formula :=
  .existsDevice (.lit "speed_limit_sign") "sign" selected

/-- Obligation: f1/f4 (obligation): A rate of speed greater than [the posted value] — for every
    selected sign, kin.speed(subject) ≤ its value. -/
def obligation : Formula :=
  .forallDevice (.lit "speed_limit_sign") "sign"
    (.implies selected
      (.cmp (.measure "kin_speed" [vSubject]) .le (.measure "dev_speed_limit_sign_value" [vSign])))

def rule : Rule :=
  { id := "NRS_484B_600_1c"
    laws := ["NRS-484B-600-1c"]
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

end TrafficSpec.Rules.NRS_484B_600_1c
