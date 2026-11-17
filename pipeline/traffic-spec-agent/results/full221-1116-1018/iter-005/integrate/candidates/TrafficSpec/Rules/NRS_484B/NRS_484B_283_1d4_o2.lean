/-
  NRS_484B_283_1d4_o2 — NRS-484B-283-1d4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    r (reference): Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:
    c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:
    t (trigger): While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady
    s1 (sibling): a pedestrian
    ob1 (sibling): may not proceed to cross the highway,
    s2 (subject): but a pedestrian
    e1 (condition): who entered the highway lawfully pursuant to subparagraph (1) or (2)
    ref2 (reference): [NRS-484B-283-1d1, NRS-484B-283-1d2]
    e2 (condition): may continue to cross the highway
    ob2 (obligation): but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety
    st (standard): as soon as possible.

  Elements (span → atoms, derived):
    c0: atoms ['dev.pedestrian_signal', 'dev.governs', 'dev.position', 'kin.position', 'kin.heading', 'st.roadway', 'st.lane'], derived []
    t: atoms ['dev.pedestrian_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    e1: atoms ['rel.occupies', 'st.roadway', 'st.lane', 'st.sidewalk', 'dev.pedestrian_signal', 'dev.governs', 'dev.position', 'kin.position', 'kin.heading'], derived [], borrowing ['ref2']
    e2: atoms ['rel.occupies', 'st.roadway', 'st.lane'], derived []
    ob2: atoms ['rel.occupies', 'st.roadway', 'st.lane', 'kin.speed'], derived []

  Compositions (span → node, as, map):
    r: NRS_484B_287_1c as exception map {'subject': 'subject'}
    r: NRS_484B_287_1d as exception map {'subject': 'subject'}
    r: NRS_484B_287_1e as exception map {'subject': 'subject'}
    r: LVMC_11_30_060_A as exception map {'subject': 'subject'}
    r: LVMC_11_30_060_B as exception map {'subject': 'subject'}
    r: LVMC_11_30_140_B_o1 as exception map {'subject': 'subject'}
    r: LVMC_11_30_140_B_o2 as exception map {'subject': 'subject'}
    r: LVMC_11_46_030_o1 as exception map {'subject': 'v'}
    r: LVMC_11_46_030_o2 as exception map {'subject': 'v'}

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    ref2: NRS-484B-283-1d1: While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal
    ref2: NRS-484B-283-1d2: While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer, a pedestrian may proceed across the highway in the direction of the signal

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_283_1d4_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedSignalFacingCos : Term := .param "p.ped_signal_facing_cos"
def pPedSignalFacingReach : Term := .param "p.ped_signal_facing_reach"
def pPedestrianClearingSpeedMin : Term := .param "p.pedestrian_clearing_speed_min"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.

  s2: the subject's class is the admitted aggregate, `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
  r: each of the nine compositions is an exception, `.not (.ruleApplies id map)`; the two of
     LVMC_11_46_030 bind their binder to a road user `v` of the scene, so no road user of the scene
     engaged by them is written `.not (.existsUser "v" (.ruleApplies id [("subject", "v")]))`.
  c0 / t: some device `d` of kind pedestrian_signal (dev.pedestrian_signal) shows
     `dont_walk_steady` here, and governs (dev.governs) the region `r` of kind roadway or of kind lane
     (st.roadway / st.lane: one region quantifier per kind, the same body under each) that the
     subject's crossing traverses.
  e2: the subject's footprint overlaps `r` here (rel.occupies), and has overlapped it at every
     observation since its step onto `r` (the `since`'s left operand).
  e1 (borrowing ref2): the subject's latest step from a sidewalk onto `r` is the latest observation at
     which its footprint overlaps `r` and stops overlapping every sidewalk (st.sidewalk:
     `rises (not (some sidewalk occupied))`), its footprint on `r` at every observation since; at
     that observation `d` showed `walk` (subparagraph (1)), or `dont_walk_flashing` with its
     countdown displayed (subparagraph (2)), and the subject faced `d`: with Δ the vector from its
     kin.position to d's dev.position and h its kin.heading, h·Δ > 0,
     (h·Δ)² ≥ p.ped_signal_facing_cos² · |Δ|² and |Δ|² ≤ p.ped_signal_facing_reach². The search
     back has no other limit; where it reaches the start of the recording without finding the step,
     `since` and `rises` leave it unknown.
  ob2 / st: the subject's kin.speed is at least p.pedestrian_clearing_speed_min, judged at every
     observation at which the applicability holds (the subject still on `r` after the steady
     indication), as the record's obligation states; the region is not read again in the
     obligation, which speaks only of the subject's speed.

  No narrowing of this file's own: the record's two narrowings (ob2, st) are the plan's.
-/

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- r: the exceptions of NRS 484B.287, 484B.290 and 484B.350. -/
def notExcepted : Formula :=
  .and (.not (.ruleApplies "NRS_484B_287_1c" [("subject", "subject")]))
  (.and (.not (.ruleApplies "NRS_484B_287_1d" [("subject", "subject")]))
  (.and (.not (.ruleApplies "NRS_484B_287_1e" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_060_A" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_060_B" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")]))
  (.and (.not (.existsUser "v" (.ruleApplies "LVMC_11_46_030_o1" [("subject", "v")])))
        (.not (.existsUser "v" (.ruleApplies "LVMC_11_46_030_o2" [("subject", "v")]))))))))))

