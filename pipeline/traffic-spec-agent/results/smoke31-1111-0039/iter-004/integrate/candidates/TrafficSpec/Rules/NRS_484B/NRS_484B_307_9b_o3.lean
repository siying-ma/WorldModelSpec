/-
  NRS_484B_307_9b_o3 — NRS-484B-307-9b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (trigger): Where the signal is a steady red with a green turn arrow:
    c2 (subject): A person driving a motorcycle, moped or
    c3 (subject): trimobile
    c4 (subject): or riding a bicycle, an electric bicycle or an electric scooter
    c5 (trigger): facing the signal
    c6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow
    c7 (boilerplate): if:
    c8 (sibling): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;
    c9 (sibling): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;
    c11 (obligation): (3) No other device at the place prohibits the turn, if applicable;
    c12 (boilerplate): and
    c13 (sibling): (4) The person yields the right-of-way
    c15 (sibling): to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.

  Elements (span → atoms, derived):
    c1: atoms ['dev.traffic_signal'], derived []
    c2: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle', 'ru.aggregate=DEF-NRS-484A-125::moped'], derived []
    c4: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    c5: atoms ['dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived ['drv.motion.entering_region']
    c6: atoms ['rel.occupies', 'st.intersection', 'kin.yaw_rate'], derived ['drv.motion.entering_region', 'drv.motion.leaving_region', 'drv.motion.heading_change_since_entry']
    c11: atoms ['dev.regulatory_sign', 'dev.traffic_signal', 'dev.governs', 'prim.conditions_hold', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []

  How each is written:
    c2, c4 — the binder class: the disjunction of the five admitted aggregates, by id.
    c6 — the observation judged is x's leaving of an intersection i (drv_motion_leaving_region).
      The entry it closes is read with `since`: `entering` at some earlier observation, and no
      entry between it and the leaving, so it is x's latest entry into i; x leaving now with no
      re-entry since means x occupied i from that entry to the observation before the leaving.
      Straight through is |heading change since entry| < p.turn_recognition_angle; a turn is
      that change at least the angle in absolute value, left positive, so the turn opposite
      green_arrow(left) is a change ≤ −angle and the one opposite green_arrow(right) ≥ +angle.
    c1, c5 — at that entry observation, x occupies a travel region c that enters i
      (st_lane_enters) and a traffic signal s governing c or i shows circular_red together with
      green_arrow(d); d = left and d = right are two disjuncts, each paired with its own
      opposite turn.
    c11 — the obligation selects i again as the applicability does (the leaving and the entry
      under the red with a green arrow, either direction). Where the change since entry is a
      left turn (≥ angle), at the entry no device governing c or i prohibits a left turn: no
      regulatory sign coded no_left_turn whose conditions hold for x (prim_conditions_hold),
      and no signal head showing red_arrow(left); a right turn (≤ −angle) likewise with
      no_right_turn and red_arrow(right). A straight passage makes neither implication engage.
      Choice the record left open: the carrier "c x entered through" is every travel region x
      occupies at the entry that enters i (a universal over them), so a rule never picks the
      approach that favours x.
    c5, c11 — the carrier quantifier ranges over travel regions, which include the intersection
      i itself (x always occupies i at its entry); `c ≠ i` (`same`) is stated beside
      st_lane_enters(c, i), since an approach carrier is never the intersection it enters and the
      relation is unrecorded (unknown, not false) on an intersection. It removes no carrier.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b_o3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantifier variables: the intersection, the approach carrier, the facing signal, a prohibiting device. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"
def vD : Arg := .var "d"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-135::motorcycle"] [])
    (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-125::moped"] [])
      (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-025::bicycle"] [])
        (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
          (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-018::electric_scooter"] []))))

/-- x's footprint begins to overlap intersection i at the observation. -/
def entering : Formula := .derived "drv_motion_entering_region" [vX, vI] []

/-- x's footprint stops overlapping intersection i at the observation. -/
def leaving : Formula := .derived "drv_motion_leaving_region" [vX, vI] []

/-- φ at x's latest entry into i: an entry at which φ held, and no entry since. -/
def atEntry (φ : Formula) : Formula := .since (.not entering) (.and entering φ)

/-- The heading change of x since its latest entry into i (degrees, left positive). -/
def headingChange : Term :=
  .quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph]

def straightThrough : Formula := .cmp (.abs headingChange) .lt pTurnRecognitionAngle
def turnLeft : Formula := .cmp headingChange .ge pTurnRecognitionAngle
def turnRight : Formula := .cmp headingChange .le (.neg pTurnRecognitionAngle)

/-- Device `d` governs the approach carrier c or the intersection i. -/
def governsApproach (d : Arg) : Formula :=
  .or (.atom "dev_governs" [d, vC] []) (.atom "dev_governs" [d, vI] [])

/-- An approach carrier of i x occupies (a carrier entering i is never i itself). -/
def approach : Formula :=
  .and (.not (.same vC vI))
    (.and (.atom "rel_occupies" [vX, vC] []) (.atom "st_lane_enters" [vC, vI] []))

/-- c1, c5: x occupies a carrier c entering i, and a signal governing c or i shows circular_red
    with green_arrow(dir). -/
def facingRedWithArrow (dir : String) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and approach
      (.existsDevice (.lit "traffic_signal") "s"
        (.and (governsApproach vS)
          (.and (.atom "dev_traffic_signal_shows" [vS, .lit "circular_red"] [])
                (.atom "dev_traffic_signal_shows" [vS, .lit s!"green_arrow({dir})"] [])))))

/-- c6: the passage through i, straight through or opposite the arrow shown at the entry. -/
def passage : Formula :=
  .or (.and (atEntry (facingRedWithArrow "left")) (.or straightThrough turnRight))
      (.and (atEntry (facingRedWithArrow "right")) (.or straightThrough turnLeft))

/-- c11: a device governing c or i prohibits a turn toward `dir` (sign code `code`). -/
def prohibits (dir code : String) : Formula :=
  .or (.existsDevice (.lit "regulatory_sign") "d"
        (.and (governsApproach vD)
          (.and (.atom "dev_regulatory_sign_code" [vD, .lit code] [])
                (.derived "prim_conditions_hold" [vD, vX] []))))
      (.existsDevice (.lit "traffic_signal") "d"
        (.and (governsApproach vD)
          (.atom "dev_traffic_signal_shows" [vD, .lit s!"red_arrow({dir})"] [])))

/-- c11 at the entry: through every approach carrier of i x occupies, no prohibition toward `dir`. -/
def noProhibition (dir code : String) : Formula :=
  .forallRegion (.lit "travel_region") "c" (.implies approach (.not (prohibits dir code)))

/-- Applicability: c1 (trigger): Where the signal is a steady red with a green turn arrow:; c5 (trigger): facing the signal; c6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.and leaving passage)

/-- Obligation: c11 (obligation): (3) No other device at the place prohibits the turn, if applicable; -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies
      (.and leaving (.or (atEntry (facingRedWithArrow "left")) (atEntry (facingRedWithArrow "right"))))
      (.and (.implies turnLeft (atEntry (noProhibition "left" "no_left_turn")))
            (.implies turnRight (atEntry (noProhibition "right" "no_right_turn")))))

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
    residues := ["Every trimobile, a motor vehicle with a seat designed to travel on three wheels, is already a member of the motorcycle aggregate claimed on span c2 (\"every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground\"): the duty is the same whether or not the word is read."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b_o3
