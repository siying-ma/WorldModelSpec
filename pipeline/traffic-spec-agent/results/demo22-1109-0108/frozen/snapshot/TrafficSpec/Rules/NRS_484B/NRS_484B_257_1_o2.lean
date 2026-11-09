/-
  NRS_484B_257_1_o2 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    sib1 (sibling): When proper signs have been erected, the driver of a vehicle shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    c1 (condition): After having stopped or, in the event of a yield sign, slowed or stopped,
    s1 (subject): the driver
    ob1 (obligation): shall yield the right-of-way to other vehicles which have entered the intersection from such through highway
    st1 (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard
    c2 (condition): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.intersection'], derived []
    c1: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'kin.speed', 'rel.occupies', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'st.travel_region', 'st.lane_direction', 'st.lane_enters', 'st.intersection', 'st.on_way', 'st.highway', 'st.sight_along_way', 'prim.region_offset_along'], derived ['drv.motion.standstill']
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    ob1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'st.on_way', 'st.highway', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'rel.surface_gap', 'rel.contact', 'kin.speed', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived ['drv.motion.region_entry']
    c2: atoms ['rel.occupies', 'st.intersection', 'kin.speed'], derived []

  How each span is written.

  s1 — the subject. `clsV`: the binder's class is the admitted aggregate
  DEF-NRS-484A-320::vehicle, one `ru_aggregate` atom with the aggregate's id as its literal
  argument.

  c2 — when the duty is read. `movingInJunction`: the subject's footprint overlaps the junction
  region (`rel_occupies` on a region the `intersection` quantifier ranges over) and its speed is
  above p.standstill_speed_tolerance. The junction so selected is the region every other span of
  the applicability and the obligation speaks of.

  c1 — the act referred to, carried with every qualification the referring words keep.
  `approachGoverned` selects the subject's approach carrier: a region of the kind
  `travel_region` whose entrance end is that junction (`st_lane_enters`) and whose traffic a stop
  sign or a yield sign governs (`dev_stop_sign`/`dev_yield_sign` with `dev_governs`), which is the
  observable evidence of the designation the first sentence presupposes. `haltPlace` is the place
  the first sentence names, in the order it names it: the stop line marking that carrier's
  entrance (`st_stop_line`, `st_entrance_of`), else — where no stop line marks it — the crosswalk
  marking it (`st_crosswalk`), else — where neither does — the point at which the view along a way
  of the junction (`st_highway`, `st_on_way`, `st_sight_along_way`) reaches
  p.intersecting_way_view_distance. At a mark, `atMark` reads the body's distance to the mark
  (`st_region_geometry`) within p.stop_point_tolerance and the mark not behind the body: the signed
  offset along the carrier's designated direction (`prim.region_offset_along`, which reads
  `st.lane_direction`) at or above zero. `haltOrSlowed` is the act at that place: the standstill
  DEF-NRS-484A-255 requires (`drv.motion.standstill` with p.standstill_speed_tolerance), or, where
  a yield sign and not a stop sign governs the carrier, a speed at or below
  p.yield_sign_slowed_max_speed. `actedOnApproach` carries the order the words give: a rising edge
  of that act since the start of the subject's latest run of occupying that carrier — the approach
  through which it reached the junction. The search therefore ends where the record says it ends
  (at the beginning of that approach) and is unknown exactly where that approach begins before the
  recording.

  e1 — the exception. `controlledHere`: a police officer (`dev_human_direction` with role
  police_officer) or a traffic-control signal (`dev_traffic_signal`) governs (`dev_governs`) the
  junction or the subject's approach carrier, and traffic — a road user of the aggregate
  DEF-NRS-484A-285::traffic — occupies the region so governed. It is conjoined negated into the
  applicability.

  ob1/st1 — the duty. `obligation`: at every junction the subject occupies, for the approach
  carrier the condition selected, and for every way of that junction that is not a way its own
  carrier lies on (the crossing, through highway: `st_highway`, `st_on_way`), every road user of
  the aggregate other than the subject that is privileged is granted precedence.
  `enteredFromThrough` (ob1): the vehicle's footprint overlaps the junction and, since an
  observation at which it came to overlap it (`drv.motion.region_entry`) while occupying a carrier
  entering that junction and lying on that highway, it has lain within the junction.
  `approachingClosely` (st1): it occupies such a carrier and either its distance to the junction
  (`st.region_geometry`) is at most its own speed times p.yield_headway_time or the closest
  approach to the subject falls below p.yield_min_clearance within p.yield_conflict_horizon.
  `grantsPrecedence`: no contact (`rel.contact`) and no such closest approach.

  Narrowings declared (readings chosen on carried duty and standard spans; the record's own
  narrowings are not restated):
    ob1 — "the closest approach falling below the clearance" is read as either the centre distance
      at the closest approach within the horizon (`prim.closest_approach_within`,
      `prim.closest_approach_distance`, which compute on the centres) falling below
      p.yield_min_clearance, or the present gap between the nearest points of the two bodies
      (`rel.surface_gap`, which measures the clearance the convention names) falling below it.
    st1 — the standard's two figures are read as alternatives, as the node's own obligation states
      them ("its distance to the junction at most its speed times p.yield_headway_time, or its
      closest approach ... below p.yield_min_clearance").

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantifier variables: the junction, the subject's approach carrier, the through highway,
    the stop line, the crosswalk, the other vehicle and the carrier it came through. -/
def jV : Arg := .var "j"
def lV : Arg := .var "l"
def wV : Arg := .var "w"
def mV : Arg := .var "m"
def xV : Arg := .var "x"
def uV : Arg := .var "u"
def cV : Arg := .var "c"
def trV : Arg := .var "tr"
def dV : Arg := .var "d"
def yV : Arg := .var "y"
def oV : Arg := .var "o"
def sgV : Arg := .var "sg"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pIntersectingWayViewDistance : Term := .param "p.intersecting_way_view_distance"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldHeadwayTime : Term := .param "p.yield_headway_time"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"
def pYieldSignSlowedMaxSpeed : Term := .param "p.yield_sign_slowed_max_speed"

def zeroMetres : Term := .lit Q.zero .metre

-- ---------------------------------------------------------------------------------------------
-- Leaves
-- ---------------------------------------------------------------------------------------------
/-- `rel.occupies`: the road user's footprint overlaps the region. -/
def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
/-- `kin.speed`: the magnitude of the road user's velocity. -/
def speedOf (x : Arg) : Term := .measure "kin_speed" [x]
/-- `st.region_geometry`: the ground distance from the road user's body outline to the region. -/
def bodyDistanceTo (x r : Arg) : Term := .measure "st_region_geometry_distance" [x, r]
/-- `prim.region_offset_along`: the signed distance from the body's reference point to the region,
    along the carrier's designated direction. -/
def offsetAlong (x r l : Arg) : Term := .quantity "prim_region_offset_along" [x, r, l] []

/-- Membership of the aggregate DEF-NRS-484A-320 defines (s1, ob1). -/
def vehicleAggregate (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []
/-- Membership of the aggregate DEF-NRS-484A-285 defines (e1). -/
def trafficAggregate (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-285::traffic"] []

/-- A stop sign governs the carrier's traffic. -/
def stopSignGoverns (l : Arg) : Formula :=
  .existsDevice (.lit "stop_sign") "d" (.atom "dev_governs" [dV, l] [])
/-- A yield sign governs the carrier's traffic. -/
def yieldSignGoverns (l : Arg) : Formula :=
  .existsDevice (.lit "yield_sign") "y" (.atom "dev_governs" [yV, l] [])

-- ---------------------------------------------------------------------------------------------
-- e1 (exception): traffic being controlled by a police officer or a traffic-control signal
-- ---------------------------------------------------------------------------------------------
/-- Traffic lies in the region: a road user of the aggregate DEF-NRS-484A-285 admits occupies it. -/
def trafficIn (r : Arg) : Formula :=
  .existsUser "tr" (.and (trafficAggregate trV) (occupies trV r))

/-- The device controls the traffic of the junction, or that of the subject's approach carrier. -/
def controlsTrafficAt (dv j l : Arg) : Formula :=
  .or (.and (.atom "dev_governs" [dv, j] []) (trafficIn j))
      (.and (.atom "dev_governs" [dv, l] []) (trafficIn l))

/-- A police officer is directing the traffic here. -/
def policeControls (j l : Arg) : Formula :=
  .existsDevice (.lit "human_direction") "o"
    (.and (.atom "dev_human_direction_role" [oV, .lit "police_officer"] [])
          (controlsTrafficAt oV j l))

/-- A traffic-control signal is controlling the traffic here. -/
def signalControls (j l : Arg) : Formula :=
  .existsDevice (.lit "traffic_signal") "sg" (controlsTrafficAt sgV j l)

/-- e1: traffic here is being controlled by a police officer or by a traffic-control signal. -/
def controlledHere (j l : Arg) : Formula := .or (policeControls j l) (signalControls j l)

-- ---------------------------------------------------------------------------------------------
-- c1 (condition): after having stopped or, in the event of a yield sign, slowed or stopped
-- ---------------------------------------------------------------------------------------------
/-- The subject's body is at the mark, within the stop-point tolerance, and the mark is not behind
    it along the carrier's direction. -/
def atMark (mk l : Arg) : Formula :=
  .and (.cmp (bodyDistanceTo vV mk) .le pStopPointTolerance)
       (.cmp (offsetAlong vV mk l) .ge zeroMetres)

/-- A stop line marks the carrier's entrance into the intersection. -/
def stopLineOf (l : Arg) : Formula :=
  .existsRegion (.lit "stop_line") "m" (.atom "st_entrance_of" [mV, l] [])
/-- The subject is at the stop line marking its carrier's entrance. -/
def haltAtStopLine (l : Arg) : Formula :=
  .existsRegion (.lit "stop_line") "m"
    (.and (.atom "st_entrance_of" [mV, l] []) (atMark mV l))

/-- A crosswalk marks the carrier's entrance into the intersection. -/
def crosswalkOf (l : Arg) : Formula :=
  .existsRegion (.lit "crosswalk") "x" (.atom "st_entrance_of" [xV, l] [])
/-- The subject is before the crosswalk marking its carrier's entrance. -/
def haltAtCrosswalk (l : Arg) : Formula :=
  .existsRegion (.lit "crosswalk") "x"
    (.and (.atom "st_entrance_of" [xV, l] []) (atMark xV l))

/-- The point at which the subject's view along a way of the junction reaches the view distance. -/
def haltAtViewPoint (j : Arg) : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "st_on_way" [j, wV] [])
          (.cmp (.measure "st_sight_along_way" [vV, wV]) .ge pIntersectingWayViewDistance))

/-- The place the first sentence names, in the order it names it. -/
def haltPlace (l j : Arg) : Formula :=
  .or (haltAtStopLine l)
      (.and (.not (stopLineOf l))
        (.or (haltAtCrosswalk l)
             (.and (.not (crosswalkOf l)) (haltAtViewPoint j))))

/-- The act the first sentence requires, at that place: the standstill, or, under a yield sign and
    no stop sign, a speed at or below the slowed-approach speed. -/
def haltOrSlowed (l j : Arg) : Formula :=
  .and (haltPlace l j)
    (.or (.derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance])
      (.and (.and (yieldSignGoverns l) (.not (stopSignGoverns l)))
            (.cmp (speedOf vV) .le pYieldSignSlowedMaxSpeed)))

