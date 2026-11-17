/-
  NRS_484B_287_1e — NRS-484B-287-1e

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (reference): Except as provided in NRS 484B.290 [LVMC-11-30-140-B]:
    s2 (trigger): When authorized to cross diagonally,
    s3 (subject): pedestrians
    s4 (obligation): shall cross only in accordance with the official traffic-control devices pertaining to such crossing movements.

  Elements (span → atoms, derived):
    s2: atoms ['rel.occupies', 'st.crosswalk', 'st.intersection', 'st.lane', 'st.lane_enters'], derived ['drv.motion.moving_across_carrier']
    s3: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s4: atoms ['dev.pedestrian_signal', 'dev.governs', 'dev.position', 'kin.position', 'kin.heading', 'rel.occupies', 'st.intersection', 'st.lane', 'st.lane_enters'], derived ['drv.motion.moving_across_carrier']

  Compositions (span → node, as, map):
    s1: LVMC_11_30_140_B_o1 as exception map {'subject': 'subject'}
    s1: LVMC_11_30_140_B_o2 as exception map {'subject': 'subject'}

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_287_1e

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrossingMotionCos : Term := .param "p.crossing_motion_cos"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pPedSignalFacingCos : Term := .param "p.ped_signal_facing_cos"
def pPedSignalFacingReach : Term := .param "p.ped_signal_facing_reach"
def pRightAngleCrossingCos : Term := .param "p.right_angle_crossing_cos"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s3: `ru_aggregate(subject, DEF-NRS-484A-165::pedestrian)`.
    s2: `diagonalEntry x` — the subject's occupancy of intersection x rises at this observation,
        some lane enters x, and for every lane entering x the subject moves across it at
        (p.halt_speed_tolerance, p.crossing_motion_cos) and not at
        (p.halt_speed_tolerance, p.right_angle_crossing_cos); the authorization is the marked
        crosswalk the subject's footprint overlaps (`st_crosswalk_marked`).
    s1: both LVMC_11_30_140_B rules, as exceptions: `not (ruleApplies …)` in the applicability.
    s4: for every intersection x re-bound with the whole selection `diagonalEntry x`, and every
        pedestrian signal head d governing x that the subject faces (Δ = dev.position(d) −
        kin.position(subject), h = kin.heading(subject): h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|²,
        |Δ|² ≤ reach²), d shows neither dont_walk_steady nor dont_walk_flashing without its
        countdown. All as the record states; no choice beyond the record's own narrowings.
-/

def vX : Arg := .var "x"
def vL : Arg := .var "l"
def vC : Arg := .var "c"
def vD : Arg := .var "d"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- The subject moves diagonally across every lane entering `x` (at least one). -/
def diagonalAcross : Formula :=
  .and (.existsRegion (.lit "lane") "l" (.atom "st_lane_enters" [vL, vX] []))
    (.forallRegion (.lit "lane") "l"
      (.implies (.atom "st_lane_enters" [vL, vX] [])
        (.and (.derived "drv_motion_moving_across_carrier" [vSubject, vL] [pHaltSpeedTolerance, pCrossingMotionCos])
          (.not (.derived "drv_motion_moving_across_carrier" [vSubject, vL] [pHaltSpeedTolerance, pRightAngleCrossingCos])))))

/-- The whole selection of the intersection whose diagonal crossing begins. -/
def diagonalEntry : Formula :=
  .and (.rises (.atom "rel_occupies" [vSubject, vX] [])) diagonalAcross

/-- s2's authorization: the subject's footprint overlaps a marked crosswalk. -/
def onMarkedCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "c"
    (.and (.atom "rel_occupies" [vSubject, vC] []) (.atom "st_crosswalk_marked" [vC] []))

/-- Applicability: s2 (trigger): When authorized to cross diagonally, -/
def applicability : Formula :=
  .and (.not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")]))
    (.and (.not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")]))
      (.and onMarkedCrosswalk
        (.existsRegion (.lit "intersection") "x" diagonalEntry)))

/-- Components of Δ = dev.position(d) − kin.position(subject) and of the heading h. -/
def dX : Term := .sub (.measure "dev_position" [vD, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dY : Term := .sub (.measure "dev_position" [vD, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
def hX : Term := .measure "kin_heading" [vSubject, .lit "x"]
def hY : Term := .measure "kin_heading" [vSubject, .lit "y"]
def hDotD : Term := .add (.mul hX dX) (.mul hY dY)
def dSq : Term := .add (.mul dX dX) (.mul dY dY)

/-- The subject faces head d: ahead along its heading, within the cone and the reach. -/
def faces : Formula :=
  .and (.cmp hDotD .gt zeroMetres)
    (.and (.cmp (.mul hDotD hDotD) .ge (.mul (.mul pPedSignalFacingCos pPedSignalFacingCos) dSq))
      (.cmp dSq .le (.mul pPedSignalFacingReach pPedSignalFacingReach)))

/-- The indication accords: neither steady don't-walk nor flashing don't-walk without countdown. -/
def accords : Formula :=
  .and (.not (.atom "dev_pedestrian_signal_state" [vD, .lit "dont_walk_steady"] []))
    (.not (.and (.atom "dev_pedestrian_signal_state" [vD, .lit "dont_walk_flashing"] [])
      (.not (.atom "dev_pedestrian_signal_countdown" [vD] []))))

/-- Obligation: s4 (obligation): shall cross only in accordance with the official traffic-control devices pertaining to such crossing movements. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "x"
    (.implies diagonalEntry
      (.forallDevice (.lit "pedestrian_signal") "d"
        (.implies (.and (.atom "dev_governs" [vD, vX] []) faces) accords)))

def rule : Rule :=
  { id := "NRS_484B_287_1e"
    laws := ["NRS-484B-287-1e"]
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

end TrafficSpec.Rules.NRS_484B_287_1e
