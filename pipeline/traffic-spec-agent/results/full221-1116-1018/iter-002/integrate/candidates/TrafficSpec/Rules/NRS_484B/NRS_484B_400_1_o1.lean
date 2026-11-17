/-
  NRS_484B_400_1_o1 — NRS-484B-400-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): If the driver of a vehicle
    s2 (trigger): intends to turn
    s3 (trigger): at an intersection and:
    s4 (condition): The turn is a right turn,
    s5 (obligation): both the approach for the right turn and the right turn must be made from the right turn lane
    s6 (condition): if the highway has a right turn lane
    s7 (reference): as set forth in subsection 4 of NRS 484B.223 [NRS-484B-223-4a, NRS-484B-223-4b],
    s8 (sibling): or must be made from the extreme right lane.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.intersection', 'rel.occupies', 'st.lane_enters', 'st.lane'], derived []
    s5: atoms ['rel.occupies', 'st.turn_lane', 'st.lane_enters', 'st.intersection'], derived []
    s6: atoms ['st.turn_lane', 'st.lane_enters', 'st.lane_direction', 'st.lane'], derived [], borrowing ['s7']

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    s7: NRS-484B-223-4a: If a highway has been designed to provide a single right lane to be used only for turning
    s7: NRS-484B-223-4b: If a highway has been designed to provide a single right lane to be used only for turning

  How each span is written.
    s1: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s3: the judged observation e is the subject's entry into an intersection i: `rises (rel_occupies
        subject i)` over every region i of kind intersection (`st_intersection i` stated). Everything
        the record reads "at the observation before e" is written `prev i X :=
        since (occ i) (¬ occ i ∧ X)`: where `rises (occ i)` holds (occ now, not at the observation
        before), this is exactly X at the observation before (the `since` recursion passes through
        the current observation, where occ holds, and stops at the one before, where it does not).
        The approach carrier c is a region of kind lane (`st_lane c`, turn lanes included by
        refinement) the subject occupies at that observation with `st_lane_enters c i`.
    s2/s4: `intent "int.right_turn" subject i`, read at the observation before e (inside `prev`).
    s6 (with s7): at the observation before e, for an approach carrier c, exactly one region t of
        kind turn_lane with `st_turn_lane_side t right`, `st_lane_enters t i` and the cosine of the
        two designated directions (`st_lane_direction`, x·x + y·y of the normalised vectors) at or
        above p.approach_lane_same_direction_cos; "exactly one" is an existential and a universal
        over turn lanes t2 satisfying the same selection, each `same t2 t`. Inside the universal the
        kind of t2 is the quantifier's (`forallRegion turn_lane`), so `st_turn_lane t2` is not
        restated (it could never change a verdict); side, entrance and direction are.
    s5: the obligation re-selects i with the applicability's whole selection (entry, intention,
        right turn lane condition) for every such i, and requires at the observation before e that
        the subject occupies a turn lane t of side right entering i. The s5 element carries no
        direction atom: a right turn lane entering i that the subject occupies is a carrier of the
        subject's own approach (c := t, its direction aligned with itself), and the applicability
        has already fixed that there is exactly one such lane, so the occupied lane is the record's
        t; this is the record's "where the subject occupies t the duty is met whatever else is
        unobserved".
    s7: definition composition, no call; carried by s6's atoms as above.
    s8: sibling, not this node.

  No choice beyond the record's: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pApproachLaneSameDirectionCos : Term := .param "p.approach_lane_same_direction_cos"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vT : Arg := .var "t"
def vT2 : Arg := .var "t2"

/-- The subject's footprint overlaps region `r` (rel.occupies). -/
def occ (r : Arg) : Formula := .atom "rel_occupies" [vSubject, r] []

/-- Carrier `r` enters intersection `i` (st.lane_enters). -/
def enters (r : Arg) : Formula := .atom "st_lane_enters" [r, vI] []

/-- Formula at the observation before the subject's entry into `i`, read where `rises (occ i)`. -/
def prev (φ : Formula) : Formula := .since (occ vI) (.and (.not (occ vI)) φ)

/-- The subject enters intersection `i` here (s3). -/
def entry : Formula := .and (.atom "st_intersection" [vI] []) (.rises (occ vI))

/-- Of a region already bound as a turn lane: its side is right and it enters `i`. -/
def rightSideEntering (t : Arg) : Formula :=
  .and (.atom "st_turn_lane_side" [t, .lit "right"] []) (enters t)

/-- A turn lane of side right entering `i` (st.turn_lane with its side, st.lane_enters). -/
def rightTurnLaneOf (t : Arg) : Formula :=
  .and (.atom "st_turn_lane" [t] []) (rightSideEntering t)

/-- Cosine between the designated directions of `a` and `b` (st.lane_direction, normalised). -/
def dirCos (a b : Arg) : Term :=
  .add (.mul (.measure "st_lane_direction" [a, .lit "x"]) (.measure "st_lane_direction" [b, .lit "x"]))
       (.mul (.measure "st_lane_direction" [a, .lit "y"]) (.measure "st_lane_direction" [b, .lit "y"]))

/-- The uniqueness test on a region `t2` bound by a quantifier over turn lanes: the kind is the
    quantifier's, so only the side, the entrance and the direction are stated. -/
def otherApproachRightTurnLane (t2 c : Arg) : Formula :=
  .and (rightSideEntering t2) (.cmp (dirCos t2 c) .ge pApproachLaneSameDirectionCos)

/-- `t` is a right turn lane of the approach carried by `c` (s6). -/
def approachRightTurnLane (t c : Arg) : Formula :=
  .and (rightTurnLaneOf t) (.cmp (dirCos t c) .ge pApproachLaneSameDirectionCos)

/-- The subject occupies a lane `c` entering `i` (its approach, s3). -/
def approachCarrier : Formula :=
  .and (.atom "st_lane" [vC] []) (.and (occ vC) (enters vC))

/-- The highway the subject approaches on has a single right turn lane (s6 with s7). -/
def hasRightTurnLane : Formula :=
  .existsRegion (.lit "lane") "c"
    (.and approachCarrier
      (.existsRegion (.lit "turn_lane") "t"
        (.and (approachRightTurnLane vT vC)
          (.forallRegion (.lit "turn_lane") "t2"
            (.implies (otherApproachRightTurnLane vT2 vC) (.same vT2 vT))))))

/-- The whole selection of the intersection `i` (s2, s3, s4, s6). -/
def selection : Formula :=
  .and entry (prev (.and (.intent "int.right_turn" vSubject vI) hasRightTurnLane))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s2 (trigger): intends to turn; s3 (trigger): at an intersection and:; s4 (condition): The turn is a right turn,; s6 (condition): if the highway has a right turn lane -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" selection

/-- Obligation: s5 (obligation): both the approach for the right turn and the right turn must be made from the right turn lane -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies selection
      (prev (.existsRegion (.lit "turn_lane") "t" (.and (rightTurnLaneOf vT) (occ vT)))))

def rule : Rule :=
  { id := "NRS_484B_400_1_o1"
    laws := ["NRS-484B-400-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.right_turn"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_400_1_o1