/-- The subject's approach carrier: a travel region whose entrance end is that junction and whose
    traffic a stop sign or a yield sign governs. -/
def approachGoverned (l j : Arg) : Formula :=
  .and (.atom "st_lane_enters" [l, j] [])
       (.or (stopSignGoverns l) (yieldSignGoverns l))

/-- c1: the act was performed during the subject's approach through that carrier — a rising edge of
    it since the start of the subject's latest run of occupying the carrier. -/
def actedOnApproach (l j : Arg) : Formula :=
  .count (haltOrSlowed l j) (occupies vV l) .ge 1

/-- c2: the subject is moving across or within the junction. -/
def movingInJunction (j : Arg) : Formula :=
  .and (occupies vV j) (.cmp (speedOf vV) .gt pStandstillSpeedTolerance)

-- ---------------------------------------------------------------------------------------------
-- ob1 / st1: granting precedence
-- ---------------------------------------------------------------------------------------------
/-- The carrier a road user occupies whose entrance end is that junction and which lies on the
    way `w`. -/
def throughCarrier (u j w : Arg) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (occupies u cV)
      (.and (.atom "st_lane_enters" [cV, j] []) (.atom "st_on_way" [cV, w] [])))

/-- ob1: the vehicle has entered the junction from a carrier on that highway and has lain within
    the junction since. -/
