/-
  Witnesses for NRS_484B_307_6a.

  The geometry, shared by every scenario below. The world frame is +x east, +y north and every
  figure here is this file's own; none of it appears in the rule.

    region 10  the subject's approach: a lane 60 m long and 4 m wide, x ∈ [-60, 0], y ∈ [-4, 0],
               running east, whose entrance end is region 20;
    region 20  the junction: an intersection region, x ∈ [0, 20], y ∈ [-10, 10];
    region 11  (branch_4 only) a second approach to the same junction, from the south,
               x ∈ [6, 14], y ∈ [-60, -10], running north;
    region 30  (branch_2 only) a marked crosswalk south of the junction, x ∈ [0, 20],
               y ∈ [-14, -10];
    device 100 head A, a signal head governing region 10;
    device 101 (branch_4 only) head B, a signal head governing region 11.

  The subject is track 1: a motor vehicle 5 m by 2 m on the centreline of region 10 (y = -2), east
  bound, so that a centre at x = -1 puts its nose 1.5 m inside the junction and a centre at x = -4
  keeps its whole body out of it. In branch_2 track 1 is a pedestrian instead.

  Occupancy is stated in every scene rather than taken from the reference point, because at the
  instant of entry the body lies across the lane and the junction at once.

  The rule looks back (the steady yellow alone may have been shown at an earlier observation of the
  same approach), and strong-since is unknown where its past runs off the start of the trace. No
  witness here needs padding or a window: in every scenario the first observation either shows the
  yellow alone (so the look-back is settled true there) or has the subject off the carrier (so it is
  settled false there).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_6a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_6a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

def laneId : RegionId := 10
def crossLaneId : RegionId := 11
def junctionId : RegionId := 20
def crosswalkId : RegionId := 30
def headA : DeviceId := 100
def headB : DeviceId := 101

/-- The subject's approach: a lane running east whose entrance end is the junction. -/
def approach : Structure :=
  Build.lane laneId
    [(m (-60), m (-4)), (m 0, m (-4)), (m 0, m 0), (m (-60), m 0)]
    Build.east (enters := some junctionId)

/-- The junction the approach runs into. -/
def junction : Structure := Build.rect junctionId .intersection (m 0) (m (-10)) (m 20) (m 10)

/-- A second approach to the same junction, from the south. -/
def crossApproach : Structure :=
  Build.lane crossLaneId
    [(m 6, m (-60)), (m 14, m (-60)), (m 14, m (-10)), (m 6, m (-10))]
    Build.north (enters := some junctionId)

/-- A marked crosswalk across the southern approach. -/
def crosswalk : Structure :=
  { Build.rect crosswalkId .crosswalk (m 0) (m (-14)) (m 20) (m (-10)) with marked := some true }

/-- The subject: a motor vehicle on the centreline of the approach, heading east. -/
def car (x : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, m (-2)) Build.east speed (cm 250, cm 100, cm 75)

/-- Head A, governing the subject's approach. -/
def signalA (states : List SignalIndication) : Device := Build.signal headA [laneId] states

/-- Head B, governing the southern approach. -/
def signalB (states : List SignalIndication) : Device := Build.signal headB [crossLaneId] states

/-- One observation of the approach: the car, the lane and the junction, and head A. -/
def approachScene (t : Timestamp) (x speed : Q) (states : List SignalIndication)
    (occ : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some 1) [car x speed] [approach, junction] [signalA states] (some occ)

def onLane : List (TrackId × RegionId) := [(1, laneId)]
def entering : List (TrackId × RegionId) := [(1, laneId), (1, junctionId)]
def inJunction : List (TrackId × RegionId) := [(1, junctionId)]
def offLane : List (TrackId × RegionId) := []

/-- `forbid` (violated): A car occupies a lane that enters a signalised junction, and the head governing that lane shows a steady circular yellow alone. Two seconds later the head shows circular red, and at that observation the car's footprint comes to overlap the junction region for the first time. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => approachScene t (m (-20)) (mps 10) [.circularYellow] onLane
    | 1 => approachScene t (m (-10)) (mps 10) [.circularYellow] onLane
    | _ => approachScene t (m (-1)) (mps 10) [.circularRed] entering

