/-
  NRS_484B_227_1_o2 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (subject): Every vehicle
    d2 (trigger): driven upon a divided highway
    d3 (sibling): must be driven only upon the right-hand roadway
    d4 (boilerplate): and
    d5 (obligation): must not be driven over, across or within any dividing space, barrier or section
    d6 (sibling): or make any left turn, semicircular turn or U-turn,
    d7 (exception): except through an opening in the barrier or dividing section or space
    d8 (exception): or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    d1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d2: atoms ['st.highway', 'st.median_or_divider', 'st.on_way', 'st.roadway', 'rel.occupies'], derived []
    d5: atoms ['st.median_or_divider', 'rel.occupies'], derived []
    d7: atoms ['st.median_or_divider', 'rel.occupies'], derived []
    d8: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies'], derived []

  How each span is written:
    d1: the class of `ego` is `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
    d2: a highway `h` (region quantifier of kind `highway`) on which some median or divider lies
        (`st_on_way md h`), and ego's footprint overlaps (`rel_occupies`) a roadway lying on `h` or
        a median or divider lying on `h`. "driven" is the record's agency reading: no atom.
    d5: for every median or divider `m` lying on `h` that ego's footprint overlaps, the duty is
        breached unless one of the exceptions holds.
    d7: `m`'s opening attribute is set (`st_median_or_divider_opening m`).
    d8: the crossover limb is the opening attribute again (d7's atom); the intersection limb is an
        intersection `i` lying on `h` (`st_on_way i h`) that ego's footprint also overlaps.
    The obligation re-selects `h` as a divided highway and states the duty for every such `h`, as
    the record's "no median or divider m lying on h" reads. The applicability's "ego upon h" is not
    restated there: the duty's own antecedent (ego overlaps a median or divider lying on `h`) is
    its median limb, so wherever the duty speaks ego is upon `h`, and the roadway limb could never
    change the obligation's value (the gate found it vacuous there).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

def zeroMetres : Term := .lit Q.zero .metre

def vH : Arg := .var "h"

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-320::vehicle"] []

/-- d2: `h` is a divided highway — some median or divider lies on it. -/
def divided : Formula :=
  .existsRegion (.lit "median_or_divider") "md" (.atom "st_on_way" [.var "md", vH] [])

/-- d2: ego upon `h` — its footprint overlaps a roadway or a median or divider lying on `h`. -/
def upon : Formula :=
  .or
    (.existsRegion (.lit "roadway") "r"
      (.and (.atom "st_on_way" [.var "r", vH] []) (.atom "rel_occupies" [vEgo, .var "r"] [])))
    (.existsRegion (.lit "median_or_divider") "mu"
      (.and (.atom "st_on_way" [.var "mu", vH] []) (.atom "rel_occupies" [vEgo, .var "mu"] [])))

/-- The selection of `h`: a divided highway ego is upon. -/
def selected : Formula := .and divided upon

/-- Applicability: d2 (trigger): driven upon a divided highway. -/
def applicability : Formula := .existsRegion (.lit "highway") "h" selected

/-- d7, d8: an opening (crossover) in `m`, or an intersection lying on `h` that ego overlaps. -/
def excepted : Formula :=
  .or
    (.atom "st_median_or_divider_opening" [.var "m"] [])
    (.existsRegion (.lit "intersection") "i"
      (.and (.atom "st_on_way" [.var "i", vH] []) (.atom "rel_occupies" [vEgo, .var "i"] [])))

/-- Obligation: d5 (obligation): must not be driven over, across or within any dividing space,
    barrier or section; d7, d8 (exceptions). -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies divided
      (.forallRegion (.lit "median_or_divider") "m"
        (.implies
          (.and (.atom "st_on_way" [.var "m", vH] []) (.atom "rel_occupies" [vEgo, .var "m"] []))
          excepted)))

def rule : Rule :=
  { id := "NRS_484B_227_1_o2"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o2
