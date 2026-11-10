/-
  NRS_484B_400_1_o1 — NRS-484B-400-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    r1 (subject): If the driver of a vehicle
    r2 (trigger): intends to turn
    r3 (trigger): at an intersection
    r4 (trigger): and: The turn is a right turn,
    r5 (obligation): both the approach for the right turn and the right turn must be made from the right turn lane
    r6 (condition): if the highway has a right turn lane
    r7 (reference): as set forth in subsection 4 of NRS 484B.223 [NRS-484B-223-4a, NRS-484B-223-4b],
    r8 (sibling): or must be made from the extreme right lane.

  Elements (span → atoms, derived):
    r1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    r3: atoms ['st.intersection', 'st.lane_enters', 'rel.occupies', 'st.travel_region'], derived []
    r5: atoms ['rel.occupies', 'st.turn_lane', 'st.lane_enters', 'st.intersection'], derived []
    r6: atoms ['st.turn_lane', 'st.lane_adjacency', 'st.on_way', 'st.highway', 'st.lane_enters', 'st.intersection', 'rel.occupies'], derived [], borrowing ['r7']

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    r7: NRS-484B-223-4a: If a highway has been designed to provide a single right lane to be used only for turning
    r7: NRS-484B-223-4b: If a highway has been designed to provide a single right lane to be used only for turning

  How each span is written.
    r1: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    r2, r4: the declared intention `int.turn_right` of x at the intersection i, read at the judged
      observation (the entry).
    r3: i ranges over the scene's intersections; the judged observation is x's entry into i,
      `rises (rel_occupies x i)`. The approach carrier c ranges over travel regions, anchored by
      `rel_occupies x c` and tied to i by `st_lane_enters c i`.
    r6 (with r7): at the observation before the entry, x occupies a carrier c entering i, and some
      turn lane t (quantifier kind `turn_lane`) of side right enters i (`st_lane_enters t i`), lies on
      a highway h (quantifier kind `highway`) that c lies on too (`st_on_way`), is the rightmost
      lane of its direction (`st_lane_adjacency` ordinal equal to count), and is c or a lane reached
      from c through right-neighbour links (`st_lane_adjacency c "right" l`).
    r5: at the observation before the entry, x occupies such a right turn lane t (the selection
      above with c := t, where "c or reached from c" holds trivially and is not written), and
      every travel region x occupies there that enters i is a turn lane of side right.
    r8: the sibling's (the extreme-right-lane node's); nothing of it is written here.

  The observation before the entry. The language has no "previous observation" operator; it is
  written exactly through `rises`. Where E = `rel_occupies x i` rises (E true here, false at the
  previous observation), ψ held at the previous observation iff `E ∨ ψ` did not rise here:
  `prevAtEntry i ψ := not (rises (E ∨ ψ))`. Both formulas use it only under `rises E`.

  Right-neighbour reachability. The record's "a lane reached from c through right-neighbour links"
  is a transitive closure, which the language has no operator for; it is unrolled to `reachSteps`
  links (c and up to five lanes to its right: six lanes in one direction). A carrier further than
  five lanes left of the turn lane would leave the rule not applicable; this is recorded in
  task_result.md as a limitation of the language, not as a reading of the span.

  The applicability and the obligation are separate formulas: the obligation states again, for
  every intersection i, the whole selection the applicability made (entry, intention, right turn
  lane at the observation before), and requires the duty at each selected i.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- x occupies region `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vX, .var r] []

/-- Carrier `c` enters intersection `i`. -/
def enters (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []

/-- Region `r` lies on highway `h`. -/
def onWay (r h : String) : Formula := .atom "st_on_way" [.var r, .var h] []

/-- `b` is lane `a`'s right neighbour of the same direction. -/
def rightOf (a b : String) : Formula := .atom "st_lane_adjacency" [.var a, .lit "right", .var b] []

/-- Lane `t` is the rightmost lane of its direction: its ordinal from the left equals the count. -/
def rightmost (t : String) : Formula :=
  .cmp (.measure "st_lane_adjacency" [.var t, .lit "ordinal"]) .eq
    (.measure "st_lane_adjacency" [.var t, .lit "count"])

/-- Turn lane `t` is of side right. -/
def rightSide (t : String) : Formula := .atom "st_turn_lane_side" [.var t, .lit "right"] []

/-- How many right-neighbour links the reachability from `c` is unrolled to. -/
def reachSteps : Nat := 5

/-- `t` is `a` or a lane reached from `a` through at most `k` right-neighbour links. -/
def reach : Nat → String → String → Formula
  | 0, a, t => .same (.var a) (.var t)
  | k + 1, a, t =>
    let l := s!"l{k + 1}"
    .or (.same (.var a) (.var t))
      (.existsRegion (.lit "travel_region") l (.and (rightOf a l) (reach k l t)))

/-- `t` lies on a highway carrier `c` lies on (on a highway, where `t` is `c` itself). -/
def sameHighway (c t : String) : Formula :=
  .existsRegion (.lit "highway") "h"
    (if c == t then onWay t "h" else .and (onWay t "h") (onWay c "h"))

/-- r6 with r7, without the reachability: `t` is of side right, enters `i`, lies on a highway `c`
    lies on, and is the rightmost lane of its direction. -/
def rightTurnLaneOn (c t i : String) : Formula :=
  .and (rightSide t)
    (.and (enters t i)
      (.and (sameHighway c t) (rightmost t)))

/-- r6 with r7: `t` is a right turn lane of the highway of carrier `c` for intersection `i`:
    `rightTurnLaneOn`, and `c` or reached from `c` through right-neighbour links. -/
def rightTurnLaneFor (c t i : String) : Formula :=
  .and (rightTurnLaneOn c t i) (reach reachSteps c t)

/-- r6: x occupies a carrier entering `i`, and the highway has a right turn lane for it. -/
def hasRightTurnLane (i : String) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (occ "c")
      (.and (enters "c" i)
        (.existsRegion (.lit "turn_lane") "t" (rightTurnLaneFor "c" "t" i))))

/-- r3: x enters intersection `i` here. -/
def entry (i : String) : Formula := .rises (occ i)

/-- ψ at the observation before x's entry into `i`; exact wherever `entry i` holds. -/
def prevAtEntry (i : String) (ψ : Formula) : Formula := .not (.rises (.or (occ i) ψ))

/-- The selection of the intersection: x enters it, intending to turn right there, and at the
    observation before the entry the highway has a right turn lane for x's approach. -/
def selected (i : String) : Formula :=
  .and (entry i)
    (.and (.intent "int.turn_right" vX (.var i))
      (prevAtEntry i (hasRightTurnLane i)))

/-- r5: x occupies such a right turn lane, and every carrier x occupies that enters `i` is a
    turn lane of side right. -/
def fromRightTurnLane (i : String) : Formula :=
  .and
    (.existsRegion (.lit "turn_lane") "t" (.and (occ "t") (rightTurnLaneOn "t" "t" i)))
    (.forallRegion (.lit "travel_region") "c"
      (.implies (.and (occ "c") (enters "c" i))
        (.and (.atom "st_turn_lane" [.var "c"] []) (rightSide "c"))))

/-- Applicability: r2 (trigger): intends to turn; r3 (trigger): at an intersection; r4 (trigger): and: The turn is a right turn,; r6 (condition): if the highway has a right turn lane -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (selected "i")

/-- Obligation: r5 (obligation): both the approach for the right turn and the right turn must be made from the right turn lane -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (selected "i") (prevAtEntry "i" (fromRightTurnLane "i")))

def rule : Rule :=
  { id := "NRS_484B_400_1_o1"
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

end TrafficSpec.Rules.NRS_484B_400_1_o1
