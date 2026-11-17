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
    e4/e7  the binder class is `ru_aggregate subject DEF-NRS-484A-320::vehicle`; "drive" is the
           subject in motion: `drv_motion_complete_halt(subject; p.halt_speed_tolerance)` does not hold.
    e5     some `controlled_access` region the subject's footprint overlaps (`rel_occupies`).
    e1     `sig_hazard(subject)`, or `ru_emergency_vehicle(subject)` together with a lit warning lamp
           (`sig_warning_lamp(subject, c)` for some colour c of red, blue, amber, white — any lamp lit,
           whatever its mode or facing); the class alone is never read as the emergency.
    e2/e10/e18  the permission of subsection 3, joined to the duty as one exception: the subject is a
           listed vehicle (e12-e17) AND it occupies a `shoulder` region that is paved
           (`st_shoulder_paved`) and lies on (`st_on_way`) a `highway` region the subject occupies,
           and some `regulatory_sign` of code `shoulder_use_permitted` governs that shoulder
           (`dev_governs`) with its conditions holding for the subject (`prim_conditions_hold`).
           The controlled-access region e10 names is the one the trigger (e5) already requires the
           subject to occupy at the same observation; it is not restated inside the exception.
    e12/e13 `ru_aggregate subject DEF-NRS-484A-020::authorized_emergency_vehicle` (one limb for both).
    e14/e16 `ru_official_vehicle(subject)` with kind `incident_management` or `coroner`.
    e15    `ru_aggregate subject DEF-NRS-484A-280::tow_car`.
    e17    `ru_aggregate subject DEF-NRS-484A-030::bus` and `ru_transit_bus(subject)`.
    e6     the obligation: for no lanes r1, r2 (`lane` regions the subject occupies) and side s in
           {left, right} does `drv_lane_entering_adjacent_lane(subject, r1, r2, s)` hold where the
           marking on side s of r1 is (solid or double_solid, white) (`st_lane_marking`) and exactly
           one of r1, r2 is governed by a `regulatory_sign` of code entrance or exit. The occupancy
           of r1 and r2 restates what the concept's contract already requires at that observation
           and anchors the two lane quantifiers to the subject.
    e8     a definition composition: no rule is called; e12-e17 carry its words.
    e11    residue (the node's).

  Choices the record left open: none beyond the above; no narrowing is declared.

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

/-- e4: the vehicle is driven — in motion, not at a complete halt. -/
def moving : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- e5: the subject's footprint overlaps a controlled-access region. -/
def onControlledAccess : Formula :=
  .existsRegion (.lit "controlled_access") "ca" (.atom "rel_occupies" [vSubject, .var "ca"] [])

/-- e1: a warning lamp of the subject lit, of any colour. -/
def warningLampLit : Formula :=
  .or (.or (.atom "sig_warning_lamp" [vSubject, .lit "red"] [])
           (.atom "sig_warning_lamp" [vSubject, .lit "blue"] []))
      (.or (.atom "sig_warning_lamp" [vSubject, .lit "amber"] [])
           (.atom "sig_warning_lamp" [vSubject, .lit "white"] []))

/-- e1: the emergency, read through the conduct that shows it. -/
def emergencyConduct : Formula :=
  .or (.atom "sig_hazard" [vSubject] [])
      (.and (.atom "ru_emergency_vehicle" [vSubject] []) warningLampLit)

/-- e12-e17: the vehicles NRS 484B.210(4) lists (borrowed through e8). -/
def listedVehicle : Formula :=
  .or (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
           (.and (.atom "ru_official_vehicle" [vSubject] [])
                 (.or (.atom "ru_official_vehicle_kind" [vSubject, .lit "incident_management"] [])
                      (.atom "ru_official_vehicle_kind" [vSubject, .lit "coroner"] []))))
      (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-280::tow_car"] [])
           (.and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-030::bus"] [])
                 (.atom "ru_transit_bus" [vSubject] [])))

/-- e2/e10/e18: the subject on a paved shoulder, lying on the highway it is on, that a
    shoulder_use_permitted regulatory sign governs with its conditions holding for the subject. -/
def onPermittedShoulder : Formula :=
  .existsRegion (.lit "shoulder") "sh"
    (.and (.and (.atom "rel_occupies" [vSubject, .var "sh"] [])
                (.atom "st_shoulder_paved" [.var "sh"] []))
          (.and (.existsRegion (.lit "highway") "hw"
                  (.and (.atom "rel_occupies" [vSubject, .var "hw"] [])
                        (.atom "st_on_way" [.var "sh", .var "hw"] [])))
                (.existsDevice (.lit "regulatory_sign") "ds"
                  (.and (.and (.atom "dev_governs" [.var "ds", .var "sh"] [])
                              (.atom "dev_regulatory_sign_code" [.var "ds", .lit "shoulder_use_permitted"] []))
                        (.derived "prim_conditions_hold" [.var "ds", vSubject] [])))))

/-- Applicability: e1 (exception): Except if required by an emergency; e2 (exception): or as otherwise authorized by subsection 3; e5 (trigger): on a controlled-access highway:; e7 (exception): A person driving a vehicle described in; e10 (exception): may drive that vehicle on a paved shoulder of a controlled-access highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.; e12 (exception): (a) An authorized emergency vehicle described in NRS 484A.480;; e13 (exception): (b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490;; e14 (exception): (c) A traffic incident management vehicle;; e15 (exception): (d) A tow car;; e16 (exception): (e) A coroner vehicle;; e17 (exception): or (f) A public transit motor bus,; e18 (exception): that is being driven on the paved shoulder of a highway where lawfully placed signage allows that vehicle to use the shoulder in that manner. -/
def applicability : Formula :=
  .and (.and moving onControlledAccess)
       (.and (.not emergencyConduct)
             (.not (.and listedVehicle onPermittedShoulder)))

/-- e6: lane `r` is an entrance or exit lane — governed by a regulatory sign of code entrance or exit. -/
def entranceOrExitLane (r : String) : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_governs" [.var "d", .var r] [])
          (.or (.atom "dev_regulatory_sign_code" [.var "d", .lit "entrance"] [])
               (.atom "dev_regulatory_sign_code" [.var "d", .lit "exit"] [])))

/-- e6: the line between r1 and r2 separates an entrance or exit lane from a marked traffic lane:
    exactly one of the two is so governed. -/
def separatesEntranceOrExit : Formula :=
  .or (.and (entranceOrExitLane "r1") (.not (entranceOrExitLane "r2")))
      (.and (entranceOrExitLane "r2") (.not (entranceOrExitLane "r1")))

/-- e6: the subject's footprint first reaches from r1 into r2 on side `s` across a solid white line. -/
def acrossSolidWhite (s : String) : Formula :=
  .and (.derived "drv_lane_entering_adjacent_lane" [vSubject, .var "r1", .var "r2", .lit s] [])
       (.or (.atom "st_lane_marking" [.var "r1", .lit s, .lit "solid", .lit "white"] [])
            (.atom "st_lane_marking" [.var "r1", .lit s, .lit "double_solid", .lit "white"] []))

/-- Obligation: e6 (obligation): Across any solid white line that separates an entrance or exit lane from a marked traffic lane. -/
def obligation : Formula :=
  .not (.existsRegion (.lit "lane") "r1"
    (.existsRegion (.lit "lane") "r2"
      (.and (.and (.atom "rel_occupies" [vSubject, .var "r1"] [])
                  (.atom "rel_occupies" [vSubject, .var "r2"] []))
            (.and (.or (acrossSolidWhite "left") (acrossSolidWhite "right"))
                  separatesEntranceOrExit))))

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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_587_2b
