/-
  NRS_484B_620_2 — NRS-484B-620-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (condition): After the establishment of a speed zone and the installation of appropriate signs to control speed,
    t2 (subject): it is unlawful for any person to drive a motor vehicle
    t3 (condition): upon the road
    t4 (condition): and in the speed zone
    t5 (obligation): in excess of the speed therein authorized.

  Elements (span → atoms, derived):
    t1: atoms ['dev.zone_sign', 'dev.speed_limit_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    t2: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    t4: atoms ['rel.occupies', 'st.travel_region', 'dev.governs', 'dev.zone_sign', 'st.highway', 'st.on_way'], derived []
    t5: atoms ['kin.speed', 'dev.speed_limit_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_620_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    t2: the class of `subject` is `ru_aggregate subject DEF-NRS-484A-130::motor_vehicle`.
    t3: "upon the road" is the declared assumption asm.within_incorporated_city, required false
        (a road is a highway outside the territorial limits of a city).
    t1 + t4: the selected region `r` is a travel region the subject occupies (rel_occupies), lying
        on a highway (st_on_way to a region of kind highway), and governed by a zone sign of kind
        speed_zone that does not mark the zone's end (dev_governs, dev_zone_sign_kind,
        dev_zone_sign_end). The establishment and the installed signs are read from the presence
        of that zone sign and of a speed limit sign of kind zone or maximum governing `r`.
    t5: for every selected region (the whole selection re-written in the obligation) and every
        speed limit sign of kind zone or maximum governing it, kin_speed ≤ the sign's value.
  No choice beyond the record's: no narrowing of this session's own.
-/

/-- Region and device variables. -/
def vR : Arg := .var "r"
def vH : Arg := .var "h"
def vZ : Arg := .var "z"
def vS : Arg := .var "s"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- t3: upon the road — the place is not within an incorporated city. -/
def onRoad : Formula := .not (.asm "asm.within_incorporated_city")

/-- t4: the travel region `r` lies on a highway. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "st_on_way" [vR, vH] [])

/-- t1/t4: a speed_zone zone sign, not an end sign, governs `r`. -/
def inSpeedZone : Formula :=
  .existsDevice (.lit "zone_sign") "z"
    (.and (.atom "dev_governs" [vZ, vR] [])
      (.and (.atom "dev_zone_sign_kind" [vZ, .lit "speed_zone"] [])
        (.not (.atom "dev_zone_sign_end" [vZ] []))))

/-- The record's whole selection of the region `r`. -/
def selected : Formula :=
  .and (.atom "rel_occupies" [vSubject, vR] []) (.and onHighway inSpeedZone)

/-- The speed limit sign `s` governs `r` and is of kind zone or maximum. -/
def authorizing : Formula :=
  .and (.atom "dev_governs" [vS, vR] [])
    (.or (.atom "dev_speed_limit_sign_kind" [vS, .lit "zone"] [])
      (.atom "dev_speed_limit_sign_kind" [vS, .lit "maximum"] []))

/-- Applicability: t1 (condition): After the establishment of a speed zone and the installation of appropriate signs to control speed,; t3 (condition): upon the road; t4 (condition): and in the speed zone -/
def applicability : Formula :=
  .and onRoad
    (.existsRegion (.lit "travel_region") "r"
      (.and selected (.existsDevice (.lit "speed_limit_sign") "s" authorizing)))

/-- Obligation: t5 (obligation): in excess of the speed therein authorized. -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "r"
    (.implies selected
      (.forallDevice (.lit "speed_limit_sign") "s"
        (.implies authorizing
          (.cmp (.measure "kin_speed" [vSubject]) .le
            (.measure "dev_speed_limit_sign_value" [vS])))))

def rule : Rule :=
  { id := "NRS_484B_620_2"
    laws := ["NRS-484B-620-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_incorporated_city"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_620_2
