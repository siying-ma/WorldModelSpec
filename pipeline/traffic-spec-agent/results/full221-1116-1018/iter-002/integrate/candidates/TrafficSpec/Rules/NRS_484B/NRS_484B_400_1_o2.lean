/-
  NRS_484B_400_1_o2 — NRS-484B-400-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): If the driver of a vehicle
    s2 (trigger): intends to turn
    s3 (trigger): at an intersection and:
    s4 (condition): The turn is a right turn,
    s5 (sibling): both the approach for the right turn and the right turn must be made from the right turn lane
    s6 (condition): if the highway has a right turn lane
    s7 (reference): as set forth in subsection 4 of NRS 484B.223 [NRS-484B-223-4a, NRS-484B-223-4b],
    s8 (obligation): or must be made from the extreme right lane.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.intersection', 'rel.occupies', 'st.lane_enters', 'st.lane', 'st.roadway'], derived []
    s6: atoms ['st.turn_lane', 'st.lane_enters', 'st.lane_direction', 'st.lane'], derived [], borrowing ['s7']
    s8: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency', 'st.lane_enters', 'st.roadway'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    s7: NRS-484B-223-4a: If a highway has been designed to provide a single right lane to be used only for turning
    s7: NRS-484B-223-4b: If a highway has been designed to provide a single right lane to be used only for turning

  How each span is written.
    s1: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s3: an intersection `i` (region quantifier of kind `intersection`) whose entry is judged:
        `rises (rel_occupies subject i)` — the footprint overlaps i here and did not at the
        observation before. "At the observation before e, X" is written
        `rises (rel_occupies subject i ∨ ¬X)`: conjoined with the entry (occupancy of i true here,
        false before) it is exactly X at the observation before; X at e is never read (the
        disjunction is settled by the occupancy at e). The approach is a carrier `c` the subject
        occupies at that observation with `st_lane_enters c i`: a region of kind `lane` (turn lanes
        included, as the kind refines lane) or of kind `roadway` recorded as a directed approach
        segment.
    s2/s4: `intent int.right_turn subject i`, read at the observation before e, inside the same
        `rises` form (never ahead of the judged observation).
    s6 (+ s7): "the highway has a right turn lane as set forth": exactly one region of kind
        `turn_lane` with `st_turn_lane_side … right`, entering i, whose designated direction makes
        with c's a cosine at or above p.approach_lane_same_direction_cos. The cosine is the dot
        product of the two `st_lane_direction` vectors, read normalised (contract). "Exactly one"
        is `∃ t (R t ∧ ∀ u (R u → same t u))`. The applicability requires its negation for the
        carrier c the subject occupies.
    s8: at the observation before e, the subject occupies a lane c entering i whose
        `st_lane_adjacency` ordinal equals its count; or it occupies no lane entering i and occupies
        a roadway directed approach segment entering i. The obligation restates the applicability's
        whole selection of i (entry, declared intention, carrier, no single right turn lane) and
        requires the duty at every selected intersection.
  No choice beyond the record's own was needed: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables: the intersection entered, the approach carrier, two turn lanes. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vT : Arg := .var "t"
def vU : Arg := .var "u"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pApproachLaneSameDirectionCos : Term := .param "p.approach_lane_same_direction_cos"

def zeroMetres : Term := .lit Q.zero .metre

/-- rel.occupies: the road user's footprint overlaps the region. -/
def occ (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- st.lane_enters: carrier `c` is an approach to intersection `i`. -/
def enters (c i : Arg) : Formula := .atom "st_lane_enters" [c, i] []

/-- A component of a carrier's designated direction (st.lane_direction, read normalised). -/
def dirComp (r : Arg) (k : String) : Term := .measure "st_lane_direction" [r, .lit k]

/-- The cosine between the designated directions of two carriers. -/
def cosDirs (a b : Arg) : Term :=
  .add (.mul (dirComp a "x") (dirComp b "x")) (.mul (dirComp a "y") (dirComp b "y"))

/-- s6/s7: `t` is a right turn lane entering i carrying traffic the way of carrier `c`. -/
def rightTurnLaneOf (t c : Arg) : Formula :=
  .and (.atom "st_turn_lane_side" [t, .lit "right"] [])
    (.and (enters t vI) (.cmp (cosDirs t c) .ge pApproachLaneSameDirectionCos))

/-- s6/s7: the highway has a single right turn lane on the approach through `c`: exactly one. -/
def singleRightTurnLane (c : Arg) : Formula :=
  .existsRegion (.lit "turn_lane") "t"
    (.and (rightTurnLaneOf vT c)
      (.forallRegion (.lit "turn_lane") "u" (.implies (rightTurnLaneOf vU c) (.same vT vU))))

/-- s3/s6: the subject occupies carrier `c`, an approach to i, and the highway has no single right
    turn lane there. -/
def approachWithoutRightTurnLane (c : Arg) : Formula :=
  .and (occ vSubject c) (.and (enters c vI) (.not (singleRightTurnLane c)))

/-- What holds at the observation before the entry: s2/s4 the declared right turn at i; s3/s6 the
    approach carrier (a lane or a roadway directed approach segment) without a right turn lane. -/
def beforeEntry : Formula :=
  .and (.intent "int.right_turn" vSubject vI)
    (.or (.existsRegion (.lit "lane") "c" (approachWithoutRightTurnLane vC))
         (.existsRegion (.lit "roadway") "c" (approachWithoutRightTurnLane vC)))

/-- s3: the subject enters i here (overlaps it here, not at the observation before). -/
def entry : Formula := .rises (occ vSubject vI)

/-- φ at the observation before the entry into i (read together with `entry`). -/
def atObservationBeforeEntry (φ : Formula) : Formula :=
  .rises (.or (occ vSubject vI) (.not φ))

/-- The selection of the intersection i the rule judges. -/
def selection : Formula := .and entry (atObservationBeforeEntry beforeEntry)

/-- The subject occupies carrier `c`, an approach to i. -/
def onApproach (c : Arg) : Formula := .and (occ vSubject c) (enters c vI)

/-- s8: the subject occupies the extreme right lane of its approach. -/
def extremeRightLane : Formula :=
  .or
    (.existsRegion (.lit "lane") "c"
      (.and (onApproach vC)
        (.cmp (.measure "st_lane_adjacency" [vC, .lit "ordinal"]) .eq
              (.measure "st_lane_adjacency" [vC, .lit "count"]))))
    (.and (.not (.existsRegion (.lit "lane") "c" (onApproach vC)))
          (.existsRegion (.lit "roadway") "c" (onApproach vC)))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s2 (trigger): intends to turn; s3 (trigger): at an intersection and:; s4 (condition): The turn is a right turn,; s6 (condition): if the highway has a right turn lane -/
def applicability : Formula := .existsRegion (.lit "intersection") "i" selection

/-- Obligation: s8 (obligation): or must be made from the extreme right lane. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies selection (atObservationBeforeEntry extremeRightLane))

def rule : Rule :=
  { id := "NRS_484B_400_1_o2"
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

end TrafficSpec.Rules.NRS_484B_400_1_o2