/-- Δ, the vector from the subject's position to the head's position, by component. -/
def dx : Term := .sub (.measure "dev_position" [.var "d", .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dy : Term := .sub (.measure "dev_position" [.var "d", .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
/-- h·Δ, with h the subject's heading. -/
def hDotD : Term :=
  .add (.mul (.measure "kin_heading" [vSubject, .lit "x"]) dx) (.mul (.measure "kin_heading" [vSubject, .lit "y"]) dy)
/-- |Δ|². -/
def distSq : Term := .add (.mul dx dx) (.mul dy dy)

/-- c0 / e1: the subject faces the head `d`. -/
def facesD : Formula :=
  .and (.cmp hDotD .gt zeroMetres)
  (.and (.cmp (.mul hDotD hDotD) .ge (.mul (.mul pPedSignalFacingCos pPedSignalFacingCos) distSq))
        (.cmp distSq .le (.mul pPedSignalFacingReach pPedSignalFacingReach)))

/-- e1 (ref2): `d` shows walk (subparagraph (1)), or the flashing indication with its countdown
    (subparagraph (2)). -/
def lawfulIndication : Formula :=
  .or (.atom "dev_pedestrian_signal_state" [.var "d", .lit "walk"] [])
      (.and (.atom "dev_pedestrian_signal_state" [.var "d", .lit "dont_walk_flashing"] [])
            (.atom "dev_pedestrian_signal_countdown" [.var "d"] []))

/-- The subject's footprint overlaps `r`. -/
def onR : Formula := .atom "rel_occupies" [vSubject, .var "r"] []

/-- The subject's footprint overlaps some sidewalk. -/
def onSidewalk : Formula :=
  .existsRegion (.lit "sidewalk") "s" (.atom "rel_occupies" [vSubject, .var "s"] [])

/-- e1: the step from a sidewalk onto `r`, made lawfully: the footprint on `r` leaves the sidewalk
    while `d` shows walk or the flashing indication with its countdown and the subject faces `d`. -/
def lawfulStep : Formula :=
  .and onR (.and (.rises (.not onSidewalk)) (.and lawfulIndication facesD))

/-- c0 / e1 / e2 for one region `r`: `d` governs `r`, and the subject has stayed on `r` since its
    latest step onto it from a sidewalk, which it made lawfully. -/
def crossingOnR : Formula :=
  .and (.atom "dev_governs" [.var "d", .var "r"] [])
       (.since onR lawfulStep)

/-- Applicability: c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:; t (trigger): While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady; e1 (condition): who entered the highway lawfully pursuant to subparagraph (1) or (2); e2 (condition): may continue to cross the highway -/
def applicability : Formula :=
  .and notExcepted
    (.existsDevice (.lit "pedestrian_signal") "d"
      (.and (.atom "dev_pedestrian_signal_state" [.var "d", .lit "dont_walk_steady"] [])
            (.or (.existsRegion (.lit "roadway") "r" crossingOnR)
                 (.existsRegion (.lit "lane") "r" crossingOnR))))

/-- Obligation: ob2 (obligation): but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety; st (standard): as soon as possible. -/
def obligation : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .ge pPedestrianClearingSpeedMin

def rule : Rule :=
  { id := "NRS_484B_283_1d4_o2"
    laws := ["NRS-484B-283-1d4"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "as soon as possible"
          concepts := ["kin.speed"]
          params := ["p.pedestrian_clearing_speed_min"]
          convention := "pedestrian clearance walking speed: a pedestrian still on the roadway after the steady indication proceeds as soon as possible where its speed is at least a floor well below the slow walking speed the clearance interval is timed for; lingering or halting on the roadway is below it"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_283_1d4_o2
