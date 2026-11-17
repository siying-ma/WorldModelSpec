/-
  LVMC_11_43_010_C2 — LVMC-11-43-010-C2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (boilerplate): The following regulations pertain to
    s2 (subject): the operation of vehicles within a roundabout
    s3 (subject): The operator of a vehicle
    s4 (condition): who intends to exit a roundabout
    s5 (obligation): Shall use the right lane to turn right

  Elements (span → atoms, derived):
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.roundabout'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['rel.occupies', 'st.roundabout'], derived ['drv.motion.right_turn_through_region']
    s5: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency'], derived ['drv.motion.right_turn_through_region']

  How each span is written:
    s2, s3: the binder class `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`; "within a
        roundabout" is the region quantifier over kind `roundabout` (st.roundabout) and the subject's
        `rel_occupies` of it in the obligation (the stretch inside r).
    s4 (condition, at_recognition): some region r of kind `roundabout` for which
        `drv_motion_right_turn_through_region(subject, r)` holds with step
        `p.heading_since_step_carla_scene_graph`, turn_min `p.turn_heading_min`, u_turn_min
        `p.u_turn_heading_min`. The concept holds only at the exit observation, the recognition of
        the act; the intention to exit is the record's observable reading of that exit.
    s5 (obligation, throughout the act): the same roundabout is re-bound with the record's whole
        selection (kind `roundabout` and the concept holding at the judged observation), for every
        such r. φ = "wherever rel_occupies(subject, r), every region l of kind `lane` with
        rel_occupies(subject, l) has st_lane_adjacency_ordinal(l) = st_lane_adjacency_count(l)".
        The act stretch runs from the onset (the rise of rel_occupies(subject, r), the entry the
        concept declares) to the exit: `since (φ ∧ ¬rises(occupies(subject, r)))
        (rises(occupies(subject, r)) ∧ φ)`, the record's `since(φ, rises(occupies) ∧ φ)` with the
        record's own "latest observation at which rel.occupies(subject, r) rose" made explicit in
        the left operand: no rise lies between the entry found and the judged observation, so the
        search into the past ends at the latest entry and nowhere else (it never runs on past the
        entry to the start of the recording, nor reaches an earlier occurrence). An entry before
        the recording, or an occupied lane's unobserved ordinal or count, leaves it unknown.

  No choice beyond the record's: no narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_43_010_C2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- Region variables. -/
def vR : Arg := .var "r"
def vL : Arg := .var "l"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s4: the subject exits roundabout r having turned right through it (recognition of the act). -/
def rightTurnThrough : Formula :=
  .derived "drv_motion_right_turn_through_region" [vSubject, vR]
    [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]

/-- s2: the subject's footprint overlaps roundabout r. -/
def inRoundabout : Formula := .atom "rel_occupies" [vSubject, vR] []

/-- s5: wherever the subject is within r, every lane it occupies is the rightmost of its direction. -/
def rightLaneHere : Formula :=
  .implies inRoundabout
    (.forallRegion (.lit "lane") "l"
      (.implies (.atom "rel_occupies" [vSubject, vL] [])
        (.cmp (.measure "st_lane_adjacency_ordinal" [vL]) .eq
              (.measure "st_lane_adjacency_count" [vL]))))

/-- Applicability: s4 (condition): who intends to exit a roundabout -/
def applicability : Formula :=
  .existsRegion (.lit "roundabout") "r" rightTurnThrough

/-- Obligation: s5 (obligation): Shall use the right lane to turn right -/
def obligation : Formula :=
  .forallRegion (.lit "roundabout") "r"
    (.implies rightTurnThrough
      (.since (.and rightLaneHere (.not (.rises inRoundabout)))
              (.and (.rises inRoundabout) rightLaneHere)))

def rule : Rule :=
  { id := "LVMC_11_43_010_C2"
    laws := ["LVMC-11-43-010-C2"]
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

end TrafficSpec.Rules.LVMC_11_43_010_C2
