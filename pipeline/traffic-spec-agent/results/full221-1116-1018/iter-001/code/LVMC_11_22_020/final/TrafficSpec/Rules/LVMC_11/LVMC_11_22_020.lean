/-
  LVMC_11_22_020 — LVMC-11-22-020

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (obligation): It is unlawful for any person to drive or operate
    s2 (subject): a vehicle of any kind or character
    s3 (standard): in a careless or imprudent manner
    s4 (condition): on any highway
    s5 (condition): in the City

  Elements (span → atoms, derived):
    s1: atoms ['kin.speed'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['rel.occupies', 'st.highway'], derived []

  How each is written:
    s2: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`, the aggregate id as
        its literal argument, not expanded.
    s4: some region of kind `highway` (st.highway; the quantifier covers the kinds that refine it)
        that the subject's footprint occupies (rel.occupies anchors the region to the subject).
    s5: the declared assumption `asm.within_city_limits`.
    s1: the record's observable reading (the plan's narrowing, not restated): the subject is
        moving, kin.speed strictly above p.halt_speed_tolerance (at or below counts as no movement,
        per the parameter's convention). The record's applicability places it there.
    s3: the operationalization, for every road user u of the scene other than the subject
        (`same` excludes the subject; "another road user", any class): not rel.contact(subject, u),
        and not (prim.closest_approach_within(subject, u; p.conflict_horizon) and
        prim.closest_approach_distance(subject, u; p.conflict_horizon) < p.conflict_centre_clearance).
        The distance is undefined where the centres do not approach within the horizon; the
        conjunction with `within` decides it false there. "below" is read as strict `<`.
        u is anchored to the subject by rel.contact and the two primitives.

  No choice beyond the record's: no narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_22_020

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The other road user of the standard (a quantifier variable). -/
def vOther : Arg := .var "u"

/-- The highway region the subject occupies (a quantifier variable). -/
def vHighway : Arg := .var "h"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s4: the subject's footprint occupies some highway region. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vSubject, vHighway] [])

/-- s5: the place lies within the city's limits. -/
def inCity : Formula := .asm "asm.within_city_limits"

/-- s1 (observable reading): the subject is moving. -/
def moving : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- Applicability: s4 (condition): on any highway; s5 (condition): in the City; s1: moving. -/
def applicability : Formula :=
  .and onHighway (.and inCity moving)

/-- s3: a collision with u. -/
def collides : Formula := .atom "rel_contact" [vSubject, vOther] []

/-- s3: a critical conflict with u — the centres approach within the horizon to a closest-approach
    centre distance below the clearance. -/
def criticalConflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vOther] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pConflictHorizon])
      .lt pConflictCentreClearance)

/-- Obligation: s1 (obligation): It is unlawful for any person to drive or operate; s3 (standard): in a careless or imprudent manner -/
def obligation : Formula :=
  .forallUser "u"
    (.implies (.not (.same vSubject vOther))
      (.and (.not collides) (.not criticalConflict)))

def rule : Rule :=
  { id := "LVMC_11_22_020"
    laws := ["LVMC-11-22-020"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_city_limits"]
    intentions := []
    operationalizations :=
      [ { standard := "careless or imprudent manner"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: driving is read as careless or imprudent where, while the subject moves, it collides with another road user (rel.contact) or another road user's centre and the subject's, under constant velocities, approach within p.conflict_horizon to a centre distance below p.conflict_centre_clearance (a critical conflict). Care is a state of mind and the whole duty is this standard, so the rule is a surrogate."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.LVMC_11_22_020
