/-
  NRS_484B_450_1k — NRS-484B-450-1k

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A person
    s2 (obligation): shall not stop, stand or park a vehicle,
    s3 (standard): except when necessary to avoid conflict
    s4 (exception): with other traffic
    s5 (exception): or in compliance with law
    s6 (exception): or the directions of a police officer
    s7 (exception): or official traffic-control device,
    s8 (boilerplate): in any of the following places:
    s9 (condition): Alongside or opposite any highway excavation or obstruction
    s10 (standard): when stopping, standing or parking would obstruct traffic.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.ahead_behind_in_lane', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s5: atoms ['dev.governs', 'dev.stop_sign', 'dev.traffic_signal', 'rel.occupies', 'st.travel_region'], derived []
    s6: atoms ['dev.governs', 'dev.human_direction', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['dev.governs', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.occupies', 'st.travel_region'], derived []
    s9: atoms ['st.obstruction', 'prim.region_lateral_offset', 'st.region_geometry', 'st.on_way', 'st.highway', 'rel.occupies'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_450_1k

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pFreePassageWidth : Term := .param "p.free_passage_width"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written (the record's applicability and obligation fields decide the split:
  the place and its obstruction of traffic are the applicability, the halt and its four
  exceptions the obligation).

  s1 — `clsSubject`: ru_aggregate(subject, DEF-NRS-484A-320::vehicle).
  s9 — `alongside o`, inside `existsRegion obstruction o` (every kind, so no kind atom):
       o lies on a highway h (st_on_way o h) whose extent the subject occupies
       (rel_occupies subject h); o's signed lateral offset from the subject
       (prim_region_lateral_offset) is nonzero, and the ground distance from the subject's body
       to o (st_region_geometry_distance) is at most |offset|.
  s10 — `obstructsTraffic o`: that distance is below p.free_passage_width, and no road edge e
       (existsRegion road_edge e) whose offset has the sign opposite to o's — written as the
       product of the two offsets below zero — lies at a distance of at least
       p.free_passage_width from the subject's body.
  s2 — `halted`: drv_motion_complete_halt(subject, p.halt_speed_tolerance); the obligation is
       its negation, unless an exception holds.
  s3/s4 — `queueException`: some road user u, not the subject (`same`), of
       DEF-NRS-484A-285::traffic, ahead of the subject in its lane
       (rel_ahead_behind_in_lane u subject), with the gap between the bodies (rel_surface_gap,
       read without a component: the distance) at most p.queue_halt_gap.
  s5/s6/s7 — `deviceException`: in a travel region r the subject occupies, a stop sign, a yield
       sign, a traffic signal showing circular_red, flashing_red or a red_arrow of any
       direction, a level-crossing device with lights flashing or gate lowering or down, or a
       human direction of role police_officer and indication stop, governs r. The record's
       exception (b) (s5: stop sign, red signal) is a subset of its exception (d) (s7), so the
       two are written once as one disjunction; the denotation is the record's (b) ∨ (c) ∨ (d).
  No choice beyond the record's own reading was needed: no narrowing is declared.
-/

def vO : Arg := .var "o"
def vH : Arg := .var "h"
def vE : Arg := .var "e"
def vU : Arg := .var "u"
def vR : Arg := .var "r"
def vD : Arg := .var "d"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Signed lateral offset (left positive) of region `r` from the subject. -/
def offsetOf (r : Arg) : Term := .quantity "prim_region_lateral_offset" [vSubject, r] []

/-- Ground distance from the subject's body to region `r`. -/
def gapTo (r : Arg) : Term := .measure "st_region_geometry_distance" [vSubject, r]

/-- s9: `o` lies on a highway the subject occupies. -/
def onSubjectsHighway : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [vO, vH] []) (.atom "rel_occupies" [vSubject, vH] []))

/-- s9: `o` lies to the subject's side (beside it or across the way), not ahead or behind. -/
def alongsideOrOpposite : Formula :=
  .and (.not (.cmp (offsetOf vO) .eq zeroMetres))
       (.cmp (gapTo vO) .le (.abs (offsetOf vO)))

/-- Zero area: the product of two offsets is compared with it (opposite signs ⟺ product < 0). -/
def zeroSquareMetres : Term := .mul zeroMetres zeroMetres

/-- s10: a road edge on the side opposite `o` leaving the free passage width. -/
def passageOnOtherSide : Formula :=
  .existsRegion (.lit "road_edge") "e"
    (.and (.cmp (.mul (offsetOf vE) (offsetOf vO)) .lt zeroSquareMetres)
          (.cmp (gapTo vE) .ge pFreePassageWidth))

/-- s10: a halt here would obstruct traffic. -/
def obstructsTraffic : Formula :=
  .and (.cmp (gapTo vO) .lt pFreePassageWidth) (.not passageOnOtherSide)

/-- Applicability: s9 and s10, for some obstruction of any kind. -/
def applicability : Formula :=
  .existsRegion (.lit "obstruction") "o"
    (.and onSubjectsHighway (.and alongsideOrOpposite obstructsTraffic))

/-- s2: the subject is at rest. -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s3/s4: a member of other traffic ahead in the subject's lane within the queue gap. -/
def queueException : Formula :=
  .existsUser "u"
    (.and (.not (.same vU vSubject))
      (.and (.atom "ru_aggregate" [vU, .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.atom "rel_ahead_behind_in_lane" [vU, vSubject] [])
              (.cmp (.measure "rel_surface_gap" [vSubject, vU]) .le pQueueHaltGap))))

def governsR : Formula := .atom "dev_governs" [vD, vR] []

def shows (i : String) : Formula := .atom "dev_traffic_signal_shows" [vD, .lit i] []

/-- A traffic signal head showing a red indication. -/
def signalRed : Formula :=
  .or (shows "circular_red")
    (.or (shows "flashing_red")
      (.or (shows "red_arrow(left)")
        (.or (shows "red_arrow(right)")
          (.or (shows "red_arrow(straight)") (shows "red_arrow(u_turn)")))))

/-- A level-crossing device commanding a halt. -/
def crossingActive : Formula :=
  .or (.atom "dev_railway_signal_or_gate_lights" [vD, .lit "flashing"] [])
    (.or (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "lowering"] [])
         (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "down"] []))

