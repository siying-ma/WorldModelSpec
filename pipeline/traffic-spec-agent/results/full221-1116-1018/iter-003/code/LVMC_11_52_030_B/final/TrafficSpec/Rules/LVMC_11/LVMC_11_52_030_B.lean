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

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_52_030_B

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s1: the binder class is `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
    s2+s3 (condition, zone): some region z of kind `curb_zone` (st.curb_zone, via the quantifier
        kind) whose colour is yellow (`st_curb_zone_colour z "yellow"`) with
        `rel_occupies(subject, z)`.
    s4/s6 (exception memberships): `ru_aggregate(subject, "DEF-LVMC-11-02-070::commercial_vehicle")`
        and `ru_aggregate(subject, "DEF-LVMC-11-02-140::taxicab")`, each one atom, never a class.
    s5/s7 (the accompanying sign): some device d of kind `zone_sign` (dev.zone_sign) with
        `dev_zone_sign_kind d "parking_restricted"`, governing (`dev_governs`) some region r of kind
        `travel_region` (st.travel_region) that the subject occupies (`rel_occupies`), with
        `prim_conditions_hold(d, subject)`. Each exception is membership ∧ this sign formula, so
        decided-false conditions make the exception false whatever the membership, and holding
        conditions with unknown membership leave it unknown (Kleene conjunction).
    s3/s4/s6 (obligation): `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`, judged at
        the observations where the applicability holds, so the halt judged is a halt in the yellow
        zone (the record places the location in the applicability; the halt concept reads no region).
  No choice beyond the record's was made: no narrowing of this file's own.
-/

def vZ : Arg := .var "z"
def vD : Arg := .var "d"
def vR : Arg := .var "r"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2/s3: the subject occupies a yellow curb zone. -/
def inYellowZone : Formula :=
  .existsRegion (.lit "curb_zone") "z"
    (.and (.atom "st_curb_zone_colour" [vZ, .lit "yellow"] [])
          (.atom "rel_occupies" [vSubject, vZ] []))

/-- s5/s7: an accompanying parking_restricted zone sign governs a travel region the subject
    occupies, and its posted conditions hold for the subject now. -/
def signConditionsHold : Formula :=
  .existsDevice (.lit "zone_sign") "d"
    (.and (.atom "dev_zone_sign_kind" [vD, .lit "parking_restricted"] [])
      (.and (.existsRegion (.lit "travel_region") "r"
               (.and (.atom "dev_governs" [vD, vR] [])
                     (.atom "rel_occupies" [vSubject, vR] [])))
            (.derived "prim_conditions_hold" [vD, vSubject] [])))

/-- s4+s5: commercial vehicle, in accordance with the accompanying sign. -/
def exceptionCommercial : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-070::commercial_vehicle"] [])
       signConditionsHold

/-- s6+s7: taxicab, in accordance with the accompanying sign. -/
def exceptionTaxicab : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-140::taxicab"] [])
       signConditionsHold

/-- Applicability: s2/s3 zone; s4–s7 exceptions. -/
def applicability : Formula :=
  .and inYellowZone (.and (.not exceptionCommercial) (.not exceptionTaxicab))

/-- Obligation: s3 (obligation): Yellow indicates a zone for: — the subject does not halt. -/
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
