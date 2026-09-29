/-
  NRS_484B_213_1 — NRS-484B-213-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (subject): A vehicle
    a2 (obligation): must not be driven to the left side of the center of a two-lane, two-directional highway
    a3 (boilerplate): and
    a4 (trigger): overtaking and passing another vehicle proceeding in the same direction,
    a5 (boilerplate): unless
    a6 (standard): such left side is clearly visible and is free of oncoming traffic for a sufficient distance ahead to permit such overtaking and passing to be completely made
    a7 (standard): without interfering with the safe operation of any vehicle approaching from the opposite direction or any vehicle overtaken.

  Elements (span → atoms, derived):
    a1: atoms ['ru.subject', 'ru.aggregate=vehicle'], derived []
    a2: atoms ['st.centre_line', 'st.roadway', 'st.lane', 'st.lane_adjacency', 'st.lane_direction', 'rel.occupies'], derived []
    a4: atoms ['rel.same_direction', 'ru.aggregate=vehicle'], derived ['drv.overtaking']

  How each span is written:
    a1 — `v` carries `ru.subject` and the aggregate word `vehicle`; `overtaken` carries the word
      alone.
    a4 — the applicability: `rel.same_direction` of the pair and `drv.overtaking` of `v` over
      `overtaken`, both at `p.same_direction_cos`. The concept is engaged only once the overtaken
      vehicle is behind, so the rule speaks from the instant the pass is made.
    a2 — the obligation's antecedent: the subject occupies a roadway (`st.roadway`) and the
      centre line (`st.centre_line`) over it, the overtaken vehicle occupies a lane (`st.lane`),
      and the subject occupies that lane's left neighbour (`st.lane_adjacency` on the side
      `left`) whose `st.lane_direction` opposes it — the two-directional highway. Every region is
      tied to a binder by `rel.occupies`.
    a6 — `drv.sight_distance_adequate` at `p.stopping_decel` and `p.reaction_time`, a visible
      `st.sight_distance` recorded for the lane crossed into, and no user that is `rel.oncoming`
      at `p.oncoming_cos` satisfying `drv.meeting` within `p.ttc_horizon`.
    a7 — `drv.time_to_conflict` with the overtaken vehicle above `p.ttc_bound` and the lateral
      `rel.surface_gap` to it at or above `p.lateral_clearance`.

  CONSEQUENCES of choices the text did not dictate (each is a `residues` entry below):
    1. "two-lane" is not read as a lane count.
    2. "to the left side of the center" is read as the footprint over the centre line while in
       the opposed neighbouring lane.
    3. the sufficient distance is measured at the subject's own speed, not at a meeting pair's
       closing speed.
    4. "clearly visible" is read as a sight distance being recorded at all for that lane.
    5. a7's two bounds are imposed on the overtaken vehicle; the oncoming side of a7 is carried
       by a6's meeting clause.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Rule

namespace TrafficSpec.Rules.NRS_484B_213_1

