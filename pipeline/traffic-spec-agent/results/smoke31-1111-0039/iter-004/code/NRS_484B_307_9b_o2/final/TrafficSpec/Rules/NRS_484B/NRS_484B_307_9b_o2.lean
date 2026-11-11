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

  Literals the text states (each written through its Units constructor):
    c9: 2 count — two

  How each span is written:
    c2, c4 — the class of `x`: the five admitted aggregates, each `ru_aggregate` with its id, joined
      by `or`.
    c5, c6 — the judged observation is x's leaving of an intersection i (`leavesI`). From it a
      `since` reaches back to x's latest entry into i: every observation after the entry is one at
      which x occupies i or leaves it and does not enter it again (`withinI`), so the entry found is
      the latest one. At that entry x occupies a travel region c that enters i (`st_lane_enters`),
      and a traffic signal s governing c or i shows circular_red with green_arrow(d) (`selection`).
      The arrow's side d (left or right) is a spelling, so each side is its own disjunct.
    c6 — at the leaving, the heading change since the entry (`headingSinceEntry`, the reviewed step
      parameter of the acquisition profile) decides the passage: straight through where its
      absolute value is below the turn recognition angle; a left turn where it is at or above the
      angle, a right turn where it is at or below its negation (left positive). Under a left arrow
      the passage is straight or a right turn; under a right arrow straight or a left turn.
    c9 — read at the same entry, through the same `since`. The wait is the latest run of
      observations at which x is halted (`drv_motion_halted`) while occupying c (`waiting`).
      Cycles: `count` of the rises of s's circular_red with green_arrow(d) display since the start
      of that run, more than the literal two (`gt 2`). The signal does not change: at no
      observation of the wait does s show circular_green or green_arrow in the direction of x's
      movement (`neverPermitted`): a `since` whose anchor is the wait's first observation (`rises
      waiting`, the display not permissive there) and which holds while every later observation
      is not one of the wait with a permissive display. The direction of x's movement is known
      only at the leaving, so the obligation is split there by the passage (straight, right turn,
      left turn) and each branch re-reads the entry with the permissive arrow of that passage.
      A wait whose start lies before the recording leaves both readings unknown (`count` and
      `since` truncated at the trace start).
    Region and device selection in the obligation (rule 3c): the obligation selects i, c and s
      again with the applicability's whole selection (leaving of i; latest entry into i; c occupied
      at the entry, entering i; s governing c or i and showing circular_red with green_arrow(d)).

  Choices the record left open (declared in `narrowings`):
    c9 — the duty is required of every carrier c and every signal head s that meet the selection
      at the entry, not of one chosen among them: the rule never picks the approach or the head
      that favours x.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The intersection passed, the approach carrier and the signal head. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- c9: the literal "two" complete cycles. -/
def completeCycles : Nat := 2

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-135::motorcycle"] [])
    (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-125::moped"] [])
      (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-025::bicycle"] [])
        (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
          (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-018::electric_scooter"] []))))

/-- x's footprint overlaps region `r`. -/
def occupies (r : Arg) : Formula := .atom "rel_occupies" [vX, r] []

/-- c5, c6: x enters / leaves the intersection i at the observation. -/
def entersI : Formula := .derived "drv_motion_entering_region" [vX, vI] []
def leavesI : Formula := .derived "drv_motion_leaving_region" [vX, vI] []

/-- c6: x's heading change since its latest entry into i (degrees, left positive). -/
def headingSinceEntry : Term :=
  .quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph]

def straightThrough : Formula := .cmp (.abs headingSinceEntry) .lt pTurnRecognitionAngle
def turnLeft : Formula := .cmp headingSinceEntry .ge pTurnRecognitionAngle
def turnRight : Formula := .cmp headingSinceEntry .le (.neg pTurnRecognitionAngle)

/-- c5, c6: an observation after the entry, up to the leaving: x in i or leaving it, not entering
    it again. -/
def withinI : Formula := .and (.not entersI) (.or (occupies vI) leavesI)

/-- φ at x's latest entry into i, read from an observation of its passage or its leaving. -/
def atEntry (φ : Formula) : Formula := .since withinI (.and entersI φ)

/-- c1: s shows the indication spelled `ind`. -/
def shows (ind : String) : Formula := .atom "dev_traffic_signal_shows" [vS, .lit ind] []

def greenArrow (dir : String) : String := s!"green_arrow({dir})"

/-- c1: a steady red with a green turn arrow toward `d`. -/
def redWithArrow (d : String) : Formula := .and (shows "circular_red") (shows (greenArrow d))

/-- c1, c5: at the entry, x occupies the travel region c, which enters i, and the signal s governs
    c or i and shows circular_red with green_arrow(d). -/
def selection (d : String) : Formula :=
  .and (occupies vC)
    (.and (.atom "st_lane_enters" [vC, vI] [])
      (.and (.or (.atom "dev_governs" [vS, vC] []) (.atom "dev_governs" [vS, vI] []))
        (redWithArrow d)))

/-- c1, c5: some such carrier and signal. -/
def facing (d : String) : Formula :=
  .existsRegion (.lit "travel_region") "c" (.existsDevice (.lit "traffic_signal") "s" (selection d))

/-- c9: x halted while occupying c. -/
def waiting : Formula := .and (.derived "drv_motion_halted" [vX] [pSpeedResolution]) (occupies vC)

/-- c9: more rises of the red-with-arrow display since the wait began than the literal. -/
def cycles (d : String) : Formula := .count (redWithArrow d) waiting .gt completeCycles

/-- c9: an indication permitting x's movement `mv` (straight, left or right). -/
def permits (mv : String) : Formula := .or (shows "circular_green") (shows (greenArrow mv))

/-- c9: at no observation of the latest wait does s show an indication permitting the movement. -/
def neverPermitted (mv : String) : Formula :=
  .since (.not (.and waiting (permits mv))) (.and (.rises waiting) (.not (permits mv)))

/-- c9: for every carrier and signal selected at the entry under arrow `d`, the duty for a
    passage `mv`. -/
def dutyFor (d mv : String) : Formula :=
  .forallRegion (.lit "travel_region") "c"
    (.forallDevice (.lit "traffic_signal") "s"
      (.implies (selection d) (.and (cycles d) (neverPermitted mv))))

/-- Applicability: c1 (trigger): Where the signal is a steady red with a green turn arrow:; c5 (trigger): facing the signal; c6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and leavesI
      (.or (.and (atEntry (facing "left")) (.or straightThrough turnRight))
        (.and (atEntry (facing "right")) (.or straightThrough turnLeft))))

/-- Obligation: c9 (obligation): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies leavesI
      (.and (.implies straightThrough
              (atEntry (.and (dutyFor "left" "straight") (dutyFor "right" "straight"))))
        (.and (.implies turnRight (atEntry (dutyFor "left" "right")))
          (.implies turnLeft (atEntry (dutyFor "right" "left"))))))

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
    narrowings :=
      [ { span := "c9"
          why := "The duty is required of every approach carrier c and every signal head s that meet the selection at x's entry (c occupied at the entry and entering i; s governing c or i and showing circular_red with green_arrow(d)), not of one chosen among them: the rule never picks the approach or the head that favours the person."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b_o2
