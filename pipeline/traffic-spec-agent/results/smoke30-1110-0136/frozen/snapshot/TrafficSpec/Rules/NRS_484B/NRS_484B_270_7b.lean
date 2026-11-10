/-
  NRS_484B_270_7b — NRS-484B-270-7b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    v1 (subject): The operator of a bicycle,
    v2 (subject): an electric bicycle
    v3 (subject): or an electric scooter
    v4 (obligation): shall not: Overtake and pass a motor vehicle
    v5 (standard): unless the operator can do so safely without endangering himself or herself or the occupants of the motor vehicle.

  Elements (span → atoms, derived):
    v1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle'], derived []
    v2: atoms ['ru.aggregate=DEF-NRS-484B-017::electric_bicycle'], derived []
    v3: atoms ['ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    v4: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived ['drv.interaction.overtaking']

  How each span is written:
    v1–v3: the class of `x` is the disjunction of the three admitted aggregates, each the atom
      `ru_aggregate` with the aggregate id as its literal (the operator read through the device's
      controlled motion is the record's own observable reading).
    v4: the motor vehicle overtaken is quantified, not a binder: the rule applies where some road
      user `y` other than `x`, a member of DEF-NRS-484A-130::motor_vehicle, is overtaken by `x`
      (drv_interaction_overtaking with the same-direction and speed tolerances).
    v5: for every such `y`, the lateral component of rel_surface_gap(x, y) is at least
      p.overtaking_lateral_clearance; and for every road user `z` other than `x` and `y`, not both
      prim_closest_approach_within(x, z) over p.conflict_time_horizon and the
      prim_closest_approach_distance(x, z) over that horizon below p.conflict_centre_clearance.
      `z` is tied to the binder by the two primitives that read `x` and `z`.

  No choice beyond the record's obligation was needed; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_7b

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The quantified motor vehicle overtaken, and the other road users read for conflicts. -/
def vY : Arg := .var "y"
def vZ : Arg := .var "z"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pOvertakingLateralClearance : Term := .param "p.overtaking_lateral_clearance"
def pSameDirectionCosTolerance : Term := .param "p.same_direction_cos_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
      (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- v4: `x` overtakes `y`, a motor vehicle other than `x`. -/
def overtakesMotorVehicle : Formula :=
  .and (.not (.same vX vY))
    (.and (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-130::motor_vehicle"] [])
      (.derived "drv_interaction_overtaking" [vX, vY]
        [pSameDirectionCosTolerance, pMotionSpeedTolerance]))

/-- Applicability: v4 — some motor vehicle is overtaken by `x` at the observation. -/
def applicability : Formula := .existsUser "y" overtakesMotorVehicle

/-- v5: the pass leaves the lateral clearance to the overtaken motor vehicle. -/
def lateralClearanceKept : Formula :=
  .cmp (.measure "rel_surface_gap" [vX, vY, .lit "lateral"]) .ge pOvertakingLateralClearance

/-- v5: `z` stands in a predicted conflict with `x` (traffic-conflict technique). -/
def predictedConflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vZ] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, vZ] [pConflictTimeHorizon])
      .lt pConflictCentreClearance)

/-- v5: no road user other than `x` and `y` is in a predicted conflict with `x`. -/
def noOtherConflict : Formula :=
  .forallUser "z"
    (.implies (.and (.not (.same vZ vX)) (.not (.same vZ vY)))
      (.not predictedConflict))

/-- Obligation: v4 (obligation): shall not: Overtake and pass a motor vehicle; v5 (standard): unless the operator can do so safely without endangering himself or herself or the occupants of the motor vehicle. -/
def obligation : Formula :=
  .forallUser "y"
    (.implies overtakesMotorVehicle (.and lateralClearanceKept noOtherConflict))

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
      [ { standard := "can do so safely without endangering himself or herself or the occupants of the motor vehicle"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.surface_gap"]
          params := ["p.overtaking_lateral_clearance", "p.conflict_time_horizon", "p.conflict_centre_clearance"]
          convention := "Endangering the occupants of the motor vehicle and the rider himself or herself is read through the measured clearance of the pass and through predicted conflicts: the lateral component of rel.surface_gap between the rider and the overtaken motor vehicle ('distance between the nearest points of two bodies ... its longitudinal and lateral components') is compared with the lateral clearance of the bicycle operating envelope, so the bound moves with the measured gap; and no other road user stands in a predicted conflict with the rider under the traffic-conflict technique (closest approach within the time horizon at a centre distance below the conflict clearance), the magnitude of the predicted closest approach entering the bound. A rel.surface_gap is a clearance, not a centre distance, so the side-by-side pass itself is judged on the bodies' gap."
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_7b
