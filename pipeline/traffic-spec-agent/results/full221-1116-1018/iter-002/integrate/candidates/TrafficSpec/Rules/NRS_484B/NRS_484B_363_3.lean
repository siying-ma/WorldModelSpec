/-
  NRS_484B_363_3 — NRS-484B-363-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): shall not make a U-turn
    s3 (trigger): in an area designated as a school zone or school crossing zone
    s4 (boilerplate): except:
    s5 (exception): (a) When there are no children present;
    s6 (exception): (b) On a day on which school is not in session;
    s7 (exception): (c) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;
    s8 (exception): (d) If the zone is designated by an operational speed limit beacon,
    s9 (exception): during the hours when the pupils of the school are in class
    s10 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;
    s11 (exception): or (e) If the zone is not designated by an operational speed limit beacon,
    s12 (exception): during the times when the sign designating the school zone or school crossing zone indicates that the speed limit is not in effect.
    s13 (definitional): As used in this section, “speed limit beacon” means a device which is used in conjunction with a sign and equipped with two or more yellow lights that flash alternately to indicate when the speed limit in a school zone or school crossing zone is in effect.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms [], derived ['drv.motion.u_turn']
    s3: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s5: atoms ['ru.child', 'st.region_geometry', 'dev.governs', 'dev.zone_sign', 'st.travel_region'], derived []
    s8: atoms ['dev.speed_limit_beacon', 'dev.governs', 'dev.inoperative', 'st.travel_region'], derived []
    s10: atoms ['dev.speed_limit_beacon'], derived []
    s11: atoms ['dev.speed_limit_beacon', 'dev.governs', 'dev.inoperative', 'st.travel_region'], derived []
    s12: atoms ['dev.zone_sign', 'prim.conditions_hold'], derived []
    s13: atoms ['dev.speed_limit_beacon'], derived []

  How each span is written.
    s1  `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`, the binder's class.
    s2  the obligation: `drv_motion_u_turn(subject; p.vehicle_turn_window, p.u_turn_heading_min,
        p.turn_yaw_rate_tol)` does not hold. It holds only at the recognition, so the duty is broken
        there; at the other observations of an applicable stretch it is kept.
    occasion (window boundary): U = |kin_yaw_rate subject| > p.turn_yaw_rate_tol, the under-way
        element. A span read `some_moment` is `¬ holdsFor W (¬ (U ∧ φ))`, one read `throughout` is
        `holdsFor W (U → φ)`, W = p.vehicle_turn_window.
    s3  some zone sign z (device quantifier, kind zone_sign) and some travel region r (region
        quantifier, kind travel_region) bound at the judged observation; at some moment while the
        U-turn is under way, z is of kind school or school_crossing, not an end sign, governs r, and
        the subject occupies r.
    s5  exception (a), for that z: no road user c that is ru_child has its body within
        p.pedestrian_near_reach (st_region_geometry_distance, ≤) of a travel region q that z governs.
    s6  exception (b): asm.school_in_session_day is false.
    s7  exception (c): asm.school_outside_operation_margin holds.
    s8–s10 exception (d), one formula per observation: some speed_limit_beacon b governs r and is not
        dev_inoperative; asm.pupils_in_class; every beacon that governs r and is not inoperative is not
        flashing.
    s11–s12 exception (e), one formula per observation: no beacon governs r and is not inoperative;
        prim_conditions_hold(z, subject) is false.
    s13 definitional: the device kind speed_limit_beacon itself; it adds no condition.
    Each exception excuses the act only where it holds at every observation while the U-turn is
    under way (the record's applicability states this for all five, so (b) and (c) are read
    `throughout` like the spans the occasion lists). The applicability is the s3 trigger and the
    negation of each such exception, for the same z and r.

  No choice beyond the record was needed: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_363_3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedestrianNearReach : Term := .param "p.pedestrian_near_reach"
def pTurnYawRateTol : Term := .param "p.turn_yaw_rate_tol"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"
def pVehicleTurnWindow : Term := .param "p.vehicle_turn_window"

def zeroMetres : Term := .lit Q.zero .metre

def vZ : Arg := .var "z"
def vR : Arg := .var "r"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: the recognised U-turn of the subject. -/
def uTurn : Formula :=
  .derived "drv_motion_u_turn" [vSubject] [pVehicleTurnWindow, pUTurnHeadingMin, pTurnYawRateTol]

