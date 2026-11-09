/-
  Witnesses for NRS_484B_127_2.

  THE GEOMETRY. One straight way running east, mapped as four regions in every rural witness:
  region 1 is the highway, twenty metres of boundary-to-boundary width (y from −10 to 10 m) and
  four kilometres long, so that every body and every verge object below lies on it; region 2 is
  the roadway, y from −3.5 to 3.5 m, lying on that highway; region 3 is the eastbound lane, y from
  −3.5 to 0 m, its designated direction east, the first and only lane in that direction; region 4
  is the oncoming lane, y from 0 to 3.5 m, direction west, likewise the only lane in its own
  direction. The `branch_1` map is a dual carriageway instead: the same highway and roadway, and
  three eastbound lanes (regions 3, 4, 5, each recording three lanes in the direction of travel),
  the bodies in the nearside one.

  THE BODIES. Track 1 is the subject and track 2 the road user ahead. An articulated lorry is
  18 m by 2.55 m (half-extents 9 m and 1.275 m), running east along the middle of the eastbound
  lane at y = −1.75 m, so that its body, y from −3.025 to −0.475 m, lies in that lane and touches
  no other. A van is 4.8 m by 1.9 m and a passenger car 4.6 m by 1.778 m — seventy inches, under
  the figure the subsection names. Every body keeps its speed and its heading, its position
  advancing by exactly that speed over the second before each scene, so that no scene asserts a
  motion its own figures deny; no body carries a yaw rate or a path length, and the lorries'
  gaps are therefore read from the footprints alone.

  THE SPACES. A longitudinal gap between two bodies is the distance between their nearest points:
  for two lorries it is the distance between their reference points less the two half-lengths,
  18 m in all. 500 feet is 152.4 m, so the `forbid` geometry (reference points 60 m apart, a gap
  of 42 m) is far below it and the `permit` geometry (278 m apart, a gap of 260 m) far above.

  THE INSTANTS. Every trace is three scenes at one second, t = 0, 1000, 2000 ms. The rule reads
  no window and looks nowhere into the past, so no witness names the instants it speaks about and
  none is unknown for a truncated window.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_127_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_127_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mm (n : Int) : Q := Units.millimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

/-- The reference point of a body that started at `x0` (centimetres) and holds `spd` metres per
    second, at the `k`-th scene of a trace whose scenes are one second apart. -/
def xAt (x0 spd : Int) (k : Nat) : Q := cm (x0 + spd * 100 * (Int.ofNat k))

/-- An articulated lorry: 18 m by 2.55 m, running east in the nearside lane. -/
def lorry (track : TrackId) (x0 spd : Int) (k : Nat) : RoadUser :=
  Build.user track [.truck, .trailerOrCombination] (xAt x0 spd k, cm (-175)) Build.east (mps spd)
    (m 9, mm 1275, m 2)

/-- The same lorry of a source that maps no outline for it: its class, place, heading and speed are
    recorded and its extent is not, so no footprint of it can be drawn. -/
def lorryWithoutOutline (track : TrackId) (x0 spd : Int) (k : Nat) : RoadUser :=
  Build.withKin (lorry track x0 spd k) (fun kk => { kk with extent := none })

/-- A passenger car: 4.6 m by 1.778 m — seventy inches wide. -/
def car (track : TrackId) (x0 spd : Int) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (xAt x0 spd k, cm (-175)) Build.east (mps spd)
    (cm 230, mm 889, cm 75)

/-- A van: 4.8 m by 1.9 m. -/
def van (track : TrackId) (x0 spd : Int) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (xAt x0 spd k, cm (-175)) Build.east (mps spd)
    (cm 240, cm 95, cm 110)

/-- The rural way: highway, roadway, the eastbound lane and the oncoming one. -/
def highwayRegion : Structure := Build.rect 1 .highway (m (-1000)) (m (-10)) (m 3000) (m 10)
def roadwayRegion : Structure :=
  { Build.rect 2 .roadway (m (-1000)) (cm (-350)) (m 3000) (cm 350) with ways := some [1] }
def nearsideLane : Structure :=
  { Build.lane 3 [(m (-1000), cm (-350)), (m 3000, cm (-350)), (m 3000, m 0), (m (-1000), m 0)]
      Build.east (ordinal := some 1) (count := some 1) with ways := some [1] }
def oncomingLane : Structure :=
  { Build.lane 4 [(m (-1000), m 0), (m 3000, m 0), (m 3000, cm 350), (m (-1000), cm 350)]
      Build.west (ordinal := some 1) (count := some 1) with ways := some [1] }
def ruralRoads : List Structure := [highwayRegion, roadwayRegion, nearsideLane, oncomingLane]

