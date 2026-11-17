/-
  NRS_484B_627_2 — NRS-484B-627-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    x1 (subject): A person
    x2 (obligation): shall not bring a vehicle to a complete stop
    x3 (condition): upon a roadway
    x4 (standard): so as to impede or block the normal and reasonable movement of
    x5 (condition): traffic
    x6 (standard): unless the stop is necessary
    x7 (exception): for safe operation
    x8 (exception): or in compliance with law.

  Elements (span → atoms, derived):
    x1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    x2: atoms ['drv.motion.complete_halt', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    x3: atoms ['rel.occupies', 'st.roadway'], derived []
    x5: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.ahead_behind_in_lane', 'rel.surface_gap'], derived []
    x7: atoms ['rel.ahead_behind_in_lane', 'rel.surface_gap', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived []
    x8: atoms ['dev.governs', 'dev.stop_sign', 'dev.yield_sign', 'dev.traffic_signal', 'dev.human_direction', 'dev.railway_signal_or_gate', 'rel.occupies', 'st.travel_region'], derived []

  How each is written:
    x1: binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    x3: applicability — the subject occupies (rel_occupies) some region of kind roadway.
    x2: `drv_motion_complete_halt subject p.halt_speed_tolerance` at the judged observation.
    x4/x5: some road user f ≠ subject, member of DEF-NRS-484A-285::traffic, with
        rel_ahead_behind_in_lane(subject, f) (subject ahead of f: f behind it in the same lane),
        the body gap rel_surface_gap(subject, f) (its distance) ≤ p.rear_signal_reach, and f at rest
        (complete_halt, p.halt_speed_tolerance) or kin_accel_longitudinal(f) ≤ −p.speed_decrease_decel_min.
    x6/x7: some road user a ≠ subject with rel_ahead_behind_in_lane(a, subject) and gap ≤
        p.queue_halt_gap; or some road user c ≠ subject with prim_closest_approach_within(subject, c,
        p.conflict_horizon) and prim_closest_approach_distance(subject, c, p.conflict_horizon) ≤
        p.conflict_centre_clearance.
    x8: some travel_region g the subject occupies, governed (dev_governs) by a stop sign, a yield
        sign, a traffic signal showing circular_red, flashing_red or red_arrow(any direction), a
        human_direction device with indication stop and role police_officer, flagger,
        school_crossing_guard or railroad_flagger, or a railway signal/gate with lights flashing or
        a gate lowering, down or raising ("a gate not up": GateState `none` is the absence of a
        gate, not a gate, so it is not read as one not up).
    Obligation: (halt ∧ traffic held behind) → (x7 limbs ∨ x8). The exceptions sit in the
    obligation, as the record's obligation states ("except where … complies").
    No reading choice beyond the record's; no narrowing declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_627_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"
def pRearSignalReach : Term := .param "p.rear_signal_reach"
def pSpeedDecreaseDecelMin : Term := .param "p.speed_decrease_decel_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- Conjunction / disjunction of a list (right-nested). -/
def andAll : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (andAll rest)
def orAll : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (orAll rest)

def v (name : String) : Arg := .var name

/-- x1: the subject is a member of DEF-NRS-484A-320::vehicle. -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- x3: the subject's footprint overlaps a roadway. -/
def applicability : Formula :=
  .existsRegion (.lit "roadway") "rw" (.atom "rel_occupies" [vSubject, v "rw"] [])

/-- x2: the subject is at rest. -/
def subjectHalted : Formula :=
  .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- The body gap between the subject and road user `x` (rel.surface_gap, its distance). -/
def gapTo (x : String) : Term := .measure "rel_surface_gap" [vSubject, v x]

/-- x4 + x5: some traffic road user other than the subject is behind it in the same lane, within
    p.rear_signal_reach of body gap, and is itself at rest (blocked) or decelerating at
    p.speed_decrease_decel_min or more (impeded). -/
def trafficHeldBehind : Formula :=
  .existsUser "f" (andAll
    [ .not (.same (v "f") vSubject)
    , .atom "ru_aggregate" [v "f", .lit "DEF-NRS-484A-285::traffic"] []
    , .atom "rel_ahead_behind_in_lane" [vSubject, v "f"] []
    , .cmp (gapTo "f") .le pRearSignalReach
    , .or (.derived "drv_motion_complete_halt" [v "f"] [pHaltSpeedTolerance])
          (.cmp (.measure "kin_accel_longitudinal" [v "f"]) .le (.neg pSpeedDecreaseDecelMin)) ])

/-- x6 + x7, first limb: a road user ahead of the subject in its lane within p.queue_halt_gap. -/
def haltBehindTraffic : Formula :=
  .existsUser "a" (andAll
    [ .not (.same (v "a") vSubject)
    , .atom "rel_ahead_behind_in_lane" [v "a", vSubject] []
    , .cmp (gapTo "a") .le pQueueHaltGap ])

/-- x6 + x7, second limb: some road user's centre predicted within p.conflict_centre_clearance of
    the subject's within p.conflict_horizon. -/
def predictedConflict : Formula :=
  .existsUser "c" (andAll
    [ .not (.same (v "c") vSubject)
    , .derived "prim_closest_approach_within" [vSubject, v "c"] [pConflictHorizon]
    , .cmp (.quantity "prim_closest_approach_distance" [vSubject, v "c"] [pConflictHorizon]) .le
        pConflictCentreClearance ])

/-- x8: a control requiring a halt governs a travel region the subject occupies. -/
def haltRequiredByControl : Formula :=
  .existsRegion (.lit "travel_region") "g" (.and
    (.atom "rel_occupies" [vSubject, v "g"] [])
    (orAll
      [ .existsDevice (.lit "stop_sign") "ds" (.atom "dev_governs" [v "ds", v "g"] [])
      , .existsDevice (.lit "yield_sign") "dy" (.atom "dev_governs" [v "dy", v "g"] [])
      , .existsDevice (.lit "traffic_signal") "dt" (.and
          (.atom "dev_governs" [v "dt", v "g"] [])
          (orAll ((["circular_red", "flashing_red", "red_arrow(left)", "red_arrow(right)",
                    "red_arrow(straight)", "red_arrow(u_turn)"]).map fun i =>
            .atom "dev_traffic_signal_shows" [v "dt", .lit i] [])))
      , .existsDevice (.lit "human_direction") "dh" (andAll
          [ .atom "dev_governs" [v "dh", v "g"] []
          , .atom "dev_human_direction_indication" [v "dh", .lit "stop"] []
          , orAll ((["police_officer", "flagger", "school_crossing_guard", "railroad_flagger"]).map fun r =>
              .atom "dev_human_direction_role" [v "dh", .lit r] []) ])
      , .existsDevice (.lit "railway_signal_or_gate") "dr" (.and
          (.atom "dev_governs" [v "dr", v "g"] [])
          (.or (.atom "dev_railway_signal_or_gate_lights" [v "dr", .lit "flashing"] [])
               (orAll ((["lowering", "down", "raising"]).map fun gs =>
                  .atom "dev_railway_signal_or_gate_gate" [v "dr", .lit gs] [])))) ]))

/-- x2, x4, x6: a halt that holds traffic behind is a violation unless it is necessary for safe
    operation (x7) or in compliance with law (x8). -/
def obligation : Formula :=
  .implies (.and subjectHalted trafficHeldBehind)
    (orAll [haltBehindTraffic, predictedConflict, haltRequiredByControl])

def rule : Rule :=
  { id := "NRS_484B_627_2"
    laws := ["NRS-484B-627-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "so as to impede or block the normal and reasonable movement of traffic"
          concepts := ["drv.motion.complete_halt", "kin.accel_longitudinal", "rel.ahead_behind_in_lane", "rel.surface_gap"]
          params := ["p.rear_signal_reach", "p.speed_decrease_decel_min", "p.halt_speed_tolerance"]
          convention := "Queue convention: the halt impedes or blocks traffic where a traffic road user is behind the halted subject in the same lane with the gap between bodies within p.rear_signal_reach (immediately to the rear) and that road user is itself at rest (complete halt within p.halt_speed_tolerance: blocked) or decelerating at p.speed_decrease_decel_min or more (impeded)."
          surrogate := false }
      , { standard := "the stop is necessary for safe operation"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.ahead_behind_in_lane", "rel.surface_gap"]
          params := ["p.queue_halt_gap", "p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "Queue spacing and the traffic-conflict technique: the stop is necessary where a road user is ahead of the subject in the same lane with the body gap within p.queue_halt_gap (the subject halts behind other traffic), or where some road user's centre is predicted to come within p.conflict_centre_clearance of the subject's within p.conflict_horizon."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_627_2
