/-
  NRS_484B_363_4 — NRS-484B-363-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): shall not overtake and pass another vehicle traveling in the same direction
    s3 (trigger): in an area designated as a school zone or school crossing zone
    s4 (boilerplate): except:
    s5 (exception): (a) On a day on which the school is not in session;
    s6 (exception): (b) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;
    s7 (exception): (c) If the zone is designated by an operational speed limit beacon,
    s8 (exception): during the hours when the pupils of the school are in class
    s9 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;
    s10 (exception): or (d) If the zone is not designated by an operational speed limit beacon,
    s11 (exception): during the times when the sign designating the school zone or school crossing zone indicates that the speed limit is not in effect.
    s12 (definitional): As used in this section, “speed limit beacon” means a device which is used in conjunction with a sign and equipped with two or more yellow lights that flash alternately to indicate when the speed limit in a school zone or school crossing zone is in effect.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.speed'], derived ['drv.interaction.overtake_pass']
    s3: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['dev.speed_limit_beacon', 'dev.governs', 'dev.inoperative', 'st.travel_region'], derived []
    s9: atoms ['dev.speed_limit_beacon'], derived []
    s10: atoms ['dev.speed_limit_beacon', 'dev.governs', 'dev.inoperative', 'st.travel_region'], derived []
    s11: atoms ['dev.zone_sign', 'prim.conditions_hold'], derived []
    s12: atoms ['dev.speed_limit_beacon'], derived []

  How each is written:
    s1  `vehicle subject`: ru_aggregate with the admitted aggregate id.
    s2  For every road user b of the scene that is a vehicle and not the subject (`other`), the pass
        is the concept drv_interaction_overtake_pass(subject, b; p.overtake_window,
        p.overtake_same_direction_cos); the obligation is that it does not hold at the judged
        observation. "traveling" is b's kin.speed above p.halt_speed_tolerance at some observation
        while the pass is under way (`someMoment`).
    occasion (window boundary, W = p.overtake_window): `someMoment φ` is
        ¬holdsFor W (¬(U ∧ φ)) and `throughout φ` is holdsFor W (U → φ), U = `underWay`.
        U is written from the under_way element's atoms: an observation is under way where, since
        an observation at which b was ahead of the moving subject with headings aligned
        (rel_bearing ahead, rel_longitudinal_overlap negative, rel_same_direction within
        p.overtake_same_direction_cos, subject's kin.speed above p.halt_speed_tolerance), the subject
        has kept moving and b has not been behind it, except at the observation where b first comes
        to be behind (the recognition, `rises behind`). The language reads U at each observation of
        the window, without the judged observation, so U marks every observation from an
        ahead-and-aligned observation of the moving subject up to the first behind; at a
        recognition its last such run ends at the record's start of the pass.
    s3  some zone sign z of kind school or school_crossing, not an end sign, governing a travel
        region r (dev_governs) that the subject occupies (rel_occupies) at some observation under way.
    s5  (a) throughout: not asm.school_in_session_day.
    s6  (b) throughout: asm.school_outside_operation_margin.
    s7–s9  (c) throughout: some speed_limit_beacon governs r and is not inoperative, and
        asm.pupils_in_class, and every beacon that governs r and is not inoperative is not flashing.
    s10–s11 (d) throughout: no speed_limit_beacon governs r and is not inoperative, and
        prim_conditions_hold(z, subject) is false.
    s12 is the contract of dev.speed_limit_beacon; it adds no formula.
    The applicability holds where no other vehicle is in the scene (the record: "the duty is met"),
    or where some other vehicle b meets the occasion (travelling, in the zone, no exception
    throughout). The obligation restates that whole selection of b, z and r.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_363_4

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables: the other vehicle, the zone sign, the region, a beacon. -/
def vB : Arg := .var "b"
def vZ : Arg := .var "z"
def vR : Arg := .var "r"
def vBc : Arg := .var "bc"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- s1/s2: membership of the admitted aggregate "vehicle". -/
def vehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: another vehicle of the scene. -/
def other : Formula := .and (vehicle vB) (.not (.same vB vSubject))

/-- The subject moves. -/
def subjectMoving : Formula := .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- s2 "traveling": b moves. -/
def otherMoving : Formula := .cmp (.measure "kin_speed" [vB]) .gt pHaltSpeedTolerance

def noLongitudinalOverlap : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [vSubject, vB]) .lt zeroMetres

