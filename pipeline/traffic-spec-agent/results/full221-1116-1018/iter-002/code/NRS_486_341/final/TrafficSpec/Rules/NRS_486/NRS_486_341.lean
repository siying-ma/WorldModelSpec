/-
  NRS_486_341 — NRS-486-341

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): Every motorcycle or moped
    s2 (condition): when being driven on the highway
    s3 (condition): is entitled to full use of the traffic lane it is occupying,
    s4 (subject): and a person shall not drive another motor vehicle
    s5 (obligation): in a manner which would deprive any such motorcycle or moped of such use.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-486-041::motorcycle', 'ru.aggregate=DEF-NRS-486-038::moped'], derived []
    s2: atoms ['rel.occupies', 'st.highway'], derived []
    s3: atoms ['rel.occupies', 'st.lane'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    s5: atoms ['rel.occupies', 'st.lane', 'rel.longitudinal_overlap'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_486_341

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s4: the binder class — `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`.
    s1: the road user `m` (a `forallUser` quantifier, other than the subject: `not (same m subject)`)
        is of DEF-NRS-486-041::motorcycle or of DEF-NRS-486-038::moped (`ru_aggregate`, each
        aggregate as its own disjunct).
    s2: `m` occupies some highway region (`existsRegion "highway" h (rel_occupies m h)`).
    s3: every lane `L` that `m` occupies (`forallRegion "lane" L (rel_occupies m L → …)`).
    s5: not (the subject occupies that same `L` and `rel_longitudinal_overlap subject m ≥ 0`).
  The applicability is the record's: the subject is a motor vehicle, which the binder class
  states; the motorcycle/moped, highway and lane conditions guard the duty per road user and per
  lane inside the obligation (the record's obligation), so a scene with no motorcycle or moped is
  compliant, not "not applicable". No choice beyond the record's was made: no narrowings.
-/

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- Applicability: the record's — the subject is a motor vehicle (its binder class); the
    s1–s3 conditions guard the duty per motorcycle/moped and per lane in the obligation. -/
def applicability : Formula := .tt

def vM : Arg := .var "m"
def vH : Arg := .var "h"
def vL : Arg := .var "L"

/-- s1: m is a motorcycle or a moped. -/
def motorcycleOrMoped : Formula :=
  .or (.atom "ru_aggregate" [vM, .lit "DEF-NRS-486-041::motorcycle"] [])
      (.atom "ru_aggregate" [vM, .lit "DEF-NRS-486-038::moped"] [])

/-- s2: m is on the highway. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vM, vH] [])

/-- s5: the subject shares lane L with m while side by side with it. -/
def deprives : Formula :=
  .and (.atom "rel_occupies" [vSubject, vL] [])
       (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vM]) .ge zeroMetres)

/-- Obligation: s5 (obligation): in a manner which would deprive any such motorcycle or moped of such use. -/
def obligation : Formula :=
  .forallUser "m"
    (.implies (.and (.not (.same vM vSubject)) (.and motorcycleOrMoped onHighway))
      (.forallRegion (.lit "lane") "L"
        (.implies (.atom "rel_occupies" [vM, vL] []) (.not deprives))))

def rule : Rule :=
  { id := "NRS_486_341"
    laws := ["NRS-486-341"]
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

end TrafficSpec.Rules.NRS_486_341
