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
    d2: atoms [], derived ['drv.motion.u_turn']
    d3: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    d5: atoms ['ru.child', 'st.region_geometry', 'dev.zone_sign', 'dev.governs', 'st.travel_region'], derived []
    d8: atoms ['dev.speed_limit_beacon', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    d10: atoms ['dev.speed_limit_beacon'], derived []
    d12: atoms ['dev.speed_limit_beacon', 'dev.governs', 'st.travel_region'], derived []
    d13: atoms ['dev.zone_sign', 'prim.conditions_hold'], derived []

  How each span is written:
    d1  the class of x: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    d2  the act: `drv_motion_u_turn x` (window p.u_turn_window, tolerance p.u_turn_reversal_tolerance),
        judged once at its recognition (`rises`). The occasion's under-way formula U is
        `drv_motion_yawing x` (p.yaw_rate_resolution): an observation of the act is one within
        p.u_turn_window behind the recognition at which x yaws.
    d3  some_moment: a zone sign z of kind school or school_crossing, not an end sign, governing a
        travel region r that x occupies at some observation of the act:
        `¬ holdsFor W x ¬(U ∧ ∃r. governs z r ∧ occupies x r)`. The obligation repeats this whole
        selection of z and requires, for every z so selected, one exception covering the whole act.
    d5  (a) throughout: no road user of class ru.child within p.child_presence_reach
        (`st_region_geometry_distance`) of a travel region z governs.
    d6  (b) throughout: asm.school_not_in_session_day.
    d7  (c) throughout: asm.outside_school_operation_margin.
    d8, d9, d10  (d) throughout: some speed limit beacon governs a travel region x occupies or z
        governs, asm.pupils_in_class holds, and that beacon is not flashing.
    d12, d13  (e) throughout: no speed limit beacon governs a travel region x occupies or z governs,
        and `prim_conditions_hold z x` is false.
    Each alternative is its own `holdsFor W x (U → …)`: one alternative covers the whole act, not
    a different one at each observation. No choice beyond the record's was made; no narrowing.

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

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- d2: x's U-turn (drv.motion.u_turn). -/
def uTurn : Formula := .derived "drv_motion_u_turn" [vX] [pUTurnWindow, pUTurnReversalTolerance]

/-- The occasion's under-way formula: x's heading is changing (drv.motion.yawing). -/
def underWay : Formula := .derived "drv_motion_yawing" [vX] [pYawRateResolution]

/-- φ at some observation of the act (some_moment). -/
def someMoment (φ : Formula) : Formula :=
  .not (.holdsFor .time pUTurnWindow "x" (.not (.and underWay φ)))

/-- φ at every observation of the act (throughout). -/
def throughout (φ : Formula) : Formula :=
  .holdsFor .time pUTurnWindow "x" (.implies underWay φ)

/-- d3: zone sign `z` is a school or school crossing zone sign that begins a zone. -/
def schoolZoneSign : Formula :=
  .and (.or (.atom "dev_zone_sign_kind" [.var "z", .lit "school"] [])
            (.atom "dev_zone_sign_kind" [.var "z", .lit "school_crossing"] []))
       (.not (.atom "dev_zone_sign_end" [.var "z"] []))

/-- d3: at the observation, x occupies a travel region `z` governs. -/
def inZone : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "dev_governs" [.var "z", .var "r"] []) (.atom "rel_occupies" [vX, .var "r"] []))

/-- d3, the whole selection of `z`: such a sign whose area x occupied at some observation of the act. -/
def selected : Formula := .and schoolZoneSign (someMoment inZone)

/-- d5 (a): no child within the presence reach of a travel region `z` governs. -/
def noChildren : Formula :=
  .not (.existsUser "c"
    (.and (.atom "ru_child" [.var "c"] [])
      (.existsRegion (.lit "travel_region") "rc"
        (.and (.atom "dev_governs" [.var "z", .var "rc"] [])
          (.cmp (.measure "st_region_geometry_distance" [.var "c", .var "rc"]) .le pChildPresenceReach)))))

/-- d8: beacon `b` governs a travel region x occupies or `z` governs. -/
def beaconDesignates : Formula :=
  .existsRegion (.lit "travel_region") "rb"
    (.and (.atom "dev_governs" [.var "b", .var "rb"] [])
      (.or (.atom "rel_occupies" [vX, .var "rb"] []) (.atom "dev_governs" [.var "z", .var "rb"] [])))

/-- d8–d10 (d): a beacon designates the zone, pupils are in class, and that beacon is not flashing. -/
def beaconDark : Formula :=
  .existsDevice (.lit "speed_limit_beacon") "b"
    (.and beaconDesignates
      (.and (.asm "asm.pupils_in_class")
        (.not (.atom "dev_speed_limit_beacon_flashing" [.var "b"] []))))

/-- d12–d13 (e): no beacon designates the zone, and z's posted conditions do not hold for x. -/
def signNotInEffect : Formula :=
  .and (.not (.existsDevice (.lit "speed_limit_beacon") "b" beaconDesignates))
       (.not (.derived "prim_conditions_hold" [.var "z", vX] []))

/-- Applicability: d3 (trigger): in an area designated as a school zone or school crossing zone; d5 (exception): (a) When there are no children present;; d6 (exception): (b) On a day on which school is not in session;; d7 (exception): (c) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;; d8 (exception): (d) If the zone is designated by an operational speed limit beacon,; d9 (exception): during the hours when the pupils of the school are in class; d10 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;; d12 (exception): (e) If the zone is not designated by an operational speed limit beacon,; d13 (exception): during the times when the sign designating the school zone or school crossing zone indicates that the speed limit is not in effect. -/
def applicability : Formula :=
  .and (.rises uTurn) (.existsDevice (.lit "zone_sign") "z" selected)

/-- Obligation: d2 (obligation): shall not make a U-turn -/
def obligation : Formula :=
  .forallDevice (.lit "zone_sign") "z"
    (.implies selected
      (.or (throughout noChildren)
        (.or (throughout (.asm "asm.school_not_in_session_day"))
          (.or (throughout (.asm "asm.outside_school_operation_margin"))
            (.or (throughout beaconDark) (throughout signNotInEffect))))))

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
