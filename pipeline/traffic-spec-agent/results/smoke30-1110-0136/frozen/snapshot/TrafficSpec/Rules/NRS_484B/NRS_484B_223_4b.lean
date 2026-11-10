/-
  NRS_484B_223_4b — NRS-484B-223-4b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): If a highway has been designed to provide a single right lane to be used only for turning
    s2 (subject): a vehicle
    s3 (obligation): must: While being driven in the right turn lane, not travel through an intersection

  Elements (span → atoms, derived):
    s1: atoms ['st.turn_lane', 'st.lane_adjacency', 'st.highway', 'st.on_way', 'rel.occupies'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.turn_lane', 'rel.occupies', 'st.lane_enters', 'st.intersection'], derived ['drv.motion.straight_through_region']

  How each span is written:
    s2: `ru_aggregate(x, DEF-NRS-484A-320::vehicle)`, the class of the binder.
    s1: some highway h with `rel_occupies(x, h)`, and on it (`st_on_way(l, h)`) some turn lane l
        (`existsRegion turn_lane`) whose side is right (`st_turn_lane_side`), whose ordinal equals
        the count of lanes in its direction (`st_lane_adjacency` ordinal / count: the rightmost),
        and no right turn lane m is its left neighbour (`st_lane_adjacency(l, left, m)`): the
        single right turn lane. Read at recognition (the occasion's `s1: at_recognition`), as the
        applicability is read at every judged observation.
    s3: the obligation re-binds l with the whole s1 selection (`singleRightTurnLane`, the highway
        x occupies included) and forbids, for an intersection i the lane runs into
        (`st_lane_enters(l, i)`), the straight crossing of i judged once at its recognition:
        `rises (drv_motion_straight_through_region(x, i))`, the exit with a heading change since
        entry below `p.straight_through_max_heading_change`, integrated with step bound
        `p.heading_since_step_carla_scene_graph`. "While being driven in the right turn lane" is
        `since (not (rises (rel_occupies(x, i)))) (rel_occupies(x, l))`: the footprint overlapped
        l at some observation from the latest entry into i (the onset, where `rel_occupies(x, i)`
        last rose) to the exit; the search into the past ends at that entry and nowhere else.

  Choices the record left open: none beyond the nesting order (the highway quantifier encloses
  the lane quantifier, as the record's applicability states it); no narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_4b

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantifier variables: the highway, the right turn lane, its left neighbour, the intersection. -/
def vH : Arg := .var "h"
def vL : Arg := .var "l"
def vM : Arg := .var "m"
def vI : Arg := .var "i"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pStraightThroughMaxHeadingChange : Term := .param "p.straight_through_max_heading_change"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: turn lane `l` (bound by the caller) is the single right turn lane of highway `h`: its side is
    right, it lies on `h`, it is the rightmost lane of its direction, and its left neighbour of the
    same direction is not a right turn lane. -/
def singleRightTurnLane : Formula :=
  .and (.atom "st_turn_lane_side" [vL, .lit "right"] [])
    (.and (.atom "st_on_way" [vL, vH] [])
      (.and (.cmp (.measure "st_lane_adjacency" [vL, .lit "ordinal"]) .eq
                  (.measure "st_lane_adjacency" [vL, .lit "count"]))
        (.not (.existsRegion (.lit "turn_lane") "m"
          (.and (.atom "st_lane_adjacency" [vL, .lit "left", vM] [])
                (.atom "st_turn_lane_side" [vM, .lit "right"] []))))))

/-- s3: x leaves intersection `i` straight (recognized at the exit), having occupied lane `l` at some
    observation since its latest entry into `i`. -/
def straightThroughOutOfLane : Formula :=
  .and (.rises (.derived "drv_motion_straight_through_region" [vX, vI]
                  [pHeadingSinceStepCarlaSceneGraph, pStraightThroughMaxHeadingChange]))
    (.since (.not (.rises (.atom "rel_occupies" [vX, vI] [])))
            (.atom "rel_occupies" [vX, vL] []))

/-- Applicability: s1 (condition): If a highway has been designed to provide a single right lane to be used only for turning -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vX, vH] [])
      (.existsRegion (.lit "turn_lane") "l" singleRightTurnLane))

/-- Obligation: s3 (obligation): must: While being driven in the right turn lane, not travel through an intersection -/
def obligation : Formula :=
  .not (.existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vX, vH] [])
      (.existsRegion (.lit "turn_lane") "l"
        (.and singleRightTurnLane
          (.existsRegion (.lit "intersection") "i"
            (.and (.atom "st_lane_enters" [vL, vI] []) straightThroughOutOfLane))))))

def rule : Rule :=
  { id := "NRS_484B_223_4b"
    laws := ["NRS-484B-223-4b"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_4b
