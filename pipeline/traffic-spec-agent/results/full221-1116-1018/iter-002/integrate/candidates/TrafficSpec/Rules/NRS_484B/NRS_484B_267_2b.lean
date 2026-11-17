/-
  NRS_484B_267_2b — NRS-484B-267-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (trigger): Upon approaching
    t2 (condition): an authorized emergency vehicle
    t3 (condition): or an official vehicle of a regulatory agency
    t4 (condition): which is moving or preparing to move in any direction,
    t5 (condition): including, without limitation, arriving at or leaving the scene of a crash or other incident,
    t6 (condition): and making use of flashing lights meeting the requirements of
    t7 (reference): subsection 3 of NRS 484A.480 [DEF-NRS-484A-480-3],
    t8 (subject): the driver of any other vehicle shall,
    t9 (exception): except when otherwise directed by a law enforcement officer:
    t10 (obligation): Proceed
    t11 (standard): with caution.
    t12 (definitional): As used in this section, “preparing to move” means any indication that is visible to an approaching driver that an authorized emergency vehicle or an official vehicle of a regulatory agency is about to move, including, without limitation: (a) A movement of the vehicle; or (b) The use of hand signals by the driver of the vehicle.

  Elements (span → atoms, derived):
    t1: atoms ['kin.speed', 'rel.bearing', 'rel.centre_distance'], derived []
    t2: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle'], derived []
    t3: atoms ['ru.official_vehicle'], derived []
    t4: atoms ['kin.speed', 'sig.hand_signal', 'sig.turn_indicator', 'rel.visible'], derived []
    t6: atoms ['sig.warning_lamp'], derived [], borrowing ['t7']
    t8: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    t9: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    t10: atoms ['kin.speed'], derived []
    t12: atoms ['kin.speed', 'sig.hand_signal', 'sig.turn_indicator', 'rel.visible'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    t7: DEF-NRS-484A-480-3: at least one flashing red warning lamp visible from the front

  How each span is written:
    t8 (class of subject): ru_aggregate subject DEF-NRS-484A-320::vehicle; "any other" is
       `not (same e subject)` inside the selection of e.
    t2/t3: e is in the authorized-emergency-vehicle aggregate, or e is an official vehicle
       (ru_official_vehicle) whose kind is regulatory_agency (ru_official_vehicle_kind).
    t6/t7: sig_warning_lamp e red flashing. The formula language reads a warning lamp by colour
       and mode only (Semantics.evalAtomE has no form with a facing literal), so "facing front"
       is not read; reported in task_result.md.
    t4/t12: moving = kin_speed e > p.halt_speed_tolerance; preparing to move = rel_visible
       subject e and (hand signal other than no_signal, or turn indicator other than off).
    t1/t10: the subject moves (kin_speed subject > p.halt_speed_tolerance); e is ahead
       (rel_bearing subject e ahead) or side by side (rel_longitudinal_overlap subject e ≥ 0);
       rel_centre_distance subject e ≤ p.emergency_approach_reach.
    t9: no human_direction device of role police_officer governs a travel region the subject
       occupies.
    t11 (operationalization): for every e so selected (the whole selection restated in the
       obligation): no rel_contact; not (prim_closest_approach_within subject e p.conflict_horizon
       and prim_closest_approach_distance < p.conflict_centre_clearance); and where
       rel_longitudinal_overlap subject e ≥ 0, rel_surface_gap subject e (the distance between
       the bodies) ≥ p.emergency_pass_clearance.
    t5: residue.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_267_2b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"
def vE : Arg := .var "e"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pEmergencyApproachReach : Term := .param "p.emergency_approach_reach"
def pEmergencyPassClearance : Term := .param "p.emergency_pass_clearance"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- t2/t3: an authorized emergency vehicle, or an official vehicle of a regulatory agency. -/
def emergencyOrRegulatory : Formula :=
  .or (.atom "ru_aggregate" [vE, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
      (.and (.atom "ru_official_vehicle" [vE] [])
            (.atom "ru_official_vehicle_kind" [vE, .lit "regulatory_agency"] []))

/-- t6/t7: a lit flashing red warning lamp. -/
def flashingRed : Formula := .atom "sig_warning_lamp" [vE, .lit "red", .lit "flashing"] []

/-- t4/t12: moving, or preparing to move with an indication visible to the subject. -/
def movingOrPreparing : Formula :=
  .or (.cmp (.measure "kin_speed" [vE]) .gt pHaltSpeedTolerance)
      (.and (.atom "rel_visible" [vSubject, vE] [])
            (.or (.not (.atom "sig_hand_signal" [vE, .lit "no_signal"] []))
                 (.not (.atom "sig_turn_indicator" [vE, .lit "off"] []))))

/-- t1/t10: the subject moves, e is ahead or alongside, within the approach reach. -/
def approaching : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.and (.or (.atom "rel_bearing" [vSubject, vE, .lit "ahead"] [])
               (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vE]) .ge zeroMetres))
          (.cmp (.measure "rel_centre_distance" [vSubject, vE]) .le pEmergencyApproachReach))

/-- The selection of e: every condition the applicability states of it. -/
def selection : Formula :=
  .and (.not (.same vE vSubject))
    (.and emergencyOrRegulatory
      (.and flashingRed
        (.and movingOrPreparing approaching)))

/-- t9: a police officer directing traffic in a travel region the subject occupies. -/
def directedByPolice : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [.var "d", .lit "police_officer"] [])
          (.existsRegion (.lit "travel_region") "r"
            (.and (.atom "dev_governs" [.var "d", .var "r"] [])
                  (.atom "rel_occupies" [vSubject, .var "r"] []))))

/-- Applicability: t1 (trigger): Upon approaching; t2 (condition): an authorized emergency vehicle; t3 (condition): or an official vehicle of a regulatory agency; t4 (condition): which is moving or preparing to move in any direction,; t5 (condition): including, without limitation, arriving at or leaving the scene of a crash or other incident,; t6 (condition): and making use of flashing lights meeting the requirements of; t9 (exception): except when otherwise directed by a law enforcement officer: -/
def applicability : Formula :=
  .and (.existsUser "e" selection) (.not directedByPolice)

/-- t11: the clearance caution secures toward e. -/
def caution : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vE] []))
    (.and (.not (.and (.derived "prim_closest_approach_within" [vSubject, vE] [pConflictHorizon])
                      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vE] [pConflictHorizon])
                            .lt pConflictCentreClearance)))
          (.implies (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vE]) .ge zeroMetres)
                    (.cmp (.measure "rel_surface_gap" [vSubject, vE]) .ge pEmergencyPassClearance)))

/-- Obligation: t10 (obligation): Proceed; t11 (standard): with caution. -/
def obligation : Formula :=
  .forallUser "e" (.implies selection caution)

def rule : Rule :=
  { id := "NRS_484B_267_2b"
    laws := ["NRS-484B-267-2b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "with caution"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact", "rel.longitudinal_overlap", "rel.surface_gap"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.emergency_pass_clearance"]
          convention := "caution is read through the conduct it secures toward the emergency vehicle: no traffic-conflict with it (closest approach of the centres under constant velocities within the time-to-collision threshold below the collision clearance), no contact, and, while side by side with it, a gap between bodies of at least the lateral passing clearance"
          surrogate := true } ]
    residues := ["illustrative: arriving at or leaving a scene are instances of moving or preparing to move, which t4 already reads; the duty is the same whether or not the vehicle is arriving at or leaving a scene"]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_267_2b
