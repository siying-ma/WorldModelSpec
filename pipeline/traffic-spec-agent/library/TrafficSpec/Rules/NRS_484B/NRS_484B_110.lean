/-
  NRS_484B_110 — NRS-484B-110

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): No vehicle
    s2 (trigger): shall at any time be driven
    s3 (obligation): through or within a safety zone.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
        → binder class `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
    s2: atoms [], derived ['drv.motion.complete_halt']
        → applicability `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`:
          the subject is moving at the judged observation; "at any time" makes every
          observation a judged one, so no time operator is added.
    s3: atoms ['rel.occupies', 'st.safety_zone'], derived []
        → obligation `∀ z of kind safety_zone, ¬ rel_occupies(subject, z)`: the kind is the
          quantifier's spelling `safety_zone` (st.safety_zone), the region tied to the subject
          by rel_occupies.

  No choice beyond the record's own narrowings was needed: `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_110

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s2 (trigger): shall at any time be driven — the subject is moving. -/
def applicability : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- Obligation: s3 (obligation): through or within a safety zone — no safety zone is occupied. -/
def obligation : Formula :=
  .forallRegion (.lit "safety_zone") "z"
    (.not (.atom "rel_occupies" [vSubject, .var "z"] []))

def rule : Rule :=
  { id := "NRS_484B_110"
    laws := ["NRS-484B-110"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_110
