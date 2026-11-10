/-
  NRS_484B_307_9b_o3 — NRS-484B-307-9b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (trigger): Where the signal is a steady red with a green turn arrow:
    b2 (subject): A person driving a motorcycle,
    b3 (subject): moped or trimobile
    b4 (subject): or riding a bicycle, an electric bicycle or an electric scooter
    b5 (condition): facing the signal
    b6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow if:
    b7 (sibling): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;
    b8 (sibling): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change
    b9 (sibling): because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;
    b10 (obligation): (3) No other device at the place prohibits the turn,
    b11 (condition): if applicable;
    b12 (sibling): and (4) The person yields the right-of-way to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.

  Elements (span → atoms, derived):
    b1: atoms ['dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    b2: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle'], derived []
    b3: atoms ['ru.aggregate=DEF-NRS-484A-125::moped', 'ru.motorcycle'], derived []
    b4: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    b5: atoms ['dev.governs', 'dev.traffic_signal', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    b6: atoms ['rel.occupies', 'st.intersection', 'kin.yaw_rate', 'dev.traffic_signal'], derived ['drv.motion.straight_through_region', 'drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region']
    b10: atoms ['dev.regulatory_sign', 'prim.conditions_hold', 'dev.governs', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    b11: atoms ['rel.occupies', 'st.intersection', 'kin.yaw_rate'], derived ['drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region']

  How each span is written:
    b2, b3, b4 (class of x): the disjunction of the five admitted aggregates, each `ru_aggregate`
      with its id, and the class atom `ru_motorcycle` (b3's nearest atom for "trimobile"; the
      record's gap on b3 stands).
    The crossing: x leaves intersection i at the judged observation (the turn and straight
      concepts are recognized at the exit). i is bound by `existsRegion "intersection"` in the
      applicability and by `forallRegion "intersection"` in the obligation, each with the record's
      whole selection (the turn concept and the signal read at entry).
    "At the entry" (the record's past operator): `atEntry φ` is
      `since (¬ rises (occupies x i)) (rises (occupies x i) ∧ φ)`: φ at the observation at which
      x's overlap with i last became true. The approach carrier is one x occupies there
      (`rel_occupies x c`, `st_lane_enters c i`, c of kind travel_region), as the record's
      applicability states ("at its entry"); a body entering i straddles the carrier and i.
    b1, b5 (signal faced): at the entry some traffic signal s shows circular_red and
      green_arrow(dir), governing x's approach carrier or i itself (`dev_governs`).
    b6 (permitted movements): straight through i, or the turn opposite the arrow — a right turn
      under green_arrow(left), a left turn under green_arrow(right). Turn concepts take the turn
      minimum of their side and the reversal bound as the upper end; the straight concept's
      `max_angle` is p.left_turn_min_angle (the node names no straight bound of its own; the left
      and right minima are the turn thresholds below which a crossing is not a turn) — a choice
      the record left open, which decides nothing here because b11 conjoins a turn.
    b11 (if applicable): the crossing is a left or a right turn; with b6 this leaves exactly the
      turn opposite the arrow, a straight crossing or a turn with the arrow being not engaged.
    b10 (obligation): for each selected i, at the entry no regulatory sign g of the turn's code
      (no_right_turn for the right turn, no_left_turn for the left turn) governs the approach
      carrier or i with `prim_conditions_hold g x`.
    b7, b8, b9, b12 are siblings carried by other nodes.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b_o3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLeftTurnMinAngle : Term := .param "p.left_turn_min_angle"
def pReversalMinAngle : Term := .param "p.reversal_min_angle"
def pRightTurnMinAngle : Term := .param "p.right_turn_min_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables: the intersection, the approach carrier, the signal, the sign. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"

def aggregate (id : String) : Formula := .atom "ru_aggregate" [vX, .lit id] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.motorcycle, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (aggregate "DEF-NRS-484A-135::motorcycle")
    (.or (aggregate "DEF-NRS-484A-125::moped")
      (.or (.atom "ru_motorcycle" [vX] [])
        (.or (aggregate "DEF-NRS-484A-025::bicycle")
          (.or (aggregate "DEF-NRS-484B-017::electric_bicycle")
            (aggregate "DEF-NRS-484B-018::electric_scooter")))))

/-- x's footprint overlaps the intersection i. -/
def occupiesI : Formula := .atom "rel_occupies" [vX, vI] []

/-- φ at x's entry into i: the observation at which the overlap last became true. -/
def atEntry (φ : Formula) : Formula :=
  .since (.not (.rises occupiesI)) (.and (.rises occupiesI) φ)

/-- Device `d` governs x's approach to i — a travel region x occupies whose entrance end is i —
    or i itself (b5, b10: "facing the signal", "at the place"). -/
def governsPlace (d : String) : Formula :=
  .or (.atom "dev_governs" [.var d, vI] [])
    (.existsRegion (.lit "travel_region") "c"
      (.and (.atom "rel_occupies" [vX, vC] [])
        (.and (.atom "st_lane_enters" [vC, vI] [])
          (.atom "dev_governs" [.var d, vC] []))))

/-- b1, b5: at the entry, a signal facing x shows a steady red with a green arrow in `dir`. -/
def redWithArrow (dir : String) : Formula :=
  atEntry
    (.existsDevice (.lit "traffic_signal") "s"
      (.and (.atom "dev_traffic_signal_shows" [.var "s", .lit "circular_red"] [])
        (.and (.atom "dev_traffic_signal_shows" [.var "s", .lit s!"green_arrow({dir})"] [])
          (governsPlace "s"))))

/-- b6, b11: the crossing of i, recognized at the exit. -/
def leftTurn : Formula :=
  .derived "drv_motion_left_turn_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pLeftTurnMinAngle, pReversalMinAngle]
def rightTurn : Formula :=
  .derived "drv_motion_right_turn_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pRightTurnMinAngle, pReversalMinAngle]
def straightThrough : Formula :=
  .derived "drv_motion_straight_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pLeftTurnMinAngle]

/-- The turn opposite the arrow: right under green_arrow(left), left under green_arrow(right). -/
def rightOppositeArrow : Formula := .and rightTurn (redWithArrow "left")
def leftOppositeArrow : Formula := .and leftTurn (redWithArrow "right")

/-- Applicability: b1 (trigger): Where the signal is a steady red with a green turn arrow:; b5 (condition): facing the signal; b6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow if:; b11 (condition): if applicable; -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (.or (redWithArrow "left") (redWithArrow "right"))
      (.and (.or straightThrough (.or rightOppositeArrow leftOppositeArrow))
        (.or leftTurn rightTurn)))

/-- b10: at the entry, no regulatory sign of `code` governs x's approach or i with its
    conditions holding for x. -/
def noProhibitingSign (code : String) : Formula :=
  atEntry
    (.not (.existsDevice (.lit "regulatory_sign") "g"
      (.and (.atom "dev_regulatory_sign_code" [.var "g", .lit code] [])
        (.and (governsPlace "g")
          (.derived "prim_conditions_hold" [.var "g", vX] [])))))

/-- Obligation: b10 (obligation): (3) No other device at the place prohibits the turn, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.and (.implies rightOppositeArrow (noProhibitingSign "no_right_turn"))
      (.implies leftOppositeArrow (noProhibitingSign "no_left_turn")))

def rule : Rule :=
  { id := "NRS_484B_307_9b_o3"
    laws := ["NRS-484B-307-9b"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b_o3
