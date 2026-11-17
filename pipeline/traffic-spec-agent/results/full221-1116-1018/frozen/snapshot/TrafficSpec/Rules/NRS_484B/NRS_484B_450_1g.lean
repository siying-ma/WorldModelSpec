/-
  NRS_484B_450_1g — NRS-484B-450-1g

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
    s9 (condition): Within 30 feet upon the approach to any official traffic-control signal
    s10 (condition): located at the side of a highway.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.ahead_behind_in_lane', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s5: atoms ['dev.governs', 'dev.stop_sign', 'dev.traffic_signal', 'rel.occupies', 'st.travel_region'], derived []
    s6: atoms ['dev.governs', 'dev.human_direction', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['dev.governs', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.occupies', 'st.travel_region'], derived []
    s9: atoms ['dev.traffic_signal', 'dev.governs', 'dev.position', 'kin.position', 'kin.extent', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.intersection', 'st.lane_direction'], derived []
    s10: atoms ['dev.position', 'kin.position', 'kin.heading', 'prim.region_lateral_offset', 'st.road_edge'], derived []

  Literals the text states (each written through its Units constructor):
    s9: 30 ft — 30 feet

  How each span is written:
    s1/s2 — the subject's class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`; the halt
      forbidden is `drv_motion_complete_halt subject` with p.halt_speed_tolerance.
    s9 — some traffic signal d and some travel region r the subject occupies, with d governing r or
      r entering (st_lane_enters) an intersection i that d governs; the head ahead of the subject's
      reference point along r's direction (dot of st_lane_direction with head − position > 0); and
      within 30 ft of the vehicle's front: |head − position| ≤ 30 ft + L/2, with L the full length
      read by kin_extent "length". Squared and doubled to stay free of any figure but the text's:
      4·|head − position|² ≤ (30 ft + 30 ft + L)², each side written as sums.
    s10 — some road edge e with offset l = prim_region_lateral_offset(subject, e); the head's
      lateral offset lat = heading × (head − position) (left positive) is ≥ l where l > 0, or ≤ l
      where l < 0.
    s3/s4 — some road user o other than the subject (`not (same o subject)`), of
      DEF-NRS-484A-285::traffic, ahead of the subject in the same lane (rel_ahead_behind_in_lane o
      subject: "o ahead of subject"), with rel_surface_gap (the distance form) ≤ p.queue_halt_gap.
    s5/s7 — the halts the law requires (stop sign; a traffic signal showing circular_red, a
      red_arrow of any direction or flashing_red) are among the device directions of s7 (stop
      sign, yield sign, those signal indications, a railway signal with lights flashing or gate
      lowering/down), each governing a travel region the subject occupies; the union is written
      once, since s5's devices are a subset of s7's (writing them twice would add a leaf that
      can never decide).
    s6 — a human_direction device of role police_officer and indication stop governing a travel
      region the subject occupies.
    The obligation: not at rest, or one of the exceptions.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_450_1g

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- s9: the text's 30 feet. -/
def thirtyFeet : Term := .lit (Units.feet 30) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

-- ------------------------------------------------------------------------------------------
-- s9 / s10: the place
-- ------------------------------------------------------------------------------------------

def vD : Arg := .var "d"
def vR : Arg := .var "r"
def vI : Arg := .var "i"
def vE : Arg := .var "e"

/-- Components of the vector from the subject's reference point to the head of `d`. -/
def dx : Term := .sub (.measure "dev_position" [vD, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dy : Term := .sub (.measure "dev_position" [vD, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])

/-- s9: d governs r, or r enters an intersection d governs. -/
def signalControlsApproach : Formula :=
  .or (.atom "dev_governs" [vD, vR] [])
      (.existsRegion (.lit "intersection") "i"
        (.and (.atom "st_lane_enters" [vR, vI] []) (.atom "dev_governs" [vD, vI] [])))

/-- s9: the head lies ahead of the reference point along r's designated direction. -/
def headAhead : Formula :=
  .cmp (.add (.mul (.measure "st_lane_direction" [vR, .lit "x"]) dx)
             (.mul (.measure "st_lane_direction" [vR, .lit "y"]) dy))
       .gt zeroMetres

/-- s9: within 30 feet of the vehicle's front: |v| ≤ 30 ft + L/2, i.e. 4|v|² ≤ (2·30 ft + L)². -/
def withinThirtyFeet : Formula :=
  let sq : Term := .add (.mul dx dx) (.mul dy dy)
  let lhs : Term := .add (.add sq sq) (.add sq sq)
  let bound : Term := .add (.add thirtyFeet thirtyFeet) (.measure "kin_extent" [vSubject, .lit "length"])
  .cmp lhs .le (.mul bound bound)

/-- s10: the head's lateral offset in the subject's frame (left positive). -/
def headLateral : Term :=
  .sub (.mul (.measure "kin_heading" [vSubject, .lit "x"]) dy)
       (.mul (.measure "kin_heading" [vSubject, .lit "y"]) dx)

/-- s10: the head lies beyond a roadway edge on that edge's side. -/
def headAtSide : Formula :=
  .existsRegion (.lit "road_edge") "e"
    (let l : Term := .quantity "prim_region_lateral_offset" [vSubject, vE] []
     .or (.and (.cmp l .gt zeroMetres) (.cmp headLateral .ge l))
         (.and (.cmp l .lt zeroMetres) (.cmp headLateral .le l)))

/-- Applicability: s9 (condition): Within 30 feet upon the approach to any official traffic-control signal; s10 (condition): located at the side of a highway. -/
def applicability : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.existsRegion (.lit "travel_region") "r"
      (.and (.atom "rel_occupies" [vSubject, vR] [])
        (.and signalControlsApproach
          (.and headAhead
            (.and withinThirtyFeet headAtSide)))))

-- ------------------------------------------------------------------------------------------
-- s2 and the exceptions
-- ------------------------------------------------------------------------------------------

/-- s2: the subject at rest. -/
def atRest : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s3/s4: a member of other traffic ahead in the same lane within the queue gap. -/
def excQueue : Formula :=
  .existsUser "o"
    (.and (.not (.same (.var "o") vSubject))
      (.and (.atom "ru_aggregate" [.var "o", .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.atom "rel_ahead_behind_in_lane" [.var "o", vSubject] [])
          (.cmp (.measure "rel_surface_gap" [vSubject, .var "o"]) .le pQueueHaltGap))))

def vQ : Arg := .var "q"
def vS : Arg := .var "s"

/-- A device of `kind` governing q and satisfying `φ`. -/
def governingDevice (kind : String) (φ : Formula) : Formula :=
  .existsDevice (.lit kind) "s" (.and (.atom "dev_governs" [vS, vQ] []) φ)

/-- A traffic signal showing a red indication. -/
def signalShowsRed : Formula :=
  .or (.atom "dev_traffic_signal_shows" [vS, .lit "circular_red"] [])
   (.or (.atom "dev_traffic_signal_shows" [vS, .lit "red_arrow(left)"] [])
    (.or (.atom "dev_traffic_signal_shows" [vS, .lit "red_arrow(right)"] [])
     (.or (.atom "dev_traffic_signal_shows" [vS, .lit "red_arrow(straight)"] [])
      (.or (.atom "dev_traffic_signal_shows" [vS, .lit "red_arrow(u_turn)"] [])
           (.atom "dev_traffic_signal_shows" [vS, .lit "flashing_red"] [])))))

/-- s5/s7: a device directing a halt governs the region (s5's devices are among s7's). -/
def deviceDirectsHalt : Formula :=
  .or (.existsDevice (.lit "stop_sign") "s" (.atom "dev_governs" [vS, vQ] []))
   (.or (.existsDevice (.lit "yield_sign") "s" (.atom "dev_governs" [vS, vQ] []))
    (.or (governingDevice "traffic_signal" signalShowsRed)
         (governingDevice "railway_signal_or_gate"
           (.or (.atom "dev_railway_signal_or_gate_lights" [vS, .lit "flashing"] [])
             (.or (.atom "dev_railway_signal_or_gate_gate" [vS, .lit "lowering"] [])
                  (.atom "dev_railway_signal_or_gate_gate" [vS, .lit "down"] []))))))

/-- s6: a police officer directing stop governs the region. -/
def officerDirectsStop : Formula :=
  governingDevice "human_direction"
    (.and (.atom "dev_human_direction_role" [vS, .lit "police_officer"] [])
          (.atom "dev_human_direction_indication" [vS, .lit "stop"] []))

/-- s5, s6, s7: on a travel region the subject occupies. -/
def excDirected : Formula :=
  .existsRegion (.lit "travel_region") "q"
    (.and (.atom "rel_occupies" [vSubject, vQ] [])
          (.or deviceDirectsHalt officerDirectsStop))

/-- Obligation: s2 (obligation): shall not stop, stand or park a vehicle,; s3 (standard): except when necessary to avoid conflict -/
def obligation : Formula :=
  .or (.not atRest) (.or excQueue excDirected)

def rule : Rule :=
  { id := "NRS_484B_450_1g"
    laws := ["NRS-484B-450-1g"]
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

end TrafficSpec.Rules.NRS_484B_450_1g
