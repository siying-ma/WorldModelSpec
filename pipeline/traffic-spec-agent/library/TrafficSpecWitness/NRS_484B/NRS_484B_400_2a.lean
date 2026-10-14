/-
  Witnesses for NRS_484B_400_2a.

  The map, shared by all four scenes (+x east, +y north, metres):

    A two-directional highway runs north-south and meets a two-directional street running
    east-west. The junction is the square [-7, 7] × [-7, 7] (region 10, kind `intersection`).
    Three arms carry a roadway region, each of kind `roadway` and so not a roadway on which
    traffic is restricted to one direction: the south arm (20), the west arm (21) and the north
    arm (22).

    The south arm carries two lanes each way. Northbound (the subject's direction): lane 31,
    x ∈ [0, 3.5], hard against the centre line at x = 0 — ordinal 1 from the left, no left
    neighbour; and lane 32, x ∈ [3.5, 7], whose left neighbour of the same direction is 31.
    Both run into the junction (`enters := 10`). Southbound: 33 and 34, which leave it.
    The west arm carries westbound lanes 41 (y ∈ [0, 3.5], against the centre line) and 42,
    and eastbound lanes 43 and 44, which are approaches to the junction.

    One vehicle (track 1, a motor vehicle, 4 m long, 1.8 m wide) and no other road user. It runs
    at 7 m/s, one observation a second, from t = 0 to t = 6 s, and reaches the junction at
    t = 3 s. Every scene carries the vehicle's yaw rate, so that the heading change behind each
    observation can be formed; the trace is padded 14 s before and 10 s after, so that the
    look-back windows at the junction and the look-ahead window over the turn are covered and
    nothing is truncated.

    Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_2a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_2a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- An axis-aligned rectangle as a polygon. -/
def poly (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

/-- Heading north-west, a unit of north and a unit of west. -/
def northWest : Vec := (Units.ratio (-1) 1, Units.ratio 1 1)

-- The junction and the roadways of its three arms: none is restricted to one direction.
def junction : Structure := Build.rect 10 .intersection (m (-7)) (m (-7)) (m 7) (m 7)
def roadwaySouth : Structure := Build.rect 20 .roadway (m (-7)) (m (-300)) (m 7) (m (-7))
def roadwayWest : Structure := Build.rect 21 .roadway (m (-300)) (m (-7)) (m (-7)) (m 7)
def roadwayNorth : Structure := Build.rect 22 .roadway (m (-7)) (m 7) (m 7) (m 300)

-- The south arm: two lanes each way.
def laneNearCentre : Structure :=
  Build.lane 31 (poly (m 0) (m (-300)) (cm 350) (m (-7))) Build.north
    (right := some 32) (ordinal := some 1) (count := some 2) (enters := some 10)
def laneOuter : Structure :=
  Build.lane 32 (poly (cm 350) (m (-300)) (m 7) (m (-7))) Build.north
    (left := some 31) (ordinal := some 2) (count := some 2) (enters := some 10)
def laneSouthInner : Structure :=
  Build.lane 33 (poly (cm (-350)) (m (-300)) (m 0) (m (-7))) Build.south
    (right := some 34) (ordinal := some 1) (count := some 2)
def laneSouthOuter : Structure :=
  Build.lane 34 (poly (m (-7)) (m (-300)) (cm (-350)) (m (-7))) Build.south
    (left := some 33) (ordinal := some 2) (count := some 2)

-- The west arm: two lanes each way.
def laneWestInner : Structure :=
  Build.lane 41 (poly (m (-300)) (m 0) (m (-7)) (cm 350)) Build.west
    (right := some 42) (ordinal := some 1) (count := some 2)
def laneWestOuter : Structure :=
  Build.lane 42 (poly (m (-300)) (cm 350) (m (-7)) (m 7)) Build.west
    (left := some 41) (ordinal := some 2) (count := some 2)
def laneEastInner : Structure :=
  Build.lane 43 (poly (m (-300)) (cm (-350)) (m (-7)) (m 0)) Build.east
    (right := some 44) (ordinal := some 1) (count := some 2) (enters := some 10)
def laneEastOuter : Structure :=
  Build.lane 44 (poly (m (-300)) (m (-7)) (m (-7)) (cm (-350))) Build.east
    (left := some 43) (ordinal := some 2) (count := some 2) (enters := some 10)

def layout : List Structure :=
  [ junction, roadwaySouth, roadwayWest, roadwayNorth
  , laneNearCentre, laneOuter, laneSouthInner, laneSouthOuter
  , laneWestInner, laneWestOuter, laneEastInner, laneEastOuter ]

/-- The subject: a motor vehicle at a position and heading, with its yaw rate (deg/s, left
    positive) observed at every instant. -/
def veh (pos : Vec) (heading : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond 7) (m 2, cm 90, cm 75))
    (fun k => { k with yawRate := some yaw })

/-- `forbid` (violated): A highway of two lanes each way, neither roadway restricted to one direction, meets a two-way street; the junction, the lanes and their neighbours are all mapped and every atom is observed, and the trace runs well before the window behind and well past the window ahead. A single vehicle, with no other road user in the scene, approaches in the right-hand lane of its direction - a lane that has a neighbouring lane of the same direction on its left - holds it to the last observation before entry, crosses into the junction from it, and within the window ahead its integrated heading change to the left passes the swing. -/
def forbidVeh : Nat → RoadUser
  | 0 => veh (cm 525, cm (-2450)) Build.north Q.zero
  | 1 => veh (cm 525, cm (-1750)) Build.north Q.zero
  | 2 => veh (cm 525, cm (-1050)) Build.north Q.zero
  | 3 => veh (cm 525, cm (-350)) Build.north Q.zero
  | 4 => veh (m 2, cm 250) northWest (Units.degrees 45)
  | 5 => veh (m (-5), cm 250) Build.west (Units.degrees 45)
  | _ => veh (m (-12), cm 250) Build.west Q.zero

def forbidTrace : Trace :=
  Build.pad
    (Build.trace 7 0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1) [forbidVeh k] layout [])
    (Units.seconds 14) (Units.seconds 10) (Units.seconds 1)

