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
    s1: the binder class, ru_aggregate(subject, DEF-NRS-484A-320::vehicle).
    s2, s7: the applicability binds a region z of kind curb_zone (existsRegion) with
      rel_occupies(subject, z) and st_curb_zone_colour(z, red); the exceptions read that same z.
    s9, s10 (2): one of the three aggregates (tour_bus, shuttle_bus, limo), st_curb_zone_kind(z,
      tour_bus_loading), the subject at rest, and sinceRise(halt ∧ rel_occupies(subject, z)) at most
      the literal thirty minutes.
    s11, s12 (3): the rtc_bus aggregate, st_curb_zone_kind(z, bus_stop), at rest, same time bound.
    s13, s14 (4): ru_official_vehicle with kind armored_car, or ru_emergency_vehicle; as the record's
      applicability states it, the class alone, with no halt condition of its own (a moving armored
      car is not engaged either way).
    s16, s17, s18 (5): some region of kind obstruction with st_obstruction_kind mail_drop_box and
      st_region_geometry_distance(subject, o) at most p.mail_drop_box_reach, the subject at rest and
      sinceRise(halt ∧ rel_occupies(subject, z)) at most p.mail_deposit_max_halt (the node's
      operationalization).
    The exceptions are negated together inside the zone quantifier, so the duty is engaged at a red
    zone the subject occupies where none of them holds.
    s3 (obligation): drv_motion_complete_halt(subject) implies the definition's exclusions: some other
      road user u ahead of the subject in its lane (rel_ahead_behind_in_lane(u, subject)) with
      rel_surface_gap(subject, u) at most p.queue_halt_gap; or some travel region r the subject
      occupies governed by a human_direction device with role police_officer and indication stop, a
      traffic_signal showing circular_red, flashing_red or red_arrow(any dir), or a stop_sign. The
      obligation does not re-bind z: the duty is the halt itself, and the applicability only engages
      where the subject occupies a selected red zone.
    No choice beyond the record's words was made, so `narrowings` is empty.

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

/-- The literal of s10 and s12: thirty minutes. -/
def thirtyMinutes : Term := .lit (Units.minutes 30) .second

/-- The zone variable bound by the applicability's curb-zone quantifier. -/
def vZone : Arg := .var "z"

/-- s3, s10, s12, s13, s14, s17: the subject at rest (drv.motion.complete_halt). -/
def halt : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s2, s7: the subject occupies the zone z. -/
def inZone : Formula := .atom "rel_occupies" [vSubject, vZone] []

/-- s10, s12, s18: the time since the subject came to rest in z (sinceRise of halt ∧ occupies z). -/
def haltInZoneFor : Term := .sinceRise (.and halt inZone)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- (2) s9, s10: a tour bus, shuttle bus or limo, in a zone of kind tour_bus_loading, at rest in it
    for at most thirty minutes. -/