/-- The occasion's under-way element: the subject's heading is turning. -/
def underWay : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [vSubject])) .gt pTurnYawRateTol

/-- A span read at some moment while the U-turn is under way (window behind). -/
def someMoment (φ : Formula) : Formula :=
  .not (.holdsFor .time pVehicleTurnWindow "subject" (.not (.and underWay φ)))

/-- A span read at every observation while the U-turn is under way (window behind). -/
def throughout (φ : Formula) : Formula :=
  .holdsFor .time pVehicleTurnWindow "subject" (.implies underWay φ)

/-- s3: z is a school or school-crossing zone sign, not an end sign, governing r, which the subject
    occupies. -/
def s3Zone : Formula :=
  .and (.or (.atom "dev_zone_sign_kind" [vZ, .lit "school"] [])
            (.atom "dev_zone_sign_kind" [vZ, .lit "school_crossing"] []))
    (.and (.not (.atom "dev_zone_sign_end" [vZ] []))
      (.and (.atom "dev_governs" [vZ, vR] [])
            (.atom "rel_occupies" [vSubject, vR] [])))

/-- s5, exception (a): no child within the reach of any travel region z governs. -/
def excA : Formula :=
  .not (.existsUser "c"
    (.and (.atom "ru_child" [.var "c"] [])
      (.existsRegion (.lit "travel_region") "q"
        (.and (.atom "dev_governs" [vZ, .var "q"] [])
          (.cmp (.measure "st_region_geometry_distance" [.var "c", .var "q"]) .le pPedestrianNearReach)))))

/-- s6, exception (b): the day is not a school-session day. -/
def excB : Formula := .not (.asm "asm.school_in_session_day")

/-- s7, exception (c): outside the operation margin. -/
def excC : Formula := .asm "asm.school_outside_operation_margin"

/-- s8/s11: some beacon governs r and is not inoperative (the zone is designated by an operational
    speed limit beacon). -/
def operationalBeacon : Formula :=
  .existsDevice (.lit "speed_limit_beacon") "b"
    (.and (.atom "dev_governs" [.var "b", vR] [])
          (.not (.atom "dev_inoperative" [.var "b"] [])))

/-- s10: no operational beacon governing r is flashing. -/
def noBeaconFlashing : Formula :=
  .forallDevice (.lit "speed_limit_beacon") "b"
    (.implies (.and (.atom "dev_governs" [.var "b", vR] [])
                    (.not (.atom "dev_inoperative" [.var "b"] [])))
              (.not (.atom "dev_speed_limit_beacon_flashing" [.var "b"] [])))

/-- s8–s10, exception (d). -/
def excD : Formula :=
  .and operationalBeacon (.and (.asm "asm.pupils_in_class") noBeaconFlashing)

/-- s11–s12, exception (e). -/
def excE : Formula :=
  .and (.not operationalBeacon)
       (.not (.derived "prim_conditions_hold" [vZ, vSubject] []))

/-- Applicability: s3 (trigger): in an area designated as a school zone or school crossing zone; s5 (exception): (a) When there are no children present;; s6 (exception): (b) On a day on which school is not in session;; s7 (exception): (c) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;; s8 (exception): (d) If the zone is designated by an operational speed limit beacon,; s9 (exception): during the hours when the pupils of the school are in class; s10 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;; s11 (exception): or (e) If the zone is not designated by an operational speed limit beacon,; s12 (exception): during the times when the sign designating the school zone or school crossing zone indicates that the speed limit is not in effect. -/
def applicability : Formula :=
  .existsDevice (.lit "zone_sign") "z"
    (.existsRegion (.lit "travel_region") "r"
      (.and (someMoment s3Zone)
        (.and (.not (throughout excA))
          (.and (.not (throughout excB))
            (.and (.not (throughout excC))
              (.and (.not (throughout excD))
                    (.not (throughout excE))))))))

/-- Obligation: s2 (obligation): shall not make a U-turn -/
def obligation : Formula := .not uTurn

def rule : Rule :=
  { id := "NRS_484B_363_3"
    laws := ["NRS-484B-363-3"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.school_in_session_day", "asm.school_outside_operation_margin", "asm.pupils_in_class"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_363_3
