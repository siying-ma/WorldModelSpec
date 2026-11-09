/-
  NRS_484B_250_4_o2 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (trigger): When a vehicle enters an intersection controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,
    sib1 (sibling): the driver of the vehicle shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    c1 (condition): After making such a stop,
    s1 (subject): the driver
    st1 (standard): shall proceed cautiously,
    ob1 (obligation): yielding to vehicles which have previously completed a stop or are within the intersection.

  Elements (span → atoms, derived):
    t1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'dev.traffic_signal', 'dev.governs', 'dev.inoperative'], derived ['drv.motion.region_entry']
    c1: atoms ['rel.occupies', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'st.travel_region', 'st.lane_direction', 'st.lane_enters', 'st.intersection', 'st.on_way', 'st.highway', 'st.sight_along_way', 'prim.region_offset_along'], derived ['drv.motion.standstill']
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    ob1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'rel.contact', 'rel.surface_gap', 'kin.speed', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived ['drv.motion.region_entry', 'drv.motion.standstill']

  How each span is written
  ------------------------
  t1 (trigger, in `applicability`). `qualifiedEntry` is the entry observation: the subject's
  footprint comes to overlap a region of kind `intersection` (`drv.motion.region_entry`, over
  `rel.occupies`), and at that same observation a device of kind `traffic_signal` has its faces
  uncovered (`dev.traffic_signal`'s uncovered attribute), shows no valid indication
  (`dev.inoperative`) and governs that junction region (`dev.governs`). The device conditions are
  read at the entry observation, as the words state ("is inoperative at the time the vehicle
  enters the intersection"). The subject's class is the admitted aggregate, in the binder.

  c1 (condition, in `applicability`). `priorStop` carries the halt with every qualification the
  referring words keep. The approach is a region of kind `travel_region` the subject occupies
  (`rel.occupies`), other than the junction itself, whose entrance end is that junction
  (`st.lane_enters`). The halt is `drv.motion.standstill` at the place the sibling sentence names,
  in the order the words state it: at a stop line that marks that carrier (`st.stop_line`,
  `st.entrance_of`); else, where no stop line marks it, at or before the crosswalk that marks it
  (`st.crosswalk`); else, where neither marks it, at a point from which the sight along a way the
  junction lies on (`st.on_way`, `st.highway`) reaches p.intersecting_way_view_distance
  (`st.sight_along_way`). "At or before the mark" is the sign of `prim.region_offset_along` along
  the carrier's designated direction (`st.lane_direction`, which that primitive reads) together
  with the body-to-mark distance of `st.region_geometry` under p.stop_point_tolerance. The search
  runs back from the judged observation to the start of that approach: `count` counts the halts
  since the latest run of "the subject is on that approach carrier" began, so the history ends
  where the record says it ends and nowhere else, and reaches past the recording exactly where
  that run does.

  s1 (subject). The duty binds the vehicle whose controlled motion the driver's conduct is read
  through: the binder `v` of the admitted aggregate (the record's observable reading).

  st1 (standard) and ob1 (obligation, in `obligation`). The duty is read at every observation from
  that qualified entry at which the subject's footprint still overlaps the junction region: the
  applicability is the entry, continued by the subject's unbroken occupancy of that region
  (`since`), which is what "from that entry on, while the subject is moving across or within the
  intersection" states on a trace. `cautiousSpeed` is the operationalized standard: the subject's
  own speed (`kin.speed`) at or below p.cautious_proceed_max_speed. `yieldToThem` grants precedence
  to every other road user of the aggregate that completed a halt on a carrier whose entrance end
  is this junction (`drv.motion.standstill`, `st.travel_region`, `st.lane_enters`, `rel.occupies`)
  or lies within the junction (`rel.occupies`, `st.intersection`): the subject must not enter the
  junction while such a road user lies within it (`drv.motion.region_entry`), must not touch it
  (`rel.contact`), and must not, where their centres approach within p.yield_conflict_horizon
  (`prim.closest_approach_within`), let that approach (`prim.closest_approach_distance`) or the
  present clearance between the two bodies (`rel.surface_gap`) fall below p.yield_min_clearance.

  Narrowings declared below: the halt of another road user is read at some observation up to and
  including the judged one; the clearance bound is read on the present body clearance as well as on
  the predicted centre approach; the duty's scope is the subject's occupancy of the junction from
  the entry on.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantifier variables: the junction, the signal head, the subject's approach carrier, a
    stop line, a crosswalk, a way, another road user and its approach carrier. -/
def iV : Arg := .var "i"
def dV : Arg := .var "d"
def lV : Arg := .var "l"
def mV : Arg := .var "m"
def cV : Arg := .var "c"
def wV : Arg := .var "w"
def yV : Arg := .var "y"
def lyV : Arg := .var "ly"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCautiousProceedMaxSpeed : Term := .param "p.cautious_proceed_max_speed"
def pIntersectingWayViewDistance : Term := .param "p.intersecting_way_view_distance"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The aggregate DEF-NRS-484A-320 admits for "vehicle". -/
def vehicleAggregate : String := "DEF-NRS-484A-320::vehicle"

def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit vehicleAggregate] []
def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
def standstill (x : Arg) : Formula := .derived "drv_motion_standstill" [x] [pStandstillSpeedTolerance]
def entersRegion (x r : Arg) : Formula := .derived "drv_motion_region_entry" [x, r] []

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := isVehicle vV

-- ---------------------------------------------------------------------------------------------
-- t1: the junction's head is installed and uncovered, shows no valid indication, and governs it
-- ---------------------------------------------------------------------------------------------
def signalDark : Formula :=
  .and (.atom "dev_traffic_signal_uncovered" [dV] [])
    (.and (.atom "dev_inoperative" [dV] [])
          (.atom "dev_governs" [dV, iV] []))

-- ---------------------------------------------------------------------------------------------
-- c1: the halt the previous sentence requires, at the place it names, on this approach
-- ---------------------------------------------------------------------------------------------
/-- The approach the subject came through: a travel region it occupies, not the junction itself,
    whose entrance end is that junction. -/
def approachCarrier : Formula :=
  .and (occupies vV lV)
    (.and (.not (.same lV iV)) (.atom "st_lane_enters" [lV, iV] []))

/-- The subject's body is at or before the mark along the carrier's designated direction, within
    the stop-point tolerance of it. -/
def atOrBeforeMark (mk : Arg) : Formula :=
  .and (.cmp (.quantity "prim_region_offset_along" [vV, mk, lV] []) .ge zeroMetres)
       (.cmp (.measure "st_region_geometry_distance" [vV, mk]) .le pStopPointTolerance)

/-- A stop line marks this carrier's entrance. -/
def stopLineOfCarrier : Formula :=
  .existsRegion (.lit "stop_line") "m" (.atom "st_entrance_of" [mV, lV] [])

/-- A crosswalk marks this carrier's entrance. -/
def crosswalkOfCarrier : Formula :=
  .existsRegion (.lit "crosswalk") "c" (.atom "st_entrance_of" [cV, lV] [])

/-- The sight along a way the junction lies on reaches the intersecting-way view distance. -/
def viewOfApproachingTraffic : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "st_on_way" [iV, wV] [])
          (.cmp (.measure "st_sight_along_way" [vV, wV]) .ge pIntersectingWayViewDistance))