/-- The dual carriageway: three lanes in the direction of travel, the bodies in the nearside one. -/
def dualHighway : Structure := Build.rect 1 .highway (m (-1000)) (m (-10)) (m 3000) (m 20)
def dualRoadway : Structure :=
  { Build.rect 2 .roadway (m (-1000)) (cm (-350)) (m 3000) (m 7) with ways := some [1] }
def dualNearside : Structure :=
  { Build.lane 3 [(m (-1000), cm (-350)), (m 3000, cm (-350)), (m 3000, m 0), (m (-1000), m 0)]
      Build.east (left := some 4) (ordinal := some 3) (count := some 3) with ways := some [1] }
def dualMiddle : Structure :=
  { Build.lane 4 [(m (-1000), m 0), (m 3000, m 0), (m 3000, cm 350), (m (-1000), cm 350)]
      Build.east (left := some 5) (right := some 3) (ordinal := some 2) (count := some 3)
      with ways := some [1] }
def dualOffside : Structure :=
  { Build.lane 5 [(m (-1000), cm 350), (m 3000, cm 350), (m 3000, m 7), (m (-1000), m 7)]
      Build.east (right := some 4) (ordinal := some 1) (count := some 3) with ways := some [1] }
def dualRoads : List Structure := [dualHighway, dualRoadway, dualNearside, dualMiddle, dualOffside]

/-- A stalled wreck on the verge of the same highway, 20 to 22 m east of the origin and clear of
    the roadway: about twelve metres from the subject's body at the start of the trace. -/
def wreckage : Structure :=
  { Build.rect 6 .obstruction (m 20) (m 4) (m 22) (m 5) with
      obstructionKind := some .stalledVehicleWreckage, ways := some [1] }

/-- A line of cones, a temporary traffic control device, marking works on the lane it governs. -/
def conesOnLane : Device := Build.device 9 .temporaryTrafficControl [3]
/-- The same line of cones, recorded as governing the roadway rather than the lane. -/
def conesOnRoadway : Device := Build.device 9 .temporaryTrafficControl [2]

/-- A clear, dry day. -/
def weather : Env :=
  { darkness := some false, precipitation := some false, wetRoad := some false,
    iceOrSnow := some false, visibility := some (m 500) }

/-- A body in the eastbound lane occupies the highway, the roadway and that lane. -/
def inLane (t : TrackId) : List (TrackId × RegionId) := [(t, 1), (t, 2), (t, 3)]

def sceneOf (t : Timestamp) (users : List RoadUser) (structures : List Structure)
    (devices : List Device) (occ : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some 1) users structures devices (some occ) weather

/-- Three scenes one second apart, t = 0 to 2000 ms. -/
def traceOf (f : Nat → Timestamp → Scene) : Trace := Build.trace 3 0 (Units.seconds 1) f

/-- Two lorries in the nearside lane of the rural way, the follower at the origin. -/
def twoLorries (aheadCm : Int) (followerSpd aheadSpd : Int) : Trace :=
  traceOf fun k t =>
    sceneOf t [lorry 1 0 followerSpd k, lorry 2 aheadCm aheadSpd k] ruralRoads []
      (inLane 1 ++ inLane 2)

/-- `forbid` (violated): On a two-lane rural highway with one lane in each direction, an articulated lorry runs at 22 m/s about 60 m behind another articulated lorry in the same lane, headings aligned. No road user is between them, no obstruction lies on the way and no temporary traffic control governs their lane or roadway, and the subject is well above the free-flow speed, so the conditions permit; the longitudinal gap is far below 500 feet. -/
def forbidTrace : Trace := twoLorries 6000 22 22

/-- `permit` (compliant): The same two lorries on the same highway at the same speed, with nothing in or across the space, but the follower holds a longitudinal gap of about 260 m, which exceeds 500 feet. -/
def permitTrace : Trace := twoLorries 27800 22 22

/-- `idle` (not_applicable): A passenger car — neither a truck of the truck aggregate nor a coupled combination, and 70 inches wide — follows an articulated lorry at 60 m on the same two-lane highway. The subject is outside the classes the subsection binds and the rule does not engage. -/
def idleTrace : Trace :=
  traceOf fun k t =>
    sceneOf t [car 1 0 22 k, lorry 2 6000 22 k] ruralRoads [] (inLane 1 ++ inLane 2)

