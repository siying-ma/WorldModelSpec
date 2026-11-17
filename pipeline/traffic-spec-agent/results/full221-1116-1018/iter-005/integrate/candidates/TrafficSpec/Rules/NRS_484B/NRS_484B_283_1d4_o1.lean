/-
  NRS_484B_283_1d4_o1 — NRS-484B-283-1d4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    r (reference): Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:
    c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:
    t (trigger): While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady
    s1 (subject): a pedestrian
    ob1 (obligation): may not proceed to cross the highway,
    s2 (exception): but a pedestrian
    e1 (exception): who entered the highway lawfully pursuant to subparagraph (1) or (2)
    ref2 (reference): [NRS-484B-283-1d1, NRS-484B-283-1d2]
    e2 (exception): may continue to cross the highway
    ob2 (sibling): but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety
    st (sibling): as soon as possible.

  Elements (span → atoms, derived):
    c0: atoms ['dev.pedestrian_signal', 'dev.governs', 'dev.position', 'kin.position', 'kin.heading', 'st.roadway', 'st.lane'], derived []
    t: atoms ['dev.pedestrian_signal'], derived []
    s1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    ob1: atoms ['rel.occupies', 'st.roadway', 'st.lane'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    e1: atoms ['rel.occupies', 'st.roadway', 'st.lane', 'st.sidewalk', 'dev.pedestrian_signal', 'dev.governs', 'dev.position', 'kin.position', 'kin.heading'], derived [], borrowing ['ref2']
    e2: atoms ['rel.occupies', 'st.sidewalk'], derived []

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

  How each span is written:
    s1: the binder class, ru_aggregate(subject, DEF-NRS-484A-165::pedestrian).
    c0, t: some pedestrian head d (existsDevice pedestrian_signal) with state dont_walk_steady,
      governing (dev_governs) a region r that is a roadway or a lane (one region quantifier per
      named kind, disjoined; universally, conjoined), and the subject faces d:
      Δ = dev_position(d) − kin_position(subject), h = kin_heading(subject); h·Δ > 0,
      (h·Δ)² ≥ p.ped_signal_facing_cos² · |Δ|², |Δ|² ≤ p.ped_signal_facing_reach² (the record's
      own inequalities, squared so no division and no root is needed).
    ob1: the record's selection of r also requires that the footprint did not overlap r at the
      previous observation. "Not at the previous observation" is written with `rises` only:
      rises(occ) ∨ (¬occ ∧ ¬rises(¬occ)), which is exactly "occ false at the previous
      observation" when both values are known. The obligation repeats the whole selection of d and r
      for every head and region (forall … implies) and requires ¬rel_occupies(subject, r) now.
    s2, e1, e2 (ref2 borrowed, no composition): since(¬onSidewalk, lawfulEntry), where
      onSidewalk = some sidewalk the subject's footprint overlaps, and lawfulEntry = the subject
      leaves the sidewalk now (rises ¬onSidewalk) onto a roadway or lane r2 it occupies, governed
      by a pedestrian head d2 that shows walk, or dont_walk_flashing with countdown, and the subject
      faces d2 (same facing test). `since` includes the entry observation itself, so the latest
      such step with no sidewalk overlapped since excepts the subject; s2's pedestrian is
      ru_aggregate on the subject.
    r: each composed rule as `.not (.ruleApplies …)`; the LVMC_11_46_030 pair, whose binder is a
      vehicle, under `existsUser "v"`.
  No reading beyond the record's was chosen; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_283_1d4_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedSignalFacingCos : Term := .param "p.ped_signal_facing_cos"
def pPedSignalFacingReach : Term := .param "p.ped_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- s1, s2: the admitted aggregate DEF-NRS-484A-165::pedestrian. -/
def isPedestrian (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := isPedestrian vSubject

/-- c0, e1: the subject faces head `d`. With Δ the vector from its kin.position to d's
    dev.position and h its kin.heading: h·Δ > 0, (h·Δ)² ≥ cos² · |Δ|², |Δ|² ≤ reach². -/
def dx (d : String) : Term :=
  .sub (.measure "dev_position" [.var d, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dy (d : String) : Term :=
  .sub (.measure "dev_position" [.var d, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
def hDotDelta (d : String) : Term :=
  .add (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (dx d))
       (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (dy d))
def distSq (d : String) : Term := .add (.mul (dx d) (dx d)) (.mul (dy d) (dy d))
def faces (d : String) : Formula :=
  .and (.cmp (hDotDelta d) .gt zeroMetres)
    (.and (.cmp (.mul (hDotDelta d) (hDotDelta d)) .ge
                (.mul (.mul pPedSignalFacingCos pPedSignalFacingCos) (distSq d)))
          (.cmp (distSq d) .le (.mul pPedSignalFacingReach pPedSignalFacingReach)))

/-- c0, ob1, e1: some roadway or some lane `r` satisfying φ (one quantifier per named kind). -/
def existsRoadwayOrLane (r : String) (φ : Formula) : Formula :=
  .or (.existsRegion (.lit "roadway") r φ) (.existsRegion (.lit "lane") r φ)

/-- ob1: every roadway and every lane `r` satisfies φ. -/
def forallRoadwayOrLane (r : String) (φ : Formula) : Formula :=
  .and (.forallRegion (.lit "roadway") r φ) (.forallRegion (.lit "lane") r φ)

/-- ob1: the subject's footprint overlaps region `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- φ was false at the previous observation (φ known here and there):
    `rises φ` (true here, false before) or (false here and not `rises ¬φ`). -/
def notBefore (φ : Formula) : Formula :=
  .or (.rises φ) (.and (.not φ) (.not (.rises (.not φ))))

/-- c0 + t + the selection of r: head `d` shows dont_walk_steady, governs roadway/lane `r`,
    the subject faces `d`, and its footprint did not overlap `r` at the previous observation. -/
def selection (d r : String) : Formula :=
  .and (.atom "dev_governs" [.var d, .var r] [])
    (.and (.atom "dev_pedestrian_signal_state" [.var d, .lit "dont_walk_steady"] [])
      (.and (faces d) (notBefore (occ r))))

/-- e2: the subject's footprint overlaps some sidewalk. -/
def onSidewalk : Formula :=
  .existsRegion (.lit "sidewalk") "s" (.atom "rel_occupies" [vSubject, .var "s"] [])

/-- e1 (borrowing ref2: 1d1 and 1d2): the step from a sidewalk onto a roadway or lane `r2`,
    made while a pedestrian head `d2` governing r2 showed walk, or dont_walk_flashing with its
    countdown, and the subject faced d2. -/
def lawfulEntry : Formula :=
  .and (.rises (.not onSidewalk))
    (existsRoadwayOrLane "r2"
      (.and (occ "r2")
        (.existsDevice (.lit "pedestrian_signal") "d2"
          (.and (.atom "dev_governs" [.var "d2", .var "r2"] [])
            (.and (.or (.atom "dev_pedestrian_signal_state" [.var "d2", .lit "walk"] [])
                       (.and (.atom "dev_pedestrian_signal_state" [.var "d2", .lit "dont_walk_flashing"] [])
                             (.atom "dev_pedestrian_signal_countdown" [.var "d2"] [])))
                  (faces "d2"))))))

/-- s2 + e1 + e2: continuing a crossing begun lawfully — no sidewalk overlapped since the
    latest such entry. -/
def continuingLawfulCrossing : Formula :=
  .since (.not onSidewalk) lawfulEntry

/-- r: the exceptions of NRS 484B.287, 484B.290 and 484B.350. -/
def excepted : Formula :=
  .or (.ruleApplies "NRS_484B_287_1c" [("subject", "subject")])
  (.or (.ruleApplies "NRS_484B_287_1d" [("subject", "subject")])
  (.or (.ruleApplies "NRS_484B_287_1e" [("subject", "subject")])
  (.or (.ruleApplies "LVMC_11_30_060_A" [("subject", "subject")])
  (.or (.ruleApplies "LVMC_11_30_060_B" [("subject", "subject")])
  (.or (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")])
  (.or (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")])
       (.existsUser "v"
         (.or (.ruleApplies "LVMC_11_46_030_o1" [("subject", "v")])
              (.ruleApplies "LVMC_11_46_030_o2" [("subject", "v")])))))))))

/-- Applicability: c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:; t (trigger): While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady; s2 (exception): but a pedestrian; e1 (exception): who entered the highway lawfully pursuant to subparagraph (1) or (2); e2 (exception): may continue to cross the highway -/
def applicability : Formula :=
  .and (.not excepted)
    (.and (.existsDevice (.lit "pedestrian_signal") "d"
            (existsRoadwayOrLane "r" (selection "d" "r")))
          (.not (.and (isPedestrian vSubject) continuingLawfulCrossing)))

/-- Obligation: ob1 (obligation): may not proceed to cross the highway, — at every head and
    roadway/lane the applicability selects, the footprint does not overlap it now. -/
def obligation : Formula :=
  .forallDevice (.lit "pedestrian_signal") "d"
    (forallRoadwayOrLane "r"
      (.implies (selection "d" "r") (.not (occ "r"))))

def rule : Rule :=
  { id := "NRS_484B_283_1d4_o1"
    laws := ["NRS-484B-283-1d4"]
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

end TrafficSpec.Rules.NRS_484B_283_1d4_o1
