/-
  NRS_484B_263_o1 — NRS-484B-263

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (subject): The driver of a vehicle
    a2 (trigger): about to enter or exit a controlled-access highway
    a3 (obligation): shall yield the right-of-way
    a4 (condition): to all vehicles approaching on the highway
    a5 (standard): whose proximity constitutes an immediate hazard
    a6 (sibling): and shall continue to yield the right-of-way to that traffic
    a7 (sibling): until the driver may proceed with reasonable safety.

  Elements (span → atoms, derived):
    a1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    a2: atoms ['rel.occupies', 'st.controlled_access', 'kin.speed'], derived []
    a3: atoms ['kin.speed', 'rel.contact'], derived []
    a4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.controlled_access', 'rel.bearing', 'kin.speed'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_263_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    a1: the binder's class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    a2: the subject moves (`kin_speed subject > p.halt_speed_tolerance`) and, for some region c of
        kind `controlled_access`, the subject's occupancy of c rises (entry) or its non-occupancy of
        c rises (exit) at the judged observation (`enterOrExit`).
    a4: in the obligation, the region c is selected again by the same whole selection
        (`controlled_access` kind, entry or exit of the subject at this observation), for every such
        region; the vehicles approaching on it are every other road user v (`not (same subject v)`)
        of the vehicle aggregate, moving (`kin_speed v > p.halt_speed_tolerance`), whose footprint
        overlaps c (`rel_occupies v c`), with the subject ahead in v's frame
        (`rel_bearing v subject "ahead"`: positive longitudinal component).
    a3: yielding to such a v is no contact (`not rel_contact subject v`) and
    a5: no immediate-hazard proximity: not (`prim_closest_approach_within subject v` over
        p.conflict_horizon and `prim_closest_approach_distance subject v` below
        p.conflict_centre_clearance). The distance is read only where the approach falls within the
        horizon (it is undefined otherwise); the conjunction is false there.
    a6, a7: siblings, not carried by this node.
  No choice beyond the record's was made; no narrowing is declared.
-/

def vC : Arg := .var "c"
def vV : Arg := .var "v"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The subject moves: speed above the halt tolerance. -/
def subjectMoving : Formula := .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- a2: entry into (occupancy rises) or exit from (non-occupancy rises) region `c` at this observation. -/
def enterOrExit : Formula :=
  .or (.rises (.atom "rel_occupies" [vSubject, vC] []))
      (.rises (.not (.atom "rel_occupies" [vSubject, vC] [])))

/-- Applicability: a2 (trigger): about to enter or exit a controlled-access highway; a4 (condition): to all vehicles approaching on the highway -/
def applicability : Formula :=
  .and subjectMoving
    (.existsRegion (.lit "controlled_access") "c" enterOrExit)

/-- a4: v is another vehicle, moving, on region c, with the subject ahead of it. -/
def approachingOnC : Formula :=
  .and (.not (.same vSubject vV))
    (.and (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] [])
      (.and (.cmp (.measure "kin_speed" [vV]) .gt pHaltSpeedTolerance)
        (.and (.atom "rel_occupies" [vV, vC] [])
          (.atom "rel_bearing" [vV, vSubject, .lit "ahead"] []))))

/-- a5: the closest approach of the centres falls within the horizon at a centre distance below the clearance. -/
def immediateHazard : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vV] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vV] [pConflictHorizon]) .lt
      pConflictCentreClearance)

/-- a3: yielding — no contact and no immediate-hazard proximity. -/
def yields : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vV] [])) (.not immediateHazard)

/-- Obligation: a3 (obligation): shall yield the right-of-way; a5 (standard): whose proximity constitutes an immediate hazard -/
def obligation : Formula :=
  .forallRegion (.lit "controlled_access") "c"
    (.implies enterOrExit
      (.forallUser "v" (.implies approachingOnC yields)))

def rule : Rule :=
  { id := "NRS_484B_263_o1"
    laws := ["NRS-484B-263"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "proximity that constitutes an immediate hazard"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: under constant velocities the two centres reach their closest approach within the time-to-collision threshold at a centre distance below the collision clearance; a vehicle so placed is an immediate hazard"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o1