/-- A police officer directing a stop. -/
def policeStop : Formula :=
  .and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
       (.atom "dev_human_direction_indication" [vD, .lit "stop"] [])

/-- s5/s6/s7: a halt in compliance with law, a police officer's direction or an official
    traffic-control device governing a travel region the subject occupies. -/
def deviceException : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] [])
      (.or (.existsDevice (.lit "stop_sign") "d" governsR)
        (.or (.existsDevice (.lit "yield_sign") "d" governsR)
          (.or (.existsDevice (.lit "traffic_signal") "d" (.and governsR signalRed))
            (.or (.existsDevice (.lit "railway_signal_or_gate") "d" (.and governsR crossingActive))
                 (.existsDevice (.lit "human_direction") "d" (.and governsR policeStop)))))))

/-- Obligation: not at rest, unless an exception holds. -/
def obligation : Formula :=
  .or (.not halted) (.or queueException deviceException)

def rule : Rule :=
  { id := "NRS_484B_450_1k"
    laws := ["NRS-484B-450-1k"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "necessary to avoid conflict with other traffic"
          concepts := ["rel.ahead_behind_in_lane", "rel.surface_gap"]
          params := ["p.queue_halt_gap"]
          convention := "queue spacing of halted vehicles: a halt with a member of traffic ahead in the same lane within that gap between bodies is a halt the traffic ahead makes necessary"
          surrogate := false }
      , { standard := "stopping, standing or parking would obstruct traffic"
          concepts := ["prim.region_lateral_offset", "st.obstruction", "st.region_geometry", "st.road_edge"]
          params := ["p.free_passage_width"]
          convention := "the free lateral width one passing vehicle needs beside a standing vehicle (design-vehicle width with its lateral clearance): a halt beside or opposite an excavation or obstruction obstructs traffic where neither the gap between the vehicle's body and the object nor the gap between its body and the roadway edge on its other side leaves that width"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_450_1k
