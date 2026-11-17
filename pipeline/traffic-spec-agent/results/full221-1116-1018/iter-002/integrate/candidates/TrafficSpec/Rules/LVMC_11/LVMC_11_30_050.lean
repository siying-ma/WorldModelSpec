/-
  LVMC_11_30_050 — LVMC-11-30-050

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): No pedestrian
    e2 (trigger): shall cross a roadway
    e3 (obligation): at any place other than by a route at right angles to the curb or by the shortest route to the opposite curb
    e4 (exception): except in a crosswalk

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    e2: atoms ['rel.occupies', 'st.roadway', 'st.lane'], derived ['drv.motion.moving_across_carrier']
    e3: atoms [], derived ['drv.motion.moving_across_carrier']
    e4: atoms ['rel.occupies', 'st.crosswalk'], derived []

  How each span is written:
    e1: the binder class `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    e2: the subject occupies some region of kind `roadway` (rel_occupies), and there is a carrier k
        it occupies — a region of kind `lane`, or one of kind `roadway` — across which it moves:
        drv_motion_moving_across_carrier(subject, k; p.halt_speed_tolerance, p.crossing_motion_cos).
        The two carrier kinds are two disjuncts, each its own region quantifier.
    e4: the subject occupies no region of kind `crosswalk` (negated existential, conjoined into the
        applicability).
    e3: for each carrier selected as in e2 (the whole selection restated: of kind lane or roadway,
        occupied by the subject, moved across within p.crossing_motion_cos), the subject moves across
        it within p.right_angle_crossing_cos. Written as two universal quantifiers (lane, roadway),
        each an implication from the selection to the duty, so the duty is required at every
        selected carrier, as the record states.

  No choice beyond the record's was needed; the record's own narrowing on e3 is not restated.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_30_050

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrossingMotionCos : Term := .param "p.crossing_motion_cos"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pRightAngleCrossingCos : Term := .param "p.right_angle_crossing_cos"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- The subject occupies region variable `v`. -/
def occupies (v : String) : Formula :=
  .atom "rel_occupies" [vSubject, .var v] []

/-- The subject moves across carrier `v`, with the given cosine bound. -/
def movesAcross (v : String) (cosMax : Term) : Formula :=
  .derived "drv_motion_moving_across_carrier" [vSubject, .var v] [pHaltSpeedTolerance, cosMax]

/-- e2's carrier selection: occupied, and moved across (not along). -/
def crossingCarrier (v : String) : Formula :=
  .and (occupies v) (movesAcross v pCrossingMotionCos)

/-- e2: on a roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "w" (occupies "w")

/-- e4: not in a crosswalk. -/
def notInCrosswalk : Formula :=
  .not (.existsRegion (.lit "crosswalk") "c" (occupies "c"))

/-- e2: some carrier (a lane, or the roadway) the subject occupies and moves across. -/
def crossesCarrier : Formula :=
  .or (.existsRegion (.lit "lane") "k" (crossingCarrier "k"))
      (.existsRegion (.lit "roadway") "k" (crossingCarrier "k"))

/-- Applicability: e2 (trigger): shall cross a roadway; e4 (exception): except in a crosswalk -/
def applicability : Formula :=
  .and onRoadway (.and notInCrosswalk crossesCarrier)

/-- Obligation: e3 (obligation): at any place other than by a route at right angles to the curb or by the shortest route to the opposite curb -/
def obligation : Formula :=
  .and
    (.forallRegion (.lit "lane") "k"
      (.implies (crossingCarrier "k") (movesAcross "k" pRightAngleCrossingCos)))
    (.forallRegion (.lit "roadway") "k"
      (.implies (crossingCarrier "k") (movesAcross "k" pRightAngleCrossingCos)))

def rule : Rule :=
  { id := "LVMC_11_30_050"
    laws := ["LVMC-11-30-050"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_30_050
