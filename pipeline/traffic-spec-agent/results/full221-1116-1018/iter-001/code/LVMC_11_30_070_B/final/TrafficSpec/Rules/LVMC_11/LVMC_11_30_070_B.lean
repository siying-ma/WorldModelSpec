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
    s1: the binder's class, `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    s4: `asm "asm.business_district"` in the applicability.
    s2: applicability — the subject occupies some region of kind `roadway` (rel_occupies).
        Obligation antecedent ("crossing") — for some region of kind `lane`, or of kind `roadway`,
        the subject occupies it and `drv_motion_moving_across_carrier subject r` holds with
        speed_tol = p.halt_speed_tolerance and cos_max = p.crossing_motion_cos. The lane and
        roadway disjuncts are the record's "a lane or roadway it occupies"; the lane is used only
        as the carrier of a designated direction.
    s3: obligation consequent — the subject occupies some region of kind `crosswalk`; the marked
        attribute is not read, so marked and unmarked crosswalks alike satisfy it.
    Obligation: crossing → occupies a crosswalk. Standing or moving along is no crossing and the
    implication holds (the record's own s2 narrowing; not restated here).

  No choice beyond the record's was made; no narrowing is declared.

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

/-- s2: the subject's footprint overlaps a roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "rw" (.atom "rel_occupies" [vSubject, .var "rw"] [])

/-- s2: the subject moves across a carrier of the given kind that it occupies. -/
def crossingOn (kind var : String) : Formula :=
  .existsRegion (.lit kind) var
    (.and (.atom "rel_occupies" [vSubject, .var var] [])
          (.derived "drv_motion_moving_across_carrier" [vSubject, .var var]
            [pHaltSpeedTolerance, pCrossingMotionCos]))

/-- s2: "cross a roadway" — moving across a lane or a roadway the subject occupies. -/
def crossing : Formula :=
  .or (crossingOn "lane" "ln") (crossingOn "roadway" "rc")

/-- s3: in a crosswalk, marked or unmarked. -/
def inCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "cw" (.atom "rel_occupies" [vSubject, .var "cw"] [])

/-- Applicability: s2 (on a roadway); s4 (condition): in any business district -/
def applicability : Formula :=
  .and (.asm "asm.business_district") onRoadway

/-- Obligation: s2 (obligation): shall cross a roadway; s3 (exception): other than in a crosswalk -/
def obligation : Formula :=
  .implies crossing inCrosswalk

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