/-- `permit` (compliant): The same highway, the same junction and the same left turn, every atom observed and both windows covered by the trace: the vehicle changes lanes early, travels the last of the approach in the lane that has no neighbour of its own direction on its left, is in that lane at the last observation before its footprint overlaps the junction, and swings left within the window ahead. -/
def permitVeh : Nat → RoadUser
  | 0 => veh (cm 525, cm (-2450)) Build.north Q.zero
  | 1 => veh (cm 175, cm (-1750)) Build.north Q.zero
  | 2 => veh (cm 175, cm (-1050)) Build.north Q.zero
  | 3 => veh (cm 175, cm (-350)) Build.north Q.zero
  | 4 => veh (cm (-150), cm 250) northWest (Units.degrees 45)
  | 5 => veh (cm (-850), cm 250) Build.west (Units.degrees 45)
  | _ => veh (cm (-1550), cm 250) Build.west Q.zero

def permitTrace : Trace :=
  Build.pad
    (Build.trace 7 0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1) [permitVeh k] layout [])
    (Units.seconds 14) (Units.seconds 10) (Units.seconds 1)

/-- `idle` (not_applicable): The same vehicle in the same right-hand lane of the same two-directional highway, every atom observed and the trace running well past the end of the window ahead so that nothing is truncated: it crosses into the junction and holds its heading, its integrated heading change staying below the swing at every observation of the window ahead, and it makes no turn at all. -/
def idleVeh : Nat → RoadUser
  | 0 => veh (cm 525, cm (-2450)) Build.north Q.zero
  | 1 => veh (cm 525, cm (-1750)) Build.north Q.zero
  | 2 => veh (cm 525, cm (-1050)) Build.north Q.zero
  | 3 => veh (cm 525, cm (-350)) Build.north Q.zero
  | 4 => veh (cm 525, cm 350) Build.north Q.zero
  | 5 => veh (cm 525, cm 1050) Build.north Q.zero
  | _ => veh (cm 525, cm 1750) Build.north Q.zero

def idleTrace : Trace :=
  Build.pad
    (Build.trace 7 0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1) [idleVeh k] layout [])
    (Units.seconds 14) (Units.seconds 10) (Units.seconds 1)

/-- `blind` (unknown): The permit scene - the vehicle approaching in the lane against the centre line of a two-directional highway and turning left within the window ahead, with the junction, the roadways, the one-way attribute and the vehicle's occupancy all observed - except that the source's manifest declares lane adjacency absent: it maps lanes but reads neither their neighbours nor their ordinals, so whether the lane the vehicle approached in had a same-direction neighbour on its left is never decided, and the duty is neither met nor broken on the trace. -/
def blindTrace : Trace := permitTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_400_2a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := window }

/-- The instant every witness speaks about: the entry into the junction, t = 3 s. The rule looks
    back over the approach and ahead over the turn, so the instants before it, where those windows
    run off the padded trace, are not what any of these scenes is about. -/
def entry : Option (Timestamp × Timestamp) := some (3000, 3000)

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated [] entry
  , witness "permit" permitTrace .compliant [] entry
  , witness "idle" idleTrace .notApplicable [] entry
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"] entry ]

end TrafficSpecWitness.NRS_484B_400_2a
