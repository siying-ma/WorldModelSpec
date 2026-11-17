/-
  NRS_484B_223_1b — NRS-484B-223-1b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): If a highway has two or more clearly marked lanes for traffic traveling in one direction,
    s2 (subject): vehicles must:
    s3 (obligation): Not be moved from that lane until the driver has given the appropriate turn signal
    s5 (standard): and ascertained that such movement can be made with safety.

  Elements (span → atoms, derived):
    s1: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['rel.occupies', 'st.lane', 'sig.turn_indicator', 'sig.hand_signal'], derived ['drv.lane.entering_adjacent_lane']

  Literals the text states (each written through its Units constructor):
    s1: 2 count — two

  How each span is written:
    s2: the binder class `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
    s1: a lane l1 (region quantifier of kind `lane`, the st.lane claim) that the subject occupies
        (`rel_occupies`), whose direction has at least the literal two lanes
        (`st_lane_adjacency(l1, count) ≥ 2`); the lanes are for traffic, written as the subject
        being of the admitted aggregate DEF-NRS-484A-285::traffic (`ru_aggregate`).
    s3 (trigger part): the move from that lane is `drv_lane_entering_adjacent_lane(subject, l1, l2, s)`
        for a lane l2 the subject comes to occupy, with s left or right; each side is its own
        disjunct, since the appropriate signal depends on it.
    s3 (duty): the signal of side s is `sig_turn_indicator(subject, s) ∨ sig_hand_signal(subject, s)`;
        "at the move and at the observation before it" (the record's narrowing) is that signal
        here and `¬ rises` of it — with the signal true here, not rising means it was true at the
        previous observation.
    s5: at the observation of the move, every other road user (`forallUser`, the subject excluded
        by `same`) is not in contact with the subject (`rel_contact`) and does not have a closest
        approach within p.conflict_horizon (`prim_closest_approach_within`) at a centre distance
        below p.conflict_centre_clearance (`prim_closest_approach_distance`).
    The obligation restates the applicability's whole selection of l1, l2 and the side, and
    requires the duty for every such selection (the record's "the lane l1 … the neighbouring lane
    l2").

  Choices the record left open: none beyond the record's own narrowings.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_1b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables: the lane left, the lane entered, another road user. -/
def vL1 : Arg := .var "l1"
def vL2 : Arg := .var "l2"
def vOther : Arg := .var "other"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"

def zeroMetres : Term := .lit Q.zero .metre

/-- s1's literal: two lanes. -/
def twoLanes : Term := .lit (Units.ratio 2 1) .count

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the lanes serve traffic, of which the subject is a member. -/
def subjectIsTraffic : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] []

/-- s1: lane l1 has at least two lanes in its direction. -/
def multiLane : Formula :=
  .cmp (.measure "st_lane_adjacency" [vL1, .lit "count"]) .ge twoLanes

/-- s1 + s3: the subject, occupying l1 of a multi-lane direction, begins to move into l2, l1's
    neighbour of the same direction on side `side`. -/
def movesInto (side : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, vL1] [])
    (.and multiLane
      (.and (.atom "rel_occupies" [vSubject, vL2] [])
        (.derived "drv_lane_entering_adjacent_lane" [vSubject, vL1, vL2, .lit side] [])))

/-- s3: the signal of side `side`, by indicator or by arm. -/
def signals (side : String) : Formula :=
  .or (.atom "sig_turn_indicator" [vSubject, .lit side] [])
      (.atom "sig_hand_signal" [vSubject, .lit side] [])

/-- s3: the signal shown here and at the observation before (here and not newly risen). -/
def signalledBefore (side : String) : Formula :=
  .and (signals side) (.not (.rises (signals side)))

/-- Applicability: s1 (condition): If a highway has two or more clearly marked lanes for traffic traveling in one direction, -/
def applicability : Formula :=
  .and subjectIsTraffic
    (.existsRegion (.lit "lane") "l1"
      (.existsRegion (.lit "lane") "l2"
        (.or (movesInto "left") (movesInto "right"))))

/-- s3: for every lane change selected, the signal of its side. -/
def signalDuty : Formula :=
  .forallRegion (.lit "lane") "l1"
    (.forallRegion (.lit "lane") "l2"
      (.and (.implies (movesInto "left") (signalledBefore "left"))
            (.implies (movesInto "right") (signalledBefore "right"))))

/-- s5: no other road user in contact with the subject or in a conflict with it. -/
def noConflict : Formula :=
  .forallUser "other"
    (.or (.same vSubject vOther)
      (.and (.not (.atom "rel_contact" [vSubject, vOther] []))
            (.not (.and (.derived "prim_closest_approach_within" [vSubject, vOther] [pConflictHorizon])
                        (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pConflictHorizon])
                              .lt pConflictCentreClearance)))))

/-- Obligation: s3 (obligation): Not be moved from that lane until the driver has given the appropriate turn signal; s5 (standard): and ascertained that such movement can be made with safety. -/
def obligation : Formula := .and signalDuty noConflict

def rule : Rule :=
  { id := "NRS_484B_223_1b"
    laws := ["NRS-484B-223-1b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "such movement can be made with safety"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: at the observation the move begins, no other road user is in contact with the subject and none approaches the subject's centre, under constant velocities, within the conflict horizon to a centre distance below the conflict clearance"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_1b
