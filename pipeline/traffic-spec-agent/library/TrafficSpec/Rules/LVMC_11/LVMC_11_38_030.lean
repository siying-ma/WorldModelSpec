/-
  LVMC_11_38_030 — LVMC-11-38-030

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): No motorcycle
    s2 (subject): or motor scooter
    s3 (obligation): shall be ridden
    s4 (condition): upon any sidewalk
    s5 (condition): of the City

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle'], derived []
    s2: atoms ['ru.moped'], derived []
    s3: atoms [], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.occupies', 'st.sidewalk'], derived []

  How each is written:
    s1: `ru_aggregate subject "DEF-NRS-484A-135::motorcycle"`, disjoined with s2 in the class.
    s2: `ru_moped subject`.
    s3: the obligation is `drv_motion_complete_halt subject [p.halt_speed_tolerance]`: a
        machine at rest on a sidewalk is not ridden; moving there violates. (The record's
        observable_reading narrowing on s3 is the plan's and is not restated.)
    s4: `existsRegion "sidewalk" sw (rel_occupies subject sw)` — the region kind carries
        st.sidewalk, rel.occupies anchors the region to the subject.
    s5: the assumption `asm.within_city_limits`, conjoined in the applicability.
  No choice was left open beyond the record's; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_38_030

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject` (s1, s2): a member of the admitted aggregate
    DEF-NRS-484A-135::motorcycle, or a moped ("motor scooter"). -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-135::motorcycle"] [])
      (.atom "ru_moped" [vSubject] [])

/-- s4: "upon any sidewalk" — the subject's footprint overlaps some region of kind sidewalk
    (st.sidewalk as the quantifier's kind, rel.occupies as the anchoring relation). -/
def onSidewalk : Formula :=
  .existsRegion (.lit "sidewalk") "sw" (.atom "rel_occupies" [vSubject, .var "sw"] [])

/-- Applicability: s4 (condition): upon any sidewalk; s5 (condition): of the City
    (asm.within_city_limits). -/
def applicability : Formula :=
  .and onSidewalk (.asm "asm.within_city_limits")

/-- Obligation: s3 (obligation): "shall [not] be ridden" — the subject is at rest
    (drv.motion.complete_halt with the reading's speed tolerance). -/
def obligation : Formula :=
  .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

def rule : Rule :=
  { id := "LVMC_11_38_030"
    laws := ["LVMC-11-38-030"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_city_limits"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_38_030
