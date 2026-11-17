/-
  NRS_484B_603_1_o2 — NRS-484B-603-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (sibling): The fact that the speed of a vehicle is lower than the prescribed limits
    s2 (sibling): does not relieve
    s3 (subject): a driver
    s4 (sibling): from the duty to decrease speed
    s5 (sibling): when approaching and crossing an intersection,
    s6 (sibling): when approaching and going around a curve,
    s7 (sibling): when approaching a hill crest,
    s8 (sibling): when traveling upon any narrow or winding highway,
    s9 (sibling): or when special hazards exist or may exist
    s10 (sibling): with respect to pedestrians or other traffic,
    s11 (sibling): or by reason of weather
    s12 (sibling): or other highway conditions,
    s13 (obligation): and speed must be decreased
    s14 (standard): as may be necessary to avoid colliding
    s15 (condition): with any person, vehicle or other conveyance
    s16 (condition): on or entering a highway
    s17 (standard): in compliance with legal requirements and the duty of all persons to use due care.

  Elements (span → atoms, derived):
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s13: atoms ['kin.speed', 'kin.accel_longitudinal'], derived []
    s15: atoms ['rel.contact', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s16: atoms ['rel.occupies', 'st.highway'], derived []

  How each is written:
    s3  — binder class and applicability: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
          The record's applicability is the subject's class alone; s15/s16 are read inside the
          obligation's universal quantifier, so a scene with no such road user complies.
    s15 — `forallUser u`, excluding the subject by `same`, over every road user whatever its class
          (the record: the aggregate restricts nothing for the parties). Colliding is `rel_contact
          subject u`; the ru.aggregate claim of s15 is carried by the subject's class.
    s16 — `existsRegion highway r, rel_occupies u r` (st.highway as the quantifier's kind; the whole
          highway, sidewalks and shoulders included, as the record states).
    s13/s14 — a predicted conflict (`prim_closest_approach_within subject u` within
          p.conflict_horizon and `prim_closest_approach_distance` ≤ p.conflict_centre_clearance)
          requires: at rest (kin.speed ≤ p.halt_speed_tolerance), or kin.accel_longitudinal ≤
          −p.speed_decrease_decel_min, or the s17 bound; contact with u while kin.speed >
          p.halt_speed_tolerance violates.
    s17 — D = v·p.driver_reaction_time + v²/(2a) ≤ rel_surface_gap (its distance, no component),
          a chosen by `Term.cond`: ice/snow → p.following_decel_ice, else wet road or precipitation
          → p.following_decel_wet, else p.following_decel_dry. Written multiplied through by 2a
          (a > 0 for every reading value), because a divisor may not read an atom:
          v² ≤ 2·(gap − v·t_r)·a, an equivalent form, not a narrowing.
  Choices the record left open: none beyond the equivalent product form above; no narrowing.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_603_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pDriverReactionTime : Term := .param "p.driver_reaction_time"
def pFollowingDecelDry : Term := .param "p.following_decel_dry"
def pFollowingDecelIce : Term := .param "p.following_decel_ice"
def pFollowingDecelWet : Term := .param "p.following_decel_wet"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pSpeedDecreaseDecelMin : Term := .param "p.speed_decrease_decel_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- The other road user the duty is owed to (s15), a quantifier variable of the obligation. -/
def vOther : Arg := .var "u"

/-- s3: the subject is a vehicle — membership of the admitted aggregate DEF-NRS-484A-320::vehicle. -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The record's applicability: the subject is a vehicle. The parties of s15/s16 are read inside the
    obligation's quantifier, so that with no such road user the subject complies (record). -/
def applicability : Formula := clsSubject

/-- s13: the subject's speed (kin.speed). -/
def speed : Term := .measure "kin_speed" [vSubject]

/-- s14: the subject at rest — speed at or below p.halt_speed_tolerance. -/
def atRest : Formula := .cmp speed .le pHaltSpeedTolerance

/-- s14: the subject moving — speed above p.halt_speed_tolerance. -/
def moving : Formula := .cmp speed .gt pHaltSpeedTolerance

/-- s13/s14: speed being decreased — longitudinal acceleration at or below minus p.speed_decrease_decel_min. -/
def decreasing : Formula :=
  .cmp (.measure "kin_accel_longitudinal" [vSubject]) .le (.neg pSpeedDecreaseDecelMin)

/-- s16: road user `u` on or entering a highway — its footprint overlaps a highway region. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "r" (.atom "rel_occupies" [vOther, .var "r"] [])

/-- s14: a collision to be avoided with `u` — the centres approach within p.conflict_horizon under
    constant velocities, to a centre distance at or below p.conflict_centre_clearance. -/
def inConflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vOther] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pConflictHorizon])
             .le pConflictCentreClearance)

