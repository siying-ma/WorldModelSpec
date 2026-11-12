/-
  NRS_484B_113_3 — NRS-484B-113-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle:
    s2 (obligation): Shall in every case yield
    s3 (standard): the right-of-way
    s4 (condition): to moving traffic and pedestrians.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms [], derived ['drv.motion.backing']
    s4: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived ['drv.motion.at_rest']

  How each is written:
    s1: ego's class is `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`; the driver is read through
        ego's motion (the record's agency reading).
    s2: the applicability is `drv_motion_backing ego` with p.rest_speed_tolerance as its motion
        tolerance (the record's reading on s2); "yield" is the obligation's universal: at every
        backing observation no road user ego must yield to is in conflict with it.
    s3: conflict = `prim_closest_approach_within ego u` (horizon p.conflict_horizon) and
        `prim_closest_approach_distance ego u` (same horizon) < p.conflict_clearance.
    s4: u ranges over every road user other than ego (`same` excludes ego) that is
        (traffic aggregate and not `drv_motion_at_rest u`, p.rest_speed_tolerance) or a member of
        the pedestrian aggregate, at rest or not. u is anchored to ego through the two primitives,
        which read both.
  No choice beyond the record was needed; no narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_113_3

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The road user quantified in the obligation (s4). -/
def vU : Arg := .var "u"

/-- Class of `ego` (s1): ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability (s2, reading on the record): ego is backing (drv.motion.backing), "in every case"
    being every observation at which it backs. -/
def applicability : Formula := .derived "drv_motion_backing" [vEgo] [pRestSpeedTolerance]

/-- s4: `u` is moving traffic (traffic aggregate, not at rest) or a pedestrian, at rest or not. -/
def yieldedTo : Formula :=
  .or
    (.and (.atom "ru_aggregate" [vU, .lit "DEF-NRS-484A-285::traffic"] [])
          (.not (.derived "drv_motion_at_rest" [vU] [pRestSpeedTolerance])))
    (.atom "ru_aggregate" [vU, .lit "DEF-NRS-484A-165::pedestrian"] [])

/-- s3: ego and `u` in conflict — projected at constant velocities their centres approach within
    the horizon, to a closest-approach centre distance below the clearance. -/
def inConflict : Formula :=
  .and
    (.derived "prim_closest_approach_within" [vEgo, vU] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vEgo, vU] [pConflictHorizon]) .lt
      pConflictClearance)

/-- Obligation (s2, s3, s4): no road user other than ego that ego must yield to is in conflict
    with it while it backs. -/
def obligation : Formula :=
  .forallUser "u"
    (.implies (.and (.not (.same vU vEgo)) yieldedTo) (.not inConflict))

def rule : Rule :=
  { id := "NRS_484B_113_3"
    laws := ["NRS-484B-113-3"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: DEF-NRS-484A-210 \"approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other\""
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_clearance"]
          convention := "Traffic-conflict technique: two road users are in conflict where, projected at their current velocities, their centres approach within the time-to-collision horizon and their closest-approach centre distance is below the clearance at which their bodies would touch. Direction, speed and proximity, the factors the definition names, enter by degree through the projected velocities and positions."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_113_3
