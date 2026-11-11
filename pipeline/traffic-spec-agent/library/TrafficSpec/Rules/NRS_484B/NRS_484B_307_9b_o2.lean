/-
  NRS_484B_307_9b_o2 — NRS-484B-307-9b

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
    c9 (obligation): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;
    c11 (sibling): (3) No other device at the place prohibits the turn, if applicable;
    c12 (boilerplate): and
    c13 (sibling): (4) The person yields the right-of-way
    c15 (sibling): to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.

  Elements (span → atoms, derived):
    c1: atoms ['dev.traffic_signal'], derived []
    c2: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle', 'ru.aggregate=DEF-NRS-484A-125::moped'], derived []
    c4: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    c5: atoms ['dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived ['drv.motion.entering_region']
    c6: atoms ['rel.occupies', 'st.intersection', 'kin.yaw_rate'], derived ['drv.motion.entering_region', 'drv.motion.leaving_region', 'drv.motion.heading_change_since_entry']
    c9: atoms ['dev.traffic_signal', 'dev.governs', 'kin.speed', 'rel.occupies', 'st.lane_enters', 'st.travel_region'], derived ['drv.motion.halted']

  How each span is written:
    c2, c4: `ru_aggregate` of x with each of the five admitted aggregate ids, disjoined (clsX).
    c1, c5: at the leaving, read through `since` back over x's stay in i to its latest entry
      (drv.motion.entering_region): there some travel region c that x occupies, with
      st_lane_enters(c, i), and some traffic signal s governing c or i shows circular_red together
      with green_arrow(d). The arrow side d (left or right) is split into two disjuncts, since the
      passage allowed at the leaving depends on it. A carrier entering i is never i itself (an
      intersection carries no st.lane_enters), so c = i is excluded with `same`; without it the
      intersection, which x always occupies at its entry, would leave the selection unknown.
    c6: at the leaving (drv.motion.leaving_region) the heading change since the entry
      (drv.motion.heading_change_since_entry, step p.heading_since_step_carla_scene_graph):
      straight is |change| < p.turn_recognition_angle; a left turn change ≥ the angle; a right
      turn change ≤ minus the angle; the turn allowed is the side opposite d.
    c9: obligation, for every intersection i, every arrow side d and every passage m allowed under
      it, at the leaving: read at the entry, for every c and every s meeting the applicability's
      selection (restated whole), (a) `count` of rises of circular_red ∧ green_arrow(d) since the
      start of the latest run of (drv.motion.halted(x) ∧ rel_occupies(x, c)) is gt 2, the node's
      own bound; (b) going back from the entry to that run, at every observation of it s shows
      neither circular_green nor green_arrow(m) (m = straight, or the side of the turn). A run
      reaching the trace start leaves both unknown.
  No choice beyond the record's was needed: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantified variables: the intersection, the approach carrier, the signal head. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"

/-- c2, c4: one of the five admitted aggregates. -/
def member (aggregate : String) : Formula := .atom "ru_aggregate" [vX, .lit aggregate] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (member "DEF-NRS-484A-135::motorcycle")
    (.or (member "DEF-NRS-484A-125::moped")
      (.or (member "DEF-NRS-484A-025::bicycle")
        (.or (member "DEF-NRS-484B-017::electric_bicycle")
          (member "DEF-NRS-484B-018::electric_scooter"))))

def occupies (r : Arg) : Formula := .atom "rel_occupies" [vX, r] []

/-- c5, c6: x's entry into i, its leaving of i, and the heading change since that entry. -/
def entering : Formula := .derived "drv_motion_entering_region" [vX, vI] []
def leaving : Formula := .derived "drv_motion_leaving_region" [vX, vI] []
def headingChange : Term :=
  .quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph]

/-- c6: straight through, or a turn to the given side, read at the leaving. -/
def passage : String → Formula
  | "left" => .cmp headingChange .ge pTurnRecognitionAngle
  | "right" => .cmp headingChange .le (.neg pTurnRecognitionAngle)
  | _ => .cmp (.abs headingChange) .lt pTurnRecognitionAngle

/-- The side opposite the green turn arrow. -/
def opposite : String → String
  | "left" => "right"
  | _ => "left"

/-- c1, c9: what s displays. -/
def shows (indication : String) : Formula := .atom "dev_traffic_signal_shows" [vS, .lit indication] []
def redWithArrow (d : String) : Formula := .and (shows "circular_red") (shows s!"green_arrow({d})")

/-- c5: at x's entry, c is a carrier x occupies that enters i, and s governs c or i and shows
    circular_red with green_arrow(d). An intersection is no approach to itself (st.lane_enters). -/
def selection (d : String) : Formula :=
  .and (.not (.same vC vI))
    (.and (occupies vC)
      (.and (.atom "st_lane_enters" [vC, vI] [])
        (.and (.or (.atom "dev_governs" [vS, vC] []) (.atom "dev_governs" [vS, vI] []))
          (redWithArrow d))))

/-- Read at the leaving: back through x's stay in i to the observation of its latest entry. -/
def atEntry (φ : Formula) : Formula :=
  .since (.or (occupies vI) leaving) (.and entering φ)

/-- Applicability: c1 (trigger): Where the signal is a steady red with a green turn arrow:; c5 (trigger): facing the signal; c6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow -/
def applicabilityFor (d : String) : Formula :=
  .and (.or (passage "straight") (passage (opposite d)))
    (atEntry (.existsRegion (.lit "travel_region") "c"
      (.existsDevice (.lit "traffic_signal") "s" (selection d))))

def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and leaving (.or (applicabilityFor "left") (applicabilityFor "right")))

/-- c9: the wait is x halted while occupying c. -/
def waiting : Formula := .and (.derived "drv_motion_halted" [vX] [pSpeedResolution]) (occupies vC)

/-- c9: an indication permitting x's movement in direction m. -/
def permits (m : String) : Formula := .or (shows "circular_green") (shows s!"green_arrow({m})")

/-- c9: more than two rises of the display since the wait began, and at no observation of the
    latest wait an indication permitting x's movement. -/
def duty (d m : String) : Formula :=
  .and (.count (redWithArrow d) waiting .gt 2)
    (.since (.not waiting)
      (.and waiting (.since (.and waiting (.not (permits m))) (.not waiting))))

def obligationFor (d m : String) : Formula :=
  .implies (.and leaving (passage m))
    (atEntry (.forallRegion (.lit "travel_region") "c"
      (.forallDevice (.lit "traffic_signal") "s" (.implies (selection d) (duty d m)))))

/-- Obligation: c9 (obligation): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.and (.and (obligationFor "left" "straight") (obligationFor "left" "right"))
      (.and (obligationFor "right" "straight") (obligationFor "right" "left")))

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
    residues := ["Every trimobile, a motor vehicle with a seat designed to travel on three wheels, is already a member of the motorcycle aggregate claimed on span c2 (\"every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground\"): the duty is the same whether or not the word is read."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b_o2
