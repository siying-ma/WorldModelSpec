/-
  NRS_484B_213_2b — NRS-484B-213-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (subject): A vehicle
    b2 (obligation): must not be driven to the left side of the highway at any time:
    b3 (trigger): When approaching within 100 feet or traversing any intersection or railroad grade crossing.
    b4 (exception): Subsection 2 does not apply upon a one-way highway.

  Elements (span → atoms, derived):
    b1: atoms ['ru.subject', 'ru.aggregate=vehicle'], derived []
    b2: atoms ['st.centre_line', 'st.roadway', 'rel.occupies'], derived []
    b3: atoms ['st.intersection', 'st.railway_crossing', 'st.region_geometry', 'rel.occupies'], derived ['drv.approaching', 'drv.in_intersection']
    b4: atoms ['st.one_way_roadway', 'rel.occupies'], derived []

  Literals the text states (each written through its Units constructor):
    b3: 100 ft — 100 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    b1 — `clsV`: the bound track is the subject and a member of the aggregate word "vehicle".
      The word, not the classes it covers; membership is the reading's.
    b3 — `trigger`: one limb per named structure kind. A limb quantifies over the regions of that
      kind, holds the region against its kind atom, and then asks either that the subject be
      approaching that kind and within the 100 feet of *that* region (`st.region_geometry`'s
      body-to-region distance, which anchors the quantified region to the subject), or that it be
      traversing that kind. The bound is the text's own figure, written through `Units.feet`;
      `p.approach_distance` is the window `drv.approaching` measures its approach over, which is
      the reading's convention and not a figure of the text.
    b4 — `exception`: the duty is withheld while the subject occupies a one-way roadway; written
      as the negation of that occupancy in the applicability, so a one-way highway leaves the rule
      not engaged rather than complied with.
    b2 — `obligation`: while the subject occupies a roadway, its body does not reach the roadway's
      centre line.

  Choices the text did not dictate (each with its CONSEQUENCE, carried in `residues`):
    - "the left side of the highway" is decided at the centre line, and the only signal the
      ontology carries about the subject and that line is occupancy, which is symmetric: the rule
      fires when the body reaches the line. CONSEQUENCE: a body wholly beyond the line, observed
      at no instant astride it, is not caught.
    - "traversing" is `drv.in_intersection` on the structure kind, which is occupancy of some
      region of that kind. CONSEQUENCE: the region traversed is not required to be the region the
      approach distance was measured to.
    - "upon a one-way highway" is read at the roadway: a region of kind `st.one_way_roadway` the
      subject occupies. CONSEQUENCE: a one-way highway whose source maps no one-way roadway region
      under the subject does not withhold the duty.
-/
import TrafficSpec.Core.Rule

namespace TrafficSpec.Rules.NRS_484B_213_2b

/-- The binders, as arguments (order and names are the node's). -/
private def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
private def pApproachDistance : Term := .param "p.approach_distance"

/-- The distance b3 states, through the `Units` constructor of its unit. -/
private def hundredFeet : Term := .lit (Units.feet 100) .metre

/-- Class of `v`: ru.subject, ru.aggregate=vehicle -/
private def clsV : Formula :=
  .and (.atom "ru_subject" [vV] []) (.atom "ru_aggregate" [vV, .lit "vehicle"] [])

/-- b3 for one structure kind: some region of the kind that the subject is approaching within the
    reading's distance of, or is traversing. -/
private def nearOrTraversing (k : StructureKind) (kindLit kindAtom r : String) : Formula :=
  .existsRegion k r
    (.and (.atom kindAtom [.var r] [])
      (.or
        (.and (.derived "drv_approaching" [vV, .lit kindLit] [pApproachDistance])
          (.cmp (.measure "st_region_geometry_distance" [vV, .var r]) .le hundredFeet))
        (.derived "drv_in_intersection" [vV, .lit kindLit] [])))

/-- b4: the subject occupies a one-way roadway. -/
private def onOneWay : Formula :=
  .existsRegion .oneWayRoadway "o"
    (.and (.atom "st_one_way_roadway" [.var "o"] []) (.atom "rel_occupies" [vV, .var "o"] []))

/-- Applicability: b3 (trigger): When approaching within 100 feet or traversing any intersection or railroad grade crossing.; b4 (exception): Subsection 2 does not apply upon a one-way highway. -/
private def applicability : Formula :=
  .and
    (.or
      (nearOrTraversing .intersection "intersection" "st_intersection" "i")
      (nearOrTraversing .railwayCrossing "railway_crossing" "st_railway_crossing" "x"))
    (.not onOneWay)

/-- Obligation: b2 (obligation): must not be driven to the left side of the highway at any time: -/
private def obligation : Formula :=
  .forallRegion .roadway "w"
    (.implies (.and (.atom "st_roadway" [.var "w"] []) (.atom "rel_occupies" [vV, .var "w"] []))
      (.forallRegion .centreLine "c"
        (.implies (.atom "st_centre_line" [.var "c"] [])
          (.not (.atom "rel_occupies" [vV, .var "c"] [])))))

def rule : Rule :=
  { id := "NRS_484B_213_2b"
    laws := ["NRS-484B-213-2b"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues :=
      [ "The left side of the highway is decided at the centre line by occupancy: a body observed at no instant astride the centre line, though wholly beyond it, is not caught."
      , "Traversing is occupancy of some region of the named kind, not necessarily the region the approach distance was measured to."
      , "The saving clause is read at the roadway: a one-way highway whose source maps no one-way roadway region under the subject does not withhold the duty." ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_213_2b
