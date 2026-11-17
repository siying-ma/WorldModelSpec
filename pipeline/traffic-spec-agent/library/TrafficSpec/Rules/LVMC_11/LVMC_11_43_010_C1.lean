/-
  LVMC_11_43_010_C1 — LVMC-11-43-010-C1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (boilerplate): The following regulations pertain to
    s2 (subject): the operation of vehicles within a roundabout
    s3 (subject): The operator of a vehicle
    s4 (condition): who intends to exit a roundabout
    s5 (obligation): Shall use the left lane to turn left or complete a U-turn

  Elements (span → atoms, derived):
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.roundabout'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['rel.occupies', 'st.roundabout'], derived ['drv.motion.left_turn_through_region', 'drv.motion.u_turn_through_region']
    s5: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency'], derived ['drv.motion.left_turn_through_region', 'drv.motion.u_turn_through_region']

  Literals the text states (each written through its Units constructor):
    s5: 1 count — the left lane

  How each span is written:
    s2/s3: the subject's class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`; "within a
      roundabout" is a region r of kind `roundabout` (st.roundabout), tied to the subject by
      rel.occupies (inside the turn concepts and the onset `rises (rel_occupies subject r)`).
    s4 (occasion recognition, at_recognition): the exit is the observation at which
      `drv_motion_left_turn_through_region(subject, r)` or `drv_motion_u_turn_through_region(subject, r)`
      rises (the concepts hold at the exit only); the applicability is `∃ roundabout r, rises(LT ∨ UT)`.
    s5 (obligation, event act read throughout from onset to recognition): the obligation re-binds
      the same roundabout by the same selection (`∃ roundabout r, rises(LT ∨ UT) ∧ …`) and reads,
      with `since`, every observation from the entry (`rises (rel_occupies subject r)`, the onset
      the concepts declare) to the judged exit: where the subject occupies r, every lane l
      (st.lane) the subject occupies has `st_lane_adjacency_ordinal l = 1` (the declared count
      literal of s5, "the left lane").
  No choice beyond the record: the record states the since-formula; no narrowing is added.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_43_010_C1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- s5: "the left lane", the declared count literal 1 (ordinal 1 is the leftmost lane). -/
def leftLaneOrdinal : Term := .lit (Units.ratio 1 1) .count

def vR : Arg := .var "r"
def vL : Arg := .var "l"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s4/s5: the subject has turned left through roundabout r, recognized as it leaves r. -/
def leftTurn : Formula :=
  .derived "drv_motion_left_turn_through_region" [vSubject, vR]
    [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]

/-- s4/s5: the subject has completed a U-turn through roundabout r, recognized as it leaves r. -/
def uTurn : Formula :=
  .derived "drv_motion_u_turn_through_region" [vSubject, vR]
    [pHeadingSinceStepCarlaSceneGraph, pUTurnHeadingMin]

/-- s4: the exit (recognition of the act): the left turn or the U-turn through r rises. -/
def exitTurning : Formula := .rises (.or leftTurn uTurn)

/-- s2: the subject's footprint overlaps the roundabout r. -/
def inR : Formula := .atom "rel_occupies" [vSubject, vR] []

/-- s5: within r, every lane the subject occupies is the lane of ordinal 1. -/
def leftLaneOnly : Formula :=
  .implies inR
    (.forallRegion (.lit "lane") "l"
      (.implies (.atom "rel_occupies" [vSubject, vL] [])
        (.cmp (.measure "st_lane_adjacency_ordinal" [vL]) .eq leftLaneOrdinal)))

/-- Applicability: s4 (condition): who intends to exit a roundabout -/
def applicability : Formula :=
  .existsRegion (.lit "roundabout") "r" exitTurning

/-- Obligation: s5 (obligation): Shall use the left lane to turn left or complete a U-turn -/
def obligation : Formula :=
  .existsRegion (.lit "roundabout") "r"
    (.and exitTurning
      (.since leftLaneOnly (.and (.rises inR) leftLaneOnly)))

def rule : Rule :=
  { id := "LVMC_11_43_010_C1"
    laws := ["LVMC-11-43-010-C1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_43_010_C1
