/-
  NRS_484B_510 — NRS-484B-510

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (obligation): A person shall not stop, stand or park a vehicle
    s2 (condition): for any purpose or length of time
    s3 (condition): in any restricted parking zone
    s4 (exception): other than for the purpose to which parking in such zone is restricted,
    s5 (exception): except that a driver of a passenger vehicle
    s6 (standard): may stop temporarily
    s7 (exception): in such zone
    s8 (exception): for the purpose of and while actually engaged in loading or unloading of passengers
    s9 (standard): when such stopping does not interfere with
    s10 (exception): any vehicle which is waiting to enter or about to enter the zone
    s11 (exception): for the purpose of parking in accordance with the purpose to which parking is restricted.

  Elements (span → atoms, derived):
    s1: atoms ['dev.governs', 'dev.human_direction', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.ahead_behind_in_lane', 'rel.occupies', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.travel_region'], derived ['drv.motion.complete_halt']
    s3: atoms ['rel.occupies', 'st.curb_zone'], derived []
    s4: atoms ['dev.zone_sign', 'dev.governs', 'prim.conditions_hold', 'rel.occupies', 'st.travel_region'], derived []
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.truck', 'ru.trailer_or_combination'], derived []
    s7: atoms ['rel.occupies', 'st.curb_zone'], derived []
    s8: atoms ['sig.door_open'], derived ['drv.motion.complete_halt']
    s10: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.curb_zone', 'st.region_geometry'], derived ['drv.motion.complete_halt']
    s11: atoms ['prim.conditions_hold', 'dev.zone_sign', 'dev.governs', 'st.travel_region'], derived []

  How each is written:
    subject: `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    s3 (applicability): some curb_zone region z of kind restricted_parking (`st_curb_zone_kind`) that
      the subject occupies (`rel_occupies`).
    s7 (obligation): the same selection of z re-stated, for every such z (`forallRegion` … `implies`).
    s1: within z, the subject is not halted (`drv_motion_complete_halt` with p.halt_speed_tolerance),
      unless one of (a)–(d):
      (a) avoid conflict: some other road user o (`same` excludes the subject) is ahead of the
          subject in its lane (`rel_ahead_behind_in_lane o subject`) with the gap between the bodies
          (`rel_surface_gap`, distance read) at most p.queue_halt_gap;
      (b) device/officer: a travel region r the subject occupies is governed (`dev_governs`) by a stop
          sign, a yield sign, a traffic signal showing a red or yellow indication (circular_red,
          circular_yellow, red_arrow(*), yellow_arrow(*)) or flashing_red, a railway signal or gate
          with lights flashing or a gate not up (lowering, down or raising: a device with gate
          `none` has no gate and so no gate that is not up), or a police officer indicating stop;
    s4: (c) some zone sign d of kind parking_restricted governing a travel region the subject
          occupies has its conditions holding for the subject (`prim_conditions_hold d subject`);
    s5/s6/s8/s9/s10/s11: (d) the subject is neither a truck nor a trailer or combination; it is not
          parked (`drv_motion_parked`, min_duration p.standing_min_duration — the operationalization
          of "temporarily"); a door of it is open at some observation of the same halt
          (`since halt (halt ∧ door)` or `until halt (halt ∧ door)`: the run of halted observations
          through the judged one, behind or ahead); and at no observation of the halt up to the
          judged one (`not (since halt (halt ∧ W))`) is there a waiting vehicle W: a road user o other
          than the subject, of the aggregate vehicle, not occupying z, halted, whose body's ground
          distance to z (`st_region_geometry_distance`) is at most p.zone_entry_wait_reach, and for
          which the conditions of some parking_restricted zone sign governing a travel region the
          subject occupies hold (`prim_conditions_hold d o`).

  Choices the record left open:
    - s1, "a traffic signal displaying a red or yellow indication or flashing_red": every steady red
      or yellow indication (circular and arrows) and flashing_red; flashing_yellow and
      flashing_yellow_arrow (caution, no halt required) are not read (declared narrowing).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_510

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"
def pStandingMinDuration : Term := .param "p.standing_min_duration"
def pZoneEntryWaitReach : Term := .param "p.zone_entry_wait_reach"

def zeroMetres : Term := .lit Q.zero .metre

def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggVehicle] []

/-- z is a restricted parking curb zone the subject occupies (s3, s7). -/
def inRestrictedZone : Formula :=
  .and (.atom "st_curb_zone_kind" [.var "z", .lit "restricted_parking"] [])
       (.atom "rel_occupies" [vSubject, .var "z"] [])

/-- Road user `who` is halted. -/
def halted (who : String) : Formula :=
  .derived "drv_motion_complete_halt" [.var who] [pHaltSpeedTolerance]

/-- (a) Halt behind other traffic: another road user ahead in the same lane within the queue gap. -/
def behindTraffic : Formula :=
  .existsUser "q"
    (.and (.not (.same (.var "q") vSubject))
      (.and (.atom "rel_ahead_behind_in_lane" [.var "q", vSubject] [])
            (.cmp (.measure "rel_surface_gap" [vSubject, .var "q"]) .le pQueueHaltGap)))

/-- The traffic signal indications read as red or yellow, and flashing red. -/
def stopIndications : List String :=
  [ "circular_red", "circular_yellow", "flashing_red"
  , "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)"
  , "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)" ]

def anyOf : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (anyOf rest)

def governsR (d : String) : Formula := .atom "dev_governs" [.var d, .var "r"] []

/-- (b) In compliance with a device or an officer governing a travel region the subject occupies. -/
def deviceOrOfficer : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
      (anyOf
        [ .existsDevice (.lit "stop_sign") "ds" (governsR "ds")
        , .existsDevice (.lit "yield_sign") "dy" (governsR "dy")
        , .existsDevice (.lit "traffic_signal") "dt"
            (.and (governsR "dt")
              (anyOf (stopIndications.map fun i => .atom "dev_traffic_signal_shows" [.var "dt", .lit i] [])))
        , .existsDevice (.lit "railway_signal_or_gate") "dr"
            (.and (governsR "dr")
              (.or (.atom "dev_railway_signal_or_gate_lights" [.var "dr", .lit "flashing"] [])
                (anyOf (["lowering", "down", "raising"].map fun g =>
                  .atom "dev_railway_signal_or_gate_gate" [.var "dr", .lit g] []))))
        , .existsDevice (.lit "human_direction") "dh"
            (.and (governsR "dh")
              (.and (.atom "dev_human_direction_role" [.var "dh", .lit "police_officer"] [])
                    (.atom "dev_human_direction_indication" [.var "dh", .lit "stop"] []))) ]))

/-- The conditions of some parking_restricted zone sign governing a travel region the subject
    occupies hold for road user `who` (s4 for the subject, s11 for the waiting vehicle). -/
def restrictionMet (d r who : String) : Formula :=
  .existsDevice (.lit "zone_sign") d
    (.and (.atom "dev_zone_sign_kind" [.var d, .lit "parking_restricted"] [])
      (.and (.existsRegion (.lit "travel_region") r
              (.and (.atom "dev_governs" [.var d, .var r] [])
                    (.atom "rel_occupies" [vSubject, .var r] [])))
            (.derived "prim_conditions_hold" [.var d, .var who] [])))

/-- (c) For the purpose to which parking is restricted. -/
def forRestrictedPurpose : Formula := restrictionMet "dz" "rz" "subject"

/-- s10/s11: a vehicle waiting to enter z to park in accordance with the restriction. -/
def waitingVehicle : Formula :=
  .existsUser "o"
    (.and (.not (.same (.var "o") vSubject))
      (.and (.atom "ru_aggregate" [.var "o", aggVehicle] [])
        (.and (.not (.atom "rel_occupies" [.var "o", .var "z"] []))
          (.and (halted "o")
            (.and (.cmp (.measure "st_region_geometry_distance" [.var "o", .var "z"]) .le pZoneEntryWaitReach)
                  (restrictionMet "dw" "rw" "o"))))))

/-- s8: a door of the subject open at some observation of the same halt, behind or ahead. -/
def doorOpenDuringHalt : Formula :=
  let door : Formula := .atom "sig_door_open" [vSubject] []
  .or (.since (halted "subject") (.and (halted "subject") door))
      (.until (halted "subject") (.and (halted "subject") door))

/-- (d) s5–s11: a temporary stop of a passenger vehicle for passengers that interferes with no
    waiting vehicle. -/
def passengerStop : Formula :=
  .and (.not (.atom "ru_truck" [vSubject] []))
    (.and (.not (.atom "ru_trailer_or_combination" [vSubject] []))
      (.and (.not (.derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pStandingMinDuration]))
        (.and doorOpenDuringHalt
              (.not (.since (halted "subject") (.and (halted "subject") waitingVehicle))))))

/-- Applicability: s2 (condition): for any purpose or length of time; s3 (condition): in any restricted parking zone; s4 (exception): other than for the purpose to which parking in such zone is restricted,; s5 (exception): except that a driver of a passenger vehicle; s7 (exception): in such zone; s8 (exception): for the purpose of and while actually engaged in loading or unloading of passengers; s10 (exception): any vehicle which is waiting to enter or about to enter the zone; s11 (exception): for the purpose of parking in accordance with the purpose to which parking is restricted. -/
def applicability : Formula :=
  .existsRegion (.lit "curb_zone") "z" inRestrictedZone

/-- Obligation: s1 (obligation): A person shall not stop, stand or park a vehicle; s6 (standard): may stop temporarily; s9 (standard): when such stopping does not interfere with -/
def obligation : Formula :=
  .forallRegion (.lit "curb_zone") "z"
    (.implies inRestrictedZone
      (.or (.not (halted "subject"))
        (anyOf [behindTraffic, deviceOrOfficer, forRestrictedPurpose, passengerStop])))

def rule : Rule :=
  { id := "NRS_484B_510"
    laws := ["NRS-484B-510"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "temporarily"
          concepts := ["drv.motion.parked"]
          params := ["p.standing_min_duration", "p.halt_speed_tolerance"]
          convention := "curbside passenger pick-up dwell: a stop counts as temporary while it has not lasted as long as a passenger pick-up dwell, i.e. while the subject is not at rest at every observation of a window of length p.standing_min_duration behind the observation (drv.motion.parked)"
          surrogate := false }
      , { standard := "does not interfere with"
          concepts := ["drv.motion.complete_halt", "rel.occupies", "st.region_geometry"]
          params := ["p.zone_entry_wait_reach", "p.halt_speed_tolerance"]
          convention := "queueing at a curb space: a stop interferes with a vehicle where, at some observation of the stop so far, that vehicle stands halted outside the zone within one passenger-car length plus a queue spacing of it (p.zone_entry_wait_reach), the place a vehicle waits to take the space"
          surrogate := false } ]
    residues := ["'For any purpose or length of time' excludes no halt: every halt is within the prohibition whatever its purpose and length, so the duty is the same whether or not these words are read."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s1"
          why := "'A traffic signal displaying a red or yellow indication or flashing_red' is read as a steady red or yellow indication (circular_red, circular_yellow, red_arrow, yellow_arrow) or flashing_red; flashing_yellow and flashing_yellow_arrow, cautionary indications that require no halt, are not read as a device's direction to halt."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_510
