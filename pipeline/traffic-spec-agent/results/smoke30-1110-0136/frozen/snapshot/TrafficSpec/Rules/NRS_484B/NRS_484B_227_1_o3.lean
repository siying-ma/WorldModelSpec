/-
  NRS_484B_227_1_o3 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every vehicle
    s2 (trigger): driven upon a divided highway
    s3 (sibling): must be driven only upon the right-hand roadway
    s4 (sibling): and must not be driven over, across or within any dividing space, barrier or section
    s5 (obligation): or make any left turn, semicircular turn or U-turn
    s6 (exception): except through an opening in the barrier or dividing section or space
    s7 (exception): or at a crossover or intersection established by a public authority

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.highway', 'st.median_or_divider', 'st.on_way', 'rel.occupies'], derived []
    s5: atoms [], derived ['drv.motion.left_turn', 'drv.motion.u_turn']
    s6: atoms ['st.median_or_divider', 'rel.occupies'], derived []
    s7: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies'], derived []

  How each is written:
    s1: `ru_aggregate(x, DEF-NRS-484A-320::vehicle)` as the class of `x`.
    s2: `onDivided` — some highway region `h` that `x` occupies, on which some median or divider
        region lies (`st_on_way(m, h)`). Read at the observation, or at some moment of the turn
        under way: `.not (.holdsFor .time W x (.not (.and underWay onDivided)))`, with `W` the
        occasion's window and `underWay` = drv.motion.turning(x; p.yaw_rate_tolerance).
    s5: the act is `drv.motion.left_turn` (window, left_turn_min_angle, reversal_min_angle) or
        `drv.motion.u_turn` (window, reversal_min_angle, reversal_max_angle); each is judged where
        it rises (its recognition). At observations where neither rises the duty is met.
    s6: `throughOpening` — some median or divider region `o` that `x` occupies whose opening
        attribute holds.
    s7: the crossover is the same opening (s6's formula); the intersection is some
        `st.intersection` region `i` that `x` occupies.
    s6/s7 are read at some moment of the turn under way, together with the turning formula:
        `.not (.holdsFor .time W x (.not (.and underWay (throughOpening ∨ atIntersection))))`.

  No choice beyond the record's was needed: no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pLeftTurnMinAngle : Term := .param "p.left_turn_min_angle"
def pReversalMaxAngle : Term := .param "p.reversal_max_angle"
def pReversalMinAngle : Term := .param "p.reversal_min_angle"
def pTurnRecognitionWindow : Term := .param "p.turn_recognition_window"
def pYawRateTolerance : Term := .param "p.yaw_rate_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The occasion's under-way element: x's heading is changing (drv.motion.turning). -/
def underWay : Formula := .derived "drv_motion_turning" [vX] [pYawRateTolerance]

/-- `some_moment` of the occasion: at some observation of the window behind at which the turn
    was under way, φ held. -/
def someMoment (φ : Formula) : Formula :=
  .not (.holdsFor .time pTurnRecognitionWindow "x" (.not (.and underWay φ)))

/-- s2: x occupies a highway on which a median or divider lies (a divided highway). -/
def onDivided : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vX, .var "h"] [])
      (.existsRegion (.lit "median_or_divider") "m" (.atom "st_on_way" [.var "m", .var "h"] [])))

/-- s6 (and s7's crossover): x's footprint overlaps a median or divider region whose opening
    attribute holds. -/
def throughOpening : Formula :=
  .existsRegion (.lit "median_or_divider") "o"
    (.and (.atom "rel_occupies" [vX, .var "o"] []) (.atom "st_median_or_divider_opening" [.var "o"] []))

/-- s7: x's footprint overlaps an intersection region. -/
def atIntersection : Formula :=
  .existsRegion (.lit "intersection") "i" (.atom "rel_occupies" [vX, .var "i"] [])

/-- s5: the acts. -/
def leftTurn : Formula :=
  .derived "drv_motion_left_turn" [vX] [pTurnRecognitionWindow, pLeftTurnMinAngle, pReversalMinAngle]
def uTurn : Formula :=
  .derived "drv_motion_u_turn" [vX] [pTurnRecognitionWindow, pReversalMinAngle, pReversalMaxAngle]

/-- Applicability: s2 (trigger): driven upon a divided highway, at the observation or at some
    moment of the turn under way. -/
def applicability : Formula :=
  .or onDivided (someMoment onDivided)

/-- Obligation: s5 (obligation): or make any left turn, semicircular turn or U-turn; s6/s7
    (exceptions) at some moment of the turn under way. -/
def obligation : Formula :=
  .implies (.or (.rises leftTurn) (.rises uTurn))
    (someMoment (.or throughOpening atIntersection))

def rule : Rule :=
  { id := "NRS_484B_227_1_o3"
    laws := ["NRS-484B-227-1"]
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

end TrafficSpec.Rules.NRS_484B_227_1_o3
