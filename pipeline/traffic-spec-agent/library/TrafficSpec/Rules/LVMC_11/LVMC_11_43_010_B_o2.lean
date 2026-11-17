/-
  LVMC_11_43_010_B_o2 — LVMC-11-43-010-B

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (boilerplate): The following regulations pertain to
    b2 (subject): the operation of vehicles
    b3 (condition): within a roundabout
    b4 (subject): The operator of a vehicle
    b5 (trigger): entering a roundabout
    b6 (sibling): shall yield
    b7 (sibling): the right-of-way
    b8 (sibling): to vehicles already in the roundabout
    b9 (obligation): and wait
    b10 (standard): for a gap
    b11 (condition): in traffic
    b12 (trigger): before entering

  Elements (span → atoms, derived):
    b2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b3: atoms ['rel.occupies', 'st.roundabout'], derived []
    b4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b5: atoms ['rel.occupies', 'st.roundabout'], derived []
    b9: atoms ['rel.occupies', 'st.roundabout'], derived []
    b11: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.roundabout'], derived []
    b12: atoms ['rel.occupies', 'st.roundabout'], derived []

  How each is written:
    b2/b4: binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    b3/b5/b12: `existsRegion roundabout r (rises (rel_occupies subject r))` — the entry event;
      the obligation restates this whole selection of `r` and judges every roundabout so entered.
    b9/b10: the duty at that entry is that no road user of b11 lacks a gap: not
      (prim_closest_approach_within(subject,u;gap) ∧ prim_closest_approach_distance(subject,u;gap)
      < clearance). Where the centres do not approach within the horizon the conjunction is false
      by its first operand, so the undefined distance never decides.
    b11: `u` ranges over every road user, other than the subject (`same`), that is a member of
      DEF-NRS-484A-285::traffic and occupies `r` (rel_occupies u r).
    Not written: the record's obligation also names rel.contact, which no element or
      operationalization of the node claims; it is left out (see task_result.md).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_43_010_B_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pRoundaboutCriticalGap : Term := .param "p.roundabout_critical_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject` (b2, b4): ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- b3/b5/b12: the subject's footprint comes to overlap the roundabout region `r` here
    (rel.occupies true now, false at the observation before). -/
def entersRoundabout (r : String) : Formula :=
  .rises (.atom "rel_occupies" [vSubject, .var r] [])

/-- Applicability: b3 (condition): within a roundabout; b5 (trigger): entering a roundabout;
    b12 (trigger): before entering — the subject enters some st.roundabout region here. -/
def applicability : Formula :=
  .existsRegion (.lit "roundabout") "r" (entersRoundabout "r")

/-- b11: a road user `u` of the gap's traffic — other than the subject, a member of
    DEF-NRS-484A-285::traffic, occupying the roundabout `r` being entered. -/
def trafficInRoundabout (u r : String) : Formula :=
  .and (.not (.same (.var u) vSubject))
    (.and (.atom "ru_aggregate" [.var u, .lit "DEF-NRS-484A-285::traffic"] [])
          (.atom "rel_occupies" [.var u, .var r] []))

/-- b10 (standard, operationalized): no gap with `u` — under constant velocities the centres
    approach within the critical gap, and the centre distance at that closest approach is below
    the conflict clearance. -/
def noGapWith (u : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, .var u] [pRoundaboutCriticalGap])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var u] [pRoundaboutCriticalGap])
             .lt pConflictCentreClearance)

/-- Obligation: b9 (obligation): and wait; b10 (standard): for a gap; b11 (condition): in traffic.
    For every roundabout `r` the subject enters here (the applicability's whole selection,
    restated), every road user of the traffic in `r` leaves a gap. -/
def obligation : Formula :=
  .forallRegion (.lit "roundabout") "r"
    (.implies (entersRoundabout "r")
      (.forallUser "u" (.implies (trafficInRoundabout "u" "r") (.not (noGapWith "u")))))

def rule : Rule :=
  { id := "LVMC_11_43_010_B_o2"
    laws := ["LVMC-11-43-010-B"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "a gap in traffic sufficient to enter"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.roundabout_critical_gap", "p.conflict_centre_clearance"]
          convention := "gap-acceptance convention of roundabout entry capacity: an entering driver accepts a gap when no road user in the roundabout comes, under constant velocities, within the conflict clearance of it sooner than the critical headway"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_43_010_B_o2
