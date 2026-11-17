/-
  NRS_484B_450_1o — NRS-484B-450-1o

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
    s9 (condition): At any place where official traffic-control devices prohibit stopping, standing or parking.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.ahead_behind_in_lane', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s5: atoms ['dev.governs', 'dev.stop_sign', 'dev.traffic_signal', 'rel.occupies', 'st.travel_region'], derived []
    s6: atoms ['dev.governs', 'dev.human_direction', 'rel.occupies', 'st.travel_region'], derived []
    s7: atoms ['dev.governs', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.occupies', 'st.travel_region'], derived []
    s9: atoms ['dev.governs', 'dev.regulatory_sign', 'prim.conditions_hold', 'rel.occupies', 'st.curb_zone', 'st.travel_region'], derived ['drv.motion.complete_halt', 'drv.motion.parked']

  How each is written:
    s1  the binder class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s9  the applicability: a `regulatory_sign` of code no_stopping / no_standing / no_parking whose
        conditions hold for the subject (`prim_conditions_hold`) and which governs (`dev_governs`) a
        `travel_region` the subject occupies (`rel_occupies`); or a `curb_zone` of kind no_stopping /
        no_parking the subject occupies. The same selections are written again, whole, in the
        obligation, each paired with the halt it names.
    s2  the prohibited halt, respectively to the place (the record's own narrowing): under a
        no_stopping sign or curb zone `drv_motion_complete_halt` (p.halt_speed_tolerance); under a
        no_standing sign `drv_motion_parked` (p.halt_speed_tolerance, p.standing_min_duration); under a
        no_parking sign or curb zone `drv_motion_parked` (p.halt_speed_tolerance,
        p.parking_min_duration).
    s3/s4  the operationalization: some road user other than the subject (`same` excludes it), of
        DEF-NRS-484A-285::traffic, ahead of the subject in the same lane (`rel_ahead_behind_in_lane
        other subject`: the first argument is the one ahead) with the distance between the bodies
        (`rel_surface_gap` read without a component, which is the distance) at most p.queue_halt_gap.
    s5/s7  one disjunct per device kind, each governing a travel region the subject occupies: stop
        sign; yield sign; traffic signal showing circular_red, red_arrow(any direction) or
        flashing_red; railway signal or gate with lights flashing, or gate lowering or down. The
        record's exception (b) (s5) is contained in (d) (s7); the union is written once, so that no
        leaf is a duplicate of another.
    s6  a human direction of role police_officer and indication stop governing a travel region the
        subject occupies.
  The exceptions sit in the obligation, as the record places them ("unless at that observation one
  of the exceptions holds"): a halt they excuse is compliant, not outside the rule.
  red_arrow(dir) is spelled once per direction (left, right, straight, u_turn), the record naming
  "a red_arrow" whatever its direction. No choice beyond the record's own narrowings is made.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_450_1o

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingMinDuration : Term := .param "p.parking_min_duration"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"
def pStandingMinDuration : Term := .param "p.standing_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The device `d` governs a travel region the subject's footprint overlaps. -/
def governsSubjectRegion (d : String) : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "dev_governs" [.var d, .var "r"] [])
          (.atom "rel_occupies" [vSubject, .var "r"] []))

/-- s9: a regulatory sign of `code` whose conditions hold for the subject governs a travel region the
    subject occupies. -/
def signProhibits (code : String) : Formula :=
  .existsDevice (.lit "regulatory_sign") "d"
    (.and (.atom "dev_regulatory_sign_code" [.var "d", .lit code] [])
      (.and (.derived "prim_conditions_hold" [.var "d", vSubject] [])
            (governsSubjectRegion "d")))

/-- s9: the subject's footprint overlaps a curb zone of `kind`. -/
def curbProhibits (kind : String) : Formula :=
  .existsRegion (.lit "curb_zone") "z"
    (.and (.atom "st_curb_zone_kind" [.var "z", .lit kind] [])
          (.atom "rel_occupies" [vSubject, .var "z"] []))

def noStoppingHere : Formula := .or (signProhibits "no_stopping") (curbProhibits "no_stopping")
def noStandingHere : Formula := signProhibits "no_standing"
def noParkingHere : Formula := .or (signProhibits "no_parking") (curbProhibits "no_parking")

/-- Applicability: s9 (condition): At any place where official traffic-control devices prohibit
    stopping, standing or parking. -/
def applicability : Formula :=
  .or noStoppingHere (.or noStandingHere noParkingHere)

/-- s2: the halts, each as the prohibition of the place names it. -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]
def standing : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pStandingMinDuration]
def parked : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pParkingMinDuration]

