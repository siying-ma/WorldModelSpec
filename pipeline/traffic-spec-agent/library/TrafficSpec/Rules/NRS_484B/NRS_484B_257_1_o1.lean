/-
  NRS_484B_257_1_o1 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    d2 (trigger): When proper signs have been erected,
    d3 (subject): the driver of a vehicle
    d4 (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    d5 (sibling): After having stopped or, in the event of a yield sign, slowed or stopped,
    d6 (sibling): the driver shall yield the right-of-way to other vehicles which have entered the intersection from such through highway or which are approaching so closely on such through highway as to constitute an immediate hazard during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    d1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.governs', 'st.intersection', 'rel.occupies'], derived []
    d2: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies', 'st.intersection'], derived []
    d3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d4: atoms ['prim.region_offset_along', 'rel.occupies', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.highway', 'st.sight_along_way', 'st.lane_direction', 'kin.speed', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.halted', 'drv.lane.enters_region']

  How each span is written.

  d3 (subject, `clsSubject`). The vehicle is the admitted aggregate, carried by `ru_aggregate` with
  the aggregate id as its literal argument; the record's own narrowing reads "the driver of" through
  the vehicle's controlled motion, and nothing of the driver is read here.

  d2 (trigger, inside `engagedHere`). The subject's approach is the carrier it occupies
  (`rel_occupies`) whose entrance end is the intersection it enters (`st_lane_enters`), quantified
  over the travel regions (`st_travel_region`) and the intersections (`st_intersection`) of the
  scene, as `st.lane_enters` directs; a proper sign is a stop sign or a yield sign recorded as
  governing that same carrier (`dev_governs`). No stopping position is read from the governance.

  d1 (exception, `trafficControlled`). The traffic being controlled is read through the aggregate the
  element admits: the subject, a member of DEF-NRS-484A-285::traffic, at a junction whose traffic a
  police officer or a traffic-control signal controls. "Controlled by a police officer" is a person
  directing traffic (`dev_human_direction`) whose role is `police_officer`, who is recorded as
  governing that intersection (`dev_governs`), and who gives an indication — every indication the
  ontology admits is a limb of the disjunction, so no manner of directing is left out. A
  traffic-control signal is a signal head (`dev_traffic_signal`) recorded as governing that
  intersection. The exception is stated as the record maps it, with no fact weaker than the one it
  states; it is negated into the applicability.

  d4 (obligation, `dutyAtPlace`). The duty is owed at the entry (`drv_lane_enters_region`, the event)
  and searched for back from it: `.since` over the approach, whose continue-condition is the absence
  of the record's two ends — the approach start (`pastTheStoppingZone`: on the carrier, off the place,
  short of it by the sign of `prim_region_offset_along` and farther from it than the stop-point
  tolerance by the body-to-region distance of `st_region_geometry`) and the previous entry of the
  subject into that same intersection (`previousEntry`). Neither the start of the recording (which
  leaves the duty unknown, as the finite-trace policy requires), nor another junction, nor another
  mark, nor a distance travelled ends the search. The place is the stop line recorded as marking that
  carrier (`st_entrance_of`), else — where the lines' entrances are observed and exclude it — the
  crosswalk recorded as marking it, else the point affording the view: the three limbs are written as
  three implications over the same carrier, so the second governs only where no line marks the carrier
  and the third only where no crossing does, and an unobserved association leaves which place governs
  unknown rather than skipping to the next limb. The act at the place is the halt
  (`drv.motion.halted`, at the motion-speed tolerance) where a stop sign governs the carrier, and the
  halt or a speed (`kin_speed`) no greater than the yield-approach speed where a yield sign governs it.
  The obligation re-states the whole selection of the carrier and the junction, and quantifies it
  universally: where the subject occupies several carriers entering the junction the duty is owed
  through each, so no carrier is picked for favouring the subject.

  The readings this session chose on d4 are declared as narrowings below.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The variables the rule quantifies over: the approach carrier, the intersection it enters, the
    place the act is owed at, the way the view is had along, and the devices read. -/
def vCarrier : Arg := .var "carrier"
def vJunction : Arg := .var "junction"
def vPlace : Arg := .var "place"
def vWay : Arg := .var "way"
def vSign : Arg := .var "sign"
def vOfficer : Arg := .var "officer"
def vSignal : Arg := .var "signal"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pIntersectionViewSightDistance : Term := .param "p.intersection_view_sight_distance"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldApproachSpeedMax : Term := .param "p.yield_approach_speed_max"

def zeroMetres : Term := .lit Q.zero .metre

-- ---------------------------------------------------------------------------------------------
-- Leaves
-- ---------------------------------------------------------------------------------------------
/-- The subject's footprint overlaps the region. -/
def occupies (r : Arg) : Formula := .atom "rel_occupies" [vSubject, r] []

/-- The event d4 places the act before: the subject enters the intersection at this observation. -/
def entersJunction : Formula := .derived "drv_lane_enters_region" [vSubject, vJunction] []

