/-
  NRS_484B_517 — NRS-484B-517

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (obligation): A person shall not stop, stand or park a vehicle
    s2 (exception): other than a bus
    s3 (condition): in a bus stop,
    s4 (exception): or a taxicab
    s5 (condition): in a taxicab stand,
    s6 (condition): when such stop or stand has been officially designated and appropriately signed,
    s7 (exception): except that the driver of a passenger vehicle
    s8 (standard): may temporarily stop there
    s9 (exception): and for the purpose of and while actually engaged in
    s10 (standard): expeditiously
    s11 (exception): loading or unloading of passengers
    s12 (standard): when such stopping does not interfere with
    s13 (exception): any bus or taxicab
    s14 (exception): waiting to enter or about to enter such zone.

  Elements (span → atoms, derived):
    s1: atoms ['dev.governs', 'dev.human_direction', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.ahead_behind_in_lane', 'rel.occupies', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.travel_region'], derived ['drv.motion.complete_halt']
    s2: atoms ['ru.aggregate=DEF-NRS-484A-030::bus'], derived []
    s3: atoms ['rel.occupies', 'st.curb_zone'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-270::taxicab'], derived []
    s5: atoms ['rel.occupies', 'st.curb_zone'], derived []
    s6: atoms ['rel.occupies', 'st.curb_zone'], derived []
    s7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.truck', 'ru.trailer_or_combination'], derived []
    s9: atoms [], derived ['drv.motion.complete_halt']
    s11: atoms ['sig.door_open'], derived []
    s13: atoms ['ru.aggregate=DEF-NRS-484A-030::bus', 'ru.aggregate=DEF-NRS-484A-270::taxicab'], derived []
    s14: atoms ['rel.occupies', 'st.curb_zone', 'st.region_geometry'], derived ['drv.motion.complete_halt']

  How each is written.
    Binder class (s1, s7): `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    Zone selection (s2–s6), `zoneSel z`: a region z of kind curb_zone (the quantifier's kind) that
      the subject occupies (`rel_occupies`), whose kind attribute is bus_stop while the subject is
      not of DEF-NRS-484A-030::bus, or taxicab_stand while it is not of DEF-NRS-484A-270::taxicab.
      The applicability is `∃ z. zoneSel z`; the obligation re-selects z with the same `zoneSel`
      and states the duty for every such z (`∀ z. zoneSel z → …`), as the record's "wherever".
    Duty (s1): the subject is not halted (`drv_motion_complete_halt`, p.halt_speed_tolerance),
      unless one of the three exceptions holds:
      (a) avoid conflict: some road user o other than the subject is ahead of it in the same lane
          (`rel_ahead_behind_in_lane o subject`) with the gap between bodies (`rel_surface_gap`,
          the distance read) at most p.queue_halt_gap;
      (b) compliance: a region r of kind travel_region the subject occupies is governed
          (`dev_governs d r`) by a stop sign, a yield sign, a traffic signal showing a red or yellow
          indication (circular_red, circular_yellow, red_arrow(dir), yellow_arrow(dir)) or
          flashing_red, a railway signal or gate with lights flashing or its gate not up (written
          as gate lowering, down or raising: the record's "not up" of a gate; a device recorded
          with no gate has no gate to be up or not), or a human direction of role police_officer
          giving the indication stop;
      (c) passenger stop (s7–s14): the subject is not `ru_truck` and not
          `ru_trailer_or_combination`; it is not `drv_motion_parked` (p.halt_speed_tolerance,
          p.standing_min_duration) — s8 "temporarily" and s10 "expeditiously", the record's one
          bound; a door of it is open (`sig_door_open`, any side) at some observation of the same
          halt, before (`since halt (halt ∧ door)`) or after (`until halt (halt ∧ door)`) the
          judged one (s9, s11); and at no observation of the halt up to the judged one
          (`¬ since halt (halt ∧ ∃ w. …)`) is there a road user w other than the subject of
          DEF-NRS-484A-030::bus or DEF-NRS-484A-270::taxicab that does not occupy z, is halted, and
          whose body's ground distance to z (`st_region_geometry_distance`) is at most
          p.zone_entry_wait_reach (s12–s14).
    No choice beyond the record's was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_517

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"
def pStandingMinDuration : Term := .param "p.standing_min_duration"
def pZoneEntryWaitReach : Term := .param "p.zone_entry_wait_reach"

def zeroMetres : Term := .lit Q.zero .metre

def vZ : Arg := .var "z"

def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggBus : String := "DEF-NRS-484A-030::bus"
def aggTaxicab : String := "DEF-NRS-484A-270::taxicab"

/-- Membership of a road user in an admitted aggregate. -/
def member (x : Arg) (agg : String) : Formula := .atom "ru_aggregate" [x, .lit agg] []

/-- `drv.motion.complete_halt` of a road user. -/
def halted (x : Arg) : Formula := .derived "drv_motion_complete_halt" [x] [pHaltSpeedTolerance]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := member vSubject aggVehicle

/-- s2–s6: the curb zone z the subject occupies, a bus stop while the subject is no bus, or a
    taxicab stand while it is no taxicab. -/
def zoneSel : Formula :=
  .and (.atom "rel_occupies" [vSubject, vZ] [])
    (.or (.and (.atom "st_curb_zone_kind" [vZ, .lit "bus_stop"] []) (.not (member vSubject aggBus)))
         (.and (.atom "st_curb_zone_kind" [vZ, .lit "taxicab_stand"] []) (.not (member vSubject aggTaxicab))))

/-- Applicability: s2 (exception): other than a bus; s3 (condition): in a bus stop,; s4 (exception): or a taxicab; s5 (condition): in a taxicab stand,; s6 (condition): when such stop or stand has been officially designated and appropriately signed,; s7 (exception): except that the driver of a passenger vehicle; s9 (exception): and for the purpose of and while actually engaged in; s11 (exception): loading or unloading of passengers; s13 (exception): any bus or taxicab; s14 (exception): waiting to enter or about to enter such zone. -/
def applicability : Formula := .existsRegion (.lit "curb_zone") "z" zoneSel

/-- (a) s1: a halt behind another road user ahead in the same lane, within the queue gap. -/
def avoidConflict : Formula :=
  .existsUser "o"
    (.and (.not (.same (.var "o") vSubject))
      (.and (.atom "rel_ahead_behind_in_lane" [.var "o", vSubject] [])
        (.cmp (.measure "rel_surface_gap" [vSubject, .var "o"]) .le pQueueHaltGap)))

def vD : Arg := .var "d"
def vR : Arg := .var "r"
def governs : Formula := .atom "dev_governs" [vD, vR] []
def shows (i : String) : Formula := .atom "dev_traffic_signal_shows" [vD, .lit i] []

/-- A red or yellow indication, or flashing red. -/
def stopIndication : Formula :=
  [ "circular_yellow", "flashing_red",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)" ].foldl
    (fun acc i => .or acc (shows i)) (shows "circular_red")

/-- (b) s1: a halt in compliance with a device or an officer governing a travel region occupied. -/
def deviceCompliance : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] [])
      (.or (.existsDevice (.lit "stop_sign") "d" governs)
      (.or (.existsDevice (.lit "yield_sign") "d" governs)
      (.or (.existsDevice (.lit "traffic_signal") "d" (.and governs stopIndication))
      (.or (.existsDevice (.lit "railway_signal_or_gate") "d"
              (.and governs
                (.or (.atom "dev_railway_signal_or_gate_lights" [vD, .lit "flashing"] [])
                  (.or (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "lowering"] [])
                    (.or (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "down"] [])
                      (.atom "dev_railway_signal_or_gate_gate" [vD, .lit "raising"] []))))))
           (.existsDevice (.lit "human_direction") "d"
              (.and governs
                (.and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
                  (.atom "dev_human_direction_indication" [vD, .lit "stop"] [])))))))))

/-- s13–s14: a bus or taxicab w, outside z, halted within the waiting reach of z. -/
def waitingToEnter : Formula :=
  .existsUser "w"
    (.and (.not (.same (.var "w") vSubject))
      (.and (.or (member (.var "w") aggBus) (member (.var "w") aggTaxicab))
        (.and (.not (.atom "rel_occupies" [.var "w", vZ] []))
          (.and (halted (.var "w"))
            (.cmp (.measure "st_region_geometry_distance" [.var "w", vZ]) .le pZoneEntryWaitReach)))))

/-- (c) s7–s14: a temporary, expeditious stop of a passenger vehicle for passengers that does not
    interfere with a bus or taxicab waiting to enter z. -/
def passengerStop : Formula :=
  .and (.not (.atom "ru_truck" [vSubject] []))
    (.and (.not (.atom "ru_trailer_or_combination" [vSubject] []))
      (.and (.not (.derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pStandingMinDuration]))
        (.and (.or (.since (halted vSubject) (.and (halted vSubject) (.atom "sig_door_open" [vSubject] [])))
                   (.until (halted vSubject) (.and (halted vSubject) (.atom "sig_door_open" [vSubject] []))))
          (.not (.since (halted vSubject) (.and (halted vSubject) waitingToEnter))))))

/-- Obligation: s1 (obligation): A person shall not stop, stand or park a vehicle; s8 (standard): may temporarily stop there; s10 (standard): expeditiously; s12 (standard): when such stopping does not interfere with -/
def obligation : Formula :=
  .forallRegion (.lit "curb_zone") "z"
    (.implies zoneSel
      (.or (.not (halted vSubject))
        (.or avoidConflict (.or deviceCompliance passengerStop))))

def rule : Rule :=
  { id := "NRS_484B_517"
    laws := ["NRS-484B-517"]
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
      , { standard := "expeditiously"
          concepts := ["drv.motion.parked"]
          params := ["p.standing_min_duration", "p.halt_speed_tolerance"]
          convention := "curbside passenger pick-up dwell: loading or unloading counts as expeditious while the halt has not lasted as long as a passenger pick-up dwell (drv.motion.parked with min_duration p.standing_min_duration); the same bound as the temporary stop it qualifies"
          surrogate := false }
      , { standard := "does not interfere with"
          concepts := ["drv.motion.complete_halt", "rel.occupies", "st.region_geometry"]
          params := ["p.zone_entry_wait_reach", "p.halt_speed_tolerance"]
          convention := "queueing at a curb space: a stop interferes with a bus or taxicab where, at some observation of the stop so far, it stands halted outside the zone within one passenger-car length plus a queue spacing of it (p.zone_entry_wait_reach), the place a vehicle waits to take the space"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_517
