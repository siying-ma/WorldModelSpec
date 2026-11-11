/-
  NRS_484B_400_1_o1 — NRS-484B-400-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): If the driver of a vehicle
    e2 (trigger): intends to turn
    e3 (trigger): at an intersection
    e4 (boilerplate): and:
    e5 (trigger): The turn is a right turn,
    e6 (obligation): both the approach for the right turn and the right turn must be made from the right turn lane
    e7 (condition): if the highway has a right turn lane
    e8 (reference): as set forth in subsection 4 of NRS 484B.223 [NRS-484B-223-4a, NRS-484B-223-4b],
    e9 (sibling): or must be made from the extreme right lane.

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e3: atoms ['st.intersection', 'st.lane_enters', 'st.travel_region', 'rel.occupies'], derived ['drv.motion.entering_region']
    e5: atoms ['kin.yaw_rate', 'rel.occupies'], derived ['drv.motion.heading_change_since_entry']
    e6: atoms ['rel.occupies', 'st.turn_lane', 'st.lane_enters', 'st.intersection', 'kin.path_length'], derived []
    e7: atoms ['st.highway', 'st.on_way', 'st.turn_lane', 'st.lane_enters', 'st.lane_direction'], derived ['drv.road.opposed_directions'], borrowing ['e8']

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    e8: NRS-484B-223-4a: a single right lane to be used only for turning
    e8: NRS-484B-223-4b: a single right lane to be used only for turning

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pOpposedCarriersCosine : Term := .param "p.opposed_carriers_cosine"
def pTurnApproachLength : Term := .param "p.turn_approach_length"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    e1: `ru_aggregate x DEF-NRS-484A-320::vehicle`; the driver is read through the vehicle's
        controlled motion (the record's observable reading), so x is the vehicle itself.
    e3: the intersection i is a region of kind `intersection`; x's entry into it is
        `drv_motion_entering_region x i`; the carrier x entered from is a region c of kind
        `travel_region` that x occupies at that entry and whose entrance end is i (`st_lane_enters c i`);
        c is not i itself (`not (same c i)`): the words' carrier x entered i from is never the
        intersection, which is a travel region too, and on which `st_lane_enters` and
        `st_lane_direction` are unrecorded rather than false.
    e5: the right turn is recognized at the observation at which the heading change since x's latest
        entry into i (`drv_motion_heading_change_since_entry x i`, step the run's reviewed sampling
        parameter) first reaches minus `p.turn_recognition_angle` (`rises`).
    e2: `intent int.turn x i`, read at the observation of that entry, through `since`: the latest
        observation at which x entered i, with no entry since.
    e7 (borrowing e8): some region r of kind `turn_lane`, side right (`st_turn_lane_side r right`),
        entering i (`st_lane_enters r i`), on the highway h (kind `highway`) the carrier c lies on
        (`st_on_way c h`, `st_on_way r h`), whose direction is not opposed to c's
        (`not drv_road_opposed_directions r c` with `p.opposed_carriers_cosine`).
    e6: at the entry, x occupies such an r, and at every observation of the path window of length
        `p.turn_approach_length` behind the entry (`holdsFor .path`, read at the entry inside
        `since`) at which x occupies some travel region entering i, it occupies that r.
  The obligation repeats the applicability's whole selection of i, c, h and r (rule 3c) and keeps
  the record's choice among the qualifying turn lanes (an existential over r).
  No choice beyond the record's own reading was made: the obligation is the record's words.
-/

def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vH : Arg := .var "h"
def vR : Arg := .var "r"
def vA : Arg := .var "a"

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e3: x enters intersection i at the observation. -/
def entersI : Formula := .derived "drv_motion_entering_region" [vX, vI] []

/-- e5: the right turn in i is recognized here: the heading change since the entry reaches minus the
    recognition angle here and did not at the observation before. -/
def rightTurnRecognized : Formula :=
  .rises (.cmp (.quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph])
    .le (.neg pTurnRecognitionAngle))

/-- e6: the approach, the path window behind the entry: wherever x occupies a carrier entering i,
    it occupies r. -/
def approachFromR : Formula :=
  .holdsFor .path pTurnApproachLength "x"
    (.implies
      (.existsRegion (.lit "travel_region") "a"
        (.and (.atom "st_lane_enters" [vA, vI] []) (.atom "rel_occupies" [vX, vA] [])))
      (.atom "rel_occupies" [vX, vR] []))

/-- e7 (e8): a right turn lane r of highway h entering i, serving the direction of c; `body` is what
    the obligation adds about r. -/
def rightTurnLane (body : Formula) : Formula :=
  .existsRegion (.lit "turn_lane") "r"
    (.and (.atom "st_turn_lane_side" [vR, .lit "right"] [])
      (.and (.atom "st_lane_enters" [vR, vI] [])
        (.and (.atom "st_on_way" [vR, vH] [])
          (.and (.not (.derived "drv_road_opposed_directions" [vR, vC] [pOpposedCarriersCosine]))
            body))))

/-- At the entry into i: e2's declared intention, the carrier c x entered from (e3) lying on
    highway h, and e7's right turn lane. -/
def atEntry (body : Formula) : Formula :=
  .and entersI
    (.and (.intent "int.turn" vX vI)
      (.existsRegion (.lit "travel_region") "c"
        (.and (.not (.same vC vI))
        (.and (.atom "st_lane_enters" [vC, vI] [])
          (.and (.atom "rel_occupies" [vX, vC] [])
            (.existsRegion (.lit "highway") "h"
              (.and (.atom "st_on_way" [vC, vH] []) (rightTurnLane body))))))))

/-- The selection, with `body` at r: the right turn recognized here in i, read back to x's latest
    entry into i. -/
def selection (body : Formula) : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and rightTurnRecognized (.since (.not entersI) (atEntry body)))

/-- Applicability: e2 (trigger): intends to turn; e3 (trigger): at an intersection; e5 (trigger): The turn is a right turn,; e7 (condition): if the highway has a right turn lane -/
def applicability : Formula := selection .tt

/-- Obligation: e6 (obligation): both the approach for the right turn and the right turn must be made from the right turn lane -/
def obligation : Formula :=
  selection (.and (.atom "rel_occupies" [vX, vR] []) approachFromR)

def rule : Rule :=
  { id := "NRS_484B_400_1_o1"
    laws := ["NRS-484B-400-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.turn"]
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_400_1_o1
