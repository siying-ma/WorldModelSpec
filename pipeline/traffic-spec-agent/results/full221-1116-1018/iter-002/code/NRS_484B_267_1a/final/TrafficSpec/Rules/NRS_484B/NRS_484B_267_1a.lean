/-
  NRS_484B_267_1a — NRS-484B-267-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    u1 (standard): Upon the immediate approach of
    u2 (condition): an authorized emergency vehicle
    u3 (condition): or an official vehicle of a regulatory agency,
    u4 (condition): making use of flashing lights meeting the requirements of
    u5 (reference): subsection 3 of NRS 484A.480 [DEF-NRS-484A-480-3],
    u6 (subject): the driver of every other vehicle shall,
    u7 (exception): except when otherwise directed by a law enforcement officer:
    u8 (obligation): Yield
    u9 (standard): the right-of-way.

  Elements (span → atoms, derived):
    u2: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle'], derived []
    u3: atoms ['ru.official_vehicle'], derived []
    u4: atoms ['sig.warning_lamp'], derived [], borrowing ['u5']
    u6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    u7: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    u8: atoms ['kin.speed', 'rel.contact'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    u5: DEF-NRS-484A-480-3: at least one flashing red warning lamp visible from the front

  How each span is written:
    u6  binder `subject`: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`; "every other" is
        `not (same e subject)` on the approaching road user `e`; "the driver" is the record's
        observable reading (the vehicle's controlled motion), not restated.
    u2  `ru_aggregate e "DEF-NRS-484A-020::authorized_emergency_vehicle"`.
    u3  `ru_official_vehicle e` and its kind attribute `ru_official_vehicle_kind e regulatory_agency`;
        u2 and u3 are the two limbs of one disjunction ("or").
    u4/u5 `sig_warning_lamp e red flashing`: a lit warning lamp, colour red, mode flashing. The
        facing the borrowed words require ("visible from the front") is not stated: the
        `sig_warning_lamp` accessor of the formula language reads colour and mode only (Atoms.lean
        `sig_warning_lamp_shows`), no atom of the surface reads a lamp's facing. Declared below as
        `no_atom` on u4, for the repair session.
    u1  (operationalization) e approaches: `kin_speed e > p.halt_speed_tolerance`, the subject
        ahead of e in e's frame (`rel_bearing e subject "ahead"`, the longitudinal component
        positive), and `rel_centre_distance e subject ≤ p.emergency_immediate_approach_reach`.
    u7  `not (existsDevice human_direction d (role police_officer ∧ existsRegion travel_region r
        (dev_governs d r ∧ rel_occupies subject r)))` in the applicability, about the subject.
    u8/u9 obligation, for every road user e the applicability's selection (u2|u3, u4, u1, other
        than the subject) selects again: where the subject moves (`kin_speed subject >
        p.halt_speed_tolerance`) it is not in contact with e (`rel_contact`) and it is not the case
        that `prim_closest_approach_within subject e p.conflict_horizon` with
        `prim_closest_approach_distance subject e p.conflict_horizon < p.conflict_centre_clearance`.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_267_1a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The approaching vehicle (bound by a user quantifier) and the exception's officer and region. -/
def vE : Arg := .var "e"
def vD : Arg := .var "d"
def vR : Arg := .var "r"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pEmergencyImmediateApproachReach : Term := .param "p.emergency_immediate_approach_reach"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- u2 | u3: an authorized emergency vehicle, or an official vehicle of a regulatory agency. -/
def specialVehicle : Formula :=
  .or (.atom "ru_aggregate" [vE, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
      (.and (.atom "ru_official_vehicle" [vE] [])
            (.atom "ru_official_vehicle_kind" [vE, .lit "regulatory_agency"] []))

/-- u4 (with u5's words): a lit red warning lamp, flashing. -/
def flashingRedLamp : Formula := .atom "sig_warning_lamp" [vE, .lit "red", .lit "flashing"] []

/-- u1: e moves, the subject lies ahead of e in e's frame, within the immediate-approach reach. -/
def immediateApproach : Formula :=
  .and (.cmp (.measure "kin_speed" [vE]) .gt pHaltSpeedTolerance)
    (.and (.atom "rel_bearing" [vE, vSubject, .lit "ahead"] [])
          (.cmp (.measure "rel_centre_distance" [vE, vSubject]) .le pEmergencyImmediateApproachReach))

/-- The approaching road user e the applicability selects: not the subject (u6 "every other"),
    of u2 or u3, making use of the lamp (u4), in immediate approach (u1). -/
def approaching : Formula :=
  .and (.not (.same vE vSubject))
    (.and specialVehicle (.and flashingRedLamp immediateApproach))

/-- u7: a police officer directing traffic governs a travel region the subject occupies. -/
def directedByOfficer : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
          (.existsRegion (.lit "travel_region") "r"
            (.and (.atom "dev_governs" [vD, vR] [])
                  (.atom "rel_occupies" [vSubject, vR] []))))

/-- Applicability: u2 (condition): an authorized emergency vehicle; u3 (condition): or an official vehicle of a regulatory agency,; u4 (condition): making use of flashing lights meeting the requirements of; u7 (exception): except when otherwise directed by a law enforcement officer: -/
def applicability : Formula :=
  .and (.existsUser "e" approaching) (.not directedByOfficer)

/-- u9: the closest approach of the two centres falls within the horizon below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vE] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vE] [pConflictHorizon])
             .lt pConflictCentreClearance)

/-- u8: yield — where the subject moves, no contact with e and no conflict with it. -/
def yields : Formula :=
  .implies (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.and (.not (.atom "rel_contact" [vSubject, vE] [])) (.not conflict))

/-- Obligation: u1 (standard): Upon the immediate approach of; u8 (obligation): Yield; u9 (standard): the right-of-way. -/
def obligation : Formula :=
  .forallUser "e" (.implies approaching yields)

def rule : Rule :=
  { id := "NRS_484B_267_1a"
    laws := ["NRS-484B-267-1a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the immediate approach of the emergency or regulatory vehicle"
          concepts := ["kin.speed", "rel.bearing", "rel.centre_distance"]
          params := ["p.halt_speed_tolerance", "p.emergency_immediate_approach_reach"]
          convention := "the vehicle approaches: it moves (speed above the speed resolution) with the subject ahead of it in its own frame; the approach is immediate within the centre distance a vehicle at an urban response speed covers in the time a driver needs to perceive its lamps and begin clearing the way"
          surrogate := false }
      , { standard := "the right-of-way: DEF-NRS-484A-210 'approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: closest approach of the two centres under constant velocities within the time-to-collision threshold at a centre distance below the collision clearance"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "u4"
          why := "the words borrowed from u5 (DEF-NRS-484A-480-3) require the flashing red warning lamp to be 'visible from the front' (the record: facing front); the formula language's sig_warning_lamp atom reads colour and mode only (sig_warning_lamp [x, colour] / [x, colour, mode], Atoms.lean sig_warning_lamp_shows), and no atom of the surface reads a lamp's facing, so the formula states 'a lit red flashing warning lamp' in any facing"
          kind := "no_atom" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_267_1a
