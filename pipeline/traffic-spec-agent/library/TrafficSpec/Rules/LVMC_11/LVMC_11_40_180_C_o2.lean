/-
  LVMC_11_40_180_C_o2 — LVMC-11-40-180-C

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (trigger): Whenever any person is riding a bicycle, electric bicycle, or electric scooter upon a sidewalk
    c2 (sibling): such person shall yield
    c3 (sibling): the right-of-way
    c4 (sibling): to any pedestrian
    c5 (obligation): and shall give audible signal
    c6 (trigger): before overtaking and passing
    c7 (condition): such pedestrian

  Elements (span → atoms, derived):
    c1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle', 'ru.aggregate=DEF-LVMC-11-02-083::electric_scooter', 'rel.occupies', 'st.sidewalk'], derived ['drv.motion.complete_halt']
    c5: atoms ['sig.horn', 'sig.siren'], derived []
    c6: atoms ['rel.bearing', 'rel.longitudinal_overlap', 'rel.same_direction'], derived ['drv.interaction.overtake_pass']
    c7: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []

  How each span is written:
    c1 — the subject's class is the disjunction of the three admitted aggregates (`clsSubject`).
         "riding … upon a sidewalk" is `ridingOnSidewalk`: the subject occupies (rel.occupies) some
         region of kind sidewalk (st.sidewalk, as the quantifier's kind) and is not at rest
         (not drv.motion.complete_halt with p.halt_speed_tolerance). Per the record it must hold at
         some observation while the pass is under way, from its onset to its recognition:
         `.since (.not aheadAligned) ridingOnSidewalk` read at the recognition — some observation
         at which the subject rode on the sidewalk with no aligned-ahead observation after it; the
         onset is the last aligned-ahead observation, so the observation lies in [onset, recognition].
    c6 — the pass is drv.interaction.overtake_pass(subject, p; p.overtake_window,
         p.overtake_same_direction_cos), which holds at the recognition only. The onset of the act
         is `aheadAligned` (rel.bearing longitudinal component > 0, rel.longitudinal_overlap < 0,
         rel.same_direction with p.overtake_same_direction_cos), read with `atLast` over
         p.overtake_window from the recognition, as the record states.
    c7 — p is a road user of the scene of the admitted aggregate DEF-NRS-484A-165::pedestrian.
         The record's "not the subject" is not written as `same`: overtake_pass(subject, subject)
         never holds (no bearing ahead of oneself), so the conjunct would decide nothing.
    c5 — the act is sig.horn or sig.siren sounding for the subject (`signal`). The search, read at
         the onset, runs back through the run of observations at which p is ahead of the subject
         (`aheadOf`: the record's "p stays ahead", rel.bearing and rel.longitudinal_overlap, without
         the alignment that only fixes the onset): `.since aheadOf (.and aheadOf signal)`. It is
         compliant on a signal while p is ahead, violated where the run is observed to begin
         (p alongside or behind) with no signal, unknown where the run reaches the recording's start
         or the signal is unobserved. A previous pass's recognition (p behind) ends the run too.
    The obligation repeats the applicability's whole selection of p, under `forallUser`: every
    pedestrian whose pass is recognized here, with the subject riding on the sidewalk during it,
    is to have had the signal before the onset.

  Choices the text did not dictate: none beyond the record's (no narrowing of my own).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_40_180_C_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The pedestrian passed (quantifier variable) and the sidewalk region (quantifier variable). -/
def vP : Arg := .var "p"
def vSw : Arg := .var "sw"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-082::electric_bicycle"] [])
         (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-083::electric_scooter"] []))

/-- c7: p is a pedestrian. -/
def isPedestrian : Formula := .atom "ru_aggregate" [vP, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- c6: p is ahead of the subject — bearing's longitudinal component (the `x` of the bearing in
    the subject's frame, (long, lat)) positive, projections apart. -/
def aheadOf : Formula :=
  .and (.cmp (.measure "rel_bearing" [vSubject, vP, .lit "x"]) .gt zeroMetres)
       (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vP]) .lt zeroMetres)

/-- c6: p ahead with headings aligned — the observation that is the onset when it is the last. -/
def aheadAligned : Formula :=
  .and aheadOf (.atom "rel_same_direction" [vSubject, vP] [pOvertakeSameDirectionCos])

/-- c6: the pass of p by the subject, recognized at this observation. -/
def passRecognized : Formula :=
  .derived "drv_interaction_overtake_pass" [vSubject, vP] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- c1: the subject occupies a sidewalk region and is not at rest. -/
def ridingOnSidewalk : Formula :=
  .and (.existsRegion (.lit "sidewalk") "sw" (.atom "rel_occupies" [vSubject, vSw] []))
       (.not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]))

/-- c1 read over the pass: at some observation from the onset (last aligned-ahead) to now. -/
def ridingOnSidewalkDuringPass : Formula := .since (.not aheadAligned) ridingOnSidewalk

/-- The selection of p: a pedestrian whose pass is recognized here, ridden on the sidewalk. -/
def passOfPedestrianOnSidewalk : Formula :=
  .and isPedestrian (.and passRecognized ridingOnSidewalkDuringPass)

/-- c5: an audible signal of the subject. -/
def signal : Formula :=
  .or (.atom "sig_horn" [vSubject] []) (.atom "sig_siren" [vSubject] [])

/-- c5/c6: at the onset, a signal at some observation of the run with p ahead that leads to it. -/
def signalBeforeOnset : Formula :=
  .atLast .time pOvertakeWindow "subject" aheadAligned (.since aheadOf (.and aheadOf signal))

/-- Applicability: c1 (trigger): Whenever any person is riding a bicycle, electric bicycle, or electric scooter upon a sidewalk; c6 (trigger): before overtaking and passing; c7 (condition): such pedestrian -/
def applicability : Formula := .existsUser "p" passOfPedestrianOnSidewalk

/-- Obligation: c5 (obligation): and shall give audible signal -/
def obligation : Formula := .forallUser "p" (.implies passOfPedestrianOnSidewalk signalBeforeOnset)

def rule : Rule :=
  { id := "LVMC_11_40_180_C_o2"
    laws := ["LVMC-11-40-180-C"]
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

end TrafficSpec.Rules.LVMC_11_40_180_C_o2
