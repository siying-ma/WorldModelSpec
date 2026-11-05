/-
  NRS_484B_257_1_o2 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    e2 (trigger): When proper signs have been erected,
    e3 (sibling): the driver of a vehicle shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    e4 (condition): After having stopped or, in the event of a yield sign, slowed or stopped,
    e5 (subject): the driver
    e6 (obligation): shall yield the right-of-way to other vehicles which have entered the intersection from such through highway
    e7 (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard
    e8 (condition): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.governs', 'st.intersection', 'rel.occupies'], derived []
    e2: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies', 'st.intersection'], derived []
    e4: atoms ['prim.region_offset_along', 'rel.occupies', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.highway', 'st.sight_along_way', 'st.lane_direction', 'kin.speed', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.halted', 'drv.lane.enters_region']
    e5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e6: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.highway', 'st.on_way', 'st.lane_enters', 'st.travel_region', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs'], derived ['drv.lane.enters_region']
    e8: atoms ['rel.occupies', 'st.intersection', 'kin.speed'], derived ['drv.lane.enters_region']

  How each span is written.

  e5 (subject) — `clsSubject`: the vehicle the subsection binds, the aggregate atom with the id
  DEF-NRS-484A-320::vehicle. The record's own observable reading (the driver read through the
  vehicle) is the plan's and is not restated below.

  e8 (condition) — `occupiesJunction` and `inMotion`, inside the applicability's intersection
  quantifier: the subject's footprint overlaps the junction (`rel_occupies` over `st_intersection`)
  and its speed is above the motion tolerance. The stretch the record describes — from the entry
  into the junction for as long as the footprint overlaps it while in motion — is exactly the
  observations at which that overlap and that motion hold: every such observation lies in the
  stretch that began at an entry, and no other does, so the entry event itself is not read again
  here (`drv.lane.enters_region` carries "which have entered" in the duty, e6).

  e1 (exception) — `controlledAtJunction`, negated in the applicability: the subject is a member
  of the admitted aggregate DEF-NRS-484A-285::traffic and either a person directing traffic
  (`dev_human_direction`) with the police-officer role and an indication given (one of the
  enumeration's values) is recorded as governing that junction, or a traffic signal
  (`dev_traffic_signal`) is recorded as governing it (`dev_governs` over `st_intersection`).

  e2 (trigger) — `stopSignGoverns` / `yieldSignGoverns` under the applicability's approach
  quantifier: a stop sign or a yield sign is recorded as governing (`dev_governs`) a travel region
  (`st_travel_region`) the subject occupies (`rel_occupies`) whose entrance end (`st_lane_enters`)
  is that junction. The signs' propriety is read from their presence, as the record directs.

  e4 (condition) — `stoppedOnThisApproach`: at some observation of the approach that led to this
  entry, the subject stood at the place the first sentence names. `stoppedOrSlowedAtPlace` is that
  observation: the footprint not yet overlapping the junction, the body short of the place along
  the carrier's designated direction (`prim_region_offset_along`, which reads
  `st.lane_direction` for that direction) and within the stop-point tolerance of it by the
  body-to-region distance (`st_region_geometry_distance`), and there halted
  (`drv.motion.halted`) — or, where a yield sign governs the carrier, at or below the
  yield-approach speed (`kin_speed`). The place is the stop line (`st_stop_line`) or the crosswalk
  (`st_crosswalk`) the source records as marking that carrier (`st_entrance_of`), and, where it
  records no such mark for the carrier, the point on the carrier at which the view along the
  through highway (`st_sight_along_way` over `st_highway`, `st_on_way`) reaches the intersection
  view sight distance. The search back ends where the record says it ends and nowhere else: at an
  observation at which the subject was short of a stop line recorded for its carrier by more than
  the stop-point tolerance, that is upstream of that line's stopping zone
  (`upstreamOfStopLine`); a search that reaches the start of the recording without finding the
  halt is unknown, which is the plan's history boundary.

  e6 (obligation) and e7 (standard) — `obligation`: at the junction the applicability selected
  (selected again here by the same relations: the intersection the subject occupies, the signed
  travel region it occupies whose entrance end is that junction, and the highway the junction lies
  on other than the one that carrier lies on), no other road user of the aggregate
  DEF-NRS-484A-320::vehicle that has entered the junction from that through highway
  (`enteredFromThroughWay`, over `drv.lane.enters_region`), or that is approaching it on that
  highway so closely as to constitute an immediate hazard (`immediateHazard`, the
  operationalization: the distance from its body to the junction at most its speed times the
  arrival time), is brought into a predicted conflict: under the velocities observed at the
  instant the centres either do not approach within the conflict horizon or are no closer than the
  minimum clearance at their closest approach (`prim.closest_approach_within`,
  `prim.closest_approach_distance`).

  Narrowing declared below (e6): "which have entered the intersection" is read over the recording —
  the vehicle's entry into the junction is an observation of this trace and its footprint has
  overlapped the junction at every observation since. A vehicle whose entry happened before the
  recording began leaves the leaf unknown, never false.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The variables the rule's own quantifiers bind. -/
