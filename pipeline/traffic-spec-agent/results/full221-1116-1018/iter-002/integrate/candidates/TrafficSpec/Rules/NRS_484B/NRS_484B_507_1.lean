/-
  NRS_484B_507_1 — NRS-484B-507-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (obligation): A person shall not stop, stand or park a vehicle
    s2 (condition): for any purpose or length of time
    s3 (standard): other than for the expeditious
    s4 (exception): unloading and delivery or pickup and loading of materials
    s5 (condition): in any place marked as a freight curb loading zone
    s6 (condition): during hours when the provisions applicable to such zones are in effect.
    s7 (exception): The driver of a vehicle
    s8 (standard): may stop temporarily
    s9 (exception): at a place marked as a freight curb loading zone
    s10 (exception): for the purpose of and while actually engaged in loading or unloading passengers,
    s11 (standard): when such stopping does not interfere with
    s12 (exception): any motor vehicle used for the transportation of materials
    s13 (exception): which is waiting to enter or about to enter such zone.

  How each is written:
    s1/s7  the subject's class is ru_aggregate DEF-NRS-484A-320::vehicle (`clsSubject`); the halt is
           drv.motion.complete_halt with p.halt_speed_tolerance (`halted`). The halt's exclusions:
           (a) `behindTraffic` — another road user y ahead of the subject in the same lane
               (rel_ahead_behind_in_lane y subject) with the body gap rel_surface_gap (distance read,
               no component) at most p.queue_halt_gap;
           (b) `complianceWithControl` — a travel region the subject occupies is governed by a stop
               sign, a yield sign, a traffic signal showing circular_red, circular_yellow or
               flashing_red, a railway signal or gate whose lights are flashing or whose gate is not
               up, or a human director in role police_officer indicating stop.
    s5/s9  a curb zone z (existsRegion curb_zone) of kind freight_loading the subject occupies.
    s6     `provisionsInEffect`: every zone sign of kind parking_restricted that governs a travel
           region the subject occupies has prim_conditions_hold for the subject; no such sign — the
           zone is in effect at all hours (the forall is vacuous).
    s3/s4  `materialsLoading`: the subject is ru_truck or ru_commercial_motor_vehicle, it is not
           drv.motion.parked over p.commercial_loading_max_halt, and a door is open during the halt.
    s8/s10 `passengerStop`: not drv.motion.parked over p.standing_min_duration, a door open during
           the halt, and no interference (s11).
           "A door open at some observation of the same halt, before or after the observation"
           (`doorDuringHalt`) is `since halted (halted ∧ door)` (back to a door-open observation
           with the halt unbroken) or `until halted (halted ∧ door)` (forward likewise).
    s11-13 `waitingGoodsVehicle z`: a road user w other than the subject, of the aggregate
           DEF-NRS-484A-130::motor_vehicle and ru_truck, not occupying z, halted, whose ground
           distance to z (st_region_geometry_distance) is at most p.zone_entry_wait_reach;
           "at no observation of the halt up to the judged one" is
           `not (since halted (halted ∧ waitingGoodsVehicle z))`.
    The obligation re-selects z with the applicability's whole selection (occupied, freight_loading,
    provisions in effect) and requires, for every such z, halted → (a) ∨ (b) ∨ (c) ∨ (d).

  Choices the record left open:
    - s1 (narrowing, reading): "a traffic signal displaying a red or yellow indication or
      flashing_red" is read as the circular indications circular_red and circular_yellow and
      flashing_red; a red or yellow arrow, which controls only the movement it points to, is not
      read as a halt in compliance with the signal.
    - "gate not up" is written as the gate attribute not `up`, as the record states it.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_507_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables. -/
