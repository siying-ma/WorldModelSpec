/-
  NRS_484B_283_1d3_o2 — NRS-484B-283-1d3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    r (reference): Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:
    c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:
    t (trigger): While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and flashing but is not accompanied by a countdown timer,
    s1 (sibling): a pedestrian
    ob1 (sibling): may not proceed to cross the highway,
    s2 (subject): but a pedestrian
    e1 (condition): who entered the highway lawfully pursuant to subparagraph (1)
    ref2 (reference): [NRS-484B-283-1d1]
    e2 (condition): may continue to cross the highway
    ob2 (obligation): but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety before the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady.

  Elements (span → atoms, derived):
    c0: atoms ['dev.pedestrian_signal', 'dev.governs', 'dev.position', 'kin.position', 'kin.heading', 'st.roadway', 'st.lane'], derived []
    t: atoms ['dev.pedestrian_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    e1: atoms ['rel.occupies', 'st.roadway', 'st.lane', 'st.sidewalk', 'dev.pedestrian_signal', 'dev.governs', 'dev.position', 'kin.position', 'kin.heading'], derived [], borrowing ['ref2']
    e2: atoms ['rel.occupies', 'st.roadway', 'st.lane'], derived []
    ob2: atoms ['rel.occupies', 'st.roadway', 'st.lane', 'dev.pedestrian_signal'], derived []

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

  How each span is written:
    s2  — the binder class: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    c0  — a pedestrian head d (device quantifier of kind pedestrian_signal) governing a roadway or a
          lane r (`dev_governs d r`; one disjunct per kind, r bound by a region quantifier of that
          kind). Facing d: Δ = dev_position d − kin_position subject, h = kin_heading subject;
          h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|², |Δ|² ≤ reach² (both parameters as the record names them).
    t / ob2 moment — the judged observation is the onset of the steady indication:
          `rises (state d dont_walk_steady)` and, at the previous observation, d showed
          dont_walk_flashing without countdown. "At the previous observation" is written
          `since (steady) (flashing ∧ ¬countdown)`: with the rise, the steady run is one
          observation long, so the `since` reaches exactly the previous observation.
    e1  — the subject's step from a sidewalk onto r is `rises (occupies subject r)` with a sidewalk
          occupied by the subject at that observation or the one before (written
          `since (occupies subject r) (∃ sidewalk s, occupies subject s)`, which with the rise reaches
          back exactly one observation). "Its latest step was made while d showed walk and the
          subject faced d" is `since (¬step) (step ∧ walk ∧ facing)`: unbounded into the past, as the
          record's history bound says; where the step lies before the recording the `since` and the
          `rises` are truncated and the applicability is unknown.
    e2  — the subject's footprint overlapped r at some observation since d last began showing
          dont_walk_flashing without countdown: `since (¬rises F) (occupies subject r ∧ F)`, F the
          flashing-without-countdown indication.
    ob2 — at that onset the subject's footprint does not overlap r. The obligation restates the
          applicability's whole selection of (d, r) and requires `¬ occupies subject r` for every
          selected pair.
    r   — `¬ ruleApplies` for each exception; the two LVMC_11_46_030 limbs bind their vehicle by
          `existsUser "v"`.
  No choice beyond the record's own narrowing was needed; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_283_1d3_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables: the pedestrian head, the roadway or lane it governs, a sidewalk. -/
def vD : Arg := .var "d"
def vR : Arg := .var "r"
def vS : Arg := .var "s"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedSignalFacingCos : Term := .param "p.ped_signal_facing_cos"
def pPedSignalFacingReach : Term := .param "p.ped_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

-- ---------------------------------------------------------------------------------------------
-- The head's indications (t, ob2, e1)
-- ---------------------------------------------------------------------------------------------
def shows (s : String) : Formula := .atom "dev_pedestrian_signal_state" [vD, .lit s] []
def walk : Formula := shows "walk"
def steady : Formula := shows "dont_walk_steady"
/-- t: "Don't Walk" illuminated and flashing, not accompanied by a countdown timer. -/
def flashingNoCountdown : Formula :=
  .and (shows "dont_walk_flashing") (.not (.atom "dev_pedestrian_signal_countdown" [vD] []))
/-- The judged observation: d shows steady here and showed flashing without countdown at the previous one. -/
def steadyOnset : Formula := .and (.rises steady) (.since steady flashingNoCountdown)

-- ---------------------------------------------------------------------------------------------
-- Facing the head (c0, e1)
-- ---------------------------------------------------------------------------------------------
def dx : Term := .sub (.measure "dev_position" [vD, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dy : Term := .sub (.measure "dev_position" [vD, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
def hx : Term := .measure "kin_heading" [vSubject, .lit "x"]
def hy : Term := .measure "kin_heading" [vSubject, .lit "y"]
def dot : Term := .add (.mul hx dx) (.mul hy dy)
def dist2 : Term := .add (.mul dx dx) (.mul dy dy)
def facing : Formula :=
  .and (.cmp dot .gt zeroMetres)
    (.and (.cmp (.mul dot dot) .ge (.mul (.mul pPedSignalFacingCos pPedSignalFacingCos) dist2))
      (.cmp dist2 .le (.mul pPedSignalFacingReach pPedSignalFacingReach)))

-- ---------------------------------------------------------------------------------------------
-- Entry and crossing (e1, e2)
-- ---------------------------------------------------------------------------------------------
def onR : Formula := .atom "rel_occupies" [vSubject, vR] []
def onSidewalk : Formula := .existsRegion (.lit "sidewalk") "s" (.atom "rel_occupies" [vSubject, vS] [])
/-- A step from a sidewalk onto r: r entered here, a sidewalk occupied here or at the previous observation. -/
def stepOntoR : Formula := .and (.rises onR) (.since onR onSidewalk)
/-- e1: the latest such step was made while d showed walk and the subject faced d (unbounded look-back). -/
def enteredLawfully : Formula := .since (.not stepOntoR) (.and stepOntoR (.and walk facing))
/-- e2: on r at some observation since d last began flashing without countdown. -/
def continuedCrossing : Formula :=
  .since (.not (.rises flashingNoCountdown)) (.and onR flashingNoCountdown)

/-- The whole selection of (d, r), shared by applicability and obligation. -/
def selected : Formula :=
  .and (.atom "dev_governs" [vD, vR] [])
    (.and steadyOnset (.and enteredLawfully continuedCrossing))

-- ---------------------------------------------------------------------------------------------
-- Exceptions (r)
-- ---------------------------------------------------------------------------------------------
def exceptions : Formula :=
  let subj (id : String) : Formula := .not (.ruleApplies id [("subject", "subject")])
  let veh (id : String) : Formula := .not (.existsUser "v" (.ruleApplies id [("subject", "v")]))
  .and (subj "NRS_484B_287_1c")
    (.and (subj "NRS_484B_287_1d")
      (.and (subj "NRS_484B_287_1e")
        (.and (subj "LVMC_11_30_060_A")
          (.and (subj "LVMC_11_30_060_B")
            (.and (subj "LVMC_11_30_140_B_o1")
              (.and (subj "LVMC_11_30_140_B_o2")
                (.and (veh "LVMC_11_46_030_o1") (veh "LVMC_11_46_030_o2"))))))))

/-- Applicability: c0, t, e1, e2 and the exceptions of r. -/
def applicability : Formula :=
  .and
    (.existsDevice (.lit "pedestrian_signal") "d"
      (.or (.existsRegion (.lit "roadway") "r" selected)
           (.existsRegion (.lit "lane") "r" selected)))
    exceptions

/-- Obligation: ob2 — at the onset of the steady indication, off every selected roadway or lane. -/
def obligation : Formula :=
  .forallDevice (.lit "pedestrian_signal") "d"
    (.and (.forallRegion (.lit "roadway") "r" (.implies selected (.not onR)))
          (.forallRegion (.lit "lane") "r" (.implies selected (.not onR))))

def rule : Rule :=
  { id := "NRS_484B_283_1d3_o2"
    laws := ["NRS-484B-283-1d3"]
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

end TrafficSpec.Rules.NRS_484B_283_1d3_o2