def vJunction : Arg := .var "junction"
def vApproach : Arg := .var "approach"
def vMark : Arg := .var "mark"
def vWay : Arg := .var "way"
def vSign : Arg := .var "sign"
def vOfficer : Arg := .var "officer"
def vSignal : Arg := .var "signal"
def vOther : Arg := .var "other"
def vComer : Arg := .var "comer"

/-- The admitted aggregates, by the ids the record claims. -/
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"
def aggTraffic : Arg := .lit "DEF-NRS-484A-285::traffic"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pImmediateHazardArrivalTime : Term := .param "p.immediate_hazard_arrival_time"
def pIntersectionViewSightDistance : Term := .param "p.intersection_view_sight_distance"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldApproachSpeedMax : Term := .param "p.yield_approach_speed_max"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggVehicle] []

-- ---------------------------------------------------------------------------------------------
-- The quantities the spans read
-- ---------------------------------------------------------------------------------------------
/-- The subject's speed. -/
def subjectSpeed : Term := .measure "kin_speed" [vSubject]
/-- The signed distance from the subject's reference point to `mark`, along `approach`'s
    designated direction: positive where the mark lies ahead. -/
def offsetToMark : Term := .quantity "prim_region_offset_along" [vSubject, vMark, vApproach] []
/-- The distance from the subject's body to `mark`. -/
def distanceToMark : Term := .measure "st_region_geometry_distance" [vSubject, vMark]

-- ---------------------------------------------------------------------------------------------
-- e8: moving across or within the intersection
-- ---------------------------------------------------------------------------------------------
/-- The subject's footprint overlaps the junction. -/
def occupiesJunction : Formula := .atom "rel_occupies" [vSubject, vJunction] []
/-- The subject is in motion: its speed is above the motion tolerance. -/
def inMotion : Formula := .cmp subjectSpeed .gt pMotionSpeedTolerance

-- ---------------------------------------------------------------------------------------------
-- e2: the sign erected for the subject's approach
-- ---------------------------------------------------------------------------------------------
def stopSignGoverns : Formula :=
  .existsDevice (.lit "stop_sign") "sign"
    (.and (.atom "dev_stop_sign" [vSign] [])
          (.atom "dev_governs" [vSign, vApproach] []))

def yieldSignGoverns : Formula :=
  .existsDevice (.lit "yield_sign") "sign"
    (.and (.atom "dev_yield_sign" [vSign] [])
          (.atom "dev_governs" [vSign, vApproach] []))

/-- A stop sign or a yield sign governs the carrier the subject approaches through. -/
def signGovernsApproach : Formula := .or stopSignGoverns yieldSignGoverns

-- ---------------------------------------------------------------------------------------------
-- e1: traffic at the junction controlled by a police officer or a traffic-control signal
-- ---------------------------------------------------------------------------------------------
/-- The person directing traffic gives an indication: one of the enumeration's values. -/
def indicationGiven : Formula :=
  .or (.atom "dev_human_direction_indication" [vOfficer, .lit "stop"] [])
    (.or (.atom "dev_human_direction_indication" [vOfficer, .lit "proceed"] [])
      (.or (.atom "dev_human_direction_indication" [vOfficer, .lit "slow"] [])
        (.or (.atom "dev_human_direction_indication" [vOfficer, .lit "turn(left)"] [])
          (.or (.atom "dev_human_direction_indication" [vOfficer, .lit "turn(right)"] [])
            (.or (.atom "dev_human_direction_indication" [vOfficer, .lit "turn(straight)"] [])
                 (.atom "dev_human_direction_indication" [vOfficer, .lit "turn(u_turn)"] []))))))

