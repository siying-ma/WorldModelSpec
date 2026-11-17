/-
  LVMC_11_30_140_B_o2 — LVMC-11-30-140-B

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Any pedestrian who is not wholly or partially blind
    s2 (subject): or any driver of any vehicle
    s3 (trigger): who approaches or comes in contact with
    s4 (condition): a person wholly or partially blind, carrying a cane or walking stick white in color, or white tipped in red, or being assisted by a person
    s5 (condition): with wisdom
    s6 (sibling): shall immediately
    s7 (sibling): come to a full stop
    s8 (obligation): and take such precautions before proceeding
    s9 (standard): as may be necessary to avoid an accident or injury to the person wholly or partially blind

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.pedestrian_with_white_cane_or_guide_animal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['rel.centre_distance', 'rel.contact'], derived ['drv.motion.complete_halt']
    s4: atoms ['ru.pedestrian_with_white_cane_or_guide_animal'], derived []
    s8: atoms [], derived ['drv.motion.complete_halt']

  How each is written:
    s1/s2 (binder class): `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"` and not
      `ru_pedestrian_with_white_cane_or_guide_animal subject`, or
      `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`. The driver is read through the vehicle's
      own motion (the record's observable reading).
    s4: the protected person is a road user `b`, not the subject (`.not (.same subject b)`), with
      `ru_pedestrian_with_white_cane_or_guide_animal b`.
    s3: the event `event b` is `rises (rel_contact subject b)` (contact beginning) or
      `rises (rel_centre_distance subject b ≤ p.blind_person_approach_reach)` while the subject is
      not at rest (`drv_motion_complete_halt` with `p.halt_speed_tolerance`).
    s8: "before proceeding" — the subject is not at rest at the judged observation, and
      `since (¬ event b) (halt ∧ once (event b))`: it was at rest at some observation at or after an
      event with b, and no event with b has occurred since then (so that halt follows the latest
      event, as the record states; the latest event is taken at or before the judged observation,
      the record's words). `once φ` is written `since tt φ`.
    s9 (operationalization, surrogate): for every b so selected, the subject is not in contact
      with b and not (`prim_closest_approach_within subject b p.conflict_horizon` and
      `prim_closest_approach_distance subject b p.conflict_horizon < p.conflict_centre_clearance`).
    s5: the record's residue.

  The obligation re-states the applicability's whole selection of b (class, not the subject, the
  event/halt history) and holds the standard for every b so selected.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_30_140_B_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The protected person's quantifier variable. -/
def vB : Arg := .var "b"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pBlindPersonApproachReach : Term := .param "p.blind_person_approach_reach"
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .or
    (.and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] [])
          (.not (.atom "ru_pedestrian_with_white_cane_or_guide_animal" [vSubject] [])))
    (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- The subject is at rest (drv.motion.complete_halt). -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s3: contact with b begins, or the centre distance first falls to the reach while the subject
    is not at rest. -/
def event : Formula :=
  .or (.rises (.atom "rel_contact" [vSubject, vB] []))
      (.and (.rises (.cmp (.measure "rel_centre_distance" [vSubject, vB]) .le pBlindPersonApproachReach))
            (.not halted))

/-- s4 + s8: b is another road user of the protected class, and the subject has been at rest at
    some observation since the latest approach or contact event with b. -/
def selected : Formula :=
  .and (.not (.same vSubject vB))
    (.and (.atom "ru_pedestrian_with_white_cane_or_guide_animal" [vB] [])
          (.since (.not event) (.and halted (.since .tt event))))

/-- s9: contact with b, or a centre course toward b closing below the clearance within the horizon. -/
def conflict : Formula :=
  .or (.atom "rel_contact" [vSubject, vB] [])
      (.and (.derived "prim_closest_approach_within" [vSubject, vB] [pConflictHorizon])
            (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vB] [pConflictHorizon]) .lt
                  pConflictCentreClearance))

/-- Applicability: s3 (trigger): who approaches or comes in contact with; s4 (condition): a person wholly or partially blind, carrying a cane or walking stick white in color, or white tipped in red, or being assisted by a person; s5 (condition): with wisdom -/
def applicability : Formula :=
  .and (.not halted) (.existsUser "b" selected)

/-- Obligation: s8 (obligation): and take such precautions before proceeding; s9 (standard): as may be necessary to avoid an accident or injury to the person wholly or partially blind -/
def obligation : Formula :=
  .forallUser "b" (.implies selected (.not conflict))

def rule : Rule :=
  { id := "LVMC_11_30_140_B_o2"
    laws := ["LVMC-11-30-140-B"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "such precautions ... as may be necessary to avoid an accident or injury to the person wholly or partially blind"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "Traffic-conflict technique: while proceeding, the subject neither touches the protected person (rel.contact) nor is on a course whose closest approach of centres, under constant velocities, comes within p.conflict_horizon (prim.closest_approach_within) at a distance below p.conflict_centre_clearance (prim.closest_approach_distance); an accident or injury is avoided when no such contact or conflict arises."
          surrogate := true } ]
    residues := ["'with wisdom' qualifies the person assisting, not the person protected; that the person assisted is wholly or partially blind and is being assisted is what identifies the protected person, and a helper's wisdom, a state of mind no trace shows, does not change that identification, so the duty owed to the person assisted is the same whether or not the helper's wisdom holds."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.LVMC_11_30_140_B_o2