/-- "Stop": complete cessation from movement, at the motion-speed tolerance. -/
def halted : Formula := .derived "drv_motion_halted" [vSubject] [pMotionSpeedTolerance]

def speedOfSubject : Term := .measure "kin_speed" [vSubject]

/-- The signed distance from the subject's reference point to the place, along the carrier's
    designated direction: positive where the place lies ahead, so the subject is short of it. -/
def offsetToPlace : Term := .quantity "prim_region_offset_along" [vSubject, vPlace, vCarrier] []

/-- The body-to-region distance from the subject to the place. -/
def distanceToPlace : Term := .measure "st_region_geometry_distance" [vSubject, vPlace]

/-- The distance along the way within which a vehicle on it could be seen from the subject. -/
def sightAlongWay : Term := .measure "st_sight_along_way" [vSubject, vWay]

-- ---------------------------------------------------------------------------------------------
-- d2: the approach and the sign erected for it
-- ---------------------------------------------------------------------------------------------
/-- The carrier the subject approaches the junction through: a travel region it occupies whose
    entrance end is that intersection. -/
def onApproach : Formula :=
  .and (.atom "st_travel_region" [vCarrier] [])
  (.and (occupies vCarrier)
  (.and (.atom "st_intersection" [vJunction] [])
        (.atom "st_lane_enters" [vCarrier, vJunction] [])))

/-- A stop sign recorded as governing that carrier. -/
def stopSignGoverns : Formula :=
  .existsDevice (.lit "stop_sign") "sign"
    (.and (.atom "dev_stop_sign" [vSign] []) (.atom "dev_governs" [vSign, vCarrier] []))

/-- A yield sign recorded as governing that carrier. -/
def yieldSignGoverns : Formula :=
  .existsDevice (.lit "yield_sign") "sign"
    (.and (.atom "dev_yield_sign" [vSign] []) (.atom "dev_governs" [vSign, vCarrier] []))

/-- "When proper signs have been erected": one of the two signs this section is about governs the
    subject's approach. -/
def properSignErected : Formula := .or stopSignGoverns yieldSignGoverns

-- ---------------------------------------------------------------------------------------------
-- d1: traffic controlled by a police officer or a traffic-control signal
-- ---------------------------------------------------------------------------------------------
/-- An indication given, whatever its manner. -/
def indicationGiven : Formula :=
  .or (.atom "dev_human_direction_indication" [vOfficer, .lit "stop"] [])
  (.or (.atom "dev_human_direction_indication" [vOfficer, .lit "proceed"] [])
  (.or (.atom "dev_human_direction_indication" [vOfficer, .lit "slow"] [])
  (.or (.atom "dev_human_direction_indication" [vOfficer, .lit "turn(left)"] [])
  (.or (.atom "dev_human_direction_indication" [vOfficer, .lit "turn(right)"] [])
  (.or (.atom "dev_human_direction_indication" [vOfficer, .lit "turn(straight)"] [])
       (.atom "dev_human_direction_indication" [vOfficer, .lit "turn(u_turn)"] []))))))

def officerControls : Formula :=
  .existsDevice (.lit "human_direction") "officer"
    (.and (.atom "dev_human_direction" [vOfficer] [])
    (.and (.atom "dev_human_direction_role" [vOfficer, .lit "police_officer"] [])
    (.and (.atom "dev_governs" [vOfficer, vJunction] []) indicationGiven)))

def signalControls : Formula :=
  .existsDevice (.lit "traffic_signal") "signal"
    (.and (.atom "dev_traffic_signal" [vSignal] []) (.atom "dev_governs" [vSignal, vJunction] []))

/-- The traffic the subject is part of is being controlled at that junction by a police officer or
    by a traffic-control signal. -/
def trafficControlled : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.or officerControls signalControls)

-- ---------------------------------------------------------------------------------------------
-- d4: the act, the place, and the search back from the entry
-- ---------------------------------------------------------------------------------------------
/-- The act the governing sign requires: the halt under a stop sign; the halt or a speed no greater
    than the yield-approach speed under a yield sign. -/
def actRequired : Formula :=
  .or (.and stopSignGoverns halted)
      (.and yieldSignGoverns (.or halted (.cmp speedOfSubject .le pYieldApproachSpeedMax)))

/-- At the marked place: on the carrier, off the place, off the intersection, short of the place
    along the carrier's designated direction and within the stop-point tolerance of it. -/
def atTheMark : Formula :=
  .and (occupies vCarrier)
  (.and (.not (occupies vPlace))
  (.and (.not (occupies vJunction))
  (.and (.cmp offsetToPlace .gt zeroMetres)
        (.cmp distanceToPlace .le pStopPointTolerance))))

/-- The approach start for a marked place: the subject on the carrier the place marks, off the
    place, short of it and farther from it than the stop-point tolerance. -/
