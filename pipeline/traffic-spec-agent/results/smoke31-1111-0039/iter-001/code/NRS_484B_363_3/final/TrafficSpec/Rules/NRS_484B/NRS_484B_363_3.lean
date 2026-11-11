/-
  NRS_484B_363_3 — NRS-484B-363-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (subject): The driver of a vehicle
    d2 (obligation): shall not make a U-turn
    d3 (trigger): in an area designated as a school zone or school crossing zone
    d4 (boilerplate): except:
    d5 (exception): (a) When there are no children present;
    d6 (exception): (b) On a day on which school is not in session;
    d7 (exception): (c) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;
    d8 (exception): (d) If the zone is designated by an operational speed limit beacon,
    d9 (exception): during the hours when the pupils of the school are in class
    d10 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;
    d11 (boilerplate): or
    d12 (exception): (e) If the zone is not designated by an operational speed limit beacon,
    d13 (exception): during the times when the sign designating the school zone or school crossing zone indicates that the speed limit is not in effect.
    d14 (definitional): As used in this section, “speed limit beacon” means a device which is used in conjunction with a sign and equipped with two or more yellow lights that flash alternately to indicate when the speed limit in a school zone or school crossing zone is in effect.

  Elements (span → atoms, derived):
    d1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d2: atoms ['prim.heading_change'], derived ['drv.motion.u_turn']
    d3: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    d5: atoms ['ru.child', 'st.region_geometry', 'dev.zone_sign', 'dev.governs', 'st.travel_region'], derived []
    d8: atoms ['dev.speed_limit_beacon', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    d10: atoms ['dev.speed_limit_beacon'], derived []
    d12: atoms ['dev.speed_limit_beacon', 'dev.governs', 'st.travel_region'], derived []
    d13: atoms ['dev.zone_sign', 'prim.conditions_hold'], derived []

  How each span is written:
    d1  `ru_aggregate x "DEF-NRS-484A-320::vehicle"`, the binder's class.
    d2  the act: `drv_motion_u_turn x (p.u_turn_window, p.u_turn_reversal_tolerance)`, judged once,
        at its recognition (`rises`). The concept reads `prim_heading_change` over the window.
    occasion (boundary window) the act's observations are those within p.u_turn_window behind
        the recognition at which x yaws (`drv_motion_yawing x p.yaw_rate_resolution`, kin.yaw_rate):
        a span read `some_moment` is `¬ holdsFor W x ¬(U ∧ φ)`, one read `throughout` is
        `holdsFor W x (U → φ)`.
    d3  (some_moment) a device of kind zone_sign z, of kind school or school_crossing and not an
        end sign, governing a travel region r that x occupies. The zone's selection is written
        again, whole, in the obligation (z is not in scope there otherwise); where several signs
        qualify the duty is required for each selected one (`forallDevice … implies`), the
        record stating the duty of "the" zone x turned in.
    d5  (a) no road user c of class ru_child within p.child_presence_reach
        (`st_region_geometry_distance c q`) of a travel region q that z governs.
    d6  (b) `asm.school_not_in_session_day`.   d7 (c) `asm.outside_school_operation_margin`.
    d8–d10 (d) a speed_limit_beacon b governing a travel region g that x occupies or z governs,
        not flashing (`dev_speed_limit_beacon_flashing`), and `asm.pupils_in_class`.
    d12–d13 (e) no speed_limit_beacon governs a travel region x occupies or z governs, and
        `prim_conditions_hold z x` is false.
    Each of (a)–(e) is read `throughout`, alternative by alternative: one of them must cover
    every observation of the act. d14 is the node's residue. No narrowing of this file's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_363_3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pChildPresenceReach : Term := .param "p.child_presence_reach"
def pUTurnReversalTolerance : Term := .param "p.u_turn_reversal_tolerance"
def pUTurnWindow : Term := .param "p.u_turn_window"
def pYawRateResolution : Term := .param "p.yaw_rate_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables: the zone sign, its region, the child's region, the beacon, its region,
    the child. -/
def vZ : Arg := .var "z"
def vR : Arg := .var "r"
def vQ : Arg := .var "q"
def vB : Arg := .var "b"
def vG : Arg := .var "g"
def vC : Arg := .var "c"

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- d2: x's U-turn (DEF-NRS-484B-077), recognized where it rises. -/
def uTurn : Formula := .derived "drv_motion_u_turn" [vX] [pUTurnWindow, pUTurnReversalTolerance]
def recognized : Formula := .rises uTurn

/-- The occasion's `under_way`: an observation of the act is one at which x yaws. -/
def underWay : Formula := .derived "drv_motion_yawing" [vX] [pYawRateResolution]

/-- φ at some observation of the act (with the act under way there). -/
def someMoment (φ : Formula) : Formula :=
  .not (.holdsFor .time pUTurnWindow "x" (.not (.and underWay φ)))

/-- φ at every observation of the act. -/
def throughout (φ : Formula) : Formula :=
  .holdsFor .time pUTurnWindow "x" (.implies underWay φ)

/-- d3: z begins a school or school crossing zone. -/
def schoolZoneSign : Formula :=
  .and (.or (.atom "dev_zone_sign_kind" [vZ, .lit "school"] [])
            (.atom "dev_zone_sign_kind" [vZ, .lit "school_crossing"] []))
       (.not (.atom "dev_zone_sign_end" [vZ] []))

/-- d3: x's footprint overlaps a travel region z governs. -/
def inZone : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "dev_governs" [vZ, vR] []) (.atom "rel_occupies" [vX, vR] []))

