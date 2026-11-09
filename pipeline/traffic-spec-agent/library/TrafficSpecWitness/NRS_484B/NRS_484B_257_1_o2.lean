/-
  Witnesses for NRS_484B_257_1_o2.

  One map for every scene (every figure here is the witness's own and appears nowhere in the rule).
  A minor road runs north, a through highway east-west; they meet in a junction region.

    region 10  the junction            the square [-7, 7] x [-7, 7]
    region 11  the subject's approach  the northbound lane [-2, 2] x [-20, -7], entering 10,
                                       lying on way 15
    region 12  the stop line           [-2, 2] x [-8.5, -8], marking region 11's entrance
    region 16  the crosswalk           [-2, 2] x [-9.5, -8], marking region 11's entrance
                                       (used instead of the stop line in `branch_3`)
    region 13  the through carrier      the eastbound lane [-320, -7] x [-4, 0], entering 10,
                                       lying on way 14
    region 14  the east-west highway   [-320, 320] x [-7, 7]  (the through highway)
    region 15  the north-south highway [-7, 7] x [-60, 60]    (the subject's own way)

  Devices: a stop sign (20) or a yield sign (21) governing region 11; a police officer (22)
  governing the junction; a traffic-control signal (23) governing region 11.

  Bodies: the subject (track 1) is a 4 m x 1.8 m car driving north along x = 0; track 2 is a 5 m
  x 2 m van driving east along y = -2 on the through carrier, or north behind the subject, or a
  pedestrian walking north along x = 4 inside the junction. Scenes are one second apart.

  Every course halts (or slows) at the mark at the fourth observation, after at least one
  observation on the carrier, so that the search back over the approach begins inside the trace.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The map
-- ---------------------------------------------------------------------------------------------
def junction : Structure :=
  { Build.rect 10 .intersection (m (-7)) (m (-7)) (m 7) (m 7) with ways := some [14, 15] }

def approachLane : Structure :=
  { Build.lane 11 [(m (-2), m (-20)), (m 2, m (-20)), (m 2, m (-7)), (m (-2), m (-7))]
      Build.north (enters := some 10) with ways := some [15] }

def stopLine : Structure :=
  { Build.rect 12 .stopLine (m (-2)) (cm (-850)) (m 2) (m (-8)) with
      ways := some [15], entranceOf := [11], entranceObserved := true }

def crossing : Structure :=
  { Build.rect 16 .crosswalk (m (-2)) (cm (-950)) (m 2) (m (-8)) with
      ways := some [15], entranceOf := [11], entranceObserved := true, marked := some true }

def throughLane : Structure :=
  { Build.lane 13 [(m (-320), m (-4)), (m (-7), m (-4)), (m (-7), m 0), (m (-320), m 0)]
      Build.east (enters := some 10) with ways := some [14] }

def wayEastWest : Structure :=
  { Build.rect 14 .highway (m (-320)) (m (-7)) (m 320) (m 7) with ways := some [14] }

def wayNorthSouth : Structure :=
  { Build.rect 15 .highway (m (-7)) (m (-60)) (m 7) (m 60) with ways := some [15] }

/-- The map with the stop line marking the subject's entrance. -/
def mapWithStopLine : List Structure :=
  [junction, approachLane, stopLine, throughLane, wayEastWest, wayNorthSouth]
/-- The map with a crosswalk and no stop line. -/
def mapWithCrosswalk : List Structure :=
  [junction, approachLane, crossing, throughLane, wayEastWest, wayNorthSouth]
/-- The map with neither mark. -/
def mapWithNoMark : List Structure :=
  [junction, approachLane, throughLane, wayEastWest, wayNorthSouth]

def stopSign : Device := Build.sign 20 .stopSign [11]
def yieldSign : Device := Build.sign 21 .yieldSign [11]
def officer : Device :=
  { Build.device 22 .humanDirection [10] with
      humanRole := some .policeOfficer, humanIndication := some .stop }
def laneSignal : Device := Build.signal 23 [11] [.circularGreen]
def laneOfficer : Device :=
  { Build.device 24 .humanDirection [11] with
      humanRole := some .policeOfficer, humanIndication := some .proceed }
def junctionSignal : Device := Build.signal 25 [10] [.circularGreen]

-- ---------------------------------------------------------------------------------------------
-- The bodies
-- ---------------------------------------------------------------------------------------------
/-- The subject: a car driving north along x = 0, at the given y (cm) and speed. -/
def car (ycm : Int) (sp : Q) (sight : Option (List (RegionId × Q)) := none) : RoadUser :=
  { Build.user 1 [.motorVehicle] (m 0, cm ycm) Build.north sp (m 2, cm 90, cm 75) with
      sightAlongWay := sight }

/-- A van on the through carrier, driving east along y = -2 at the given x (cm). -/
def crossVan (xcm : Int) (sp : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm xcm, m (-2)) Build.east sp (cm 250, m 1, cm 120)

/-- A van behind the subject on its own approach carrier, at the given y (cm). -/
def follower (ycm : Int) (sp : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (m 0, cm ycm) Build.north sp (cm 250, m 1, cm 120)

/-- A pedestrian walking north through the junction along x = 4, at the given y (cm). -/
def walker (ycm : Int) (sp : Q) : RoadUser :=
  Build.user 2 [.pedestrian] (m 4, cm ycm) Build.north sp (cm 30, cm 30, cm 90)

/-- A course: one (position in cm, speed) per observation. -/
abbrev Course := List (Int × Q)

def stepOf (xs : Course) (k : Nat) : Int × Q := xs.getD k (0, Q.zero)

/-- A trace of the map: the subject's course, an optional second body per observation, and the
    observations at which the second body's footprint is stated to lie across the junction too
    (its reference point being still on its carrier). -/
def junctionTrace (sts : List Structure) (devs : List Device) (carCourse : Course)
    (second : Nat → Option RoadUser) (straddle : List Nat)
    (sight : Option (List (RegionId × Q)) := none) : Trace :=
  Build.trace carCourse.length 0 (Units.seconds 1) fun k t =>
    let c := stepOf carCourse k
    let us := car c.1 c.2 sight :: (match second k with | some u => [u] | none => [])
    Build.scene t (some 1) us sts devs
      (some (Build.occupancyFromGeometry us sts ++
        (if straddle.contains k then [(2, 10)] else [])))

/-- A body of the map at a free position, heading north. -/
def bodyAt (track : TrackId) (cls : List RoadUserClass) (xcm ycm : Int) (sp : Q)
    (half : Q × Q × Q) : RoadUser :=
  Build.user track cls (cm xcm, cm ycm) Build.north sp half

/-- A trace of two bodies at free positions, each (x, y in cm, speed) per observation. -/
def pairTrace (sts : List Structure) (devs : List Device)
    (a b : List (Int × Int × Q)) : Trace :=
  Build.trace a.length 0 (Units.seconds 1) fun k t =>
    let p := a.getD k (0, 0, Q.zero)
    let q := b.getD k (0, 0, Q.zero)
    let us := [ bodyAt 1 [.motorVehicle] p.1 p.2.1 p.2.2 (m 2, cm 90, cm 75)
              , bodyAt 2 [.motorVehicle] q.1 q.2.1 q.2.2 (cm 250, m 1, cm 120) ]
    Build.scene t (some 1) us sts devs (some (Build.occupancyFromGeometry us sts))

def noSecond : Nat → Option RoadUser := fun _ => none
def vanOn (xs : Course) : Nat → Option RoadUser :=
  fun k => let s := stepOf xs k; some (crossVan s.1 s.2)
def followerOn (xs : Course) : Nat → Option RoadUser :=
  fun k => let s := stepOf xs k; some (follower s.1 s.2)
def walkerOn (xs : Course) : Nat → Option RoadUser :=
  fun k => let s := stepOf xs k; some (walker s.1 s.2)

-- ---------------------------------------------------------------------------------------------
-- The courses
-- ---------------------------------------------------------------------------------------------
/-- Approach the stop line, halt at it (fourth observation), then cross the junction. -/
def haltAndCross : Course :=
  [(-2400, mps 6), (-1800, mps 4), (-1300, mps 2), (-960, Q.zero), (-600, mps 4), (-250, mps 4)]
/-- The same, carried one observation further across the junction. -/
def haltAndClear : Course :=
  [(-2400, mps 6), (-1800, mps 4), (-1300, mps 2), (-960, Q.zero), (-600, mps 4), (-200, mps 4),
   (200, mps 4)]
/-- Never halt and never slow: straight through the stop line and across the junction. -/
def rollThrough : Course :=
  [(-2600, mps 8), (-1800, mps 8), (-1000, mps 8), (-200, mps 8), (600, mps 8)]
/-- Slow to 3 m/s at the yield line without halting, then cross. -/
def slowAndCross : Course :=
  [(-2400, mps 8), (-1800, mps 6), (-1300, mps 5), (-960, mps 3), (-600, mps 4), (-200, mps 4)]
/-- Halt before the crosswalk (which lies 1.5 m deep behind the junction), then cross. -/
def haltAtCrossingAndCross : Course :=
  [(-2400, mps 6), (-1800, mps 4), (-1400, mps 2), (-1100, Q.zero), (-600, mps 4), (-200, mps 4)]
/-- Halt at the line, then creep into the junction and stand still inside it. -/
def haltAndStandInside : Course :=
  [(-2400, mps 6), (-1800, mps 4), (-1300, mps 2), (-960, Q.zero), (-600, Q.zero),
   (-600, Q.zero)]
/-- Halt at the line, then creep across the junction at 1 m/s. -/
def haltAndCreep : Course :=
  [(-2400, mps 6), (-1800, mps 4), (-1300, mps 2), (-960, Q.zero), (-650, mps 1), (-550, mps 1)]

/-- A van that reaches the junction from the west and is inside it from the fourth observation. -/
def vanIntoJunction : Course :=
  [(-2000, mps 4), (-1600, mps 4), (-1200, mps 4), (-800, mps 4), (-400, mps 3), (-100, mps 3)]
/-- The same van, slower through the junction so that the bodies pass without touching. -/
def vanThroughJunction : Course :=
  [(-2000, mps 4), (-1600, mps 4), (-1200, mps 4), (-800, mps 4), (-400, mps 4), (0, mps 4)]
/-- A van on the through highway at 25 m/s, 34 m short of the junction at the fifth observation. -/
def vanClosing : Course :=
  [(-13400, mps 25), (-10900, mps 25), (-8400, mps 25), (-5900, mps 25), (-3400, mps 25),
   (-900, mps 25)]
/-- A van on the through highway at 20 m/s, 200 m from the junction at the fifth observation. -/
def vanFarOff : Course :=
  [(-28950, mps 20), (-26950, mps 20), (-24950, mps 20), (-22950, mps 20), (-20950, mps 20),
   (-18950, mps 20)]
/-- A van following the subject onto its own approach carrier. -/
def vanBehind : Course :=
  [(-3400, mps 4), (-3000, mps 4), (-2600, mps 4), (-2200, mps 4), (-1800, mps 4), (-1400, mps 4)]
/-- The subject halts at the line, then turns left into the junction and is struck on its left
    side; (x, y in cm, speed). -/
def haltAndTurnLeft : List (Int × Int × Q) :=
  [ (0, -2400, mps 6), (0, -1800, mps 4), (0, -1300, mps 2), (0, -960, Q.zero)
  , (-300, -600, mps 5), (-600, -200, mps 1) ]
/-- A van on the through carrier creeping north at the subject's own velocity, its body reaching
    into the junction; (x, y in cm, speed). -/
def vanAbreast : List (Int × Int × Q) :=
  [ (-750, -600, mps 1), (-750, -500, mps 1), (-750, -420, mps 1), (-750, -300, mps 1)
  , (-750, -250, mps 1), (-750, -200, mps 1) ]

/-- A pedestrian walking north through the junction. -/
def walkThroughJunction : Course :=
  [(-400, mps 1), (-300, mps 1), (-200, mps 1), (-100, mps 1), (0, mps 1), (100, mps 1),
   (200, mps 1)]

-- ---------------------------------------------------------------------------------------------
-- The scenarios
-- ---------------------------------------------------------------------------------------------
/-- `forbid` (violated): A stop sign governs the car's approach lane to a highway junction. The car halts at the stop line, then pulls out and crosses the junction while a van that entered the junction from the highway is within it, and the two bodies touch inside the junction. -/
def forbidTrace : Trace :=
  junctionTrace mapWithStopLine [stopSign] haltAndCross (vanOn vanIntoJunction) [3]

/-- `permit` (compliant): The same junction and halt at the stop line. The car then crosses the junction and no other road user is in the scene at any observation: nothing has entered from the through highway and nothing approaches on it, so the duty is discharged with the subject alone. -/
def permitTrace : Trace :=
  junctionTrace mapWithStopLine [stopSign] haltAndClear noSecond []

/-- `idle` (not_applicable): The car never halts and never slows at the stop line: it rolls straight through and across the junction. The condition that it had stopped, or under a yield sign slowed or stopped, does not hold, so this rule is not engaged and only the first node of the line judges the conduct. -/
def idleTrace : Trace :=
  junctionTrace mapWithStopLine [stopSign] rollThrough noSecond []

/-- `blind` (unknown): The car halts at its stop line and moves into the junction while a van is on the highway, but the source carries no boundary outline for the junction region, so the van's distance to the junction cannot be read and whether it approaches so closely as to be an immediate hazard is unknown. -/
def blindTrace : Trace :=
  junctionTrace mapWithStopLine [stopSign] haltAndCross (vanOn vanClosing) []

/-- `branch_1` (violated): The car halts at its stop line, then pulls across the junction while a van on the through highway is thirty metres away at 25 m/s -- within its speed times the headway bound -- and their closest approach under constant velocities within the horizon falls to a metre: a vehicle approaching so closely as to constitute an immediate hazard is not given precedence. -/
def branch_1Trace : Trace :=
  junctionTrace mapWithStopLine [stopSign] haltAndCross (vanOn vanClosing) []

/-- `branch_2` (compliant): A yield sign governs the approach. The car slows to 3 m/s at the yield line without halting, which satisfies the condition, and then crosses while the nearest vehicle on the through highway is two hundred metres away at 20 m/s: neither within the headway bound nor near the clearance bound. -/
def branch_2Trace : Trace :=
  junctionTrace mapWithStopLine [yieldSign] slowAndCross (vanOn vanFarOff) []

/-- `branch_3` (compliant): No stop line marks the approach; a crosswalk does. The car halts just
    short of the crosswalk, which is the place the words name where there is no stop line, and
    then crosses the empty junction. -/
def branch_3Trace : Trace :=
  junctionTrace mapWithCrosswalk [stopSign] haltAtCrossingAndCross noSecond []

/-- `branch_4` (compliant): Neither a stop line nor a crosswalk marks the approach. The car halts
    at a point from which it sees 120 m along the through highway, above the view distance the
    reading names, and then crosses the empty junction. -/
def branch_4Trace : Trace :=
  junctionTrace mapWithNoMark [stopSign] haltAndCross noSecond [] (some [(14, m 120)])

/-- `branch_5` (violated): A yield sign governs the approach and the car halts at its line (a halt
    satisfies the condition under a yield sign too), then creeps across the junction at 1 m/s
    while a van that entered from the through highway passes close by: the bodies never touch and
    their centres stay more than the clearance apart, but the nearest points of the two bodies
    come well inside it. -/
def branch_5Trace : Trace :=
  junctionTrace mapWithStopLine [yieldSign] haltAndCreep (vanOn vanThroughJunction) [3]

/-- `branch_6` (not_applicable): The same halt and crossing, but a police officer is directing the
    traffic of the junction the car is in: the exception withdraws the duty. -/
def branch_6Trace : Trace :=
  junctionTrace mapWithStopLine [stopSign, officer] haltAndClear noSecond []

/-- `branch_7` (not_applicable): A traffic-control signal governs the approach carrier, on which a
    second vehicle is waiting, so the traffic of that carrier is being controlled by a signal: the
    exception withdraws the duty. -/
def branch_7Trace : Trace :=
  junctionTrace mapWithStopLine [stopSign, laneSignal] haltAndCross (followerOn vanBehind) []

/-- `branch_8` (not_applicable): The car halts at the stop line, creeps into the junction and
    stands still inside it: it is not moving across or within the intersection, so the duty is not
    read at those observations. -/
def branch_8Trace : Trace :=
  junctionTrace mapWithStopLine [stopSign] haltAndStandInside noSecond []

/-- `branch_9` (compliant): The car halts at the stop line and crosses the junction while a
    pedestrian is walking through it four metres away: a pedestrian is no member of the aggregate
    the term 'vehicle' defines, so no precedence is owed to it under this rule. -/
def branch_9Trace : Trace :=
  junctionTrace mapWithStopLine [stopSign] haltAndClear (walkerOn walkThroughJunction) []

/-- `branch_10` (violated): The car halts at the stop line and turns left into the junction, where
    a van whose body reaches in from the through carrier -- its distance to the junction nil, well
    inside its own speed times the headway -- is struck on the car's left side. The two keep the
    same velocity at that observation, so their centres never approach: the duty is broken by the
    contact alone, and the vehicle is privileged by the headway bound alone. -/
def branch_10Trace : Trace :=
  pairTrace mapWithStopLine [stopSign] haltAndTurnLeft vanAbreast

/-- `branch_11` (not_applicable): A police officer is directing the traffic of the approach
    carrier, on which a second vehicle is waiting: the exception withdraws the duty. -/
def branch_11Trace : Trace :=
  junctionTrace mapWithStopLine [stopSign, laneOfficer] haltAndCross (followerOn vanBehind) []

/-- `branch_12` (not_applicable): A traffic-control signal governs the junction the car is in: the
    exception withdraws the duty. -/
def branch_12Trace : Trace :=
  junctionTrace mapWithStopLine [stopSign, junctionSignal] haltAndClear noSecond []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o2"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .notApplicable
  , witness "branch_12" branch_12Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_257_1_o2
