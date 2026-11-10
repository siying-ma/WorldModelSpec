/-
  NRS_484B_307_9a_o1 — NRS-484B-307-9a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (trigger): Where the signal is a steady red with a green turn arrow:
    a2 (reference): Except as otherwise provided in paragraph (b) [NRS-484B-307-9b],
    a3 (subject): vehicular traffic
    a4 (condition): facing the signal
    a5 (obligation): may enter the intersection only to make the movement indicated by the green turn arrow,
    a6 (sibling): but must yield the right-of-way to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.
    a7 (definitional): Drivers turning in the direction of the arrow are thereby advised that so long as the turn arrow is illuminated, oncoming or opposing traffic simultaneously faces a steady red signal.

  Elements (span → atoms, derived):
    a1: atoms ['dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    a3: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    a4: atoms ['dev.governs', 'dev.traffic_signal', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    a5: atoms ['rel.occupies', 'st.intersection', 'kin.yaw_rate', 'dev.traffic_signal'], derived ['drv.motion.straight_through_region', 'drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region']

  Compositions (span → node, as, map):
    a2: NRS_484B_307_9b_o1 as exception map {'x': 'x'}
    a2: NRS_484B_307_9b_o2 as exception map {'x': 'x'}
    a2: NRS_484B_307_9b_o3 as exception map {'x': 'x'}
    a2: NRS_484B_307_9b_o4 as exception map {'x': 'x'}

  How each is written.
    a3: the class is `ru_aggregate x traffic`; the applicability adds `not (ru_aggregate x pedestrian)`
        ('vehicular').
    occasion: the act is judged at its recognition, x leaving an intersection i
        (`rises (not (rel_occupies x i))`). The entry is the last rise of x's overlap with i, reached
        from the exit by `since (not (rises occ)) (rises occ ∧ φ)`: φ held at the latest observation
        at which the overlap became true.
    a1/a4: at the entry, a traffic signal s (`existsDevice traffic_signal`) showed circular_red and
        at least one of green_arrow(left), green_arrow(right), green_arrow(u_turn), and governed either
        the intersection itself or a travel region c that enters i (`st_lane_enters c i`) and that x
        occupied at the observation before the entry. "At the observation before" is written with
        `rises` alone: A held at the previous observation exactly when (A ∧ ¬rises A) ∨ rises ¬A.
    a5: for every intersection i and signal s selected as in the applicability (the selection written
        again in the obligation), violated where the crossing recognized at the exit (`rises` of the
        act concept, which holds only at the exit) is a left turn and s showed no green_arrow(left) at
        the entry, a right turn and no green_arrow(right), or a through movement and no
        green_arrow(straight).
    a2: each paragraph (b) node is `not (ruleApplies … [x ↦ x])` in the applicability.

  Choices: none beyond the record's (no narrowing of my own).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9a_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantifier variables: the intersection, the signal, the approach carrier. -/
def vI : Arg := .var "i"
def vS : Arg := .var "s"
def vC : Arg := .var "c"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLeftTurnMinAngle : Term := .param "p.left_turn_min_angle"
def pReversalMinAngle : Term := .param "p.reversal_min_angle"
def pRightTurnMinAngle : Term := .param "p.right_turn_min_angle"
def pStraightThroughMaxHeadingChange : Term := .param "p.straight_through_max_heading_change"

def zeroMetres : Term := .lit Q.zero .metre

/-- `φ` held at the previous observation, read at this one: `(φ ∧ ¬rises φ) ∨ rises ¬φ`. -/
def atPrevious (φ : Formula) : Formula :=
  .or (.and φ (.not (.rises φ))) (.rises (.not φ))

/-- x overlaps the intersection i. -/
def inI : Formula := .atom "rel_occupies" [vX, vI] []

/-- x enters i here: its overlap with i becomes true. -/
def entersI : Formula := .rises inI

/-- x leaves i here: its overlap with i becomes false. -/
def leavesI : Formula := .rises (.not inI)

/-- φ held at x's entry into i, the latest observation at which its overlap with i became true. -/
def atEntry (φ : Formula) : Formula :=
  .since (.not entersI) (.and entersI φ)

/-- The signal s shows the indication spelled `ind`. -/
def shows (ind : String) : Formula := .atom "dev_traffic_signal_shows" [vS, .lit ind] []

/-- a1: s shows a steady red with a green turn arrow. -/
def redWithTurnArrow : Formula :=
  .and (shows "circular_red")
    (.or (shows "green_arrow(left)") (.or (shows "green_arrow(right)") (shows "green_arrow(u_turn)")))

/-- a4: x faces s — s governs the intersection itself, or a travel region c entering i that x
    occupied at the observation before the entry. -/
def facing : Formula :=
  .or (.atom "dev_governs" [vS, vI] [])
    (.existsRegion (.lit "travel_region") "c"
      (.and (.atom "dev_governs" [vS, vC] [])
        (.and (.atom "st_lane_enters" [vC, vI] [])
          (atPrevious (.atom "rel_occupies" [vX, vC] [])))))

/-- The whole selection of i and s, read at the exit: x leaves i, and at its entry s, facing x,
    showed a steady red with a green turn arrow. -/
def selected : Formula :=
  .and leavesI (atEntry (.and facing redWithTurnArrow))

/-- a5: the movements recognized at the exit. -/
def leftTurn : Formula :=
  .rises (.derived "drv_motion_left_turn_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pLeftTurnMinAngle, pReversalMinAngle])
def rightTurn : Formula :=
  .rises (.derived "drv_motion_right_turn_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pRightTurnMinAngle, pReversalMinAngle])
def straightThrough : Formula :=
  .rises (.derived "drv_motion_straight_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pStraightThroughMaxHeadingChange])

/-- The movement `act` is made and s showed no arrow `ind` for it at the entry. -/
def unindicated (act : Formula) (ind : String) : Formula :=
  .and act (atEntry (.not (shows ind)))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-285::traffic -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-285::traffic"] []

/-- Applicability: a3 'vehicular'; a1 (trigger) and a4 (condition) at the entry, read from the exit;
    a2, the exceptions of paragraph (b). -/
def applicability : Formula :=
  .and (.not (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-165::pedestrian"] []))
    (.and (.existsRegion (.lit "intersection") "i"
            (.existsDevice (.lit "traffic_signal") "s" selected))
      (.and (.not (.ruleApplies "NRS_484B_307_9b_o1" [("x", "x")]))
        (.and (.not (.ruleApplies "NRS_484B_307_9b_o2" [("x", "x")]))
          (.and (.not (.ruleApplies "NRS_484B_307_9b_o3" [("x", "x")]))
            (.not (.ruleApplies "NRS_484B_307_9b_o4" [("x", "x")]))))))

/-- Obligation: a5 (obligation): may enter the intersection only to make the movement indicated by
    the green turn arrow — for every i and s selected as in the applicability. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallDevice (.lit "traffic_signal") "s"
      (.implies selected
        (.and (.not (unindicated leftTurn "green_arrow(left)"))
          (.and (.not (unindicated rightTurn "green_arrow(right)"))
            (.not (unindicated straightThrough "green_arrow(straight)"))))))

def rule : Rule :=
  { id := "NRS_484B_307_9a_o1"
    laws := ["NRS-484B-307-9a"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["An advisory statement of the signal phasing (opposing traffic faces a steady red while the arrow is lit); it permits, requires and forbids nothing, and no duty of the road user turns on it."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9a_o1
