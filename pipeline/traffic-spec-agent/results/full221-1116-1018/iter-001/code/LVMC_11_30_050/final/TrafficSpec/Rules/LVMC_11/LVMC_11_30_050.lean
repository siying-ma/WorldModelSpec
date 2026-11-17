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
    e1: the binder class `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
    e2: the subject occupies some roadway (`existsRegion roadway`, `rel_occupies`), and it occupies
        some carrier k across which it moves: k is a lane (`existsRegion lane`) or a roadway
        (`existsRegion roadway`), each tied to the subject by `rel_occupies`, and
        `drv_motion_moving_across_carrier(subject, k)` with speed_tol p.halt_speed_tolerance and
        cos_max p.crossing_motion_cos. The two carrier kinds are two disjuncts, as the
        applicability names them ("a lane, st.lane, or a roadway").
    e4: the subject occupies no crosswalk: `not (existsRegion crosswalk (rel_occupies subject c))`.
    e3: for each carrier the applicability selects (the same selection written again: a lane or a
        roadway the subject occupies and moves across with p.crossing_motion_cos), the subject moves
        across it at right angles: `drv_motion_moving_across_carrier(subject, k)` with
        p.halt_speed_tolerance and p.right_angle_crossing_cos. The record states "for each such
        carrier k", so it is a universal over both carrier kinds.
  No choice beyond the record's own narrowing on e3 was made; no narrowing is added.

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

/-- The subject occupies region `v`. -/
def occ (v : String) : Formula := .atom "rel_occupies" [vSubject, .var v] []

/-- The subject moves across carrier `v` within cosine bound `cosMax`. -/
def across (v : String) (cosMax : Term) : Formula :=
  .derived "drv_motion_moving_across_carrier" [vSubject, .var v] [pHaltSpeedTolerance, cosMax]

/-- Carrier `v` is selected: the subject occupies it and moves across it (e2). -/
def selected (v : String) : Formula := .and (occ v) (across v pCrossingMotionCos)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- e2: on a roadway. -/
def onRoadway : Formula := .existsRegion (.lit "roadway") "road" (occ "road")

/-- e2: moving across a carrier it occupies (a lane or a roadway). -/
def crossingCarrier : Formula :=
  .or (.existsRegion (.lit "lane") "k_lane" (selected "k_lane"))
      (.existsRegion (.lit "roadway") "k_road" (selected "k_road"))

/-- e4: not in a crosswalk. -/
def inCrosswalk : Formula := .existsRegion (.lit "crosswalk") "cw" (occ "cw")

/-- Applicability: e2 (trigger): shall cross a roadway; e4 (exception): except in a crosswalk -/
def applicability : Formula :=
  .and onRoadway (.and (.not inCrosswalk) crossingCarrier)

/-- Obligation: e3 (obligation): at any place other than by a route at right angles to the curb or by the shortest route to the opposite curb -/
def obligation : Formula :=
  .and
    (.forallRegion (.lit "lane") "k_lane"
      (.implies (selected "k_lane") (across "k_lane" pRightAngleCrossingCos)))
    (.forallRegion (.lit "roadway") "k_road"
      (.implies (selected "k_road") (across "k_road" pRightAngleCrossingCos)))

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
