/-
  NRS_484B_223_1b — NRS-484B-223-1b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): If a highway has two or more clearly marked lanes for traffic traveling in one direction,
    s2 (subject): vehicles must:
    s3 (obligation): Not be moved from that lane
    s4 (condition): until the driver has given the appropriate turn signal
    s5 (standard): and ascertained that such movement can be made with safety.

  Elements (span → atoms, derived):
    s1: atoms ['st.highway', 'st.lane', 'st.lane_marking', 'st.lane_adjacency', 'st.lane_direction', 'st.on_way', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.lane', 'rel.occupies'], derived ['drv.lane.exits_region']
    s4: atoms ['sig.turn_indicator', 'sig.hand_signal', 'st.lane', 'prim.region_lateral_offset', 'rel.occupies'], derived ['drv.lane.enters_region']

  Literals the text states (each written through its Units constructor):
    s1: 2 count — two or more clearly marked lanes

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written
  ------------------------
  s2 (subject), the binder class: `ru_aggregate subject DEF-NRS-484A-320::vehicle`, the admitted
  aggregate under its id and never the classes it covers.

  s1 (trigger), `laneGroup` and `applicability`: a lane (`existsRegion "lane"`, the atom st.lane) the
  subject occupies (`rel_occupies`), lying on a highway (`existsRegion "highway"` — the atom
  st.highway — with `st_on_way` tying the lane to that way), whose adjacency records two or more lanes
  in that lane's direction (`st_lane_adjacency` read at its `count` field, against the text's literal
  2), the subject on it being traffic (`ru_aggregate … DEF-NRS-484A-285::traffic`). The lane's
  designated direction (st.lane_direction) is read where the trigger's "in one direction" does work on
  the movement: the lane entered must carry the same designated direction as the lane left, so the
  movement is one among the lanes the trigger counts (`entersLane`).

  s1's "clearly marked … on the side the vehicle leaves" (`leavesMarkedSide`) is written in the duty's
  antecedent, not in the applicability: which side the subject leaves is fixed only at the observation
  of the departure, and no formula of the applicability can name it. `applicability ∧ obligation` state
  the trigger whole; the split is declared as a narrowing on s3.

  s3 (obligation), `obligation`: at the observation at which the subject leaves the lane the trigger
  binds (`drv_lane_exits_region` on that lane, the lane selected again by the trigger's own relations
  — the occupancy of that observation is false by the event's own contract, and the occupancy before it
  is what the event reads), and across a side of it whose marking is of a type other than none
  (`st_lane_marking`, the side given by the sign of the lateral offset), the duty must hold for the
  lane entered (`drv_lane_enters_region`, `rel_occupies`, the same designated direction).

  s4 (condition), `signalGiven`: the appropriate turn signal is being shown at that observation —
  `sig_turn_indicator` or `sig_hand_signal` on the side of the departure, no window behind being
  required. The side is the sign of `prim_region_lateral_offset` of the lane left: negative where that
  lane now lies to the subject's right, so the subject moved to its left and the left signal is the
  appropriate one; positive the mirror case (narrowing on s3).

  s5 (standard), `movementSafe`: the operationalization's conflict prediction, for every other road
  user — either the centres do not approach within p.yield_conflict_horizon
  (`prim_closest_approach_within`) or the centre distance at that closest approach stays at or above
  p.yield_min_clearance (`prim_closest_approach_distance`) — with the body gap `rel_surface_gap` to a
  road user that occupies the lane entered required to be greater than zero (narrowing on s5).
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_1b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The quantified entities: the lane the subject occupies and leaves, the way it lies on, the lane
    it enters, and another road user. -/
def vLane : Arg := .var "lane"
def vWay : Arg := .var "way"
def vEntered : Arg := .var "entered"
def vOther : Arg := .var "other"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The text's "two or more … lanes". -/
def twoLanes : Term := .lit (Q.ofInt 2) .count

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the lane lies on a highway, its adjacency counts two or more lanes in its direction, and the
    subject on it is traffic. -/
def laneGroup (lane : Arg) : Formula :=
  .and (.existsRegion (.lit "highway") "way" (.atom "st_on_way" [lane, vWay] []))
    (.and (.cmp (.measure "st_lane_adjacency" [lane, .lit "count"]) .ge twoLanes)
          (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] []))

/-- Applicability: s1 (trigger): If a highway has two or more clearly marked lanes for traffic traveling in one direction,; s2 (subject): vehicles must: -/
def applicability : Formula :=
  .existsRegion (.lit "lane") "lane"
    (.and (.atom "rel_occupies" [vSubject, vLane] []) (laneGroup vLane))

/-- The signed lateral offset (m, left positive) of the lane the subject leaves, read from the
    subject at the observation of the departure. -/
def offsetOfLaneLeft (lane : Arg) : Term := .quantity "prim_region_lateral_offset" [vSubject, lane] []

/-- The subject left the lane across its left side: the lane now lies to the subject's right. -/
def departsLeft (lane : Arg) : Formula := .cmp (offsetOfLaneLeft lane) .lt zeroMetres
/-- The subject left the lane across its right side. -/
def departsRight (lane : Arg) : Formula := .cmp (offsetOfLaneLeft lane) .gt zeroMetres

