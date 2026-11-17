/-
  NRS_484B_450_1j — NRS-484B-450-1j

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
    s9 (condition): Within 20 feet of a driveway entrance to any fire station
    s10 (condition): and, on the side of a highway opposite the entrance to any fire station,
    s11 (condition): within 75 feet of that entrance.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.ahead_behind_in_lane', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s5: atoms ['dev.governs', 'dev.stop_sign', 'dev.traffic_signal', 'rel.occupies', 'st.travel_region'], derived []
    s6: atoms ['dev.governs', 'dev.human_direction', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['dev.governs', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.occupies', 'st.travel_region'], derived []
    s9: atoms ['st.fire_station_entrance', 'st.region_geometry'], derived []
    s10: atoms ['st.fire_station_entrance', 'st.road_edge', 'prim.region_lateral_offset', 'st.on_way', 'st.highway', 'rel.occupies'], derived []
    s11: atoms ['st.fire_station_entrance', 'st.region_geometry'], derived []

  How each is written:
    s1     the binder class: `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    s2     the subject at rest: `drv_motion_complete_halt subject` with p.halt_speed_tolerance; the
           obligation is "not at rest, or an exception holds".
    s3/s4  the node's operationalization: some road user `o`, not the subject (`same`), of
           DEF-NRS-484A-285::traffic, ahead of the subject in the same lane
           (`rel_ahead_behind_in_lane o subject`: o ahead of subject), with the gap between bodies
           (`rel_surface_gap subject o`, the distance) at most p.queue_halt_gap.
    s5/s6/s7  one travel region `r` the subject occupies (`rel_occupies`), governed (`dev_governs`)
           by a stop sign, a yield sign, a traffic signal showing circular_red, a red_arrow (any
           direction) or flashing_red, a railway signal or gate with lights flashing or gate
           lowering or down, or a human direction of role police_officer with indication stop.
           s5's stop sign and red signal are the same disjuncts as s7's and are written once
           (a disjunct written twice says nothing more).
    s9     some fire station entrance `f` with `st_region_geometry_distance subject f` ≤ 20 ft.
    s10/s11 some fire station entrance `f`, within 75 ft of the subject's body, and some highway
           `h` the subject occupies with a road edge `e1` lying on `h` (`st_on_way`) such that,
           with offsets read toward the entrance's side (`prim_region_lateral_offset`, multiplied
           by the sign of f's offset through `Term.cond`), e1's offset is positive (nonzero, of
           f's sign) and at most |lf|, and every road edge `e2` on `h` whose offset toward the
           entrance's side is negative (opposite sign) is nearer than e1 (|l2| < |l1|). Where lf
           is zero no l1 is both positive and at most |lf|, so the side test fails, as the
           record's "of the sign of lf" says.

  Literals the text states (each written through its Units constructor):
    s9: 20 ft — 20 feet
    s11: 75 ft — 75 feet

  No choice left open by the record was taken beyond writing "of the sign of lf" through `cond`;
  no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_450_1j

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- The text's literals (s9, s11). -/
def twentyFeet : Term := .lit (Units.feet 20) .metre
def seventyFiveFeet : Term := .lit (Units.feet 75) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Ground distance from the subject's body to region `r` (st.region_geometry). -/
def distTo (r : String) : Term := .measure "st_region_geometry_distance" [vSubject, .var r]

/-- Signed lateral offset of region `r` from the subject (left positive). -/
def offset (r : String) : Term := .quantity "prim_region_lateral_offset" [vSubject, .var r] []

/-- The offset of `r` read toward the side of the entrance `f`: positive on f's side. -/
def toward (f r : String) : Term :=
  .cond (.cmp (offset f) .gt zeroMetres) (offset r) (.neg (offset r))

/-- s9: within 20 feet of a fire station driveway entrance. -/
def nearEntrance : Formula :=
  .existsRegion (.lit "fire_station_entrance") "f" (.cmp (distTo "f") .le twentyFeet)

/-- s10: the subject on a highway it occupies, on the side opposite entrance `f`. -/
def oppositeSide (f : String) : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "rel_occupies" [vSubject, .var "h"] [])
      (.existsRegion (.lit "road_edge") "e1"
        (.and (.atom "st_on_way" [.var "e1", .var "h"] [])
          (.and (.cmp (toward f "e1") .gt zeroMetres)
            (.and (.cmp (toward f "e1") .le (.abs (offset f)))
              (.forallRegion (.lit "road_edge") "e2"
                (.implies
                  (.and (.atom "st_on_way" [.var "e2", .var "h"] [])
                        (.cmp (toward f "e2") .lt zeroMetres))
                  (.cmp (.neg (toward f "e2")) .lt (toward f "e1")))))))))

/-- s10 + s11: opposite the entrance and within 75 feet of that same entrance. -/
def oppositeEntrance : Formula :=
  .existsRegion (.lit "fire_station_entrance") "f"
    (.and (oppositeSide "f") (.cmp (distTo "f") .le seventyFiveFeet))

/-- Applicability: s9 (condition) or s10 with s11 (conditions). -/
def applicability : Formula := .or nearEntrance oppositeEntrance

/-- s2: the subject at rest. -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s3/s4: other traffic ahead in the same lane within the queue gap. -/
def queueAhead : Formula :=
  .existsUser "o"
    (.and (.not (.same (.var "o") vSubject))
      (.and (.atom "ru_aggregate" [.var "o", .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.atom "rel_ahead_behind_in_lane" [.var "o", vSubject] [])
          (.cmp (.measure "rel_surface_gap" [vSubject, .var "o"]) .le pQueueHaltGap))))

def governsR (d : String) : Formula := .atom "dev_governs" [.var d, .var "r"] []

/-- s5/s7: a stop sign governs region `r`. -/
def stopSign : Formula := .existsDevice (.lit "stop_sign") "dStop" (governsR "dStop")

/-- s7: a yield sign governs region `r`. -/
def yieldSign : Formula := .existsDevice (.lit "yield_sign") "dYield" (governsR "dYield")

def showsS (i : String) : Formula := .atom "dev_traffic_signal_shows" [.var "dSig", .lit i] []

/-- s5/s7: a traffic signal showing a red indication governs region `r`. -/
def redSignal : Formula :=
  .existsDevice (.lit "traffic_signal") "dSig"
    (.and (governsR "dSig")
      (.or (showsS "circular_red")
        (.or (showsS "red_arrow(left)")
          (.or (showsS "red_arrow(right)")
            (.or (showsS "red_arrow(straight)")
              (.or (showsS "red_arrow(u_turn)") (showsS "flashing_red")))))))

/-- s7: a level-crossing signal flashing or its gate lowering or down governs region `r`. -/
def railActive : Formula :=
  .existsDevice (.lit "railway_signal_or_gate") "dRail"
    (.and (governsR "dRail")
      (.or (.atom "dev_railway_signal_or_gate_lights" [.var "dRail", .lit "flashing"] [])
        (.or (.atom "dev_railway_signal_or_gate_gate" [.var "dRail", .lit "lowering"] [])
             (.atom "dev_railway_signal_or_gate_gate" [.var "dRail", .lit "down"] []))))

/-- s6: a police officer directing stop governs region `r`. -/
def policeStop : Formula :=
  .existsDevice (.lit "human_direction") "dPol"
    (.and (governsR "dPol")
      (.and (.atom "dev_human_direction_role" [.var "dPol", .lit "police_officer"] [])
            (.atom "dev_human_direction_indication" [.var "dPol", .lit "stop"] [])))

/-- s5/s6/s7: a halt the law, a police officer or a device directs, on a travel region the
    subject occupies. -/
def directedHalt : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
      (.or stopSign (.or yieldSign (.or redSignal (.or railActive policeStop)))))

/-- Obligation: s2 (obligation) with s3 (standard) and the exceptions s4–s7. -/
def obligation : Formula := .or (.not halted) (.or queueAhead directedHalt)

def rule : Rule :=
  { id := "NRS_484B_450_1j"
    laws := ["NRS-484B-450-1j"]
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

end TrafficSpec.Rules.NRS_484B_450_1j
