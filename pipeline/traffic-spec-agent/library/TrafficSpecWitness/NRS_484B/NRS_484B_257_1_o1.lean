/-
  Witnesses for NRS_484B_257_1_o1.

  The geometry, shared by every scene below (world frame, +x east, +y north; every figure here is
  the witness's own and appears nowhere in the rule):

    - a side road runs north into a through highway. The junction (region 3, `intersection`) is the
      square x, y ∈ [-4, 4] m. The subject's approach lane (region 2, `lane`, direction north,
      enters region 3) is x ∈ [-3.5, 0], y ∈ [-22, -1], so it overlaps the junction's near edge and
      a body entering the junction still occupies the lane it came through.
    - a transverse stop line (region 4) across the lane at y ∈ [-10.3, -9.7], and a crosswalk
      (region 5) across it at y ∈ [-8, -5]. Each witness says, by `entrance_of`, which carriers the
      line and the crossing mark — the empty list with `entrance_observed` set is "observed, and it
      marks this carrier not at all".
    - the through highway (region 6) x ∈ [-60, 60], y ∈ [-4, 4] and the side highway (region 7)
      x ∈ [-4, 4], y ∈ [-30, 4]. The junction lies on both; the approach lane lies on the side
      highway only, so the crossing way the rule reads is region 6.
    - the car is track 1, a motor vehicle 4 m long and 1.8 m wide, driving north along x = -1.75 at
      one observation a second. Its sight along the through highway is given per scene.
    - the stop sign (device 100) and the yield sign (device 101) govern the approach lane; the
      police officer (device 200) and the signal head (device 201) govern whatever each witness
      says. No witness holds a road user other than the car.

  Each trace begins with the car short of the lane (the rule is then not engaged) and ends at the
  observation at which the car's reference point is inside the junction while its body at the
  observation before was clear of it, so that the entry into the junction is the same instant
  whether occupancy is read from the reference point or from the footprint.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

def laneId : RegionId := 2
def junctionId : RegionId := 3
def stopLineId : RegionId := 4
def crosswalkId : RegionId := 5
def throughWayId : RegionId := 6
def sideWayId : RegionId := 7

def junction : Structure :=
  { Build.rect junctionId .intersection (m (-4)) (m (-4)) (m 4) (m 4) with
      ways := some [throughWayId, sideWayId] }

def approachLane : Structure :=
  { Build.lane laneId
      [(cm (-350), m (-22)), (m 0, m (-22)), (m 0, m (-1)), (cm (-350), m (-1))]
      Build.north (enters := some junctionId) with
      ways := some [sideWayId] }

/-- The stop line across the lane, with the carriers it is observed to mark. -/
def stopLine (marks : List RegionId) : Structure :=
  { Build.rect stopLineId .stopLine (cm (-350)) (cm (-1030)) (m 0) (cm (-970)) with
      entranceOf := marks, entranceObserved := true, ways := some [sideWayId] }

/-- The crosswalk on the near side of the junction, with the carriers it is observed to mark. -/
def crossing (marks : List RegionId) : Structure :=
  { Build.rect crosswalkId .crosswalk (cm (-350)) (m (-8)) (m 0) (m (-5)) with
      entranceOf := marks, entranceObserved := true, marked := some true,
      ways := some [sideWayId] }

def throughWay : Structure := Build.rect throughWayId .highway (m (-60)) (m (-4)) (m 60) (m 4)
def sideWay : Structure := Build.rect sideWayId .highway (m (-4)) (m (-30)) (m 4) (m 4)

/-- A stop line marking the approach lane; no crossing marks it. -/
def mapStopLine : List Structure :=
  [junction, approachLane, stopLine [laneId], crossing [], throughWay, sideWay]
/-- The line and the crossing are observed, and neither marks the approach lane. -/
def mapNoMark : List Structure :=
  [junction, approachLane, stopLine [], crossing [], throughWay, sideWay]
/-- No stop line marks the lane; the crosswalk does. -/
def mapCrossing : List Structure :=
  [junction, approachLane, stopLine [], crossing [laneId], throughWay, sideWay]

