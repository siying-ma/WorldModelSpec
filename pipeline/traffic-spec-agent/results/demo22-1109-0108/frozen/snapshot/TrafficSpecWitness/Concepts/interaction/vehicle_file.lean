/-
  Witnesses for drv.interaction.vehicle_file.

  The geometry. One straight east-bound lane (region 1) on a rural highway, the rectangle
  x ∈ [-50 m, 500 m], y ∈ [-2 m, 2 m], its direction east. Every car is 5 m long and 2 m wide
  (half extents 2.5 m, 1 m, 0.75 m), sits on the lane centre line (y = 0), heads east and runs at
  20 m/s; each trace is three observations one second apart, so every car advances 20 m per
  observation and the distances between them never change. u is track 1.

  The instance's figures: min_member_count 3 road users, file_reach 50 m, same_direction_tolerance
  0.95 (all five headings are identical, cosine 1).

  `holds`: five cars at x = 0, 25, 50, 75, 100 at the first observation, so the gap between the
  bodies of neighbours is 25 − 2.5 − 2.5 = 20 m. From u (x = 0) the gaps are 20 m (track 2), 45 m
  (track 3), 70 m (track 4) and 95 m (track 5): u itself, track 2 and track 3 lie within the 50 m
  reach, ahead of u in the lane and aligned with it — three members, the minimum count.

  `fails`: u alone in the lane with one other car at x = 400, a gap of 395 m between the bodies.
  u is the only member: one road user, short of three.

  `blind`: the same five cars, but the source measures the gap between the bodies rather than the
  cars' extents: it reports the surface gap (and which car is ahead of which in the lane) as
  measured relations and gives no extent, so no footprint can be read from the geometry. With the
  gap observed the count is three; with `rel.surface_gap` absent the mask drops the measured gap,
  nothing can replace it, and how many cars lie within the reach cannot be read.
-/
import TrafficSpec.Concepts.interaction.vehicle_file
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.vehicle_file

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.vehicle_file@w"
    concept := "drv.interaction.vehicle_file"
    literals := []
    nats := []
    params := [("min_member_count", .lit (Q.ofInt 3) .count), ("file_reach", .lit (m 50) .metre),
               ("same_direction_tolerance", .lit (Units.ratio 95 100) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The east-bound lane the file runs in. -/
def theLane : Structure :=
  Build.lane 1 [(m (-50), m (-2)), (m 500, m (-2)), (m 500, m 2), (m (-50), m 2)] Build.east
    (ordinal := some 1) (count := some 1)

/-- A car on the lane centre line, `x0` at the first observation, advancing 20 m per observation. -/
def car (track : TrackId) (x0 : Int) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (m (x0 + 20 * Int.ofNat k), m 0) Build.east
    (Units.metresPerSecond 20) (cm 250, m 1, cm 75) (some (m (20 * Int.ofNat k)))

/-- `holds` (compliant): Five cars run in file in one lane of a rural highway, each within 20 m of the next and all headings aligned: each of them, counting itself, has at least three members of the group within the reach, ahead of or behind it in the lane. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 0 k, car 2 25 k, car 3 50 k, car 4 75 k, car 5 100 k ]
      [ theLane ]
      [ ]

/-- `fails` (violated): One car runs alone in that lane with the nearest other road user 400 m ahead: the minimum member count is not reached within the reach. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 0 k, car 2 400 k ]
      [ theLane ]
      [ ]

/-- A car of which the source observes the position, the heading and the motion but not the
    extent, so that no footprint — and no computed surface gap — can be read from it. -/
def gaugedCar (track : TrackId) (x0 : Int) (k : Nat) : RoadUser :=
  Build.withKin (car track x0 k) fun kin => { kin with extent := none }

/-- The gap between the bodies of u (track 1) and each of the other four cars, as the source
    measures it: 20 m, 45 m, 70 m, 95 m, all of it longitudinal. -/
def gauged : List (TrackId × Int) := [(2, 20), (3, 45), (4, 70), (5, 95)]

/-- What the source supplies and the geometry cannot give without the extents: the surface gap
    from u to each other car, and which of the two lies ahead of the other in the lane. -/
def gaugedRelations : List MeasuredRelation :=
  gauged.flatMap fun (v, g) =>
    [ Build.relation 1 v fun r => { r with surfaceGap := some (m g, m 0), aAheadOfB := some false }
    , Build.relation v 1 fun r => { r with aAheadOfB := some true } ]

/-- `blind` (unknown): The five cars with the source declaring the gap between bodies absent: how far apart the members are, and so how many lie within the reach, cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s :=
      Build.scene t (some 1)
        [ gaugedCar 1 0 k, gaugedCar 2 25 k, gaugedCar 3 50 k, gaugedCar 4 75 k, gaugedCar 5 100 k ]
        [ theLane ]
        [ ]
    { s with occupancyObserved := [], occupies := [], relations := gaugedRelations }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"] ]

end TrafficSpecWitness.Concepts.interaction.vehicle_file
