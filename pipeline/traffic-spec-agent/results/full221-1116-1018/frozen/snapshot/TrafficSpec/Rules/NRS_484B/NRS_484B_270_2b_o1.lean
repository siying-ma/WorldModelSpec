/-
  NRS_484B_270_2b_o1 — NRS-484B-270-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (trigger): When overtaking or passing
    b2 (trigger): a bicycle, an electric bicycle or an electric scooter
    b3 (trigger): proceeding in the same direction,
    b4 (subject): the driver of a motor vehicle
    b5 (obligation): shall exercise due care and:
    b6 (sibling): If there is only one lane for traffic proceeding in the same direction,
    b7 (sibling): pass to the left of the bicycle, electric bicycle or electric scooter
    b8 (sibling): at a safe distance, which must be not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter,
    b9 (sibling): and shall not move again to the right side of the highway
    b10 (sibling): until the vehicle is safely clear of the overtaken bicycle, electric bicycle or electric scooter.
    b11 (reference): Except as otherwise provided in NRS 484B.213 and 484B.217 [NRS-484B-213-1, NRS-484B-213-2a, NRS-484B-213-2b, NRS-484B-213-2c, NRS-484B-217-2],
    b12 (exception): when passing to the left of a bicycle, electric bicycle or electric scooter at a safe distance of not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter, this paragraph authorizes the driver, if it is safe, to pass: (1) To the left of the center of the highway. (2) In a no-passing zone.

  Elements (span → atoms, derived):
    b1: atoms ['rel.longitudinal_overlap'], derived ['drv.interaction.overtake_pass']
    b2: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    b3: atoms ['rel.same_direction', 'kin.speed'], derived []
    b4: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []

  Compositions (span → node, as, map):
    b11: NRS_484B_213_1 as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2a as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2b as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2c as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_217_2 as unless map {'subject': 'subject'} scopes b12

  How each is written:
    subject class (b4): ru_aggregate(subject, DEF-NRS-484A-130::motor_vehicle).
    b1: rises(drv_interaction_overtake_pass(subject, r; p.overtake_window,
        p.overtake_same_direction_cos)) — judged once, at the pass's recognition.
    b2: ru_aggregate(r, …bicycle) ∨ ru_aggregate(r, …electric_bicycle) ∨ ru_aggregate(r, …electric_scooter).
    b3: at some observation of the window behind of length p.overtake_window,
        kin_speed(r) > p.halt_speed_tolerance ∧ rel_same_direction(subject, r; p.overtake_same_direction_cos),
        written ¬ holdsFor(¬ …).
    r ≠ subject (`same`), existential in the applicability.
    b5 (surrogate operationalization): for every r of the same whole selection, at every observation
        of the window behind of length p.overtake_window: ¬ rel_contact(subject, r) ∧
        (rel_longitudinal_overlap(subject, r) ≥ 0 → kin_accel_longitudinal(r) ≥ −p.rider_evasive_decel).
    b11 compositions (unless, scoping b12): b12 is a residue with scope "none" — the authorization
        leaves this paragraph's duty unchanged — so it has no formula here and the compositions,
        which only suspend that authorization, change neither the applicability nor the obligation.
  No choice beyond the record's was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_2b_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"
def pRiderEvasiveDecel : Term := .param "p.rider_evasive_decel"

def zeroMetres : Term := .lit Q.zero .metre

/-- The overtaken road user, a quantifier variable. -/
def vRider : Arg := .var "r"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- b2: r is a bicycle, an electric bicycle or an electric scooter. -/
def riderClass : Formula :=
  .or (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
      (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- b1: the subject's overtaking of r is recognized at this observation. -/
def passRecognized : Formula :=
  .rises (.derived "drv_interaction_overtake_pass" [vSubject, vRider]
    [pOvertakeWindow, pOvertakeSameDirectionCos])

/-- b3: r proceeding (moving) with its heading aligned with the subject's, at one observation. -/
def proceedingSameDirection : Formula :=
  .and (.cmp (.measure "kin_speed" [vRider]) .gt pHaltSpeedTolerance)
    (.atom "rel_same_direction" [vSubject, vRider] [pOvertakeSameDirectionCos])

/-- The whole selection of r: another road user, a rider class, the pass recognized now, and at
    some observation of the window behind proceeding in the subject's direction. -/
def selection : Formula :=
  .and (.not (.same vRider vSubject))
    (.and riderClass
      (.and passRecognized
        (.not (.holdsFor .time pOvertakeWindow "subject" (.not proceedingSameDirection)))))

/-- Applicability: b1, b2, b3 (b12 is a residue and changes nothing here). -/
def applicability : Formula := .existsUser "r" selection

/-- b5 surrogate, at one observation of the pass: no contact with r, and wherever side by side
    r's longitudinal acceleration is not below the negative of the evasive deceleration. -/
def dueCare : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vRider] []))
    (.implies (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vRider]) .ge zeroMetres)
      (.cmp (.measure "kin_accel_longitudinal" [vRider]) .ge (.neg pRiderEvasiveDecel)))

/-- Obligation: b5 (obligation): shall exercise due care and: -/
def obligation : Formula :=
  .forallUser "r" (.implies selection (.holdsFor .time pOvertakeWindow "subject" dueCare))

def rule : Rule :=
  { id := "NRS_484B_270_2b_o1"
    laws := ["NRS-484B-270-2b"]
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
    residues := ["the authorization lets a driver passing a rider at the stated clearance pass left of the center or in a no-passing zone, conduct other rules (NRS 484B.213, 484B.217) forbid; it relaxes those rules and leaves the duties of this paragraph unchanged: the duty of care is the same whether or not the authorization holds"]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_270_2b_o1
