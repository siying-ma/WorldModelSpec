/-
  NRS_484B_307_9b_o1 — NRS-484B-307-9b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (trigger): Where the signal is a steady red with a green turn arrow:
    b2 (subject): A person driving a motorcycle,
    b3 (subject): moped or trimobile
    b4 (subject): or riding a bicycle, an electric bicycle or an electric scooter
    b5 (condition): facing the signal
    b6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow if:
    b7 (obligation): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;
    b8 (sibling): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change
    b9 (sibling): because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;
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
    b7: atoms ['prim.region_offset_along', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.lane_enters', 'st.region_geometry', 'st.stop_line', 'st.travel_region'], derived ['drv.motion.stopped']

  How each span is written.
    Judged instant: the exit of x from an intersection i (the movement concepts hold only there).
    b2–b4 (subject): `clsX` is the disjunction of the five admitted aggregates and ru_motorcycle
      (the trimobile the record maps to it), each as claimed.
    b6 (trigger): straight_through_region(x, i) with either arrow; right_turn_through_region(x, i)
      with green_arrow(left); left_turn_through_region(x, i) with green_arrow(right). Step bound
      p.heading_since_step_carla_scene_graph, angles as the record names them.
    b1/b5 (trigger, condition): `atEntry i φ` reads φ at x's latest entry into i (the latest rise of
      rel_occupies(x, i)), `since (¬ rises occ_i) (rises occ_i ∧ φ)`. There some traffic signal s
      shows circular_red and green_arrow(dir) and either governs i, or governs a travel region c with
      st_lane_enters(c, i) that x occupied at the observation before the entry
      (`beforeEntry i φ` = `since occ_i (¬occ_i ∧ φ)`, which, read at the entry, is φ one observation
      earlier).
    b7 (obligation): at the exit, for every intersection i selected as in the applicability (the
      whole selection written again), at the entry, for every travel region c with
      st_lane_enters(c, i) occupied at the observation before the entry, `haltFound` holds there:
      `since (¬ searchEnd) halt`, a halt found before the search ends.
      - place: the stop line recorded as marking c (st_entrance_of(l, c)); else (no stop line marks
        c) the crosswalk recorded as marking c; else i itself. An unobserved association leaves the
        "else" unknown, so the place is unknown where it matters.
      - halt: drv.motion.stopped (p.motion_speed_tolerance), x on c, body within
        p.stop_point_tolerance of the mark (st_region_geometry_distance) and not beyond it along c
        (prim_region_offset_along ≥ 0); for the crosswalk and intersection places, x not occupying
        the mark.
      - searchEnd: the approach start — x on c, off the mark, short of it (offset > 0) and farther
        than p.stop_point_tolerance from it — or a previous entry into i (a rise of rel_occupies(x, i)
        at or before the observation before the current entry). `since` carries the unobserved past
        as unknown, so a search reaching the recording's start without either end is unknown.

  Choices the record left open (declared as narrowings):
    - b7: where x occupied several approach carriers into i before entering, the halt is required at
      the place of each (∀ c), not "unknown where the verdicts differ".
    - b7: the approach start is read on c itself (the carrier the mark marks for this approach),
      not on any other carrier the same mark is recorded as marking.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLeftTurnMinAngle : Term := .param "p.left_turn_min_angle"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pReversalMinAngle : Term := .param "p.reversal_min_angle"
def pRightTurnMinAngle : Term := .param "p.right_turn_min_angle"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pStraightThroughMaxHeadingChange : Term := .param "p.straight_through_max_heading_change"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables: the intersection, the approach carrier, the signal, the marks. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"
def vL : Arg := .var "l"
def vW : Arg := .var "w"

def aggregate (id : String) : Formula := .atom "ru_aggregate" [vX, .lit id] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.motorcycle, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (aggregate "DEF-NRS-484A-135::motorcycle")
    (.or (aggregate "DEF-NRS-484A-125::moped")
      (.or (.atom "ru_motorcycle" [vX] [])
        (.or (aggregate "DEF-NRS-484A-025::bicycle")
          (.or (aggregate "DEF-NRS-484B-017::electric_bicycle")
            (aggregate "DEF-NRS-484B-018::electric_scooter")))))

/-- x's footprint overlaps region `r`. -/
def occ (r : Arg) : Formula := .atom "rel_occupies" [vX, r] []

/-- x enters `i` here: the overlap with `i` becomes true. -/
def entered (i : Arg) : Formula := .rises (occ i)

/-- Read at an entry into `i`: φ at the observation before it. -/
def beforeEntry (i : Arg) (φ : Formula) : Formula := .since (occ i) (.and (.not (occ i)) φ)

/-- Read at an exit from `i`: φ at x's latest entry into `i`. -/
def atEntry (i : Arg) (φ : Formula) : Formula := .since (.not (entered i)) (.and (entered i) φ)

/-- b1: signal `s` displays the steady red together with a green arrow to `dir`. -/
def redWithArrow (s : Arg) (dir : String) : Formula :=
  .and (.atom "dev_traffic_signal_shows" [s, .lit "circular_red"] [])
    (.atom "dev_traffic_signal_shows" [s, .lit s!"green_arrow({dir})"] [])

