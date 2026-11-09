/-
  Witnesses for NRS_484A_450_2.

  The geometry, once, in the world frame (+x east, +y north); every figure here is the witness's
  own and appears nowhere in the rule.

  A minor two-way street runs east-west: the highway region `minorWay` is x ∈ [-50, 50],
  y ∈ [-5, 5]. A major street runs north-south: the highway region `majorWay` is x ∈ [20, 30],
  y ∈ [-100, 100]. They meet at the four-way junction `junction`, the intersection region
  x ∈ [20, 30], y ∈ [-5, 5], which lies on both ways.

  The eastbound approach `approachLane` is the lane x ∈ [0, 20], y ∈ [-5, 0], direction east,
  recorded as entering `junction`, lying on `minorWay`. A stop sign governs it.

  The marks, each recorded as marking that lane's entrance (their entrances observed, so their
  lists are complete):
    * `crossing`, a marked crosswalk x ∈ [18, 20] across the whole minor way;
    * `stopLine`, a stop line x ∈ [16, 16.4] in the eastbound half;
    * `farStopLine`, a stop line x ∈ [14, 14.4], used by the history-boundary witness only.

  The car is 5 m long and 2 m wide (half-extents 2.5 m and 1 m), centred on y = -2.5, heading
  east; `x` below is its reference point, so its body outline is [x - 2.5, x + 2.5]. Occupancy is
  stated in each scene, since a reference point lies in one polygon while the body overlaps
  several. At x = 15 the body ends 0.5 m short of the crossing (inside the 1 m stop-point
  tolerance); at x = 14 it ends 1.5 m short of it (outside); at x = 13 it ends 0.5 m short of
  `stopLine`; at x = 19 or 21 it overlaps the junction, at x = 17 the crossing only.

  In the view witnesses no mark is recorded at all, the car carries a sight distance along the
  major way (40 m where the approach is blind, 120 m where it is open, against the reading's
  100 m), and a second vehicle stands on the major way 60 m south of the junction, visible or
  occluded as the scenario states.

  Observations are one second apart; the car's speeds are the readings at each observation
  (4 m/s rolling, 0 at a halt, against the reading's 0.1 m/s standstill tolerance).
-/
import TrafficSpec.Rules.NRS_484A.NRS_484A_450_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484A_450_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

def car : TrackId := 1
def crossTraffic : TrackId := 2

def laneId : RegionId := 10
def crossLaneId : RegionId := 11
def junctionId : RegionId := 20
def crossingId : RegionId := 30
def stopLineId : RegionId := 31
def farStopLineId : RegionId := 32
def minorWayId : RegionId := 40
def majorWayId : RegionId := 41
def signId : DeviceId := 50

-- ---------------------------------------------------------------------------------------------
-- The world
-- ---------------------------------------------------------------------------------------------
def approachLane : Structure :=
  { Build.lane laneId [(m 0, m (-5)), (m 20, m (-5)), (m 20, m 0), (m 0, m 0)] Build.east
      (enters := some junctionId) with ways := some [minorWayId] }

/-- The northbound approach on the major way: a carrier the car never occupies. -/
def crossLane : Structure :=
  { Build.lane crossLaneId [(m 20, m (-100)), (m 25, m (-100)), (m 25, m (-5)), (m 20, m (-5))]
      Build.north (enters := some junctionId) with ways := some [majorWayId] }

def junction : Structure :=
  { Build.rect junctionId .intersection (m 20) (m (-5)) (m 30) (m 5) with
      ways := some [minorWayId, majorWayId] }

def minorWay : Structure := Build.rect minorWayId .highway (m (-50)) (m (-5)) (m 50) (m 5)
def majorWay : Structure := Build.rect majorWayId .highway (m 20) (m (-100)) (m 30) (m 100)

def crossing : Structure :=
  { Build.rect crossingId .crosswalk (m 18) (m (-5)) (m 20) (m 5) with
      marked := some true, ways := some [minorWayId],
      entranceOf := [laneId], entranceObserved := true }

def stopLine : Structure :=
  { Build.rect stopLineId .stopLine (m 16) (m (-5)) (cm 1640) (m 0) with
      ways := some [minorWayId], entranceOf := [laneId], entranceObserved := true }

def farStopLine : Structure :=
  { Build.rect farStopLineId .stopLine (m 14) (m (-5)) (cm 1440) (m 0) with
      ways := some [minorWayId], entranceOf := [laneId], entranceObserved := true }

def crosswalkWorld : List Structure := [approachLane, junction, crossing, minorWay, majorWay]
def stopLineWorld : List Structure := [approachLane, junction, stopLine, minorWay, majorWay]
def farStopLineWorld : List Structure := [approachLane, junction, farStopLine, minorWay, majorWay]
def bareWorld : List Structure := [approachLane, junction, minorWay, majorWay]
def crossLaneWorld : List Structure := [approachLane, crossLane, junction, minorWay, majorWay]

def signOnLane : Device := Build.sign signId .stopSign [laneId]
def signOnCrossLane : Device := Build.sign signId .stopSign [crossLaneId]

-- ---------------------------------------------------------------------------------------------
-- Bodies and scenes
-- ---------------------------------------------------------------------------------------------
def carAt (x speed : Q) : RoadUser :=
  Build.user car [.motorVehicle] (x, cm (-250)) Build.east speed (cm 250, m 1, cm 150)

/-- A pedal cycle propelled by human power: a class the vehicle definition leaves out. -/
def cycleAt (x speed : Q) : RoadUser :=
  Build.user car [.bicycle] (x, cm (-250)) Build.east speed (cm 90, cm 30, cm 90)

/-- The regions the body overlaps, by where it stands on the approach. -/
def onApproach : List RegionId := [laneId, minorWayId]
def overCrossing : List RegionId := [laneId, crossingId, minorWayId]
def overStopLine : List RegionId := [laneId, stopLineId, minorWayId]
def overFarStopLine : List RegionId := [laneId, farStopLineId, minorWayId]
def enteringOverCrossing : List RegionId := [laneId, crossingId, junctionId, minorWayId, majorWayId]
def entering : List RegionId := [laneId, junctionId, minorWayId, majorWayId]
def inJunction : List RegionId := [junctionId, minorWayId, majorWayId]

def sceneAt (t : Timestamp) (u : RoadUser) (occ : List RegionId)
    (world : List Structure) (devices : List Device) : Scene :=
  Build.scene t (some car) [u] world devices (occupies := some (occ.map fun r => (car, r)))

/-- A scene of the view branch: no mark anywhere, a sight distance along the major way, and a
    second vehicle on it, visible or occluded as the source records. -/
def viewScene (t : Timestamp) (x speed sight : Q) (visible : Bool) (occ : List RegionId) : Scene :=
  let subject := { carAt x speed with sightAlongWay := some [(majorWayId, sight)] }
  let other := Build.user crossTraffic [.motorVehicle] (cm 2500, m (-60)) Build.north (mps 15)
    (cm 250, m 1, cm 150)
  Build.withRelations
    (Build.scene t (some car) [subject, other] bareWorld [signOnLane]
      (occupies := some ((occ.map fun r => (car, r)) ++ [(crossTraffic, majorWayId)])))
    [Build.relation car crossTraffic (fun r => { r with visible := some visible })]

-- ---------------------------------------------------------------------------------------------
-- The planned scenarios
-- ---------------------------------------------------------------------------------------------
/-- `forbid` (violated): A car runs along a marked lane that the source records as entering a four-way junction, and a stop sign governs that lane. A marked crosswalk is recorded as marking that lane's entrance. From the last observation at which the car is off the crossing, short of it and more than the stop-point tolerance from it, through to the observation at which its footprint first overlaps the junction, its speed never falls to the standstill tolerance: it rolls over the crossing at about 4 m/s and enters the junction. -/
def forbidTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (carAt (m 7) (mps 4)) onApproach crosswalkWorld [signOnLane]
    | 1 => sceneAt t (carAt (m 11) (mps 4)) onApproach crosswalkWorld [signOnLane]
    | 2 => sceneAt t (carAt (m 15) (mps 4)) onApproach crosswalkWorld [signOnLane]
    | 3 => sceneAt t (carAt (m 19) (mps 4)) enteringOverCrossing crosswalkWorld [signOnLane]
    | _ => sceneAt t (carAt (m 23) (mps 4)) inJunction crosswalkWorld [signOnLane]

/-- `permit` (compliant): The same approach and the same crossing. Two seconds before the crossing the car's speed falls to zero and stays there for several observations, its body short of the crossing along the lane's designated direction and within the stop-point tolerance of it, its footprint overlapping neither the crossing nor the junction; it then moves off and enters the junction. -/
def permitTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (carAt (m 7) (mps 4)) onApproach crosswalkWorld [signOnLane]
    | 1 => sceneAt t (carAt (m 11) (mps 4)) onApproach crosswalkWorld [signOnLane]
    | 2 => sceneAt t (carAt (m 14) (mps 2)) onApproach crosswalkWorld [signOnLane]
    | 3 => sceneAt t (carAt (m 15) Q.zero) onApproach crosswalkWorld [signOnLane]
    | 4 => sceneAt t (carAt (m 15) Q.zero) onApproach crosswalkWorld [signOnLane]
    | 5 => sceneAt t (carAt (m 17) (mps 2)) overCrossing crosswalkWorld [signOnLane]
    | _ => sceneAt t (carAt (m 19) (mps 4)) enteringOverCrossing crosswalkWorld [signOnLane]

/-- `idle` (not_applicable): A pedal cycle propelled by human power — a device the vehicle definition leaves out, so the aggregate is false for it — rides along the same stop-sign-governed lane and into the junction without halting anywhere. No vehicle is bound and the rule does not engage. -/
def idleTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (cycleAt (m 7) (mps 4)) onApproach crosswalkWorld [signOnLane]
    | 1 => sceneAt t (cycleAt (m 11) (mps 4)) onApproach crosswalkWorld [signOnLane]
    | 2 => sceneAt t (cycleAt (m 15) (mps 4)) onApproach crosswalkWorld [signOnLane]
    | _ => sceneAt t (cycleAt (m 21) (mps 4)) inJunction crosswalkWorld [signOnLane]

/-- `blind` (unknown): The forbid approach, with the source declaring the speed of road users absent: the trigger is decided (the lane, its entrance into the junction, the stop sign's governance and the entry are all recorded), but no observation of the approach decides whether the car came to a complete cessation from movement, so the search for the act neither finds it nor excludes it. -/
def blindTrace : Trace := forbidTrace

/-- `history_boundary` (unknown): The recording begins with the car already over the stop line and short of the junction, its body nearer the mark than the stop-point tolerance, so no observation at which it was outside the mark's stopping zone upstream is recorded; it enters the junction two observations later without halting in the recorded part. The search back from the entry reaches neither the start of the approach nor a previous entry of this car into this junction, and no recorded halt decides the duty. -/
def history_boundaryTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (carAt (cm 1420) (mps 3)) overFarStopLine farStopLineWorld [signOnLane]
    | 1 => sceneAt t (carAt (m 17) (mps 3)) onApproach farStopLineWorld [signOnLane]
    | _ => sceneAt t (carAt (m 21) (mps 4)) entering farStopLineWorld [signOnLane]

-- ---------------------------------------------------------------------------------------------
-- The branches the planned scenes do not reach
-- ---------------------------------------------------------------------------------------------
/-- `branch_1` (compliant): no crosswalk marks the lane; a clearly marked stop line does. The car
    halts 0.5 m short of the line, moves over it and enters the junction. -/
def branch_1Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (carAt (m 7) (mps 4)) onApproach stopLineWorld [signOnLane]
    | 1 => sceneAt t (carAt (m 11) (mps 2)) onApproach stopLineWorld [signOnLane]
    | 2 => sceneAt t (carAt (m 13) Q.zero) onApproach stopLineWorld [signOnLane]
    | 3 => sceneAt t (carAt (m 17) (mps 3)) overStopLine stopLineWorld [signOnLane]
    | _ => sceneAt t (carAt (m 21) (mps 4)) entering stopLineWorld [signOnLane]

/-- `branch_2` (violated): neither a crosswalk nor a stop line marks the lane. The approach is
    blind at first (40 m along the major way), opens up to 120 m, and the car rolls through the
    point at which the view is met and into the junction without halting. -/
def branch_2Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => viewScene t (m 7) (mps 4) (m 40) true onApproach
    | 1 => viewScene t (m 11) (mps 4) (m 40) true onApproach
    | 2 => viewScene t (m 15) (mps 4) (m 120) true onApproach
    | _ => viewScene t (m 19) (mps 4) (m 120) true entering

/-- `branch_3` (compliant): the same unmarked approach; the car halts where the view along the
    major way is 120 m and the vehicle on that way is visible from it, then enters. -/
def branch_3Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => viewScene t (m 7) (mps 4) (m 40) true onApproach
    | 1 => viewScene t (m 11) (mps 2) (m 40) true onApproach
    | 2 => viewScene t (m 15) Q.zero (m 120) true onApproach
    | _ => viewScene t (m 19) (mps 4) (m 120) true entering

/-- `branch_4` (violated): the same halt, and the sight distance along the major way is 120 m, but
    the vehicle standing on that way is occluded from the car at every observation, so the view
    the standard names is not met where it halts. -/
def branch_4Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => viewScene t (m 7) (mps 4) (m 40) false onApproach
    | 1 => viewScene t (m 11) (mps 2) (m 40) false onApproach
    | 2 => viewScene t (m 15) Q.zero (m 120) false onApproach
    | _ => viewScene t (m 19) (mps 4) (m 120) false entering

/-- `branch_5` (violated): the car halts short of the crossing and enters the junction (that entry
    discharged), backs out onto the approach over the crossing, and enters again without halting:
    the second entry owes its own halt and the search back from it ends at the previous entry. -/
def branch_5Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (carAt (m 11) (mps 4)) onApproach crosswalkWorld [signOnLane]
    | 1 => sceneAt t (carAt (m 15) Q.zero) onApproach crosswalkWorld [signOnLane]
    | 2 => sceneAt t (carAt (m 19) (mps 4)) enteringOverCrossing crosswalkWorld [signOnLane]
    | 3 => sceneAt t (carAt (m 23) (mps 4)) inJunction crosswalkWorld [signOnLane]
    | 4 => sceneAt t (carAt (m 17) (mps 2)) overCrossing crosswalkWorld [signOnLane]
    | _ => sceneAt t (carAt (m 21) (mps 4)) enteringOverCrossing crosswalkWorld [signOnLane]

/-- `branch_6` (not_applicable): the stop sign the scene records governs the northbound approach on
    the major way, not the lane the car occupies, so no stop sign indicates the junction for it. -/
def branch_6Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (carAt (m 7) (mps 4)) onApproach crossLaneWorld [signOnCrossLane]
    | 1 => sceneAt t (carAt (m 11) (mps 4)) onApproach crossLaneWorld [signOnCrossLane]
    | 2 => sceneAt t (carAt (m 15) (mps 4)) onApproach crossLaneWorld [signOnCrossLane]
    | _ => sceneAt t (carAt (m 21) (mps 4)) entering crossLaneWorld [signOnCrossLane]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484A_450_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach the trace lacks: the observations between the car's exit from the stop line's stopping zone upstream and the start of the recording, in which the halt the duty requires could have been made")
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable ]

end TrafficSpecWitness.NRS_484A_450_2
