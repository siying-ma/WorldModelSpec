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

  How each is written:
    s1/s2  the binder `subject` of ru_aggregate DEF-NRS-484A-320::vehicle; the halt it may not make
           is drv_motion_complete_halt(subject, p.halt_speed_tolerance), at each observation.
    s9     some road user b, not the subject (`same`), of DEF-NRS-484A-320::vehicle; the subject
           beside it (rel_longitudinal_overlap(subject, b) ≥ 0); b and the edge e on the same side
           of the subject: the lateral component ("y", left positive) of rel_bearing(subject, b) and
           prim_region_lateral_offset(subject, e) both strictly negative (both to the right) or both
           strictly positive (both to the left) — nonzero and of the same sign, the record's words.
           (A product of the two would compare m² with m, which the unit check refuses.)
    s10    drv_motion_complete_halt(b, p.halt_speed_tolerance).
    s11    some region e of kind road_edge lying on (st_on_way) some region of kind highway, with
           st_region_geometry_distance(b, e) ≤ p.edge_standing_gap.
    s3/s4  (operationalization) some road user o, not the subject, of DEF-NRS-484A-285::traffic,
           ahead of the subject in its lane (rel_ahead_behind_in_lane(o, subject): o ahead of
           subject) with rel_surface_gap(subject, o) (the distance between bodies) ≤ p.queue_halt_gap.
    s5/s7  one disjunction over the devices governing (dev_governs) some travel region the subject
           occupies (rel_occupies): a stop sign; a yield sign; a traffic signal showing circular_red,
           flashing_red or red_arrow(any dir); a railway signal or gate with lights flashing or gate
           lowering or down. The stop sign and the red signal, which s5 and s7 both name, are
           written once (the obligation's limbs (b) and (d) overlap there).
    s6     a human_direction device of role police_officer and indication stop governing a travel
           region the subject occupies, in the same travel-region quantifier.
    Obligation: not halted, or one of the exceptions holds. The exceptions are read only in the
    obligation, so a halt they excuse is compliant, as the record's obligation states.
  No narrowing of my own: every reading above is the record's.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_450_1l

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pEdgeStandingGap : Term := .param "p.edge_standing_gap"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"
def aggTraffic : Arg := .lit "DEF-NRS-484A-285::traffic"

/-- A road user at rest at the observation (s2, s10). -/
def halted (x : Arg) : Formula := .derived "drv_motion_complete_halt" [x] [pHaltSpeedTolerance]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggVehicle] []

def vB : Arg := .var "b"
def vE : Arg := .var "e"

/-- s11: the edge e lies on a highway, and b's body is within the standing gap of it. -/
def edgeOfHighway : Formula :=
  .and (.existsRegion (.lit "highway") "h" (.atom "st_on_way" [vE, .var "h"] []))
    (.cmp (.measure "st_region_geometry_distance" [vB, vE]) .le pEdgeStandingGap)

/-- s9: the subject beside b, and b and its edge on the same (nonzero) side of the subject. -/
def bearingLat : Term := .measure "rel_bearing" [vSubject, vB, .lit "y"]
def edgeOffset : Term := .quantity "prim_region_lateral_offset" [vSubject, vE] []

def onHighwaySide : Formula :=
  .and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vB]) .ge zeroMetres)
    (.or (.and (.cmp bearingLat .lt zeroMetres) (.cmp edgeOffset .lt zeroMetres))
         (.and (.cmp bearingLat .gt zeroMetres) (.cmp edgeOffset .gt zeroMetres)))

/-- Applicability: s9, s10, s11. -/
def applicability : Formula :=
  .existsUser "b"
    (.and (.not (.same vB vSubject))
      (.and (.atom "ru_aggregate" [vB, aggVehicle] [])
        (.and (halted vB)
          (.existsRegion (.lit "road_edge") "e"
            (.and edgeOfHighway onHighwaySide)))))

/-- s3/s4: a member of traffic ahead in the subject's lane within the queue gap. -/
def queueAhead : Formula :=
  .existsUser "o"
    (.and (.not (.same (.var "o") vSubject))
      (.and (.atom "ru_aggregate" [.var "o", aggTraffic] [])
        (.and (.atom "rel_ahead_behind_in_lane" [.var "o", vSubject] [])
          (.cmp (.measure "rel_surface_gap" [vSubject, .var "o"]) .le pQueueHaltGap))))

def vD : Arg := .var "d"
def vR : Arg := .var "r"
def governsR : Formula := .atom "dev_governs" [vD, vR] []

def signalShows (i : String) : Formula := .atom "dev_traffic_signal_shows" [vD, .lit i] []

/-- s5, s6, s7: a device or a police officer, governing the region r, that commands a halt. -/
def haltCommanded : Formula :=
  .or (.existsDevice (.lit "stop_sign") "d" governsR)
  (.or (.existsDevice (.lit "yield_sign") "d" governsR)
  (.or (.existsDevice (.lit "traffic_signal") "d"
          (.and governsR
            (.or (signalShows "circular_red")
            (.or (signalShows "flashing_red")
            (.or (signalShows "red_arrow(left)")
            (.or (signalShows "red_arrow(right)")
            (.or (signalShows "red_arrow(straight)")
                 (signalShows "red_arrow(u_turn)"))))))))
  (.or (.existsDevice (.lit "railway_signal_or_gate") "d"
          (.and governsR
            (.or (.atom "dev_railway_signal_or_gate_lights" [vD, .lit "flashing"] [])
              (.or (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "lowering"] [])
                   (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "down"] [])))))
       (.existsDevice (.lit "human_direction") "d"
          (.and governsR
            (.and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
                  (.atom "dev_human_direction_indication" [vD, .lit "stop"] [])))))))

/-- s5, s6, s7: in a travel region the subject occupies. -/
def lawfulHalt : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] []) haltCommanded)

/-- Obligation: s2 (obligation): shall not stop, stand or park a vehicle,; s3 (standard): except when necessary to avoid conflict -/
def obligation : Formula :=
  .or (.not (halted vSubject)) (.or queueAhead lawfulHalt)

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
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_450_1l