def stopSign : Device := Build.sign 100 .stopSign [laneId]
def yieldSign : Device := Build.sign 101 .yieldSign [laneId]
/-- A police officer directing the traffic of the regions given, waving it on. -/
def officer (governs : List RegionId) : Device :=
  { Build.device 200 .humanDirection governs (some (cm (-450), m (-2))) with
      humanRole := some .policeOfficer, humanIndication := some .proceed }
def signalHead (governs : List RegionId) : Device := Build.signal 201 governs [.circularGreen]

/-- The car at a point of the lane's centre line, with its speed and its sight along the through
    highway. -/
def car (y speed sight : Q) : RoadUser :=
  { Build.user 1 [.motorVehicle] (cm (-175), y) Build.north speed (m 2, cm 90, cm 80) with
      sightAlongWay := some [(throughWayId, sight)] }

/-- One scene a second, from a list of (y, speed, sight along the through highway). -/
def run (sts : List Structure) (devs : List Device) (ks : List (Q × Q × Q)) : Trace :=
  Build.trace ks.length 0 (Units.seconds 1) fun k t =>
    match ks[k]? with
    | some (y, sp, sg) => Build.scene t (some 1) [car y sp sg] sts devs
    | none => Build.scene t (some 1) [car (m 0) Q.zero (m 0)] sts devs

/-- Approach and entry with no halt anywhere: the car is clear of the lane, then upstream of the
    stop line's stopping zone twice, then inside it, then past the line, then in the junction. -/
def noHaltSteps : List (Q × Q × Q) :=
  [ (cm (-2600), mps 5, m 40)
  , (cm (-2100), mps 5, m 50)
  , (cm (-1600), mps 5, m 60)
  , (cm (-1290), mps 4, m 70)
  , (cm (-890), mps 4, m 80)
  , (cm (-290), mps 6, m 90) ]

/-- `forbid` (violated): A side road meets a highway. A stop sign governs the car's approach lane, a stop line is recorded as marking that lane, and no officer or signal controls the junction. The car rolls over the line at 4 m/s and enters the junction, its speed never falling to the standstill tolerance anywhere on the approach from the line's upstream zone onward. No other road user is in the scene. -/
def forbidTrace : Trace := run mapStopLine [stopSign] noHaltSteps

/-- `permit` (compliant): The same junction and stop sign. The car comes to rest with its speed at zero while its body is within the stop-point tolerance of the stop line and short of it, then enters the junction. The scene holds no other road user and the verdict is still decided. -/
def permitTrace : Trace :=
  run mapStopLine [stopSign]
    [ (cm (-2600), mps 5, m 40)
    , (cm (-2100), mps 5, m 50)
    , (cm (-1600), mps 4, m 60)
    , (cm (-1290), mps 1, m 70)     -- inside the stopping zone, still rolling
    , (cm (-1260), Q.zero, m 75)    -- halted 0.3 m short of the line
    , (cm (-860), mps 4, m 80)
    , (cm (-260), mps 6, m 90) ]

/-- `idle` (not_applicable): The same geometry, but a police officer stands in the junction giving a proceed indication to the traffic on the car's approach. The exception holds, so the rule is not engaged. -/
def idleTrace : Trace := run mapStopLine [stopSign, officer [junctionId]] noHaltSteps

/-- `blind` (unknown): The car enters the junction without halting and a stop sign stands beside its approach, but the source does not report which travel regions that sign governs, so whether a proper sign has been erected for this approach is unknown. -/
def blindTrace : Trace := run mapStopLine [stopSign] noHaltSteps

/-- `branch_1` (compliant): A yield sign, not a stop sign, governs the car's approach, with a stop line marking the lane. The car does not halt but comes down to 3 m/s within the stop-point tolerance of the line before entering the junction: under a yield sign the words require no mandatory halt. -/
def branch_1Trace : Trace :=
  run mapStopLine [yieldSign]
    [ (cm (-2600), mps 6, m 40)
    , (cm (-2100), mps 6, m 50)
    , (cm (-1600), mps 6, m 60)
    , (cm (-1290), mps 6, m 70)     -- inside the stopping zone, too fast to count
    , (cm (-1100), mps 3, m 80)     -- slowed at the line
    , (cm (-750), mps 5, m 85)
    , (cm (-150), mps 6, m 90) ]

