/-
  NRS_484B_413_3 — NRS-484B-413-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A driver
    s2 (trigger): shall not stop
    s3 (standard): or suddenly decrease the speed
    s4 (subject): of a vehicle
    s5 (obligation): without first giving an appropriate signal
    s6 (condition): to the driver of any vehicle immediately to the rear.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.ahead_behind_in_lane', 'rel.surface_gap', 'dev.governs', 'dev.human_direction', 'dev.stop_sign', 'dev.yield_sign', 'dev.traffic_signal', 'dev.railway_signal_or_gate', 'rel.occupies', 'st.travel_region'], derived ['drv.motion.complete_halt']
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['sig.brake_lamp', 'sig.hand_signal'], derived []
    s6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.ahead_behind_in_lane', 'rel.surface_gap'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_413_3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"
def pRearSignalReach : Term := .param "p.rear_signal_reach"
def pStopSignalLeadWindow : Term := .param "p.stop_signal_lead_window"
def pSuddenDecelMin : Term := .param "p.sudden_decel_min"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.

  s1/s4 — the subject binder's class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.

  s2 — "stop", read under DEF-NRS-484A-260: the onset of `drv_motion_complete_halt(subject;
    p.halt_speed_tolerance)` (`rises`), and the halt not excused:
      · other traffic: some road user `lead` (not the subject) ahead of the subject in the same lane
        (`rel_ahead_behind_in_lane lead subject`, "lead ahead of subject") with the body gap
        (`rel_surface_gap`, distance) at most p.queue_halt_gap;
      · a device or officer: some `travel_region` `occ` the subject occupies (`rel_occupies`) that a
        stop sign, a yield sign, a traffic signal showing circular_red / red_arrow(any direction) /
        flashing_red, a railway signal or gate with lights flashing or gate lowering or down, or a
        human direction of role police_officer indicating stop governs (`dev_governs d occ`).
  s3 — "suddenly decrease the speed", the node's operationalization: the rise of
    `kin_accel_longitudinal subject ≤ −p.sudden_decel_min` (at or below and not at the previous
    observation).
  s6 — some road user `rear` (not the subject) of the aggregate DEF-NRS-484A-320::vehicle that the
    subject is ahead of in the same lane (`rel_ahead_behind_in_lane subject rear`) with
    `rel_surface_gap` at most p.rear_signal_reach.
  s5 — the signal: `sig_brake_lamp subject` or `sig_hand_signal subject stop_or_slow`, shown at E or
    at some observation of the time window of length p.stop_signal_lead_window behind E:
    `not (holdsFor time W subject (not signal))` (the window `[E − W, E]` includes E).

  No choice beyond the record was needed: `narrowings` is empty.
-/

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: the onset of a complete halt. -/
def haltOnset : Formula :=
  .rises (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- s2 (DEF-NRS-484A-260 exclusion): a road user ahead in the same lane within the queue gap. -/
def queueAhead : Formula :=
  .existsUser "lead"
    (.and (.not (.same (.var "lead") vSubject))
      (.and (.atom "rel_ahead_behind_in_lane" [.var "lead", vSubject] [])
        (.cmp (.measure "rel_surface_gap" [vSubject, .var "lead"]) .le pQueueHaltGap)))

def governs (d : String) : Formula := .atom "dev_governs" [.var d, .var "occ"] []

def shows (d s : String) : Formula := .atom "dev_traffic_signal_shows" [.var d, .lit s] []

/-- A traffic signal showing a red indication: circular_red, red_arrow (any direction), flashing_red. -/
def redShown (d : String) : Formula :=
  .or (shows d "circular_red")
    (.or (shows d "flashing_red")
      (.or (shows d "red_arrow(left)")
        (.or (shows d "red_arrow(right)")
          (.or (shows d "red_arrow(straight)") (shows d "red_arrow(u_turn)")))))

/-- s2 (DEF-NRS-484A-260 exclusion): the subject occupies a travel region governed by a device or an
    officer directing it to stop. -/
def deviceGoverned : Formula :=
  .existsRegion (.lit "travel_region") "occ"
    (.and (.atom "rel_occupies" [vSubject, .var "occ"] [])
      (.or (.existsDevice (.lit "stop_sign") "dStop" (governs "dStop"))
        (.or (.existsDevice (.lit "yield_sign") "dYield" (governs "dYield"))
          (.or (.existsDevice (.lit "traffic_signal") "dSignal"
                  (.and (governs "dSignal") (redShown "dSignal")))
            (.or (.existsDevice (.lit "railway_signal_or_gate") "dRail"
                    (.and (governs "dRail")
                      (.or (.atom "dev_railway_signal_or_gate_lights" [.var "dRail", .lit "flashing"] [])
                        (.or (.atom "dev_railway_signal_or_gate_gate" [.var "dRail", .lit "lowering"] [])
                          (.atom "dev_railway_signal_or_gate_gate" [.var "dRail", .lit "down"] [])))))
              (.existsDevice (.lit "human_direction") "dHuman"
                (.and (governs "dHuman")
                  (.and (.atom "dev_human_direction_role" [.var "dHuman", .lit "police_officer"] [])
                    (.atom "dev_human_direction_indication" [.var "dHuman", .lit "stop"] [])))))))))

/-- s3: the onset of a sudden decrease of speed (the node's operationalization). -/
def suddenDecelOnset : Formula :=
  .rises (.cmp (.measure "kin_accel_longitudinal" [vSubject]) .le (.neg pSuddenDecelMin))

/-- s6: a vehicle immediately to the rear in the same lane. -/
def vehicleToRear : Formula :=
  .existsUser "rear"
    (.and (.not (.same (.var "rear") vSubject))
      (.and (.atom "ru_aggregate" [.var "rear", .lit "DEF-NRS-484A-320::vehicle"] [])
        (.and (.atom "rel_ahead_behind_in_lane" [vSubject, .var "rear"] [])
          (.cmp (.measure "rel_surface_gap" [vSubject, .var "rear"]) .le pRearSignalReach))))

/-- Applicability: s2 (trigger): shall not stop; s6 (condition): to the driver of any vehicle immediately to the rear. -/
def applicability : Formula :=
  .and
    (.or (.and haltOnset (.not (.or queueAhead deviceGoverned))) suddenDecelOnset)
    vehicleToRear

/-- s5: the stop-or-slow signal shown. -/
def signalShown : Formula :=
  .or (.atom "sig_brake_lamp" [vSubject] [])
    (.atom "sig_hand_signal" [vSubject, .lit "stop_or_slow"] [])

/-- Obligation: s3 (standard): or suddenly decrease the speed; s5 (obligation): without first giving an appropriate signal -/
def obligation : Formula :=
  .not (.holdsFor .time pStopSignalLeadWindow "subject" (.not signalShown))

def rule : Rule :=
  { id := "NRS_484B_413_3"
    laws := ["NRS-484B-413-3"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "suddenly"
          concepts := ["kin.accel_longitudinal"]
          params := ["p.sudden_decel_min"]
          convention := "a decrease of speed is sudden where the longitudinal deceleration exceeds the comfortable deceleration most drivers use when braking for an expected stop"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_413_3