def officerDirecting : Formula :=
  .existsDevice (.lit "human_direction") "officer"
    (.and (.atom "dev_human_direction" [vOfficer] [])
      (.and (.atom "dev_human_direction_role" [vOfficer, .lit "police_officer"] [])
        (.and indicationGiven
              (.atom "dev_governs" [vOfficer, vJunction] []))))

def signalControlling : Formula :=
  .existsDevice (.lit "traffic_signal") "signal"
    (.and (.atom "dev_traffic_signal" [vSignal] [])
          (.atom "dev_governs" [vSignal, vJunction] []))

/-- The traffic the subject belongs to is being controlled at that junction. -/
def controlledAtJunction : Formula :=
  .and (.atom "ru_aggregate" [vSubject, aggTraffic] [])
       (.or officerDirecting signalControlling)

-- ---------------------------------------------------------------------------------------------
-- e4: after having stopped (or, under a yield sign, slowed or stopped) at the place
-- ---------------------------------------------------------------------------------------------
/-- The body stands short of `mark` along the carrier's direction and within the stop-point
    tolerance of it. -/
def atMark : Formula :=
  .and (.cmp offsetToMark .gt zeroMetres)
       (.cmp distanceToMark .le pStopPointTolerance)

def atStopLineOfApproach : Formula :=
  .existsRegion (.lit "stop_line") "mark"
    (.and (.atom "st_stop_line" [vMark] [])
      (.and (.atom "st_entrance_of" [vMark, vApproach] []) atMark))

def atCrosswalkOfApproach : Formula :=
  .existsRegion (.lit "crosswalk") "mark"
    (.and (.atom "st_crosswalk" [vMark] [])
      (.and (.atom "st_entrance_of" [vMark, vApproach] []) atMark))

/-- The source records a stop line or a crosswalk marking that carrier's entrance. -/
def someMarkOfApproach : Formula :=
  .or (.existsRegion (.lit "stop_line") "mark" (.atom "st_entrance_of" [vMark, vApproach] []))
      (.existsRegion (.lit "crosswalk") "mark" (.atom "st_entrance_of" [vMark, vApproach] []))

/-- `way` is the through highway: a highway the junction lies on other than the one the carrier
    lies on. -/
def throughWay : Formula :=
  .and (.atom "st_highway" [vWay] [])
    (.and (.atom "st_on_way" [vJunction, vWay] [])
          (.not (.atom "st_on_way" [vApproach, vWay] [])))

/-- The point on the carrier at which the view along the through highway reaches the intersection
    view sight distance. -/
def atSightPoint : Formula :=
  .existsRegion (.lit "highway") "way"
    (.and throughWay
          (.cmp (.measure "st_sight_along_way" [vSubject, vWay]) .ge pIntersectionViewSightDistance))

/-- The place the first sentence names: the recorded stop line, the recorded crosswalk, or — where
    the source records neither for that carrier — the sight point. -/
def placeOfTheFirstSentence : Formula :=
  .or atStopLineOfApproach
    (.or atCrosswalkOfApproach
         (.and (.not someMarkOfApproach) atSightPoint))

/-- At this observation the subject stood at the place, or crept there under a yield sign. -/
def stoppedOrSlowedAtPlace : Formula :=
  .and (.not occupiesJunction)
    (.and placeOfTheFirstSentence
      (.or (.derived "drv_motion_halted" [vSubject] [pMotionSpeedTolerance])
           (.and yieldSignGoverns (.cmp subjectSpeed .le pYieldApproachSpeedMax))))

/-- The subject stands upstream of the stopping zone of a stop line recorded for its carrier:
    short of that line, along the carrier's direction, by more than the stop-point tolerance.
    This is where the search back for the halt ends. -/
def upstreamOfStopLine : Formula :=
  .existsRegion (.lit "stop_line") "mark"
    (.and (.atom "st_entrance_of" [vMark, vApproach] [])
          (.cmp offsetToMark .gt pStopPointTolerance))

/-- Since the subject came into the stopping zone of its approach, it stood at the place. -/
def stoppedOnThisApproach : Formula :=
  .since (.not upstreamOfStopLine) stoppedOrSlowedAtPlace

-- ---------------------------------------------------------------------------------------------
-- e6, e7: the vehicles whose right-of-way the subject must yield, and the conflict it must not
-- bring about
-- ---------------------------------------------------------------------------------------------
/-- The other road user occupies a carrier of the through highway whose entrance end is the
    junction: it came in on that highway. -/
