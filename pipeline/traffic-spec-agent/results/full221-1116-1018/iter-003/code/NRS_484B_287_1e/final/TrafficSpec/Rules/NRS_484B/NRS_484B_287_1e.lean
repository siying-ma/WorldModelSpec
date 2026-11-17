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
    s4: atoms ['dev.pedestrian_signal', 'dev.position', 'kin.position', 'kin.heading'], derived []

  Compositions (span → node, as, map):
    s1: LVMC_11_30_140_B_o1 as exception map {'subject': 'subject'}
    s1: LVMC_11_30_140_B_o2 as exception map {'subject': 'subject'}

  Writing:
    s1: `.not (.ruleApplies …)` for each of LVMC_11_30_140_B_o1/_o2, subject ↦ subject.
    s2: some intersection x with `rises (rel_occupies subject x)` (the entry); at least one lane
        enters x and for every lane l entering x, moving_across_carrier(subject, l) holds at
        (halt_speed_tolerance, crossing_motion_cos) and fails at (halt_speed_tolerance,
        right_angle_crossing_cos); 'authorized' as some marked crosswalk the subject occupies.
    s3: ru_aggregate(subject, DEF-NRS-484A-165::pedestrian).
    s4: for every pedestrian signal head d the subject faces (h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|²,
        |Δ|² ≤ reach², Δ = dev_position(d) − kin_position(subject), h = kin_heading read unit),
        d shows neither dont_walk_steady nor dont_walk_flashing without countdown.
  No choice beyond the record's own narrowings was made.

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

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s1: the exceptions of NRS 484B.290 [LVMC-11-30-140-B]. -/
def exceptions : Formula :=
  .and (.not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")]))
       (.not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")]))

/-- The subject moves across lane `l` (velocity off its direction by more than the crossing bound)
    but not at right angles to it. -/
def obliqueTo (l : String) : Formula :=
  .and (.derived "drv_motion_moving_across_carrier" [vSubject, .var l] [pHaltSpeedTolerance, pCrossingMotionCos])
       (.not (.derived "drv_motion_moving_across_carrier" [vSubject, .var l] [pHaltSpeedTolerance, pRightAngleCrossingCos]))

/-- s2: the subject begins a diagonal crossing of intersection `x`: its footprint comes to overlap
    `x` here, and its motion is oblique to every lane entering `x` (at least one exists). -/
def diagonalEntry : Formula :=
  .existsRegion (.lit "intersection") "x"
    (.and (.rises (.atom "rel_occupies" [vSubject, .var "x"] []))
      (.and (.existsRegion (.lit "lane") "l0" (.atom "st_lane_enters" [.var "l0", .var "x"] []))
            (.forallRegion (.lit "lane") "l"
              (.implies (.atom "st_lane_enters" [.var "l", .var "x"] []) (obliqueTo "l")))))

/-- s2 ('authorized'): the subject's footprint overlaps a marked crosswalk. -/
def onMarkedCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "c"
    (.and (.atom "rel_occupies" [vSubject, .var "c"] [])
          (.atom "st_crosswalk_marked" [.var "c"] []))

/-- Applicability: s2 (trigger): When authorized to cross diagonally, -/
def applicability : Formula :=
  .and exceptions (.and diagonalEntry onMarkedCrosswalk)

/-- Components of Δ, the vector from the subject's position to head `d`. -/
def dx (d : String) : Term :=
  .sub (.measure "dev_position" [.var d, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dy (d : String) : Term :=
  .sub (.measure "dev_position" [.var d, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])

/-- h·Δ, with h the subject's (unit) heading. -/
def hDotDelta (d : String) : Term :=
  .add (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (dx d))
       (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (dy d))

def deltaSq (d : String) : Term := .add (.mul (dx d) (dx d)) (.mul (dy d) (dy d))

/-- The subject faces head `d`: ahead along its heading, within the facing cone and the reach. -/
def faces (d : String) : Formula :=
  .and (.cmp (hDotDelta d) .gt zeroMetres)
    (.and (.cmp (.mul (hDotDelta d) (hDotDelta d)) .ge
                (.mul (.mul pPedSignalFacingCos pPedSignalFacingCos) (deltaSq d)))
          (.cmp (deltaSq d) .le (.mul pPedSignalFacingReach pPedSignalFacingReach)))

/-- The head forbids starting: steady don't-walk, or flashing don't-walk without countdown. -/
def forbids (d : String) : Formula :=
  .or (.atom "dev_pedestrian_signal_state" [.var d, .lit "dont_walk_steady"] [])
      (.and (.atom "dev_pedestrian_signal_state" [.var d, .lit "dont_walk_flashing"] [])
            (.not (.atom "dev_pedestrian_signal_countdown" [.var d] [])))

/-- Obligation: s4 (obligation): shall cross only in accordance with the official traffic-control devices pertaining to such crossing movements. -/
def obligation : Formula :=
  .forallDevice (.lit "pedestrian_signal") "d" (.implies (faces "d") (.not (forbids "d")))

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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_287_1e
