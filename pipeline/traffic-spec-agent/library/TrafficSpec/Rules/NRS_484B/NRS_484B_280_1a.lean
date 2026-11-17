/-
  NRS_484B_280_1a — NRS-484B-280-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    x1 (subject): A driver of a motor vehicle
    x2 (standard): shall: Exercise due care
    x3 (obligation): to avoid a collision
    x4 (condition): with a pedestrian.

  Elements (span → atoms, derived):
    x1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    x3: atoms ['rel.contact'], derived []
    x4: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []

  How each is written:
    x1 — the binder class: `ru_aggregate(subject, "DEF-NRS-484A-130::motor_vehicle")`. 'Driver' is
         the record's observable reading (the vehicle's controlled motion); nothing more is added.
    x4 — inside the obligation, as the record states it: every road user `p` of the scene other
         than the subject (`not (same p subject)`) that is a member of
         `DEF-NRS-484A-165::pedestrian` (`ru_aggregate(p, …)`). A scene with no pedestrian leaves the
         duty vacuously met; the applicability is the subject's class alone, as the record says.
    x3 — `not rel_contact(subject, p)`.
    x2 — the operationalization (surrogate): at an observation where `kin_speed(subject)` is above
         `p.halt_speed_tolerance`, it is not the case that `prim_closest_approach_within(subject, p)`
         over `p.conflict_horizon` holds together with `prim_closest_approach_distance(subject, p)`
         over `p.conflict_horizon` below `p.conflict_centre_clearance`. The within-test is the first
         conjunct, so where the centres do not approach within the horizon (the distance undefined)
         the conjunction is decided false.
    The speed guard scopes both the contact and the closest-approach clauses, as the record's
    obligation places "At every observation at which the subject's kin.speed is above …" around
    the whole quantified duty.

  No choice beyond the record's own narrowings was needed; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_280_1a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The road user quantified over in the obligation. -/
def vP : Arg := .var "p"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- Applicability: the subject's class (in its binder) is the whole of it, as the record states. -/
def applicability : Formula := .tt

/-- x2 guard: the subject moves (speed above the halt tolerance). -/
def subjectMoving : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- x4: `p` is a pedestrian other than the subject. -/
def isOtherPedestrian : Formula :=
  .and (.not (.same vP vSubject))
    (.atom "ru_aggregate" [vP, .lit "DEF-NRS-484A-165::pedestrian"] [])

/-- x3: no collision with `p`. -/
def noContact : Formula :=
  .not (.atom "rel_contact" [vSubject, vP] [])

/-- x2 operationalization: no closest approach within the horizon below the centre clearance. -/
def noConflict : Formula :=
  .not (.and (.derived "prim_closest_approach_within" [vSubject, vP] [pConflictHorizon])
              (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vP] [pConflictHorizon])
                    .lt pConflictCentreClearance))

/-- Obligation: x2 (standard): shall: Exercise due care; x3 (obligation): to avoid a collision;
    x4 (condition): with a pedestrian. -/
def obligation : Formula :=
  .implies subjectMoving
    (.forallUser "p" (.implies isOtherPedestrian (.and noContact noConflict)))

def rule : Rule :=
  { id := "NRS_484B_280_1a"
    laws := ["NRS-484B-280-1a"]
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
          convention := "traffic-conflict technique: while the vehicle moves, care shows in its keeping no closest approach to the pedestrian, under constant velocities, within a time-to-collision horizon and below a centre clearance of about a car's half-length plus half a body width"
          surrogate := true } ]
    residues := []
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_280_1a