/-- The place of the halt, in the order the words state it: the stop line marking this carrier;
    else, where none marks it, the crosswalk marking it; else, where neither marks it, the point
    from which the sight along the way reaches the view distance. -/
def haltPlace : Formula :=
  .or (.existsRegion (.lit "stop_line") "m"
         (.and (.atom "st_entrance_of" [mV, lV] []) (atOrBeforeMark mV)))
   (.or (.and (.not stopLineOfCarrier)
          (.existsRegion (.lit "crosswalk") "c"
             (.and (.atom "st_entrance_of" [cV, lV] []) (atOrBeforeMark cV))))
        (.and (.not stopLineOfCarrier)
          (.and (.not crosswalkOfCarrier) viewOfApproachingTraffic)))

/-- The halt itself: motionless, on this approach, at the place the words name. -/
def haltAtPlace : Formula := .and (standstill vV) (.and (occupies vV lV) haltPlace)

/-- Such a stop was made on this approach: at least one halt at the place since the latest run of
    being on that approach carrier began. -/
def priorStop : Formula :=
  .existsRegion (.lit "travel_region") "l"
    (.and approachCarrier (.count haltAtPlace approachCarrier .ge 1))

-- ---------------------------------------------------------------------------------------------
-- t1 ∧ c1: the qualified entry, and the duty's reach from it
-- ---------------------------------------------------------------------------------------------
def qualifiedEntry : Formula :=
  .and (entersRegion vV iV) (.and signalDark priorStop)

