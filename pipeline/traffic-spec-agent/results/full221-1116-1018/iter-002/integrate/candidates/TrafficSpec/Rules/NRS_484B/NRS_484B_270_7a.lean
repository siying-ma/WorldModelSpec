/-
  NRS_484B_270_7a — NRS-484B-270-7a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    q1 (subject): The operator of a bicycle, an electric bicycle or an electric scooter
    q2 (standard): shall not: Intentionally
    q4 (obligation): interfere with the movement
    q3 (condition): of a motor vehicle.

  Elements (span → atoms, derived):
    q1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    q3: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    q4: atoms ['rel.bearing', 'kin.accel_longitudinal', 'kin.speed'], derived []

  How each span is written:
    q1 — the binder class and the applicability: the subject is a member of one of the three
         admitted aggregates (`ru_aggregate` with each id), a disjunction. "The operator" is the
         plan's observable reading (the device's controlled motion); nothing further is written.
    q3 — inside the obligation: every road user `m` other than the subject (`same` excludes it)
         that is a member of DEF-NRS-484A-130::motor_vehicle.
    q4 — the movement of `m`: `m` moving (kin_speed above p.halt_speed_tolerance), the subject
         ahead of `m` (`rel_bearing m subject "ahead"`: the longitudinal component of the
         subject's bearing in m's frame is positive), and the movement disturbed (`m`'s
         kin_accel_longitudinal at or below −p.vehicle_evasive_decel).
    q2 — the operationalization (surrogate): the evasive braking above together with
         prim_closest_approach_within(m, subject, p.conflict_horizon) and
         prim_closest_approach_distance(m, subject, p.conflict_horizon) below
         p.conflict_centre_clearance; the obligation forbids that conjunction.

  Choices the record left open: none beyond the above. The quantifier over `m` is a universal
  read at each observation, as the record's obligation states; the moving and motor-vehicle
  conditions are its guard (an implication), the conflict its forbidden consequent.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_7a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The quantified motor vehicle. -/
def vVehicle : Arg := .var "m"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pVehicleEvasiveDecel : Term := .param "p.vehicle_evasive_decel"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
         (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- Applicability: the subject is a member of one of the three aggregates, read as operated (q1). -/
def applicability : Formula := clsSubject

/-- q3: `m` is another road user, a member of DEF-NRS-484A-130::motor_vehicle; q4: `m` is moving. -/
def movingMotorVehicle : Formula :=
  .and (.not (.same vVehicle vSubject))
    (.and (.atom "ru_aggregate" [vVehicle, .lit "DEF-NRS-484A-130::motor_vehicle"] [])
          (.cmp (.measure "kin_speed" [vVehicle]) .gt pHaltSpeedTolerance))

/-- q4 + q2: the subject ahead of `m`, `m` braking evasively, and their closest approach within
    the horizon and below the centre clearance. -/
def interference : Formula :=
  .and (.atom "rel_bearing" [vVehicle, vSubject, .lit "ahead"] [])
    (.and (.cmp (.measure "kin_accel_longitudinal" [vVehicle]) .le (.neg pVehicleEvasiveDecel))
      (.and (.derived "prim_closest_approach_within" [vVehicle, vSubject] [pConflictHorizon])
            (.cmp (.quantity "prim_closest_approach_distance" [vVehicle, vSubject] [pConflictHorizon])
                  .lt pConflictCentreClearance)))

/-- Obligation: q2 (standard): shall not: Intentionally; q4 (obligation): interfere with the movement -/
def obligation : Formula :=
  .forallUser "m" (.implies movingMotorVehicle (.not interference))

def rule : Rule :=
  { id := "NRS_484B_270_7a"
    laws := ["NRS-484B-270-7a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "intentionally interfere (intent, a state of mind, and the degree of interference)"
          concepts := ["kin.accel_longitudinal", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.vehicle_evasive_decel", "p.halt_speed_tolerance", "p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: an interference with a vehicle's movement is a conflict in which the vehicle, with the rider ahead of it, brakes evasively — a deceleration beyond comfortable service braking while their closest approach lies within a time-to-collision horizon and below a centre clearance"
          surrogate := true } ]
    residues := []
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_270_7a
