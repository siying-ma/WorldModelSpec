/-
  NRS_484B_250_1 — NRS-484B-250-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): approaching an intersection
    s3 (obligation): shall yield the right-of-way
    s4 (condition): to a vehicle which has entered the intersection from a different highway.
    s5 (reference): Except as otherwise provided in subsection 4 [NRS-484B-250-4],
    s6 (exception): this section does not apply at intersections controlled by official traffic-control devices
    s7 (exception): or to vehicles approaching each other from opposite directions,
    s8 (exception): when the driver of one of the vehicles is intending to
    s9 (exception): or is making a left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived ['drv.motion.entering_region']
    s3: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.on_way', 'st.highway'], derived ['drv.motion.entering_region']
    s6: atoms ['dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s7: atoms ['st.lane_enters', 'st.travel_region', 'rel.occupies'], derived ['drv.road.opposed_directions', 'drv.motion.entering_region']
    s9: atoms ['kin.yaw_rate', 'rel.occupies'], derived ['drv.motion.heading_change_since_entry']

  Compositions (span → node, as, map):
    s5: NRS_484B_250_4_o1 as unless map {'x': 'x'} scopes s6

  How each span is written:
    s1: the class of x is `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s2: `approach i c` — x enters intersection i at this observation (drv_motion_entering_region x i)
        and occupies a travel region c (rel_occupies x c) whose entrance end is i (st_lane_enters c i).
    s6 + s5: `deviceException i c` — a traffic signal, stop sign or yield sign governs i or c
        (dev_governs), conjoined with `.not (.ruleApplies NRS_484B_250_4_o1 {x ↦ x})` (as `unless`,
        scoping s6 only). A carrier is `selected` where `approach` holds and the device exception
        does not; the applicability is: some intersection and some carrier are selected.
    s3: the obligation re-selects every (i, c) with the record's whole selection of the carrier
        (`approach`: x's entry into i, rel_occupies x c, st_lane_enters c i) and requires at each
        that no vehicle y owed precedence occupies i. The device exception is not repeated there:
        it decides whether the duty applies (the applicability), not which carrier is judged.
    s4: y owed precedence: y is not x, is a vehicle, occupies i, and for some travel region c2,
        `since (rel_occupies y i) (entering y i ∧ rel_occupies y c2 ∧ st_lane_enters c2 i)` — y has
        occupied i at every observation since its latest entry, at which it occupied approach c2 —
        and c2 lies on a highway h2 (st_on_way c2 h2) on which c does not lie. An entry before the
        recording leaves `since` unknown, as the record states.
    s7–s9: the pair exception is evaluated at the judged observation: opposed designated directions
        of c and c2 (drv_road_opposed_directions, p.opposed_carriers_cosine) and (int.left_turn of x
        at i, or of y at i, or the heading change of x or of y since entry into i
        (drv_motion_heading_change_since_entry, step p.heading_since_step_carla_scene_graph) at
        least p.turn_recognition_angle).

  Choices the record left open:
    - The carriers c, c1 and c2 range over travel regions, a kind the intersection refines; the
      intersection is not an approach to itself, but Core reads `st_lane_enters i i` as unknown (an
      intersection carries no lane record). Each carrier is therefore stated distinct from the
      intersection (`.not (.same c i)`), which `st_lane_enters c i` already entails by its contract
      ("the intersection region a directed approach carrier runs into"); without it every verdict
      that a carrier decides would be unknown through the intersection standing in as its own
      approach. No region the record selects is excluded by it.
    - Where x occupies several approaches entering i, the duty applies where one of them is not
      covered by the device exception, and is then judged through each of them (`forallRegion`): a
      violation through one of them is a violation; the rule never picks the favourable carrier.
      The record asks for unknown where the verdicts differ; that is not expressible robustly while
      the intersection itself is a travel region with an undecided entrance (see above).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantified variables. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vY : Arg := .var "y"
def vC2 : Arg := .var "c2"
def vH2 : Arg := .var "h2"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pOpposedCarriersCosine : Term := .param "p.opposed_carriers_cosine"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

def vehicle (u : Arg) : Formula := .atom "ru_aggregate" [u, .lit "DEF-NRS-484A-320::vehicle"] []
def occupies (u r : Arg) : Formula := .atom "rel_occupies" [u, r] []
def entering (u r : Arg) : Formula := .derived "drv_motion_entering_region" [u, r] []
def laneEnters (c i : Arg) : Formula := .atom "st_lane_enters" [c, i] []
def governs (d r : Arg) : Formula := .atom "dev_governs" [d, r] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle vX

/-- s2: x enters i at this observation from an approach carrier c it occupies. -/
def approach : Formula :=
  .and (entering vX vI)
    (.and (occupies vX vC) (.and (.not (.same vC vI)) (laneEnters vC vI)))

/-- s6: a device of `kind` governs i or c. -/
def controlledBy (kind var : String) : Formula :=
  .existsDevice (.lit kind) var (.or (governs (.var var) vI) (governs (.var var) vC))

/-- s6, with s5 as `unless`: the device exception does not hold where NRS_484B_250_4_o1 applies. -/
def deviceException : Formula :=
  .and
    (.or (controlledBy "traffic_signal" "d1")
      (.or (controlledBy "stop_sign" "d2") (controlledBy "yield_sign" "d3")))
    (.not (.ruleApplies "NRS_484B_250_4_o1" [("x", "x")]))

/-- The pair (i, c) through which the duty applies. -/
def selected : Formula := .and approach (.not deviceException)

/-- s9: road user `u` is making a left turn at i. -/
def makingLeftTurn (u : Arg) : Formula :=
  .cmp (.quantity "drv_motion_heading_change_since_entry" [u, vI] [pHeadingSinceStepCarlaSceneGraph])
    .ge pTurnRecognitionAngle

/-- s7–s9: approaching from opposite directions, one intending or making a left turn. -/
def pairException : Formula :=
  .and (.derived "drv_road_opposed_directions" [vC, vC2] [pOpposedCarriersCosine])
    (.or (.intent "int.left_turn" vX vI)
      (.or (.intent "int.left_turn" vY vI)
        (.or (makingLeftTurn vX) (makingLeftTurn vY))))

/-- s4: y has occupied i since its latest entry, made from c2, which lies on a highway c does not. -/
def enteredFromDifferentHighway : Formula :=
  .existsRegion (.lit "travel_region") "c2"
    (.and
      (.since (occupies vY vI)
        (.and (entering vY vI) (.and (occupies vY vC2) (laneEnters vC2 vI))))
      (.and (.not (.same vC2 vI))
        (.and
          (.existsRegion (.lit "highway") "h2"
            (.and (.atom "st_on_way" [vC2, vH2] []) (.not (.atom "st_on_way" [vC, vH2] []))))
          (.not pairException))))

/-- s4: a vehicle y other than x, in i, owed precedence. -/
def owedPrecedence : Formula :=
  .and (.not (.same vY vX))
    (.and (vehicle vY) (.and (occupies vY vI) enteredFromDifferentHighway))

/-- Applicability: s2 (trigger): approaching an intersection; s4 (condition): to a vehicle which has entered the intersection from a different highway.; s6 (exception): this section does not apply at intersections controlled by official traffic-control devices; s7 (exception): or to vehicles approaching each other from opposite directions,; s8 (exception): when the driver of one of the vehicles is intending to; s9 (exception): or is making a left turn. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" selected)

/-- Obligation: s3 (obligation): shall yield the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.implies approach (.not (.existsUser "y" owedPrecedence))))

def rule : Rule :=
  { id := "NRS_484B_250_1"
    laws := ["NRS-484B-250-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations := []
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_1
