/-
  NRS_484B_600_1e — NRS-484B-600-1e

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    s2 (condition): In any event,
    s3 (obligation): a rate of speed greater than 80 miles per hour.

  Elements (span → atoms, derived):
    s1: atoms ['ru.subject', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['kin.speed'], derived []

  Literals the text states (each written through its Units constructor):
    s3: 80 mph — 80 miles per hour

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written.

    s1 — the subject. Both of its atoms are the binder's class: `ru_subject veh` (the road user
    whose conduct the rule judges) and `ru_aggregate veh "DEF-NRS-484A-320::vehicle"` (membership
    of the admitted aggregate, written with the aggregate's id and never with the classes the
    reading puts under it). The record's own narrowing on this span — 'any person to drive or
    operate' read through the vehicle's controlled motion, an observable_reading of category
    agency — is the plan's and is not restated here; the element claims no motion atom, so the
    span is written from its two class atoms alone.

    s2 — residue, carried verbatim in `residues`. 'In any event,' withdraws no restriction and
    states no condition, so the applicability says nothing beyond the binder's class: the cap
    engages at every observation of such a vehicle, which is `.tt`. This is the record's own
    reading of the span ("The clause states no place, time or condition, and 'in any event'
    withdraws none, so the cap engages at every observation of such a vehicle"), not a choice of
    this session, so nothing is declared in `narrowings`.

    s3 — the duty. `kin_speed veh`, the subject's own speed, compared with the statute's figure,
    carried as the declared literal `Units.mph 80` (exactly 0.44704 m/s per mph) and tagged
    `.metrePerSecond`. The law forbids a rate *greater than* the figure, so the duty is `≤`:
    a speed equal to the figure complies. No parameter and no posted value enters.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1e

/-- The binders, as arguments (order and names are the node's). -/
def vVeh : Arg := .var "veh"

/-- The statute's own figure on s3, written through its `Units` constructor. -/
def eightyMph : Term := .lit (Units.mph 80) .metrePerSecond

/-- Class of `veh`: ru.subject, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsVeh : Formula :=
  .and (.atom "ru_subject" [vVeh] [])
       (.atom "ru_aggregate" [vVeh, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: s2 (condition): In any event, -/
def applicability : Formula := .tt

/-- Obligation: s3 (obligation): a rate of speed greater than 80 miles per hour. -/
def obligation : Formula :=
  .cmp (.measure "kin_speed" [vVeh]) .le eightyMph

def rule : Rule :=
  { id := "NRS_484B_600_1e"
    laws := ["NRS-484B-600-1e"]
    binders :=
      [ { name := "veh", cls := clsVeh } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["'In any event,' imposes no condition on the duty: it states that the cap holds whatever else is posted or reasonable under the other paragraphs of subsection 1, which is the absence of a restriction rather than one. The rule applies the cap at every observation of a vehicle in controlled motion, so the duty is exactly the same whether or not these words are read, and nothing the words cover is lost by not carrying them."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- no reading of this session's own: every span the node carries is written from its own atoms
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_600_1e
