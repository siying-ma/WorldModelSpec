/-
  NRS_484B_600_1e — NRS-484B-600-1e

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    g1 (subject): It is unlawful for any person to drive or operate
    g2 (subject): a vehicle of any kind or character
    g3 (boilerplate): at:
    g4 (condition): In any event,
    g5 (obligation): a rate of speed greater than 80 miles per hour.

  Elements (span → atoms, derived):
    g1: atoms ['kin.speed'], derived []
    g2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    g5: atoms ['kin.speed'], derived []

  Literals the text states (each written through its Units constructor):
    g5: 80 mph — 80 miles per hour

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1e

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written:
    g1 ("drive or operate"): read, as the node's own observable_reading narrowing states, through the
       vehicle's controlled motion — kin.speed of the subject, which the obligation compares. No
       further condition on who drives is added.
    g2 ("a vehicle of any kind or character"): the binder class, ru_aggregate of the subject with the
       admitted aggregate id DEF-NRS-484A-320::vehicle.
    g4 ("In any event,"): a residue of the node; it adds no condition, so the applicability is `.tt`
       and the binder class alone decides engagement.
    g5 ("a rate of speed greater than 80 miles per hour"): forbidden is kin.speed > 80 mph, so the
       duty is kin.speed ≤ 80 mph (the literal written through Units.mph, in m/s).
  No choice left open by the record was made: no narrowing of this session's own.
-/

/-- The text's literal bound: 80 miles per hour (g5). -/
def limit80mph : Term := .lit (Units.mph 80) .metrePerSecond

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: g4 (condition): In any event, — a residue; it adds no condition. -/
def applicability : Formula := .tt

/-- Obligation: g5 (obligation): a rate of speed greater than 80 miles per hour is unlawful —
    kin.speed(subject) is not greater than 80 mph. -/
def obligation : Formula := .cmp (.measure "kin_speed" [vSubject]) .le limit80mph

def rule : Rule :=
  { id := "NRS_484B_600_1e"
    laws := ["NRS-484B-600-1e"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["\"In any event\" states that the bound holds whatever other limit or circumstance applies; it adds no condition, and the duty is the same whether or not the words are read."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_600_1e
