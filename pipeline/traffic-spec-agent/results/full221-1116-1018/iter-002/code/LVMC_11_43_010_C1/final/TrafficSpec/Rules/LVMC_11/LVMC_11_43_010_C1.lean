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

  How each span is written:
    s2/s3: the class of `subject` is the admitted aggregate, `ru_aggregate subject
      "DEF-NRS-484A-320::vehicle"`; "within a roundabout" is a region `r` of kind `roundabout`
      (`existsRegion`), tied to the subject by `rel_occupies` (in the obligation) and by the turn
      concepts, whose entry and exit are the subject's footprint overlap with `r`.
    s4 (at_recognition): the exit is the recognition of the act: the turn concepts hold at the
      observation at which the subject leaves `r`; the act `turnThrough r` is the disjunction
      left turn ∨ U-turn through `r`, judged once at its recognition with `.rises`.
    s5: "turn left or complete a U-turn" is the same act re-bound in the obligation (the whole
      selection of `r` written again: kind roundabout, and the act recognized through it now).
      "use the left lane" is
        since(φ, rises(occupies(subject, r)) ∧ φ),
        φ = occupies(subject, r) → ∀ lane l, occupies(subject, l) → ordinal(l) = 1,
      the act stretch from the onset (the latest rise of the subject's overlap with r, the onset
      the concepts declare) to the recognition being judged; at the recognition itself the subject
      no longer overlaps r, so φ is vacuous there. The ordinal 1 is the atom's own contract's
      "ordinal 1 is the leftmost lane", the count literal 1.

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

/-- The leftmost lane's ordinal: st.lane_adjacency's contract, "ordinal 1 is the leftmost lane".
    The node's obligation states `ordinal(l) = 1` but declares no literal for it (the gate returns
    BARE_LITERAL): the plan must declare this literal on s5; see task_result.md. -/
def leftmostOrdinal : Term := .lit (Units.ratio 1 1) .count

def vR : Arg := .var "r"
def vL : Arg := .var "l"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The act through roundabout `r`: a left turn or a U-turn, each holding at the exit from `r` only. -/
def turnThrough : Formula :=
  .or (.derived "drv_motion_left_turn_through_region" [vSubject, vR]
          [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin])
      (.derived "drv_motion_u_turn_through_region" [vSubject, vR]
          [pHeadingSinceStepCarlaSceneGraph, pUTurnHeadingMin])

/-- Recognition of the act (s4, at_recognition): the exit from `r` having so turned. -/
def recognized : Formula := .rises turnThrough

/-- Onset of the act: the subject's footprint came to overlap `r`. -/
def inR : Formula := .atom "rel_occupies" [vSubject, vR] []
def onset : Formula := .rises inR

/-- Within `r`, every lane the subject's footprint overlaps is the lane of ordinal 1. -/
def leftLaneOnly : Formula :=
  .implies inR
    (.forallRegion (.lit "lane") "l"
      (.implies (.atom "rel_occupies" [vSubject, vL] [])
        (.cmp (.measure "st_lane_adjacency_ordinal" [vL]) .eq leftmostOrdinal)))

/-- Applicability: s4 (condition): who intends to exit a roundabout -/
def applicability : Formula :=
  .existsRegion (.lit "roundabout") "r" recognized

/-- Obligation: s5 (obligation): Shall use the left lane to turn left or complete a U-turn -/
def obligation : Formula :=
  .existsRegion (.lit "roundabout") "r"
    (.and recognized (.since leftLaneOnly (.and onset leftLaneOnly)))

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
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_43_010_C1
