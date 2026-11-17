/-
  NRS_484B_363_4 — NRS-484B-363-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): shall not overtake and pass another vehicle traveling in the same direction
    s3 (trigger): in an area designated as a school zone or school crossing zone
    s4 (boilerplate): except:
    s5 (exception): (a) On a day on which the school is not in session;
    s6 (exception): (b) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;
    s7 (exception): (c) If the zone is designated by an operational speed limit beacon,
    s8 (exception): during the hours when the pupils of the school are in class
    s9 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;
    s10 (exception): or (d) If the zone is not designated by an operational speed limit beacon,
    s11 (exception): during the times when the sign designating the school zone or school crossing zone indicates that the speed limit is not in effect.
    s12 (definitional): As used in this section, “speed limit beacon” means a device which is used in conjunction with a sign and equipped with two or more yellow lights that flash alternately to indicate when the speed limit in a school zone or school crossing zone is in effect.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.speed'], derived ['drv.interaction.overtake_pass']
    s3: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['dev.speed_limit_beacon', 'dev.governs', 'dev.inoperative', 'st.travel_region'], derived []
    s9: atoms ['dev.speed_limit_beacon'], derived []
    s10: atoms ['dev.speed_limit_beacon', 'dev.governs', 'dev.inoperative', 'st.travel_region'], derived []
    s11: atoms ['dev.zone_sign', 'prim.conditions_hold'], derived []
    s12: atoms ['dev.speed_limit_beacon'], derived []

  How each is written:
    s1  — the binder class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s2  — for each road user b of the scene (`forallUser`/`existsUser "b"`), b another vehicle
          (`ru_aggregate b …`, `not (same b subject)`); the pass is the concept call
          `drv_interaction_overtake_pass subject b [p.overtake_window, p.overtake_same_direction_cos]`;
          "traveling" is b's `kin_speed` above `p.halt_speed_tolerance` at some observation while the
          pass is under way (the applicability's own reading, `someMoment`).
    occasion (boundary "window", W = p.overtake_window, subject's time window):
          ahead-aligned(o) = `rel_bearing subject b "ahead"` ∧ `rel_longitudinal_overlap subject b < 0`
          ∧ `rel_same_direction subject b` (p.overtake_same_direction_cos) ∧ the subject moving
          (`kin_speed subject > p.halt_speed_tolerance`) — "b ahead of the moving subject with
          headings aligned".
          U(o) = `until (not ahead-aligned) pass`: from o on, b is not ahead-aligned until the pass
          is recognized. At the recognition n this holds at exactly the observations after the last
          ahead-aligned one L of the window up to n. CHOICE: the language has no "next observation"
          operator, so the last ahead-aligned observation L itself cannot be singled out from the
          earlier members of its run from the observation's own vantage; U is the stretch (L, n],
          the pass from the first observation at which b is no longer ahead with a gap to its
          recognition. Every observation strictly before L is excluded, as the record requires.
          some_moment φ = `not (holdsFor .time W subject (not (U ∧ φ)))`;
          throughout φ  = `holdsFor .time W subject (U → φ)`.
    s3  — some_moment: ∃ zone sign z (`existsDevice "zone_sign"`), ∃ travel region r
          (`existsRegion "travel_region"`) with `dev_governs z r`, `dev_zone_sign_kind z` school or
          school_crossing, not `dev_zone_sign_end z`, and `rel_occupies subject r`. z and r are
          quantified outside the time operators: the exceptions are read "for that z and r".
    s5  — (a) throughout `not asm.school_in_session_day`.
    s6  — (b) throughout `asm.school_outside_operation_margin`.
    s7, s8, s9 — (c) throughout: some `speed_limit_beacon` bc with `dev_governs bc r` and not
          `dev_inoperative bc`; `asm.pupils_in_class`; every such operational beacon governing r
          not `dev_speed_limit_beacon_flashing`.
    s10, s11 — (d) throughout: no operational beacon governing r, and not
          `prim_conditions_hold z subject`.
    s12 — the contract of dev.speed_limit_beacon (the beacon quantifier's kind); adds nothing.
    The duty applies where some other vehicle's pass qualifies (travelling, in the zone, no
    exception holding throughout), or where no other vehicle is in the scene (the record: "with no
    other vehicle in the scene the duty is met"). The obligation restates the whole qualification
    for every b and requires that the pass of no qualifying b is recognized at the judged
    observation.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_363_4

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantified variables: the other road user, the zone sign, the region, the beacon. -/
def vB : Arg := .var "b"
def vZ : Arg := .var "z"
def vR : Arg := .var "r"
def vBc : Arg := .var "bc"

/-- The admitted aggregate of 'vehicle'. -/
def vehicleAggregate : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, vehicleAggregate] []

/-- s2: b is another vehicle of the scene. -/
def otherVehicle : Formula :=
  .and (.atom "ru_aggregate" [vB, vehicleAggregate] []) (.not (.same vB vSubject))

/-- A road user moving: its speed above the halt tolerance. -/
def moving (x : Arg) : Formula := .cmp (.measure "kin_speed" [x]) .gt pHaltSpeedTolerance

/-- s2: the pass of b by the subject. -/
def overtakePass : Formula :=
  .derived "drv_interaction_overtake_pass" [vSubject, vB] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- Occasion: b ahead of the moving subject with headings aligned. -/
def aheadAligned : Formula :=
  .and (.atom "rel_bearing" [vSubject, vB, .lit "ahead"] [])
    (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vB]) .lt zeroMetres)
      (.and (.atom "rel_same_direction" [vSubject, vB] [pOvertakeSameDirectionCos])
        (moving vSubject)))

