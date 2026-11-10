/-
  NRS_484B_363_3 — NRS-484B-363-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    u1 (subject): The driver of a vehicle
    u2 (obligation): shall not make a U-turn
    u3 (condition): in an area designated as a school zone or school crossing zone
    u4 (boilerplate): except:
    u5 (exception): (a) When there are no children present;
    u6 (exception): (b) On a day on which school is not in session;
    u7 (exception): (c) During the period from a half hour after school is no longer in operation to a half hour before school is next in operation;
    u8 (exception): (d) If the zone is designated by an operational speed limit beacon,
    u9 (exception): during the hours when the pupils of the school are in class
    u10 (exception): and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that the speed limit is in effect;
    u11 (exception): or (e) If the zone is not designated by an operational speed limit beacon,
    u12 (exception): during the times when the sign designating the school zone or school crossing zone indicates that the speed limit is not in effect.
    u13 (definitional): As used in this section, “speed limit beacon” means a device which is used in conjunction with a sign and equipped with two or more yellow lights that flash alternately to indicate when the speed limit in a school zone or school crossing zone is in effect.

  Elements (span → atoms, derived):
    u1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    u2: atoms [], derived ['drv.motion.u_turn']
    u3: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    u5: atoms ['ru.child', 'rel.occupies', 'st.highway', 'st.on_way'], derived []
    u8: atoms ['dev.speed_limit_beacon', 'dev.governs', 'dev.inoperative', 'rel.occupies', 'st.travel_region'], derived []
    u10: atoms ['dev.speed_limit_beacon'], derived []
    u11: atoms ['dev.speed_limit_beacon', 'dev.governs', 'dev.inoperative', 'rel.occupies', 'st.travel_region'], derived []
    u12: atoms ['dev.zone_sign', 'prim.conditions_hold', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    u13: atoms ['dev.speed_limit_beacon'], derived []

  How each element is written:
    u1: the binder class, `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    u2: the act, `rises (drv_motion_u_turn x window min max)`: the rule judges the U-turn once, at the
        observation it is recognized. The occasion (boundary "window") is the recognition window
        behind it; an observation is under way where `drv_motion_turning x tol` holds (U).
    u3 (some_moment): `not (holdsFor W x (not (U and Z)))`, Z = some zone sign z of kind school or
        school_crossing governs a travel region x occupies.
    Exceptions, each read throughout as `holdsFor W x (U implies E)`, one disjunct per exception, so
    the same exception holds at every observation of the U-turn:
    u5 (a): for every school / school-crossing zone sign z governing a travel region r x occupies,
        every highway h that r lies on (st_on_way r h) is occupied by no road user of class child.
    u6 (b), u7 (c): the declared assumptions.
    u8–u10 (d): some speed limit beacon b, not inoperative, governs a travel region x occupies,
        b is not flashing, and asm.pupils_in_class.
    u11–u12 (e): no beacon that is not inoperative governs a travel region x occupies, and for every
        school / school-crossing zone sign z governing a travel region x occupies, prim_conditions_hold
        z x is false.
    The zone sign z of (a) and (e) is the applicability's selection written again (rule 3c); the
    record names "the" zone sign, and every such sign the U-turn is in is held to the exception.
    u13: what dev.speed_limit_beacon denotes; no formula of its own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_363_3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pReversalMaxAngle : Term := .param "p.reversal_max_angle"
def pReversalMinAngle : Term := .param "p.reversal_min_angle"
def pTurnRecognitionWindow : Term := .param "p.turn_recognition_window"
def pYawRateTolerance : Term := .param "p.yaw_rate_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- u2: the U-turn (DEF-NRS-484B-077), recognized where it rises. -/
def uTurn : Formula :=
  .derived "drv_motion_u_turn" [vX] [pTurnRecognitionWindow, pReversalMinAngle, pReversalMaxAngle]

/-- The occasion's under-way element: x's heading is changing. -/
def underWay : Formula := .derived "drv_motion_turning" [vX] [pYawRateTolerance]

/-- A span read at some observation while the U-turn is under way. -/
def someMoment (φ : Formula) : Formula :=
  .not (.holdsFor .time pTurnRecognitionWindow "x" (.not (.and underWay φ)))

/-- A span read at every observation while the U-turn is under way. -/
def throughout (φ : Formula) : Formula :=
  .holdsFor .time pTurnRecognitionWindow "x" (.implies underWay φ)

/-- Zone sign `z` is of kind school or school_crossing. -/
def schoolKind (z : String) : Formula :=
  .or (.atom "dev_zone_sign_kind" [.var z, .lit "school"] [])
      (.atom "dev_zone_sign_kind" [.var z, .lit "school_crossing"] [])

/-- Device `d` governs travel region `r`, which x occupies. -/
def governsOccupied (d r : String) : Formula :=
  .and (.atom "dev_governs" [.var d, .var r] []) (.atom "rel_occupies" [vX, .var r] [])

/-- u3: some school / school-crossing zone sign governs a travel region x occupies. -/
def inSchoolZone : Formula :=
  .existsDevice (.lit "zone_sign") "z"
    (.and (schoolKind "z") (.existsRegion (.lit "travel_region") "r" (governsOccupied "z" "r")))

/-- u5 (a): no child occupies the highway that the zone's governed region x occupies lies on. -/
def noChildren : Formula :=
  .forallDevice (.lit "zone_sign") "z"
    (.implies (schoolKind "z")
      (.forallRegion (.lit "travel_region") "r"
        (.implies (governsOccupied "z" "r")
          (.forallRegion (.lit "highway") "h"
            (.implies (.atom "st_on_way" [.var "r", .var "h"] [])
              (.forallUser "c"
                (.implies (.atom "ru_child" [.var "c"] [])
                  (.not (.atom "rel_occupies" [.var "c", .var "h"] [])))))))))

/-- A beacon `b`, not inoperative, governs a travel region x occupies (u8, u11). -/
def operationalBeacon (b : String) : Formula :=
  .and (.not (.atom "dev_inoperative" [.var b] []))
    (.existsRegion (.lit "travel_region") "r" (governsOccupied b "r"))

/-- u8–u10 (d): an operational beacon governs, pupils are in class, its lights are not flashing. -/
def beaconDark : Formula :=
  .and
    (.existsDevice (.lit "speed_limit_beacon") "b"
      (.and (operationalBeacon "b") (.not (.atom "dev_speed_limit_beacon_flashing" [.var "b"] []))))
    (.asm "asm.pupils_in_class")

/-- u11–u12 (e): no operational beacon governs, and the zone sign's conditions do not hold. -/
def signNotInEffect : Formula :=
  .and
    (.not (.existsDevice (.lit "speed_limit_beacon") "b" (operationalBeacon "b")))
    (.forallDevice (.lit "zone_sign") "z"
      (.implies
        (.and (schoolKind "z") (.existsRegion (.lit "travel_region") "r" (governsOccupied "z" "r")))
        (.not (.derived "prim_conditions_hold" [.var "z", vX] []))))

/-- Applicability: u2 the U-turn, recognized here; u3 under way at some observation in a school zone
    or school crossing zone. -/
def applicability : Formula :=
  .and (.rises uTurn) (someMoment inSchoolZone)

/-- Obligation: u2 (obligation): shall not make a U-turn — except where one of (a)–(e) holds at
    every observation of the U-turn. -/
def obligation : Formula :=
  .or (throughout noChildren)
    (.or (throughout (.asm "asm.school_not_in_session"))
      (.or (throughout (.asm "asm.school_out_of_operation_period"))
        (.or (throughout beaconDark) (throughout signNotInEffect))))

def rule : Rule :=
  { id := "NRS_484B_363_3"
    laws := ["NRS-484B-363-3"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.school_not_in_session", "asm.school_out_of_operation_period", "asm.pupils_in_class"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_363_3