/-- `permit` (compliant): The same lane and head. The car faces the steady yellow, brakes and comes to rest short of the junction, its footprint never overlapping the junction region while the head shows red; no other road user is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => approachScene t (m (-20)) (mps 10) [.circularYellow] onLane
    | 1 => approachScene t (m (-14)) (mps 5) [.circularYellow] onLane
    | _ => approachScene t (m (-12)) (mps 0) [.circularRed] onLane

/-- `idle` (not_applicable): The head governing the car's lane shows a steady circular green throughout and never a steady yellow alone: the trigger never holds and the rule is not engaged, even though the car enters the junction. -/
def idleTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => approachScene t (m (-67)) (mps 22) [.circularGreen] offLane
    | 1 => approachScene t (m (-45)) (mps 22) [.circularGreen] onLane
    | 2 => approachScene t (m (-23)) (mps 22) [.circularGreen] onLane
    | _ => approachScene t (m (-1)) (mps 22) [.circularGreen] entering

/-- `blind` (unknown): The car faces the steady yellow and later enters the junction, but at the entry observation the source reports no state for the head governing its lane, so whether the red was exhibited is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => approachScene t (m (-20)) (mps 10) [.circularYellow] onLane
    | 1 => approachScene t (m (-10)) (mps 10) [.circularYellow] onLane
    | _ => approachScene t (m (-1)) (mps 10) [.circularRed] entering

/-- `branch_1` (compliant): The car faces the steady yellow and crosses into the junction while the head still shows the yellow, the red appearing only after its whole body is inside: the entry was not made at an observation at which the red was exhibited. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => approachScene t (m (-20)) (mps 10) [.circularYellow] onLane
    | 1 => approachScene t (m (-1)) (mps 10) [.circularYellow] entering
    | _ => approachScene t (m 8) (mps 10) [.circularRed] inJunction

/-- `branch_2` (not_applicable): A pedestrian on a crosswalk at the same junction faces the same head after it has shown steady yellow alone and steps into the junction region while the red is exhibited: the subject is not of the vehicle aggregate, so the duty this rule states does not bind it. -/
def pedestrianScene (t : Timestamp) (y : Q) (states : List SignalIndication)
    (occ : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some 1)
    [ Build.user 1 [.pedestrian] (m 10, y) Build.north (mps 1) (cm 30, cm 30, cm 90) ]
    [approach, junction, crosswalk] [signalA states] (some occ)

def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => pedestrianScene t (m (-12)) [.circularYellow] [(1, crosswalkId)]
    | 1 => pedestrianScene t (cm (-1050)) [.circularYellow] [(1, crosswalkId)]
    | _ => pedestrianScene t (m (-9)) [.circularRed] [(1, junctionId)]

/-- `branch_3` (not_applicable): the head governing the car's lane shows the steady yellow together
    with a green left arrow throughout, so no observation shows the yellow alone; the car enters
    the junction once the yellow has given way to the red. -/
def branch_3Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => approachScene t (m (-67)) (mps 22) [.circularYellow, .greenArrow .left] offLane
    | 1 => approachScene t (m (-45)) (mps 22) [.circularYellow, .greenArrow .left] onLane
    | 2 => approachScene t (m (-23)) (mps 22) [.circularYellow, .greenArrow .left] onLane
    | _ => approachScene t (m (-1)) (mps 22) [.circularRed] entering

/-- `branch_4` (compliant): the car faces head A's steady yellow alone on its own lane and enters
    the junction while head A still shows that yellow; head B, which governs the southern approach
    and not the car's lane, exhibits the red throughout. A red face governing another approach does
    not forbid this entry. -/
def crossScene (t : Timestamp) (x speed : Q) (a b : List SignalIndication)
    (occ : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some 1) [car x speed] [approach, crossApproach, junction]
    [signalA a, signalB b] (some occ)

def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => crossScene t (m (-20)) (mps 10) [.circularYellow] [.circularRed] onLane
    | 1 => crossScene t (m (-10)) (mps 10) [.circularYellow] [.circularRed] onLane
    | _ => crossScene t (m (-1)) (mps 10) [.circularYellow] [.circularRed] entering

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_6a"
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
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_484B_307_6a
