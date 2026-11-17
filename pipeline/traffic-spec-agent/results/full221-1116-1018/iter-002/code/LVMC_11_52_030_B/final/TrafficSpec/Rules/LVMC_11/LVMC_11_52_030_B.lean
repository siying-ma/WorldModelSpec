/-
  LVMC_11_52_030_B — LVMC-11-52-030-B

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The parking of vehicles is prohibited or restricted in certain zones as set forth in this Section.
    s2 (condition): The location of such zones shall be established by posting appropriate signage or other durable markings, by painting curbs or the edges of road surfaces in accordance with the colors listed below, or by a combination thereof:
    s3 (obligation): Yellow indicates a zone for:
    s4 (exception): (1) Commercial vehicles to stop, stand or park for the purpose of loading or unloading freight
    s5 (exception): in accordance with the conditions and times posted on an accompanying sign; and
    s6 (exception): (2) Taxicabs to stop, stand, park for the purpose of loading, unloading or waiting for passengers
    s7 (exception): in accordance with the conditions and times posted on an accompanying sign.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.curb_zone', 'rel.occupies'], derived []
    s3: atoms ['st.curb_zone', 'rel.occupies'], derived ['drv.motion.complete_halt']
    s4: atoms ['ru.aggregate=DEF-LVMC-11-02-070::commercial_vehicle'], derived ['drv.motion.complete_halt']
    s5: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.travel_region', 'prim.conditions_hold'], derived []
    s6: atoms ['ru.aggregate=DEF-LVMC-11-02-140::taxicab'], derived ['drv.motion.complete_halt']
    s7: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.travel_region', 'prim.conditions_hold'], derived []

  How each span is written:
    s1: the binder class, ru_aggregate(subject, DEF-NRS-484A-320::vehicle).
    s2/s3: existsRegion curb_zone z with rel_occupies(subject, z) and st_curb_zone_colour(z, yellow).
    s4/s6: ru_aggregate(subject, DEF-LVMC-11-02-070::commercial_vehicle) and
           ru_aggregate(subject, DEF-LVMC-11-02-140::taxicab), each conjoined with s5/s7.
    s5/s7: existsDevice zone_sign d with dev_zone_sign_kind(d, parking_restricted), d governing a
           travel region r the subject occupies (dev_governs, rel_occupies), and
           prim_conditions_hold(d, subject).
    s3 (duty): not drv_motion_complete_halt(subject) with p.halt_speed_tolerance, judged at the
           observations where the applicability (the subject in the yellow zone) holds, so the halt
           judged is a halt in z.
  No reading beyond the record's was chosen; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_52_030_B

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle (s1). -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2/s3: the subject occupies a curb zone (st.curb_zone) whose painted colour is yellow. -/
def inYellowZone : Formula :=
  .existsRegion (.lit "curb_zone") "z"
    (.and (.atom "rel_occupies" [vSubject, .var "z"] [])
          (.atom "st_curb_zone_colour" [.var "z", .lit "yellow"] []))

/-- s5/s7: an accompanying zone sign of kind parking_restricted governs a travel region the
    subject occupies, and its posted conditions hold for the subject. -/
def accompanyingSignHolds : Formula :=
  .existsDevice (.lit "zone_sign") "d"
    (.and (.atom "dev_zone_sign_kind" [.var "d", .lit "parking_restricted"] [])
      (.and (.existsRegion (.lit "travel_region") "r"
              (.and (.atom "dev_governs" [.var "d", .var "r"] [])
                    (.atom "rel_occupies" [vSubject, .var "r"] [])))
            (.derived "prim_conditions_hold" [.var "d", vSubject] [])))

/-- s4+s5: a commercial vehicle within the accompanying sign's conditions. -/
def exceptionCommercial : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-070::commercial_vehicle"] [])
       accompanyingSignHolds

/-- s6+s7: a taxicab within the accompanying sign's conditions. -/
def exceptionTaxicab : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-140::taxicab"] [])
       accompanyingSignHolds

/-- Applicability: s2 (condition) the yellow curb zone the subject occupies; s4–s7 (exceptions)
    the commercial vehicle or taxicab within the accompanying sign's conditions. -/
def applicability : Formula :=
  .and inYellowZone (.not (.or exceptionCommercial exceptionTaxicab))

/-- Obligation: s3 (obligation): Yellow indicates a zone for: — the subject does not halt
    (drv.motion.complete_halt, speed_tol p.halt_speed_tolerance) where it occupies the zone. -/
def obligation : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

def rule : Rule :=
  { id := "LVMC_11_52_030_B"
    laws := ["LVMC-11-52-030-B"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_52_030_B
