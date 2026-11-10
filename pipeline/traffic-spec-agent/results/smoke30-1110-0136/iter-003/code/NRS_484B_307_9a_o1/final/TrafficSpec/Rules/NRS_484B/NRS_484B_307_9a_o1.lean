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

  How each span is written:
    a3: the binder class is `ru_aggregate x "DEF-NRS-484A-285::traffic"`; the applicability adds
        `¬ ru_aggregate x "DEF-NRS-484A-165::pedestrian"` (the law's "vehicular").
    occasion: the act (one of the three movement concepts) is an event recognized at x's exit from
        an intersection i: `rises (¬ rel_occupies x i)`, each act read as `rises (<act>)`. Its onset
        is the entry, `rises (rel_occupies x i)`; what held at the entry is read from the exit by
        `atEntry θ := since (¬ rises occ) (rises occ ∧ θ)`, θ at the latest entry into i.
    a1/a4 (read at recognition, through `atEntry`): some traffic signal s (a device quantifier of
        kind traffic_signal) shows circular_red together with green_arrow(left), green_arrow(right)
        or green_arrow(u_turn) (the turn arrows the a1 element names), and s governs i
        (`dev_governs s i`) or governs a travel region c (`existsRegion travel_region`) with
        `st_lane_enters c i` that x occupied at the observation before the entry. "The observation
        before" is written with `rises` alone: prev φ ≡ rises (¬φ) ∨ (φ ∧ ¬ rises φ).
    a2: `¬ ruleApplies` of each of NRS_484B_307_9b_o1 … _o4 with x ↦ x, in the applicability.
    a5: for every intersection i and traffic signal s selected as in the applicability (the whole
        selection written again), a left turn through i requires green_arrow(left) on s at the
        entry, a right turn green_arrow(right), a through movement green_arrow(straight). Left turn
        band [p.left_turn_min_angle, p.reversal_min_angle), right turn band
        [p.right_turn_min_angle, p.reversal_min_angle), through below
        p.straight_through_max_heading_change; step p.heading_since_step_carla_scene_graph.
  No choice beyond the record's was made; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9a_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLeftTurnMinAngle : Term := .param "p.left_turn_min_angle"
def pReversalMinAngle : Term := .param "p.reversal_min_angle"
def pRightTurnMinAngle : Term := .param "p.right_turn_min_angle"
def pStraightThroughMaxHeadingChange : Term := .param "p.straight_through_max_heading_change"

def zeroMetres : Term := .lit Q.zero .metre

def vI : Arg := .var "i"
def vS : Arg := .var "s"
def vC : Arg := .var "c"

/-- φ at the previous observation, written with `rises` alone. -/
def prevF (φ : Formula) : Formula :=
  .or (.rises (.not φ)) (.and φ (.not (.rises φ)))

/-- x overlaps the intersection i. -/
def inI : Formula := .atom "rel_occupies" [vX, vI] []

/-- Recognition: x leaves i at this observation. -/
def leavesI : Formula := .rises (.not inI)

/-- Onset: x enters i at this observation. -/
def entersI : Formula := .rises inI

/-- θ held at x's latest entry into i, read from a later observation. -/
def atEntry (θ : Formula) : Formula :=
  .since (.not entersI) (.and entersI θ)

def shows (lit : String) : Formula := .atom "dev_traffic_signal_shows" [vS, .lit lit] []

/-- a1: a steady red with a green turn arrow. -/
def redWithTurnArrow : Formula :=
  .and (shows "circular_red")
    (.or (shows "green_arrow(left)") (.or (shows "green_arrow(right)") (shows "green_arrow(u_turn)")))

/-- a4: s governs i, or the approach carrier x occupied at the observation before the entry. -/
def facing : Formula :=
  .or (.atom "dev_governs" [vS, vI] [])
    (.existsRegion (.lit "travel_region") "c"
      (.and (.atom "dev_governs" [vS, vC] [])
        (.and (.atom "st_lane_enters" [vC, vI] [])
          (prevF (.atom "rel_occupies" [vX, vC] [])))))

/-- The selection of i and s: x leaves i, and at its entry s, facing it, showed red with a turn arrow. -/
def selected : Formula :=
  .and leavesI (atEntry (.and facing redWithTurnArrow))

def leftTurn : Formula :=
  .rises (.derived "drv_motion_left_turn_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pLeftTurnMinAngle, pReversalMinAngle])
def rightTurn : Formula :=
  .rises (.derived "drv_motion_right_turn_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pRightTurnMinAngle, pReversalMinAngle])
def straightThrough : Formula :=
  .rises (.derived "drv_motion_straight_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pStraightThroughMaxHeadingChange])

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-285::traffic -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-285::traffic"] []

def notExcepted (id : String) : Formula := .not (.ruleApplies id [("x", "x")])

/-- Applicability: a1 (trigger): Where the signal is a steady red with a green turn arrow:; a4 (condition): facing the signal -/
def applicability : Formula :=
  .and (.not (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-165::pedestrian"] []))
    (.and (.existsRegion (.lit "intersection") "i"
        (.existsDevice (.lit "traffic_signal") "s" selected))
      (.and (notExcepted "NRS_484B_307_9b_o1")
        (.and (notExcepted "NRS_484B_307_9b_o2")
          (.and (notExcepted "NRS_484B_307_9b_o3") (notExcepted "NRS_484B_307_9b_o4")))))

/-- Obligation: a5 (obligation): may enter the intersection only to make the movement indicated by the green turn arrow, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallDevice (.lit "traffic_signal") "s"
      (.implies selected
        (.and (.implies leftTurn (atEntry (shows "green_arrow(left)")))
          (.and (.implies rightTurn (atEntry (shows "green_arrow(right)")))
            (.implies straightThrough (atEntry (shows "green_arrow(straight)")))))))

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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9a_o1