/-- The subject lies within the junction, and did so at every observation since the qualified
    entry into it: "from that entry on, while the subject is moving across or within the
    intersection". The lookback is read only where the subject lies within the junction. -/
def engagedInJunction : Formula :=
  .and (occupies vV iV)
    (.definedWhen (occupies vV iV) (.since (occupies vV iV) qualifiedEntry))

/-- Applicability: t1 (trigger): When a vehicle enters an intersection controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,; c1 (condition): After making such a stop, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsDevice (.lit "traffic_signal") "d" engagedInJunction)

-- ---------------------------------------------------------------------------------------------
-- st1 ∧ ob1: proceed cautiously, yielding
-- ---------------------------------------------------------------------------------------------
/-- st1, operationalized: the subject's own speed at or below the cautious bound. -/
def cautiousSpeed : Formula := .cmp (.measure "kin_speed" [vV]) .le pCautiousProceedMaxSpeed

/-- The other road user completed a halt on a carrier whose entrance end is this junction, at some
    observation up to and including this one. -/
def haltedAtEntrance : Formula :=
  .since .tt
    (.existsRegion (.lit "travel_region") "ly"
      (.and (occupies yV lyV)
        (.and (.not (.same lyV iV))
          (.and (.atom "st_lane_enters" [lyV, iV] []) (standstill yV)))))

/-- The road users the subject owes precedence to: another road user of the aggregate that either
    completed such a halt or lies within the junction. -/
def owedPrecedence : Formula :=
  .and (.not (.same yV vV))
    (.and (isVehicle yV) (.or haltedAtEntrance (occupies yV iV)))

/-- Precedence is not granted: the subject enters the junction while that road user lies within
    it, touches it, or closes on it under constant velocities within the horizon to less than the
    clearance, in the present body clearance or in the centre distance at the closest approach. -/
def precedenceDenied : Formula :=
  .or (.and (entersRegion vV iV) (occupies yV iV))
   (.or (.atom "rel_contact" [vV, yV] [])
        (.and (.derived "prim_closest_approach_within" [vV, yV] [pYieldConflictHorizon])
          (.or (.cmp (.quantity "prim_closest_approach_distance" [vV, yV] [pYieldConflictHorizon])
                     .lt pYieldMinClearance)
               (.cmp (.measure "rel_surface_gap" [vV, yV]) .lt pYieldMinClearance))))

def yieldToThem : Formula :=
  .forallUser "y" (.implies owedPrecedence (.not precedenceDenied))

def duty : Formula := .and cautiousSpeed yieldToThem

/-- Obligation: st1 (standard): shall proceed cautiously,; ob1 (obligation): yielding to vehicles which have previously completed a stop or are within the intersection. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (.existsDevice (.lit "traffic_signal") "d" engagedInJunction) duty)

def rule : Rule :=
  { id := "NRS_484B_250_4_o2"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "shall proceed cautiously"
          concepts := ["drv.motion.region_entry", "kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "st.intersection"]
          params := ["p.cautious_proceed_max_speed", "p.yield_conflict_horizon", "p.yield_min_clearance"]
          convention := "A low-speed stopping-distance convention bounds the caution: moving off from a required halt, the subject's speed where it enters and crosses the junction is held at or below p.cautious_proceed_max_speed, the speed at which a vehicle can halt within the junction's conflict area on seeing a road user it must give way to; the degree of the hazard enters through the conflict-avoidance convention, the closest approach under constant velocities within p.yield_conflict_horizon staying clear of p.yield_min_clearance, so that the bound moves with the proximity and the closing speed of the road users the same sentence names rather than switching on their presence alone."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "ob1"
          why := "'which have previously completed a stop' is read as a standstill of that road user, on a carrier whose entrance end is this junction, at some observation of the recording up to and including the judged one: the language looks back to an observation at or before the one it judges, and a road user standing at an entrance at the judged observation has come to the halt the words describe."
          kind := "reading" }
      , { span := "ob1"
          why := "the clearance of p.yield_min_clearance is read on two measurements the record names together: the centre distance at the closest approach under constant velocities within p.yield_conflict_horizon (prim.closest_approach_distance), and the clearance between the nearest points of the two bodies at the observation (rel.surface_gap); precedence is denied where either falls below it while the centres approach within the horizon."
          kind := "reading" }
      , { span := "st1"
          why := "the duty is read at every observation from the qualified entry at which the subject's footprint still overlaps the junction region, that unbroken occupancy carrying 'from that entry on, while the subject is moving across or within the intersection'; it is not read after the subject's footprint has left the junction."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o2
