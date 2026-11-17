/-
  NRS_484B_363_1 — NRS-484B-363-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A person shall not drive a motor vehicle
    s2 (obligation): at a speed in excess of 15 miles per hour
    s3 (trigger): in an area designated as a school zone
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
    s2: 15 mph — 15 miles per hour

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_363_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s1: `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"` (the admitted aggregate, never its classes).
    s3: some zone sign z (device quantifier over `zone_sign`: dev.zone_sign) with kind `school` and
        not an end sign, and some travel region r (region quantifier over `travel_region`) that z
        governs (`dev_governs z r`) and the subject's footprint overlaps (`rel_occupies subject r`).
        The existential over (z, r) is the record's ("applies if it applies for any of them").
    s5: exception (a) is `¬ asm.school_in_session_day`.
    s6: exception (b) is `asm.school_outside_operation_margin`.
    s7/s8/s9: exception (c): some beacon b (device quantifier over `speed_limit_beacon`) governs r
        and is not inoperative; `asm.pupils_in_class`; and every beacon that governs r and is not
        inoperative is not flashing (`dev_speed_limit_beacon_flashing`).
    s10/s11: exception (d): no beacon governs r and is not inoperative, and
        `prim_conditions_hold z subject` is false.
    s12: definitional; carried by the beacon device kind in s7, s9, s10.
    s2: obligation `kin_speed subject ≤ 15 mph` (Units.mph 15, the text's literal), at the judged
        observation.
  No choice beyond the record's: no narrowing of this session's own.
-/

def vZone : Arg := .var "z"
def vRegion : Arg := .var "r"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- A beacon `b` designates the zone's region r and is operational (s7 / s10). -/
def operationalBeacon (b : String) : Formula :=
  .and (.atom "dev_governs" [.var b, vRegion] []) (.not (.atom "dev_inoperative" [.var b] []))

/-- s3: z is a school zone sign, not an end sign, governing r, which the subject occupies. -/
def schoolZone : Formula :=
  .and (.atom "dev_zone_sign_kind" [vZone, .lit "school"] [])
    (.and (.not (.atom "dev_zone_sign_end" [vZone] []))
      (.and (.atom "dev_governs" [vZone, vRegion] [])
        (.atom "rel_occupies" [vSubject, vRegion] [])))

/-- s5: exception (a). -/
def excA : Formula := .not (.asm "asm.school_in_session_day")

/-- s6: exception (b). -/
def excB : Formula := .asm "asm.school_outside_operation_margin"

/-- s7, s8, s9: exception (c). -/
def excC : Formula :=
  .and (.existsDevice (.lit "speed_limit_beacon") "b" (operationalBeacon "b"))
    (.and (.asm "asm.pupils_in_class")
      (.forallDevice (.lit "speed_limit_beacon") "b2"
        (.implies (operationalBeacon "b2")
          (.not (.atom "dev_speed_limit_beacon_flashing" [.var "b2"] [])))))

/-- s10, s11: exception (d). -/
def excD : Formula :=
  .and (.not (.existsDevice (.lit "speed_limit_beacon") "b3" (operationalBeacon "b3")))
    (.not (.derived "prim_conditions_hold" [vZone, vSubject] []))

/-- Applicability: s3 (trigger): in an area designated as a school zone; s5 (exception): (a) On a day on which school is not in session;; s6 (exception): (b) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;; s7 (exception): (c) If the zone is designated by an operational speed limit beacon,; s8 (exception): during the hours when the pupils of the school are in class; s9 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;; s10 (exception): or (d) If the zone is not designated by an operational speed limit beacon,; s11 (exception): during the times when the sign designating the school zone indicates that the speed limit is not in effect. -/
def applicability : Formula :=
  .existsDevice (.lit "zone_sign") "z"
    (.existsRegion (.lit "travel_region") "r"
      (.and schoolZone
        (.not (.or excA (.or excB (.or excC excD))))))

/-- Obligation: s2 (obligation): at a speed in excess of 15 miles per hour -/
def obligation : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .le (.lit (Units.mph 15) .metrePerSecond)

def rule : Rule :=
  { id := "NRS_484B_363_1"
    laws := ["NRS-484B-363-1"]
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

end TrafficSpec.Rules.NRS_484B_363_1