/-- b ahead of the subject: positive longitudinal bearing, projections sharing no length. -/
def otherAhead : Formula := .and (.atom "rel_bearing" [vSubject, vB, .lit "ahead"] []) noLongitudinalOverlap

/-- b behind the subject: negative longitudinal bearing, projections sharing no length. -/
def otherBehind : Formula := .and (.atom "rel_bearing" [vSubject, vB, .lit "behind"] []) noLongitudinalOverlap

def aligned : Formula := .atom "rel_same_direction" [vSubject, vB] [pOvertakeSameDirectionCos]

/-- The occasion's under_way element. -/
def underWay : Formula :=
  .since (.and subjectMoving (.or (.not otherBehind) (.rises otherBehind)))
         (.and (.and otherAhead aligned) subjectMoving)

def someMoment (φ : Formula) : Formula :=
  .not (.holdsFor .time pOvertakeWindow "subject" (.not (.and underWay φ)))

def throughout (φ : Formula) : Formula :=
  .holdsFor .time pOvertakeWindow "subject" (.implies underWay φ)

/-- s2: the act. -/
def pass : Formula :=
  .derived "drv_interaction_overtake_pass" [vSubject, vB] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- s3: a school or school crossing zone sign, not an end sign. -/
def schoolZoneSign : Formula :=
  .and (.or (.atom "dev_zone_sign_kind" [vZ, .lit "school"] [])
            (.atom "dev_zone_sign_kind" [vZ, .lit "school_crossing"] []))
       (.not (.atom "dev_zone_sign_end" [vZ] []))

/-- s7/s10: a beacon that governs r and is not inoperative. -/
def beaconOperational : Formula :=
  .and (.atom "dev_governs" [vBc, vR] []) (.not (.atom "dev_inoperative" [vBc] []))

def someOperationalBeacon : Formula := .existsDevice (.lit "speed_limit_beacon") "bc" beaconOperational

/-- (a) s5. -/
def excA : Formula := throughout (.not (.asm "asm.school_in_session_day"))
/-- (b) s6. -/
def excB : Formula := throughout (.asm "asm.school_outside_operation_margin")
/-- (c) s7, s8, s9. -/
def excC : Formula :=
  throughout (.and (.and someOperationalBeacon (.asm "asm.pupils_in_class"))
    (.forallDevice (.lit "speed_limit_beacon") "bc"
      (.implies beaconOperational (.not (.atom "dev_speed_limit_beacon_flashing" [vBc] [])))))
/-- (d) s10, s11. -/
def excD : Formula :=
  throughout (.and (.not someOperationalBeacon) (.not (.derived "prim_conditions_hold" [vZ, vSubject] [])))

/-- s3 with the exceptions, for that z and r. -/
def inSchoolZone : Formula :=
  .existsDevice (.lit "zone_sign") "z"
    (.existsRegion (.lit "travel_region") "r"
      (.and schoolZoneSign
        (.and (.atom "dev_governs" [vZ, vR] [])
          (.and (someMoment (.atom "rel_occupies" [vSubject, vR] []))
            (.and (.not excA) (.and (.not excB) (.and (.not excC) (.not excD))))))))

/-- The occasion of the duty for one other road user b. -/
def occasion : Formula := .and other (.and (someMoment otherMoving) inSchoolZone)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := vehicle vSubject

/-- Applicability: no other vehicle in the scene (the duty is met), or some other vehicle whose
    pass would be made travelling, in the zone, with no exception throughout. -/
def applicability : Formula :=
  .or (.not (.existsUser "b" other)) (.existsUser "b" occasion)

/-- Obligation: s2 (obligation): shall not overtake and pass another vehicle traveling in the same direction -/
def obligation : Formula := .forallUser "b" (.implies occasion (.not pass))

def rule : Rule :=
  { id := "NRS_484B_363_4"
    laws := ["NRS-484B-363-4"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.school_in_session_day", "asm.school_outside_operation_margin", "asm.pupils_in_class"]
    intentions := []
    operationalizations := []
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_363_4