/-- `branch_2` (violated): A stop sign governs the approach, and the lane's stop lines and crosswalks are observed with none marking it. The car crosses the point nearest the junction at which the sight along the crossing way reaches the view distance at 6 m/s and enters without ever halting: the third place governs and no halt is found. -/
def branch_2Trace : Trace :=
  run mapNoMark [stopSign]
    [ (cm (-2600), mps 6, m 40)
    , (cm (-2100), mps 6, m 50)
    , (cm (-1600), mps 6, m 60)     -- the view along the through highway is still short
    , (cm (-1100), mps 6, m 120)    -- the view has opened
    , (cm (-800), mps 6, m 130)
    , (cm (-200), mps 6, m 140) ]

/-- `branch_3` (compliant): neither a stop line nor a crosswalk marks the lane, and the car halts
    where the sight along the crossing way has reached the view distance, then enters. -/
def branch_3Trace : Trace :=
  run mapNoMark [stopSign]
    [ (cm (-2600), mps 6, m 40)
    , (cm (-2100), mps 6, m 50)
    , (cm (-1600), mps 6, m 60)
    , (cm (-1100), mps 2, m 120)
    , (cm (-1050), Q.zero, m 125)   -- halted where the way can be seen
    , (cm (-700), mps 4, m 130)
    , (cm (-150), mps 5, m 140) ]

/-- `branch_4` (not_applicable): the officer directs the traffic of the car's approach lane rather
    than of the junction; the exception holds all the same. -/
def branch_4Trace : Trace := run mapStopLine [stopSign, officer [laneId]] noHaltSteps

/-- `branch_5` (not_applicable): a traffic-control signal governs the junction the car approaches. -/
def branch_5Trace : Trace := run mapStopLine [stopSign, signalHead [junctionId]] noHaltSteps

/-- `branch_6` (not_applicable): a traffic-control signal governs the car's approach lane. -/
def branch_6Trace : Trace := run mapStopLine [stopSign, signalHead [laneId]] noHaltSteps

/-- `branch_7` (compliant): no stop line marks the lane but a crosswalk does, and the car halts
    within the stop-point tolerance of the crossing, short of it, before entering. -/
def branch_7Trace : Trace :=
  run mapCrossing [stopSign]
    [ (cm (-2600), mps 5, m 40)
    , (cm (-2100), mps 5, m 45)
    , (cm (-1400), mps 4, m 50)
    , (cm (-1050), mps 2, m 55)     -- inside the crossing's stopping zone, still rolling
    , (cm (-1020), Q.zero, m 60)    -- halted 0.2 m short of the crossing
    , (cm (-650), mps 4, m 65)
    , (cm (-150), mps 5, m 70) ]

/-- `branch_8` (violated): a yield sign governs the approach and a stop line marks the lane, and the
    car crosses the line at 8 m/s without slowing to the yield-sign speed. -/
def branch_8Trace : Trace :=
  run mapStopLine [yieldSign]
    [ (cm (-2900), mps 8, m 40)
    , (cm (-2150), mps 8, m 50)
    , (cm (-1500), mps 8, m 60)
    , (cm (-1100), mps 8, m 70)
    , (cm (-700), mps 8, m 80)
    , (cm (-150), mps 8, m 90) ]

/-- `history_boundary` (unknown): The recording begins with the car already between the stop line and the junction, inside the line's stopping zone, and the car then enters the junction. No halt is recorded, and the recording holds neither the start of the approach upstream of the line nor a previous entry of the car into that junction. -/
def history_boundaryTrace : Trace :=
  run mapStopLine [stopSign]
    [ (cm (-1290), mps 4, m 70)
    , (cm (-890), mps 4, m 80)
    , (cm (-290), mps 6, m 90) ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o1"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .violated
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the stretch of the approach upstream of the stop line's stopping zone, at which the car entered that zone, lies before the first observation of the recording") ]

end TrafficSpecWitness.NRS_484B_257_1_o1
