/-
  NRS_484B_270_2a_o1 — NRS-484B-270-2a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (trigger): When overtaking or passing
    a2 (trigger): a bicycle, an electric bicycle or an electric scooter
    a3 (trigger): proceeding in the same direction,
    a4 (subject): the driver of a motor vehicle
    a5 (obligation): shall exercise due care and:
    a6 (sibling): If there is more than one lane for traffic proceeding in the same direction,
    a7 (sibling): move the vehicle to the lane to the immediate left,
    a8 (sibling): if the lane is available and moving into the lane is reasonably safe.

  Elements (span → atoms, derived):
    a1: atoms ['rel.longitudinal_overlap'], derived ['drv.interaction.overtake_pass']
    a2: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    a3: atoms ['rel.same_direction', 'kin.speed'], derived []
    a4: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []

  How each is written:
    a4: the binder `subject`'s class, `ru_aggregate subject DEF-NRS-484A-130::motor_vehicle`.
    a1: `rises (drv_interaction_overtake_pass subject r)` with window p.overtake_window and
        same_dir_cos p.overtake_same_direction_cos — the observation at which the pass is
        recognized; r is any road user of the scene other than the subject (`not (same subject r)`).
    a2: r is a member of one of the three admitted aggregates (a disjunction of `ru_aggregate`).
    a3: at some observation of the window behind of length p.overtake_window (the pass's own
        look-back), r is moving (kin.speed above p.halt_speed_tolerance) with its heading aligned
        with the subject's (rel.same_direction, tolerance p.overtake_same_direction_cos); written
        `not (holdsFor time W subject (not (moving and aligned)))`.
    a5 (surrogate, the node's operationalization): for every r of the applicability's whole
        selection (re-bound in the obligation), at every observation of the same window behind,
        the subject is not in contact with r (rel.contact), and wherever the two are side by side
        (rel.longitudinal_overlap at or above zero) r's longitudinal acceleration is not below the
        negative of p.rider_evasive_decel.
    a6–a8 are sibling spans, carried by another node.

  No choice beyond the record's: no narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_2a_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The overtaken road user, bound by a quantifier. -/
def vRider : Arg := .var "r"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"
def pRiderEvasiveDecel : Term := .param "p.rider_evasive_decel"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- a2: r is a bicycle, an electric bicycle or an electric scooter. -/
def riderClass : Formula :=
  .or (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
      (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- a1: the pass of r by the subject is recognized here. -/
def passRecognized : Formula :=
  .rises (.derived "drv_interaction_overtake_pass" [vSubject, vRider]
    [pOvertakeWindow, pOvertakeSameDirectionCos])

/-- a3: r proceeding (moving) in the subject's direction, at one observation. -/
def proceedingSameDirection : Formula :=
  .and (.cmp (.measure "kin_speed" [vRider]) .gt pHaltSpeedTolerance)
    (.atom "rel_same_direction" [vSubject, vRider] [pOvertakeSameDirectionCos])

/-- The whole selection of r: not the subject, of the three classes, passed now, and proceeding in
    the same direction at some observation of the window behind. -/
def selection : Formula :=
  .and (.not (.same vSubject vRider))
    (.and riderClass
      (.and passRecognized
        (.not (.holdsFor .time pOvertakeWindow "subject" (.not proceedingSameDirection)))))

/-- Applicability: a1 (trigger): When overtaking or passing; a2 (trigger): a bicycle, an electric bicycle or an electric scooter; a3 (trigger): proceeding in the same direction, -/
def applicability : Formula :=
  .existsUser "r" selection

/-- a5's standard at one observation: no contact, and no evasive braking of r while side by side. -/
def dueCareHere : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vRider] []))
    (.implies (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vRider]) .ge zeroMetres)
      (.cmp (.measure "kin_accel_longitudinal" [vRider]) .ge (.neg pRiderEvasiveDecel)))

/-- Obligation: a5 (obligation): shall exercise due care and: -/
def obligation : Formula :=
  .forallUser "r"
    (.implies selection (.holdsFor .time pOvertakeWindow "subject" dueCareHere))

def rule : Rule :=
  { id := "NRS_484B_270_2a_o1"
    laws := ["NRS-484B-270-2a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "shall exercise due care"
          concepts := ["kin.accel_longitudinal", "rel.contact", "rel.longitudinal_overlap"]
          params := ["p.rider_evasive_decel"]
          convention := "traffic-conflict technique: the pass is made with due care where the subject's body never touches the overtaken rider's (rel.contact) and the rider is never made to brake harder than an evasive deceleration (kin.accel_longitudinal below its negative) while the two are side by side (rel.longitudinal_overlap at or above zero); care is a state of mind, read only through this outcome"
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_270_2a_o1
