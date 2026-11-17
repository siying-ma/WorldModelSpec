/-
  NRS_484B_203_1_o1 — NRS-484B-203-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    h1 (subject): Drivers of vehicles proceeding in opposite directions
    h2 (obligation): shall pass each other keeping to the right,
    h3 (boilerplate): and
    h4 (sibling): upon highways having width for not more than one line of traffic in each direction,
    h5 (sibling): each driver shall give to the other at least one-half of the paved portion of the highway
    h6 (sibling): as nearly as possible.

  Elements (span → atoms, derived):
    h1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.oncoming'], derived ['drv.motion.complete_halt']
    h2: atoms ['rel.longitudinal_overlap', 'rel.bearing', 'rel.occupies', 'st.highway'], derived []

  How each is written:
    h1 — the subject's class is `ru_aggregate subject DEF-NRS-484A-320::vehicle`; "proceeding" is the
         applicability `¬ drv_motion_complete_halt(subject, p.halt_speed_tolerance)`. The other
         vehicle is a road user `other` quantified in the obligation, of the same aggregate and
         oncoming to the subject (`rel_oncoming(subject, other)` with p.oncoming_heading_cos).
    h2 — "pass each other": `rel_longitudinal_overlap(subject, other) > 0` (the projections share
         length) and both occupy one highway region (`existsRegion highway h`, `rel_occupies` of
         each). "keeping to the right": the other lies on the subject's left,
         `rel_bearing(subject, other, left)` (lateral component positive).
    The obligation holds for every such `other`; it is violated where one lies on the subject's
    right (or straight across its centre line, lateral zero, which is not on its left).

  Choices the record left open: none. A road user is never oncoming to itself (its headings are
  aligned), so no `same` exclusion of the subject is written.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_203_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"
/-- The other vehicle met, quantified in the obligation. -/
def vOther : Arg := .var "other"
/-- A highway region both occupy, quantified in the obligation. -/
def vWay : Arg := .var "way"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOncomingHeadingCos : Term := .param "p.oncoming_heading_cos"

def zeroMetres : Term := .lit Q.zero .metre

def vehicleAggregate : String := "DEF-NRS-484A-320::vehicle"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit vehicleAggregate] []

/-- Applicability (h1, "proceeding"): the subject is not at rest. -/
def applicability : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- h2: subject and other occupy one highway region. -/
def onSameHighway : Formula :=
  .existsRegion (.lit "highway") "way"
    (.and (.atom "rel_occupies" [vSubject, vWay] [])
          (.atom "rel_occupies" [vOther, vWay] []))

/-- h1 + h2: `other` is a vehicle on the subject's highway, oncoming and alongside. -/
def meeting : Formula :=
  .and (.atom "ru_aggregate" [vOther, .lit vehicleAggregate] [])
    (.and onSameHighway
      (.and (.atom "rel_oncoming" [vSubject, vOther] [pOncomingHeadingCos])
            (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vOther]) .gt zeroMetres)))

/-- Obligation (h2): every vehicle the subject meets and passes lies on the subject's left. -/
def obligation : Formula :=
  .forallUser "other"
    (.implies meeting (.atom "rel_bearing" [vSubject, vOther, .lit "left"] []))

def rule : Rule :=
  { id := "NRS_484B_203_1_o1"
    laws := ["NRS-484B-203-1"]
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

end TrafficSpec.Rules.NRS_484B_203_1_o1
