/-
  NRS_484B_450_1l — NRS-484B-450-1l

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
    s9 (condition): On the highway side of any vehicle
    s10 (condition): stopped or parked
    s11 (condition): at the edge of or curb of a highway.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.ahead_behind_in_lane', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s5: atoms ['dev.governs', 'dev.stop_sign', 'dev.traffic_signal', 'rel.occupies', 'st.travel_region'], derived []
    s6: atoms ['dev.governs', 'dev.human_direction', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['dev.governs', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.occupies', 'st.travel_region'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.bearing', 'rel.longitudinal_overlap', 'prim.region_lateral_offset'], derived []
    s10: atoms [], derived ['drv.motion.complete_halt']
    s11: atoms ['st.road_edge', 'st.region_geometry', 'st.on_way', 'st.highway'], derived []

  How each span is written:
    s1/s2  the subject binder's class is `ru_aggregate subject DEF-NRS-484A-320::vehicle`; the duty
           "shall not stop, stand or park" is `¬ drv_motion_complete_halt(subject, p.halt_speed_tolerance)`
           at every observation the applicability holds (each of stop, stand, park is a halting).
    s9     some road user `b`, not the subject (`¬ same b subject`), of DEF-NRS-484A-320::vehicle,
           side by side with the subject (`rel_longitudinal_overlap subject b ≥ 0`), with b's bearing
           from the subject (`rel_bearing subject b` lateral component, selector "y") and the edge's
           signed lateral offset (`prim_region_lateral_offset subject e`) both < 0 or both > 0.
    s10    `drv_motion_complete_halt(b, p.halt_speed_tolerance)`.
    s11    some region `e` of kind road_edge that lies on (`st_on_way`) some region of kind highway,
           with the ground distance from b's body to it (`st_region_geometry_distance b e`, the
           distance accessor of st.region_geometry) at most p.edge_standing_gap.
    s3/s4  (operationalization) some road user `c`, not the subject, of DEF-NRS-484A-285::traffic,
           ahead of the subject in the same lane (`rel_ahead_behind_in_lane c subject`: c ahead of
           the subject) with `rel_surface_gap subject c` (the gap's length, no component selected)
           at most p.queue_halt_gap.
    s5/s6/s7  some region `r` of kind travel_region the subject occupies (`rel_occupies`) is governed
           (`dev_governs`) by a stop sign, a yield sign, a traffic signal showing circular_red,
           flashing_red or a red_arrow of any direction, a railway signal or gate with lights
           flashing or gate lowering or down, or a human direction with role police_officer and
           indication stop. The device limbs of s5 are a subset of those of s7 (stop sign, red
           signal), so the three exceptions are written as one disjunction over one occupied
           travel region: the same devices, each written once.
  Choices the text did not dictate: "a red_arrow" is read for every arrow direction
  (left, right, straight, u_turn), the record naming none. No narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_450_1l

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables. -/
def vB : Arg := .var "b"
def vE : Arg := .var "e"
def vC : Arg := .var "c"
def vR : Arg := .var "r"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pEdgeStandingGap : Term := .param "p.edge_standing_gap"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"
def aggTraffic : Arg := .lit "DEF-NRS-484A-285::traffic"

/-- drv.motion.complete_halt of a road user (s2, s10). -/
def halted (x : Arg) : Formula := .derived "drv_motion_complete_halt" [x] [pHaltSpeedTolerance]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggVehicle] []

/-- s11: the edge `e` lies on a highway. -/
def edgeOnHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "st_on_way" [vE, .var "h"] [])

/-- s11: b's body is at the edge `e`. -/
def bAtEdge : Formula :=
  .cmp (.measure "st_region_geometry_distance" [vB, vE]) .le pEdgeStandingGap

/-- s9: the subject and b side by side. -/
def sideBySide : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [vSubject, vB]) .ge zeroMetres

/-- s9: b and its edge on the same side of the subject. -/
def bLateral : Term := .measure "rel_bearing" [vSubject, vB, .lit "y"]
def edgeLateral : Term := .quantity "prim_region_lateral_offset" [vSubject, vE] []
def sameSide : Formula :=
  .or (.and (.cmp bLateral .lt zeroMetres) (.cmp edgeLateral .lt zeroMetres))
      (.and (.cmp bLateral .gt zeroMetres) (.cmp edgeLateral .gt zeroMetres))

/-- Applicability: s9, s10, s11 — a vehicle b, not the subject, at rest at the edge of a highway,
    with the subject beside it on its highway side. -/
def applicability : Formula :=
  .existsUser "b"
    (.and (.not (.same vB vSubject))
      (.and (.atom "ru_aggregate" [vB, aggVehicle] [])
        (.and (halted vB)
          (.existsRegion (.lit "road_edge") "e"
            (.and edgeOnHighway
              (.and bAtEdge
                (.and sideBySide sameSide)))))))

/-- s3/s4: a member of traffic ahead in the subject's lane within the queue gap. -/
def queueAhead : Formula :=
  .existsUser "c"
    (.and (.not (.same vC vSubject))
      (.and (.atom "ru_aggregate" [vC, aggTraffic] [])
        (.and (.atom "rel_ahead_behind_in_lane" [vC, vSubject] [])
          (.cmp (.measure "rel_surface_gap" [vSubject, vC]) .le pQueueHaltGap))))

def governsR (d : String) : Formula := .atom "dev_governs" [.var d, vR] []

def signalRed (d : String) : Formula :=
  .or (.atom "dev_traffic_signal_shows" [.var d, .lit "circular_red"] [])
    (.or (.atom "dev_traffic_signal_shows" [.var d, .lit "flashing_red"] [])
      (.or (.atom "dev_traffic_signal_shows" [.var d, .lit "red_arrow(left)"] [])
        (.or (.atom "dev_traffic_signal_shows" [.var d, .lit "red_arrow(right)"] [])
          (.or (.atom "dev_traffic_signal_shows" [.var d, .lit "red_arrow(straight)"] [])
            (.atom "dev_traffic_signal_shows" [.var d, .lit "red_arrow(u_turn)"] [])))))

def railActive (d : String) : Formula :=
  .or (.atom "dev_railway_signal_or_gate_lights" [.var d, .lit "flashing"] [])
    (.or (.atom "dev_railway_signal_or_gate_gate" [.var d, .lit "lowering"] [])
      (.atom "dev_railway_signal_or_gate_gate" [.var d, .lit "down"] []))

/-- s5/s6/s7: a device or a police officer commanding a halt governs the travel region `r`. -/
def haltCommanded : Formula :=
  .or (.existsDevice (.lit "stop_sign") "ds" (governsR "ds"))
    (.or (.existsDevice (.lit "yield_sign") "dy" (governsR "dy"))
      (.or (.existsDevice (.lit "traffic_signal") "dt" (.and (governsR "dt") (signalRed "dt")))
        (.or (.existsDevice (.lit "railway_signal_or_gate") "dr" (.and (governsR "dr") (railActive "dr")))
          (.existsDevice (.lit "human_direction") "dh"
            (.and (governsR "dh")
              (.and (.atom "dev_human_direction_role" [.var "dh", .lit "police_officer"] [])
                (.atom "dev_human_direction_indication" [.var "dh", .lit "stop"] [])))))))

def deviceOrOfficer : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] []) haltCommanded)

/-- Obligation: s2 (not at rest), unless s3/s4 or s5/s6/s7. -/
def obligation : Formula :=
  .or (.not (halted vSubject)) (.or queueAhead deviceOrOfficer)

def rule : Rule :=
  { id := "NRS_484B_450_1l"
    laws := ["NRS-484B-450-1l"]
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
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_450_1l