/-- s1: the lane carries a marking of a type other than none on that side. -/
def markedOn (lane : Arg) (side : String) : Formula :=
  .not (.atom "st_lane_marking" [lane, .lit side, .lit "none"] [])

/-- s1: the side the subject leaves carries a marking of a type other than none. -/
def leavesMarkedSide (lane : Arg) : Formula :=
  .or (.and (departsLeft lane) (markedOn lane "left"))
      (.and (departsRight lane) (markedOn lane "right"))

/-- s4: the turn indicator or the arm signal shows that side. -/
def appropriateSignal (side : String) : Formula :=
  .or (.atom "sig_turn_indicator" [vSubject, .lit side] [])
      (.atom "sig_hand_signal" [vSubject, .lit side] [])

/-- s4: the appropriate turn signal is being given for the side of the departure. -/
def signalGiven (lane : Arg) : Formula :=
  .and (.implies (departsLeft lane) (appropriateSignal "left"))
       (.implies (departsRight lane) (appropriateSignal "right"))

/-- s5: the movement can be made with safety — the operationalization's conflict prediction for
    every other road user, and no contact with a road user already in the lane entered. -/
def movementSafe (entered : Arg) : Formula :=
  .forallUser "other"
    (.implies (.not (.same vOther vSubject))
      (.and
        (.or (.not (.derived "prim_closest_approach_within" [vSubject, vOther] [pYieldConflictHorizon]))
             (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pYieldConflictHorizon])
                   .ge pYieldMinClearance))
        (.implies (.atom "rel_occupies" [vOther, entered] [])
                  (.cmp (.measure "rel_surface_gap" [vSubject, vOther]) .gt zeroMetres))))

/-- s4: the lane the subject enters — entered at this observation, occupied by the subject, another
    lane than the one left, and of the same designated direction (s1's "in one direction"). -/
def entersLane (lane entered : Arg) : Formula :=
  .and (.derived "drv_lane_enters_region" [vSubject, entered] [])
    (.and (.atom "rel_occupies" [vSubject, entered] [])
      (.and (.not (.same lane entered))
        (.and (.cmp (.measure "st_lane_direction" [lane, .lit "x"]) .eq
                    (.measure "st_lane_direction" [entered, .lit "x"]))
              (.cmp (.measure "st_lane_direction" [lane, .lit "y"]) .eq
                    (.measure "st_lane_direction" [entered, .lit "y"])))))

/-- Obligation: s3 (obligation): Not be moved from that lane; s4 (condition): until the driver has given the appropriate turn signal; s5 (standard): and ascertained that such movement can be made with safety. -/
def obligation : Formula :=
  .forallRegion (.lit "lane") "lane"
    (.implies
      (.and (laneGroup vLane)
        (.and (.derived "drv_lane_exits_region" [vSubject, vLane] [])
              (leavesMarkedSide vLane)))
      (.forallRegion (.lit "lane") "entered"
        (.implies (entersLane vLane vEntered)
                  (.and (signalGiven vLane) (movementSafe vEntered)))))

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
      [ { standard := "ascertained that such movement can be made with safety"
          concepts := ["drv.lane.enters_region", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "rel.surface_gap", "st.lane"]
          params := ["p.yield_conflict_horizon", "p.yield_min_clearance"]
          convention := "conflict-prediction convention of surrogate safety measures: the movement can be made with safety where, at the observation of the movement, no other road user is on a course that would bring the two bodies into conflict — for every other road user, either their centres do not approach within p.yield_conflict_horizon under the velocities observed (prim.closest_approach_within) or the centre distance at that closest approach stays at or above p.yield_min_clearance (prim.closest_approach_distance), the clearance below which two bodies would be in conflict since centre distance overstates a body clearance by about the two half-extents. The body gap rel.surface_gap to a road user already in the lane entered is read beside the prediction, a gap of zero being contact. The duty to ascertain is read by the outcome the check secures, the movement made with the clearances the reading sets."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "The side across which the subject leaves the lane — and with it which signal is appropriate (s4) and which side's marking must be of a type other than none (s1) — is read from the sign of prim.region_lateral_offset of the lane left, at the observation of the departure: negative where that lane now lies to the subject's right, so the subject moved to its left. The record reads the offset on the lane entered; at the observation of the departure the subject's reference point lies in the lane entered, where the primitive is zero by its contract and so decides no side, and the same signed quantity on the lane left decides it with the sign inverted."
          kind := "reading" }
      , { span := "s3"
          why := "The departure is read as a movement into another lane that carries the same designated direction as the lane left — one of the two or more lanes the trigger counts (st.lane_direction, which the record claims for the direction counted). A crossing out of the lane that is not into such a lane is not read as this duty's movement."
          kind := "reading" }
      , { span := "s3"
          why := "The trigger's marking of the lane on the side the subject leaves is written in the duty's antecedent rather than in the applicability, because the side is fixed only at the observation of the departure: a departure across a side whose marking is of type none leaves the duty complied with at that observation rather than not engaged, while applicability and obligation together state the trigger whole."
          kind := "reading" }
      , { span := "s5"
          why := "The body gap to a road user that occupies the lane entered is required to be greater than zero: the convention names the gap beside the prediction and says a gap of zero is contact, without stating a bound, and the bound written here is that absence of contact."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_1b