/-- s17: the surface deceleration — ice or snow, else wet road or precipitation, else dry. -/
def surfaceDecel : Term :=
  .cond (.atom "env_ice_or_snow" [] []) pFollowingDecelIce
    (.cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
      pFollowingDecelWet pFollowingDecelDry)

/-- s17: the surface gap to `u` less the reaction distance, gap − v·t_r. -/
def gapBeyondReaction : Term :=
  .sub (.measure "rel_surface_gap" [vSubject, vOther]) (.mul speed pDriverReactionTime)

/-- s17: the stopping distance D = v·t_r + v²/(2a) at or below the surface gap to `u`, written
    multiplied through by 2a (a > 0), since a divisor may not read an atom:
    v² ≤ (gap − v·t_r)·2a, the deceleration selected once. -/
def dueCare : Formula :=
  .cmp (.mul speed speed) .le
       (.mul (.add gapBeyondReaction gapBeyondReaction) surfaceDecel)

/-- s14/s15: no collision with `u` while the subject moves. -/
def noCollision : Formula :=
  .not (.and (.atom "rel_contact" [vSubject, vOther] []) moving)

/-- s13–s17: for every road user other than the subject on or entering a highway, where a
    collision with it is predicted the subject is at rest, decreasing speed, or within its
    stopping distance of the gap; and it is not in contact with it while moving. -/
def obligation : Formula :=
  .forallUser "u"
    (.implies (.and (.not (.same vOther vSubject)) onHighway)
      (.and (.implies inConflict (.or atRest (.or decreasing dueCare)))
            noCollision))

def rule : Rule :=
  { id := "NRS_484B_603_1_o2"
    laws := ["NRS-484B-603-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "speed decreased as may be necessary to avoid colliding"
          concepts := ["kin.accel_longitudinal", "kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.speed_decrease_decel_min", "p.halt_speed_tolerance"]
          convention := "Traffic-conflict technique: a collision is to be avoided with a road user whose centre comes within p.conflict_centre_clearance of the subject's within p.conflict_horizon under constant velocities; the speed is being decreased where the longitudinal acceleration is at or below minus p.speed_decrease_decel_min, the source's acceleration resolution, or the subject is at rest (speed at or below p.halt_speed_tolerance); contact while the subject moves is a collision not avoided."
          surrogate := true }
      , { standard := "in compliance with legal requirements and the duty of all persons to use due care"
          concepts := ["env.ice_or_snow", "env.precipitation", "env.wet_road", "kin.speed", "rel.surface_gap"]
          params := ["p.driver_reaction_time", "p.following_decel_dry", "p.following_decel_wet", "p.following_decel_ice"]
          convention := "AASHTO stopping-distance model: due care is met toward a road user in predicted conflict where the subject's stopping distance D = v times p.driver_reaction_time plus v squared over twice the surface deceleration (p.following_decel_ice on ice or snow, else p.following_decel_wet on a wet road or in precipitation, else p.following_decel_dry) is at or below the surface gap between the bodies; the bound moves with speed, surface and gap."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_603_1_o2
