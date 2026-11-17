/-
  NRS_484B_263_o2 — NRS-484B-263

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (subject): The driver of a vehicle
    a2 (trigger): about to enter or exit a controlled-access highway
    a3 (sibling): shall yield the right-of-way
    a4 (condition): to all vehicles approaching on the highway
    a5 (standard): whose proximity constitutes an immediate hazard
    a6 (obligation): and shall continue to yield the right-of-way to that traffic
    a7 (standard): until the driver may proceed with reasonable safety.

  Elements (span → atoms, derived):
    a1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    a2: atoms ['rel.occupies', 'st.controlled_access', 'kin.speed'], derived []
    a4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.controlled_access', 'rel.bearing', 'kin.speed'], derived []
    a6: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'kin.speed', 'rel.contact', 'kin.time'], derived []

  How each is written:
    a1: the subject's class is `ru_aggregate subject DEF-NRS-484A-320::vehicle`; the driver is read
        through the vehicle's controlled motion (the record's observable reading).
    a2: the entry or exit event on a controlled-access region c is
        `rises (occupies subject c) ∨ rises (¬ occupies subject c)` — the rise of the overlap, or
        the rise of its absence right after an overlap (an exit). The applicability is the subject
        moving (kin_speed > p.halt_speed_tolerance) and some controlled-access region c with
        `0 < sinceRise(event) ≤ p.merge_window`, as the record's applicability states.
    a4: the approaching vehicles: every road user v other than the subject, of the vehicle
        aggregate, moving (kin_speed > p.halt_speed_tolerance), occupying the same c, and with the
        subject ahead in v's frame (longitudinal component of rel_bearing v subject > 0).
    a6: 'that traffic' adds the traffic aggregate on v; the continuing yield is no contact
        (rel_contact) at each judged observation; 'continue' is placed on the clock (kin.time) by
        the time since the entry/exit event (Term.sinceRise reads the observation instants).
    a5/a7: traffic-conflict bound: not (closest approach within p.conflict_horizon and centre
        distance at it below p.conflict_centre_clearance).
    The obligation re-binds c with the applicability's whole selection (controlled-access kind,
    the event timing window) for every such c (rule 3c).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_263_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pMergeWindow : Term := .param "p.merge_window"

def zeroMetres : Term := .lit Q.zero .metre

def zeroSeconds : Term := .lit Q.zero .second

def vC : Arg := .var "c"
def vV : Arg := .var "v"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- a2: the subject moves. -/
def subjectMoving : Formula := .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- a2: the subject's footprint overlaps region c. -/
def subjectOnC : Formula := .atom "rel_occupies" [vSubject, vC] []

/-- a2: the entry into c (rise of the overlap) or the exit from it (rise of its absence after an
    overlap). -/
def entryOrExit : Formula := .or (.rises subjectOnC) (.rises (.not subjectOnC))

/-- a2/a6/a7: the latest entry or exit lies strictly before this observation and no more than
    p.merge_window before it. -/
def withinMerge : Formula :=
  .and (.cmp (.sinceRise entryOrExit) .gt zeroSeconds)
       (.cmp (.sinceRise entryOrExit) .le pMergeWindow)

/-- Applicability: a2 (trigger): about to enter or exit a controlled-access highway; a4 (condition): to all vehicles approaching on the highway -/
def applicability : Formula :=
  .and subjectMoving (.existsRegion (.lit "controlled_access") "c" withinMerge)

/-- a4 + a6: v is of that traffic: another road user of the traffic and vehicle aggregates, moving,
    on the same c, with the subject ahead in v's frame. -/
def approaching : Formula :=
  .and (.not (.same vV vSubject))
    (.and (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] [])
        (.and (.cmp (.measure "kin_speed" [vV]) .gt pHaltSpeedTolerance)
          (.and (.atom "rel_occupies" [vV, vC] [])
            (.atom "rel_bearing" [vV, vSubject, .lit "ahead"] [])))))

/-- a5/a7: the traffic-conflict bound. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vV] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vV] [pConflictHorizon]) .lt
          pConflictCentreClearance)

/-- a6: yielding to v: no contact and no traffic conflict. -/
def yields : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vV] [])) (.not conflict)

/-- Obligation: a5 (standard): whose proximity constitutes an immediate hazard; a6 (obligation): and shall continue to yield the right-of-way to that traffic; a7 (standard): until the driver may proceed with reasonable safety. -/
def obligation : Formula :=
  .forallRegion (.lit "controlled_access") "c"
    (.implies withinMerge (.forallUser "v" (.implies approaching yields)))

def rule : Rule :=
  { id := "NRS_484B_263_o2"
    laws := ["NRS-484B-263"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "proximity that constitutes an immediate hazard (the traffic the continuing yield concerns)"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: closest approach of the two centres under constant velocities within the time-to-collision threshold at a centre distance below the collision clearance"
          surrogate := false }
      , { standard := "until the driver may proceed with reasonable safety"
          concepts := ["kin.time", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.merge_window"]
          convention := "the subject may proceed with reasonable safety once no approaching vehicle of that traffic is in a traffic-conflict (closest approach within the time-to-collision threshold below the collision clearance); the continuing duty is read over the merge or diverge that follows the entry or exit, whose duration is the time an acceleration or deceleration lane is run"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o2
