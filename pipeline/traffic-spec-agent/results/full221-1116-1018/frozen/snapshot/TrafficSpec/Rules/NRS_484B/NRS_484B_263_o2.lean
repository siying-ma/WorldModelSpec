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
    a1: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    a2: the subject moves (`kin_speed subject > p.halt_speed_tolerance`), and for some
        controlled-access region c (`existsRegion "controlled_access"`) the event "entry or exit" is
        the change of the subject's overlap with c: `rises (rel_occupies subject c)` (entry) or
        `rises (¬ rel_occupies subject c)` (exit: non-overlap that follows overlap). The latest such
        event lies strictly before the observation and at most p.merge_window before it:
        `0 < sinceRise(event) ≤ p.merge_window` (kin.time through `sinceRise`).
    a4/a6: in the obligation, every controlled-access region c with that same selection
        (`0 < sinceRise(event c) ≤ p.merge_window`, written again), and every other road user v
        (`¬ same v subject`) of both aggregates (traffic, vehicle), moving
        (`kin_speed v > p.halt_speed_tolerance`), whose footprint overlaps c, and in whose frame
        the subject lies ahead (`rel_bearing v subject "ahead"`, longitudinal component positive).
    a5/a7: the continuing yield to v: no contact (`rel_contact`), and no traffic conflict — not
        (`prim_closest_approach_within subject v p.conflict_horizon` and the centre distance at that
        approach `< p.conflict_centre_clearance`). The duty runs over the merge window that follows
        the entry or exit (the record's reading of a6).

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

def zeroSeconds : Term := .lit Q.zero .second

def vC : Arg := .var "c"
def vV : Arg := .var "v"

/-- A road user moves: its speed above the halt tolerance. -/
def moving (x : Arg) : Formula :=
  .cmp (.measure "kin_speed" [x]) .gt pHaltSpeedTolerance

/-- The subject's footprint overlaps the controlled-access region c. -/
def subjectOnC : Formula := .atom "rel_occupies" [vSubject, vC] []

/-- The entry into c (rise of overlap) or the exit from it (rise of non-overlap after overlap). -/
def entryOrExit : Formula := .or (.rises subjectOnC) (.rises (.not subjectOnC))

/-- The latest entry or exit lies strictly before this observation and within the merge window. -/
def recentEntryOrExit : Formula :=
  .and (.cmp (.sinceRise entryOrExit) .gt zeroSeconds)
       (.cmp (.sinceRise entryOrExit) .le pMergeWindow)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: a2 (trigger): about to enter or exit a controlled-access highway; a4 (condition): to all vehicles approaching on the highway -/
def applicability : Formula :=
  .and (moving vSubject)
       (.existsRegion (.lit "controlled_access") "c" recentEntryOrExit)

/-- v is of that traffic: another road user of both aggregates, moving, on c, with the subject ahead. -/
def thatTraffic : Formula :=
  .and (.not (.same vV vSubject))
    (.and (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] [])
        (.and (moving vV)
          (.and (.atom "rel_occupies" [vV, vC] [])
                (.atom "rel_bearing" [vV, vSubject, .lit "ahead"] [])))))

/-- Traffic conflict: closest approach within the horizon below the collision clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vV] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vV] [pConflictHorizon])
             .lt pConflictCentreClearance)

/-- Obligation: a5 (standard): whose proximity constitutes an immediate hazard; a6 (obligation): and shall continue to yield the right-of-way to that traffic; a7 (standard): until the driver may proceed with reasonable safety. -/
def obligation : Formula :=
  .forallRegion (.lit "controlled_access") "c"
    (.implies recentEntryOrExit
      (.forallUser "v"
        (.implies thatTraffic
          (.and (.not (.atom "rel_contact" [vSubject, vV] []))
                (.not conflict)))))

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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o2
