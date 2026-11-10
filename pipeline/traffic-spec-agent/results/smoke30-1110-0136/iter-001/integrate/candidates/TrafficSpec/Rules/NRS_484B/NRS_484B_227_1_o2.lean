/-
  NRS_484B_227_1_o2 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every vehicle
    s2 (trigger): driven upon a divided highway
    s3 (sibling): must be driven only upon the right-hand roadway
    s4 (obligation): and must not be driven over, across or within any dividing space, barrier or section
    s5 (sibling): or make any left turn, semicircular turn or U-turn
    s6 (exception): except through an opening in the barrier or dividing section or space
    s7 (exception): or at a crossover or intersection established by a public authority

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.highway', 'st.median_or_divider', 'st.on_way', 'rel.occupies'], derived []
    s4: atoms ['st.median_or_divider', 'rel.occupies'], derived []
    s6: atoms ['st.median_or_divider', 'rel.occupies'], derived []
    s7: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written:
    s1: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`, the admitted aggregate claimed whole.
    s2: some highway region `h` that `x` occupies, on which some median or divider region lies
        (`st_on_way m h`). The `m` of the applicability only establishes that the highway is
        divided; the duty speaks of every divider `x` occupies on such a highway.
    s4: for every median or divider region `m` that `x` occupies and that lies on a highway `x`
        occupies (the applicability's whole selection of the highway restated, rule 3c), the
        exception must hold; outside s6/s7 occupying `m` is the violation.
    s6/s7: the exception is the consequent of the obligation, as the record writes it: the opening
        attribute of that same `m` (the crossover/opening `x` passes through), or some intersection
        region `i` that `x` occupies. Where the opening attribute is unobserved the duty is unknown.
  No choice beyond the record's own narrowings (s2 agency, s7 status) was made.
-/

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: `x` occupies a highway on which a median or divider lies. -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vX, .var "h"] [])
      (.existsRegion (.lit "median_or_divider") "m"
        (.atom "st_on_way" [.var "m", .var "h"] [])))

/-- s6/s7: through the opening of `m`, or at an intersection `x` occupies. -/
def excepted : Formula :=
  .or (.atom "st_median_or_divider_opening" [.var "m"] [])
    (.existsRegion (.lit "intersection") "i" (.atom "rel_occupies" [vX, .var "i"] []))

/-- s4: every divider of a highway `x` occupies that `x` occupies is crossed only as s6/s7 allow. -/
def obligation : Formula :=
  .forallRegion (.lit "median_or_divider") "m"
    (.implies
      (.and (.atom "rel_occupies" [vX, .var "m"] [])
        (.existsRegion (.lit "highway") "h"
          (.and (.atom "rel_occupies" [vX, .var "h"] [])
            (.atom "st_on_way" [.var "m", .var "h"] []))))
      excepted)

def rule : Rule :=
  { id := "NRS_484B_227_1_o2"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o2