def excTourBus : Formula :=
  .and (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-150::tour_bus"] [])
         (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-150::shuttle_bus"] [])
              (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-090::limo"] [])))
    (.and (.atom "st_curb_zone_kind" [vZone, .lit "tour_bus_loading"] [])
      (.and halt (.cmp haltInZoneFor .le thirtyMinutes)))

/-- (3) s11, s12: an RTC bus, in a zone of kind bus_stop, at rest in it for at most thirty minutes. -/
def excRtcBus : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-120::rtc_bus"] [])
    (.and (.atom "st_curb_zone_kind" [vZone, .lit "bus_stop"] [])
      (.and halt (.cmp haltInZoneFor .le thirtyMinutes)))

/-- (4) s13, s14: an armored car (official vehicle of kind armored_car) or an emergency vehicle. -/
def excArmoredOrEmergency : Formula :=
  .or (.and (.atom "ru_official_vehicle" [vSubject] [])
            (.atom "ru_official_vehicle_kind" [vSubject, .lit "armored_car"] []))
      (.atom "ru_emergency_vehicle" [vSubject] [])

/-- (5) s16, s17, s18: a mail drop box within reach of the subject's body, the subject at rest in z
    for at most the expeditious-deposit bound. -/
def excMailDropBox : Formula :=
  .and (.existsRegion (.lit "obstruction") "o"
          (.and (.atom "st_obstruction_kind" [.var "o", .lit "mail_drop_box"] [])
                (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "o"]) .le pMailDropBoxReach)))
    (.and halt (.cmp haltInZoneFor .le pMailDepositMaxHalt))

/-- Applicability: s2 (condition): The location of such zones shall be established by posting appropriate signage or other durable markings, by painting curbs or the edges of road surfaces in accordance with the colors listed below, or by a combination thereof:; s4 (condition): whether or not the vehicle is attended and whether or not the engine or motor is running,; s7 (condition): a curb or road surface edge which is painted red indicates no parking,; s8 (condition): whether or not accompanied by signage to that effect.; s9 (exception): (2) When the location is accompanied by signage which indicates that parking is limited to tour buses, shuttle buses and limos,; s10 (exception): those vehicles may park for a period up to thirty minutes for the loading or unloading of passengers. (3); s11 (exception): When the location is accompanied by signage which indicates that parking is limited to RTC buses,; s12 (exception): those vehicles may park for a period up to thirty minutes for the loading or unloading of passengers. (4); s13 (exception): Armored cars and emergency vehicles may park at such locations; s14 (exception): for the period necessary to conduct their business,; s15 (exception): whether or not there is accompanying signage so indicating.; s16 (exception): (5) At locations where a drop box for U.S. mail is adjacent to a curb or road surface painted red,; s17 (exception): a person may stop -/
def applicability : Formula :=
  .existsRegion (.lit "curb_zone") "z"
    (.and inZone
      (.and (.atom "st_curb_zone_colour" [vZone, .lit "red"] [])
        (.not (.or excTourBus (.or excRtcBus (.or excArmoredOrEmergency excMailDropBox))))))

/-- s3 (definition of stopping): a halt to avoid conflict with traffic — another road user ahead of
    the subject in its lane within the queue gap of the bodies. -/
def queuedBehind : Formula :=
  .existsUser "u"
    (.and (.not (.same (.var "u") vSubject))
      (.and (.atom "rel_ahead_behind_in_lane" [.var "u", vSubject] [])
            (.cmp (.measure "rel_surface_gap" [vSubject, .var "u"]) .le pQueueHaltGap)))

/-- s3 (definition of stopping): a halt in compliance with a police officer's stop, a red signal
    indication or a stop sign governing a travel region the subject occupies. -/
def directedToHalt : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
      (.or (.existsDevice (.lit "human_direction") "d"
              (.and (.atom "dev_governs" [.var "d", .var "r"] [])
                (.and (.atom "dev_human_direction_role" [.var "d", .lit "police_officer"] [])
                      (.atom "dev_human_direction_indication" [.var "d", .lit "stop"] []))))
        (.or (.existsDevice (.lit "traffic_signal") "d"
                (.and (.atom "dev_governs" [.var "d", .var "r"] [])
                  (.or (.atom "dev_traffic_signal_shows" [.var "d", .lit "circular_red"] [])
                    (.or (.atom "dev_traffic_signal_shows" [.var "d", .lit "flashing_red"] [])
                      (.or (.atom "dev_traffic_signal_shows" [.var "d", .lit "red_arrow(left)"] [])
                        (.or (.atom "dev_traffic_signal_shows" [.var "d", .lit "red_arrow(right)"] [])
                          (.or (.atom "dev_traffic_signal_shows" [.var "d", .lit "red_arrow(straight)"] [])
                               (.atom "dev_traffic_signal_shows" [.var "d", .lit "red_arrow(u_turn)"] []))))))))
             (.existsDevice (.lit "stop_sign") "d"
                (.atom "dev_governs" [.var "d", .var "r"] [])))))

/-- Obligation: s3 (obligation): Red indicates no stopping, standing or parking,; s18 (standard): for the period of time necessary to expeditiously deposit mail in such a drop box. -/
def obligation : Formula :=
  .implies halt (.or queuedBehind directedToHalt)

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
          convention := "curbside dwell of a single drop-off: the time to pull up, reach the box from the vehicle or a step away and post the mail; the halt counts as expeditious while the subject is at rest and the time since it came to rest in the zone (sinceRise of drv.motion.complete_halt and rel.occupies) is at most the parameter"
          surrogate := false } ]
    residues := ["\"whether or not the vehicle is attended and whether or not the engine or motor is running\" makes the duty the same in every case: the halt is barred either way, so neither occupancy nor kin.engine_running is read.", "\"whether or not accompanied by signage to that effect\": the red paint alone marks the zone; a sign beside it changes nothing.", "\"whether or not there is accompanying signage so indicating\": the armored car and emergency vehicle exception holds with or without a sign."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_52_030_A