def enteredFromThrough (u j w : Arg) : Formula :=
  .and (occupies u j)
    (.since (occupies u j)
      (.and (.derived "drv_motion_region_entry" [u, j] []) (throughCarrier u j w)))

/-- The closest approach of the two bodies within the conflict horizon falls below the clearance. -/
def closeApproach (a b : Arg) : Formula :=
  .and (.derived "prim_closest_approach_within" [a, b] [pYieldConflictHorizon])
    (.or (.cmp (.quantity "prim_closest_approach_distance" [a, b] [pYieldConflictHorizon]) .lt
            pYieldMinClearance)
         (.cmp (.measure "rel_surface_gap" [a, b]) .lt pYieldMinClearance))

/-- st1: the vehicle is approaching on that highway so closely as to constitute an immediate
    hazard. -/
def approachingClosely (u j w : Arg) : Formula :=
  .and (throughCarrier u j w)
    (.or (.cmp (bodyDistanceTo u j) .le (.mul (speedOf u) pYieldHeadwayTime))
         (closeApproach vV u))

/-- A road user the subject must grant precedence to. -/
def privileged (u j w : Arg) : Formula :=
  .and (.not (.same u vV))
    (.and (vehicleAggregate u)
      (.or (enteredFromThrough u j w) (approachingClosely u j w)))

