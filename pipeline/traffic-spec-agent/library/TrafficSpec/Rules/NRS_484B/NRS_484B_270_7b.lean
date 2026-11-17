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
    y2: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle', 'kin.position', 'kin.heading', 'rel.longitudinal_overlap', 'rel.same_direction'], derived ['drv.interaction.overtake_pass']

  How each is written:
    y1: the binder class is the disjunction of the three admitted aggregates, each `ru_aggregate`
        with its id.
    y2: for every road user m other than the subject that is a member of
        DEF-NRS-484A-130::motor_vehicle, the act is recognized where
        `drv_interaction_overtake_pass(subject, m)` (window p.overtake_window, same_dir_cos
        p.overtake_same_direction_cos) holds; the concept holds at the recognition only.
        The act's beginning is located as the concept's contract defines it: `aheadAligned`, m
        ahead of the subject with headings aligned — the component along the subject's heading
        (kin.heading, read normalised) of the vector from the subject's position to m's position
        (kin.position) positive, rel.longitudinal_overlap negative, rel.same_direction within
        p.overtake_same_direction_cos.
    y3: `safe` at an observation — no rel.contact with m, rel.surface_gap (the distance between
        the bodies) to m at least p.bicycle_pass_safe_gap, and no road user u other than the
        subject and m with prim.closest_approach_within over p.conflict_horizon and
        prim.closest_approach_distance over p.conflict_horizon below p.conflict_centre_clearance.
        "Safe at the beginning and at every observation after it up to the recognition" is written
        `since (safe ∧ ¬aheadAligned) (aheadAligned ∧ safe)`: the latest observation at which m was
        ahead with headings aligned is the beginning, so every later observation up to the
        recognition is one at which aheadAligned fails; requiring ¬aheadAligned in the left operand
        makes the search stop at that latest aligned-ahead observation (equivalent to
        `since safe (aheadAligned ∧ safe)` in its decided values) and keeps the search from reading
        anything before the act's beginning.

  Choices the record left open: none beyond the equivalent form of the `since` above; the
  applicability is `.tt` (no trigger or condition span; the subject's class is the binder's).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_7b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"
/-- The motor vehicle passed, and any other road user, as quantifier variables. -/
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

/-- Applicability: (no trigger/condition span) -/
def applicability : Formula := .tt

/-- y2: m is a member of DEF-NRS-484A-130::motor_vehicle. -/
def isMotorVehicle : Formula :=
  .atom "ru_aggregate" [vM, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- y2: the pass's recognition, drv.interaction.overtake_pass(subject, m). -/
def passRecognized : Formula :=
  .derived "drv_interaction_overtake_pass" [vSubject, vM] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- y2: the component along the subject's heading of the vector from the subject's position to
    m's position. -/
def longitudinalComponent : Term :=
  .add
    (.mul (.sub (.measure "kin_position" [vM, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"]))
          (.measure "kin_heading" [vSubject, .lit "x"]))
    (.mul (.sub (.measure "kin_position" [vM, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"]))
          (.measure "kin_heading" [vSubject, .lit "y"]))

/-- y2: m ahead of the subject with headings aligned (the pass's beginning, as the concept's
    contract defines it). -/
def aheadAligned : Formula :=
  .and (.cmp longitudinalComponent .gt zeroMetres)
    (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vM]) .lt zeroMetres)
          (.atom "rel_same_direction" [vSubject, vM] [pOvertakeSameDirectionCos]))

/-- y3: no other road user u in a conflicting closest approach with the subject. -/
def noConflict : Formula :=
  .forallUser "u"
    (.or (.or (.same vU vSubject) (.same vU vM))
         (.not (.and (.derived "prim_closest_approach_within" [vSubject, vU] [pConflictHorizon])
                     (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vU] [pConflictHorizon])
                           .lt pConflictCentreClearance))))

/-- y3: the pass is safe at an observation. -/
def safe : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vM] []))
    (.and (.cmp (.measure "rel_surface_gap" [vSubject, vM]) .ge pBicyclePassSafeGap)
          noConflict)

/-- Obligation: y2 (obligation): shall not: Overtake and pass a motor vehicle; y3 (standard): unless the operator can do so safely without endangering himself or herself or the occupants of the motor vehicle. -/
def obligation : Formula :=
  .forallUser "m"
    (.implies
      (.and (.not (.same vM vSubject)) (.and isMotorVehicle passRecognized))
      (.since (.and safe (.not aheadAligned)) (.and aheadAligned safe)))

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
