/-
  Witnesses for NRS_484B_257_1_o2.

  Geometry (metres, +x east, +y north), sampled every second:
  - intersection 10: x ∈ [-10, 10], y ∈ [-10, 10], on highways 20 (north–south) and 21 (east–west).
  - ego's approach lane 11: x ∈ [0, 4], y ∈ [-30, -10], northbound, enters 10, on highway 20;
    the lane 15 upstream of it: y ∈ [-80, -30], northbound, leads to 11, enters nothing.
  - the through lane 14: x ∈ [10, 80], y ∈ [0, 4], westbound, enters 10, on highway 21; no sign.
  - stop line 12 marking 11: y ∈ [-12, -11.5] (the far variant: y ∈ [-26, -25.5]);
    crosswalk 13 marking 11: x ∈ [-10, 10], y ∈ [-14, -11].
  - ego (track 1) and b (track 2) are passenger cars, half-length 2.5, half-width 1.
  - ego halts with its centre at y = -15 (line: body 0.5 m short of it, 3 m behind it along 11),
    y = -17 (crosswalk) or y = -13 (intersection edge); then enters 10 at (2, -8) at 6 m/s.
  - b drives west along y = 2 at 10 m/s, at x = 20 when ego enters: 7.5 m from 10, against
    10 × 4.1 = 41 m; projected closest approach after 1.76 s at 0.69 m, against 3 s and 3 m.
  - yield scene: ego decelerates at 1–2 m/s² (against 0.5) from 9 m/s to 4 m/s at y = -15, enters
    at (2, -8) at 5 m/s; b, already in 10 at (8, 2) at 3 m/s after leaving lane 14, meets it
    after 2 s at 0 m.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
def body : Q × Q × Q := (cm 250, m 1, cm 75)

-- Binders ↦ tracks: ego ↦ 1

/-- Ego northbound along x = 2. -/
def ego (y speed : Q) : RoadUser := Build.user 1 [.motorVehicle] (m 2, y) Build.north speed body

/-- Ego northbound with its longitudinal acceleration and path length. -/
def egoBraking (y speed accel path : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (m 2, y) Build.north speed body (some path))
    fun k => { k with accelLongitudinal := some accel }

/-- b westbound along y = 2. -/
def other (x speed : Q) : RoadUser := Build.user 2 [.motorVehicle] (x, m 2) Build.west speed body

def junction : Structure :=
  { Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10) with ways := some [20, 21] }
def approachLane : Structure :=
  { Build.lane 11 (box (m 0) (m (-30)) (m 4) (m (-10))) Build.north (enters := some 10) with
    ways := some [20] }
def upstreamLane : Structure :=
  { Build.lane 15 (box (m 0) (m (-80)) (m 4) (m (-30))) Build.north (leadsTo := some [11]) with
    ways := some [20] }
def throughLane : Structure :=
  { Build.lane 14 (box (m 10) (m 0) (m 80) (m 4)) Build.west (enters := some 10) with
    ways := some [21] }
def northSouth : Structure := Build.rect 20 .highway (m (-10)) (m (-80)) (m 10) (m 80)
def eastWest : Structure := Build.rect 21 .highway (m (-80)) (m (-10)) (m 80) (m 10)
def lineAt (y0 y1 : Q) : Structure :=
  { Build.rect 12 .stopLine (m 0) y0 (m 4) y1 with
    entranceOf := [11], entranceObserved := true, ways := some [20] }
def stopLine : Structure := lineAt (m (-12)) (cm (-1150))
def farLine : Structure := lineAt (m (-26)) (cm (-2550))
def crosswalk : Structure :=
  { Build.rect 13 .crosswalk (m (-10)) (m (-14)) (m 10) (m (-11)) with
    entranceOf := [11], entranceObserved := true, marked := some true, ways := some [20] }
def roads : List Structure := [junction, approachLane, upstreamLane, throughLane, northSouth, eastWest]

def stopSign : Device := { Build.sign 30 .stopSign [11] with conditions := some {} }
def yieldSign : Device := { Build.sign 31 .yieldSign [11] with conditions := some {} }
def officer (id : DeviceId) (role : HumanRole) (governs : List RegionId) : Device :=
  { Build.device id .humanDirection governs with humanRole := some role, humanIndication := some .stop }
