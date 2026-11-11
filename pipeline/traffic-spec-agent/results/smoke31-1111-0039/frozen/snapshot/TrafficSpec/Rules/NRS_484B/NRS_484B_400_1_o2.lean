/-
  NRS_484B_400_1_o2 — NRS-484B-400-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): If the driver of a vehicle
    e2 (trigger): intends to turn
    e3 (trigger): at an intersection
    e4 (boilerplate): and:
    e5 (trigger): The turn is a right turn,
    e6 (sibling): both the approach for the right turn and the right turn must be made from the right turn lane
    e7 (condition): if the highway has a right turn lane
    e8 (reference): as set forth in subsection 4 of NRS 484B.223 [NRS-484B-223-4a, NRS-484B-223-4b],
    e9 (obligation): or must be made from the extreme right lane.

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e3: atoms ['st.intersection', 'st.lane_enters', 'st.travel_region', 'rel.occupies'], derived ['drv.motion.entering_region']
    e5: atoms ['kin.yaw_rate', 'rel.occupies'], derived ['drv.motion.heading_change_since_entry']
    e7: atoms ['st.highway', 'st.on_way', 'st.turn_lane', 'st.lane_enters', 'st.lane_direction'], derived ['drv.road.opposed_directions'], borrowing ['e8']
    e9: atoms ['st.lane', 'st.lane_adjacency', 'st.lane_enters', 'rel.occupies', 'kin.path_length'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    e8: NRS-484B-223-4a: a single right lane to be used only for turning
    e8: NRS-484B-223-4b: a single right lane to be used only for turning

  How each span is written:
    e1: the binder class `ru_aggregate x DEF-NRS-484A-320::vehicle`; the driver is read through the
        vehicle's controlled motion (the record's observable reading), so no further leaf.
    e5: the right turn in intersection i is recognized at the judged observation: the heading change
        since x's latest entry into i (drv.motion.heading_change_since_entry, step bound the reviewed
        p.heading_since_step_carla_scene_graph) is at most minus p.turn_recognition_angle there and
        was not at the observation before (`rises`).
    e2, e3: the latest entry of x into i (drv.motion.entering_region) is found with `since` (no entry
        since it); at that entry int.turn is declared for x at i, and x's footprint overlaps the
        carrier c it came from (rel.occupies), a travel region (st.travel_region quantifier) that
        enters i (st.lane_enters) and lies on the highway h (st.on_way, st.highway quantifier).
        `not (st_intersection c)` states what st.lane_enters' contract makes a carrier (a lane or a
        kind refining it, or a directed roadway, shoulder or bicycle segment, never an intersection);
        st.lane_enters(c, i) already entails it, but an intersection carries no lane record, so the
        atom is unknown, not false, on an intersection and the conjunct keeps it out of the selection.
    e7 (with e8's borrowed words): read negated, as the record states: no st.turn_lane of side right
        enters i, lies on h and has a designated direction not opposed to c's
        (drv.road.opposed_directions with p.opposed_carriers_cosine).
    e9: at that entry (the same `since` anchor) x's footprint overlaps a st.lane L that enters i, lies
        on h, has a direction not opposed to c's and whose st.lane_adjacency ordinal equals its count;
        and over the path window of p.turn_approach_length behind the entry (holdsFor .path, which
        reads kin.path_length), at every observation at which x occupies a travel region entering i
        it occupies L.
    The obligation restates the whole selection of i, c and h (recognition, entry with the
    declared intention, carrier, highway, absence of a right turn lane) and requires the duty for
    every selected triple (`forallRegion … implies`).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_400_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantifier variables: the intersection, the approach carrier, the highway, a right turn lane,
    the extreme right lane, and a carrier occupied in the approach window. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vH : Arg := .var "h"
def vT : Arg := .var "tl"
def vL : Arg := .var "l"
def vA : Arg := .var "a"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pOpposedCarriersCosine : Term := .param "p.opposed_carriers_cosine"
def pTurnApproachLength : Term := .param "p.turn_approach_length"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e3: x enters i at this observation. -/
def entersI : Formula := .derived "drv_motion_entering_region" [vX, vI] []

/-- e5: x's right turn in i is recognized here: the heading change since its entry into i reaches
    minus the recognition angle here and had not at the observation before. -/
def rightTurnRecognized : Formula :=
  .rises (.cmp (.quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph])
    .le (.neg pTurnRecognitionAngle))

/-- e2, e3: at x's latest entry into i, int.turn was declared for x at i and x's footprint
    overlapped the carrier c. -/
def enteredWithIntentFrom : Formula :=
  .since (.not entersI)
    (.and entersI (.and (.intent "int.turn" vX vI) (.atom "rel_occupies" [vX, vC] [])))

/-- e3: c is an approach carrier of i on the highway h (a carrier is no intersection). -/
def approachCarrier : Formula :=
  .and (.not (.atom "st_intersection" [vC] []))
    (.and (.atom "st_lane_enters" [vC, vI] []) (.atom "st_on_way" [vC, vH] []))

/-- e7 (e8's words): no right turn lane enters i on h with a direction not opposed to c's. -/
def noRightTurnLane : Formula :=
  .not (.existsRegion (.lit "turn_lane") "tl"
    (.and (.atom "st_turn_lane_side" [vT, .lit "right"] [])
      (.and (.atom "st_lane_enters" [vT, vI] [])
        (.and (.atom "st_on_way" [vT, vH] [])
          (.not (.derived "drv_road_opposed_directions" [vT, vC] [pOpposedCarriersCosine]))))))

/-- The record's whole selection of i, c and h (the quantifiers over their kinds bind them). -/
def selection : Formula :=
  .and rightTurnRecognized (.and enteredWithIntentFrom (.and approachCarrier noRightTurnLane))

/-- e9, at the entry: x overlaps an extreme right lane L of the approach, and over the approach
    window it occupies L wherever it occupies a carrier entering i. -/
def extremeRightLane : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and (.atom "st_lane_enters" [vL, vI] [])
      (.and (.atom "st_on_way" [vL, vH] [])
        (.and (.not (.derived "drv_road_opposed_directions" [vL, vC] [pOpposedCarriersCosine]))
          (.and (.cmp (.measure "st_lane_adjacency" [vL, .lit "ordinal"]) .eq
                      (.measure "st_lane_adjacency" [vL, .lit "count"]))
            (.and (.atom "rel_occupies" [vX, vL] [])
              (.holdsFor .path pTurnApproachLength "x"
                (.forallRegion (.lit "travel_region") "a"
                  (.implies
                    (.and (.atom "rel_occupies" [vX, vA] []) (.atom "st_lane_enters" [vA, vI] []))
                    (.atom "rel_occupies" [vX, vL] [])))))))))

/-- Applicability: e2 (trigger): intends to turn; e3 (trigger): at an intersection; e5 (trigger): The turn is a right turn,; e7 (condition): if the highway has a right turn lane -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.existsRegion (.lit "highway") "h" selection))

/-- Obligation: e9 (obligation): or must be made from the extreme right lane. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.forallRegion (.lit "highway") "h"
        (.implies selection (.since (.not entersI) (.and entersI extremeRightLane)))))

def rule : Rule :=
  { id := "NRS_484B_400_1_o2"
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

end TrafficSpec.Rules.NRS_484B_400_1_o2