def vZ : Arg := .var "z"      -- the freight curb zone
def vZS : Arg := .var "zs"    -- a zone sign
def vZR : Arg := .var "zr"    -- the travel region a zone sign governs
def vCR : Arg := .var "cr"    -- a travel region the subject occupies (control devices)
def vCD : Arg := .var "cd"    -- a control device
def vY : Arg := .var "y"      -- a road user ahead in the lane
def vW : Arg := .var "w"      -- a goods vehicle waiting to enter

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCommercialLoadingMaxHalt : Term := .param "p.commercial_loading_max_halt"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"
def pStandingMinDuration : Term := .param "p.standing_min_duration"
def pZoneEntryWaitReach : Term := .param "p.zone_entry_wait_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- A road user at rest (drv.motion.complete_halt). -/
def halted (x : Arg) : Formula := .derived "drv_motion_complete_halt" [x] [pHaltSpeedTolerance]

/-- The subject parked over a window of length `d` (drv.motion.parked). -/
def parkedFor (d : Term) : Formula := .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, d]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s6: every parking_restricted zone sign governing a travel region the subject occupies has its
    conditions holding for the subject. -/
def provisionsInEffect : Formula :=
  .forallDevice (.lit "zone_sign") "zs"
    (.implies
      (.and (.atom "dev_zone_sign_kind" [vZS, .lit "parking_restricted"] [])
        (.existsRegion (.lit "travel_region") "zr"
          (.and (.atom "rel_occupies" [vSubject, vZR] []) (.atom "dev_governs" [vZS, vZR] []))))
      (.derived "prim_conditions_hold" [vZS, vSubject] []))

/-- s5/s9 with s6: the region `z` is a freight curb loading zone the subject occupies, in effect. -/
def freightZoneInEffect : Formula :=
  .and (.atom "rel_occupies" [vSubject, vZ] [])
    (.and (.atom "st_curb_zone_kind" [vZ, .lit "freight_loading"] []) provisionsInEffect)