def operatingSignal (id : DeviceId) (governs : List RegionId) : Device :=
  { Build.signal id governs [.circularRed] with uncovered := some true, inoperative := some false }
def darkSignal (id : DeviceId) (governs : List RegionId) : Device :=
  { Build.signal id governs [.dark] with uncovered := some true, inoperative := some true }

/-- One scene per second from the listed road users. -/
def episode (structures : List Structure) (devices : List Device) (users : List (List RoadUser)) : Trace :=
  Build.trace users.length 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (users.getD k []) structures devices

/-- Ego halts with its centre at `y` from the trace start, then enters 10; b approaches on 14. -/
def haltThenCross (y : Q) : List (List RoadUser) :=
  [ [ego y (mps 0), other (m 40) (mps 10)]
  , [ego y (mps 0), other (m 30) (mps 10)]
  , [ego (m (-8)) (mps 6), other (m 20) (mps 10)] ]

/-- Ego arrives from lane 15, halts with its centre at `y`, then enters 10; b approaches on 14. -/
def arriveHaltCross (y : Q) : List (List RoadUser) :=
  [ [ego (m (-35)) (mps 5), other (m 60) (mps 10)]
  , [ego (m (-24)) (mps 4), other (m 50) (mps 10)]
  , [ego y (mps 0), other (m 40) (mps 10)]
  , [ego y (mps 0), other (m 30) (mps 10)]
  , [ego (m (-8)) (mps 6), other (m 20) (mps 10)] ]

/-- Ego decelerates from lane 15 to the line's zone without stopping and enters 10, meeting b,
    which has entered 10 from lane 14. -/
def slowAndEnter : List (List RoadUser) :=
  [ [egoBraking (m (-36)) (mps 9) (Units.metresPerSecondSq (-2)) (m 0), other (m 20) (mps 3)]
  , [egoBraking (m (-28)) (mps 7) (Units.metresPerSecondSq (-2)) (m 8), other (m 17) (mps 3)]
  , [egoBraking (m (-21)) (mps 6) (Units.metresPerSecondSq (-1)) (m 15), other (m 14) (mps 3)]
  , [egoBraking (m (-15)) (mps 4) (Units.metresPerSecondSq (-1)) (m 21), other (m 11) (mps 3)]
  , [egoBraking (m (-8)) (mps 5) (Units.metresPerSecondSq 1) (m 28), other (m 8) (mps 3)] ]

/-- `forbid` (violated): A stop sign governs ego's approach c; ego comes to rest at the stop line marking c, then crosses the intersection while vehicle b approaches on the unsigned through highway at a distance from the intersection below its speed times p.immediate_hazard_time; their projected closest approach lies within p.conflict_horizon below p.conflict_clearance while ego is within the intersection. -/
def forbidTrace : Trace :=
  episode (roads ++ [stopLine]) [stopSign] (haltThenCross (m (-15)))

/-- `permit` (compliant): Same scene; ego stays at rest at the line until b has passed, then crosses with no projected conflict. -/
def permitTrace : Trace :=
  episode (roads ++ [stopLine]) [stopSign]
    [ [ego (m (-15)) (mps 0), other (m 35) (mps 10)]
    , [ego (m (-15)) (mps 0), other (m 25) (mps 10)]
    , [ego (m (-15)) (mps 0), other (m 15) (mps 10)]
    , [ego (m (-15)) (mps 0), other (m 5) (mps 10)]
    , [ego (m (-15)) (mps 0), other (m (-5)) (mps 10)]
    , [ego (m (-8)) (mps 6), other (m (-15)) (mps 10)]
    , [ego (m (-2)) (mps 6), other (m (-25)) (mps 10)] ]

/-- `idle` (not_applicable): No stop or yield sign governs ego's approach; ego crosses the intersection. -/
def idleTrace : Trace :=
  episode (roads ++ [stopLine]) [] (haltThenCross (m (-15)))

