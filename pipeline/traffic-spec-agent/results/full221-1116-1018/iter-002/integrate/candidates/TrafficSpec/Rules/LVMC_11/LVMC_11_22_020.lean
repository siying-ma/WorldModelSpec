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
    s2 → binder class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s4 → applicability: some region of kind `highway` that the subject occupies (`rel_occupies`); the
         quantifier's kind is st.highway, written as named (no narrowing to the roadway).
    s5 → applicability: the declared assumption `asm.within_city_limits`.
    s1 → applicability: the plan's observable reading (a moving vehicle is taken to be driven):
         `kin_speed subject > p.halt_speed_tolerance`. Placed in the applicability, as the record's
         applicability states it.
    s3 → obligation (surrogate operationalization): no other road user `other` (any class; `same`
         excludes the subject itself) with `rel_contact subject other`, or with
         `prim_closest_approach_within subject other [p.conflict_horizon]` and
         `prim_closest_approach_distance subject other [p.conflict_horizon] < p.conflict_centre_clearance`.
    Choices left open: none beyond the record (no narrowing of this session's own).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_22_020

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

/-- The other road user of the standard (a quantifier variable of the obligation). -/
def vOther : Arg := .var "other"

/-- Class of `subject` (s2): membership of the admitted aggregate DEF-NRS-484A-320::vehicle, one atom,
    not expanded into its classes. -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s4: the subject's footprint occupies some region of kind `highway` (st.highway, the whole public
    way, refinements included). -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "hw" (.atom "rel_occupies" [vSubject, .var "hw"] [])

/-- s5: the declared assumption. -/
def inCity : Formula := .asm "asm.within_city_limits"

/-- s1 (observable reading of 'drive or operate'): the vehicle moves, its speed above the halt
    tolerance. -/
def moving : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- Applicability: s4 (condition): on any highway; s5 (condition): in the City; s1: the vehicle is
    driven (moving). -/
def applicability : Formula :=
  .and onHighway (.and inCity moving)

/-- s3, collision limb: the other road user's body touches the subject's. -/
def collides : Formula := .atom "rel_contact" [vSubject, vOther] []

/-- s3, critical-conflict limb: under constant velocities the centres approach within the horizon,
    to a closest-approach centre distance below the clearance. -/
def criticalConflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vOther] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pConflictHorizon])
      .lt pConflictCentreClearance)

/-- Obligation: s1 (obligation): It is unlawful for any person to drive or operate; s3 (standard): in
    a careless or imprudent manner — no other road user (any class) collides or is in a critical
    conflict with the subject. -/
def obligation : Formula :=
  .not (.existsUser "other"
    (.and (.not (.same vOther vSubject)) (.or collides criticalConflict)))

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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := true }

end TrafficSpec.Rules.LVMC_11_22_020
