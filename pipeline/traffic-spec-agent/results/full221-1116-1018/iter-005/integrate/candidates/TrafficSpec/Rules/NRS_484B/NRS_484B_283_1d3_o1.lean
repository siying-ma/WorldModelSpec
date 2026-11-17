/-
  NRS_484B_283_1d3_o1 — NRS-484B-283-1d3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    r (reference): Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:
    c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:
    t (trigger): While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and flashing but is not accompanied by a countdown timer,
    s1 (subject): a pedestrian
    ob1 (obligation): may not proceed to cross the highway,
    s2 (exception): but a pedestrian
    e1 (exception): who entered the highway lawfully pursuant to subparagraph (1)
    ref2 (reference): [NRS-484B-283-1d1]
    e2 (exception): may continue to cross the highway
    ob2 (sibling): but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety before the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady.

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

  How each is written.
    s1/s2: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"` as the binder's class (s2 names the
      same pedestrian, so it adds nothing beyond the binder's class).
    c0: a pedestrian head d (`existsDevice "pedestrian_signal"`) governing a roadway or lane r
      (`dev_governs d r`, with r ranging over `roadway` and over `lane`: two quantifiers, one per
      kind the record names), faced by the subject: with Δ = dev_position(d) − kin_position(subject)
      and h = kin_heading(subject), h·Δ > 0, (h·Δ)² ≥ cos² · |Δ|², |Δ|² ≤ reach² (the record's
      comparisons, with cos = p.ped_signal_facing_cos and reach = p.ped_signal_facing_reach).
    t: `dev_pedestrian_signal_state d "dont_walk_flashing"` and `not (dev_pedestrian_signal_countdown d)`.
    ob1: the applicability also selects only those (d, r) for which the subject's footprint did not
      overlap r at the previous observation; the obligation is that it does not overlap r now.
      "Not at the previous observation" of P is written from `rises`, the only operator that reads
      the previous observation: ¬prev(P) ≡ rises(P) ∨ (¬P ∧ ¬rises(¬P)) (and prev(P) ≡
      rises(¬P) ∨ (P ∧ ¬rises(P))). The obligation repeats the whole selection of (d, r) (rule 3c)
      under `forallDevice`/`forallRegion`: at every selected pair the footprint is off r.
    e1/e2 (with ref2's words): `since (no sidewalk occupied) (lawful step)`, the lawful step being an
      observation at which the subject occupies a roadway or lane r2, occupied a sidewalk at the
      previous observation, and some pedestrian head d2 governing r2 shows walk and is faced by the
      subject (the same facing comparisons). `since` is inclusive: the step's own observation need
      not be off the sidewalk, every later one is. A later step from a sidewalk passes through a
      sidewalk observation and so ends the run: the step the exception reads is the latest.
    r: each composition is `not (ruleApplies …)`; the two LVMC_11_46_030 rules bind their subject to
      a road user v of the scene: `not (existsUser v (ruleApplies o1 ∨ ruleApplies o2))`.

  No narrowing of my own: every choice above is the record's applicability and obligation.
  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_283_1d3_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedSignalFacingCos : Term := .param "p.ped_signal_facing_cos"
def pPedSignalFacingReach : Term := .param "p.ped_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Conjunction of a list. -/
def allOf : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (allOf rest)

/-- φ held at the previous observation (from `rises`, which alone reads it). -/
def prev (φ : Formula) : Formula :=
  .or (.rises (.not φ)) (.and φ (.not (.rises φ)))

/-- φ did not hold at the previous observation. -/
def notPrev (φ : Formula) : Formula :=
  .or (.rises φ) (.and (.not φ) (.not (.rises (.not φ))))

/-- Some region of kind roadway, or some of kind lane, satisfies φ. -/
def someRoadwayOrLane (v : String) (φ : Formula) : Formula :=
  .or (.existsRegion (.lit "roadway") v φ) (.existsRegion (.lit "lane") v φ)

/-- Every region of kind roadway and every one of kind lane satisfies φ. -/
def everyRoadwayAndLane (v : String) (φ : Formula) : Formula :=
  .and (.forallRegion (.lit "roadway") v φ) (.forallRegion (.lit "lane") v φ)

/-- The subject's footprint overlaps region `r`. -/
def occupies (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- The subject's footprint overlaps some sidewalk. -/
def onSidewalk (sw : String) : Formula :=
  .existsRegion (.lit "sidewalk") sw (.atom "rel_occupies" [vSubject, .var sw] [])

/-- Δ from the subject's position to the head `d`, component `k`. -/
def delta (d k : String) : Term :=
  .sub (.measure "dev_position" [.var d, .lit k]) (.measure "kin_position" [vSubject, .lit k])

/-- h·Δ, h the subject's heading. -/
def headingDot (d : String) : Term :=
  .add (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (delta d "x"))
       (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (delta d "y"))

/-- |Δ|². -/
def distSq (d : String) : Term :=
  .add (.mul (delta d "x") (delta d "x")) (.mul (delta d "y") (delta d "y"))

/-- The subject faces the head `d`: ahead, within the cone, within the reach. -/
def faces (d : String) : Formula :=
  allOf
    [ .cmp (headingDot d) .gt zeroMetres
    , .cmp (.mul (headingDot d) (headingDot d)) .ge
        (.mul (.mul pPedSignalFacingCos pPedSignalFacingCos) (distSq d))
    , .cmp (distSq d) .le (.mul pPedSignalFacingReach pPedSignalFacingReach) ]

/-- c0 and t: head `d` governs `r`, shows dont_walk_flashing without countdown, and is faced. -/
def flashingFaced (d r : String) : Formula :=
  allOf
    [ .atom "dev_governs" [.var d, .var r] []
    , .atom "dev_pedestrian_signal_state" [.var d, .lit "dont_walk_flashing"] []
    , .not (.atom "dev_pedestrian_signal_countdown" [.var d] [])
    , faces d ]

/-- The record's selection of (d, r): the above, and the footprint off r at the previous observation. -/
def selected (d r : String) : Formula :=
  .and (flashingFaced d r) (notPrev (occupies r))

/-- e1 (ref2's words): a step onto roadway or lane r2 from a sidewalk while a head governing r2
    showed walk and the subject faced it. -/
def lawfulStep : Formula :=
  someRoadwayOrLane "r2"
    (allOf
      [ occupies "r2"
      , prev (onSidewalk "sw_before")
      , .existsDevice (.lit "pedestrian_signal") "d2"
          (allOf
            [ .atom "dev_governs" [.var "d2", .var "r2"] []
            , .atom "dev_pedestrian_signal_state" [.var "d2", .lit "walk"] []
            , faces "d2" ]) ])

/-- e1 + e2: continuing the crossing begun by that step: no sidewalk occupied since. -/
def continuingLawfulCrossing : Formula :=
  .since (.not (onSidewalk "sw_since")) lawfulStep

/-- r: the compositions, each as an exception. -/
def notExcepted : Formula :=
  allOf
    [ .not (.ruleApplies "NRS_484B_287_1c" [("subject", "subject")])
    , .not (.ruleApplies "NRS_484B_287_1d" [("subject", "subject")])
    , .not (.ruleApplies "NRS_484B_287_1e" [("subject", "subject")])
    , .not (.ruleApplies "LVMC_11_30_060_A" [("subject", "subject")])
    , .not (.ruleApplies "LVMC_11_30_060_B" [("subject", "subject")])
    , .not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")])
    , .not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")])
    , .not (.existsUser "v"
        (.or (.ruleApplies "LVMC_11_46_030_o1" [("subject", "v")])
             (.ruleApplies "LVMC_11_46_030_o2" [("subject", "v")]))) ]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- Applicability: c0 (condition): Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:; t (trigger): While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and flashing but is not accompanied by a countdown timer,; s2 (exception): but a pedestrian; e1 (exception): who entered the highway lawfully pursuant to subparagraph (1); e2 (exception): may continue to cross the highway -/
def applicability : Formula :=
  allOf
    [ notExcepted
    , .existsDevice (.lit "pedestrian_signal") "d" (someRoadwayOrLane "r" (selected "d" "r"))
    , .not continuingLawfulCrossing ]

/-- Obligation: ob1 (obligation): may not proceed to cross the highway, -/
def obligation : Formula :=
  .forallDevice (.lit "pedestrian_signal") "d"
    (everyRoadwayAndLane "r" (.implies (selected "d" "r") (.not (occupies "r"))))

def rule : Rule :=
  { id := "NRS_484B_283_1d3_o1"
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

end TrafficSpec.Rules.NRS_484B_283_1d3_o1
