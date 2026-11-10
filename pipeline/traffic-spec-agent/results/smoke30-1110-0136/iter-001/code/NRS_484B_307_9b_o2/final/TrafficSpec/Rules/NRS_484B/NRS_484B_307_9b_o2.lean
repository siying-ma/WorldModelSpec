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

  Literals the text states (each written through its Units constructor):
    b8: 2 count — two complete cycles

  How each span is written.
    b2–b4 (subject): the class of `x` is the disjunction of the five claimed aggregates
      (`ru_aggregate x "<id>"`) and the class atom `ru_motorcycle` (the nearest atom for
      'trimobile', as the record maps it).
    b6 (trigger): the judged observation is x's exit from an intersection `i`: the crossing is
      `drv_motion_straight_through_region(x, i)`, or the turn opposite the arrow —
      `drv_motion_right_turn_through_region(x, i)` under `green_arrow(left)`,
      `drv_motion_left_turn_through_region(x, i)` under `green_arrow(right)`. The two arrow
      directions are written as two branches (`dirBranch "left"`, `dirBranch "right"`) of one
      shape; the movement concepts read kin.yaw_rate and rel.occupies.
    b1, b5 (trigger, condition): read at x's entry into `i`, reached from the exit through the past
      operator `since (¬ rises occ(x,i)) (rises occ(x,i) ∧ …)`: the latest observation at which
      x's occupancy of `i` began. There a traffic signal `s` shows circular_red and
      green_arrow(dir), and governs either x's approach carrier `c` (a travel region with
      `st_lane_enters(c, i)`) or `i` itself. Facing is x occupying `c` at the observation before
      the entry, as the b5 element states; at the entry, where occ(x,i) has just become true,
      `rises (occ(x,i) ∨ ¬φ)` is exactly φ at the previous observation (`beforeEntry`), so that
      operator reads it.
    b8 (obligation): for the same intersection, arrow direction, signal and carrier (the whole
      selection written again), at the observation before the entry: the wait `H` is x halted
      (`drv_motion_stopped` with p.motion_speed_tolerance) on `c` and not in `i`, and its stretch
      runs from H's latest rise; through it x did not occupy `i` and `s` showed no circular_green
      (`since`), and the event "green_arrow(dir) is out and has lit since the wait began"
      (`since (¬ rises H) (rises arrow)`) rose at least the literal two times since the wait began
      (`Formula.count … .ge 2`). A wait that began before the recording leaves the count unknown.
      Every selected signal and carrier is held to it (a rule never picks the carrier that
      favours the road user).

  Choices the record left open (declared in `narrowings`):
    b8: the stretch of the wait is read up to the observation before the entry, the last at which
      x does not occupy `i`; the entry observation itself belongs to the crossing, not the wait.

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

/-- b8: the text's "two complete cycles" (a count). -/
def twoCompleteCycles : Nat := 2

/-- Quantifier variables: the intersection crossed, the signal, the approach carrier. -/
def vI : Arg := .var "i"
def vS : Arg := .var "s"
def vC : Arg := .var "c"

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.motorcycle, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-135::motorcycle"] [])
    (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-125::moped"] [])
      (.or (.atom "ru_motorcycle" [vX] [])
        (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-025::bicycle"] [])
          (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
            (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-018::electric_scooter"] [])))))

/-- x occupies the intersection `i`. -/
def occI : Formula := .atom "rel_occupies" [vX, vI] []
/-- x occupies the carrier `c`. -/
def occC : Formula := .atom "rel_occupies" [vX, vC] []

/-- At x's entry into `i` (occ(x, i) true here, false at the previous observation): φ at the
    observation before the entry. -/
def beforeEntry (φ : Formula) : Formula := .rises (.or occI (.not φ))

/-- From the exit: φ at x's latest entry into `i`. -/
def atEntry (φ : Formula) : Formula := .since (.not (.rises occI)) (.and (.rises occI) φ)

/-- b6: the crossing of `i` is straight through or a turn opposite the green arrow `dir`. -/
def crossing (dir : String) : Formula :=
  let opposite : Formula :=
    if dir == "left" then
      .derived "drv_motion_right_turn_through_region" [vX, vI]
        [pHeadingSinceStepCarlaSceneGraph, pRightTurnMinAngle, pReversalMinAngle]
    else
      .derived "drv_motion_left_turn_through_region" [vX, vI]
        [pHeadingSinceStepCarlaSceneGraph, pLeftTurnMinAngle, pReversalMinAngle]
  .or (.derived "drv_motion_straight_through_region" [vX, vI]
        [pHeadingSinceStepCarlaSceneGraph, pStraightThroughMaxHeadingChange])
    opposite

/-- The indications of `s`. -/
def shows (ind : String) : Formula := .atom "dev_traffic_signal_shows" [vS, .lit ind] []
def arrow (dir : String) : Formula := shows s!"green_arrow({dir})"

/-- b1, b5, read at the entry: `s` governs x's approach carrier `c` into `i` (occupied at the
    observation before the entry) or `i` itself, and shows circular_red with green_arrow(dir). -/
def selection (dir : String) : Formula :=
  .and (.atom "st_lane_enters" [vC, vI] [])
    (.and (.or (.atom "dev_governs" [vS, vC] []) (.atom "dev_governs" [vS, vI] []))
      (.and (beforeEntry occC)
        (.and (shows "circular_red") (arrow dir))))

/-- Some signal and carrier selected at the entry. -/
def selected (dir : String) : Formula :=
  .existsDevice (.lit "traffic_signal") "s"
    (.existsRegion (.lit "travel_region") "c" (selection dir))

/-- b8: x halted on the approach `c`, not in `i`. -/
def halted : Formula :=
  .and (.derived "drv_motion_stopped" [vX] [pMotionSpeedTolerance])
    (.and occC (.not occI))

/-- b8: one complete cycle ends where green_arrow(dir) is out after having lit since the wait began. -/
def arrowOutAfterLit (dir : String) : Formula :=
  .and (.not (arrow dir)) (.since (.not (.rises halted)) (.rises (arrow dir)))

/-- b8: the wait, read at the observation before the entry. -/
def waited (dir : String) : Formula :=
  .and (.count (arrowOutAfterLit dir) halted .ge twoCompleteCycles)
    (.since (.and (.not occI) (.not (shows "circular_green")))
      (.and (.rises halted) (.not (shows "circular_green"))))

/-- Applicability for one arrow direction, at an intersection `i`. -/
def applies (dir : String) : Formula :=
  .and (crossing dir) (atEntry (selected dir))

/-- Applicability: b1 (trigger): Where the signal is a steady red with a green turn arrow:; b5 (condition): facing the signal; b6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow if:; b9 (condition): because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.or (applies "left") (applies "right"))

/-- The duty for one arrow direction at `i`: every signal and carrier selected at the entry. -/
def dirDuty (dir : String) : Formula :=
  .implies (crossing dir)
    (atEntry
      (.forallDevice (.lit "traffic_signal") "s"
        (.forallRegion (.lit "travel_region") "c"
          (.implies (selection dir) (beforeEntry (waited dir))))))

/-- Obligation: b8 (obligation): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i" (.and (dirDuty "left") (dirDuty "right"))

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
    narrowings :=
      [ { span := "b8"
          why := "The stretch of the wait is read up to the observation before the entry, the last at which the road user does not occupy the intersection; the entry observation itself belongs to the crossing, so the signal's indications there are read only by the applicability."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b_o2
