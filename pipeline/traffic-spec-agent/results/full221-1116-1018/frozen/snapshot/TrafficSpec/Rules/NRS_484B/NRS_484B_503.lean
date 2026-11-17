/-
  NRS_484B_503 — NRS-484B-503

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (obligation): A person shall not stop, stand or park a vehicle
    s2 (condition): for any purpose or period of time
    s3 (standard): except for the expeditious
    s4 (exception): loading or unloading of passengers
    s5 (condition): in any place marked as a passenger curb loading zone
    s6 (condition): during hours when the regulations applicable to such passenger curb loading zone are effective.

  Elements (span → atoms, derived):
    s1: atoms ['dev.governs', 'dev.human_direction', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.ahead_behind_in_lane', 'rel.occupies', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.travel_region'], derived ['drv.motion.complete_halt']
    s4: atoms ['sig.door_open'], derived ['drv.motion.complete_halt']
    s5: atoms ['rel.occupies', 'st.curb_zone'], derived []
    s6: atoms ['dev.zone_sign', 'dev.governs', 'prim.conditions_hold', 'rel.occupies', 'st.travel_region'], derived []

  How each is written:
    class: the subject is a member of the admitted aggregate DEF-NRS-484A-320::vehicle (ru_aggregate).
    s5: some region of kind curb_zone that the subject occupies (rel_occupies) and whose kind is
        passenger_loading (st_curb_zone_kind) — `inPassengerZone`.
    s6: every zone sign (dev.zone_sign) of kind parking_restricted that governs (dev_governs) a
        travel region (st.travel_region) the subject occupies (rel_occupies) has its conditions
        holding for the subject now (prim_conditions_hold); with no such sign the forall is vacuous,
        so the marked zone is effective at all hours — `regulationsEffective`.
    applicability: s5 ∧ s6.
    obligation: for every curb_zone region selected again as in the applicability (occupied,
        passenger_loading, regulations effective), the subject is not halted
        (drv.motion.complete_halt with p.halt_speed_tolerance), unless
        (a) some other road user (not `same` as the subject) is ahead of it in the same lane
            (rel_ahead_behind_in_lane other subject) with a body gap (rel_surface_gap, the distance
            read) at most p.queue_halt_gap;
        (b) a travel region the subject occupies is governed by a stop sign, a yield sign, a traffic
            signal showing a red or yellow indication (circular, arrow of any direction) or flashing
            red, a railway signal or gate whose lights are flashing or whose gate is lowering, down
            or raising, or a police officer indicating stop;
        (c) s3/s4: the subject is not parked (drv.motion.parked, p.halt_speed_tolerance,
            p.standing_min_duration) and it has been halted since an observation at which it was
            halted with a door open (`since`), or stays halted until one (`until`).
    s2: residue (the node's).

  Choices the record left open (declared as narrowings on s1):
    - "gate not up" is read as a gate observed lowering, down or raising: a crossing with no gate
      (gate state `none`) does not by itself excuse a halt; only its flashing lights do.
    - "a red or yellow indication" is read as circular_red, circular_yellow, red_arrow(dir) and
      yellow_arrow(dir) for every direction; flashing_yellow and flashing_yellow_arrow are not
      included (permissive indications).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_503

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"
def pStandingMinDuration : Term := .param "p.standing_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

def occupies (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []
def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s5: the subject's footprint overlaps the curb zone `z`, of kind passenger_loading. -/
def inPassengerZone (z : String) : Formula :=
  .and (occupies z) (.atom "st_curb_zone_kind" [.var z, .lit "passenger_loading"] [])

/-- s6: every parking_restricted zone sign governing a travel region the subject occupies has its
    conditions holding now for the subject; none such: effective at all hours. -/
def regulationsEffective : Formula :=
  .forallDevice (.lit "zone_sign") "zs"
    (.implies
      (.and (.atom "dev_zone_sign_kind" [.var "zs", .lit "parking_restricted"] [])
            (.existsRegion (.lit "travel_region") "tr" (.and (occupies "tr") (governs "zs" "tr"))))
      (.derived "prim_conditions_hold" [.var "zs", vSubject] []))

/-- Applicability: s5 and s6 (s2 is a residue; s4 is an exception carried in the obligation). -/
def applicability : Formula :=
  .and (.existsRegion (.lit "curb_zone") "z" (inPassengerZone "z")) regulationsEffective

/-- s1: the subject at rest. -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- (a) a halt behind other traffic in the same lane, within the queue gap. -/
def queueHalt : Formula :=
  .existsUser "o"
    (.and (.not (.same (.var "o") vSubject))
      (.and (.atom "rel_ahead_behind_in_lane" [.var "o", vSubject] [])
            (.cmp (.measure "rel_surface_gap" [vSubject, .var "o"]) .le pQueueHaltGap)))

def dirs : List String := ["left", "right", "straight", "u_turn"]

def anyOf : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (anyOf rest)

/-- A red or yellow indication, or flashing red. -/
def stopIndications : List String :=
  ["circular_red", "circular_yellow", "flashing_red"]
    ++ dirs.map (fun d => s!"red_arrow({d})") ++ dirs.map (fun d => s!"yellow_arrow({d})")

/-- (b) the region `r` (occupied by the subject) is governed by a device or an officer requiring
    the halt. -/
def stopControl (r : String) : Formula :=
  anyOf
    [ .existsDevice (.lit "stop_sign") "ds" (governs "ds" r)
    , .existsDevice (.lit "yield_sign") "dy" (governs "dy" r)
    , .existsDevice (.lit "traffic_signal") "dt"
        (.and (governs "dt" r)
          (anyOf (stopIndications.map fun i => .atom "dev_traffic_signal_shows" [.var "dt", .lit i] [])))
    , .existsDevice (.lit "railway_signal_or_gate") "dg"
        (.and (governs "dg" r)
          (.or (.atom "dev_railway_signal_or_gate_lights" [.var "dg", .lit "flashing"] [])
               (anyOf (["lowering", "down", "raising"].map fun g =>
                  .atom "dev_railway_signal_or_gate_gate" [.var "dg", .lit g] []))))
    , .existsDevice (.lit "human_direction") "dh"
        (.and (governs "dh" r)
          (.and (.atom "dev_human_direction_role" [.var "dh", .lit "police_officer"] [])
                (.atom "dev_human_direction_indication" [.var "dh", .lit "stop"] []))) ]

def deviceHalt : Formula :=
  .existsRegion (.lit "travel_region") "r" (.and (occupies "r") (stopControl "r"))

/-- (c) s3/s4: expeditious loading or unloading of passengers. -/
def haltedDoorOpen : Formula := .and halted (.atom "sig_door_open" [vSubject] [])

def loadingHalt : Formula :=
  .and (.not (.derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pStandingMinDuration]))
       (.or (.since halted haltedDoorOpen) (.until halted haltedDoorOpen))

/-- Obligation: s1 (obligation): A person shall not stop, stand or park a vehicle; s3 (standard): except for the expeditious -/
def obligation : Formula :=
  .forallRegion (.lit "curb_zone") "z"
    (.implies (.and (inPassengerZone "z") regulationsEffective)
      (anyOf [.not halted, queueHalt, deviceHalt, loadingHalt]))

def rule : Rule :=
  { id := "NRS_484B_503"
    laws := ["NRS-484B-503"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "expeditious"
          concepts := ["drv.motion.parked"]
          params := ["p.standing_min_duration", "p.halt_speed_tolerance"]
          convention := "curbside passenger pick-up dwell: a halt counts as expeditious loading or unloading while it has not lasted as long as a passenger pick-up dwell at the curb, i.e. while the subject is not at rest at every observation of a window of length p.standing_min_duration behind the observation (drv.motion.parked)"
          surrogate := false } ]
    residues := ["'For any purpose or period of time' excludes no halt: every halt, whatever its purpose and length, is within the prohibition, so the duty is the same whether or not these words are read."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s1"
          why := "A railway gate 'not up' is read as a gate observed lowering, down or raising; a crossing without a gate (gate state none) excuses a halt only through flashing lights."
          kind := "reading" }
      , { span := "s1"
          why := "A traffic signal's 'red or yellow indication' is read as circular red or yellow and red or yellow arrows of any direction (with flashing red); flashing yellow and flashing yellow arrows, which permit proceeding, are not included."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_503
