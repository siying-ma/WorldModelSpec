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
    e17: atoms ['ru.transit_bus'], derived [], borrowing ['e8']
    e18: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.shoulder', 'dev.governs', 'dev.regulatory_sign', 'prim.conditions_hold'], derived [], borrowing ['e8']

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    e8: NRS-484B-210-1: (c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;

  How each span is written:
    e4: class ru_aggregate(subject, DEF-NRS-484A-320::vehicle); "drive" = not drv_motion_complete_halt
        with p.halt_speed_tolerance (the record's observable reading).
    e5: some controlled_access region the subject occupies.
    e1: sig_hazard(subject), or ru_emergency_vehicle(subject) with sig_warning_lamp lit; the lamp
        atom takes a colour, so "a warning lamp lit" is the disjunction over every colour (red, blue,
        amber, white) — the whole meaning, no narrowing.
    e2/e10/e18 (authorization, placed in the obligation as the record's obligation states): the
        shoulder is paved (st_shoulder_paved), lies on (st_on_way) a highway region the subject
        occupies, and is governed (dev_governs) by a regulatory_sign of code shoulder_use_permitted
        whose conditions hold for the subject (prim_conditions_hold).
    e7/e12–e17: the listed classes — the two aggregates, ru_official_vehicle of kind
        incident_management or coroner, ru_transit_bus.
    e6: no median_or_divider occupied; every occupied shoulder authorized; and some lane or some
        shoulder occupied (the record's "overlaps some st.lane unless every shoulder ... it overlaps
        is an authorized shoulder", read with the shoulder actually overlapped, so a footprint on
        the controlled-access highway that overlaps neither lane nor shoulder is outside the lanes,
        as the record's e6 narrowing states).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_587_2a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e4: the vehicle is driven — moving, not at complete halt with the speed tolerance. -/
def driven : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- e5: the subject's footprint overlaps a controlled-access highway region. -/
def onControlledAccess : Formula :=
  .existsRegion (.lit "controlled_access") "ca" (occ "ca")

/-- e1: the emergency, read through conduct: hazard lamps flashing, or an emergency vehicle with a
    lit warning lamp (of any colour). -/
def warningLampLit : Formula :=
  .or (.atom "sig_warning_lamp" [vSubject, .lit "red"] [])
    (.or (.atom "sig_warning_lamp" [vSubject, .lit "blue"] [])
      (.or (.atom "sig_warning_lamp" [vSubject, .lit "amber"] [])
        (.atom "sig_warning_lamp" [vSubject, .lit "white"] [])))

def emergency : Formula :=
  .or (.atom "sig_hazard" [vSubject] [])
    (.and (.atom "ru_emergency_vehicle" [vSubject] []) warningLampLit)

/-- e7, e8, e12–e17: the subject is one of the listed vehicles. -/
def listedVehicle : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
    (.or (.and (.atom "ru_official_vehicle" [vSubject] [])
               (.or (.atom "ru_official_vehicle_kind" [vSubject, .lit "incident_management"] [])
                    (.atom "ru_official_vehicle_kind" [vSubject, .lit "coroner"] [])))
      (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-280::tow_car"] [])
           (.atom "ru_transit_bus" [vSubject] [])))

/-- e2, e10, e18: shoulder `s` is authorized for the subject — a listed vehicle, the shoulder paved,
    lying on a highway the subject is on, governed by a shoulder_use_permitted regulatory sign whose
    conditions hold for the subject. -/
def authorizedShoulder (s : String) : Formula :=
  .and listedVehicle
    (.and (.atom "st_shoulder_paved" [.var s] [])
      (.and (.existsRegion (.lit "highway") "hw"
               (.and (occ "hw") (.atom "st_on_way" [.var s, .var "hw"] [])))
            (.existsDevice (.lit "regulatory_sign") "sign"
               (.and (.atom "dev_regulatory_sign_code" [.var "sign", .lit "shoulder_use_permitted"] [])
                 (.and (.atom "dev_governs" [.var "sign", .var s] [])
                       (.derived "prim_conditions_hold" [.var "sign", vSubject] []))))))

/-- Applicability: e1 (exception): Except if required by an emergency; e2 (exception): or as otherwise authorized by subsection 3; e5 (trigger): on a controlled-access highway:; e7 (exception): A person driving a vehicle described in; e10 (exception): may drive that vehicle on a paved shoulder of a controlled-access highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.; e12 (exception): (a) An authorized emergency vehicle described in NRS 484A.480;; e13 (exception): (b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490;; e14 (exception): (c) A traffic incident management vehicle;; e15 (exception): (d) A tow car;; e16 (exception): (e) A coroner vehicle;; e17 (exception): or (f) A public transit motor bus,; e18 (exception): that is being driven on the paved shoulder of a highway where lawfully placed signage allows that vehicle to use the shoulder in that manner. -/
def applicability : Formula :=
  .and driven (.and onControlledAccess (.not emergency))

/-- Obligation: e6 (obligation): Upon any portion of the highway that lies outside of a marked traffic lane or marked entrance or exit lane.
    No median or divider overlapped; every shoulder overlapped is an authorized one; and the
    footprint overlaps some lane or some (thereby authorized) shoulder — a footprint on the
    controlled-access highway overlapping neither is outside the marked lanes. -/
def obligation : Formula :=
  .and (.forallRegion (.lit "median_or_divider") "md" (.not (occ "md")))
    (.and (.forallRegion (.lit "shoulder") "sh" (.implies (occ "sh") (authorizedShoulder "sh")))
      (.or (.existsRegion (.lit "lane") "ln" (occ "ln"))
           (.existsRegion (.lit "shoulder") "sh2" (occ "sh2"))))

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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_587_2a