/-- b5: signal `s` faces x as it enters `i`: it governs `i`, or the approach carrier into `i` x
    occupied at the observation before the entry. -/
def facing (s i : Arg) : Formula :=
  .or (.atom "dev_governs" [s, i] [])
    (.existsRegion (.lit "travel_region") "c"
      (.and (beforeEntry i (occ vC))
        (.and (.atom "st_lane_enters" [vC, i] []) (.atom "dev_governs" [s, vC] []))))

/-- b1 + b5, read at the entry into `i`: a traffic signal facing x shows red with a green `dir` arrow. -/
def signalAtEntry (dir : String) : Formula :=
  .existsDevice (.lit "traffic_signal") "s" (.and (facing vS vI) (redWithArrow vS dir))

def straightThrough : Formula :=
  .derived "drv_motion_straight_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pStraightThroughMaxHeadingChange]
def leftTurn : Formula :=
  .derived "drv_motion_left_turn_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pLeftTurnMinAngle, pReversalMinAngle]
def rightTurn : Formula :=
  .derived "drv_motion_right_turn_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pRightTurnMinAngle, pReversalMinAngle]

/-- b1, b5, b6: the intersection `i` x leaves here, having entered it on red with a green arrow and
    gone straight through or turned opposite the arrow. -/
def selection : Formula :=
  .or (.and straightThrough (atEntry vI (.or (signalAtEntry "left") (signalAtEntry "right"))))
    (.or (.and rightTurn (atEntry vI (signalAtEntry "left")))
      (.and leftTurn (atEntry vI (signalAtEntry "right"))))

/-- Applicability: b1 (trigger): Where the signal is a steady red with a green turn arrow:; b5 (condition): facing the signal; b6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow if: -/
def applicability : Formula := .existsRegion (.lit "intersection") "i" selection

-- b7: the place on the approach carrier `c`, and the halt.

/-- Body-to-mark distance and the reference point's offset to the mark along c's direction. -/
def markDistance (mk : Arg) : Term := .measure "st_region_geometry_distance" [vX, mk]
def markOffset (mk : Arg) : Term := .quantity "prim_region_offset_along" [vX, mk, vC] []

/-- Within the stop-point tolerance of the mark and not beyond it. -/
def atMark (mk : Arg) : Formula :=
  .and (.cmp (markDistance mk) .le pStopPointTolerance) (.cmp (markOffset mk) .ge zeroMetres)

/-- Outside the mark's stopping zone upstream: off it, short of it, farther than the tolerance. -/
def upstreamOf (mk : Arg) : Formula :=
  .and (.not (occ mk))
    (.and (.cmp (markOffset mk) .gt zeroMetres) (.cmp (markDistance mk) .gt pStopPointTolerance))

/-- The mark is recorded as marking c's entrance. -/
def marksC (mk : Arg) : Formula := .atom "st_entrance_of" [mk, vC] []

def hasStopLine : Formula := .existsRegion (.lit "stop_line") "l" (marksC vL)
def hasCrosswalk : Formula := .existsRegion (.lit "crosswalk") "w" (marksC vW)

/-- φ at the governing place, in the words' order: the stop line marking c; failing one, the
    crosswalk marking c; failing both, the intersection. -/
def atPlace (onLine onCrosswalk onJunction : Arg → Formula) : Formula :=
  .or (.existsRegion (.lit "stop_line") "l" (.and (marksC vL) (onLine vL)))
    (.and (.not hasStopLine)
      (.or (.existsRegion (.lit "crosswalk") "w" (.and (marksC vW) (onCrosswalk vW)))
        (.and (.not hasCrosswalk) (onJunction vI))))

def stopped : Formula := .derived "drv_motion_stopped" [vX] [pMotionSpeedTolerance]

/-- x halted on c at the place. -/
def halt : Formula :=
  .and stopped
    (.and (occ vC)
      (atPlace atMark (fun mk => .and (atMark mk) (.not (occ mk))) (fun mk => .and (atMark mk) (.not (occ mk)))))

/-- The approach start, or a previous entry into i: where the search for a halt ends. -/
def searchEnd : Formula :=
  .or (.and (occ vC) (atPlace upstreamOf upstreamOf upstreamOf)) (entered vI)

/-- A halt since the search's end; unknown where the recording begins before either end. -/
def haltFound : Formula := .since (.not searchEnd) halt

/-- Read at the entry into i: for each approach carrier c into i x occupied at the observation
    before, a halt was found there. -/
def duty : Formula :=
  .forallRegion (.lit "travel_region") "c"
    (beforeEntry vI (.implies (.and (occ vC) (.atom "st_lane_enters" [vC, vI] [])) haltFound))

/-- Obligation: b7 (obligation): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection; -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i" (.implies selection (atEntry vI duty))

def rule : Rule :=
  { id := "NRS_484B_307_9b_o1"
    laws := ["NRS-484B-307-9b"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "b7"
          why := "Where x occupied several approach carriers into the intersection at the observation before its entry, the halt is required at the place of each carrier, rather than leaving the verdict unknown where the carriers' places give different verdicts."
          kind := "reading" }
      , { span := "b7"
          why := "The approach start that ends the search for a halt is read on the approach carrier itself (the carrier the mark is recorded as marking for this approach), not on another carrier the same mark is recorded as marking."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b_o1
