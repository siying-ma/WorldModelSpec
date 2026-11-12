/-
  NRS_484B_280_1a — NRS-484B-280-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    p1 (subject): A driver of a motor vehicle
    p2 (standard): shall: Exercise due care
    p3 (obligation): to avoid a collision with a pedestrian.

  Elements (span → atoms, derived):
    p1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    p3: atoms ['rel.contact', 'ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []

  How each is written:
    p1 — the class of `ego`: `ru_aggregate ego "DEF-NRS-484A-130::motor_vehicle"`, the admitted
      aggregate claimed whole. "A driver of" is the plan's observable reading (the vehicle's
      controlled motion); no formula of its own. No trigger or condition span: the applicability
      is `.tt` and the duty is judged at every observation.
    p3 — every road user `p` of the scene other than ego (`.not (.same p ego)`) that is a
      pedestrian (`ru_aggregate p "DEF-NRS-484A-165::pedestrian"`); "a collision" is
      `rel_contact ego p`, which must not hold.
    p2 — the operationalization "due care": ego at rest (`drv_motion_at_rest ego` under
      p.rest_speed_tolerance) discharges the duty; otherwise the centres must not approach within
      p.conflict_horizon (`prim_closest_approach_within`) to a centre distance below
      p.pedestrian_conflict_clearance (`prim_closest_approach_distance`, compared with `lt`). The
      distance is read only inside a conjunction with `prim_closest_approach_within`, where it is
      defined; where the centres do not approach, the conjunction is decided false.

  Choices the record left open: none beyond the record's own narrowings; the obligation is the
  record's `obligation` sentence written operator for operator.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_280_1a

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The road user quantified over in p3. -/
def vPed : Arg := .var "p"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pPedestrianConflictClearance : Term := .param "p.pedestrian_conflict_clearance"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- Applicability: (no trigger/condition span) -/
def applicability : Formula := .tt

/-- p3: `p` is a pedestrian other than ego. -/
def isOtherPedestrian : Formula :=
  .and (.not (.same vPed vEgo))
    (.atom "ru_aggregate" [vPed, .lit "DEF-NRS-484A-165::pedestrian"] [])

/-- p2: ego is at rest. -/
def egoAtRest : Formula := .derived "drv_motion_at_rest" [vEgo] [pRestSpeedTolerance]

/-- p3: a collision between ego and `p`. -/
def collision : Formula := .atom "rel_contact" [vEgo, vPed] []

/-- p2: the centres approach within the horizon to a centre distance below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vEgo, vPed] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vEgo, vPed] [pConflictHorizon])
      .lt pPedestrianConflictClearance)

/-- Obligation: p2 (standard): shall: Exercise due care; p3 (obligation): to avoid a collision with a pedestrian. -/
def obligation : Formula :=
  .forallUser "p"
    (.implies isOtherPedestrian
      (.or egoAtRest (.and (.not collision) (.not conflict))))

def rule : Rule :=
  { id := "NRS_484B_280_1a"
    laws := ["NRS-484B-280-1a"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "due care"
          concepts := ["drv.motion.at_rest", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.pedestrian_conflict_clearance", "p.rest_speed_tolerance"]
          convention := "Traffic-conflict technique: while the motor vehicle moves (drv.motion.at_rest under p.rest_speed_tolerance does not hold), a pedestrian whose centre it approaches within the time-to-collision horizon p.conflict_horizon (prim.closest_approach_within) to a centre distance below p.pedestrian_conflict_clearance (prim.closest_approach_distance) is a conflict the driver's care did not avoid; the projected distance enters the bound itself, so a nearer approach is a graver one. Care is a state of mind and the standard is the whole duty: the rule is a surrogate."
          surrogate := true } ]
    residues := []
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_280_1a