/-- The binders, as arguments (order and names are the node's). -/
private def vV : Arg := .var "v"
private def vOvertaken : Arg := .var "overtaken"

/-- The quantified variables: a road user, and the regions the antecedent speaks about. -/
private def vOther : Arg := .var "o"
private def vRoadway : Arg := .var "rw"
private def vCentre : Arg := .var "cl"
private def vOwnLane : Arg := .var "lOwn"
private def vOppLane : Arg := .var "lOpp"

/-- The reading's parameters; no value of any of them lives in this file. -/
private def pLateralClearance : Term := .param "p.lateral_clearance"
private def pOncomingCos : Term := .param "p.oncoming_cos"
private def pReactionTime : Term := .param "p.reaction_time"
private def pSameDirectionCos : Term := .param "p.same_direction_cos"
private def pStoppingDecel : Term := .param "p.stopping_decel"
private def pTtcBound : Term := .param "p.ttc_bound"
private def pTtcHorizon : Term := .param "p.ttc_horizon"

private def zeroMetres : Term := .lit Q.zero .metre
private def zeroRatio : Term := .lit Q.zero .ratio

/-- A component of a lane's direction. -/
private def laneDirection (l : Arg) (component : String) : Term :=
  .measure "st_lane_direction" [l, .lit component]

/-- The two lanes carry traffic the opposite way: their directions point against each other. -/
private def opposedDirections (a b : Arg) : Formula :=
  .cmp (.add (.mul (laneDirection a "x") (laneDirection b "x"))
             (.mul (laneDirection a "y") (laneDirection b "y")))
       .lt zeroRatio

/-- Class of `v`: ru.subject, ru.aggregate=vehicle -/
private def clsV : Formula :=
  .and (.atom "ru_subject" [vV] []) (.atom "ru_aggregate" [vV, .lit "vehicle"] [])
/-- Class of `overtaken`: ru.aggregate=vehicle -/
private def clsOvertaken : Formula := .atom "ru_aggregate" [vOvertaken, .lit "vehicle"] []

/-- Applicability: a4 (trigger): overtaking and passing another vehicle proceeding in the same direction, -/
private def applicability : Formula :=
  .and (.atom "rel_same_direction" [vV, vOvertaken] [pSameDirectionCos])
       (.derived "drv_overtaking" [vV, vOvertaken] [pSameDirectionCos])

/-- a6, first limb: the left side is clearly visible for the distance the pass needs. -/
private def visibleFarEnough : Formula :=
  .and (.derived "drv_sight_distance_adequate" [vV] [pStoppingDecel, pReactionTime])
       (.cmp (.measure "st_sight_distance" [vOppLane]) .gt zeroMetres)

/-- a6, second limb: no oncoming user is met within the horizon. -/
private def freeOfOncoming : Formula :=
  .forallUser "o"
    (.implies (.atom "rel_oncoming" [vV, vOther] [pOncomingCos])
              (.not (.derived "drv_meeting" [vV, vOther] [pTtcHorizon, pOncomingCos])))

/-- a7: the overtaken vehicle's safe operation is not interfered with. -/
private def noInterference : Formula :=
  .and (.cmp (.quantity "drv_time_to_conflict" [vV, vOvertaken] [pTtcHorizon]) .gt pTtcBound)
       (.cmp (.measure "rel_surface_gap" [vV, vOvertaken, .lit "lateral"]) .ge pLateralClearance)

/-- Obligation: a2 (obligation): must not be driven to the left side of the center of a two-lane, two-directional highway; a6 (standard): such left side is clearly visible and is free of oncoming traffic for a sufficient distance ahead to permit such overtaking and passing to be completely made; a7 (standard): without interfering with the safe operation of any vehicle approaching from the opposite direction or any vehicle overtaken. -/
private def obligation : Formula :=
  .forallRegion .roadway "rw"
    (.implies (.and (.atom "st_roadway" [vRoadway] []) (.atom "rel_occupies" [vV, vRoadway] []))
      (.forallRegion .centreLine "cl"
        (.implies (.and (.atom "st_centre_line" [vCentre] [])
                        (.atom "rel_occupies" [vV, vCentre] []))
          (.forallRegion .lane "lOwn"
            (.implies (.and (.atom "st_lane" [vOwnLane] [])
                            (.atom "rel_occupies" [vOvertaken, vOwnLane] []))
              (.forallRegion .lane "lOpp"
                (.implies
                  (.and (.atom "st_lane_adjacency" [vOwnLane, .lit "left", vOppLane] [])
                    (.and (.atom "rel_occupies" [vV, vOppLane] [])
                          (opposedDirections vOwnLane vOppLane)))
                  (.and (.and visibleFarEnough freeOfOncoming) noInterference))))))))

def rule : Rule :=
  { id := "NRS_484B_213_1"
    laws := ["NRS-484B-213-1"]
    binders :=
      [ { name := "v", cls := clsV }
      , { name := "overtaken", cls := clsOvertaken } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "clearly visible and free of oncoming traffic for a sufficient distance ahead to permit the pass to be completely made"
          concepts := ["drv.meeting", "drv.sight_distance_adequate", "rel.oncoming", "st.sight_distance"]
          params := ["p.stopping_decel", "p.reaction_time", "p.oncoming_cos", "p.ttc_horizon"]
          convention := "The table's pairing for 'clearly visible for a sufficient distance; view obstructed': `drv.sight_distance_adequate` at the subject's speed, its model being the passing-sight-distance reading of the stopping-distance model (`p.stopping_decel`, `p.reaction_time`) applied to the closing speed of a meeting pair, so the visible `st.sight_distance` covers the whole manoeuvre; 'free of oncoming traffic' is that no user with `rel.oncoming` (heading cosine of opposition at least `p.oncoming_cos`) satisfies `drv.meeting` within the horizon `p.ttc_horizon`."
          surrogate := false }
      , { standard := "without interfering with the safe operation of any vehicle approaching from the opposite direction or any vehicle overtaken"
          concepts := ["drv.time_to_conflict", "rel.surface_gap"]
          params := ["p.ttc_bound", "p.lateral_clearance"]
          convention := "The table's pairing for 'with safety (of a pass)': `drv.time_to_conflict` with every affected user — each oncoming vehicle and the overtaken vehicle — stays above `p.ttc_bound` (conflict-analysis convention) and the lateral `rel.surface_gap` to each stays at or above `p.lateral_clearance`."
          surrogate := false } ]
    residues :=
      [ "The text's 'two-lane' is not read as a lane count: the rule asks only that the lane the overtaken vehicle occupies have a left neighbour running the opposite way, so a two-directional highway of more than one lane each way is not excluded."
      , "'Driven to the left side of the center' is read as the subject's footprint occupying the centre-line region while it occupies that opposed left neighbour lane; a subject wholly inside the opposing lane, its body no longer over the line, falls outside the obligation's antecedent."
      , "The sufficient distance is measured at the subject's own speed: `drv.sight_distance_adequate` takes one track, so the closing speed of a meeting pair the convention names is not what the bound uses, and the bound is weaker than the passing-sight-distance model."
      , "'Clearly visible' is read as a sight distance being recorded at all for the lane crossed into; how clear the view along it is beyond that is not captured."
      , "a7's two bounds are imposed on the overtaken vehicle. For a vehicle approaching from the opposite direction the interference bound is carried by a6: `p.ttc_bound` lies below `p.ttc_horizon`, so an oncoming user whose time to conflict is under the bound is necessarily one `drv.meeting` reports. `p.lateral_clearance` is not asked of an oncoming vehicle, which met head-on in the borrowed lane can never give it."
      ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_213_1
