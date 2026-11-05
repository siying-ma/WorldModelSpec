/-
  Witnesses for drv.interaction.passing_vehicle_ahead.

  Two bodies and two lanes, nothing else: the concept reads the pair's headings, speeds, the
  overlap of their footprints along the first body's heading, and which of them is ahead of the
  other in a lane they share, so no device and no signal is built.

  The world. A straight way running east, two lanes of 4 m: lane 1 from y = −2 m to y = 2 m and
  lane 2 (its left neighbour) from y = 2 m to y = 6 m, both of direction east, both reaching from
  x = −300 m to x = 400 m so that every body of every trace lies inside one of them (occupancy is
  derived from the geometry). Both bodies are trucks 12 m long, 2.5 m wide and 3 m high
  (half-extents 6 m, 1.25 m, 1.5 m); track 1 is the first road user (`u`), track 2 the second
  (`v`).

  The instants. Nine instants one second apart (t = 0 … 8000 ms). Every scenario speaks about the
  last one (`window` = [8000, 8000]): the concept looks back over a five-second window, and at
  t = 8000 ms that window (t = 3000 … 8000 ms) lies inside the trace. The headings are written as
  east throughout, including through the lane change of the `holds` trace, whose lateral step of
  3 m in one second is a course about 7° off east — well inside the alignment tolerance below.

  The instance's own figures: a window of 5 s, the time within which one body draws level with
  another it was behind; an alignment tolerance of 0.98, the cosine of about 11°, the largest
  angle between two headings still read as travel in one direction; and a closing tolerance of
  1 m/s, the speed difference below which a reading counts as no gain.

    holds  — the faster truck (25 m/s, from x = −46 m) comes up on the slower one (20 m/s, from
             x = 0) in lane 1, changes to lane 2 after t = 4000 ms, and at t = 8000 ms stands at
             x = 154 m with the slower truck at x = 160 m: the headings are aligned, the speed
             difference is 5 m/s, the footprints' projections along the first truck's heading
             ([148, 160] and [154, 166]) share 6 m, and the last observation of the window at
             which the two were in one line of travel is t = 4000 ms — four seconds earlier, both
             in lane 1, the second truck 26 m ahead of the first.
    fails  — both trucks keep lane 1 at 22 m/s, 40 m apart: the projections along the heading share
             −28 m (a gap of 28 m between them, no shared length) and neither gains on the other,
             so no act of going by is read.
    blind  — the same passing, seen by a source that gives the slower truck's position, heading and
             speed but neither its extent nor its lane: with no footprint for it, nothing decides
             the length the projections share (rel.longitudinal_overlap is declared absent and no
             measurement of it is supplied), while that source does report the lane relation it
             measures — the slower truck ahead of the faster in one line of travel up to
             t = 4000 ms and not after, which is what the geometry of the `holds` trace shows — so
             the headings, the speeds and the earlier position behind are read as before and the
             drawing level, and with it the whole concept, is unknown.
-/
import TrafficSpec.Concepts.interaction.passing_vehicle_ahead
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.passing_vehicle_ahead

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1, v ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.passing_vehicle_ahead@w"
    concept := "drv.interaction.passing_vehicle_ahead"
    literals := []
    nats := []
    params :=
      [ ("pass_window", .lit (Units.seconds 5) .second)
      , ("alignment_tolerance", .lit (Units.ratio 98 100) .ratio)
      , ("closing_speed_tolerance", .lit (Units.metresPerSecond 1) .metrePerSecond) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The instant index as an integer, for the positions below. -/
def ki (k : Nat) : Int := Int.ofNat k

/-- Lane 1: the right-hand lane of the way, from y = −2 m to y = 2 m, running east. -/
def lane1 : Structure :=
  Build.lane 1 [(m (-300), m (-2)), (m 400, m (-2)), (m 400, m 2), (m (-300), m 2)]
    Build.east (left := some 2) (ordinal := some 2) (count := some 2)

/-- Lane 2: the left-hand lane of the same way, from y = 2 m to y = 6 m, running east. -/
def lane2 : Structure :=
  Build.lane 2 [(m (-300), m 2), (m 400, m 2), (m 400, m 6), (m (-300), m 6)]
    Build.east (right := some 1) (ordinal := some 1) (count := some 2)

def ways : List Structure := [lane1, lane2]

/-- A truck 12 m long, 2.5 m wide and 3 m high at the position and speed given, heading east. -/
def truck (track : TrackId) (x y : Q) (speed : Q) : RoadUser :=
  Build.user track [.truck, .motorVehicle] (x, y) Build.east speed (m 6, cm 125, cm 150)

/-- The same truck of which the source observes no extent, so no footprint of it is known. -/
def truckWithoutExtent (track : TrackId) (x y : Q) (speed : Q) : RoadUser :=
  Build.withKin (truck track x y speed) fun k => { k with extent := none }

/-- The faster truck of the passing traces: 25 m/s from x = −46 m. -/
def fastX (k : Nat) : Q := m (-46 + 25 * ki k)

/-- Its lateral position: lane 1 up to t = 4000 ms, then lane 2. -/
def fastY (k : Nat) : Q := if k ≤ 4 then m 0 else if k == 5 then m 3 else m 4

/-- The slower truck of the passing traces: 20 m/s from x = 0, keeping lane 1. -/
def slowX (k : Nat) : Q := m (20 * ki k)

/-- `holds` (compliant): A truck travelling at 25 m/s draws level with a truck travelling at 20 m/s: their headings are aligned, their footprints' projections along the first truck's heading share 6 m, and four seconds earlier the second truck was recorded ahead of the first in the same lane. -/
def holdsTrace : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (fastX k) (fastY k) (Units.metresPerSecond 25)
      , truck 2 (slowX k) (m 0) (Units.metresPerSecond 20) ]
      ways
      [ ]  -- devices

/-- `fails` (violated): The same two trucks travel in one lane at 22 m/s each with a 40 m gap: the projections along the heading share no positive length and neither gains on the other, so no act of going by is read. -/
def failsTrace : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (m (-40 + 22 * ki k)) (m 0) (Units.metresPerSecond 22)
      , truck 2 (m (22 * ki k)) (m 0) (Units.metresPerSecond 22) ]
      ways
      [ ]  -- devices

/-- `blind` (unknown): The faster truck is alongside the slower one with aligned headings and was behind it within the window, but the source supplies no longitudinal overlap: rel.longitudinal_overlap is absent, so whether the bodies are drawing level is unknown. -/
def blindTrace : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    let s := Build.scene t (some 1)
      [ truck 1 (fastX k) (fastY k) (Units.metresPerSecond 25)
      , truckWithoutExtent 2 (slowX k) (m 0) (Units.metresPerSecond 20) ]
      ways
      [ ]  -- devices
      (occupies := some [(1, if k ≤ 4 then 1 else 2)])
    -- The slower truck's body and its lane are not this source's to give, so Core can compute
    -- neither the shared length of the projections nor which of the two is ahead in a lane; the
    -- source reports the lane relation it measures itself, in both directions, and nothing else.
    Build.withRelations { s with occupancyObserved := [1] }
      [ Build.relation 1 2 fun r => { r with aAheadOfB := some false }
      , Build.relation 2 1 fun r => { r with aAheadOfB := some (if k ≤ 4 then true else false) } ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1), ("v", 2)]
    expected := expected
    window := some (8000, 8000) }   -- the one instant whose five-second window behind the trace covers

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"] ]

end TrafficSpecWitness.Concepts.interaction.passing_vehicle_ahead