/-- d3 (some_moment): z is the sign of the zone x was in during the act. -/
def zoneOfAct : Formula := .and schoolZoneSign (someMoment inZone)

/-- d5: a child within the presence reach of a travel region z governs. -/
def childPresent : Formula :=
  .existsUser "c"
    (.and (.atom "ru_child" [vC] [])
          (.existsRegion (.lit "travel_region") "q"
            (.and (.atom "dev_governs" [vZ, vQ] [])
                  (.cmp (.measure "st_region_geometry_distance" [vC, vQ]) .le pChildPresenceReach))))

/-- d8, d12: beacon b governs a travel region x occupies or z governs. -/
def beaconOfZone : Formula :=
  .existsRegion (.lit "travel_region") "g"
    (.and (.atom "dev_governs" [vB, vG] [])
          (.or (.atom "rel_occupies" [vX, vG] []) (.atom "dev_governs" [vZ, vG] [])))

/-- (a) d5: no children present. -/
def excA : Formula := .not childPresent
/-- (b) d6. -/
def excB : Formula := .asm "asm.school_not_in_session_day"
/-- (c) d7. -/
def excC : Formula := .asm "asm.outside_school_operation_margin"
/-- (d) d8–d10: a beacon designates the zone, pupils are in class, and it is not flashing. -/
def excD : Formula :=
  .and (.existsDevice (.lit "speed_limit_beacon") "b"
          (.and beaconOfZone (.not (.atom "dev_speed_limit_beacon_flashing" [vB] []))))
       (.asm "asm.pupils_in_class")
/-- (e) d12–d13: no beacon designates the zone, and z's sign indicates its limit is not in effect. -/
def excE : Formula :=
  .and (.not (.existsDevice (.lit "speed_limit_beacon") "b" beaconOfZone))
       (.not (.derived "prim_conditions_hold" [vZ, vX] []))

/-- Applicability: d2 recognized, d3 at some observation of the act. -/
def applicability : Formula :=
  .and recognized (.existsDevice (.lit "zone_sign") "z" zoneOfAct)

/-- Obligation: d2 (obligation): shall not make a U-turn — unless, for each zone sign selected as
    in the applicability, one of the exceptions (a)–(e) covers every observation of the act. -/
def obligation : Formula :=
  .forallDevice (.lit "zone_sign") "z"
    (.implies zoneOfAct
      (.or (throughout excA)
        (.or (throughout excB)
          (.or (throughout excC)
            (.or (throughout excD) (throughout excE))))))

def rule : Rule :=
  { id := "NRS_484B_363_3"
    laws := ["NRS-484B-363-3"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.school_not_in_session_day", "asm.outside_school_operation_margin", "asm.pupils_in_class"]
    intentions := []
    operationalizations := []
    residues := ["The section's own definition of a speed limit beacon; dev.speed_limit_beacon's contract (\"a pair or more of yellow lamps mounted with a speed sign, flashing alternately when the sign's limit is in effect\") already states it, and the elements of spans d8, d10 and d12 read that atom; it imposes no duty of its own."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_363_3
