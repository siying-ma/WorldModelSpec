/-
  LVMC_11_52_030_A — LVMC-11-52-030-A

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The parking of vehicles is prohibited or restricted in certain zones as set forth in this Section.
    s2 (condition): The location of such zones shall be established by posting appropriate signage or other durable markings, by painting curbs or the edges of road surfaces in accordance with the colors listed below, or by a combination thereof:
    s3 (obligation): Red indicates no stopping, standing or parking,
    s4 (condition): whether or not the vehicle is attended and whether or not the engine or motor is running,
    s5 (boilerplate): subject to the following:
    s6 (boilerplate): (1) Except as provided in this Subsection,
    s7 (condition): a curb or road surface edge which is painted red indicates no parking,
    s8 (condition): whether or not accompanied by signage to that effect.
    s9 (exception): (2) When the location is accompanied by signage which indicates that parking is limited to tour buses, shuttle buses and limos,
    s10 (exception): those vehicles may park for a period up to thirty minutes for the loading or unloading of passengers. (3)
    s11 (exception): When the location is accompanied by signage which indicates that parking is limited to RTC buses,
    s12 (exception): those vehicles may park for a period up to thirty minutes for the loading or unloading of passengers. (4)
    s13 (exception): Armored cars and emergency vehicles may park at such locations
    s14 (exception): for the period necessary to conduct their business,
    s15 (exception): whether or not there is accompanying signage so indicating.
    s16 (exception): (5) At locations where a drop box for U.S. mail is adjacent to a curb or road surface painted red,
    s17 (exception): a person may stop
    s18 (standard): for the period of time necessary to expeditiously deposit mail in such a drop box.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.curb_zone', 'rel.occupies'], derived []
    s3: atoms ['st.curb_zone', 'rel.occupies', 'rel.ahead_behind_in_lane', 'rel.surface_gap', 'dev.human_direction', 'dev.traffic_signal', 'dev.stop_sign', 'dev.governs', 'st.travel_region'], derived ['drv.motion.complete_halt']
    s7: atoms ['st.curb_zone', 'rel.occupies'], derived []
    s9: atoms ['st.curb_zone', 'rel.occupies', 'ru.aggregate=DEF-LVMC-11-02-150::tour_bus', 'ru.aggregate=DEF-LVMC-11-02-150::shuttle_bus', 'ru.aggregate=DEF-LVMC-11-02-090::limo'], derived []
    s10: atoms ['rel.occupies'], derived ['drv.motion.complete_halt']
    s11: atoms ['st.curb_zone', 'rel.occupies', 'ru.aggregate=DEF-LVMC-11-02-120::rtc_bus'], derived []
    s12: atoms ['rel.occupies'], derived ['drv.motion.complete_halt']
    s13: atoms ['ru.official_vehicle', 'ru.emergency_vehicle'], derived ['drv.motion.complete_halt']
    s14: atoms [], derived ['drv.motion.complete_halt']
    s16: atoms ['st.obstruction', 'st.region_geometry'], derived []
    s17: atoms [], derived ['drv.motion.complete_halt']

  Literals the text states (each written through its Units constructor):
    s10: 30 min — thirty minutes
    s12: 30 min — thirty minutes

  How each is written:
    s1  — binder class: `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
    s2, s7 — applicability binds a region `z` of kind `curb_zone` (the quantifier's kind) with
          `st_curb_zone_colour(z, red)` and `rel_occupies(subject, z)`.
    s3  — obligation: `drv_motion_complete_halt(subject; p.halt_speed_tolerance)` implies the
          definition of stopping's exclusions: some other road user `u` with
          `rel_ahead_behind_in_lane(u, subject)` (u ahead of subject in a shared lane) and
          `rel_surface_gap(subject, u) ≤ p.queue_halt_gap`; or a travel region `r`
          (`travel_region` quantifier) the subject occupies, governed (`dev_governs d r`) by a
          `human_direction` device of role police_officer with indication stop, a
          `traffic_signal` showing circular_red, red_arrow(left|right|straight|u_turn) or
          flashing_red, or a `stop_sign`. The obligation does not name `z`: the halt it bars is
          the subject's halt at the judged observation, at which the applicability already
          places the subject in the red zone.
    s9/s10 — exception (2): the subject is in one of the three aggregates (tour_bus,
          shuttle_bus, limo), `st_curb_zone_kind(z, tour_bus_loading)`, the subject is at rest,
          and `sinceRise(complete_halt(subject) ∧ rel_occupies(subject, z)) ≤ 30 min`.
    s11/s12 — exception (3): the same with `DEF-LVMC-11-02-120::rtc_bus` and kind bus_stop.
    s13/s14 — exception (4): `ru_official_vehicle(subject) ∧ ru_official_vehicle_kind(subject,
          armored_car)` or `ru_emergency_vehicle(subject)`, at any halt length (the node's
          applicability states no halt test for it).
    s16/s17/s18 — exception (5): some `obstruction` region `o` with
          `st_obstruction_kind(o, mail_drop_box)` and `st_region_geometry_distance(subject, o) ≤
          p.mail_drop_box_reach`, the subject at rest, and the time since it came to rest in `z`
          at most `p.mail_deposit_max_halt` (the operationalization of s18).
    Choice: in exceptions (2), (3) and (5) the halt-duration test is conjoined with the
          subject being at rest now (`complete_halt`, the halt s10, s12 and s17 claim): "the
          time since the subject came to rest" speaks of the current halt. Where the subject is
          not at rest the obligation holds whatever the exception says, so this decides only
          not-applicable against compliant, never the duty; it keeps a stale `sinceRise` of an
          earlier halt, or an onset never seen, from deciding the exception for a moving vehicle.
    Residues s4, s8, s15 are the node's.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_52_030_A

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pMailDepositMaxHalt : Term := .param "p.mail_deposit_max_halt"
def pMailDropBoxReach : Term := .param "p.mail_drop_box_reach"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- s10, s12: "thirty minutes". -/
def thirtyMinutes : Term := .lit (Units.minutes 30) .second

def vZ : Arg := .var "z"
def vO : Arg := .var "o"
def vR : Arg := .var "r"
def vD : Arg := .var "d"
def vU : Arg := .var "u"

def agg (id : String) : Formula := .atom "ru_aggregate" [vSubject, .lit id] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := agg "DEF-NRS-484A-320::vehicle"

/-- The subject at rest at the observation (drv.motion.complete_halt). -/
def halted : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- The subject occupies the zone `z`. -/
def inZone : Formula := .atom "rel_occupies" [vSubject, vZ] []

/-- Seconds since the subject came to rest in `z` (s10, s12, s18). -/
def restInZone : Term := .sinceRise (.and halted inZone)

/-- s9/s10: tour buses, shuttle buses and limos in a tour-bus loading zone, up to thirty minutes. -/
def excTourBus : Formula :=
  .and (.or (agg "DEF-LVMC-11-02-150::tour_bus")
          (.or (agg "DEF-LVMC-11-02-150::shuttle_bus") (agg "DEF-LVMC-11-02-090::limo")))
    (.and (.atom "st_curb_zone_kind" [vZ, .lit "tour_bus_loading"] [])
      (.and halted (.cmp restInZone .le thirtyMinutes)))

/-- s11/s12: RTC buses in a bus-stop zone, up to thirty minutes. -/
def excRtcBus : Formula :=
  .and (agg "DEF-LVMC-11-02-120::rtc_bus")
    (.and (.atom "st_curb_zone_kind" [vZ, .lit "bus_stop"] [])
      (.and halted (.cmp restInZone .le thirtyMinutes)))

/-- s13/s14: armored cars and emergency vehicles, for any period. -/
def excArmoredOrEmergency : Formula :=
  .or (.and (.atom "ru_official_vehicle" [vSubject] [])
            (.atom "ru_official_vehicle_kind" [vSubject, .lit "armored_car"] []))
      (.atom "ru_emergency_vehicle" [vSubject] [])

/-- s16/s17/s18: a halt beside a mail drop box, for the time an expeditious deposit takes. -/
def excMailDropBox : Formula :=
  .and (.existsRegion (.lit "obstruction") "o"
          (.and (.atom "st_obstruction_kind" [vO, .lit "mail_drop_box"] [])
                (.cmp (.measure "st_region_geometry_distance" [vSubject, vO]) .le pMailDropBoxReach)))
    (.and halted (.cmp restInZone .le pMailDepositMaxHalt))

/-- Applicability: s2 (condition): The location of such zones shall be established by posting appropriate signage or other durable markings, by painting curbs or the edges of road surfaces in accordance with the colors listed below, or by a combination thereof:; s4 (condition): whether or not the vehicle is attended and whether or not the engine or motor is running,; s7 (condition): a curb or road surface edge which is painted red indicates no parking,; s8 (condition): whether or not accompanied by signage to that effect.; s9 (exception): (2) When the location is accompanied by signage which indicates that parking is limited to tour buses, shuttle buses and limos,; s10 (exception): those vehicles may park for a period up to thirty minutes for the loading or unloading of passengers. (3); s11 (exception): When the location is accompanied by signage which indicates that parking is limited to RTC buses,; s12 (exception): those vehicles may park for a period up to thirty minutes for the loading or unloading of passengers. (4); s13 (exception): Armored cars and emergency vehicles may park at such locations; s14 (exception): for the period necessary to conduct their business,; s15 (exception): whether or not there is accompanying signage so indicating.; s16 (exception): (5) At locations where a drop box for U.S. mail is adjacent to a curb or road surface painted red,; s17 (exception): a person may stop -/
def applicability : Formula :=
  .existsRegion (.lit "curb_zone") "z"
    (.and (.atom "st_curb_zone_colour" [vZ, .lit "red"] [])
      (.and inZone
        (.not (.or excTourBus (.or excRtcBus (.or excArmoredOrEmergency excMailDropBox))))))

/-- s3: a halt behind another road user ahead in the subject's lane, within the queue gap. -/
def queueHalt : Formula :=
  .existsUser "u"
    (.and (.not (.same vU vSubject))
      (.and (.atom "rel_ahead_behind_in_lane" [vU, vSubject] [])
            (.cmp (.measure "rel_surface_gap" [vSubject, vU]) .le pQueueHaltGap)))

/-- s3: a red signal indication (circular_red, red_arrow(dir), flashing_red). -/
def redIndication : Formula :=
  let shows (i : String) : Formula := .atom "dev_traffic_signal_shows" [vD, .lit i] []
  .or (shows "circular_red")
    (.or (shows "flashing_red")
      (.or (shows "red_arrow(left)")
        (.or (shows "red_arrow(right)")
          (.or (shows "red_arrow(straight)") (shows "red_arrow(u_turn)")))))

/-- s3: an officer's or a device's direction to halt, governing a travel region the subject occupies. -/
def directedHalt : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, vR] [])
      (.or (.existsDevice (.lit "human_direction") "d"
              (.and (.atom "dev_governs" [vD, vR] [])
                (.and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
                      (.atom "dev_human_direction_indication" [vD, .lit "stop"] []))))
        (.or (.existsDevice (.lit "traffic_signal") "d"
                (.and (.atom "dev_governs" [vD, vR] []) redIndication))
             (.existsDevice (.lit "stop_sign") "d"
                (.atom "dev_governs" [vD, vR] [])))))

/-- Obligation: s3 (obligation): Red indicates no stopping, standing or parking,; s18 (standard): for the period of time necessary to expeditiously deposit mail in such a drop box. -/
def obligation : Formula :=
  .implies halted (.or queueHalt directedHalt)

def rule : Rule :=
  { id := "LVMC_11_52_030_A"
    laws := ["LVMC-11-52-030-A"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "for the period of time necessary to expeditiously deposit mail in such a drop box"
          concepts := ["drv.motion.complete_halt", "rel.occupies"]
          params := ["p.mail_deposit_max_halt"]
          convention := "curbside dwell of a single drop-off: the time to pull up, reach the box from the vehicle or a step away and post the mail; the halt counts as expeditious while the time since the subject came to rest in the zone (sinceRise of drv.motion.complete_halt and rel.occupies) is at most the parameter"
          surrogate := false } ]
    residues := ["\"whether or not the vehicle is attended and whether or not the engine or motor is running\" makes the duty the same in every case: the halt is barred either way, so neither occupancy nor kin.engine_running is read.", "\"whether or not accompanied by signage to that effect\": the red paint alone marks the zone; a sign beside it changes nothing.", "\"whether or not there is accompanying signage so indicating\": the armored car and emergency vehicle exception holds with or without a sign."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_52_030_A
