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
    s1: the binder class, ru_aggregate subject "DEF-NRS-484A-320::vehicle".
    s2: for each road user b (ru_aggregate b vehicle, not same as subject), the act is
        drv_interaction_overtake_pass(subject, b; p.overtake_window, p.overtake_same_direction_cos);
        "traveling" is kin_speed b > p.halt_speed_tolerance at some observation of the pass
        (some_moment over U). The obligation: for every selected b, no pass at the judged instant.
    Occasion (boundary window, W = p.overtake_window, s = subject): some_moment φ is
        ¬holdsFor W s ¬(U ∧ φ); throughout φ is holdsFor W s (U → φ). U, from the under_way atoms:
        AA = subject moving (kin_speed > p.halt_speed_tolerance) ∧ rel_bearing ahead ∧
             rel_longitudinal_overlap < 0 ∧ rel_same_direction(p.overtake_same_direction_cos);
        Behind = rel_bearing behind ∧ rel_longitudinal_overlap < 0;
        U = ¬AA ∧ since(alongside ∨ rises Behind, AA), alongside = ¬AA ∧ ¬Behind ∧ subject moving.
        U holds at each observation after the last ahead-aligned one, through the drawing-past
        with the subject moving, up to and including the first observation with b behind (the
        recognition), and not after it. Choice: the past-only language cannot mark the last
        ahead-aligned observation itself (that needs the next observation), so U begins at the
        observation after it; the alternative, counting every ahead-aligned observation of the
        approach, would read observations before the pass began.
    s3 (some_moment): existsRegion travel_region r, existsDevice zone_sign z with, at one
        observation of the pass, rel_occupies subject r ∧ dev_governs z r ∧ kind school or
        school_crossing ∧ ¬dev_zone_sign_end z.
    s5 (a): throughout ¬asm.school_in_session_day; s6 (b): throughout asm.school_outside_operation_margin.
    s7–s9 (c): throughout [some speed_limit_beacon governs r and is not dev_inoperative ∧
        asm.pupils_in_class ∧ every such beacon is not flashing].
    s10–s11 (d): throughout [no such beacon ∧ ¬prim_conditions_hold(z, subject)].
    Each exception is negated in the applicability: the duty applies where none holds throughout.
    "With no other vehicle in the scene the duty is met" (the record's applicability): a second
        disjunct, no road user o other than the subject is a vehicle and the subject occupies a
        travel region a school / school_crossing zone sign (not an end sign) governs; the
        obligation is then met vacuously. Choice: the zone of s3 is kept in that disjunct so the
        trigger still decides the engagement.
    s12: definitional; carried by dev.speed_limit_beacon (the quantifier kind and its flashing attribute).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_363_4

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables: `b` the other vehicle, `r` the travel region, `z` the zone sign. -/
def vB : Arg := .var "b"
def vR : Arg := .var "r"
def vZ : Arg := .var "z"

/-- s1, s2: membership of the admitted aggregate `vehicle` (DEF-NRS-484A-320). -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

-- ---------------------------------------------------------------------------------------------
-- The occasion: the pass of `b` under way (record `occasion.under_way`).
-- ---------------------------------------------------------------------------------------------

/-- The subject moves: its speed above the halt tolerance. -/
def subjectMoving : Formula := .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- The two bodies' projections on the subject's heading share no length. -/
def noOverlap : Formula := .cmp (.measure "rel_longitudinal_overlap" [vSubject, vB]) .lt zeroMetres

/-- b ahead of the moving subject with headings aligned (the observation that begins the pass). -/
def aheadAligned : Formula :=
  .and subjectMoving
    (.and (.atom "rel_bearing" [vSubject, vB, .lit "ahead"] [])
      (.and noOverlap (.atom "rel_same_direction" [vSubject, vB] [pOvertakeSameDirectionCos])))

/-- b behind the subject, the projections sharing no length. -/
def behindClear : Formula := .and (.atom "rel_bearing" [vSubject, vB, .lit "behind"] []) noOverlap

/-- The moving subject drawing past b: b neither ahead-aligned nor behind. -/
def alongside : Formula := .and (.not aheadAligned) (.and (.not behindClear) subjectMoving)

/-- U: an observation after the last one at which b was ahead-aligned, the subject moving and b
    alongside at every observation since, up to and including the one at which b comes to be
    behind (the recognition). -/
def underWay : Formula :=
  .and (.not aheadAligned) (.since (.or alongside (.rises behindClear)) aheadAligned)

/-- A span read `some_moment` over the pass. -/
def someMoment (φ : Formula) : Formula :=
  .not (.holdsFor .time pOvertakeWindow "subject" (.not (.and underWay φ)))

/-- A span read `throughout` the pass. -/
def throughout (φ : Formula) : Formula :=
  .holdsFor .time pOvertakeWindow "subject" (.implies underWay φ)

-- ---------------------------------------------------------------------------------------------
-- The elements.
-- ---------------------------------------------------------------------------------------------

/-- s2: b travelling: its speed above the halt tolerance at some observation of the pass. -/
def otherTravelling : Formula :=
  someMoment (.cmp (.measure "kin_speed" [vB]) .gt pHaltSpeedTolerance)

/-- s3: a zone sign of kind school or school_crossing, not an end sign. -/
def schoolZoneSign (z : Arg) : Formula :=
  .and (.or (.atom "dev_zone_sign_kind" [z, .lit "school"] [])
            (.atom "dev_zone_sign_kind" [z, .lit "school_crossing"] []))
       (.not (.atom "dev_zone_sign_end" [z] []))

/-- s3: the subject's footprint overlaps r, which z governs (some observation of the pass). -/
def inZone : Formula :=
  someMoment (.and (.atom "rel_occupies" [vSubject, vR] [])
                   (.and (.atom "dev_governs" [vZ, vR] []) (schoolZoneSign vZ)))

/-- s7, s10: a speed limit beacon governing r that is not inoperative. -/
def operationalBeacon (v : String) : Formula :=
  .existsDevice (.lit "speed_limit_beacon") v
    (.and (.atom "dev_governs" [.var v, vR] []) (.not (.atom "dev_inoperative" [.var v] [])))

/-- (a) s5: not a school day. -/
def excA : Formula := throughout (.not (.asm "asm.school_in_session_day"))

/-- (b) s6: outside the operation margin. -/
def excB : Formula := throughout (.asm "asm.school_outside_operation_margin")

/-- (c) s7, s8, s9: an operational beacon governs r, pupils in class, and no operational beacon
    governing r flashes. -/
def excC : Formula :=
  throughout
    (.and (operationalBeacon "bc")
      (.and (.asm "asm.pupils_in_class")
        (.forallDevice (.lit "speed_limit_beacon") "bf"
          (.implies (.and (.atom "dev_governs" [.var "bf", vR] [])
                          (.not (.atom "dev_inoperative" [.var "bf"] [])))
                    (.not (.atom "dev_speed_limit_beacon_flashing" [.var "bf"] []))))))

/-- (d) s10, s11: no operational beacon governs r, and the zone sign's conditions do not hold. -/
def excD : Formula :=
  throughout
    (.and (.not (operationalBeacon "bd"))
          (.not (.derived "prim_conditions_hold" [vZ, vSubject] [])))

/-- s3 with the exceptions: some region r and zone sign z of the pass, with no exception holding
    throughout it. -/
def passInZone : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.existsDevice (.lit "zone_sign") "z"
      (.and inZone
        (.and (.not excA) (.and (.not excB) (.and (.not excC) (.not excD))))))

