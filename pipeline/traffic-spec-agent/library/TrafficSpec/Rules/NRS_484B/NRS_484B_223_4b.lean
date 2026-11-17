/-
  NRS_484B_223_4b — NRS-484B-223-4b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): If a highway has been designed to provide a single right lane to be used only for turning,
    s2 (subject): a vehicle must:
    s3 (condition): While being driven in the right turn lane,
    s4 (obligation): not travel through an intersection.

  Elements (span → atoms, derived):
    s1: atoms ['rel.occupies', 'st.turn_lane'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['rel.occupies', 'st.turn_lane', 'st.lane_enters', 'st.intersection'], derived []
    s4: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.right_turn_through_region']

  How each span is written.
    The occasion is the act drv.motion.right_turn_through_region through an intersection X
    (`existsRegion "intersection" x`, st.intersection), an event act:
      onset        `entryX` = `rises (rel_occupies subject x)` — the footprint comes to overlap X;
      recognition  `exitX`  = `rises (not (rel_occupies subject x))` — the footprint no longer
                   overlaps X, having overlapped it at the previous observation.
    s1 (at_recognition): at the exit, a region l of kind turn_lane (`existsRegion "turn_lane" l`,
      st.turn_lane) whose side is right (`st_turn_lane_side l right`) and which enters X
      (`st_lane_enters l x`, s3's entry topology, the same lane bound for s3).
    s3 (some_moment over the act stretch): `since (not entryX) (rel_occupies subject l)` — the
      footprint overlapped l at some observation from the latest entry into X (included) up to
      the exit: any overlap before that entry is cut off by the entry itself, so the stretch is
      exactly [onset, recognition] of this occurrence.
    s2: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`, the binder's class.
    s4: at that exit, the act is recognized, `rises (drv_motion_right_turn_through_region subject x)`
      with step p.heading_since_step_carla_scene_graph, turn_min p.turn_heading_min and u_turn_min
      p.u_turn_heading_min (the concept holds at the exit only, so its rise is its recognition).
      The obligation repeats the whole selection of X (exit, right turn lane entering X occupied
      during the passage) and binds it for every intersection so selected (`forallRegion`).
  Choices the text left open: none beyond the record; no narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_4b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The intersection passed through, and the right turn lane entering it. -/
def vX : Arg := .var "x"
def vL : Arg := .var "l"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The subject's footprint overlaps X (rel.occupies). -/
def occupiesX : Formula := .atom "rel_occupies" [vSubject, vX] []

/-- Onset: the entry into X. -/
def entryX : Formula := .rises occupiesX

/-- Recognition: the exit from X. -/
def exitX : Formula := .rises (.not occupiesX)

/-- s1 / s3: l is a turn lane of side right that enters X. -/
def rightTurnLaneIntoX : Formula :=
  .and (.atom "st_turn_lane_side" [vL, .lit "right"] []) (.atom "st_lane_enters" [vL, vX] [])

/-- s3 (some_moment): the footprint overlapped l at some observation from the latest entry into X
    up to now. -/
def drivenInLaneDuringPassage : Formula :=
  .since (.not entryX) (.atom "rel_occupies" [vSubject, vL] [])

/-- The whole selection of X at the observation judged: the exit from X of a passage made while
    being driven in a right turn lane entering X. -/
def selection : Formula :=
  .and exitX
    (.existsRegion (.lit "turn_lane") "l" (.and rightTurnLaneIntoX drivenInLaneDuringPassage))

/-- s4: the passage through X was a turn to the right, recognized at the exit. -/
def rightTurnThroughX : Formula :=
  .rises (.derived "drv_motion_right_turn_through_region" [vSubject, vX]
    [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin])

/-- Applicability: s1 (trigger): If a highway has been designed to provide a single right lane to be used only for turning,; s3 (condition): While being driven in the right turn lane, -/
def applicability : Formula := .existsRegion (.lit "intersection") "x" selection

/-- Obligation: s4 (obligation): not travel through an intersection. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "x" (.implies selection rightTurnThroughX)

def rule : Rule :=
  { id := "NRS_484B_223_4b"
    laws := ["NRS-484B-223-4b"]
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

end TrafficSpec.Rules.NRS_484B_223_4b
