/-
  NRS_484B_227_1_o1 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (subject): Every vehicle
    d2 (trigger): driven upon a divided highway
    d3 (obligation): must be driven only upon the right-hand roadway
    d4 (boilerplate): and
    d5 (sibling): must not be driven over, across or within any dividing space, barrier or section
    d6 (sibling): or make any left turn, semicircular turn or U-turn,
    d7 (exception): except through an opening in the barrier or dividing section or space
    d8 (exception): or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    d1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d2: atoms ['st.highway', 'st.median_or_divider', 'st.on_way', 'st.roadway', 'rel.occupies'], derived []
    d3: atoms ['st.roadway', 'st.median_or_divider', 'rel.occupies', 'prim.region_lateral_offset'], derived []
    d7: atoms ['st.median_or_divider', 'rel.occupies'], derived []
    d8: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    d1: ego carries the admitted aggregate DEF-NRS-484A-320::vehicle (`ru_aggregate`).
    d2: a highway h (quantifier of kind `highway`) such that ego's footprint overlaps
        (`rel_occupies`) a roadway r lying on h (`st_on_way r h`), and some median or divider
        lies on h (`st_on_way dm h`): the record's applicability, "divided" being the presence of
        the median on the way. "driven" is the plan's agency reading.
    d7/d8: not where ego's footprint overlaps a median or divider lying on h whose opening
        attribute is set (`st_median_or_divider_opening`: the opening and the crossover), or an
        intersection lying on h. The exception is read for the same h the trigger selects; it
        removes the observation from judgment (the record: "not judged at an observation"), so
        it sits in the applicability only.
    d3: for every highway h selected as in the trigger (a roadway of h occupied by ego, a median
        on h — the selection written again), every median or divider m lying on h has a positive signed
        lateral offset from ego (`prim_region_lateral_offset ego m > 0`): it lies to ego's left,
        so ego is on the right-hand roadway.
  No choice beyond the record's: no narrowing is declared.
-/

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-320::vehicle"] []

/-- d2: ego is upon a divided highway `h`: it occupies a roadway lying on `h`, and a median or
    divider lies on `h`. -/
def onDividedHighway (h : String) : Formula :=
  .and
    (.existsRegion (.lit "roadway") "r"
      (.and (.atom "rel_occupies" [vEgo, .var "r"] [])
            (.atom "st_on_way" [.var "r", .var h] [])))
    (.existsRegion (.lit "median_or_divider") "dm"
      (.atom "st_on_way" [.var "dm", .var h] []))

/-- d7, d8: ego is in an opening of a median or divider of `h` (a crossover), or in an
    intersection lying on `h`. -/
def atOpeningOrIntersection (h : String) : Formula :=
  .or
    (.existsRegion (.lit "median_or_divider") "o"
      (.and (.atom "st_on_way" [.var "o", .var h] [])
        (.and (.atom "rel_occupies" [vEgo, .var "o"] [])
              (.atom "st_median_or_divider_opening" [.var "o"] []))))
    (.existsRegion (.lit "intersection") "i"
      (.and (.atom "st_on_way" [.var "i", .var h] [])
            (.atom "rel_occupies" [vEgo, .var "i"] [])))

/-- The highway selection shared by the applicability and the obligation. -/
def selected (h : String) : Formula :=
  .and (onDividedHighway h) (.not (atOpeningOrIntersection h))

/-- Applicability: d2 (trigger): driven upon a divided highway; d7 (exception): except through an opening in the barrier or dividing section or space; d8 (exception): or at a crossover or intersection established by a public authority. -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h" (selected "h")

/-- Obligation: d3 (obligation): must be driven only upon the right-hand roadway -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (onDividedHighway "h")
      (.forallRegion (.lit "median_or_divider") "m"
        (.implies (.atom "st_on_way" [.var "m", .var "h"] [])
          (.cmp (.quantity "prim_region_lateral_offset" [vEgo, .var "m"] []) .gt zeroMetres))))

def rule : Rule :=
  { id := "NRS_484B_227_1_o1"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o1