/-- Applicability: s5, s6 (s2 is a residue; s4, s7, s9, s10, s12, s13 are the obligation's exceptions). -/
def applicability : Formula := .existsRegion (.lit "curb_zone") "z" freightZoneInEffect

/-- s1 (a): a halt behind other traffic in the lane. -/
def behindTraffic : Formula :=
  .existsUser "y"
    (.and (.not (.same vY vSubject))
      (.and (.atom "rel_ahead_behind_in_lane" [vY, vSubject] [])
        (.cmp (.measure "rel_surface_gap" [vSubject, vY]) .le pQueueHaltGap)))

/-- The control device `cd` governs the travel region `cr`. -/
def governsCR : Formula := .atom "dev_governs" [vCD, vCR] []

/-- s1 (b): a halt in compliance with a device or an officer governing a travel region occupied. -/
def complianceWithControl : Formula :=
  .existsRegion (.lit "travel_region") "cr"
    (.and (.atom "rel_occupies" [vSubject, vCR] [])
      (.or (.existsDevice (.lit "stop_sign") "cd" governsCR)
      (.or (.existsDevice (.lit "yield_sign") "cd" governsCR)
      (.or (.existsDevice (.lit "traffic_signal") "cd"
              (.and governsCR
                (.or (.atom "dev_traffic_signal_shows" [vCD, .lit "circular_red"] [])
                (.or (.atom "dev_traffic_signal_shows" [vCD, .lit "circular_yellow"] [])
                     (.atom "dev_traffic_signal_shows" [vCD, .lit "flashing_red"] [])))))
      (.or (.existsDevice (.lit "railway_signal_or_gate") "cd"
              (.and governsCR
                (.or (.atom "dev_railway_signal_or_gate_lights" [vCD, .lit "flashing"] [])
                     (.not (.atom "dev_railway_signal_or_gate_gate" [vCD, .lit "up"] [])))))
           (.existsDevice (.lit "human_direction") "cd"
              (.and governsCR
                (.and (.atom "dev_human_direction_role" [vCD, .lit "police_officer"] [])
                      (.atom "dev_human_direction_indication" [vCD, .lit "stop"] [])))))))))

/-- s4/s10: a door of the subject open at some observation of the same halt, before or after. -/
def doorDuringHalt : Formula :=
  .or (.since (halted vSubject) (.and (halted vSubject) (.atom "sig_door_open" [vSubject] [])))
      (.until (halted vSubject) (.and (halted vSubject) (.atom "sig_door_open" [vSubject] [])))

/-- s3/s4: the expeditious loading or unloading of materials. -/
def materialsLoading : Formula :=
  .and (.or (.atom "ru_truck" [vSubject] []) (.atom "ru_commercial_motor_vehicle" [vSubject] []))
    (.and (.not (parkedFor pCommercialLoadingMaxHalt)) doorDuringHalt)

/-- s11–s13: a goods motor vehicle halted outside `z` within the waiting reach of it. -/
def waitingGoodsVehicle : Formula :=
  .existsUser "w"
    (.and (.not (.same vW vSubject))
    (.and (.atom "ru_aggregate" [vW, .lit "DEF-NRS-484A-130::motor_vehicle"] [])
    (.and (.atom "ru_truck" [vW] [])
    (.and (.not (.atom "rel_occupies" [vW, vZ] []))
    (.and (halted vW)
          (.cmp (.measure "st_region_geometry_distance" [vW, vZ]) .le pZoneEntryWaitReach))))))

/-- s8/s10/s11: a temporary stop for passengers that interferes with no waiting goods vehicle. -/
def passengerStop : Formula :=
  .and (.not (parkedFor pStandingMinDuration))
    (.and doorDuringHalt
      (.not (.since (halted vSubject) (.and (halted vSubject) waitingGoodsVehicle))))

/-- Obligation: s1 with its exclusions, s3/s4 and s8/s10/s11–s13, at every freight zone selected. -/
def obligation : Formula :=
  .forallRegion (.lit "curb_zone") "z"
    (.implies freightZoneInEffect
      (.implies (halted vSubject)
        (.or behindTraffic
        (.or complianceWithControl
        (.or materialsLoading passengerStop)))))

def rule : Rule :=
  { id := "NRS_484B_507_1"
    laws := ["NRS-484B-507-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "expeditious"
          concepts := ["drv.motion.parked"]
          params := ["p.commercial_loading_max_halt", "p.halt_speed_tolerance"]
          convention := "commercial loading zone time limit: a halt counts as expeditious loading or unloading of materials while it has not lasted as long as the thirty-minute limit common to commercial loading zones, i.e. while the subject is not at rest at every observation of a window of length p.commercial_loading_max_halt behind the observation (drv.motion.parked)"
          surrogate := false }
      , { standard := "temporarily"
          concepts := ["drv.motion.parked"]
          params := ["p.standing_min_duration", "p.halt_speed_tolerance"]
          convention := "curbside passenger pick-up dwell: a stop counts as temporary while it has not lasted as long as a passenger pick-up dwell, i.e. while the subject is not at rest at every observation of a window of length p.standing_min_duration behind the observation (drv.motion.parked)"
          surrogate := false }
      , { standard := "does not interfere with"
          concepts := ["drv.motion.complete_halt", "rel.occupies", "st.region_geometry"]
          params := ["p.zone_entry_wait_reach", "p.halt_speed_tolerance"]
          convention := "queueing at a curb space: a stop interferes with a goods vehicle where, at some observation of the stop so far, that vehicle stands halted outside the zone within one passenger-car length plus a queue spacing of it (p.zone_entry_wait_reach), the place a vehicle waits to take the space"
          surrogate := false } ]
    residues := ["'For any purpose or length of time' excludes no halt: every halt is within the prohibition whatever its purpose and length, so the duty is the same whether or not these words are read."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s1"
          why := "'A traffic signal displaying a red or yellow indication or flashing_red' is read as the circular indications circular_red and circular_yellow and flashing_red; a red or yellow arrow, which controls only the movement it points to, is not read as requiring the halt."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_507_1
