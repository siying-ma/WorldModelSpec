/-
  NRS_484B_227_1_o2 — NRS-484B-227-1

  THE READING (the blueprint's; this session records here, per span, how each element is written,
  and every choice the text did not dictate).

  Spans:
    s1 (subject): Every vehicle
    s2 (trigger): driven upon a divided highway
    s3 (sibling): must be driven only upon the right-hand roadway
    s4 (obligation): and must not be driven over, across or within any dividing space, barrier or section
    s5 (sibling): or make any left turn, semicircular turn or U-turn,
    s6 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=vehicle'], derived []
    s2: atoms ['st.highway', 'st.roadway', 'st.median_or_divider', 'rel.occupies'], derived []
    s4: atoms ['rel.occupies', 'st.median_or_divider'], derived []
    s6: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies'], derived []

  How each span is written.

  s1 — `clsV` is `ru_aggregate v "vehicle"`: the word of the text as the atom's literal argument,
  never the classes the word covers.

  s2 — `uponDividedHighway`. A highway, a roadway and a dividing section are region kinds, so each
  is a region quantifier of that kind, and `rel_occupies` ties the subject to the way and to the
  roadway it is upon: the highway read is the subject's own, and the roadway is the one its
  footprint overlaps. “divided” is the dividing section between the roadways: the third quantifier
  asserts that the scene carries one. `rel.occupies` is the only tie between the subject and a
  region the record claims — no claimed atom relates two regions — so the dividing section is named
  through the subject's own place: the quantifier's body is `¬(occupies v m ∧ opening m)`, the
  dividing section the subject is not upon through an opening of it. Under the exception conjunct
  below (which holds of every dividing section of the scene wherever the rule applies) this is
  exactly “a dividing section is there”: where the subject is upon one through its opening the
  exception already withdraws the rule, and where it is not, every dividing section of the scene
  satisfies the body. The “driven” of the span is the vehicle's own controlled motion upon the way,
  whoever is at the controls (the record's observable reading on s2); nothing here reads an agent.

  s6 — `throughOpening` and `withinIntersection`, negated in the applicability, so the rule is not
  engaged where the exception holds. `throughOpening` is `∃ m [median_or_divider]. occupies v m ∧
  st_median_or_divider_opening m`: the opening in the barrier, dividing section or space, read on
  the very structure the duty reads and at the subject's own place, which is also the crossover the
  span names (the attribute marks the dividing section where a crossover exists). `withinIntersection`
  is `∃ i [intersection]. occupies v i`. “established by a public authority” is a legal status no
  scene carries; the presence of the opening and of the intersection is its observable evidence and
  the rule presumes it (the record's observable reading on s6). Both limbs are anchored to the
  subject by `rel_occupies`, so the exception is the subject's own place and not any opening of the
  scene.

  s4 — `obligation` is `¬ ∃ m [median_or_divider]. occupies v m`: the subject's footprint overlaps
  no dividing space, barrier or section. “over, across or within” is one observation, declared as a
  narrowing below.

  s3 and s5 are siblings of this node and are written nowhere here.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
  This rule has none of either: every leaf is a Boolean atom.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantified regions, as arguments. -/
def hA : Arg := .var "h"
def rA : Arg := .var "r"
def mA : Arg := .var "m"
def moA : Arg := .var "mo"
def mxA : Arg := .var "mx"
def iA : Arg := .var "i"

/-- The subject's footprint overlaps the region `x` (`rel.occupies`). -/
def occupies (x : Arg) : Formula := .atom "rel_occupies" [vV, x] []

/-- The dividing structure `x` carries an opening, where a crossover exists
    (`st.median_or_divider`). -/
def hasOpening (x : Arg) : Formula := .atom "st_median_or_divider_opening" [x] []

/-- Class of `v`: ru.aggregate=vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "vehicle"] []

/-- s6, first limb: the subject is upon a dividing section through an opening in it (a crossover). -/
def throughOpening : Formula :=
  .existsRegion (.lit "median_or_divider") "mo"
    (.and (occupies moA) (hasOpening moA))

/-- s6, second limb: the subject is within an intersection. -/
def withinIntersection : Formula :=
  .existsRegion (.lit "intersection") "i" (occupies iA)

/-- s2 (trigger): the subject's footprint overlaps a roadway of a highway which a dividing
    section divides. -/
def uponDividedHighway : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (occupies hA)
      (.existsRegion (.lit "roadway") "r"
        (.and (occupies rA)
          (.existsRegion (.lit "median_or_divider") "m"
            (.not (.and (occupies mA) (hasOpening mA)))))))

/-- Applicability: s2 (trigger): driven upon a divided highway; s6 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority. -/
def applicability : Formula :=
  .and uponDividedHighway (.not (.or throughOpening withinIntersection))

/-- Obligation: s4 (obligation): and must not be driven over, across or within any dividing space, barrier or section -/
def obligation : Formula :=
  .not (.existsRegion (.lit "median_or_divider") "mx" (occupies mxA))

def rule : Rule :=
  { id := "NRS_484B_227_1_o2"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s4"
        , why := "“over, across or within” is written as one observation: the subject's footprint overlaps the dividing space, barrier or section (rel.occupies). A body driven over or across the structure overlaps it while it passes, so the three words are decided alike; the reading is narrower than the words where a body passes the structure between two observations without being seen upon it, which the sampling rate of the source bounds."
        , kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o2
