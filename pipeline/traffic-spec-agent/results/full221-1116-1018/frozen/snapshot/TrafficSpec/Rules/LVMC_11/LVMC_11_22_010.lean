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
    h1 — the binder `subject`'s class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    h3 — applicability: kin_speed(subject) > p.halt_speed_tolerance ("operating" read through the
         vehicle's motion: the record's own observable reading, not restated).
    h2 + h4 — obligation, for every road user o other than the subject (`same` excludes the
         subject itself, whose body trivially overlaps its own):
           not rel_contact(subject, o), and
           rel_ahead_behind_in_lane(o, subject) (o ahead of the subject in a shared lane) →
             not (prim_closest_approach_within(subject, o; p.attention_ttc_min) and
                  prim_closest_approach_distance(subject, o; p.attention_ttc_min)
                    < p.conflict_centre_clearance).
         The distance is undefined where the centres do not approach within the horizon; the
         conjunction with `within` false decides those cases.

  Choices the record left open (declared as narrowings):
    h4 — the record says "in contact with no road user and no structure"; Core's rel_contact
         relates two road users (two track arguments) only, so contact is read against every
         other road user of the scene; contact with a structure is not read.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_22_010

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The other road user, quantified in the obligation. -/
def vOther : Arg := .var "o"

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

/-- h4: a rear-end conflict with `o`: the centres approach within the TTC horizon to a distance
    below the conflict clearance. -/
def rearEndConflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vOther] [pAttentionTtcMin])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pAttentionTtcMin])
      .lt pConflictCentreClearance)

/-- Obligation: h2 (obligation): shall; h4 (standard): give his full time and attention to the operation of the vehicle -/
def obligation : Formula :=
  .forallUser "o"
    (.implies (.not (.same vOther vSubject))
      (.and (.not (.atom "rel_contact" [vSubject, vOther] []))
        (.implies (.atom "rel_ahead_behind_in_lane" [vOther, vSubject] [])
          (.not rearEndConflict))))

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
      [ { span := "h4"
          why := "contact is read against every other road user only: Core's rel.contact relates two tracks, so the record's 'no structure' limb is not read"
          kind := "reading" } ]
    surrogate := true }

end TrafficSpec.Rules.LVMC_11_22_010
