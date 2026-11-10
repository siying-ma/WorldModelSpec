/-
  NRS_484B_400_1_o2 — NRS-484B-400-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    r1 (subject): If the driver of a vehicle
    r2 (trigger): intends to turn
    r3 (trigger): at an intersection
    r4 (trigger): and: The turn is a right turn,
    r5 (sibling): both the approach for the right turn and the right turn must be made from the right turn lane
    r6 (condition): if the highway has a right turn lane
    r7 (reference): as set forth in subsection 4 of NRS 484B.223 [NRS-484B-223-4a, NRS-484B-223-4b],
    r8 (obligation): or must be made from the extreme right lane.

  Elements (span → atoms, derived):
    r1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    r3: atoms ['st.intersection', 'st.lane_enters', 'rel.occupies', 'st.travel_region'], derived []
    r6: atoms ['st.turn_lane', 'st.lane_adjacency', 'st.on_way', 'st.highway', 'st.lane_enters', 'st.intersection', 'rel.occupies'], derived [], borrowing ['r7']
    r8: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency', 'st.lane_enters', 'st.intersection'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    r7: NRS-484B-223-4a: If a highway has been designed to provide a single right lane to be used only for turning
    r7: NRS-484B-223-4b: If a highway has been designed to provide a single right lane to be used only for turning

  How each span is written:
    r1: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    r2, r4: the declared intention `int.turn_right` of x at the intersection i, read at the judged
      observation (the entry).
    r3: an intersection i (`existsRegion "intersection"`) that x enters here: `rises (rel_occupies x i)`.
      The carrier of r3 (a `travel_region` x occupies whose entrance end is i, `st_lane_enters`)
      is the carrier through which r6 finds the highway.
    r6 (+ r7): the highway has a right turn lane: some `turn_lane` t with side right, entering i,
      whose `st_lane_adjacency` ordinal equals its count (the rightmost lane of its direction: the
      borrowed "single right lane to be used only for turning"), lying on (`st_on_way`) a
      `highway` w on which also lies a `travel_region` carrier c that x occupies and that enters i.
      The record reads it at the observation before the entry, and the node applies where no such
      lane exists there.
    r8: at the observation before the entry, x occupies some `lane` l entering i whose ordinal
      equals its count, and every `lane` x occupies there that enters i is such a lane.

  "At the observation before the entry". The language has no previous-observation operator; the
  record fixes the judged observation at the entry, where `rel_occupies x i` rises (false at the
  observation before, true here). At such an observation `rises (rel_occupies x i ∨ ψ)` is exactly
  "ψ is false at the observation before" (the disjunction is true here through the occupancy, and
  false at the observation before exactly where ψ is), so `notBefore i ψ` states ψ's absence at the
  observation before the entry and `before i ψ := notBefore i (¬ψ)` states ψ there. Both are used
  only conjoined with (or under) the entry `rises (rel_occupies x i)`. This writes the record's
  instant as stated; it is no narrowing.

  The obligation restates the applicability's whole selection of i (the entry, the declared
  intention, the absent right turn lane) and requires the extreme right lane at every intersection
  so selected.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

def zeroMetres : Term := .lit Q.zero .metre

def vI : Arg := .var "i"

/-- `rel_occupies x r`. -/
def occ (r : Arg) : Formula := .atom "rel_occupies" [vX, r] []

/-- r3: x enters the intersection i here. -/
def entersI : Formula := .rises (occ vI)

/-- At an entry into i (`entersI`): ψ is false at the observation before the entry. -/
def notBefore (ψ : Formula) : Formula := .rises (.or (occ vI) ψ)

/-- At an entry into i (`entersI`): ψ holds at the observation before the entry. -/
def before (ψ : Formula) : Formula := notBefore (.not ψ)

/-- The lane is the rightmost of its direction: its ordinal from the left equals the count. -/
def rightmost (r : Arg) : Formula :=
  .cmp (.measure "st_lane_adjacency" [r, .lit "ordinal"]) .eq (.measure "st_lane_adjacency" [r, .lit "count"])

/-- r6 (+ r7): the highway of a carrier x occupies entering i has a right turn lane entering i. -/
def rightTurnLane : Formula :=
  .existsRegion (.lit "turn_lane") "t"
    (.and (.atom "st_turn_lane_side" [.var "t", .lit "right"] [])
    (.and (.atom "st_lane_enters" [.var "t", vI] [])
    (.and (rightmost (.var "t"))
      (.existsRegion (.lit "highway") "w"
        (.and (.atom "st_on_way" [.var "t", .var "w"] [])
          (.existsRegion (.lit "travel_region") "c"
            (.and (occ (.var "c"))
            (.and (.atom "st_lane_enters" [.var "c", vI] [])
                  (.atom "st_on_way" [.var "c", .var "w"] [])))))))))

/-- r2, r3, r4, r6: the selection of i — x enters it here with its declared intention to turn
    right there, and the highway had no right turn lane at the observation before the entry. -/
def selected : Formula :=
  .and entersI
  (.and (.intent "int.turn_right" vX vI)
        (notBefore rightTurnLane))

/-- r8: x occupies a lane entering i that is the extreme right lane, and every lane it occupies
    entering i is. -/
def extremeRight : Formula :=
  .and
    (.existsRegion (.lit "lane") "l"
      (.and (occ (.var "l"))
      (.and (.atom "st_lane_enters" [.var "l", vI] [])
            (rightmost (.var "l")))))
    (.forallRegion (.lit "lane") "l"
      (.implies
        (.and (occ (.var "l")) (.atom "st_lane_enters" [.var "l", vI] []))
        (rightmost (.var "l"))))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: r2 (trigger): intends to turn; r3 (trigger): at an intersection; r4 (trigger): and: The turn is a right turn,; r6 (condition): if the highway has a right turn lane -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" selected

/-- Obligation: r8 (obligation): or must be made from the extreme right lane. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies selected (before extremeRight))

def rule : Rule :=
  { id := "NRS_484B_400_1_o2"
    laws := ["NRS-484B-400-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.turn_right"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_400_1_o2
