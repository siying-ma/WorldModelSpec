/-
  NRS_484B_227_1_o1 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (subject): Every vehicle
    b (trigger): driven upon a divided highway
    c (obligation): must be driven only upon the right-hand roadway
    d (sibling): and must not be driven over, across or within any dividing space, barrier or section
    e (sibling): or make any left turn, semicircular turn or U-turn,
    f (exception): except through an opening in the barrier or dividing section or space
    g (exception): or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.median_or_divider'], derived []
    c: atoms ['rel.occupies', 'st.roadway', 'st.on_way'], derived ['drv.motion.moving_against_carrier']
    f: atoms ['rel.occupies', 'st.median_or_divider'], derived []
    g: atoms ['rel.occupies', 'st.median_or_divider', 'st.intersection'], derived []

  How each is written:
    a: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    b: some highway region h the subject occupies (`rel_occupies`) on which some median_or_divider
       region lies (`st_on_way d h`).
    f, g: no median_or_divider region lying on h that carries the opening attribute
       (`st_median_or_divider_opening`: an opening, or a crossover) is occupied by the subject, and no
       intersection lying on h is occupied by the subject. Both exceptions are conjoined into the
       selection of h.
    c: for every highway h selected as in the applicability (the whole selection, exceptions
       included, re-written: 3c), for every roadway r lying on h that the subject occupies,
       `drv_motion_moving_against_carrier subject r` with speed_tol p.halt_speed_tolerance does
       not hold.
  No choice beyond the record's was made: no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- b: a median_or_divider region lies on the highway `h`. -/
def dividedHighway (h : String) : Formula :=
  .existsRegion (.lit "median_or_divider") "d"
    (.atom "st_on_way" [.var "d", .var h] [])

/-- f, g (crossover): the subject's footprint overlaps a divider region lying on `h` that carries the
    opening attribute. -/
def atOpening (h : String) : Formula :=
  .existsRegion (.lit "median_or_divider") "o"
    (.and (.atom "st_on_way" [.var "o", .var h] [])
      (.and (.atom "rel_occupies" [vSubject, .var "o"] [])
        (.atom "st_median_or_divider_opening" [.var "o"] [])))

/-- g (intersection): the subject's footprint overlaps an intersection lying on `h`. -/
def atIntersection (h : String) : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (.atom "st_on_way" [.var "i", .var h] [])
      (.atom "rel_occupies" [vSubject, .var "i"] []))

/-- The selection of the highway `h`: occupied by the subject, divided, and neither exception holds. -/
def selectedHighway (h : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var h] [])
    (.and (dividedHighway h)
      (.and (.not (atOpening h)) (.not (atIntersection h))))

/-- Applicability: b (trigger): driven upon a divided highway; f (exception): except through an opening in the barrier or dividing section or space; g (exception): or at a crossover or intersection established by a public authority. -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h" (selectedHighway "h")

/-- Obligation: c (obligation): must be driven only upon the right-hand roadway -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (selectedHighway "h")
      (.forallRegion (.lit "roadway") "r"
        (.implies
          (.and (.atom "st_on_way" [.var "r", .var "h"] [])
            (.atom "rel_occupies" [vSubject, .var "r"] []))
          (.not (.derived "drv_motion_moving_against_carrier" [vSubject, .var "r"]
            [pHaltSpeedTolerance])))))

def rule : Rule :=
  { id := "NRS_484B_227_1_o1"
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

end TrafficSpec.Rules.NRS_484B_227_1_o1