/-- The other vehicles whose pass the duty governs. -/
def selected : Formula :=
  .and (isVehicle vB)
    (.and (.not (.same vB vSubject))
      (.and otherTravelling passInZone))

/-- s2: the subject overtakes and passes b. -/
def overtakePass : Formula :=
  .derived "drv_interaction_overtake_pass" [vSubject, vB] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- The record's "with no other vehicle in the scene the duty is met": the subject, the only
    vehicle, in a region a school (crossing) zone sign governs. -/
def aloneInZone : Formula :=
  .and (.not (.existsUser "o" (.and (isVehicle (.var "o")) (.not (.same (.var "o") vSubject)))))
    (.existsRegion (.lit "travel_region") "rz"
      (.and (.atom "rel_occupies" [vSubject, .var "rz"] [])
        (.existsDevice (.lit "zone_sign") "zz"
          (.and (.atom "dev_governs" [.var "zz", .var "rz"] []) (schoolZoneSign (.var "zz"))))))

/-- Applicability: s3 (trigger) and the exceptions s5–s11, per other travelling vehicle. -/
def applicability : Formula := .or (.existsUser "b" selected) aloneInZone

/-- Obligation: s2 (obligation): for every selected b, no pass of b. -/
def obligation : Formula := .forallUser "b" (.implies selected (.not overtakePass))

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
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_363_4