/-- `blind` (unknown): The forbid scene with the source declaring the gap between bodies absent: both road users' classes, the following relation and the single-lane carriageway are recorded, but the space cannot be read, so the duty is unknown. The source maps no outline for the lorry ahead, so it observes neither that lorry's occupancy nor any gap of its own computing: it reports the clearance and the lorry's place in the lane as measured relations, and the manifest declares the clearance absent. -/
def blindTrace : Trace :=
  traceOf fun k t =>
    { Build.withRelations
        (sceneOf t [lorry 1 0 22 k, lorryWithoutOutline 2 6000 22 k] ruralRoads [] (inLane 1))
        [ Build.relation 1 2 (fun r => { r with surfaceGap := some (m 42, Q.zero) }),
          Build.relation 2 1 (fun r => { r with aAheadOfB := some true }) ]
      with occupancyObserved := [1] }

/-- `branch_1` (not_applicable): The same two lorries at 60 m, moving on a dual carriageway whose lane adjacency records three lanes in the direction of travel of the lane they occupy. The second exception applies by its own words and the subsection does not apply. -/
def branch_1Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [lorry 1 0 22 k, lorry 2 6000 22 k] dualRoads [] (inLane 1 ++ inLane 2)

/-- `branch_2` (not_applicable): On the two-lane highway the following lorry is overtaking and passing the lorry ahead: the two travel in the same direction, the follower's speed exceeds the leader's by 4 m/s and the lorry ahead is still ahead of it in the lane as it draws level. The first exception applies and the duty does not bite on the closed space. -/
def branch_2Trace : Trace := twoLorries 6000 26 22

/-- `branch_3` (compliant): The follower lorry is held at 2 m/s in a slow-moving queue on the two-lane highway, 15 m behind the lorry ahead, with a van that has moved into the space between them. Its speed is below the free-flow bound and a road user occupies the space, so the conditions do not permit and no space of 500 feet is owed at that observation. -/
def branch_3Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [lorry 1 0 2 k, lorry 2 3300 2 k, van 3 1650 2 k] ruralRoads []
      (inLane 1 ++ inLane 2 ++ inLane 3)

/-- `branch_4` (compliant): The forbid geometry at free-flow speed with nothing between the two lorries, but a line of cones — a temporary traffic control device — governs the lane the subject occupies, a works zone on its own lane. The conditions do not permit, so the shorter space is not a breach at that observation. -/
def branch_4Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [lorry 1 0 22 k, lorry 2 6000 22 k] ruralRoads [conesOnLane]
      (inLane 1 ++ inLane 2)

/-- `branch_5` (not_applicable): The subject lorry runs alone at 22 m/s on the two-lane highway: no other road user is in the scene, so it follows nothing, the trigger fails and the subsection never engages — a decided verdict in a scene that supplies none of the road users the rule quantifies over. -/
def branch_5Trace : Trace :=
  traceOf fun k t => sceneOf t [lorry 1 0 22 k] ruralRoads [] (inLane 1)

/-- `branch_6` (compliant): The queue of branch_3 with nothing in the space: the follower lorry
    is held at 2 m/s, 15 m behind the lorry ahead, and no road user, obstruction or device stands
    between them. Its speed alone is below the free-flow bound, so the conditions do not permit. -/
def branch_6Trace : Trace := twoLorries 3300 2 2

/-- `branch_7` (compliant): The subject lorry runs at free-flow speed with a 60 m space to the
    lorry it follows, and a van has moved into that space 30 m ahead of it. The stream runs
    freely, but a road user occupies the space, so the conditions do not permit and the space the
    van has closed is no breach. -/
def branch_7Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [lorry 1 0 22 k, lorry 2 7800 22 k, van 3 4200 22 k] ruralRoads []
      (inLane 1 ++ inLane 2 ++ inLane 3)

/-- `branch_8` (compliant): The forbid geometry with the line of cones recorded as governing the
    roadway the subject occupies rather than its lane: the works zone still makes the space
    impossible to hold, so the conditions do not permit. -/
def branch_8Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [lorry 1 0 22 k, lorry 2 6000 22 k] ruralRoads [conesOnRoadway]
      (inLane 1 ++ inLane 2)

/-- `branch_9` (compliant): The forbid geometry with a stalled wreck on the verge of the same
    highway, about twelve metres from the subject's body — nearer to it than the space ahead. The
    conditions do not permit, so the shorter space is no breach. -/
def branch_9Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [lorry 1 0 22 k, lorry 2 6000 22 k] (ruralRoads ++ [wreckage]) []
      (inLane 1 ++ inLane 2)

/-- `branch_10` (not_applicable): The subject lorry follows a van 1.9 m wide at 60 m on the
    two-lane highway. The van is a vehicle, but neither a truck of the truck aggregate nor a
    combination of vehicles 80 inches or more in overall width, so the trigger fails and the
    subsection does not engage. -/
def branch_10Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [lorry 1 0 22 k, van 2 6000 22 k] ruralRoads [] (inLane 1 ++ inLane 2)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_127_2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_127_2
