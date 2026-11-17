/-
  NRS_484B_587_2b — NRS-484B-587-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (exception): Except if required by an emergency
    e2 (exception): or as otherwise authorized by subsection 3
    e3 (boilerplate): [(3) appended below],
    e4 (subject): a person shall not drive a vehicle
    e5 (trigger): on a controlled-access highway:
    e6 (obligation): Across any solid white line that separates an entrance or exit lane from a marked traffic lane.
    e7 (exception): A person driving a vehicle described in
    e8 (reference): paragraphs (a) to (f), inclusive, of subsection 4 of NRS 484B.210
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
    e6: atoms ['st.lane_marking', 'st.lane', 'dev.governs', 'dev.regulatory_sign'], derived ['drv.lane.entering_adjacent_lane']
    e7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e10: atoms ['rel.occupies', 'st.shoulder', 'st.controlled_access', 'dev.governs', 'dev.regulatory_sign', 'prim.conditions_hold'], derived []
    e12: atoms ['ru.emergency_vehicle'], derived [], borrowing ['e8']
    e13: atoms ['ru.emergency_vehicle'], derived [], borrowing ['e8']
    e14: atoms ['ru.official_vehicle'], derived [], borrowing ['e8']
    e15: atoms ['ru.official_vehicle', 'ru.motor_vehicle'], derived [], borrowing ['e8']
    e16: atoms ['ru.official_vehicle'], derived [], borrowing ['e8']
    e17: atoms ['ru.transit_bus'], derived [], borrowing ['e8']
    e18: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.shoulder', 'dev.governs', 'dev.regulatory_sign', 'prim.conditions_hold'], derived [], borrowing ['e8']

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    e8: NRS-484B-210-1: (c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;

  How each span is written:
    e4  binder class: ru_aggregate(subject, DEF-NRS-484A-320::vehicle); "drive" as the subject not
        at rest: ¬ drv_motion_complete_halt(subject) with p.halt_speed_tolerance.
    e5  ∃ ca : controlled_access, rel_occupies(subject, ca).
    e1  exception: sig_hazard(subject), or ru_emergency_vehicle(subject) with a warning lamp lit
        (sig_warning_lamp of any colour: red, blue, amber or white — "a warning lamp lit").
    e2/e7/e10/e12–e18  exception: the subject is a listed vehicle — ru_emergency_vehicle (e12, e13);
        ru_official_vehicle of kind incident_management (e14) or coroner (e16); ru_official_vehicle of
        kind tow that is ru_motor_vehicle (e15); ru_transit_bus (e17) — and it occupies a paved
        shoulder sh (st_shoulder_paved) lying on (st_on_way) a highway hw it occupies, and some
        regulatory sign of code shoulder_use_permitted governs sh with its conditions holding for the
        subject (prim_conditions_hold). The controlled-access region of e10 is the one of e5, which the
        applicability already requires the subject to occupy.
    e6  obligation: for no lanes r1, r2 does drv_lane_entering_adjacent_lane(subject, r1, r2, s) hold
        with s = left or right, where the marking on side s of r1 is (solid | double_solid, white),
        and one of r1, r2 is governed by a regulatory sign coded entrance or exit and the other by
        none (each lane's test is its own device quantifier).
    e8  borrowed list only (definition): carried by e12–e17; no rule is composed.
    e11 residue (the node's).

  No choice beyond the record's: no narrowing of my own is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_587_2b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e4: the vehicle is driven — not at rest. -/
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

/-- e1: an emergency, read through the conduct that shows it. -/
def emergencyShown : Formula :=
  .or (.atom "sig_hazard" [vSubject] [])
    (.and (.atom "ru_emergency_vehicle" [vSubject] []) warningLampLit)

/-- e12–e17 (the list borrowed through e8): the vehicles subsection 3 names. -/
def listedVehicle : Formula :=
  .or (.atom "ru_emergency_vehicle" [vSubject] [])
    (.or (.and (.atom "ru_official_vehicle" [vSubject] [])
            (.or (.atom "ru_official_vehicle_kind" [vSubject, .lit "incident_management"] [])
              (.or (.atom "ru_official_vehicle_kind" [vSubject, .lit "coroner"] [])
                (.and (.atom "ru_official_vehicle_kind" [vSubject, .lit "tow"] [])
                      (.atom "ru_motor_vehicle" [vSubject] [])))))
      (.atom "ru_transit_bus" [vSubject] []))

/-- e10/e18: the subject on a paved shoulder lying on a highway it occupies, the shoulder governed by
    a shoulder_use_permitted regulatory sign whose conditions hold for it. -/
def onPermittedShoulder : Formula :=
  .existsRegion (.lit "shoulder") "sh"
    (.and (.atom "rel_occupies" [vSubject, .var "sh"] [])
      (.and (.atom "st_shoulder_paved" [.var "sh"] [])
        (.and (.existsRegion (.lit "highway") "hw"
                (.and (.atom "rel_occupies" [vSubject, .var "hw"] [])
                      (.atom "st_on_way" [.var "sh", .var "hw"] [])))
              (.existsDevice (.lit "regulatory_sign") "dsh"
                (.and (.atom "dev_regulatory_sign_code" [.var "dsh", .lit "shoulder_use_permitted"] [])
                  (.and (.atom "dev_governs" [.var "dsh", .var "sh"] [])
                        (.derived "prim_conditions_hold" [.var "dsh", vSubject] [])))))))

/-- e2/e7/e10/e12–e18: authorized by subsection 3. -/
def authorizedBySubsection3 : Formula := .and listedVehicle onPermittedShoulder

/-- Applicability: e1 (exception): Except if required by an emergency; e2 (exception): or as otherwise authorized by subsection 3; e5 (trigger): on a controlled-access highway:; e7 (exception): A person driving a vehicle described in; e10 (exception): may drive that vehicle on a paved shoulder of a controlled-access highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.; e12 (exception): (a) An authorized emergency vehicle described in NRS 484A.480;; e13 (exception): (b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490;; e14 (exception): (c) A traffic incident management vehicle;; e15 (exception): (d) A tow car;; e16 (exception): (e) A coroner vehicle;; e17 (exception): or (f) A public transit motor bus,; e18 (exception): that is being driven on the paved shoulder of a highway where lawfully placed signage allows that vehicle to use the shoulder in that manner. -/
def applicability : Formula :=
  .and moving
    (.and onControlledAccess
      (.and (.not emergencyShown) (.not authorizedBySubsection3)))

/-- e6: lane `r` is governed by a regulatory sign coded entrance or exit (device variable `d`). -/
def entranceOrExitLane (r d : String) : Formula :=
  .existsDevice (.lit "regulatory_sign") d
    (.and (.or (.atom "dev_regulatory_sign_code" [.var d, .lit "entrance"] [])
               (.atom "dev_regulatory_sign_code" [.var d, .lit "exit"] []))
          (.atom "dev_governs" [.var d, .var r] []))

/-- e6: the line separates an entrance or exit lane from a marked traffic lane. -/
def separatesRampFromThrough : Formula :=
  .or (.and (entranceOrExitLane "r1" "dA1") (.not (entranceOrExitLane "r2" "dA2")))
      (.and (entranceOrExitLane "r2" "dB2") (.not (entranceOrExitLane "r1" "dB1")))

/-- e6: a solid white line on side `s` of r1. -/
def solidWhiteOn (s : String) : Formula :=
  .or (.atom "st_lane_marking" [.var "r1", .lit s, .lit "solid", .lit "white"] [])
      (.atom "st_lane_marking" [.var "r1", .lit s, .lit "double_solid", .lit "white"] [])

/-- e6: the footprint first reaches from r1 into r2 across that line on side `s`. -/
def crossesOn (s : String) : Formula :=
  .and (.derived "drv_lane_entering_adjacent_lane" [vSubject, .var "r1", .var "r2", .lit s] [])
       (solidWhiteOn s)

/-- Obligation: e6 (obligation): Across any solid white line that separates an entrance or exit lane from a marked traffic lane. -/
def obligation : Formula :=
  .not (.existsRegion (.lit "lane") "r1"
    (.existsRegion (.lit "lane") "r2"
      (.and (.or (crossesOn "left") (crossesOn "right")) separatesRampFromThrough)))

def rule : Rule :=
  { id := "NRS_484B_587_2b"
    laws := ["NRS-484B-587-2b"]
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

end TrafficSpec.Rules.NRS_484B_587_2b
