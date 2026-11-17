/-
  LVMC_11_22_010 — LVMC-11-22-010

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    h1 (subject): A person
    h2 (obligation): shall
    h3 (condition): when operating a vehicle
    h4 (standard): give his full time and attention to the operation of the vehicle

  Elements (span → atoms, derived):
    h1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    h2: atoms ['rel.contact'], derived []
    h3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.speed'], derived []

  How each is written:
    h1 / h3 'vehicle': the binder class `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
    h3 'operating': `kin_speed(subject) > p.halt_speed_tolerance` (the record's observable reading).
    h2 + h4 (the surrogate standard), two conjuncts:
      - no contact: for every road user `other` that is not the subject, `¬ rel_contact(subject, other)`.
      - no rear-end conflict: for every road user `lead` other than the subject that is ahead of the
        subject in its lane (`rel_ahead_behind_in_lane(lead, subject)`: the first argument is the one
        ahead), not (`prim_closest_approach_within(subject, lead; p.attention_ttc_min)` and
        `prim_closest_approach_distance(subject, lead; p.attention_ttc_min) < p.conflict_centre_clearance`).
        Where the centres do not approach within the horizon the conjunction is decided false by its
        first operand, so the undefined distance does not leave it unknown.

  Choice the record left open (declared as a narrowing on h2):
    - the record states "in contact with no road user and no structure"; `rel_contact` relates two
      tracks only (its arguments are track, track), so the formula checks contact with every other
      road user and does not read contact with a structure region.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_22_010

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables of the obligation. -/
def vOther : Arg := .var "other"
def vLead : Arg := .var "lead"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pAttentionTtcMin : Term := .param "p.attention_ttc_min"
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: h3 (condition): when operating a vehicle — the vehicle is in motion. -/
def applicability : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- h2 / h4: the subject's body touches no other road user. -/
def noContact : Formula :=
  .forallUser "other"
    (.implies (.not (.same vOther vSubject))
      (.not (.atom "rel_contact" [vSubject, vOther] [])))

/-- h4: the centres of the subject and the road user `lead` approach within the time-to-collision
    horizon to a centre distance below the conflict clearance. -/
def rearEndConflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vLead] [pAttentionTtcMin])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vLead] [pAttentionTtcMin])
      .lt pConflictCentreClearance)

/-- h4: no road user ahead of the subject in its lane is closed on to a rear-end conflict. -/
def noRearEndConflict : Formula :=
  .forallUser "lead"
    (.implies
      (.and (.not (.same vLead vSubject)) (.atom "rel_ahead_behind_in_lane" [vLead, vSubject] []))
      (.not rearEndConflict))

/-- Obligation: h2 (obligation): shall; h4 (standard): give his full time and attention to the operation of the vehicle -/
def obligation : Formula :=
  .and noContact noRearEndConflict

def rule : Rule :=
  { id := "LVMC_11_22_010"
    laws := ["LVMC-11-22-010"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "full time and attention to the operation of the vehicle"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.ahead_behind_in_lane", "rel.contact"]
          params := ["p.attention_ttc_min", "p.conflict_centre_clearance"]
          convention := "surrogate safety measure for inattention: a driver who attends to the driving task neither collides nor closes on the road user ahead in its lane to a time-to-collision below the rear-end conflict threshold"
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "h2"
          why := "the record's 'in contact with no road user and no structure' is written with rel.contact, whose arguments are two road users: contact of the subject with another road user is read, contact with a structure region is not"
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.LVMC_11_22_010
