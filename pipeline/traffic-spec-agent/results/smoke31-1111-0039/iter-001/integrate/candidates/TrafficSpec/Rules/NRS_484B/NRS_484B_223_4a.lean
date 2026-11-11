/-
  NRS_484B_223_4a — NRS-484B-223-4a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (condition): If a highway has been designed to provide
    d2 (condition): a single right lane to be used only for turning
    d3 (subject): a vehicle must
    d4 (obligation): Be driven in the right turn lane only for the purpose of making a right turn

  Elements (span → atoms, derived):
    d1: atoms ['st.highway', 'st.on_way'], derived []
    d2: atoms ['st.turn_lane', 'st.lane', 'st.lane_adjacency'], derived []
    d3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d4: atoms ['st.turn_lane', 'st.lane', 'st.lane_adjacency', 'st.intersection', 'st.lane_enters', 'rel.occupies', 'kin.yaw_rate'], derived ['drv.motion.heading_change_since_entry']

  How each span is written:
    d3: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`, the binder's class.
    d1, d2: the selection `singleRightTurnLane L` — L an `st.turn_lane` region of side right
      (`st_turn_lane_side`), lying on (`st_on_way`) some `st.highway` region, with no
      `st.turn_lane` region of side right that is L's left or right neighbour
      (`st_lane_adjacency`, sides "left" and "right"), and x occupying L at the observation or at
      an earlier one (`since tt (rel_occupies x L)`, which is "here" included). The applicability
      asks that some region be so selected.
    d4: the obligation re-states the whole selection of L for every region it selects, and for
      every `st.intersection` region I that L enters (`st_lane_enters`) forbids
      (a) x stopping here occupying L (`rises (not (rel_occupies x L))`) while occupying the lane
          (`st.lane`, which turn lanes refine) that is L's left neighbour (`st_lane_adjacency`
          "left") and not occupying I;
      (b) x stopping here occupying I (`rises (not (rel_occupies x I))`), having begun to overlap I
          at an observation at which it occupied L (`since tt (rises (rel_occupies x I) and
          rel_occupies x L)`), with `drv.motion.heading_change_since_entry(x, I)` (step
          p.heading_since_step_carla_scene_graph; it reads kin.yaw_rate) greater than minus
          p.turn_recognition_angle.
  No choice beyond the record's was needed: every reading above is the record's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_4a

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

def vL : Arg := .var "L"
def vI : Arg := .var "I"

def occupies (r : Arg) : Formula := .atom "rel_occupies" [vX, r] []

/-- d1, d2: L is a single right turn lane on a highway, which x occupies here or occupied earlier. -/
def singleRightTurnLane : Formula :=
  .and (.atom "st_turn_lane_side" [vL, .lit "right"] [])
    (.and (.existsRegion (.lit "highway") "H" (.atom "st_on_way" [vL, .var "H"] []))
      (.and (.not (.existsRegion (.lit "turn_lane") "N"
          (.and (.atom "st_turn_lane_side" [.var "N", .lit "right"] [])
            (.or (.atom "st_lane_adjacency" [vL, .lit "left", .var "N"] [])
              (.atom "st_lane_adjacency" [vL, .lit "right", .var "N"] [])))))
        (.since .tt (occupies vL))))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: d1 (condition): If a highway has been designed to provide; d2 (condition): a single right lane to be used only for turning -/
def applicability : Formula := .existsRegion (.lit "turn_lane") "L" singleRightTurnLane

/-- (a) x leaves L here into the lane on L's left, short of the intersection I. -/
def backToTheLeft : Formula :=
  .and (.rises (.not (occupies vL)))
    (.and (.existsRegion (.lit "lane") "M"
        (.and (.atom "st_lane_adjacency" [vL, .lit "left", .var "M"] []) (occupies (.var "M"))))
      (.not (occupies vI)))

/-- (b) x leaves I here, entered from L, with no right turn since that entry. -/
def leftWithoutTurningRight : Formula :=
  .and (.rises (.not (occupies vI)))
    (.and (.since .tt (.and (.rises (occupies vI)) (occupies vL)))
      (.cmp (.quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph])
        .gt (.neg pTurnRecognitionAngle)))

/-- Obligation: d4 (obligation): Be driven in the right turn lane only for the purpose of making a right turn -/
def obligation : Formula :=
  .forallRegion (.lit "turn_lane") "L"
    (.implies singleRightTurnLane
      (.forallRegion (.lit "intersection") "I"
        (.implies (.atom "st_lane_enters" [vL, vI] [])
          (.and (.not backToTheLeft) (.not leftWithoutTurningRight)))))

def rule : Rule :=
  { id := "NRS_484B_223_4a"
    laws := ["NRS-484B-223-4a"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_4a
