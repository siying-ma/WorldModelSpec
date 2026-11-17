/-
  NRS_484B_450_1h — NRS-484B-450-1h

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
    s9 (condition): Between a safety zone and the adjacent curb
    s10 (condition): or within 30 feet of points on the curb immediately opposite the ends of a safety zone.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.ahead_behind_in_lane', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s5: atoms ['dev.governs', 'dev.stop_sign', 'dev.traffic_signal', 'rel.occupies', 'st.travel_region'], derived []
    s6: atoms ['dev.governs', 'dev.human_direction', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['dev.governs', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.occupies', 'st.travel_region'], derived []
    s9: atoms ['st.safety_zone', 'st.road_edge', 'prim.region_lateral_offset', 'st.region_geometry', 'rel.occupies'], derived []
    s10: atoms ['st.safety_zone', 'st.road_edge', 'prim.region_lateral_offset', 'prim.region_offset_along', 'st.region_geometry', 'st.lane_direction', 'st.travel_region', 'rel.occupies', 'kin.extent'], derived []

  Literals the text states (each written through its Units constructor):
    s10: 30 ft — 30 feet

  How each span is written:
    s1/s2: binder class ru_aggregate DEF-NRS-484A-320::vehicle; the duty is "not at rest"
      (drv_motion_complete_halt with p.halt_speed_tolerance) unless an exception holds.
    s9: ∃ safety zone z not occupied, ∃ road edge e adjacent to z (no road edge laterally nearer z,
      by prim_region_lateral_offset), lz·le < 0 and the body-to-zone distance ≤ |lz|.
    s10: ∃ travel region r occupied, with d = |prim_region_offset_along(z, r)| − length/2 > 0 and
      g = body-to-curb distance, d² + g² ≤ (30 ft)². Written doubled (2d, 2g, 30 ft + 30 ft) so that
      no figure other than the text's literal enters the rule; the comparison is equivalent.
    s3/s4: the operationalization — another road user of DEF-NRS-484A-285::traffic ahead in the
      same lane (rel_ahead_behind_in_lane u subject) with rel_surface_gap ≤ p.queue_halt_gap.
    s5–s7: ∃ travel region r the subject occupies, governed by a stop sign, a yield sign, a traffic
      signal showing circular_red / flashing_red / red_arrow(any dir), a railway signal or gate with
      lights flashing or gate lowering or down, or a human direction of role police_officer with
      indication stop. s5's stop sign and red signal are included in s7's list and written once.
  No choice beyond the record was needed; no narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_450_1h

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- s10: the text's literal, 30 feet. -/
def thirtyFeet : Term := .lit (Units.feet 30) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle (s1, s2). -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The signed lateral offset of a region from the subject (prim.region_lateral_offset). -/
def lat (r : String) : Term := .quantity "prim_region_lateral_offset" [vSubject, .var r] []

/-- Ground distance from the subject's body to a region (st.region_geometry). -/
def dist (r : String) : Term := .measure "st_region_geometry_distance" [vSubject, .var r]

/-- s9/s10: road edge `e` is the curb adjacent to zone `z`: no roadway edge lies laterally nearer
    the zone (|le − lz| ≤ |l2 − lz| for every roadway edge e2). -/
def adjacentCurb : Formula :=
  .forallRegion (.lit "road_edge") "e2"
    (.cmp (.abs (.sub (lat "e") (lat "z"))) .le (.abs (.sub (lat "e2") (lat "z"))))

/-- s9: between the zone and the adjacent curb — the two on opposite sides of the subject
    (lz·le < 0, both nonzero), the zone alongside (body-to-zone distance ≤ |lz|). -/
def betweenZoneAndCurb : Formula :=
  .and (.cmp (.mul (lat "z") (lat "e")) .lt (.mul zeroMetres zeroMetres))
       (.cmp (dist "z") .le (.abs (lat "z")))

/-- s10: within 30 feet of the point on the curb opposite an end of the zone. With
    d = |offset along r of z| − length/2 and g = body-to-curb distance, d > 0 and d² + g² ≤ (30 ft)²;
    written doubled (2d = 2|a| − length, 2g, 2·30 ft) so no literal but the text's enters. -/
def twiceAlong : Term :=
  .sub (.add (.abs (.quantity "prim_region_offset_along" [vSubject, .var "z", .var "r"] []))
             (.abs (.quantity "prim_region_offset_along" [vSubject, .var "z", .var "r"] [])))
       (.measure "kin_extent" [vSubject, .lit "length"])
def twiceCurbGap : Term := .add (dist "e") (dist "e")
def twiceThirtyFeet : Term := .add thirtyFeet thirtyFeet
def oppositeZoneEnd : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
      (.and (.cmp twiceAlong .gt zeroMetres)
            (.cmp (.add (.mul twiceAlong twiceAlong) (.mul twiceCurbGap twiceCurbGap)) .le
                  (.mul twiceThirtyFeet twiceThirtyFeet))))

/-- Applicability: s9 (condition): Between a safety zone and the adjacent curb; s10 (condition): or within 30 feet of points on the curb immediately opposite the ends of a safety zone. -/
def applicability : Formula :=
  .existsRegion (.lit "safety_zone") "z"
    (.and (.not (.atom "rel_occupies" [vSubject, .var "z"] []))
      (.existsRegion (.lit "road_edge") "e"
        (.and adjacentCurb (.or betweenZoneAndCurb oppositeZoneEnd))))

/-- s2: the subject is at rest (drv.motion.complete_halt). -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s3/s4 (operationalization): some road user other than the subject, of
    DEF-NRS-484A-285::traffic, ahead in the same lane within p.queue_halt_gap between bodies. -/
def trafficAhead : Formula :=
  .existsUser "u"
    (.and (.not (.same (.var "u") vSubject))
      (.and (.atom "ru_aggregate" [.var "u", .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.atom "rel_ahead_behind_in_lane" [.var "u", vSubject] [])
              (.cmp (.measure "rel_surface_gap" [vSubject, .var "u"]) .le pQueueHaltGap))))

def governsR (d : String) : Formula := .atom "dev_governs" [.var d, .var "r"] []

def signalShows (k : String) : Formula := .atom "dev_traffic_signal_shows" [.var "ds", .lit k] []

/-- s5/s7: a stop sign, a yield sign, a traffic signal showing a red indication, a level-crossing
    signal with lights flashing or gate lowering/down; s6: a police officer directing stop — each
    governing the travel region `r` the subject occupies. (s5's stop sign and red signal are a part
    of s7's list; written once.) -/
def deviceHalt : Formula :=
  .or (.existsDevice (.lit "stop_sign") "dst" (governsR "dst"))
  (.or (.existsDevice (.lit "yield_sign") "dy" (governsR "dy"))
  (.or (.existsDevice (.lit "traffic_signal") "ds"
          (.and (governsR "ds")
            (.or (signalShows "circular_red")
            (.or (signalShows "flashing_red")
            (.or (signalShows "red_arrow(left)")
            (.or (signalShows "red_arrow(right)")
            (.or (signalShows "red_arrow(straight)") (signalShows "red_arrow(u_turn)"))))))))
  (.or (.existsDevice (.lit "railway_signal_or_gate") "dr"
          (.and (governsR "dr")
            (.or (.atom "dev_railway_signal_or_gate_lights" [.var "dr", .lit "flashing"] [])
            (.or (.atom "dev_railway_signal_or_gate_gate" [.var "dr", .lit "lowering"] [])
                 (.atom "dev_railway_signal_or_gate_gate" [.var "dr", .lit "down"] [])))))
       (.existsDevice (.lit "human_direction") "dh"
          (.and (governsR "dh")
            (.and (.atom "dev_human_direction_role" [.var "dh", .lit "police_officer"] [])
                  (.atom "dev_human_direction_indication" [.var "dh", .lit "stop"] [])))))))

def complianceHalt : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] []) deviceHalt)

/-- Obligation: s2 (obligation): shall not stop, stand or park a vehicle,; s3 (standard): except when necessary to avoid conflict; s4–s7 the exceptions. -/
def obligation : Formula :=
  .or (.not halted) (.or trafficAhead complianceHalt)

def rule : Rule :=
  { id := "NRS_484B_450_1h"
    laws := ["NRS-484B-450-1h"]
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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_450_1h
