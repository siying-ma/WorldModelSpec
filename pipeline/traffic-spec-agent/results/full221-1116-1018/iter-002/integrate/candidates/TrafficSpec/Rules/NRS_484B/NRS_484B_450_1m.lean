/-
  NRS_484B_450_1m — NRS-484B-450-1m

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
    s9 (condition): Upon any bridge or other elevated structure
    s10 (condition): or within a highway tunnel.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.ahead_behind_in_lane', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s5: atoms ['dev.governs', 'dev.stop_sign', 'dev.traffic_signal', 'rel.occupies', 'st.travel_region'], derived []
    s6: atoms ['dev.governs', 'dev.human_direction', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['dev.governs', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.occupies', 'st.travel_region'], derived []
    s9: atoms ['rel.occupies', 'st.elevated_structure'], derived []
    s10: atoms ['rel.occupies', 'st.elevated_structure'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_450_1m

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s1  — the class of `subject`: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s9, s10 — the applicability: some region of kind `elevated_structure` (bridge, viaduct or
          tunnel carrying the roadway) that the subject's footprint overlaps (`rel_occupies`).
    s2  — the obligation's duty: the subject is not at rest, `¬ drv_motion_complete_halt subject`
          with `p.halt_speed_tolerance` (stop, stand and park are each a halting, so all halts).
    s3/s4 — exception (a), the record's operationalization: some road user `o` other than the
          subject (`¬ same`), of `DEF-NRS-484A-285::traffic`, ahead of the subject in the same
          lane (`rel_ahead_behind_in_lane o subject`: `o` ahead of `subject`), with the gap
          between bodies (`rel_surface_gap subject o`, the distance read without a component)
          at most `p.queue_halt_gap`.
    s5, s6, s7 — exceptions (b), (c), (d): some travel region (`travel_region`, the abstract kind
          covering every kind a device governs) the subject occupies, governed (`dev_governs`) by
          a stop sign, a yield sign, a traffic signal showing circular_red, a red_arrow of any
          direction or flashing_red, a railway signal or gate with lights flashing or gate
          lowering or down, or a human direction of role police_officer with indication stop.
          Exception (b) (the stop sign and the red signal) is contained in (d); the union is
          written once, under one region quantifier, so that no device is counted twice.
          `dev_governs` reads only which traffic the device directs, never where a halt is due.
  The exceptions are in the obligation (as the record's obligation states them), so an excused
  halt is compliant, not outside the duty.
  No choice beyond the record's words was made: `narrowings` is empty.
-/

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s9, s10: the subject's footprint overlaps a bridge, viaduct or tunnel carrying the roadway. -/
def applicability : Formula :=
  .existsRegion (.lit "elevated_structure") "e" (.atom "rel_occupies" [vSubject, .var "e"] [])

/-- s2: the subject is at rest. -/
def atRest : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s3/s4: a member of other traffic ahead in the same lane within the queue gap between bodies. -/
def behindTraffic : Formula :=
  .existsUser "o"
    (.and (.not (.same (.var "o") vSubject))
      (.and (.atom "ru_aggregate" [.var "o", .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.atom "rel_ahead_behind_in_lane" [.var "o", vSubject] [])
          (.cmp (.measure "rel_surface_gap" [vSubject, .var "o"]) .le pQueueHaltGap))))

/-- The device `d` governs the travel region `r`. -/
def governs (d : String) : Formula := .atom "dev_governs" [.var d, .var "r"] []

/-- A traffic signal head `d` shows a red indication (circular_red, a red_arrow, flashing_red). -/
def showsRed (d : String) : Formula :=
  let shows (i : String) : Formula := .atom "dev_traffic_signal_shows" [.var d, .lit i] []
  .or (shows "circular_red")
    (.or (shows "red_arrow(left)")
      (.or (shows "red_arrow(right)")
        (.or (shows "red_arrow(straight)")
          (.or (shows "red_arrow(u_turn)") (shows "flashing_red")))))

/-- s5, s6, s7: a device or a police officer commands a halt to a travel region the subject occupies. -/
def directedHalt : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
      (.or (.existsDevice (.lit "stop_sign") "dStop" (governs "dStop"))
        (.or (.existsDevice (.lit "yield_sign") "dYield" (governs "dYield"))
          (.or (.existsDevice (.lit "traffic_signal") "dSignal"
                  (.and (governs "dSignal") (showsRed "dSignal")))
            (.or (.existsDevice (.lit "railway_signal_or_gate") "dRail"
                    (.and (governs "dRail")
                      (.or (.atom "dev_railway_signal_or_gate_lights" [.var "dRail", .lit "flashing"] [])
                        (.or (.atom "dev_railway_signal_or_gate_gate" [.var "dRail", .lit "lowering"] [])
                          (.atom "dev_railway_signal_or_gate_gate" [.var "dRail", .lit "down"] [])))))
              (.existsDevice (.lit "human_direction") "dHuman"
                (.and (governs "dHuman")
                  (.and (.atom "dev_human_direction_role" [.var "dHuman", .lit "police_officer"] [])
                    (.atom "dev_human_direction_indication" [.var "dHuman", .lit "stop"] [])))))))))

/-- s2 with s3–s7: not at rest, unless the halt is behind traffic or commanded. -/
def obligation : Formula :=
  .or (.not atRest) (.or behindTraffic directedHalt)

def rule : Rule :=
  { id := "NRS_484B_450_1m"
    laws := ["NRS-484B-450-1m"]
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

end TrafficSpec.Rules.NRS_484B_450_1m
