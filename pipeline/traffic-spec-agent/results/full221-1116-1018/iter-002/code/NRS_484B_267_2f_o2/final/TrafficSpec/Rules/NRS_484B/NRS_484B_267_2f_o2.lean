/-
  NRS_484B_267_2f_o2 — NRS-484B-267-2f

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Upon approaching an authorized emergency vehicle or an official vehicle of a regulatory agency which is moving or preparing to move in any direction,
    s2 (trigger): including, without limitation, arriving at or leaving the scene of a crash or other incident,
    s3 (trigger): and making use of flashing lights meeting the requirements of
    s4 (reference): subsection 3 of NRS 484A.480 [DEF-NRS-484A-480-3],
    s5 (subject): the driver of any other vehicle shall,
    s6 (exception): except when otherwise directed by a law enforcement officer:
    s7 (boilerplate): If the authorized emergency vehicle or official vehicle of a regulatory agency:
    s8 (sibling): (1) Approaches the driver’s vehicle,
    s9 (sibling): proceed
    s9r (sibling): as required pursuant to subsection 1 [NRS-484B-267-1a, NRS-484B-267-1b, NRS-484B-267-1c];
    s10 (condition): or (2) Stops,
    s11 (obligation): proceed
    s11r (reference): as required pursuant to NRS 484B.607 [NRS-484B-607-1a, NRS-484B-607-1b, NRS-484B-607-1c, NRS-484B-607-1d].
    s12 (definitional): As used in this section, “preparing to move” means any indication that is visible to an approaching driver that an authorized emergency vehicle or an official vehicle of a regulatory agency is about to move, including, without limitation: (a) A movement of the vehicle; or (b) The use of hand signals by the driver of the vehicle.

  Elements (span → atoms, derived):
    s1: atoms ['kin.speed', 'rel.bearing', 'rel.centre_distance', 'ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle', 'ru.official_vehicle', 'rel.visible', 'sig.hand_signal', 'sig.turn_indicator'], derived []
    s3: atoms ['sig.warning_lamp'], derived [], borrowing ['s4']
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s10: atoms [], derived ['drv.motion.complete_halt']
    s11: atoms ['kin.speed'], derived []
    s12: atoms ['kin.speed', 'rel.visible', 'sig.hand_signal', 'sig.turn_indicator'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    s4: DEF-NRS-484A-480-3: at least one flashing red warning lamp visible from the front

  How each span is written:
    s1/s12  some road user `e`, not the subject (`.not (.same subject e)`), a member of
            DEF-NRS-484A-020::authorized_emergency_vehicle or an ru_official_vehicle of kind
            regulatory_agency; moving: kin_speed e > p.halt_speed_tolerance; preparing to move:
            rel_visible subject e and (sig_hand_signal e ≠ no_signal or sig_turn_indicator e ≠ off);
            approaching: kin_speed subject > p.halt_speed_tolerance, rel_bearing subject e "ahead"
            (longitudinal component positive), rel_centre_distance subject e ≤ p.emergency_approach_reach.
    s3/s4   sig_warning_lamp e red flashing. DEFECT: the formula atom `sig_warning_lamp` reads colour
            and mode only (Semantics.evalAtomE); no accessor reads `facing`, so "visible from the
            front" cannot be stated. Not narrowed (a trigger is never narrowed): reported.
    s5      ru_aggregate subject DEF-NRS-484A-320::vehicle.
    s6      not: some human_direction device of role police_officer governing a travel_region the
            subject occupies.
    s10     drv_motion_complete_halt e (p.halt_speed_tolerance) now, and `since` (past mirror of
            until) the last observation at which the s1 trigger held with the lamp lit.
    s11     DEFECT: the record states the obligation is "Not expressible ... no formula is written for
            it and the duty is not weakened to a weaker one" (NRS 484B.607 is outside the corpus). No
            formula is written; the placeholder `.tt` stands, and the node is reported in task_result.md.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_267_2f_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"
def vE : Arg := .var "e"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pEmergencyApproachReach : Term := .param "p.emergency_approach_reach"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: an authorized emergency vehicle or an official vehicle of a regulatory agency. -/
def priorityVehicle : Formula :=
  .or (.atom "ru_aggregate" [vE, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
      (.and (.atom "ru_official_vehicle" [vE] [])
            (.atom "ru_official_vehicle_kind" [vE, .lit "regulatory_agency"] []))

/-- s3/s4: a red warning lamp lit, flashing (facing not readable: see header). -/
def flashingLamp : Formula := .atom "sig_warning_lamp" [vE, .lit "red", .lit "flashing"] []

/-- s1/s12 (a): a movement of the vehicle. -/
def eMoving : Formula := .cmp (.measure "kin_speed" [vE]) .gt pHaltSpeedTolerance

/-- s1/s12: preparing to move — visible from the subject, with an arm signal or a lit turn indicator. -/
def ePreparing : Formula :=
  .and (.atom "rel_visible" [vSubject, vE] [])
       (.or (.not (.atom "sig_hand_signal" [vE, .lit "no_signal"] []))
            (.not (.atom "sig_turn_indicator" [vE, .lit "off"] [])))

/-- s1: the subject, moving, approaching `e` ahead of it within the approach reach. -/
def subjectApproaching : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.and (.atom "rel_bearing" [vSubject, vE, .lit "ahead"] [])
          (.cmp (.measure "rel_centre_distance" [vSubject, vE]) .le pEmergencyApproachReach))

/-- s1 + s3: the trigger at one observation. -/
def trigger : Formula :=
  .and flashingLamp (.and (.or eMoving ePreparing) subjectApproaching)

/-- s10: `e` at rest. -/
def eHalted : Formula := .derived "drv_motion_complete_halt" [vE] [pHaltSpeedTolerance]

/-- s6: a police officer directing traffic in a travel region the subject occupies. -/
def directedByOfficer : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction" [.var "d"] [])
      (.and (.atom "dev_human_direction_role" [.var "d", .lit "police_officer"] [])
        (.existsRegion (.lit "travel_region") "r"
          (.and (.atom "st_travel_region" [.var "r"] [])
            (.and (.atom "dev_governs" [.var "d", .var "r"] [])
                  (.atom "rel_occupies" [vSubject, .var "r"] []))))))

/-- Applicability: s1, s3 (s4), s10, and the s6 exception. -/
def applicability : Formula :=
  .and
    (.existsUser "e"
      (.and (.not (.same vSubject vE))
        (.and priorityVehicle
          (.and flashingLamp
            (.and eHalted (.since eHalted trigger))))))
    (.not directedByOfficer)

/-- Obligation: s11 — the record declares it not expressible (NRS 484B.607 outside the corpus);
    no formula is written for it. See the header and task_result.md. -/
def obligation : Formula := .tt

def rule : Rule :=
  { id := "NRS_484B_267_2f_o2"
    laws := ["NRS-484B-267-2f"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["'including, without limitation' lists examples of a vehicle moving or preparing to move; the duty is the same whether or not the vehicle is arriving at or leaving the scene of a crash or other incident", "NRS 484B.607 and its lines NRS-484B-607-1a to 1d are not in the corpus this run formalizes (no record, accepted or planned, and the harness supplies no text for them): the manner of proceeding they require is not captured"]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_267_2f_o2
