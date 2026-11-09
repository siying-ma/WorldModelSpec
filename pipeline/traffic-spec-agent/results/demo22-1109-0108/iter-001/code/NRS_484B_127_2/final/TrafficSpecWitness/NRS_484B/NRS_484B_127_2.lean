/-
  Witnesses for NRS_484B_127_2.

  The world. One straight east–west highway (region 10, the whole way between its boundary lines,
  y from −12 m to +12 m), an improved roadway on it (region 13) and lanes on it: region 11, the
  eastbound lane (y from −4 m to 0, direction east), region 12, the westbound lane (y from 0 to
  +4 m, direction west), and, where a scene needs a second lane of the subject's direction, region
  14 (y from −8 m to −4 m, direction east). Every lane and the roadway record the highway as their
  way. On the two-lane highway each lane records ordinal 1 of a count of 1 lane in its direction,
  so the count of s7 is decided, not merely unobserved.

  The bodies. An articulated lorry is 18 m long and 2.5 m wide (half-extents 9 m, 1.25 m, 2 m) and
  carries the truck and trailer-or-combination classes, so the truck aggregate holds of it; a
  passenger car is 4.8 m long and 1.78 m (70 inches) wide; a van is 5 m long and 1.8 m wide. All
  run in the eastbound lane on its centre line (y = −2 m), headings east.

  The instants. Each trace is three observations one second apart, the scene unchanged: the rule
  looks back nowhere, so no window needs padding and no witness names one.

  The figures that matter against the reading: a centre spacing of 60 m between two lorries is a
  longitudinal clearance of 42 m, far below the 500 feet (152.4 m) of s4; a centre spacing of
  260 m is a clearance of 242 m, far above it. 22 m/s is far above the free-flow bound of the
  conditions, 2 m/s and 0 m/s far below it. Every figure here is the witness's own and appears
  nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_127_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_127_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

/-- A lateral strip of the way, from `y0` to `y1`, running 2 km either side of the origin. -/
def strip (y0 y1 : Q) : List Vec :=
  [(m (-2000), y0), (m 2000, y0), (m 2000, y1), (m (-2000), y1)]

/-- Region 10: the whole highway between its boundary lines. -/
def highwayWay : Structure := Build.region 10 .highway (strip (m (-12)) (m 12))

/-- Region 11: the eastbound lane, with the lane ordinal and the count of lanes in its direction
    as the source records them. -/
def eastLane (ordinal count : Option Nat) : Structure :=
  { Build.lane 11 (strip (m (-4)) Q.zero) Build.east (ordinal := ordinal) (count := count) with
      ways := some [10] }

/-- Region 12: the westbound lane of a two-lane, two-way highway. -/
def westLane : Structure :=
  { Build.lane 12 (strip Q.zero (m 4)) Build.west (ordinal := some 1) (count := some 1) with
      ways := some [10] }

/-- Region 14: a second eastbound lane, of the same direction of travel as region 11. -/
def secondEastLane : Structure :=
  { Build.lane 14 (strip (m (-8)) (m (-4))) Build.east with ways := some [10] }

/-- Region 13: the improved roadway. -/
def roadwayOf (y0 y1 : Q) : Structure :=
  { Build.region 13 .roadway (strip y0 y1) with ways := some [10] }

/-- Region 15: a barrier standing in the eastbound lane, on the way. -/
def barrier : Structure :=
  { Build.rect 15 .obstruction (m 30) (m (-3)) (m 33) (m (-1)) with
      ways := some [10], obstructionKind := some .barrier }

/-- The two-lane, two-way highway: one lane in each direction. -/
def twoWayWorld : List Structure :=
  [highwayWay, eastLane (some 1) (some 1), westLane, roadwayOf (m (-4)) (m 4)]

/-- A carriageway whose lane adjacency records three lanes in the subject's direction. -/
def threeLaneWorld : List Structure :=
  [highwayWay, eastLane (some 2) (some 3), roadwayOf (m (-4)) (m 4)]

/-- Two lanes of the subject's direction on the way, neither recording a lane count. -/
def twoSameDirectionLanesWorld : List Structure :=
  [highwayWay, eastLane none none, secondEastLane, roadwayOf (m (-8)) Q.zero]

def lorry (track : TrackId) (x speed : Q) : RoadUser :=
  Build.user track [.truck, .trailerOrCombination] (x, m (-2)) Build.east speed (m 9, cm 125, m 2)

/-- The same lorry, of which the source records no body extent, so the space between the bodies
    cannot be read. -/
def bodylessLorry (track : TrackId) (x speed : Q) : RoadUser :=
  Build.withKin (lorry track x speed) fun k => { k with extent := none }

def car (track : TrackId) (x speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, m (-2)) Build.east speed (cm 240, cm 89, cm 75)

def vanUser (track : TrackId) (x speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, m (-2)) Build.east speed (cm 250, cm 90, m 1)

/-- Three observations a second apart of one unchanging scene. -/
def still (users : List RoadUser) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => Build.scene t (some 1) users structures devices

/-- `forbid` (violated): On a two-lane rural highway with one lane in each direction, an articulated lorry runs at 22 m/s about 60 m behind another articulated lorry in the same lane, headings aligned. No road user is between them, no works or obstruction lies in the space, and the subject is well above the free-flow speed, so the conditions permit; the longitudinal gap is far below 500 feet. -/
def forbidTrace : Trace :=
  still [lorry 1 (m 0) (mps 22), lorry 2 (m 60) (mps 22)] twoWayWorld []

