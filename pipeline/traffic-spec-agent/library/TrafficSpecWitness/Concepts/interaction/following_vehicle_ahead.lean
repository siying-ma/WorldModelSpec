/-
  Witnesses for drv.interaction.following_vehicle_ahead.

  One straight stretch of road running east, mapped as lanes 200 m long and 4 m wide: lane 10, the
  box from (-100, -2) to (100, 2), carrying the designated direction east, and — where a second
  lane is needed — lane 11, the box from (-100, 2) to (100, 6), also carrying east. Two cars, each
  4 m long and 1.8 m wide (half-extents 2 m, 0.9 m, 0.75 m): track 1, the follower, which the
  formal `u` is grounded to, and track 2, the leader, which `v` is grounded to. Both carry heading
  east, so the cosine of the angle between the two headings is 1. Occupancy is derived from the
  geometry: each car lies in every lane whose polygon contains its position. No device is built and
  no region formal is passed: the concept reads the two bodies' order in the lane, their headings
  and the follower's speed alone — not the gap between them, not its adequacy, not a pass, not a
  tailgating judgement. Each trace is three instants a second apart (t = 0, 1000, 2000 ms) with the
  same scene in each: the concept reads the observation itself, with no window behind or ahead, so
  every instant decides on its own and no scenario needs a `window`.

  The instance's own figures: an alignment tolerance of 0.95, the cosine at or below which two
  headings are no longer read as travel in one and the same direction (about 18° apart), and a
  motion tolerance of 1 m/s, the speed at or below which a reading counts as no travel.

    holds — the follower (track 1) stands at (0, 0) and the leader (track 2) at (30, 0), both in
            lane 10 and both travelling east at 20 m/s. The leader is ahead of the follower in that
            one lane along its direction, the cosine between the two headings is 1, well above the
            alignment tolerance of 0.95, and the follower's 20 m/s stands well above the motion
            tolerance of 1 m/s, so the follower is read as following.
    fails — the two cars travel east side by side in adjacent lanes: the follower at (0, 0) in lane
            10 and the leader at (0, 4) in lane 11, both at 20 m/s. Neither is ahead of the other
            in the same lane — they share no lane and neither lies behind the other along the
            heading — so the relation is decidedly false, although the cosine between the headings
            is still 1, above the alignment tolerance, and both speeds are above the motion
            tolerance.
    blind — the same scene as `holds`, the leader plainly in front of the follower in lane 10 and
            the headings aligned, but the source supplies no speed: the manifest declares
            `kin.speed` absent, so the speed field is blank and whether the follower's speed stands
            above the motion tolerance, and hence whether it follows, is unknown.
-/
import TrafficSpec.Concepts.interaction.following_vehicle_ahead
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.following_vehicle_ahead

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1, v ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: an alignment tolerance of 0.95, the cosine at or
    below which two headings are no longer read as one direction, and a motion tolerance of
    1 m/s, the speed at or below which a reading counts as no travel. Both figures are the
    witness's own. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.following_vehicle_ahead@w"
    concept := "drv.interaction.following_vehicle_ahead"
    literals := []
    nats := []
    params := [("alignment_tolerance", .lit (Units.ratio 95 100) .ratio),
               ("motion_speed_tolerance", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A rectangular polygon from two corners. -/
def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

/-- Lane 10: a 200 m × 4 m lane from (-100, -2) to (100, 2), designated east. -/
def laneRight : Structure := Build.lane 10 (box (m (-100)) (m (-2)) (m 100) (m 2)) Build.east

/-- Lane 11: the lane beside it, from (-100, 2) to (100, 6), designated east. -/
def laneLeft : Structure := Build.lane 11 (box (m (-100)) (m 2) (m 100) (m 6)) Build.east

/-- A car travelling east at the given speed from the given position: 4 m long, 1.8 m wide. -/
def car (track : TrackId) (x y : Q) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) Build.east speed (m 2, cm 90, cm 75)

/-- Three instants a second apart, the same cars and lanes in each. -/
def still (users : List RoadUser) (structures : List Structure) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures
      [ ]  -- devices

/-- `holds` (compliant): Two cars travel east in lane 10 at 20 m/s, the leader (track 2) at
    (30, 0) ahead of the follower (track 1) at (0, 0) in that one lane along its direction; the
    cosine between the two headings is 1, well above the alignment tolerance, and the follower's
    speed is well above the motion tolerance. The follower is read as following. -/
def holdsTrace : Trace :=
  still [ car 1 (m 0) (m 0) (Units.metresPerSecond 20)
        , car 2 (m 30) (m 0) (Units.metresPerSecond 20) ]
       [ laneRight ]

/-- `fails` (violated): The two cars travel east side by side in adjacent lanes, the follower at
    (0, 0) in lane 10 and the leader at (0, 4) in lane 11: neither is ahead of the other in the
    same lane, so the relation does not hold, although the cosine between the headings is 1, above
    the alignment tolerance, and both speeds are above the motion tolerance. -/
def failsTrace : Trace :=
  still [ car 1 (m 0) (m 0) (Units.metresPerSecond 20)
        , car 2 (m 0) (m 4) (Units.metresPerSecond 20) ]
       [ laneRight, laneLeft ]

/-- `blind` (unknown): The scene of `holds` — the leader plainly in front of the follower in lane
    10 and the headings aligned — with `kin.speed` declared absent, so no speed is observed and
    whether the follower's speed stands above the motion tolerance is unknown. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1), ("v", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.interaction.following_vehicle_ahead
