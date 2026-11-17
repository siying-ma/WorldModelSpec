/-
  NRS_484B_267_1b_o2 — NRS-484B-267-1b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    u1 (standard): Upon the immediate approach of
    u2 (condition): an authorized emergency vehicle
    u3 (condition): or an official vehicle of a regulatory agency,
    u4 (condition): making use of flashing lights meeting the requirements of
    u5 (reference): subsection 3 of NRS 484A.480 [DEF-NRS-484A-480-3],
    u6 (subject): the driver of every other vehicle shall,
    u7 (exception): except when otherwise directed by a law enforcement officer:
    b1 (sibling): Except as otherwise provided in this paragraph,
    b2 (sibling): immediately
    b3 (sibling): drive to a position parallel to, and
    b4 (sibling): as close as possible to, the right-hand edge or, if applicable, curb of a highway
    b5 (sibling): and clear of any intersection.
    b6 (obligation): The driver shall not drive to and stop in a position on a paved shoulder of a highway
    b7 (condition): where lawfully placed signage allows a vehicle described in paragraphs (a) to (f), inclusive, of subsection 4 of NRS 484B.210 [list appended below] to drive on the shoulder.
    b8 (definitional): The provisions of subparagraph (1) of paragraph (c) of subsection 1 do not apply to: (a) An authorized emergency vehicle described in NRS 484A.480; (b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490; (c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle; or (f) A public transit motor bus, that is being driven on the paved shoulder of a highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.

  Elements (span → atoms, derived):
    u2: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle'], derived []
    u3: atoms ['ru.official_vehicle'], derived []
    u4: atoms ['sig.warning_lamp'], derived [], borrowing ['u5']
    u6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    u7: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    b6: atoms ['rel.occupies', 'st.shoulder', 'st.highway', 'st.on_way'], derived ['drv.motion.complete_halt']
    b7: atoms ['dev.regulatory_sign', 'dev.governs'], derived []
    b8: atoms ['dev.regulatory_sign'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    u5: DEF-NRS-484A-480-3: at least one flashing red warning lamp visible from the front

  How each span is written:
    u6 → binder class: ru_aggregate(subject, DEF-NRS-484A-320::vehicle).
    u2/u3 → some road user e, not the subject: ru_aggregate(e, DEF-NRS-484A-020::authorized_emergency_vehicle)
       or (ru_official_vehicle(e) and ru_official_vehicle_kind(e, regulatory_agency)).
    u4/u5 → sig_warning_lamp(e, red, flashing). The record also states 'facing front' ('visible from
       the front'); no accessor of the surface reads a lamp's facing, declared `no_atom` on u4.
    u1 → in the applicability, as the record's applicability places it: kin_speed(e) > p.halt_speed_tolerance,
       rel_bearing(e, subject).x > 0, rel_centre_distance(e, subject) ≤ p.emergency_immediate_approach_reach.
    u7 → not: some human_direction device d of role police_officer governing (dev_governs) a
       travel_region r the subject occupies (rel_occupies).
    b6/b7/b8 → obligation: not (rises(drv_motion_complete_halt(subject; p.halt_speed_tolerance)) and
       some shoulder s the subject occupies, st_shoulder_paved, on (st_on_way) some highway w, governed by
       some regulatory_sign g of code shoulder_use_permitted). The sign is in the obligation, as the
       record's obligation and its branch_1 (compliant without a sign) place it.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_267_1b_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pEmergencyImmediateApproachReach : Term := .param "p.emergency_immediate_approach_reach"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables: `e` the approaching vehicle, `d` a person directing traffic, `r` a travel
    region `d` governs, `s` the shoulder, `w` the highway it lies on, `g` the shoulder-use sign. -/
def vE : Arg := .var "e"
def vD : Arg := .var "d"
def vR : Arg := .var "r"
def vS : Arg := .var "s"
def vW : Arg := .var "w"
def vG : Arg := .var "g"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- u2 / u3: an authorized emergency vehicle, or an official vehicle of kind regulatory_agency. -/
def emergencyOrRegulatory : Formula :=
  .or (.atom "ru_aggregate" [vE, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
      (.and (.atom "ru_official_vehicle" [vE] [])
            (.atom "ru_official_vehicle_kind" [vE, .lit "regulatory_agency"] []))

/-- u4 (+u5): a lit warning lamp, colour red, mode flashing. -/
def flashingRedLamp : Formula := .atom "sig_warning_lamp" [vE, .lit "red", .lit "flashing"] []

/-- u1 (operationalization): `e` moves (speed above the halt tolerance), the subject lies ahead of
    it in its frame (longitudinal bearing positive), within the immediate-approach reach. -/
def immediateApproach : Formula :=
  .and (.cmp (.measure "kin_speed" [vE]) .gt pHaltSpeedTolerance)
    (.and (.cmp (.measure "rel_bearing" [vE, vSubject, .lit "x"]) .gt zeroMetres)
          (.cmp (.measure "rel_centre_distance" [vE, vSubject]) .le pEmergencyImmediateApproachReach))

/-- u7: a person of role police_officer directs traffic in a travel region the subject occupies. -/
def officerDirecting : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
          (.existsRegion (.lit "travel_region") "r"
            (.and (.atom "rel_occupies" [vSubject, vR] [])
                  (.atom "dev_governs" [vD, vR] []))))

/-- Applicability: u1–u5 (some other road user `e`, emergency or regulatory, lamps flashing red,
    in immediate approach) and not u7 (no police officer directing the subject). -/
def applicability : Formula :=
  .and
    (.existsUser "e"
      (.and (.not (.same vE vSubject))
        (.and emergencyOrRegulatory
          (.and flashingRedLamp immediateApproach))))
    (.not officerDirecting)

/-- b6 with b7/b8: the subject's footprint overlaps a paved shoulder lying on a highway, governed
    by a regulatory sign of code shoulder_use_permitted. -/
def onSignedPavedShoulder : Formula :=
  .existsRegion (.lit "shoulder") "s"
    (.and (.atom "rel_occupies" [vSubject, vS] [])
      (.and (.atom "st_shoulder_paved" [vS] [])
        (.and (.existsRegion (.lit "highway") "w" (.atom "st_on_way" [vS, vW] []))
              (.existsDevice (.lit "regulatory_sign") "g"
                (.and (.atom "dev_regulatory_sign_code" [vG, .lit "shoulder_use_permitted"] [])
                      (.atom "dev_governs" [vG, vS] []))))))

/-- Obligation (b6): not — the subject comes to rest here (complete_halt rises) while on such a
    shoulder. -/
def obligation : Formula :=
  .not (.and (.rises (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]))
             onSignedPavedShoulder)

def rule : Rule :=
  { id := "NRS_484B_267_1b_o2"
    laws := ["NRS-484B-267-1b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the immediate approach of the emergency or regulatory vehicle"
          concepts := ["kin.speed", "rel.bearing", "rel.centre_distance"]
          params := ["p.halt_speed_tolerance", "p.emergency_immediate_approach_reach"]
          convention := "the vehicle moves with the subject ahead of it in its own frame, within the centre distance a vehicle at an urban response speed covers in the time a driver needs to perceive its lamps and begin clearing the way"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "u4"
          why := "'visible from the front' (borrowed from DEF-NRS-484A-480-3 via u5; the record's 'facing front'): the formula surface reads a warning lamp only by colour and mode (sig_warning_lamp [x, colour, mode]); no accessor reads its facing, so the condition can be written only as 'a red flashing warning lamp lit', weaker than the record states"
          kind := "no_atom" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_267_1b_o2