/-- Granting precedence: no contact, and no closest approach below the clearance. -/
def grantsPrecedence (u : Arg) : Formula :=
  .and (.not (.atom "rel_contact" [vV, u] []))
       (.not (closeApproach vV u))

-- ---------------------------------------------------------------------------------------------
-- The rule
-- ---------------------------------------------------------------------------------------------
/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := vehicleAggregate vV

/-- Applicability: e1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:; c1 (condition): After having stopped or, in the event of a yield sign, slowed or stopped,; c2 (condition): during the time such driver is moving across or within the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "j"
    (.and (movingInJunction jV)
      (.existsRegion (.lit "travel_region") "l"
        (.and (approachGoverned lV jV)
          (.and (.not (controlledHere jV lV)) (actedOnApproach lV jV)))))

/-- Obligation: ob1 (obligation): shall yield the right-of-way to other vehicles which have entered the intersection from such through highway; st1 (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "j"
    (.implies (occupies vV jV)
      (.forallRegion (.lit "travel_region") "l"
        (.implies (approachGoverned lV jV)
          (.forallRegion (.lit "highway") "w"
            (.implies (.and (.atom "st_on_way" [jV, wV] [])
                            (.not (.atom "st_on_way" [lV, wV] [])))
              (.forallUser "u" (.implies (privileged uV jV wV) (grantsPrecedence uV))))))))

def rule : Rule :=
  { id := "NRS_484B_257_1_o2"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "or which are approaching so closely on such through highway as to constitute an immediate hazard"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "rel.surface_gap", "st.highway", "st.intersection", "st.lane_enters", "st.on_way", "st.region_geometry", "st.travel_region"]
          params := ["p.yield_headway_time", "p.yield_conflict_horizon", "p.yield_min_clearance"]
          convention := "Gap-acceptance convention for a stop- or yield-controlled crossing. 'So closely' is the other vehicle's distance to the junction, which st.region_geometry gives as 'the ground distance from a road user's body outline to it', read on a vehicle whose carrier lies on the through highway (rel.occupies, st.travel_region, st.lane_enters, st.on_way, st.highway): the vehicle is so close where that distance is at most its own speed (kin.speed) times p.yield_headway_time, so the bound moves with its speed -- a faster approach makes a greater distance count, a slower one a smaller -- rather than switching on its presence. The immediacy is read in the same breath by the conflict-avoidance convention: the closest approach between the two bodies under constant velocities within p.yield_conflict_horizon falling below p.yield_min_clearance, measured between the nearest points of the bodies by rel.surface_gap. Both figures are the reading's, from gap-acceptance tables for a crossing manoeuvre, and neither is the law's."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "ob1"
          why := "'the closest approach ... below p.yield_min_clearance' is read as either the centre distance at the closest approach within p.yield_conflict_horizon (prim.closest_approach_within, prim.closest_approach_distance, which compute on the centres under constant velocities) falling below the clearance, or the gap between the nearest points of the two bodies (rel.surface_gap, the clearance the convention names) falling below it: the primitive gives the approach, the relation the measure between the bodies."
          kind := "reading" }
      , { span := "st1"
          why := "the standard's two figures are read as alternatives, as the node's own obligation states them ('its distance to the junction at most its speed times p.yield_headway_time, or its closest approach to the subject ... below p.yield_min_clearance'): a vehicle on the through highway that meets either is approaching so closely as to constitute an immediate hazard."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o2
