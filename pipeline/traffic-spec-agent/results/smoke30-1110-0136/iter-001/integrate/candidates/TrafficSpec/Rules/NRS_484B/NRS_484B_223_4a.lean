/-
  NRS_484B_223_4a — NRS-484B-223-4a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): If a highway has been designed to provide a single right lane to be used only for turning
    s2 (subject): a vehicle
    s3 (obligation): must: Be driven in the right turn lane only
    s4 (exception): for the purpose of making a right turn

  Elements (span → atoms, derived):
    s1: atoms ['st.turn_lane', 'st.lane_adjacency', 'st.highway', 'st.on_way', 'rel.occupies'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.turn_lane', 'rel.occupies', 'st.lane_enters', 'st.intersection'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_4a

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s2: `ru_aggregate x DEF-NRS-484A-320::vehicle`, the admitted aggregate claimed whole.
    s1: a highway h that x occupies, and on it (st_on_way) a turn lane L of side right that is
        single: rightmost of its direction (st_lane_adjacency ordinal = count) and whose left
        neighbour of the same direction (st_lane_adjacency "left") is no right turn lane.
        `singleRightTurnLane h L` is that whole selection; the applicability asks that some such
        L exists on a highway x occupies.
    s3/s4: for every highway h x occupies and every lane L of that same whole selection that x
        occupies, x intends a right turn (int.turn_right, at the judged observation) at the
        intersection L enters (st_lane_enters, st_intersection). Where the source records no
        intersection L enters, the purpose's target is unobserved: `definedWhen` on the existence
        of the entrance makes the verdict unknown, never violated.
  No choice beyond the record's: no narrowing is declared.
-/

def vH : Arg := .var "h"
def vL : Arg := .var "L"
def vM : Arg := .var "M"
def vI : Arg := .var "i"

/-- s1: L is a right turn lane on highway h, rightmost of its direction, whose left neighbour of
    the same direction is not itself a right turn lane. -/
def singleRightTurnLane : Formula :=
  .and (.atom "st_turn_lane_side" [vL, .lit "right"] [])
    (.and (.atom "st_on_way" [vL, vH] [])
      (.and (.cmp (.measure "st_lane_adjacency_ordinal" [vL]) .eq
                  (.measure "st_lane_adjacency_count" [vL]))
        (.not (.existsRegion (.lit "turn_lane") "M"
          (.and (.atom "st_lane_adjacency" [vL, .lit "left", vM] [])
                (.atom "st_turn_lane_side" [vM, .lit "right"] []))))))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s1 (condition): If a highway has been designed to provide a single right lane to be used only for turning; s4 (exception): for the purpose of making a right turn -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vX, vH] [])
      (.existsRegion (.lit "turn_lane") "L" singleRightTurnLane))

/-- s3/s4: some intersection L enters, at which x intends a right turn. -/
def entersIntersection : Formula :=
  .existsRegion (.lit "intersection") "i" (.atom "st_lane_enters" [vL, vI] [])

def turnsRightThere : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (.atom "st_lane_enters" [vL, vI] []) (.intent "int.turn_right" vX vI))

/-- Obligation: s3 (obligation): must: Be driven in the right turn lane only -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (.atom "rel_occupies" [vX, vH] [])
      (.forallRegion (.lit "turn_lane") "L"
        (.implies (.and singleRightTurnLane (.atom "rel_occupies" [vX, vL] []))
          (.definedWhen entersIntersection turnsRightThere))))

def rule : Rule :=
  { id := "NRS_484B_223_4a"
    laws := ["NRS-484B-223-4a"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.turn_right"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_4a
