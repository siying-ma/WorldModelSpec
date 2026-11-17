/-
  NRS_484B_270_7b — NRS-484B-270-7b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    y1 (subject): The operator of a bicycle, an electric bicycle or an electric scooter
    y2 (obligation): shall not: Overtake and pass a motor vehicle
    y3 (standard): unless the operator can do so safely without endangering himself or herself or the occupants of the motor vehicle.

  Elements (span → atoms, derived):
    y1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    y2: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived ['drv.interaction.overtake_pass']

  How each is written:
    y1 — the binder class: the disjunction of the three admitted aggregates, each `ru_aggregate`
         with its id. The applicability adds nothing (no trigger or condition span).
    y2 — for every road user m other than the subject that is a member of
         DEF-NRS-484A-130::motor_vehicle, the act `drv_interaction_overtake_pass(subject, m)` with
         window p.overtake_window and same_dir_cos p.overtake_same_direction_cos. The concept holds
         at the recognition only (its contract), so the duty is judged there (at_recognition).
    y3 — the operationalization, read over the act from its beginning to its recognition, as the
         record states: `since safe (aheadAligned ∧ safe)`. The beginning is the last observation
         at which m was ahead of the subject with headings aligned (the concept's own definition of
         the act's beginning: the longitudinal component of m's position relative to the subject's
         along the subject's heading positive, rel.longitudinal_overlap negative, rel.same_direction
         within p.overtake_same_direction_cos — the reads of drv.interaction.overtake_pass). `since`
         with the beginning conjoined with `safe` requires `safe` at the beginning and at every
         observation after it up to the recognition; an earlier beginning is no escape, since
         every observation after it, the latest beginning included, must be safe.
         safe = not rel_contact(subject, m) ∧ rel_surface_gap(subject, m) (the distance between the
         bodies) ≥ p.bicycle_pass_safe_gap ∧ for every road user u other than the subject and m,
         not (prim_closest_approach_within(subject, u) over p.conflict_horizon ∧
         prim_closest_approach_distance(subject, u) < p.conflict_centre_clearance).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_7b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"
/-- The passed motor vehicle, and any other road user during the pass. -/
def vM : Arg := .var "m"
def vU : Arg := .var "u"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pBicyclePassSafeGap : Term := .param "p.bicycle_pass_safe_gap"
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
         (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- Applicability: (no trigger/condition span) — the duty engages every member of the class. -/
def applicability : Formula := .tt

/-- y2: `m` is a motor vehicle other than the subject. -/
def motorVehicle : Formula :=
  .and (.not (.same vM vSubject))
    (.atom "ru_aggregate" [vM, .lit "DEF-NRS-484A-130::motor_vehicle"] [])

/-- y2: the act, at its recognition. -/
def overtakePass : Formula :=
  .derived "drv_interaction_overtake_pass" [vSubject, vM] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- The longitudinal component of m's position relative to the subject, along the subject's heading. -/
def longitudinalOfM : Term :=
  .add
    (.mul (.sub (.measure "kin_position" [vM, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"]))
          (.measure "kin_heading" [vSubject, .lit "x"]))
    (.mul (.sub (.measure "kin_position" [vM, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"]))
          (.measure "kin_heading" [vSubject, .lit "y"]))

/-- The act's beginning: m ahead of the subject with headings aligned. -/
def aheadAligned : Formula :=
  .and (.cmp longitudinalOfM .gt zeroMetres)
    (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vM]) .lt zeroMetres)
          (.atom "rel_same_direction" [vSubject, vM] [pOvertakeSameDirectionCos]))

/-- y3: no conflicting closest approach between the subject and any road user other than m. -/
def noConflict : Formula :=
  .forallUser "u"
    (.implies (.and (.not (.same vU vSubject)) (.not (.same vU vM)))
      (.not (.and (.derived "prim_closest_approach_within" [vSubject, vU] [pConflictHorizon])
                  (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vU] [pConflictHorizon])
                        .lt pConflictCentreClearance))))

/-- y3: the pass is safe at this observation. -/
def safe : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vM] []))
    (.and (.cmp (.measure "rel_surface_gap" [vSubject, vM]) .ge pBicyclePassSafeGap)
          noConflict)

/-- Obligation: y2 (obligation): shall not: Overtake and pass a motor vehicle; y3 (standard): unless the operator can do so safely without endangering himself or herself or the occupants of the motor vehicle. -/
def obligation : Formula :=
  .forallUser "m"
    (.implies (.and motorVehicle overtakePass)
      (.since safe (.and aheadAligned safe)))

def rule : Rule :=
  { id := "NRS_484B_270_7b"
    laws := ["NRS-484B-270-7b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "safely, without endangering the operator or the occupants of the motor vehicle"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact", "rel.surface_gap"]
          params := ["p.bicycle_pass_safe_gap", "p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "bicyclist operating space: a pass is safe where the gap between the rider's body and the passed vehicle's body stays at least the rider's operating-space sway and the bodies never touch; traffic-conflict technique: no other road user comes into a closest approach within a time-to-collision horizon and below a centre clearance during the pass"
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_7b
