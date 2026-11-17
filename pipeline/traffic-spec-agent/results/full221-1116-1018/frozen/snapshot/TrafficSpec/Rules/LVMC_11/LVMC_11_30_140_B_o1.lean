/-
  LVMC_11_30_140_B_o1 — LVMC-11-30-140-B

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Any pedestrian who is not wholly or partially blind
    s2 (subject): or any driver of any vehicle
    s3 (trigger): who approaches or comes in contact with
    s4 (condition): a person wholly or partially blind, carrying a cane or walking stick white in color, or white tipped in red, or being assisted by a person
    s5 (condition): with wisdom
    s6 (standard): shall immediately
    s7 (obligation): come to a full stop
    s8 (sibling): and take such precautions before proceeding
    s9 (sibling): as may be necessary to avoid an accident or injury to the person wholly or partially blind

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.pedestrian_with_white_cane_or_guide_animal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['rel.centre_distance', 'rel.contact'], derived ['drv.motion.complete_halt']
    s4: atoms ['ru.pedestrian_with_white_cane_or_guide_animal'], derived []
    s7: atoms [], derived ['drv.motion.complete_halt']

  How each is written:
    s1/s2 → `clsSubject`: a member of the pedestrian aggregate that is not of the class
      ru.pedestrian_with_white_cane_or_guide_animal, or a member of the vehicle aggregate (the
      driver read through the vehicle's controlled motion — the record's observable reading).
    s4 → `protectedPerson b`: some other road user `b` (not `same` as the subject) of the class
      ru.pedestrian_with_white_cane_or_guide_animal; `b` is anchored to the subject by the
      relations of s3, which read both.
    s3 → `event b`: contact begins (`rises` of rel_contact subject b), or the centre distance falls
      to p.blind_person_approach_reach (`rises` of the comparison) while the subject is not at
      rest (not drv.motion.complete_halt with p.halt_speed_tolerance).
    s6/s7 → `obligation`: drv.motion.complete_halt of the subject at some observation of the
      time window ahead of length p.immediate_stop_window, measured on the subject (`within`);
      a window past the trace's end is unknown, as the record states.
    s5 is the node's residue; s8/s9 are siblings, not this node's.
  No choice beyond the record's was needed: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_30_140_B_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The protected person, a quantifier variable of the applicability. -/
def vBlind : Arg := .var "blind_person"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pBlindPersonApproachReach : Term := .param "p.blind_person_approach_reach"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pImmediateStopWindow : Term := .param "p.immediate_stop_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- drv.motion.complete_halt of the subject (s3's "not at rest", s7's "full stop"). -/
def subjectAtRest : Formula :=
  .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s1: a pedestrian not of the class that marks a wholly or partially blind person. -/
def clsPedestrian : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] [])
       (.not (.atom "ru_pedestrian_with_white_cane_or_guide_animal" [vSubject] []))

/-- s2: a vehicle, read through its controlled motion. -/
def clsVehicle : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .or clsPedestrian clsVehicle

/-- s4: the protected person, another road user of the white-cane / led class. -/
def protectedPerson : Formula :=
  .and (.not (.same vBlind vSubject))
       (.atom "ru_pedestrian_with_white_cane_or_guide_animal" [vBlind] [])

/-- s3 "comes in contact with": contact begins at this observation. -/
def contactBegins : Formula :=
  .rises (.atom "rel_contact" [vSubject, vBlind] [])

/-- s3 "approaches": the centre distance falls to the reach while the subject is not at rest. -/
def approaches : Formula :=
  .and (.rises (.cmp (.measure "rel_centre_distance" [vSubject, vBlind]) .le pBlindPersonApproachReach))
       (.not subjectAtRest)

/-- Applicability: s3 (trigger): who approaches or comes in contact with; s4 (condition): a person wholly or partially blind, carrying a cane or walking stick white in color, or white tipped in red, or being assisted by a person; s5 (condition): with wisdom -/
def applicability : Formula :=
  .existsUser "blind_person" (.and protectedPerson (.or contactBegins approaches))

/-- Obligation: s6 (standard): shall immediately; s7 (obligation): come to a full stop -/
def obligation : Formula :=
  .within .time pImmediateStopWindow "subject" subjectAtRest

def rule : Rule :=
  { id := "LVMC_11_30_140_B_o1"
    laws := ["LVMC-11-30-140-B"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "immediately"
          concepts := ["drv.motion.complete_halt"]
          params := ["p.immediate_stop_window"]
          convention := "The stop is immediate when the subject is at rest within a window ahead of the approach or contact event no longer than a perception-reaction time plus the braking time from an urban approach speed (AASHTO stopping-sight-distance model)."
          surrogate := false } ]
    residues := ["'with wisdom' qualifies the person assisting, not the person protected; that the person assisted is wholly or partially blind and is being assisted is what identifies the protected person, and a helper's wisdom, a state of mind no trace shows, does not change that identification, so the duty owed to the person assisted is the same whether or not the helper's wisdom holds."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_30_140_B_o1