def prohibitedHalt : Formula :=
  .or (.and noStoppingHere halted)
    (.or (.and noStandingHere standing)
         (.and noParkingHere parked))

/-- s3/s4: a member of traffic other than the subject ahead in the same lane within the queue gap. -/
def queueAhead : Formula :=
  .existsUser "o"
    (.and (.not (.same (.var "o") vSubject))
      (.and (.atom "ru_aggregate" [.var "o", .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.atom "rel_ahead_behind_in_lane" [.var "o", vSubject] [])
              (.cmp (.measure "rel_surface_gap" [vSubject, .var "o"]) .le pQueueHaltGap))))

/-- s5/s7: a stop sign, yield sign, red signal or active level-crossing device governs the
    subject's travel region. -/
def deviceRequiresHalt : Formula :=
  .or (.existsDevice (.lit "stop_sign") "ds" (governsSubjectRegion "ds"))
  (.or (.existsDevice (.lit "yield_sign") "dy" (governsSubjectRegion "dy"))
  (.or (.existsDevice (.lit "traffic_signal") "dt"
        (.and (.or (.atom "dev_traffic_signal_shows" [.var "dt", .lit "circular_red"] [])
              (.or (.atom "dev_traffic_signal_shows" [.var "dt", .lit "red_arrow(left)"] [])
              (.or (.atom "dev_traffic_signal_shows" [.var "dt", .lit "red_arrow(right)"] [])
              (.or (.atom "dev_traffic_signal_shows" [.var "dt", .lit "red_arrow(straight)"] [])
              (.or (.atom "dev_traffic_signal_shows" [.var "dt", .lit "red_arrow(u_turn)"] [])
                   (.atom "dev_traffic_signal_shows" [.var "dt", .lit "flashing_red"] []))))))
              (governsSubjectRegion "dt")))
       (.existsDevice (.lit "railway_signal_or_gate") "dr"
        (.and (.or (.atom "dev_railway_signal_or_gate_lights" [.var "dr", .lit "flashing"] [])
              (.or (.atom "dev_railway_signal_or_gate_gate" [.var "dr", .lit "lowering"] [])
                   (.atom "dev_railway_signal_or_gate_gate" [.var "dr", .lit "down"] [])))
              (governsSubjectRegion "dr")))))

/-- s6: a police officer directing the subject's travel region to stop. -/
def policeStop : Formula :=
  .existsDevice (.lit "human_direction") "dh"
    (.and (.atom "dev_human_direction_role" [.var "dh", .lit "police_officer"] [])
      (.and (.atom "dev_human_direction_indication" [.var "dh", .lit "stop"] [])
            (governsSubjectRegion "dh")))

def excused : Formula := .or queueAhead (.or deviceRequiresHalt policeStop)

/-- Obligation: s2 (obligation): shall not stop, stand or park a vehicle,; s3 (standard): except when
    necessary to avoid conflict; s4–s7 the exceptions. -/
def obligation : Formula := .or (.not prohibitedHalt) excused

def rule : Rule :=
  { id := "NRS_484B_450_1o"
    laws := ["NRS-484B-450-1o"]
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

end TrafficSpec.Rules.NRS_484B_450_1o
