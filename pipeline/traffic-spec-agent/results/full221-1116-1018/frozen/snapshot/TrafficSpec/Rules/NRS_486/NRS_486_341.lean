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

  How each is written:
    s4: the binder class, `ru_aggregate subject DEF-NRS-484A-130::motor_vehicle`. The applicability
        is the class alone (the record's applicability), so a scene without any motorcycle or
        moped is judged compliant, not idle.
    s1: the obligation quantifies every road user `m` other than the subject (`not (same m subject)`)
        that is of either admitted aggregate (motorcycle or moped, a disjunction).
    s2: `m` occupies some region of kind `highway` (`existsRegion highway h (rel_occupies m h)`).
    s3: every region of kind `lane` that `m` occupies (`forallRegion lane L (rel_occupies m L → …)`).
    s5: in each such lane, it is not the case that the subject occupies L and
        rel_longitudinal_overlap(subject, m) ≥ 0 (zero, the record's bound).
    The quantifiers are the record's (every m, every L), at every observation (no time operator:
    the verdict aggregates the instants). No choice beyond the record was needed: no narrowing.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_486_341

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The quantified motorcycle or moped, the highway it is on, the lane it occupies. -/
def vM : Arg := .var "m"
def vH : Arg := .var "h"
def vL : Arg := .var "L"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- Applicability: the subject is a motor vehicle (the binder class); s1–s3 are the guard of the
    obligation's quantifiers, so a scene with no motorcycle or moped is compliant. -/
def applicability : Formula := clsSubject

/-- s1: `m` is a motorcycle or a moped. -/
def motorcycleOrMoped : Formula :=
  .or (.atom "ru_aggregate" [vM, .lit "DEF-NRS-486-041::motorcycle"] [])
      (.atom "ru_aggregate" [vM, .lit "DEF-NRS-486-038::moped"] [])

/-- s2: `m` is on a highway. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vM, vH] [])

/-- s5: the subject shares lane `L` with `m` side by side. -/
def sharesLaneBeside : Formula :=
  .and (.atom "rel_occupies" [vSubject, vL] [])
       (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vM]) .ge zeroMetres)

/-- Obligation: s1, s2, s3 guard; s5 the duty in each lane the motorcycle or moped occupies. -/
def obligation : Formula :=
  .forallUser "m"
    (.implies
      (.and (.not (.same vM vSubject)) (.and motorcycleOrMoped onHighway))
      (.forallRegion (.lit "lane") "L"
        (.implies (.atom "rel_occupies" [vM, vL] [])
                  (.not sharesLaneBeside))))

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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_486_341
