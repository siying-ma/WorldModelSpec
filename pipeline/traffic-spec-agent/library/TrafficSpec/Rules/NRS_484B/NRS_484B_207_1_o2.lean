/-
  NRS_484B_207_1_o2 — NRS-484B-207-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (subject): The driver of a vehicle
    t2 (trigger): overtaking another vehicle proceeding in the same direction
    t3 (sibling): shall pass to the left thereof
    t4 (sibling): at a safe distance
    t5 (boilerplate): and
    t6 (obligation): shall not again drive to the right side of the highway
    t7 (standard): until safely clear of the overtaken vehicle.

  Elements (span → atoms, derived):
    t1: atoms ['ru.subject', 'ru.aggregate=driver'], derived []
    t2: atoms ['rel.same_direction', 'ru.aggregate=vehicle'], derived ['drv.overtaking']
    t6: atoms ['st.roadway', 'st.centre_line', 'rel.occupies'], derived []

  How each span is written:

    t1 → `clsD`: the bound track is the scene's subject and a member of the aggregate `driver`.
    t2 → `applicability`: `rel.same_direction` of the pair under `p.same_direction_cos`, and
      `drv.overtaking` of the subject over the other party under the same tolerance (the overtaken
      was ahead at an earlier observation and is behind now). The other party's class is
      `clsOvertaken`, the aggregate `vehicle`.
    t6 → `onRightHalf`: the subject occupies a region of kind `st.roadway` and occupies no region
      of kind `st.centre_line`. CHOICE: the ontology has no atom that splits a roadway at its
      centre line, so the half of the highway the subject's direction uses is read as the roadway
      region the trace records, and the return is complete only once the body is no longer on the
      centre line. CONSEQUENCE (residue 1, 2).
    "again" (t6) is NOT carried by the applicability: the rule does not check that the subject in
      fact left the right side to make the pass. A past-looking conjunct ("off the right side at
      some earlier observation") is unknown, never false, at the start of a trace, so it would
      turn the case it means to exclude — a pass made without crossing the centre line — into
      unknown rather than not applicable, and no scenario of the node exercises it.
      CONSEQUENCE (residue 5).
    t7 → `safelyClear`: the operationalization. `rel.longitudinal_overlap` of the subject over the
      overtaken is no longer positive and, the overlap having ended, `drv.time_gap` of the
      overtaken to the subject, over the longitudinal `rel.surface_gap` that vehicle has to it, is
      at least `p.headway`. The two bounds are placed under the overlap rather than beside it, so
      an unobserved overlap leaves the standard undecided. CONSEQUENCE (residue 3, 4).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Rule

namespace TrafficSpec.Rules.NRS_484B_207_1_o2

/-- The binders, as arguments (order and names are the node's). -/
private def vD : Arg := .var "d"
private def vOvertaken : Arg := .var "overtaken"

/-- The quantified regions of t6. -/
private def vRoadway : Arg := .var "rw"
private def vCentreLine : Arg := .var "cl"

/-- The reading's parameters; no value of any of them lives in this file. -/
private def pHeadway : Term := .param "p.headway"
private def pSameDirectionCos : Term := .param "p.same_direction_cos"

private def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `d`: ru.subject, ru.aggregate=driver -/
private def clsD : Formula :=
  .and (.atom "ru_subject" [vD] [])
       (.atom "ru_aggregate" [vD, .lit "driver"] [])

/-- Class of `overtaken`: ru.aggregate=vehicle -/
private def clsOvertaken : Formula := .atom "ru_aggregate" [vOvertaken, .lit "vehicle"] []

/-- t6: the subject is on the right side of the highway — it occupies the roadway its direction
    uses and no longer occupies the centre line. -/
private def onRightHalf : Formula :=
  .and
    (.existsRegion .roadway "rw"
      (.and (.atom "st_roadway" [vRoadway] [])
            (.atom "rel_occupies" [vD, vRoadway] [])))
    (.forallRegion .centreLine "cl"
      (.not (.and (.atom "st_centre_line" [vCentreLine] [])
                  (.atom "rel_occupies" [vD, vCentreLine] []))))

/-- Applicability: t2 (trigger): overtaking another vehicle proceeding in the same direction -/
private def applicability : Formula :=
  .and (.atom "rel_same_direction" [vD, vOvertaken] [pSameDirectionCos])
       (.derived "drv_overtaking" [vD, vOvertaken] [pSameDirectionCos])

/-- t7: the signed overlap of the two bodies along the subject's axis has ended. -/
private def overlapEnded : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [vD, vOvertaken]) .le zeroMetres

/-- t7: the overtaken vehicle's longitudinal clearance to the subject — the quantity its time
    gap is measured over. -/
private def gapAhead : Term := .measure "rel_surface_gap" [vOvertaken, vD, .lit "longitudinal"]

/-- t7: safely clear — the overlap has ended and, the overlap having ended, the overtaken
    vehicle's clearance to the subject is a real one and its time gap over that clearance is at
    least the headway. -/
private def safelyClear : Formula :=
  .and overlapEnded
       (.implies overlapEnded
                 (.and (.cmp gapAhead .ge zeroMetres)
                       (.cmp (.quantity "drv_time_gap" [vOvertaken, vD] []) .ge pHeadway)))

/-- Obligation: t6 (obligation): shall not again drive to the right side of the highway; t7 (standard): until safely clear of the overtaken vehicle. -/
private def obligation : Formula := .or (.not onRightHalf) safelyClear

def rule : Rule :=
  { id := "NRS_484B_207_1_o2"
    laws := ["NRS-484B-207-1"]
    binders :=
      [ { name := "d", cls := clsD }
      , { name := "overtaken", cls := clsOvertaken } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations :=
      [ { standard := "until safely clear of the overtaken vehicle"
          concepts := ["drv.time_gap", "rel.longitudinal_overlap", "rel.surface_gap"]
          params := ["p.headway"]
          convention := "The two-second headway convention applied to the completion of a pass: the subject is safely clear when `rel.longitudinal_overlap` with the overtaken vehicle has ended (signed overlap no longer positive) and the overtaken vehicle's `drv.time_gap` to the subject, from `rel.surface_gap` (longitudinal) over its own speed, is at least `p.headway`."
          surrogate := false } ]
    residues :=
      [ "The right side of the highway is read as the `st.roadway` region the trace records for the subject's direction; a source that records the whole carriageway as one roadway region cannot tell the two halves apart, and every roadway occupancy then counts as the right side."
      , "The return to the right side is complete only once the subject occupies no `st.centre_line` region, so a body still astride the line is treated as not yet back."
      , "The headway bound is read only where `rel.longitudinal_overlap` decides that the bodies are apart: with the overlap unobserved the standard is undecided rather than decided by the gap alone."
      , "The clearance the headway is measured over is read on the overtaken vehicle's side (`rel.surface_gap` from it to the subject), so a source whose overlap and whose surface gap disagree is judged by the overlap for the end of the pass and by the gap for the headway."
      , "\"Again\" is not captured: the rule judges any engaged instant at which the subject is on the right side and not yet safely clear, whether or not it left the right side to make the pass, so an overtaking made without crossing the centre line is judged by this rule too." ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_207_1_o2
