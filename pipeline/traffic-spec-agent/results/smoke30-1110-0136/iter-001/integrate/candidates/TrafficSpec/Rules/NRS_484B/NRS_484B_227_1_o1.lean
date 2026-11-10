/-
  NRS_484B_227_1_o1 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every vehicle
    s2 (trigger): driven upon a divided highway
    s3 (obligation): must be driven only upon the right-hand roadway
    s4 (sibling): and must not be driven over, across or within any dividing space, barrier or section
    s5 (sibling): or make any left turn, semicircular turn or U-turn
    s6 (sibling): except through an opening in the barrier or dividing section or space
    s7 (sibling): or at a crossover or intersection established by a public authority

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.highway', 'st.median_or_divider', 'st.on_way', 'rel.occupies'], derived []
    s3: atoms ['st.roadway', 'st.lane', 'st.on_way', 'rel.occupies'], derived ['drv.lane.facing_against_direction']

  How each is written:
    s1: the binder class is ru_aggregate(x, DEF-NRS-484A-320::vehicle).
    s2: some highway h that x occupies (rel_occupies) has a median_or_divider m lying on it
        (st_on_way(m, h)); 'driven' is the record's observable reading (presence), not restated.
    s3: for every highway h selected as in s2 (the whole selection restated), for every roadway c
        and, separately, every lane c with st_on_way(c, h) and rel_occupies(x, c):
        not drv_lane_facing_against_direction(x, c; p.against_direction_cos_tolerance).
        The record states this reading in full; no narrowing of this file's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pAgainstDirectionCosTolerance : Term := .param "p.against_direction_cos_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: the highway `h` is divided — some median or divider lies on it. -/
def dividedHighway (h : String) : Formula :=
  .existsRegion (.lit "median_or_divider") "m" (.atom "st_on_way" [.var "m", .var h] [])

/-- s2: `x` is upon a divided highway `h` (the whole selection, restated in the obligation). -/
def onDividedHighway (h : String) : Formula :=
  .and (.atom "rel_occupies" [vX, .var h] []) (dividedHighway h)

/-- Applicability: s2 (trigger): driven upon a divided highway -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h" (onDividedHighway "h")

/-- s3: on every carrier of kind `kind` lying on `h` that `x` occupies, `x` does not point
    against its designated direction. -/
def notAgainstOn (kind h : String) : Formula :=
  .forallRegion (.lit kind) "c"
    (.implies
      (.and (.atom "st_on_way" [.var "c", .var h] []) (.atom "rel_occupies" [vX, .var "c"] []))
      (.not (.derived "drv_lane_facing_against_direction" [vX, .var "c"] [pAgainstDirectionCosTolerance])))

/-- Obligation: s3 (obligation): must be driven only upon the right-hand roadway -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (onDividedHighway "h")
      (.and (notAgainstOn "roadway" "h") (notAgainstOn "lane" "h")))

def rule : Rule :=
  { id := "NRS_484B_227_1_o1"
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

end TrafficSpec.Rules.NRS_484B_227_1_o1