def pastTheStoppingZone : Formula :=
  .and (occupies vCarrier)
  (.and (.not (occupies vPlace))
  (.and (.cmp offsetToPlace .gt zeroMetres)
        (.cmp distanceToPlace .gt pStopPointTolerance)))

/-- The previous entry of the subject into that same intersection: an observation at which it is
    within the intersection otherwise than by the entry judged. -/
def previousEntry : Formula := .and (occupies vJunction) (.not entersJunction)

/-- The act at the marked place, searched for back from the entry; the search ends at the approach
    start or at the previous entry, and nowhere else. -/
def searchAtMark : Formula :=
  .since (.not (.or pastTheStoppingZone previousEntry)) (.and atTheMark actRequired)

/-- At the point affording the view: on the carrier, off the intersection, with the sight distance
    along the through highway at least the intersection view sight distance. -/
def atTheViewPoint : Formula :=
  .and (.atom "st_highway" [vWay] [])
  (.and (occupies vCarrier)
  (.and (.not (occupies vJunction))
        (.cmp sightAlongWay .ge pIntersectionViewSightDistance)))

/-- The approach start for that point: upstream of it the view along the way is shorter than the
    reading requires. -/
def shortOfTheViewPoint : Formula :=
  .and (occupies vCarrier)
  (.and (.not (occupies vJunction))
        (.cmp sightAlongWay .lt pIntersectionViewSightDistance))

def searchAtViewPoint : Formula :=
  .since (.not (.or shortOfTheViewPoint previousEntry)) (.and atTheViewPoint actRequired)

/-- A stop line recorded as marking that carrier's entrance. -/
def lineMarksCarrier : Formula :=
  .existsRegion (.lit "stop_line") "place"
    (.and (.atom "st_stop_line" [vPlace] []) (.atom "st_entrance_of" [vPlace, vCarrier] []))

/-- A crosswalk recorded as marking that carrier's entrance. -/
def crossingMarksCarrier : Formula :=
  .existsRegion (.lit "crosswalk") "place"
    (.and (.atom "st_crosswalk" [vPlace] []) (.atom "st_entrance_of" [vPlace, vCarrier] []))

def actAtLine : Formula :=
  .existsRegion (.lit "stop_line") "place"
    (.and (.atom "st_stop_line" [vPlace] [])
    (.and (.atom "st_entrance_of" [vPlace, vCarrier] []) searchAtMark))

def actAtCrossing : Formula :=
  .existsRegion (.lit "crosswalk") "place"
    (.and (.atom "st_crosswalk" [vPlace] [])
    (.and (.atom "st_entrance_of" [vPlace, vCarrier] []) searchAtMark))

def actAtViewPoint : Formula := .existsRegion (.lit "highway") "way" searchAtViewPoint

/-- The three places in the words' order: the line where one marks the carrier, else the crossing
    where one marks it, else the point affording the view. -/
def dutyAtPlace : Formula :=
  .and (.implies lineMarksCarrier actAtLine)
  (.and (.implies (.and (.not lineMarksCarrier) crossingMarksCarrier) actAtCrossing)
        (.implies (.and (.not lineMarksCarrier) (.not crossingMarksCarrier)) actAtViewPoint))

-- ---------------------------------------------------------------------------------------------
-- The rule
-- ---------------------------------------------------------------------------------------------
/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The occasion the duty is owed on: the subject enters the intersection through a carrier a
    proper sign governs. -/
def engagedHere : Formula := .and onApproach (.and properSignErected entersJunction)

/-- Applicability: d1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:; d2 (trigger): When proper signs have been erected, -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "carrier"
    (.existsRegion (.lit "intersection") "junction"
      (.and engagedHere (.not trafficControlled)))

/-- Obligation: d4 (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway. -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "carrier"
    (.forallRegion (.lit "intersection") "junction"
      (.implies engagedHere dutyAtPlace))

def rule : Rule :=
  { id := "NRS_484B_257_1_o1"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "d4"
          why := "the previous entry of the subject into that same intersection, at which the record ends the search back from the entry judged, is written as an observation at which the subject is within that intersection otherwise than by the entry judged (`previousEntry`): the language names no observation but the one judged, so the previous entry is reached through the stay it begins. The search therefore ends one observation later than the record's words, which shortens it and never lengthens it; only a previous entry whose whole stay in the junction falls between two observations is missed."
          kind := "reading" }
      , { span := "d4"
          why := "\"the point nearest the intersection where the driver has a view of approaching traffic\" is written as any observation of the approach, off the intersection, at which the sight distance along the way reaches the intersection view sight distance: no region denotes that point, and the language cannot minimise a distance over the points of a carrier, so the place is read by the view it affords rather than by being the nearest such point. The approach start for that place is read, in the same spirit, as the observations at which the view is shorter than the reading requires."
          kind := "reading" }
      , { span := "d4"
          why := "\"the through highway\" is written as a highway region (`st.highway`) along which the subject has the required view (`st.sight_along_way`): no claimed atom records which of a junction's ways is the through way, so the way is read as one the view is had along."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o1
