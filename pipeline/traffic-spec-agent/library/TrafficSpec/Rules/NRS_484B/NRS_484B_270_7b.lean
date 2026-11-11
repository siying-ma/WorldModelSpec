/-
  NRS_484B_270_7b — NRS-484B-270-7b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (subject): The operator of a bicycle, an electric bicycle or an electric scooter
    a2 (obligation): shall not: Overtake and pass a motor vehicle
    a4 (standard): unless the operator can do so safely without endangering himself or herself or the occupants of the motor vehicle.

  Elements (span → atoms, derived):
    a1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    a2: atoms ['rel.same_direction', 'rel.longitudinal_overlap', 'kin.speed', 'ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived ['drv.interaction.overtaking_alongside']

  How each is written:
    a1 — the class of `x`: membership of any of the three admitted aggregates (`ru_aggregate` with
         the aggregate id), as a disjunction.
    a2 — the motor vehicle passed is a road user `y` other than `x` carrying
         DEF-NRS-484A-130::motor_vehicle that `x` is overtaking alongside
         (drv.interaction.overtaking_alongside with p.same_direction_cosine and
         p.overtaking_speed_margin; the concept reads rel.same_direction, rel.longitudinal_overlap
         and kin.speed). The applicability is that some such `y` exists; the obligation is stated
         for every such `y`.
    a4 — the standard, for each such `y`: the surface gap between the bodies (`rel_surface_gap`
         read without a component, i.e. its distance) is at least p.passing_lateral_clearance;
         and no road user `z` other than `x` and `y` both approaches `x` within
         p.immediate_hazard_gap (prim.closest_approach_within) and has a closest-approach centre
         distance (prim.closest_approach_distance) below p.conflict_clearance.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_7b

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantifier variables: the motor vehicle passed, and any other road user. -/
def vY : Arg := .var "y"
def vZ : Arg := .var "z"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pImmediateHazardGap : Term := .param "p.immediate_hazard_gap"
def pOvertakingSpeedMargin : Term := .param "p.overtaking_speed_margin"
def pPassingLateralClearance : Term := .param "p.passing_lateral_clearance"
def pSameDirectionCosine : Term := .param "p.same_direction_cosine"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
      (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- a2: `y`, another road user, is a motor vehicle that `x` is overtaking alongside. -/
def overtakingMotorVehicle : Formula :=
  .and (.not (.same vX vY))
    (.and (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-130::motor_vehicle"] [])
      (.derived "drv_interaction_overtaking_alongside" [vX, vY] [pSameDirectionCosine, pOvertakingSpeedMargin]))

/-- Applicability: (no trigger/condition span) — some motor vehicle is being overtaken alongside by `x`. -/
def applicability : Formula := .existsUser "y" overtakingMotorVehicle

/-- a4, the occupants and the rider against the vehicle passed: the surface gap kept to `y`. -/
def clearanceKept : Formula :=
  .cmp (.measure "rel_surface_gap" [vX, vY]) .ge pPassingLateralClearance

/-- a4, the rider against other traffic: `z` is predicted to come within the conflict radius of `x`
    within the critical gap. -/
def conflictWith : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vZ] [pImmediateHazardGap])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, vZ] [pImmediateHazardGap]) .lt pConflictClearance)

def noConflict : Formula :=
  .forallUser "z"
    (.implies (.and (.not (.same vZ vX)) (.not (.same vZ vY)))
      (.not conflictWith))

/-- Obligation: a2 (obligation): shall not: Overtake and pass a motor vehicle; a4 (standard): unless the operator can do so safely without endangering himself or herself or the occupants of the motor vehicle. -/
def obligation : Formula :=
  .forallUser "y" (.implies overtakingMotorVehicle (.and clearanceKept noConflict))

def rule : Rule :=
  { id := "NRS_484B_270_7b"
    laws := ["NRS-484B-270-7b"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "safely without endangering himself or herself or the occupants of the motor vehicle"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.surface_gap"]
          params := ["p.passing_lateral_clearance", "p.conflict_clearance", "p.immediate_hazard_gap"]
          convention := "Passing-clearance convention for cycles passing motor vehicles (the endangerment of the occupants and of the rider by the vehicle passed): the surface gap between the two bodies while side by side is at least the passing clearance, read by its degree. Surrogate-safety closest-approach convention (the endangerment of the rider by other traffic): no other road user is predicted, under constant velocities within the critical gap, to come nearer the rider than the conflict radius."
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_7b
