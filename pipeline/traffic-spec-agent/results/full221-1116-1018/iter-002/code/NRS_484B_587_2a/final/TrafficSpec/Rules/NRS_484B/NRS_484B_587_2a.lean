/-
  NRS_484B_587_2a — NRS-484B-587-2a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (exception): Except if required by an emergency
    e2 (exception): or as otherwise authorized by subsection 3
    e3 (boilerplate): [(3) appended below],
    e4 (subject): a person shall not drive a vehicle
    e5 (trigger): on a controlled-access highway:
    e6 (obligation): Upon any portion of the highway that lies outside of a marked traffic lane or marked entrance or exit lane.
    e7 (exception): A person driving a vehicle described in
    e8 (reference): paragraphs (a) to (f), inclusive, of subsection 4 of NRS 484B.210
    e9 (boilerplate): [list appended below]
    e10 (exception): may drive that vehicle on a paved shoulder of a controlled-access highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.
    e11 (definitional): The provisions of subparagraph (1) of paragraph (c) of subsection 1 do not apply to:
    e12 (exception): (a) An authorized emergency vehicle described in NRS 484A.480;
    e13 (exception): (b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490;
    e14 (exception): (c) A traffic incident management vehicle;
    e15 (exception): (d) A tow car;
    e16 (exception): (e) A coroner vehicle;
    e17 (exception): or (f) A public transit motor bus,
    e18 (exception): that is being driven on the paved shoulder of a highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.

  Elements (span → atoms, derived):
    e1: atoms ['ru.emergency_vehicle', 'sig.warning_lamp', 'sig.hazard'], derived []
    e2: atoms ['dev.regulatory_sign'], derived []
    e4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    e5: atoms ['rel.occupies', 'st.controlled_access'], derived []
    e6: atoms ['rel.occupies', 'st.lane', 'st.shoulder', 'st.median_or_divider'], derived []
    e7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e10: atoms ['rel.occupies', 'st.shoulder', 'st.controlled_access', 'dev.governs', 'dev.regulatory_sign', 'prim.conditions_hold'], derived []
    e12: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle'], derived [], borrowing ['e8']
    e13: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle'], derived [], borrowing ['e8']
    e14: atoms ['ru.official_vehicle'], derived [], borrowing ['e8']
    e15: atoms ['ru.aggregate=DEF-NRS-484A-280::tow_car'], derived [], borrowing ['e8']
    e16: atoms ['ru.official_vehicle'], derived [], borrowing ['e8']
    e17: atoms ['ru.aggregate=DEF-NRS-484A-030::bus', 'ru.transit_bus'], derived [], borrowing ['e8']
    e18: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.shoulder', 'dev.governs', 'dev.regulatory_sign', 'prim.conditions_hold'], derived [], borrowing ['e8']

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    e8: NRS-484B-210-1: (c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;

  How each span is written:
    e4/e7  the binder class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`; "drive" is the
           subject in motion: `drv_motion_complete_halt(subject; p.halt_speed_tolerance)` not holding.
    e5     some `controlled_access` region the subject occupies (`rel_occupies`).
    e1     the exception: `sig_hazard(subject)`, or `ru_emergency_vehicle(subject)` together with a
           warning lamp lit (`sig_warning_lamp(subject, colour)` for each colour of the enumeration:
           "a warning lamp lit" names no colour). The class alone never excuses.
    e6     the obligation, three conjuncts: no `median_or_divider` occupied; every `shoulder`
           occupied is an authorized one; and some `lane` occupied, or else some authorized
           `shoulder` occupied. The record's "every non-lane region it overlaps is an authorized
           shoulder" is read over the kinds the element names (lane, shoulder, median or divider):
           the controlled-access and highway regions the subject also overlaps are the highway
           itself, not a portion outside a lane, so they are not counted; with the first two
           conjuncts, a subject in no lane complies only on an authorized shoulder.
    e2/e10/e12-e18  an authorized shoulder `s`: the subject is a listed vehicle and `s` is paved
           (`st_shoulder_paved`), lies on (`st_on_way`) a `highway` region the subject occupies,
           and some `regulatory_sign` of code `shoulder_use_permitted` governs it (`dev_governs`)
           with its conditions holding for the subject (`prim_conditions_hold`). Being on the
           controlled-access highway (e10) is already the applicability's.
    listed vehicle (e12/e13, e14, e15, e16, e17): `ru_aggregate` authorized_emergency_vehicle, or
           `ru_official_vehicle` of kind incident_management or coroner, or `ru_aggregate`
           tow_car, or `ru_aggregate` bus together with `ru_transit_bus`.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_587_2a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e4: the vehicle is driven — in motion, not at a complete halt. -/
def moving : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- e5: the subject's footprint overlaps a controlled-access highway. -/
def onControlledAccess : Formula :=
  .existsRegion (.lit "controlled_access") "ca" (.atom "rel_occupies" [vSubject, .var "ca"] [])

/-- e1: a warning lamp lit, of any colour. -/
def warningLampLit : Formula :=
  .or (.atom "sig_warning_lamp" [vSubject, .lit "red"] [])
    (.or (.atom "sig_warning_lamp" [vSubject, .lit "blue"] [])
      (.or (.atom "sig_warning_lamp" [vSubject, .lit "amber"] [])
        (.atom "sig_warning_lamp" [vSubject, .lit "white"] [])))

/-- e1: the emergency, read through the conduct that shows it. -/
def emergency : Formula :=
  .or (.atom "sig_hazard" [vSubject] [])
    (.and (.atom "ru_emergency_vehicle" [vSubject] []) warningLampLit)

/-- Applicability: e4, e5, and the exception e1. -/
def applicability : Formula :=
  .and moving (.and onControlledAccess (.not emergency))

/-- e12-e17: the subject is a vehicle of the list borrowed through e8. -/
def listedVehicle : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
    (.or (.and (.atom "ru_official_vehicle" [vSubject] [])
              (.or (.atom "ru_official_vehicle_kind" [vSubject, .lit "incident_management"] [])
                   (.atom "ru_official_vehicle_kind" [vSubject, .lit "coroner"] [])))
      (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-280::tow_car"] [])
        (.and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-030::bus"] [])
              (.atom "ru_transit_bus" [vSubject] []))))

/-- e2/e10/e18: shoulder `s` is one subsection 3 authorizes the subject to use. -/
def authorizedShoulder (s : String) : Formula :=
  .and listedVehicle
    (.and (.atom "st_shoulder_paved" [.var s] [])
      (.and (.existsRegion (.lit "highway") "hw"
              (.and (.atom "rel_occupies" [vSubject, .var "hw"] [])
                    (.atom "st_on_way" [.var s, .var "hw"] [])))
        (.existsDevice (.lit "regulatory_sign") "sign"
          (.and (.atom "dev_regulatory_sign_code" [.var "sign", .lit "shoulder_use_permitted"] [])
            (.and (.atom "dev_governs" [.var "sign", .var s] [])
                  (.derived "prim_conditions_hold" [.var "sign", vSubject] []))))))

/-- Obligation: e6 (obligation): Upon any portion of the highway that lies outside of a marked traffic lane or marked entrance or exit lane. -/
def obligation : Formula :=
  .and (.not (.existsRegion (.lit "median_or_divider") "md" (.atom "rel_occupies" [vSubject, .var "md"] [])))
    (.and (.forallRegion (.lit "shoulder") "sh"
            (.implies (.atom "rel_occupies" [vSubject, .var "sh"] []) (authorizedShoulder "sh")))
      (.or (.existsRegion (.lit "lane") "ln" (.atom "rel_occupies" [vSubject, .var "ln"] []))
           (.existsRegion (.lit "shoulder") "ash"
              (.and (.atom "rel_occupies" [vSubject, .var "ash"] []) (authorizedShoulder "ash")))))

def rule : Rule :=
  { id := "NRS_484B_587_2a"
    laws := ["NRS-484B-587-2a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["Introduces the list of NRS 484B.210(4) as appended; the exemption from the passing rule of NRS 484B.210(1)(c)(1) it states is that section's, not this duty's, and is not read here."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_587_2a
