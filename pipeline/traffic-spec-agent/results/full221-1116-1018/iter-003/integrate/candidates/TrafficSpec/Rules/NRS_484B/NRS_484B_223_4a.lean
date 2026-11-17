/-
  NRS_484B_223_4a — NRS-484B-223-4a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): If a highway has been designed to provide a single right lane to be used only for turning,
    s2 (subject): a vehicle must:
    s3 (obligation): Be driven in the right turn lane
    s4 (exception): only for the purpose of making a right turn.

  Elements (span → atoms, derived):
    s1: atoms ['st.turn_lane', 'rel.occupies'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['rel.occupies', 'st.turn_lane', 'st.intersection', 'st.lane_enters', 'st.driveway_or_alley_entrance', 'st.on_way', 'st.highway'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_4a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s2: the subject's class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s1: some region of kind `turn_lane` (st.turn_lane) whose side is `right` (`st_turn_lane_side`,
        the attribute of st.turn_lane) is occupied by the subject (`rel_occupies`). "Designed to
        provide" is the record's observable reading (the lane's presence on the road).
    s3 + s4: for every turn lane t of side right the subject occupies (s1's whole selection
        restated, since the applicability's region is not in scope in the obligation), the
        declared intention `int.right_turn` of the subject, read at the judged observation, is
        true at some region the right turn the lane serves is tied to:
          · an `intersection` r that t enters (`st_lane_enters t r`), or
          · a `driveway_or_alley_entrance` r lying on a `highway` h on which t lies
            (`st_on_way t h`, `st_on_way r h`).
        Declared false at every such region, or no such region existing, makes the existential
        false and the presence violated; undeclared at one and false at the others leaves it
        unknown (three-valued `or`/`exists`).
  Anchoring: t by `rel_occupies subject t`; the intersection by `st_lane_enters t r`; the highway
  by `st_on_way t h`; the driveway entrance by `st_on_way r h`.
  No choice beyond the record's was made: no narrowing is declared.
-/

def vTurn : Arg := .var "t"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the subject occupies the turn lane `t`, a turn lane of side right. -/
def inRightTurnLane : Formula :=
  .and (.atom "rel_occupies" [vSubject, vTurn] [])
       (.atom "st_turn_lane_side" [vTurn, .lit "right"] [])

/-- Applicability: s1 (condition): If a highway has been designed to provide a single right lane to be used only for turning,; s4 (exception): only for the purpose of making a right turn. -/
def applicability : Formula :=
  .existsRegion (.lit "turn_lane") "t" inRightTurnLane

/-- s3/s4: the right turn at the intersection the lane enters. -/
def turnAtEnteredIntersection : Formula :=
  .existsRegion (.lit "intersection") "x"
    (.and (.atom "st_lane_enters" [vTurn, .var "x"] [])
          (.intent "int.right_turn" vSubject (.var "x")))

/-- s3/s4: the right turn into a driveway or alley entrance lying on the lane's highway. -/
def turnAtDrivewayOnWay : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [vTurn, .var "h"] [])
          (.existsRegion (.lit "driveway_or_alley_entrance") "e"
            (.and (.atom "st_on_way" [.var "e", .var "h"] [])
                  (.intent "int.right_turn" vSubject (.var "e")))))

/-- Obligation: s3 (obligation): Be driven in the right turn lane -/
def obligation : Formula :=
  .forallRegion (.lit "turn_lane") "t"
    (.implies inRightTurnLane
      (.or turnAtEnteredIntersection turnAtDrivewayOnWay))

def rule : Rule :=
  { id := "NRS_484B_223_4a"
    laws := ["NRS-484B-223-4a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.right_turn"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_4a
