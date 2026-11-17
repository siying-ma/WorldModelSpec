/-
  NRS_484B_283_1d2 — NRS-484B-283-1d2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    r (reference): Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:
    c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:
    t (trigger): While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer,
    s (subject): a pedestrian
    c (condition): may proceed across the highway in the direction of the signal,
    ob (obligation): but must complete the crossing before the countdown timer gets to zero.

  Elements (span → atoms, derived):
    c0: atoms ['dev.pedestrian_signal', 'dev.governs', 'st.roadway', 'st.lane'], derived []
    t: atoms ['dev.pedestrian_signal'], derived []
    s: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    c: atoms ['rel.occupies', 'st.roadway', 'st.lane', 'kin.heading', 'kin.position', 'dev.position'], derived []
    ob: atoms ['rel.occupies', 'st.roadway', 'st.lane', 'dev.pedestrian_signal'], derived []

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

  How each span is written.
    s:  `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    c0: a head `d` of kind `pedestrian_signal` (device quantifier) governing (`dev_governs d r`) a
        region `r` of kind `roadway` or of kind `lane` (two region quantifiers, one per kind named).
    t:  `flashingCountdown d` = state dont_walk_flashing ∧ countdown displayed.
    c:  the latest entry: `entry r` = `rises (rel_occupies subject r)` (on r here, not at the
        observation before). `facing d` is the record's cone-and-reach test over Δ = dev_position −
        kin_position and h = kin_heading: h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|², |Δ|² ≤ reach².
        `crossedUnderCountdown d r` = `since (flashingCountdown ∧ ¬entry) (entry ∧ flashingCountdown
        ∧ facing)`: some observation at which the subject entered r while d showed the flashing
        indication with countdown and the subject faced d, with no later entry and the flashing
        countdown shown at every observation since. The search has no bound other than that entry;
        where the entry lies before the recording `since` carries the unobserved past as unknown.
    ob (trigger of the duty, the countdown's end): d shows dont_walk_steady here and
        `crossedUnderCountdown` held at the previous observation. Since dont_walk_steady here makes
        `crossedUnderCountdown` false here, "held at the previous observation" is written
        `rises (¬ crossedUnderCountdown)` (false here, true at the observation before).
    ob (duty): for every head d and region r so selected (the whole selection written again in the
        obligation), the subject's footprint does not overlap r (`¬ rel_occupies subject r`).
    r:  each composition as an exception, `¬ ruleApplies`; the two LVMC_11_46_030 limbs bind their
        binder to a road user `v` of the scene: `¬ ∃ v. (applies o1 v ∨ applies o2 v)`.

  No choice beyond the record's own narrowings: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_283_1d2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedSignalFacingCos : Term := .param "p.ped_signal_facing_cos"
def pPedSignalFacingReach : Term := .param "p.ped_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

def vD : Arg := .var "d"
def vR : Arg := .var "r"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- t: the head shows the flashing “Don't Walk” indication accompanied by a countdown timer. -/
def flashingCountdown : Formula :=
  .and (.atom "dev_pedestrian_signal_state" [vD, .lit "dont_walk_flashing"] [])
       (.atom "dev_pedestrian_signal_countdown" [vD] [])

/-- ob: the head shows the steady indication. -/
def steady : Formula := .atom "dev_pedestrian_signal_state" [vD, .lit "dont_walk_steady"] []

/-- c: the subject's footprint came onto r here (not on it at the observation before). -/
def entry : Formula := .rises (.atom "rel_occupies" [vSubject, vR] [])

/-- c: the components of Δ (subject → head) and of the subject's heading. -/
def dx : Term := .sub (.measure "dev_position" [vD, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dy : Term := .sub (.measure "dev_position" [vD, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
def hx : Term := .measure "kin_heading" [vSubject, .lit "x"]
def hy : Term := .measure "kin_heading" [vSubject, .lit "y"]
def dot : Term := .add (.mul hx dx) (.mul hy dy)
def dist2 : Term := .add (.mul dx dx) (.mul dy dy)

/-- c: the subject faces d — the head ahead along its heading, within the cone and the reach. -/
def facing : Formula :=
  .and (.cmp dot .gt zeroMetres)
    (.and (.cmp (.mul dot dot) .ge (.mul (.mul pPedSignalFacingCos pPedSignalFacingCos) dist2))
          (.cmp dist2 .le (.mul pPedSignalFacingReach pPedSignalFacingReach)))

/-- c: the latest entry onto r was made under the flashing countdown facing d, and the flashing
    countdown has been shown at every observation since. -/
def crossedUnderCountdown : Formula :=
  .since (.and flashingCountdown (.not entry)) (.and entry (.and flashingCountdown facing))

/-- c0 + t + c + the countdown's end: d governs r, shows the steady indication here, and the
    subject's crossing of r under the flashing countdown held at the previous observation. -/
def selection : Formula :=
  .and (.atom "dev_governs" [vD, vR] [])
    (.and steady (.rises (.not crossedUnderCountdown)))

/-- r: the exceptions. -/
def exceptions : Formula :=
  .and (.not (.ruleApplies "NRS_484B_287_1c" [("subject", "subject")]))
  (.and (.not (.ruleApplies "NRS_484B_287_1d" [("subject", "subject")]))
  (.and (.not (.ruleApplies "NRS_484B_287_1e" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_060_A" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_060_B" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")]))
        (.not (.existsUser "v"
          (.or (.ruleApplies "LVMC_11_46_030_o1" [("subject", "v")])
               (.ruleApplies "LVMC_11_46_030_o2" [("subject", "v")]))))))))))

/-- Applicability: c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:; t (trigger): While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer,; c (condition): may proceed across the highway in the direction of the signal, -/
def applicability : Formula :=
  .and
    (.existsDevice (.lit "pedestrian_signal") "d"
      (.or (.existsRegion (.lit "roadway") "r" selection)
           (.existsRegion (.lit "lane") "r" selection)))
    exceptions

/-- ob: off r — the crossing completed. -/
def offRegion : Formula := .not (.atom "rel_occupies" [vSubject, vR] [])

/-- Obligation: ob (obligation): but must complete the crossing before the countdown timer gets to zero. -/
def obligation : Formula :=
  .forallDevice (.lit "pedestrian_signal") "d"
    (.and (.forallRegion (.lit "roadway") "r" (.implies selection offRegion))
          (.forallRegion (.lit "lane") "r" (.implies selection offRegion)))

def rule : Rule :=
  { id := "NRS_484B_283_1d2"
    laws := ["NRS-484B-283-1d2"]
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

end TrafficSpec.Rules.NRS_484B_283_1d2
