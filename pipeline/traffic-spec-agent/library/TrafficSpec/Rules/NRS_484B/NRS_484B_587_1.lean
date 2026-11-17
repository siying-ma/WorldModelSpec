/-
  NRS_484B_587_1 — NRS-484B-587-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (trigger): When official traffic-control devices are erected giving notice thereof,
    c2 (subject): a person shall not drive a vehicle
    c3 (obligation): onto or from any controlled-access highway
    c4 (exception): except at those entrances and exits which are indicated by such devices.

  Elements (span → atoms, derived):
    c1: atoms ['dev.regulatory_sign'], derived []
    c2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    c3: atoms ['rel.occupies', 'st.controlled_access'], derived []
    c4: atoms ['dev.governs', 'dev.regulatory_sign', 'rel.occupies', 'st.travel_region'], derived []

  How each span is written:
    c2: the binder class `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
    c1: some device of kind `regulatory_sign` in the scene whose code is `entrance` or `exit`
        (`dev_regulatory_sign_code`), as the record's applicability states (presence in the scene).
    c3: for a controlled-access region ca (`existsRegion controlled_access`), entry is
        `rises(rel_occupies(subject, ca))`, departure is `rises(not rel_occupies(subject, ca))`;
        either one engages the rule (applicability).
    c4: the obligation re-selects every controlled-access region ca (`forallRegion`) and, for each:
        at an entry, the subject occupies some travel region r (`existsRegion travel_region`)
        governed (`dev_governs`) by a regulatory sign of code `entrance`; at a departure,
        `rises(not X)` with X = occupies ca ∧ occupies some travel region governed by a regulatory
        sign of code `exit` — at a departure X is false here, so this holds exactly when X held at
        the previous observation, as the record writes it.

  No choice beyond the record's was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_587_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

def vCa : Arg := .var "ca"
def vR : Arg := .var "r"
def vD : Arg := .var "d"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The subject occupies ca. -/
def occCa : Formula := .atom "rel_occupies" [vSubject, vCa] []

/-- c3: the subject's footprint comes to overlap ca. -/
def entersCa : Formula := .rises occCa

/-- c3: the subject's footprint ceases to overlap ca. -/
def leavesCa : Formula := .rises (.not occCa)

/-- c1: some regulatory sign coded entrance or exit is present in the scene. -/
def noticeErected : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.or (.atom "dev_regulatory_sign_code" [vD, .lit "entrance"] [])
         (.atom "dev_regulatory_sign_code" [vD, .lit "exit"] []))

/-- c4: the subject occupies some travel region governed by a regulatory sign of the given code. -/
def atIndicated (code : String) : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] [])
      (.existsDevice (.lit "regulatory_sign") "d"
        (.and (.atom "dev_regulatory_sign_code" [vD, .lit code] [])
              (.atom "dev_governs" [vD, vR] []))))

/-- Applicability: c1 (trigger): When official traffic-control devices are erected giving notice thereof,; c4 (exception): except at those entrances and exits which are indicated by such devices. -/
def applicability : Formula :=
  .and noticeErected
    (.existsRegion (.lit "controlled_access") "ca" (.or entersCa leavesCa))

/-- Obligation: c3 (obligation): onto or from any controlled-access highway -/
def obligation : Formula :=
  .forallRegion (.lit "controlled_access") "ca"
    (.and (.implies entersCa (atIndicated "entrance"))
          (.implies leavesCa (.rises (.not (.and occCa (atIndicated "exit"))))))

def rule : Rule :=
  { id := "NRS_484B_587_1"
    laws := ["NRS-484B-587-1"]
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

end TrafficSpec.Rules.NRS_484B_587_1
