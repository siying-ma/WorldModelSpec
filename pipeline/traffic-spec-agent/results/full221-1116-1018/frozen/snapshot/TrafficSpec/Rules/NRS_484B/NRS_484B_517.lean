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

  How each is written:
    subject class: `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    s2–s6 (applicability `selZone z`): a curb zone z (`existsRegion curb_zone`) the subject occupies
      (`rel_occupies`) that is of kind bus_stop while the subject is not a bus
      (`ru_aggregate … DEF-NRS-484A-030::bus` false), or of kind taxicab_stand while it is not a
      taxicab (`ru_aggregate … DEF-NRS-484A-270::taxicab` false); `st_curb_zone_kind` reads the kind.
    obligation: for every curb zone z with the same selection `selZone z` (re-bound, per rule 3c),
      the subject is not halted (`drv_motion_complete_halt` with p.halt_speed_tolerance), unless
      (a) queue: some road user w ≠ subject ahead of it in the same lane
          (`rel_ahead_behind_in_lane w subject`, w ahead of subject) with a body gap
          (`rel_surface_gap`, the distance) ≤ p.queue_halt_gap;
      (b) device or officer: some travel region r the subject occupies is governed (`dev_governs`)
          by a stop sign, a yield sign, a traffic signal showing a red or yellow indication or
          flashing_red, a railway signal or gate with lights flashing or a gate not up, or a
          human director of role police_officer giving the indication stop;
      (c) passenger stop (s7–s14): the subject is a vehicle, not a truck nor a trailer or
          combination; not parked (`drv_motion_parked` with p.halt_speed_tolerance,
          p.standing_min_duration: s8 "temporarily", s10 "expeditiously"); a door open at some
          observation of the same halt (`since`/`until` over the halt, s9/s11); and not, at any
          observation of the halt up to now (`since` over the halt, s12), a road user w ≠ subject
          that is a bus or a taxicab (the two aggregates, s13), outside z (`rel_occupies` false),
          within p.zone_entry_wait_reach of z (`st_region_geometry_distance`), and halted there
          (waiting) or staying outside z within that reach until it occupies z (strong `until`:
          about to enter) (s14).

  Choices the record left open (declared as narrowings):
    s1: "a red or yellow indication" is read as the steady red and yellow indications, circular
      and arrow (circular_red, circular_yellow, red_arrow(dir), yellow_arrow(dir)), with the
      record's flashing_red; flashing_yellow and flashing_yellow_arrow, which permit proceeding
      with caution, are not taken as an indication a halt complies with.
    s1: "a gate not up" is read as a gate in the states lowering, down or raising: the state none
      (no gate at the device) is no gate, so not a gate that is not up.

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

def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggBus : String := "DEF-NRS-484A-030::bus"
def aggTaxicab : String := "DEF-NRS-484A-270::taxicab"

def isAgg (x : Arg) (agg : String) : Formula := .atom "ru_aggregate" [x, .lit agg] []

/-- drv.motion.complete_halt of a road user, with the halt speed tolerance. -/
def halted (x : Arg) : Formula := .derived "drv_motion_complete_halt" [x] [pHaltSpeedTolerance]

def occupies (x : Arg) (r : String) : Formula := .atom "rel_occupies" [x, .var r] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isAgg vSubject aggVehicle

/-- s2–s6: the curb zone z the subject occupies, of kind bus_stop while the subject is not a bus,
    or of kind taxicab_stand while it is not a taxicab. -/
def selZone (z : String) : Formula :=
  .and (occupies vSubject z)
    (.or (.and (.atom "st_curb_zone_kind" [.var z, .lit "bus_stop"] []) (.not (isAgg vSubject aggBus)))
         (.and (.atom "st_curb_zone_kind" [.var z, .lit "taxicab_stand"] []) (.not (isAgg vSubject aggTaxicab))))

/-- Applicability: s2 (exception): other than a bus; s3 (condition): in a bus stop,; s4 (exception): or a taxicab; s5 (condition): in a taxicab stand,; s6 (condition): when such stop or stand has been officially designated and appropriately signed. -/
def applicability : Formula := .existsRegion (.lit "curb_zone") "z" (selZone "z")

/-- (a) s1: a halt behind a road user ahead in the same lane within the queue gap. -/
def queueHalt : Formula :=
  .existsUser "wq"
    (.and (.not (.same (.var "wq") vSubject))
      (.and (.atom "rel_ahead_behind_in_lane" [.var "wq", vSubject] [])
        (.cmp (.measure "rel_surface_gap" [vSubject, .var "wq"]) .le pQueueHaltGap)))

def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []

def shows (d : String) (i : String) : Formula := .atom "dev_traffic_signal_shows" [.var d, .lit i] []

/-- The red or yellow indications (steady; circular and arrow) and flashing_red. -/
def redOrYellow (d : String) : Formula :=
  [ "circular_yellow", "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)"
  , "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)"
  , "flashing_red" ].foldl (fun acc i => .or acc (shows d i)) (shows d "circular_red")

def railActive (d : String) : Formula :=
  .or (.atom "dev_railway_signal_or_gate_lights" [.var d, .lit "flashing"] [])
    (.or (.atom "dev_railway_signal_or_gate_gate" [.var d, .lit "lowering"] [])
      (.or (.atom "dev_railway_signal_or_gate_gate" [.var d, .lit "down"] [])
           (.atom "dev_railway_signal_or_gate_gate" [.var d, .lit "raising"] [])))

def officerStop (d : String) : Formula :=
  .and (.atom "dev_human_direction_role" [.var d, .lit "police_officer"] [])
       (.atom "dev_human_direction_indication" [.var d, .lit "stop"] [])

/-- (b) s1: a halt in compliance with a device or an officer governing a travel region the subject occupies. -/
def deviceHalt : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (occupies vSubject "r")
      (.or (.existsDevice (.lit "stop_sign") "ds" (governs "ds" "r"))
        (.or (.existsDevice (.lit "yield_sign") "dy" (governs "dy" "r"))
          (.or (.existsDevice (.lit "traffic_signal") "dt" (.and (governs "dt" "r") (redOrYellow "dt")))
            (.or (.existsDevice (.lit "railway_signal_or_gate") "dr" (.and (governs "dr" "r") (railActive "dr")))
                 (.existsDevice (.lit "human_direction") "dh" (.and (governs "dh" "r") (officerStop "dh"))))))))

/-- s7: a passenger vehicle: a vehicle neither a truck nor a trailer or combination. -/
def passengerVehicle : Formula :=
  .and (isAgg vSubject aggVehicle)
    (.and (.not (.atom "ru_truck" [vSubject] [])) (.not (.atom "ru_trailer_or_combination" [vSubject] [])))

/-- s8, s10: temporary and expeditious: not parked for the passenger pick-up dwell. -/
def notParked : Formula :=
  .not (.derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pStandingMinDuration])

/-- s9, s11: a door of the subject open at some observation of the same halt, before or after. -/
def doorDuringHalt : Formula :=
  let φ : Formula := halted vSubject
  let ψ : Formula := .and (halted vSubject) (.atom "sig_door_open" [vSubject] [])
  .or (.since φ ψ) (.until φ ψ)

/-- s14: w outside z within the waiting reach of it. -/
def nearOutside (w z : String) : Formula :=
  .and (.not (occupies (.var w) z))
    (.cmp (.measure "st_region_geometry_distance" [.var w, .var z]) .le pZoneEntryWaitReach)

/-- s12–s14: a bus or taxicab waiting to enter or about to enter z, at this observation. -/
def interferes (z : String) : Formula :=
  .existsUser "wb"
    (.and (.not (.same (.var "wb") vSubject))
      (.and (.or (isAgg (.var "wb") aggBus) (isAgg (.var "wb") aggTaxicab))
        (.and (nearOutside "wb" z)
          (.or (halted (.var "wb"))
               (.until (nearOutside "wb" z) (occupies (.var "wb") z))))))

/-- (c) s7–s14: the temporary, expeditious stop of a passenger vehicle loading or unloading passengers,
    interfering with no bus or taxicab at any observation of the halt so far. -/
def passengerStop (z : String) : Formula :=
  .and passengerVehicle
    (.and notParked
      (.and doorDuringHalt
        (.not (.since (halted vSubject) (.and (halted vSubject) (interferes z))))))

/-- Obligation: s1 (obligation): A person shall not stop, stand or park a vehicle; s8 (standard): may temporarily stop there; s10 (standard): expeditiously; s12 (standard): when such stopping does not interfere with -/
def obligation : Formula :=
  .forallRegion (.lit "curb_zone") "z"
    (.implies (selZone "z")
      (.or (.not (halted vSubject))
        (.or queueHalt (.or deviceHalt (passengerStop "z")))))

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
          convention := "queueing at a curb space: a stop interferes with a bus or taxicab where, at some observation of the stop so far, it is outside the zone within one passenger-car length plus a queue spacing of it (p.zone_entry_wait_reach), the place a vehicle waits to take the space, and is halted there or stays there until it comes onto the zone"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s1"
          why := "'a traffic signal displaying a red or yellow indication': read as the steady red and yellow indications, circular and arrow (circular_red, circular_yellow, red_arrow(dir), yellow_arrow(dir)), with the record's flashing_red; flashing_yellow and flashing_yellow_arrow, which let traffic proceed with caution, are not taken as an indication a halt complies with"
          kind := "reading" }
      , { span := "s1"
          why := "'a railway signal or gate with ... gate not up': read as a gate in the state lowering, down or raising; the state none (the device has no gate) is not a gate that is not up"
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_517