/-- `blind` (unknown): Scene of forbid, but the source declares dev.governs absent: whether the stop sign governs ego's approach cannot be read. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): As forbid, except that ego's only halt was far upstream of the stop line, outside its stopping zone, and ego did not halt at the line: the act g8 refers to was not made, so this duty does not arise (NRS_484B_257_1_o1 judges the missing halt). -/
def branch_1Trace : Trace :=
  episode (roads ++ [stopLine]) [stopSign]
    [ [ego (m (-45)) (mps 0), other (cm 5075) (mps 10)]
    , [ego (m (-37)) (mps 8), other (cm 4075) (mps 10)]
    , [ego (m (-25)) (mps 8), other (cm 3075) (mps 10)]
    , [ego (m (-15)) (mps 8), other (cm 2075) (mps 10)]
    , [ego (m (-5)) (mps 8), other (cm 1075) (mps 10)] ]

/-- `branch_2` (compliant): A stop sign governs c; ego stops at the line and crosses with no other road user in the scene. -/
def branch_2Trace : Trace :=
  episode (roads ++ [stopLine]) [stopSign]
    [ [ego (m (-15)) (mps 0)], [ego (m (-15)) (mps 0)], [ego (m (-8)) (mps 6)] ]

/-- `branch_3` (violated): Only a yield sign governs c; ego decelerates before the line, enters without stopping, and is in projected conflict with vehicle b that had already entered the intersection from the through highway. -/
def branch_3Trace : Trace :=
  episode (roads ++ [stopLine]) [yieldSign] slowAndEnter

/-- `branch_4` (violated): no stop line; ego halts short of the crosswalk marking c, then crosses into b's path. -/
def branch_4Trace : Trace :=
  episode (roads ++ [crosswalk]) [stopSign] (haltThenCross (m (-17)))

/-- `branch_5` (violated): neither stop line nor crosswalk; ego halts at the intersection's edge, then crosses into b's path. -/
def branch_5Trace : Trace :=
  episode roads [stopSign] (haltThenCross (m (-13)))

/-- `branch_6` (not_applicable): forbid, with a police officer directing traffic on c. -/
def branch_6Trace : Trace :=
  episode (roads ++ [stopLine]) [stopSign, officer 40 .policeOfficer [11]] (haltThenCross (m (-15)))

/-- `branch_7` (not_applicable): forbid, with an operating signal head governing the intersection. -/
def branch_7Trace : Trace :=
  episode (roads ++ [stopLine]) [stopSign, operatingSignal 41 [10]] (haltThenCross (m (-15)))

/-- `branch_8` (violated): forbid, with a flagger on c, a police officer and an operating signal on b's lane only, and an inoperative signal head over the intersection: none controls ego's entry. -/
def branch_8Trace : Trace :=
  episode (roads ++ [stopLine])
    [stopSign, officer 42 .flagger [11], officer 43 .policeOfficer [14],
     darkSignal 44 [10], operatingSignal 45 [14]]
    (haltThenCross (m (-15)))

/-- `branch_9` (not_applicable): a stop line well back and a crosswalk mark c; ego passes the line and halts only short of the crosswalk. -/
def branch_9Trace : Trace :=
  episode (roads ++ [farLine, crosswalk]) [stopSign] (arriveHaltCross (m (-17)))

/-- `branch_10` (not_applicable): a stop line well back marks c; ego passes it and halts only at the intersection's edge. -/
def branch_10Trace : Trace :=
  episode (roads ++ [farLine]) [stopSign] (arriveHaltCross (m (-13)))

/-- `branch_11` (not_applicable): a crosswalk marks c; ego halts on the crosswalk at the intersection's edge, not short of it. -/
def branch_11Trace : Trace :=
  episode (roads ++ [crosswalk]) [stopSign] (arriveHaltCross (cm (-1250)))

/-- `branch_12` (not_applicable): a stop sign and a yield sign govern c; ego only slows and enters, so the halt the stop sign requires was not made. -/
def branch_12Trace : Trace :=
  episode (roads ++ [stopLine]) [stopSign, yieldSign] slowAndEnter

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .notApplicable
  , witness "branch_11" branch_11Trace .notApplicable
  , witness "branch_12" branch_12Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_257_1_o2
