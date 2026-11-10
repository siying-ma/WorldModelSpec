/-
  NRS_484B_440_1_o1 — NRS-484B-440-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (trigger): Upon any highway
    e2 (condition): outside of a business or residence district
    e3 (obligation): no person shall stop, park or leave standing
    e4 (subject): any vehicle,
    e5 (condition): whether attended or unattended,
    e6 (condition): upon the paved or main-traveled part of the highway
    e7 (standard): when it is practicable to stop, park or so leave such vehicle off such part of the highway,
    e8 (sibling): but in every event an unobstructed width of the highway opposite a standing vehicle shall be left
    e9 (sibling): for the free passage of other vehicles
    e10 (sibling): and a clear view of such stopped vehicles shall be available from a distance of 200 feet in each direction upon such highway.
    e11 (exception): This section shall not apply to the driver of any vehicle which is disabled
    e12 (exception): while on the paved or main-traveled portion of a highway
    e13 (exception): in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position.

  Elements (span → atoms, derived):
    e1: atoms ['rel.occupies', 'st.highway'], derived []
    e3: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance', 'rel.ahead_behind_in_lane', 'rel.surface_gap', 'dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived ['drv.motion.stopped']
    e4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e6: atoms ['rel.occupies', 'st.roadway', 'st.on_way'], derived []
    e12: atoms ['rel.occupies', 'st.roadway'], derived []

  How each is written:
    e4: the class of x is ru_aggregate with the aggregate id DEF-NRS-484A-320::vehicle.
    e1, e6: some highway h that x occupies, and some roadway rw with st_on_way(rw, h) that x
      occupies (the kinds are the quantifiers' kinds). The obligation repeats this selection of h
      whole, since e7's shoulder must lie on that same highway.
    e2: not asm.business_or_residence_district.
    e11–e13: the applicability excludes asm.vehicle_disabled ∧ (x occupies some roadway) ∧
      asm.disabled_vehicle_immovable.
    e3: x halted (drv_motion_stopped, p.motion_speed_tolerance), and the halt not one the stopping
      definition excepts: some z ≠ x ahead of x in its lane (rel_ahead_behind_in_lane(z, x), z
      ahead) with rel_surface_gap(x, z) below p.queue_standstill_gap, or with
      prim_closest_approach_within(x, z) over p.conflict_time_horizon and the distance at closest
      approach below p.conflict_centre_clearance; or some travel region x occupies governed
      (dev_governs) by a traffic signal showing circular_red, flashing_red or a red arrow of any
      direction, a stop sign, a yield sign, or a human direction with role police_officer and
      indication stop.
    e7: some shoulder s with st_on_way(s, h), st_region_geometry_distance(x, s) at most
      p.off_roadway_reach, and no road user w ≠ x halted (same tolerance), occupying s, with
      rel_longitudinal_overlap(x, w) at or above zero.
    The violation: at some selected h, x halted, the halt not excepted, and halting off practicable.
  Choices the text left open: none beyond the record's; no narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_440_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pOffRoadwayReach : Term := .param "p.off_roadway_reach"
def pQueueStandstillGap : Term := .param "p.queue_standstill_gap"

def zeroMetres : Term := .lit Q.zero .metre

def occupies (who r : String) : Formula := .atom "rel_occupies" [.var who, .var r] []

/-- A road user at a complete halt (drv.motion.stopped at the speed resolution). -/
def halted (who : String) : Formula := .derived "drv_motion_stopped" [.var who] [pMotionSpeedTolerance]

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e1 + e6: x occupies highway `h` and a roadway lying on it. The obligation repeats this
    selection of `h` whole, since the shoulder it reads must lie on the same highway. -/
def onRoadwayOf (h : String) : Formula :=
  .and (occupies "x" h)
    (.existsRegion (.lit "roadway") "rw" (.and (.atom "st_on_way" [.var "rw", .var h] []) (occupies "x" "rw")))

/-- e11–e13: the vehicle is disabled, on a roadway, and cannot be moved. -/
def disabledException : Formula :=
  .and (.asm "asm.vehicle_disabled")
    (.and (.existsRegion (.lit "roadway") "rd" (occupies "x" "rd")) (.asm "asm.disabled_vehicle_immovable"))

/-- Applicability: e1 (trigger): Upon any highway; e2 (condition): outside of a business or residence district; e5 (condition): whether attended or unattended,; e6 (condition): upon the paved or main-traveled part of the highway; e11 (exception): This section shall not apply to the driver of any vehicle which is disabled; e12 (exception): while on the paved or main-traveled portion of a highway; e13 (exception): in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position. -/
def applicability : Formula :=
  .and (.existsRegion (.lit "highway") "h" (onRoadwayOf "h"))
    (.and (.not (.asm "asm.business_or_residence_district"))
      (.not disabledException))

/-- e3: a halt to avoid conflict with other traffic — another road user ahead of x in its lane
    within the standstill gap, or one in a predicted conflict with x. -/
def conflictHalt : Formula :=
  .existsUser "z" (.and (.not (.same (.var "z") vX))
    (.or
      (.and (.atom "rel_ahead_behind_in_lane" [.var "z", vX] [])
        (.cmp (.measure "rel_surface_gap" [vX, .var "z"]) .lt pQueueStandstillGap))
      (.and (.derived "prim_closest_approach_within" [vX, .var "z"] [pConflictTimeHorizon])
        (.cmp (.quantity "prim_closest_approach_distance" [vX, .var "z"] [pConflictTimeHorizon])
          .lt pConflictCentreClearance))))

/-- The red indications of a signal head that direct a halt. -/
def showsRed (d : String) : Formula :=
  let shows (i : String) : Formula := .atom "dev_traffic_signal_shows" [.var d, .lit i] []
  .or (shows "circular_red")
    (.or (shows "flashing_red")
      (.or (shows "red_arrow(left)")
        (.or (shows "red_arrow(right)")
          (.or (shows "red_arrow(straight)") (shows "red_arrow(u_turn)")))))

/-- e3: a halt in compliance with a device or an officer governing a travel region x occupies. -/
def directedHalt : Formula :=
  .existsRegion (.lit "travel_region") "r" (.and (occupies "x" "r")
    (.or (.existsDevice (.lit "traffic_signal") "dsig"
            (.and (.atom "dev_governs" [.var "dsig", .var "r"] []) (showsRed "dsig")))
      (.or (.existsDevice (.lit "stop_sign") "dstop" (.atom "dev_governs" [.var "dstop", .var "r"] []))
        (.or (.existsDevice (.lit "yield_sign") "dyield" (.atom "dev_governs" [.var "dyield", .var "r"] []))
          (.existsDevice (.lit "human_direction") "dhum"
            (.and (.atom "dev_governs" [.var "dhum", .var "r"] [])
              (.and (.atom "dev_human_direction_role" [.var "dhum", .lit "police_officer"] [])
                (.atom "dev_human_direction_indication" [.var "dhum", .lit "stop"] []))))))))

/-- e7: a shoulder of highway `h` within the reach of x's body, with no other halted road user
    on it alongside x. -/
def practicableOff (h : String) : Formula :=
  .existsRegion (.lit "shoulder") "s"
    (.and (.atom "st_on_way" [.var "s", .var h] [])
      (.and (.cmp (.measure "st_region_geometry_distance" [vX, .var "s"]) .le pOffRoadwayReach)
        (.not (.existsUser "w" (.and (.not (.same (.var "w") vX))
          (.and (halted "w")
            (.and (occupies "w" "s")
              (.cmp (.measure "rel_longitudinal_overlap" [vX, .var "w"]) .ge zeroMetres))))))))

/-- Obligation: e3 (obligation): no person shall stop, park or leave standing; e7 (standard): when it is practicable to stop, park or so leave such vehicle off such part of the highway, -/
def obligation : Formula :=
  .not (.existsRegion (.lit "highway") "h"
    (.and (onRoadwayOf "h")
      (.and (halted "x")
        (.and (.not (.or conflictHalt directedHalt)) (practicableOff "h")))))

def rule : Rule :=
  { id := "NRS_484B_440_1_o1"
    laws := ["NRS-484B-440-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district", "asm.vehicle_disabled", "asm.disabled_vehicle_immovable"]
    intentions := []
    operationalizations :=
      [ { standard := "practicable to stop, park or so leave such vehicle off such part of the highway"
          concepts := ["rel.longitudinal_overlap", "rel.occupies", "st.on_way", "st.region_geometry", "st.shoulder"]
          params := ["p.off_roadway_reach"]
          convention := "Practicability of halting off the roadway is read through the space off the roadway beside the vehicle: a st.shoulder lying on the same highway (st.on_way) whose boundary lies within one standard lane width of the vehicle's body (st.region_geometry ground distance from the body outline, compared with the reach), so the distance measured enters the bound, and on which no other halted road user occupies (rel.occupies) the stretch alongside the vehicle (rel.longitudinal_overlap not negative). A shoulder farther than the reach, or one taken alongside, makes halting off the roadway not practicable."
          surrogate := false } ]
    residues := ["Attended or unattended, the duty is the same: the words name both cases and exclude neither, so no observation of occupancy is read."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_440_1_o1
