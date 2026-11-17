/-
  NRS_484B_227_1_o2 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (subject): Every vehicle
    b (trigger): driven upon a divided highway
    c (sibling): must be driven only upon the right-hand roadway
    d (obligation): and must not be driven over, across or within any dividing space, barrier or section
    e (sibling): or make any left turn, semicircular turn or U-turn,
    f (exception): except through an opening in the barrier or dividing section or space
    g (exception): or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.median_or_divider'], derived []
    d: atoms ['rel.occupies', 'st.median_or_divider'], derived []
    f: atoms ['rel.occupies', 'st.median_or_divider'], derived []
    g: atoms ['rel.occupies', 'st.median_or_divider', 'st.intersection'], derived []

  How each span is written:
    a: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    b: a highway h (quantifier over kind `highway`, st.highway) that the subject occupies
       (rel_occupies subject h) and on which some median_or_divider region lies
       (quantifier over kind `median_or_divider`, st_on_way md h). "Driven" is the plan's
       observable reading (the vehicle's presence/motion on h), not restated here.
    g (intersection limb): conjoined into the selection of h as the absence of an intersection
       lying on h (st_on_way i h, kind `intersection`) whose region the subject occupies
       (rel_occupies subject i): where it holds, the rule does not apply (blueprint applicability).
    d: for every median_or_divider region m lying on h (st_on_way m h), the subject's footprint
       does not overlap m (not rel_occupies subject m). "Over, across or within" are all the
       overlap, as the element states.
    f / g (crossover limb): the duty at m is lifted where m carries the opening attribute
       (st_median_or_divider_opening m), the accessor of st.median_or_divider.
  The obligation re-binds h by the applicability's whole selection (occupied, divided, no
  occupied intersection on it) and states the duty for every such h and every divider on it.
  No choice beyond the record's: no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- b: some median_or_divider region lies on highway `h` (h divided). -/
def dividedHighway (h : String) : Formula :=
  .existsRegion (.lit "median_or_divider") "md"
    (.atom "st_on_way" [.var "md", .var h] [])

/-- g (intersection limb): the subject's footprint overlaps an intersection lying on highway `h`. -/
def atIntersectionOn (h : String) : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (.atom "st_on_way" [.var "i", .var h] [])
          (.atom "rel_occupies" [vSubject, .var "i"] []))

/-- The selection of highway `h`: the subject occupies it, it is divided, and the subject is not
    at an intersection lying on it. -/
def selectsHighway (h : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var h] [])
    (.and (dividedHighway h) (.not (atIntersectionOn h)))

/-- Applicability: b (trigger): driven upon a divided highway; f (exception): except through an opening in the barrier or dividing section or space; g (exception): or at a crossover or intersection established by a public authority. -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h" (selectsHighway "h")

/-- Obligation: d (obligation): and must not be driven over, across or within any dividing space, barrier or section -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (selectsHighway "h")
      (.forallRegion (.lit "median_or_divider") "m"
        (.implies (.atom "st_on_way" [.var "m", .var "h"] [])
          (.or (.not (.atom "rel_occupies" [vSubject, .var "m"] []))
               (.atom "st_median_or_divider_opening" [.var "m"] [])))))

def rule : Rule :=
  { id := "NRS_484B_227_1_o2"
    laws := ["NRS-484B-227-1"]
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

end TrafficSpec.Rules.NRS_484B_227_1_o2