/-- `permit` (compliant): The same two lorries on the same highway at the same speed, but the follower holds a longitudinal gap of about 260 m, which exceeds 500 feet. -/
def permitTrace : Trace :=
  still [lorry 1 (m 0) (mps 22), lorry 2 (m 260) (mps 22)] twoWayWorld []

/-- `idle` (not_applicable): A passenger car — neither a truck of the truck aggregate nor a coupled combination, and 70 inches wide — follows an articulated lorry at 60 m on the same two-lane highway. The subject is outside the classes the subsection binds and the rule does not engage. -/
def idleTrace : Trace :=
  still [car 1 (m 0) (mps 22), lorry 2 (m 60) (mps 22)] twoWayWorld []

/-- `blind` (unknown): The forbid scene with the source declaring the gap between bodies absent: both road users' classes, the following relation and the single-lane carriageway are recorded, but the space cannot be read, so the duty is unknown. -/
def blindTrace : Trace :=
  still [lorry 1 (m 0) (mps 22), bodylessLorry 2 (m 60) (mps 22)] twoWayWorld []

/-- `branch_1` (not_applicable): The same two lorries at 60 m, moving on a dual carriageway whose lane adjacency records three lanes in their direction of travel. The second exception applies by its own words and the subsection does not apply. -/
def branch_1Trace : Trace :=
  still [lorry 1 (m 0) (mps 22), lorry 2 (m 60) (mps 22)] threeLaneWorld []

/-- `branch_2` (not_applicable): On the two-lane highway the following lorry is overtaking and passing the lorry ahead: the two travel in the same direction, the follower's speed exceeds the leader's by 4 m/s and the lorry ahead is still ahead of it in the lane as it passes. The first exception applies and the duty does not bite on the closed space. -/
def branch_2Trace : Trace :=
  still [lorry 1 (m 0) (mps 26), lorry 2 (m 60) (mps 22)] twoWayWorld []

/-- `branch_3` (compliant): The follower lorry is held at 2 m/s in a slow-moving queue on the two-lane highway, 10 m behind the lorry ahead, with a van that has moved into the space between them. Its speed is below the free-flow bound and a road user occupies the space, so the conditions do not permit and no space of 500 feet is owed at that observation. -/
def branch_3Trace : Trace :=
  still [lorry 1 (m 0) (mps 2), vanUser 3 (m 14) (mps 2), lorry 2 (m 28) (mps 2)] twoWayWorld []

/-- `branch_4` (not_applicable): The two lorries on a way that records no lane count, but on which
    a second lane of their direction of travel lies beside theirs: two lanes are available for
    traffic moving in the same direction, so the second exception applies. -/
def branch_4Trace : Trace :=
  still [lorry 1 (m 0) (mps 22), lorry 2 (m 60) (mps 22)] twoSameDirectionLanesWorld []

/-- `branch_5` (compliant): The forbid scene at free-flow speed with a van that has moved into the
    space 20 m ahead of the subject: a road user occupies the space, so the conditions do not
    permit although the stream runs freely. -/
def branch_5Trace : Trace :=
  still [lorry 1 (m 0) (mps 22), vanUser 3 (m 20) (mps 22), lorry 2 (m 60) (mps 22)] twoWayWorld []

/-- `branch_6` (compliant): The forbid geometry with both lorries creeping at 2 m/s and nothing in
    the space: the subject's speed alone is below the free-flow bound, so the conditions do not
    permit. -/
def branch_6Trace : Trace :=
  still [lorry 1 (m 0) (mps 2), lorry 2 (m 60) (mps 2)] twoWayWorld []

/-- `branch_7` (compliant): The forbid scene with a barrier standing on the way ahead: an
    obstruction makes the space impossible to hold, so the conditions do not permit. -/
def branch_7Trace : Trace :=
  still [lorry 1 (m 0) (mps 22), lorry 2 (m 60) (mps 22)] (twoWayWorld ++ [barrier]) []

/-- `branch_8` (not_applicable): The subject lorry leads and the other lorry runs 60 m behind it:
    the subject follows nothing, so the subsection never engages. -/
def branch_8Trace : Trace :=
  still [lorry 1 (m 0) (mps 22), lorry 2 (m (-60)) (mps 22)] twoWayWorld []

/-- `branch_9` (not_applicable): The subject lorry follows a passenger car 70 inches wide at 60 m:
    the road user followed is neither a truck of the aggregate nor a wide combination, so the
    subsection does not engage. -/
def branch_9Trace : Trace :=
  still [lorry 1 (m 0) (mps 22), car 2 (m 60) (mps 22)] twoWayWorld []

/-- `branch_10` (compliant): Both lorries stand still on the three-lane carriageway, 60 m apart:
    the subject is not moving, so the second exception does not apply by its own words, and the
    duty engages — but a standing subject is below the free-flow bound, so the conditions do not
    permit. -/
def branch_10Trace : Trace :=
  still [lorry 1 (m 0) (mps 0), lorry 2 (m 60) (mps 0)] threeLaneWorld []

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
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .compliant ]

end TrafficSpecWitness.NRS_484B_127_2
