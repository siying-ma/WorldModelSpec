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
    s2: atoms ['rel.contact'], derived ['drv.motion.moving_backward']
    s4: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-165::pedestrian', 'rel.occupies', 'st.highway'], derived ['drv.motion.complete_halt']

  How each span is written:
    s1: the binder class `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`; the record's agency
        narrowing ('driver' read through the vehicle's motion) is the plan's and is not restated.
    s2: "in every case" — the applicability is the record's backing case,
        `drv_motion_moving_backward(subject)` with speed_tol = p.halt_speed_tolerance (the record's
        own s2 narrowing). "yield" — for every road user `other` in the scope of s4, the subject is
        not in contact with it (`rel_contact`) and not in a danger of a crash with it (s3).
    s3: the operationalization, as the record writes it: `prim_closest_approach_within(subject,
        other, p.conflict_horizon)` and `prim_closest_approach_distance(subject, other,
        p.conflict_horizon) < p.conflict_centre_clearance`.
    s4: the scope of the universal quantifier over road users `other`, not the subject (`same`):
        moving traffic — `ru_aggregate(other, DEF-NRS-484A-285::traffic)`, occupying some region of
        kind highway (`rel_occupies`, the quantifier kind `highway` carrying st.highway), and not
        `drv_motion_complete_halt(other)` with p.halt_speed_tolerance — or a pedestrian,
        `ru_aggregate(other, DEF-NRS-484A-165::pedestrian)`, moving or not.

  Choices the record left open: none; the obligation is written as the record states it. The
  highway `other` occupies is bound by an existential region quantifier over kind `highway`, tied
  to `other` by `rel_occupies` ('using any highway').

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_113_3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The road user yielded to (quantifier variable). -/
def vOther : Arg := .var "other"

/-- The highway the road user uses (quantifier variable). -/
def vHighway : Arg := .var "way"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: "in every case" of backing — the subject moves against its heading. -/
def backing : Formula :=
  .derived "drv_motion_moving_backward" [vSubject] [pHaltSpeedTolerance]

/-- Applicability: the subject is backing at the observation. -/
def applicability : Formula := backing

/-- s4: moving traffic — a member of the traffic aggregate, using a highway, not at rest. -/
def movingTraffic : Formula :=
  .and (.atom "ru_aggregate" [vOther, .lit "DEF-NRS-484A-285::traffic"] [])
    (.and (.existsRegion (.lit "highway") "way" (.atom "rel_occupies" [vOther, vHighway] []))
      (.not (.derived "drv_motion_complete_halt" [vOther] [pHaltSpeedTolerance])))

/-- s4: pedestrians, moving or not. -/
def pedestrian : Formula :=
  .atom "ru_aggregate" [vOther, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s4: the road users the subject yields to: any other road user that is moving traffic or a pedestrian. -/
def yieldedTo : Formula :=
  .and (.not (.same vSubject vOther)) (.or movingTraffic pedestrian)

/-- s3: the danger of a crash — the centres approach within the horizon to below the clearance. -/
def dangerOfCrash : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vOther] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pConflictHorizon])
      .lt pConflictCentreClearance)

/-- s2: to yield — no contact with, and no danger of a crash with, the road user. -/
def yields : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vOther] [])) (.not dangerOfCrash)

/-- Obligation: s2 (obligation): Shall in every case yield; s3 (standard): the right-of-way -/
def obligation : Formula :=
  .forallUser "other" (.implies yieldedTo yields)

def rule : Rule :=
  { id := "NRS_484B_113_3"
    laws := ["NRS-484B-113-3"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way (DEF-NRS-484A-210: circumstances of direction, speed and proximity giving rise to the danger of a crash unless one grants precedence)"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: direction, speed and proximity give rise to the danger of a crash where, under constant velocities, the two road users approach each other within the time-to-collision threshold p.conflict_horizon (prim.closest_approach_within) to a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance)"
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_113_3
