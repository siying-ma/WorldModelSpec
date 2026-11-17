/-
  LVMC_11_30_070_B — LVMC-11-30-070-B

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): No pedestrian
    s2 (obligation): shall cross a roadway
    s3 (exception): other than in a marked crosswalk or within an unmarked crosswalk
    s4 (condition): in any business district

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s2: atoms ['rel.occupies', 'st.lane', 'st.roadway'], derived ['drv.motion.moving_across_carrier']
    s3: atoms ['rel.occupies', 'st.crosswalk'], derived []

  How each is written:
    s1: the binder class `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    s4: `asm "asm.business_district"` in the applicability, beside the record's
        "footprint overlaps a roadway" (`existsRegion roadway`, `rel_occupies`).
    s2: in the obligation, the antecedent "moves across a lane or roadway it occupies": a region of
        kind lane, or one of kind roadway, that the subject occupies and across whose designated
        direction it moves (`drv_motion_moving_across_carrier` with p.halt_speed_tolerance and
        p.crossing_motion_cos). The record's "occupies a roadway" in the obligation is already the
        applicability (evaluated at the same observation), so it is not repeated there.
    s3: the consequent: the subject occupies some region of kind crosswalk (no `marked` test: both
        marked and unmarked crosswalks are admitted, the whole kind is kept).

  No choice beyond the record's own narrowing was needed; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_30_070_B

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrossingMotionCos : Term := .param "p.crossing_motion_cos"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- The subject's footprint overlaps a region of kind `kind` (rel.occupies). -/
def occupiesSome (kind var : String) : Formula :=
  .existsRegion (.lit kind) var (.atom "rel_occupies" [vSubject, .var var] [])

/-- s2: the subject occupies a carrier of kind `kind` and moves across its designated direction. -/
def crossesCarrier (kind var : String) : Formula :=
  .existsRegion (.lit kind) var
    (.and (.atom "rel_occupies" [vSubject, .var var] [])
          (.derived "drv_motion_moving_across_carrier" [vSubject, .var var]
            [pHaltSpeedTolerance, pCrossingMotionCos]))

/-- Applicability: s1 (via the binder), the subject's footprint on a roadway; s4 (condition): in any business district -/
def applicability : Formula :=
  .and (occupiesSome "roadway" "rw") (.asm "asm.business_district")

/-- Obligation: s2 (obligation): shall cross a roadway; s3 (exception): other than in a marked crosswalk or within an unmarked crosswalk -/
def obligation : Formula :=
  .implies
    (.or (crossesCarrier "lane" "ln") (crossesCarrier "roadway" "rd"))
    (occupiesSome "crosswalk" "cw")

def rule : Rule :=
  { id := "LVMC_11_30_070_B"
    laws := ["LVMC-11-30-070-B"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_district"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_30_070_B
