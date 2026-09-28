/-
  NRS_484B_207_1_o1 — NRS-484B-207-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (subject): The driver of a vehicle
    t2 (trigger): overtaking another vehicle proceeding in the same direction
    t3 (obligation): shall pass to the left thereof
    t4 (standard): at a safe distance
    t5 (boilerplate): and
    t6 (sibling): shall not again drive to the right side of the highway
    t7 (sibling): until safely clear of the overtaken vehicle.

  Elements (span → atoms, derived):
    t1: atoms ['ru.subject', 'ru.aggregate=driver'], derived []
    t2: atoms ['rel.same_direction', 'ru.aggregate=vehicle'], derived ['drv.overtaking']
    t3: atoms ['rel.bearing'], derived ['drv.passing_side']

  How each span is written:
    t1  `clsD`: the subject of the scene, a member of the aggregate word 'driver'.
    t2  `applicability`: `drv.overtaking` of the subject over the overtaken body, with
        `rel.same_direction` stated beside it as the trigger's own words. The concept is true only
        once the overtaken body, earlier ahead, is behind: the rule judges a completed pass.
    t3  `passedLeft`: `drv.passing_side` names the side the *overtaken* body was on while the
        bodies overlapped, so "pass to the left thereof" is that body on the subject's right.
        `rel.bearing` is the same observable read directly, as the anchor of t4's window: the last
        instant at which the overtaken body was ahead is where the pass begins.
    t4  `clearanceThroughPass`, `headwayAfterPass`, `timeToConflictAbove`: the three bounds of the
        operationalization. The overlap the clearance bound speaks of is read off the longitudinal
        component of `rel.surface_gap` (at or below zero); the clearance bound is required at every
        instant since the overtaken body was last ahead, the headway is required to be reached at
        some instant of the episode, and the time to conflict at the instants the rule engages.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Rule

namespace TrafficSpec.Rules.NRS_484B_207_1_o1

/-- The binders, as arguments (order and names are the node's). -/
private def vD : Arg := .var "d"
private def vOvertaken : Arg := .var "overtaken"

/-- The reading's parameters; no value of any of them lives in this file. -/
private def pHeadway : Term := .param "p.headway"
private def pLateralClearance : Term := .param "p.lateral_clearance"
private def pSameDirectionCos : Term := .param "p.same_direction_cos"
private def pTtcBound : Term := .param "p.ttc_bound"
private def pTtcHorizon : Term := .param "p.ttc_horizon"

private def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `d`: ru.subject, ru.aggregate=driver -/
private def clsD : Formula :=
  .and (.atom "ru_subject" [vD] []) (.atom "ru_aggregate" [vD, .lit "driver"] [])

/-- Class of `overtaken`: ru.aggregate=vehicle -/
private def clsOvertaken : Formula := .atom "ru_aggregate" [vOvertaken, .lit "vehicle"] []

/-- Applicability: t2 (trigger): overtaking another vehicle proceeding in the same direction -/
private def applicability : Formula :=
  .and (.derived "drv_overtaking" [vD, vOvertaken] [pSameDirectionCos])
       (.atom "rel_same_direction" [vD, vOvertaken] [pSameDirectionCos])

/-- The clearances between the two bodies in the subject's frame. -/
private def lateralGap : Term := .measure "rel_surface_gap" [vD, vOvertaken, .lit "lateral"]
private def longitudinalGap : Term := .measure "rel_surface_gap" [vD, vOvertaken, .lit "longitudinal"]

/-- t3: the overtaken body was on the subject's right while the bodies overlapped — the subject
    passed to its left. -/
private def passedLeft : Formula :=
  .derived "drv_passing_side" [vD, vOvertaken, .lit "right"] [pSameDirectionCos]

/-- t4: while the bodies overlap along the subject's axis, the lateral clearance is at or above
    the bound. -/
private def clearanceHeld : Formula :=
  .or (.cmp longitudinalGap .gt zeroMetres) (.cmp lateralGap .ge pLateralClearance)

/-- t4: the clearance has held at every instant since the overtaken body was last ahead. -/
private def clearanceThroughPass : Formula :=
  .since clearanceHeld (.atom "rel_bearing" [vD, vOvertaken, .lit "ahead"] [])

/-- t4: the pass leaves the overtaken body a headway of at least `p.headway`. -/
private def headwayAfterPass : Formula :=
  .eventually (.cmp (.quantity "drv_time_gap" [vOvertaken, vD] []) .ge pHeadway)

/-- t4: the time to conflict with the overtaken body is above `p.ttc_bound`. -/
private def timeToConflictAbove : Formula :=
  .cmp (.quantity "drv_time_to_conflict" [vD, vOvertaken] [pTtcHorizon]) .gt pTtcBound

/-- Obligation: t3 (obligation): shall pass to the left thereof; t4 (standard): at a safe distance -/
private def obligation : Formula :=
  .and passedLeft (.and clearanceThroughPass (.and headwayAfterPass timeToConflictAbove))

def rule : Rule :=
  { id := "NRS_484B_207_1_o1"
    laws := ["NRS-484B-207-1"]
    binders :=
      [ { name := "d", cls := clsD }
      , { name := "overtaken", cls := clsOvertaken } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "at a safe distance"
          concepts := ["drv.time_gap", "drv.time_to_conflict", "rel.surface_gap"]
          params := ["p.lateral_clearance", "p.headway", "p.ttc_bound"]
          convention := "The pairing the operationalization table gives for 'safe distance ... (of a pass)': lateral clearance `rel.surface_gap` (lateral component, subject's frame) at or above `p.lateral_clearance` throughout the overlap, the headway `drv.time_gap` after the manoeuvre at or above `p.headway` (two-second headway convention), and `drv.time_to_conflict` with the overtaken vehicle above `p.ttc_bound` (conflict-analysis convention)."
          surrogate := false } ]
    residues :=
      [ "The pass is judged once `drv.overtaking` holds, that is once the overtaken vehicle is behind: a clearance broken during a pass the subject breaks off is not captured."
      , "The overlap the clearance bound speaks of is read off the longitudinal component of `rel.surface_gap` (at or below zero), not `rel.longitudinal_overlap`: a source that reports the overlap but no gap decides nothing here."
      , "The window of the clearance bound opens at the last instant the overtaken vehicle was ahead (`rel.bearing`): a clearance broken earlier, before the subject came up behind it, is not captured."
      , "The headway is the overtaken vehicle's to the subject (`drv.time_gap` of the follower) and is required to be reached at some instant of the episode, not at every instant the rule engages: a pass that ends outside the recording is not captured."
      , "`drv.time_to_conflict` is projected over the reading's `p.ttc_horizon`, which the node does not name: a conflict later than that horizon reads as no conflict."
      , "t6 and t7 (returning to the right side only when safely clear) are siblings of this node and are not captured here." ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_207_1_o1
