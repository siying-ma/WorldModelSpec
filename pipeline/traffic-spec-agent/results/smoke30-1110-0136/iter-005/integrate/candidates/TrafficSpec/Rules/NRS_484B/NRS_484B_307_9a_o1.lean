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
    a3: the class of x is ru_aggregate(x, DEF-NRS-484A-285::traffic); 'vehicular' is the
        applicability's conjunct not ru_aggregate(x, DEF-NRS-484A-165::pedestrian).
    occasion: the act is an event recognized at the exit; `exitI` is rises(not occupies(x, i)),
        x leaving an intersection i (existsRegion "intersection").
    a1, a4 (at_recognition, read at the entry): `atEntry ψ` evaluates ψ at x's entry into i, the
        observation at which occupies(x, i) last rose, from the exit: since(occupies(x, i),
        rises(occupies(x, i)) ∧ ψ) holds at the observation before the exit, which `prev` reaches
        (Core has no previous-observation operator; `prev φ` is written from `rises` alone and is
        φ one observation back wherever φ is decided here). a4: some travel_region c that x
        occupied at the observation before the entry (`prev` again), with st_lane_enters(c, i)
        and dev_governs(s, c), or dev_governs(s, i). a1: s shows circular_red and one of
        green_arrow(left | right | u_turn).
    a2: not ruleApplies for each of NRS_484B_307_9b_o1…o4, x ↦ x.
    a5: for every intersection i and traffic signal s satisfying the same whole selection
        (`selection`, shared by both formulas), each of the three movement concepts at the exit
        conjoined with the absence at the entry of the arrow indicating it is a breach.
  No choice beyond the record's own readings; no narrowing is declared.

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

/-- φ at the previous observation, from `rises` alone: where φ holds here, it held before unless it
    rose here; where it fails here, it held before exactly when its negation rose here. -/
def prev (φ : Formula) : Formula :=
  .or (.and φ (.not (.rises φ))) (.rises (.not φ))

/-- x's footprint overlaps the intersection `i` (rel.occupies, st.intersection). -/
def occI : Formula := .atom "rel_occupies" [vX, .var "i"] []

/-- The occasion's recognition: x leaves `i` here (overlap at the observation before, not here). -/
def exitI : Formula := .rises (.not occI)

/-- ψ held at x's entry into `i`, the observation at which its overlap with `i` last became true,
    read from the exit: the `since` holds at the observation before the exit (the overlap held
    throughout from the entry), which `prev` reaches since it is false at the exit itself. -/
def atEntry (ψ : Formula) : Formula :=
  prev (.since occI (.and (.rises occI) ψ))

/-- a4: the signal `s` faces x — it governs the approach carrier `c` x occupied at the observation
    before the entry, whose entrance end is `i` (dev.governs, st.lane_enters, rel.occupies over
    st.travel_region), or it governs `i` itself. Read at the entry. -/
def facing : Formula :=
  .or
    (.existsRegion (.lit "travel_region") "c"
      (.and (prev (.atom "rel_occupies" [vX, .var "c"] []))
        (.and (.atom "st_lane_enters" [.var "c", .var "i"] [])
          (.atom "dev_governs" [.var "s", .var "c"] []))))
    (.atom "dev_governs" [.var "s", .var "i"] [])

def shows (ind : String) : Formula := .atom "dev_traffic_signal_shows" [.var "s", .lit ind] []

/-- a1: steady red (circular_red) displayed with at least one green turn arrow. Read at the entry. -/
def redWithTurnArrow : Formula :=
  .and (shows "circular_red")
    (.or (shows "green_arrow(left)") (.or (shows "green_arrow(right)") (shows "green_arrow(u_turn)")))

/-- The whole selection of `i` and `s`: x leaves `i` here, and at its entry `s`, facing it, showed
    a steady red with a green turn arrow. Written once and used in both formulas. -/
def selection : Formula := .and exitI (atEntry (.and facing redWithTurnArrow))

def exceptions : Formula :=
  .and (.not (.ruleApplies "NRS_484B_307_9b_o1" [("x", "x")]))
    (.and (.not (.ruleApplies "NRS_484B_307_9b_o2" [("x", "x")]))
      (.and (.not (.ruleApplies "NRS_484B_307_9b_o3" [("x", "x")]))
        (.not (.ruleApplies "NRS_484B_307_9b_o4" [("x", "x")]))))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-285::traffic -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-285::traffic"] []

/-- Applicability: a3 'vehicular' (x not a pedestrian); a1, a4 read at the entry from the exit;
    a2 paragraph (b)'s nodes as exceptions. -/
def applicability : Formula :=
  .and (.not (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-165::pedestrian"] []))
    (.and
      (.existsRegion (.lit "intersection") "i"
        (.existsDevice (.lit "traffic_signal") "s" selection))
      exceptions)

def leftTurn : Formula :=
  .derived "drv_motion_left_turn_through_region" [vX, .var "i"]
    [pHeadingSinceStepCarlaSceneGraph, pLeftTurnMinAngle, pReversalMinAngle]
def rightTurn : Formula :=
  .derived "drv_motion_right_turn_through_region" [vX, .var "i"]
    [pHeadingSinceStepCarlaSceneGraph, pRightTurnMinAngle, pReversalMinAngle]
def straightThrough : Formula :=
  .derived "drv_motion_straight_through_region" [vX, .var "i"]
    [pHeadingSinceStepCarlaSceneGraph, pStraightThroughMaxHeadingChange]

/-- Obligation: a5 — for every intersection and signal selected as in the applicability, the
    movement completed at the exit is one an arrow `s` displayed at the entry indicates. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallDevice (.lit "traffic_signal") "s"
      (.implies selection
        (.and (.not (.and leftTurn (atEntry (.not (shows "green_arrow(left)")))))
          (.and (.not (.and rightTurn (atEntry (.not (shows "green_arrow(right)")))))
            (.not (.and straightThrough (atEntry (.not (shows "green_arrow(straight)")))))))))

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