def comerCarrier : Formula :=
  .existsRegion (.lit "travel_region") "comer"
    (.and (.atom "st_travel_region" [vComer] [])
      (.and (.atom "st_lane_enters" [vComer, vJunction] [])
        (.and (.atom "st_on_way" [vComer, vWay] [])
              (.atom "rel_occupies" [vOther, vComer] []))))

/-- The other vehicle has entered the junction from the through highway: it entered at an
    observation of this recording, on a carrier of that highway, and its footprint has overlapped
    the junction at every observation since. -/
def enteredFromThroughWay : Formula :=
  .since (.atom "rel_occupies" [vOther, vJunction] [])
         (.and (.derived "drv_lane_enters_region" [vOther, vJunction] []) comerCarrier)

/-- e7, as the operationalization states it: the other vehicle is approaching that junction on the
    through highway and the distance from its body to the junction is at most its speed times the
    arrival time. -/
def immediateHazard : Formula :=
  .and (.derived "drv_position_approaching_intersection" [vOther, vJunction] [])
    (.and comerCarrier
      (.cmp (.measure "st_region_geometry_distance" [vOther, vJunction]) .le
            (.mul (.measure "kin_speed" [vOther]) pImmediateHazardArrivalTime)))

/-- The subject brings about no predicted conflict with the other vehicle. -/
def noPredictedConflict : Formula :=
  .or (.not (.derived "prim_closest_approach_within" [vSubject, vOther] [pYieldConflictHorizon]))
      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vOther] [pYieldConflictHorizon])
            .ge pYieldMinClearance)

-- ---------------------------------------------------------------------------------------------
-- The two formulas
-- ---------------------------------------------------------------------------------------------
/-- Applicability: e1 (exception); e2 (trigger); e4 (condition); e8 (condition). -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "junction"
    (.and (.atom "st_intersection" [vJunction] [])
      (.and occupiesJunction
        (.and inMotion
          (.and (.not controlledAtJunction)
            (.existsRegion (.lit "travel_region") "approach"
              (.and (.atom "st_travel_region" [vApproach] [])
                (.and (.atom "st_lane_enters" [vApproach, vJunction] [])
                  (.and (.atom "rel_occupies" [vSubject, vApproach] [])
                    (.and signGovernsApproach stoppedOnThisApproach)))))))))

/-- Obligation: e6 (obligation); e7 (standard). The junction, the carrier and the through highway
    are selected again by the relations that fixed them in the applicability. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "junction"
    (.implies (.and (.atom "st_intersection" [vJunction] []) occupiesJunction)
      (.forallRegion (.lit "travel_region") "approach"
        (.implies
          (.and (.atom "st_travel_region" [vApproach] [])
            (.and (.atom "st_lane_enters" [vApproach, vJunction] [])
              (.and (.atom "rel_occupies" [vSubject, vApproach] []) signGovernsApproach)))
          (.forallRegion (.lit "highway") "way"
            (.implies throughWay
              (.forallUser "other"
                (.implies
                  (.and (.not (.same vOther vSubject))
                    (.and (.atom "ru_aggregate" [vOther, aggVehicle] [])
                          (.or enteredFromThroughWay immediateHazard)))
                  noPredictedConflict)))))))

def rule : Rule :=
  { id := "NRS_484B_257_1_o2"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "approaching so closely on such through highway as to constitute an immediate hazard"
          concepts := ["drv.position.approaching_intersection", "kin.speed", "rel.occupies", "st.highway", "st.intersection", "st.lane_enters", "st.on_way", "st.region_geometry", "st.travel_region"]
          params := ["p.immediate_hazard_arrival_time"]
          convention := "gap-acceptance convention for a vehicle entering from a stop or yield controlled approach: a vehicle approaching on the through highway is so close as to constitute an immediate hazard where the distance from its body to the junction region (st.region_geometry) is at most its observed speed times the arrival time, that is where it would reach the junction within the time a passenger car needs to clear the junction from the controlled approach. The bound moves with the approaching vehicle's own speed and its own distance, so the degree of each is read"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "e6"
          why := "\"which have entered the intersection\" is read over the recording: the other vehicle's entry into the junction is an observation of this trace (drv.lane.enters_region on that junction, on a carrier of the through highway) and its footprint has overlapped the junction at every observation since. A vehicle whose entry happened before the recording began leaves the leaf unknown, never false."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o2
