/-
  NRS_484B_307_9b_o2 — NRS-484B-307-9b

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
    b8 (obligation): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change
    b9 (condition): because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;
    b10 (sibling): (3) No other device at the place prohibits the turn,
    b11 (sibling): if applicable;
    b12 (sibling): and (4) The person yields the right-of-way to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.

  Elements (span → atoms, derived):
    b1: atoms ['dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    b2: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle'], derived []
    b3: atoms ['ru.aggregate=DEF-NRS-484A-125::moped', 'ru.motorcycle'], derived []
    b4: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    b5: atoms ['dev.governs', 'dev.traffic_signal', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    b6: atoms ['rel.occupies', 'st.intersection', 'kin.yaw_rate', 'dev.traffic_signal'], derived ['drv.motion.straight_through_region', 'drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region']
    b8: atoms ['dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived ['drv.motion.stopped']

  How each span is written:
    b2–b4: the class of x is the disjunction of the five admitted aggregates (`ru_aggregate` with
      the aggregate id) and `ru_motorcycle` (the nearest atom for "trimobile").
    b1, b5: at x's entry into the intersection i (`atEntry`: the latest rise of rel_occupies(x, i),
      read from the exit through `since`), the traffic signal s shows circular_red and
      green_arrow(dir); at the observation before the entry (`atPrev`: `since (rises occ) (¬occ ∧ …)`
      evaluated at the entry) x occupies the approach carrier c (a travel region) with
      st_lane_enters(c, i), and s governs c or governs i itself. c is the record's "approach
      carrier", so st_lane_enters(c, i) is required in both cases of the governance.
    b6: the crossing is drv.motion.straight_through_region, or the turn opposite the arrow:
      right_turn_through_region under green_arrow(left), left_turn_through_region under
      green_arrow(right); the turn bands end at p.reversal_min_angle. dir is spelled out as the two
      cases left and right.
    b8: at the observation before the entry, H = stopped(x) ∧ occupies(x, c) ∧ ¬occupies(x, i);
      the wait is the stretch from H's latest rise (no further rise of H after it) through which x
      does not occupy i and s shows no circular_green. Two complete arrow cycles are the chain,
      each link read back through `since` within the wait: A = green_arrow(dir) rises, then ¬A
      rises, then A rises, then ¬A rises, all after (or at) H's latest rise and no later than the
      observation before the entry. Each cycle so both lights and goes out within the wait (the
      record's narrowing). No numeric threshold is written. A wait whose start the recording does
      not show leaves the chain unknown through `since`'s unobserved past.
    b9: the record's residue.

  Obligation quantifiers: every intersection, signal, carrier and direction selected as in the
  applicability is held to the duty (forall … selection → duty).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLeftTurnMinAngle : Term := .param "p.left_turn_min_angle"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pReversalMinAngle : Term := .param "p.reversal_min_angle"
def pRightTurnMinAngle : Term := .param "p.right_turn_min_angle"
def pStraightThroughMaxHeadingChange : Term := .param "p.straight_through_max_heading_change"

def zeroMetres : Term := .lit Q.zero .metre

def vI : Arg := .var "i"
def vS : Arg := .var "s"
def vC : Arg := .var "c"

def agg (id : String) : Formula := .atom "ru_aggregate" [vX, .lit id] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.motorcycle, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (agg "DEF-NRS-484A-135::motorcycle")
    (.or (agg "DEF-NRS-484A-125::moped")
      (.or (.atom "ru_motorcycle" [vX] [])
        (.or (agg "DEF-NRS-484A-025::bicycle")
          (.or (agg "DEF-NRS-484B-017::electric_bicycle")
            (agg "DEF-NRS-484B-018::electric_scooter")))))

/-- x's footprint overlaps the intersection i. -/
def occI : Formula := .atom "rel_occupies" [vX, vI] []
/-- x's footprint overlaps the carrier c. -/
def occC : Formula := .atom "rel_occupies" [vX, vC] []
/-- The signal s displays an indication. -/
def shows (ind : String) : Formula := .atom "dev_traffic_signal_shows" [vS, .lit ind] []
def arrow (dir : String) : Formula := shows s!"green_arrow({dir})"

/-- φ at x's entry into i: the latest rise of its overlap with i, read back from the judged observation. -/
def atEntry (φ : Formula) : Formula := .since (.not (.rises occI)) (.and (.rises occI) φ)
/-- φ at the observation before the entry (read at the entry). -/
def atPrev (φ : Formula) : Formula := .since (.rises occI) (.and (.not occI) φ)

/-- b1/b5: c is an approach carrier of i that x occupies, governed by s, or s governs i itself. -/
def approach : Formula :=
  .and occC
    (.and (.atom "st_lane_enters" [vC, vI] [])
      (.or (.atom "dev_governs" [vS, vC] []) (.atom "dev_governs" [vS, vI] [])))

/-- b6: the crossings. -/
def straight : Formula :=
  .derived "drv_motion_straight_through_region" [vX, vI] [pHeadingSinceStepCarlaSceneGraph, pStraightThroughMaxHeadingChange]
def leftTurn : Formula :=
  .derived "drv_motion_left_turn_through_region" [vX, vI] [pHeadingSinceStepCarlaSceneGraph, pLeftTurnMinAngle, pReversalMinAngle]
def rightTurn : Formula :=
  .derived "drv_motion_right_turn_through_region" [vX, vI] [pHeadingSinceStepCarlaSceneGraph, pRightTurnMinAngle, pReversalMinAngle]
/-- The turn opposite the arrow's direction. -/
def opposite (dir : String) : Formula := if dir == "left" then rightTurn else leftTurn

/-- The selection for an arrow direction, at the exit: the crossing, and at the entry the steady
    red with the arrow, the approach read at the observation before. -/
def selection (dir : String) : Formula :=
  .and (.or straight (opposite dir))
    (atEntry (.and (shows "circular_red") (.and (arrow dir) (atPrev approach))))

/-- b8: x halted on the approach, not in the intersection. -/
def halted : Formula :=
  .and (.derived "drv_motion_stopped" [vX] [pMotionSpeedTolerance]) (.and occC (.not occI))
/-- Every observation of the wait: x outside i, no circular_green. -/
def stretch : Formula := .and (.not occI) (.not (shows "circular_green"))
/-- After the wait's start: no later rise of the halt. -/
def inWait : Formula := .and (.not (.rises halted)) stretch
/-- The wait's start: the latest rise of the halt. -/
def waitStart : Formula := .and (.rises halted) stretch
/-- An edge at this observation, with the earlier part of the chain within the wait behind it. -/
def link (edge earlier : Formula) : Formula := .and edge (.since inWait earlier)
/-- Two complete cycles of the arrow ended within the wait: lit, out, lit, out, in order, from the
    wait's start up to here. -/
def twoCycles (dir : String) : Formula :=
  let lit := Formula.rises (arrow dir)
  let out := Formula.rises (.not (arrow dir))
  .since inWait (link out (link lit (link out (link lit waitStart))))

def duty (dir : String) : Formula := atEntry (atPrev (twoCycles dir))

def selected (body : Formula) : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsDevice (.lit "traffic_signal") "s"
      (.existsRegion (.lit "travel_region") "c" body))

/-- Applicability: b1 (trigger): Where the signal is a steady red with a green turn arrow:; b5 (condition): facing the signal; b6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow if:; b9 (condition): because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; -/
def applicability : Formula :=
  selected (.or (selection "left") (selection "right"))

/-- Obligation: b8 (obligation): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallDevice (.lit "traffic_signal") "s"
      (.forallRegion (.lit "travel_region") "c"
        (.and (.implies (selection "left") (duty "left"))
              (.implies (selection "right") (duty "right")))))

def rule : Rule :=
  { id := "NRS_484B_307_9b_o2"
    laws := ["NRS-484B-307-9b"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["The cause the words name (a malfunction, or a failure to detect the road user) is what a signal's not changing for a waiting road user through two complete cycles consists in; once the obligation reads two complete cycles with no change, the cause adds no further restriction, so the duty is the same whether or not these words are read."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b_o2
