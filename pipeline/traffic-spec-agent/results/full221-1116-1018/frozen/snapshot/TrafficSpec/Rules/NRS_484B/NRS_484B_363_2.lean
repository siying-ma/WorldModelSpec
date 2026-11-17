/-
  NRS_484B_363_2 — NRS-484B-363-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A person shall not drive a motor vehicle
    s2 (obligation): at a speed in excess of 25 miles per hour
    s3 (trigger): in an area designated as a school crossing zone
    s4 (boilerplate): except:
    s5 (exception): (a) On a day on which school is not in session;
    s6 (exception): (b) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;
    s7 (exception): (c) If the zone is designated by an operational speed limit beacon,
    s8 (exception): during the hours when the pupils of the school are in class
    s9 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;
    s10 (exception): or (d) If the zone is not designated by an operational speed limit beacon,
    s11 (exception): during the times when the sign designating the school zone indicates that the speed limit is not in effect.
    s12 (definitional): As used in this section, “speed limit beacon” means a device which is used in conjunction with a sign and equipped with two or more yellow lights that flash alternately to indicate when the speed limit in a school zone or school crossing zone is in effect.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    s2: atoms ['kin.speed'], derived []
    s3: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['dev.speed_limit_beacon', 'dev.governs', 'dev.inoperative', 'st.travel_region'], derived []
    s9: atoms ['dev.speed_limit_beacon'], derived []
    s10: atoms ['dev.speed_limit_beacon', 'dev.governs', 'dev.inoperative', 'st.travel_region'], derived []
    s11: atoms ['dev.zone_sign', 'prim.conditions_hold'], derived []
    s12: atoms ['dev.speed_limit_beacon'], derived []

  Literals the text states (each written through its Units constructor):
    s2: 25 mph — 25 miles per hour

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_363_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written (no choice beyond the record's own applicability text was needed):
    s1: the binder class is `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`.
    s3: some travel region r (`existsRegion travel_region`) that the subject occupies
        (`rel_occupies`) and some zone sign z (`existsDevice zone_sign`) governing r
        (`dev_governs`) with kind school_crossing and not an end sign. The exceptions are read
        for that z and r, inside both quantifiers: the duty applies if it applies for any such
        pair, as the record states.
    s5 (a): `asm.school_in_session_day` false.
    s6 (b): `asm.school_outside_operation_margin` true.
    s7/s8/s9 (c): some beacon b governing r and not inoperative, `asm.pupils_in_class`, and every
        beacon governing r and not inoperative not flashing.
    s10/s11 (d): no beacon governing r and not inoperative, and `prim_conditions_hold z subject`
        false.
    s12: the device kind `speed_limit_beacon`; it adds no condition.
    s2: `kin_speed subject ≤ 25 mph`, the literal through `Units.mph`.
-/

def vR : Arg := .var "r"
def vZ : Arg := .var "z"
def vB : Arg := .var "b"
def vB2 : Arg := .var "b2"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- s7/s10: beacon `v` governs r and is not inoperative (an operational beacon designating the zone). -/
def operationalBeacon (v : Arg) : Formula :=
  .and (.atom "dev_governs" [v, vR] []) (.not (.atom "dev_inoperative" [v] []))

/-- s7: the zone is designated by an operational speed limit beacon. -/
def someOperationalBeacon : Formula :=
  .existsDevice (.lit "speed_limit_beacon") "b" (operationalBeacon vB)

/-- (a) s5: a day on which school is not in session. -/
def excA : Formula := .not (.asm "asm.school_in_session_day")

/-- (b) s6: outside the half-hour operation margins. -/
def excB : Formula := .asm "asm.school_outside_operation_margin"

/-- (c) s7–s9: operational beacon, pupils in class, no operational beacon flashing. -/
def excC : Formula :=
  .and someOperationalBeacon
    (.and (.asm "asm.pupils_in_class")
      (.forallDevice (.lit "speed_limit_beacon") "b2"
        (.implies (operationalBeacon vB2)
          (.not (.atom "dev_speed_limit_beacon_flashing" [vB2] [])))))

/-- (d) s10–s11: no operational beacon, and the zone sign's conditions do not hold now. -/
def excD : Formula :=
  .and (.not someOperationalBeacon)
    (.not (.derived "prim_conditions_hold" [vZ, vSubject] []))

/-- Applicability: s3 (trigger): in an area designated as a school crossing zone; s5 (exception): (a) On a day on which school is not in session;; s6 (exception): (b) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;; s7 (exception): (c) If the zone is designated by an operational speed limit beacon,; s8 (exception): during the hours when the pupils of the school are in class; s9 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;; s10 (exception): or (d) If the zone is not designated by an operational speed limit beacon,; s11 (exception): during the times when the sign designating the school zone indicates that the speed limit is not in effect. -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] [])
      (.existsDevice (.lit "zone_sign") "z"
        (.and (.atom "dev_governs" [vZ, vR] [])
          (.and (.atom "dev_zone_sign_kind" [vZ, .lit "school_crossing"] [])
            (.and (.not (.atom "dev_zone_sign_end" [vZ] []))
              (.not (.or excA (.or excB (.or excC excD)))))))))

/-- Obligation: s2 (obligation): at a speed in excess of 25 miles per hour -/
def obligation : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .le (.lit (Units.mph 25) .metrePerSecond)

def rule : Rule :=
  { id := "NRS_484B_363_2"
    laws := ["NRS-484B-363-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.school_in_session_day", "asm.school_outside_operation_margin", "asm.pupils_in_class"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_363_2
