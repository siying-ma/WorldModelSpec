/-
  LVMC_11_16_060 — LVMC-11-16-060

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (obligation): The prima facie speed limit is twenty-five miles per hour
    f2 (condition): on all streets and highways
    f3 (exception): unless a different speed limit is posted as set forth in this Title

  Elements (span → atoms, derived):
    f1: atoms ['kin.speed'], derived []
    f2: atoms ['rel.occupies', 'st.highway'], derived []
    f3: atoms ['dev.speed_limit_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []

  How each span is written:
    subject: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    f2: some region of kind `highway` (streets included: a street is a highway in a city) that
        the subject occupies (`rel_occupies`).
    f3: no device of kind `speed_limit_sign`, of sign kind maximum, structure_maximum or zone
        (`dev_speed_limit_sign_kind`; a minimum is no different limit, per the record), governs
        (`dev_governs`) some region of kind `travel_region` the subject occupies (`rel_occupies`).
        The device is anchored to the subject through the governed region it occupies.
    f1: `kin_speed subject ≤ 25 mph`, the literal written through `Units.mph 25` (m/s).
        The record's own narrowings (prima facie read as a maximum; posting read through the
        sign's presence) are the plan's and are not restated.

  Choices the text did not dictate: none beyond the record's.

  Literals the text states (each written through its Units constructor):
    f1: 25 mph — twenty-five miles per hour

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_16_060

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-- f1: twenty-five miles per hour. -/
def primaFacieLimit : Term := .lit (Units.mph 25) .metrePerSecond

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- f2: the subject occupies a highway (streets included). -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "w" (.atom "rel_occupies" [vSubject, .var "w"] [])

/-- f3: a maximum, structure-maximum or zone speed limit sign governs a travel region the subject
    occupies. -/
def differentLimitPosted : Formula :=
  .existsDevice (.lit "speed_limit_sign") "d"
    (.and
      (.or (.atom "dev_speed_limit_sign_kind" [.var "d", .lit "maximum"] [])
        (.or (.atom "dev_speed_limit_sign_kind" [.var "d", .lit "structure_maximum"] [])
             (.atom "dev_speed_limit_sign_kind" [.var "d", .lit "zone"] [])))
      (.existsRegion (.lit "travel_region") "r"
        (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
              (.atom "dev_governs" [.var "d", .var "r"] []))))

/-- Applicability: f2 (condition): on all streets and highways; f3 (exception): unless a different speed limit is posted as set forth in this Title -/
def applicability : Formula := .and onHighway (.not differentLimitPosted)

/-- Obligation: f1 (obligation): The prima facie speed limit is twenty-five miles per hour -/
def obligation : Formula := .cmp (.measure "kin_speed" [vSubject]) .le primaFacieLimit

def rule : Rule :=
  { id := "LVMC_11_16_060"
    laws := ["LVMC-11-16-060"]
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

end TrafficSpec.Rules.LVMC_11_16_060
