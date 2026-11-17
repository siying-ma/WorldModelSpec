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
    h1 — class of `subject`: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
         'proceeding': applicability is the negation of `drv_motion_complete_halt subject` with
         p.halt_speed_tolerance. The other vehicle `c` is quantified over every road user of the
         scene and restricted to the same aggregate; 'in opposite directions' is
         `rel_oncoming subject c` with p.oncoming_heading_cos.
    h2 — 'pass each other': `rel_longitudinal_overlap subject c` strictly above zero (the
         projections share length). Same highway: some region of kind `highway` (a quantifier over
         the kind covers the kinds refining it) that both `subject` and `c` occupy (`rel_occupies`).
         'keeping to the right': `rel_bearing subject c "left"`, the lateral component of c's
         bearing in the subject's frame strictly positive (the record: "c lies on the subject's
         left").
  The subject itself is in the range of the user quantifier; it is never oncoming to itself
  (its heading is not opposed to its own), so no `same` exclusion is needed.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_203_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"
/-- The other vehicle met, and the highway they share. -/
def vOther : Arg := .var "c"
def vHighway : Arg := .var "h"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOncomingHeadingCos : Term := .param "p.oncoming_heading_cos"

def zeroMetres : Term := .lit Q.zero .metre

def vehicleAggregate : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, vehicleAggregate] []

/-- Applicability: h1 'proceeding' — the subject is not at rest. -/
def applicability : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- h2: both occupy one highway region. -/
def sameHighway : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vSubject, vHighway] [])
          (.atom "rel_occupies" [vOther, vHighway] []))

/-- h1/h2: `c` is a vehicle on the subject's highway, oncoming, and alongside it. -/
def meets : Formula :=
  .and (.atom "ru_aggregate" [vOther, vehicleAggregate] [])
    (.and sameHighway
      (.and (.atom "rel_oncoming" [vSubject, vOther] [pOncomingHeadingCos])
            (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vOther]) .gt zeroMetres)))

/-- Obligation: h2 (obligation): shall pass each other keeping to the right, -/
def obligation : Formula :=
  .forallUser "c"
    (.implies meets (.atom "rel_bearing" [vSubject, vOther, .lit "left"] []))

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
