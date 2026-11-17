/-
  NRS_484B_270_5a — NRS-484B-270-5a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    w1 (subject): The driver of a motor vehicle
    w2 (standard): shall: Exercise due care
    w3 (obligation): to avoid a collision
    w4 (condition): with a person riding
    w5 (condition): a bicycle, an electric bicycle or an electric scooter.

  Elements (span → atoms, derived):
    w1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    w3: atoms ['rel.contact'], derived []
    w4: atoms ['kin.speed'], derived []
    w5: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []

  How each is written:
    w1: the binder class `ru_aggregate(subject, DEF-NRS-484A-130::motor_vehicle)`; the applicability
        adds nothing beyond it (the record's applicability is the class, read as driven).
    w2 (operationalization, surrogate): at every observation at which the subject's kin.speed is
        above p.halt_speed_tolerance (an implication heading the obligation, as the record's
        obligation opens "At every observation at which ..."), for every road user b of the scene,
        it is not the case that prim.closest_approach_within(subject, b; p.conflict_horizon) holds
        with prim.closest_approach_distance(subject, b; p.conflict_horizon) strictly below
        p.conflict_centre_clearance ("below").
    w3: `not rel_contact(subject, b)`.
    w4: `kin_speed(b) > p.halt_speed_tolerance`, conjoined into the antecedent selecting b.
    w5: the disjunction of the three aggregates on b, by their ids, never expanded into classes;
        b is distinct from the subject (`same`).
  The quantified road user b is tied to the subject by rel.contact and the two closest-approach
  primitives, each of which reads both.

  No narrowing of this session's own: every choice above is the record's obligation as worded.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_5a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The road user quantified over by the obligation (the rider). -/
def vRider : Arg := .var "b"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- w4: a road user moving above the halt tolerance. -/
def moving (x : Arg) : Formula :=
  .cmp (.measure "kin_speed" [x]) .gt pHaltSpeedTolerance

/-- w5: b is a member of one of the three admitted aggregates. -/
def riderDevice : Formula :=
  .or (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
         (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- w4 + w5: b is another road user, a riding bicycle, electric bicycle or electric scooter. -/
def isRider : Formula :=
  .and (.not (.same vSubject vRider)) (.and riderDevice (moving vRider))

/-- w2 (operationalization): a closest approach within the horizon below the centre clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vRider] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vRider] [pConflictHorizon])
      .lt pConflictCentreClearance)

/-- w3: no collision. -/
def collision : Formula := .atom "rel_contact" [vSubject, vRider] []

/-- Applicability: the subject's class (binder) is the whole applicability the record states. -/
def applicability : Formula := .tt

/-- Obligation: w2 (standard): shall: Exercise due care; w3 (obligation): to avoid a collision -/
def obligation : Formula :=
  .implies (moving vSubject)
    (.forallUser "b"
      (.implies isRider (.and (.not collision) (.not conflict))))

def rule : Rule :=
  { id := "NRS_484B_270_5a"
    laws := ["NRS-484B-270-5a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "due care to avoid a collision (a standard of the driver's care, a state of mind)"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.halt_speed_tolerance", "p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: while the vehicle moves, care shows in its keeping no closest approach to the rider, under constant velocities, within a time-to-collision horizon and below a centre clearance of about a car's half-length plus half a body width"
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_270_5a