/-- Occasion `under_way`: b no longer ahead-aligned from here until the pass is recognized. -/
def underWay : Formula := .until (.not aheadAligned) overtakePass

/-- A span read `some_moment` over the occasion. -/
def someMoment (φ : Formula) : Formula :=
  .not (.holdsFor .time pOvertakeWindow "subject" (.not (.and underWay φ)))

/-- A span read `throughout` over the occasion. -/
def throughout (φ : Formula) : Formula :=
  .holdsFor .time pOvertakeWindow "subject" (.implies underWay φ)

/-- s2: b travelling at some observation while the pass is under way. -/
def travelling : Formula := someMoment (moving vB)

/-- s3: z a school or school crossing zone sign, not an end sign, governing r. -/
def designates : Formula :=
  .and (.atom "dev_governs" [vZ, vR] [])
    (.and (.or (.atom "dev_zone_sign_kind" [vZ, .lit "school"] [])
               (.atom "dev_zone_sign_kind" [vZ, .lit "school_crossing"] []))
      (.not (.atom "dev_zone_sign_end" [vZ] [])))

/-- s3 (some_moment): the subject's footprint on r while z designates it. -/
def inZone : Formula := someMoment (.and designates (.atom "rel_occupies" [vSubject, vR] []))

/-- s7/s10: beacon bc governs r and is operational. -/
def beaconOperational : Formula :=
  .and (.atom "dev_governs" [vBc, vR] []) (.not (.atom "dev_inoperative" [vBc] []))

def someOperationalBeacon : Formula :=
  .existsDevice (.lit "speed_limit_beacon") "bc" beaconOperational

/-- s9: no operational beacon governing r is flashing. -/
def noOperationalBeaconFlashing : Formula :=
  .forallDevice (.lit "speed_limit_beacon") "bc"
    (.implies beaconOperational (.not (.atom "dev_speed_limit_beacon_flashing" [vBc] [])))

/-- s5 (a). -/
def exceptionA : Formula := throughout (.not (.asm "asm.school_in_session_day"))
/-- s6 (b). -/
def exceptionB : Formula := throughout (.asm "asm.school_outside_operation_margin")
/-- s7, s8, s9 (c). -/
def exceptionC : Formula :=
  throughout (.and someOperationalBeacon (.and (.asm "asm.pupils_in_class") noOperationalBeaconFlashing))
/-- s10, s11 (d). -/
def exceptionD : Formula :=
  throughout (.and (.not someOperationalBeacon) (.not (.derived "prim_conditions_hold" [vZ, vSubject] [])))

/-- s3 with the exceptions, for that z and r. -/
def zoneOccasion : Formula :=
  .existsDevice (.lit "zone_sign") "z"
    (.existsRegion (.lit "travel_region") "r"
      (.and inZone (.not (.or exceptionA (.or exceptionB (.or exceptionC exceptionD))))))

/-- The pass of b to which the duty applies. -/
def qualifyingPass : Formula := .and otherVehicle (.and travelling zoneOccasion)

/-- Applicability: s3 (trigger): in an area designated as a school zone or school crossing zone; s5 (exception): (a) On a day on which the school is not in session;; s6 (exception): (b) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;; s7 (exception): (c) If the zone is designated by an operational speed limit beacon,; s8 (exception): during the hours when the pupils of the school are in class; s9 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;; s10 (exception): or (d) If the zone is not designated by an operational speed limit beacon,; s11 (exception): during the times when the sign designating the school zone or school crossing zone indicates that the speed limit is not in effect. -/
def applicability : Formula :=
  .or (.existsUser "b" qualifyingPass) (.not (.existsUser "b" otherVehicle))

/-- Obligation: s2 (obligation): shall not overtake and pass another vehicle traveling in the same direction -/
def obligation : Formula :=
  .forallUser "b" (.implies qualifyingPass (.not overtakePass))

def rule : Rule :=
  { id := "NRS_484B_363_4"
    laws := ["NRS-484B-363-4"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.school_in_session_day", "asm.school_outside_operation_margin", "asm.pupils_in_class"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_363_4
