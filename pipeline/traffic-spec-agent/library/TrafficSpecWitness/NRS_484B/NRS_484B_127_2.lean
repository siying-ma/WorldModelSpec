/-
  Witnesses for NRS_484B_127_2.

  The map (metres, +x east, +y north; every figure here is the witness's own and appears nowhere in
  the rule):

  - the rural way (region 1, a highway, x in [-8, 8], y in [-200, 1000]) runs north-south with one
    lane in each direction: lane 11 northbound (x in [0, 8], ordinal 1, one lane in its direction)
    and lane 12 southbound (x in [-8, 0], ordinal 1, one lane in its direction), both lying on
    way 1.
  - the multi-lane way (region 2, a highway, x in [-8, 16]) carries two northbound lanes — 21
    (x in [0, 8], ordinal 1) and 22 (x in [8, 16], ordinal 2), each recording two lanes in that
    direction and each the other's neighbour — and the southbound lane 23 (x in [-8, 0]), all
    lying on way 2.
  - a wide goods truck is 20 m long and 100 inches wide (half-extents 10 m, 50 in, 2 m); a narrow
    one is 60 inches wide (half-width 30 in); a passenger car is 4 m long and 2 m wide.
  - each trace is three observations 1 s apart, the bodies advancing by their own speed, so that
    every scene's speed and geometry agree. Occupancy is read from the geometry (each body's
    reference point lies in its lane and on its way) except in `branch_2`, where the passing
    body straddles the lane line and its overlap of both lanes is stated.
  - `branch_2` is padded by 15 s of its first and last scene at each end, so that the 10 s window
    in which the pass's line-of-travel history is read is covered rather than truncated; each
    witness names the instants it speaks about (`window`), the three unpadded observations.

  The figures the scenes turn on: 500 feet is 152.4 m, the free-flow minimum 8 m/s, the motion
  tolerance 0.3 m/s. A forbidding gap is 40 m, a permitting one 200 m; a free-flowing truck runs
  at 22 m/s, a queued one at 4 m/s.

  `blind` is the one scene whose source is incomplete. Core reads a body gap from the two
  footprints wherever it has them, and a manifest that calls `rel.surface_gap` absent drops only a
  gap the source supplies: a source that reads no gap between the bodies is therefore a source
  that cannot draw one of them. Its lead truck is given its class, its size, its place and its
  speed, but not its orientation, and its occupancy is not among the source's observations, so no
  footprint of it exists; the relations that source measures of the pair directly — the lead body
  ahead of the follower in one line of travel, the two headings aligned — are supplied, which
  Core permits here because it can compute neither without an orientation and an observed
  occupancy. Everything the rule reads is then decided except the gap between the bodies, and the
  witness is unknown for that atom alone.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_127_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_127_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def inch (n : Int) : Q := Units.inches n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

-- ---------------------------------------------------------------------------------------------
-- Bodies
-- ---------------------------------------------------------------------------------------------
/-- A truck 20 m long and 100 inches wide: over the 80 inches the text names. -/
def wideExt : Q × Q × Q := (m 10, inch 50, m 2)
/-- A truck 20 m long and 60 inches wide: under the 80 inches the text names. -/
def narrowExt : Q × Q × Q := (m 10, inch 30, m 2)
/-- A passenger car, 4 m long and 2 m wide. -/
def carExt : Q × Q × Q := (m 2, m 1, cm 75)

/-- A body travelling north at its own speed: at the k-th observation it has advanced by k times
    that speed from where it started. -/
def northbound (track : TrackId) (classes : List RoadUserClass) (ext : Q × Q × Q)
    (x : Q) (y0 speed : Int) (k : Nat) : RoadUser :=
  Build.user track classes (x, m (y0 + speed * Int.ofNat k)) Build.north (mps speed) ext

-- ---------------------------------------------------------------------------------------------
-- The ways
-- ---------------------------------------------------------------------------------------------
def ruralWay : Structure := Build.rect 1 .highway (m (-8)) (m (-200)) (m 8) (m 1000)

def rightLane : Structure :=
  { Build.lane 11 [(m 0, m (-200)), (m 8, m (-200)), (m 8, m 1000), (m 0, m 1000)]
      Build.north (ordinal := some 1) (count := some 1) with ways := some [1] }

def oncomingLane : Structure :=
  { Build.lane 12 [(m (-8), m (-200)), (m 0, m (-200)), (m 0, m 1000), (m (-8), m 1000)]
      Build.south (ordinal := some 1) (count := some 1) with ways := some [1] }

/-- One lane in each direction: no lane of this way records a second lane in its direction. -/
def ruralRoad : List Structure := [ruralWay, rightLane, oncomingLane]

def multiWay : Structure := Build.rect 2 .highway (m (-8)) (m (-200)) (m 16) (m 1000)

def innerLane : Structure :=
  { Build.lane 21 [(m 0, m (-200)), (m 8, m (-200)), (m 8, m 1000), (m 0, m 1000)]
      Build.north (right := some 22) (ordinal := some 1) (count := some 2) with ways := some [2] }

def outerLane : Structure :=
  { Build.lane 22 [(m 8, m (-200)), (m 16, m (-200)), (m 16, m 1000), (m 8, m 1000)]
      Build.north (left := some 21) (ordinal := some 2) (count := some 2) with ways := some [2] }

def multiOncomingLane : Structure :=
  { Build.lane 23 [(m (-8), m (-200)), (m 0, m (-200)), (m 0, m 1000), (m (-8), m 1000)]
      Build.south (ordinal := some 1) (count := some 1) with ways := some [2] }

/-- Two lanes available for traffic moving in the subject's direction. -/
def multiLaneRoad : List Structure := [multiWay, innerLane, outerLane, multiOncomingLane]

-- ---------------------------------------------------------------------------------------------
-- Traces
-- ---------------------------------------------------------------------------------------------
def traceOf (structures : List Structure) (users : Nat → List RoadUser)
    (occupies : Option (List (TrackId × RegionId)) := none) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (users k) structures [] occupies

/-- `forbid` (violated): On a two-lane rural highway with one lane in each direction, a goods truck 100 inches wide travels at 22 m/s behind another goods truck of the same width in the same lane, headings aligned, with a longitudinal body gap of 40 m. No third vehicle is between them and no other road user is in the scene. -/
def forbidTrace : Trace :=
  traceOf ruralRoad fun k =>
    [ northbound 1 [.truck] wideExt (m 4) 0 22 k
    , northbound 2 [.truck] wideExt (m 4) 60 22 k ]

/-- `permit` (compliant): The same two trucks on the same single-lane-per-direction highway at the same speed, the follower holding a longitudinal body gap of 200 m, above 500 feet, with no third vehicle in the space. -/
def permitTrace : Trace :=
  traceOf ruralRoad fun k =>
    [ northbound 1 [.truck] wideExt (m 4) 0 22 k
    , northbound 2 [.truck] wideExt (m 4) 220 22 k ]

/-- `idle` (not_applicable): A goods truck 100 inches wide follows a passenger car closely on the same rural highway: the leader is neither a truck nor a combination of vehicles, so the duty is not engaged. -/
def idleTrace : Trace :=
  traceOf ruralRoad fun k =>
    [ northbound 1 [.truck] wideExt (m 4) 0 22 k
    , northbound 2 [.motorVehicle] carExt (m 4) 30 22 k ]

/-- The lead truck as the blind source sees it: its class, its size, its place and its speed, but
    not its orientation, and its body never outlined on the map — so no footprint of it can be
    drawn and no gap between the bodies read. -/
def headinglessLeader (k : Nat) : RoadUser :=
  { track := 2
    classes := some [.truck]
    kin := { position := some (m 4, m (60 + 22 * Int.ofNat k))
             speed := some (mps 22)
             extent := some wideExt } }

/-- `blind` (unknown): The two wide trucks follow one another as in the forbid scenario, but the source supplies no body gaps: rel.surface_gap is absent, so whether 500 feet is left is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      { Build.scene t (some 1)
          [ northbound 1 [.truck] wideExt (m 4) 0 22 k, headinglessLeader k ]
          ruralRoad [] (some [(1, 1), (1, 11)]) with occupancyObserved := [1] }
      -- the relations this source measures of the pair directly; Core can compute neither of
      -- them here, the lead body having neither an orientation nor an observed occupancy
      [ Build.relation 1 2 fun r => { r with aAheadOfB := some false, sameDirection := some true }
      , Build.relation 2 1 fun r => { r with aAheadOfB := some true, sameDirection := some true } ]

/-- `branch_1` (not_applicable): The same two wide trucks travel 40 m apart in the right lane of a highway whose lane adjacency records two lanes in their direction of travel, both moving: the subsection does not apply. -/
def branch_1Trace : Trace :=
  traceOf multiLaneRoad fun k =>
    [ northbound 1 [.truck] wideExt (m 12) 0 22 k
    , northbound 2 [.truck] wideExt (m 12) 60 22 k ]

/-- `branch_2` (not_applicable): The follower, a 100-inch truck, pulls out and goes by the wide truck ahead on the single-lane-per-direction highway: its speed exceeds the leader's, their bodies overlap along its heading, and within the pass window behind the leader was ahead of it in the same lane. The duty does not prevent the pass. -/
def branch_2Trace : Trace :=
  Build.pad
    (traceOf ruralRoad
      (fun k =>
        [ northbound 1 [.truck] wideExt (m (-1)) 0 25 k
        , northbound 2 [.truck] wideExt (m 4) 10 22 k ])
      (some [(1, 1), (1, 11), (1, 12), (2, 1), (2, 11)]))
    (Units.seconds 15) (Units.seconds 15) (Units.seconds 1)

/-- `branch_3` (compliant): The follower, a 100-inch truck, crawls in a queue 15 m behind the wide truck ahead, its speed below the free-flow minimum: conditions do not permit the 500-foot space and no violation arises. (A halted follower follows nothing — the relation the trigger reads needs motion — so the queue creeps at 4 m/s.) -/
def branch_3Trace : Trace :=
  traceOf ruralRoad fun k =>
    [ northbound 1 [.truck] wideExt (m 4) 0 4 k
    , northbound 2 [.truck] wideExt (m 4) 35 4 k ]

/-- `branch_4` (compliant): The two wide trucks run 40 m apart at 22 m/s as in the forbid scenario, but a passenger car travels in the same lane 13 m ahead of the follower, inside the space it would have to leave: conditions do not permit it, and the short gap is no violation. -/
def branch_4Trace : Trace :=
  traceOf ruralRoad fun k =>
    [ northbound 1 [.truck] wideExt (m 4) 0 22 k
    , northbound 2 [.truck] wideExt (m 4) 60 22 k
    , northbound 3 [.motorVehicle] carExt (m 4) 25 22 k ]

/-- `branch_5` (violated): A combination of vehicles 100 inches wide follows another combination of the same width at 22 m/s with a body gap of 40 m on the single-lane-per-direction highway: the duty binds a combination as it binds a truck. -/
def branch_5Trace : Trace :=
  traceOf ruralRoad fun k =>
    [ northbound 1 [.trailerOrCombination] wideExt (m 4) 0 22 k
    , northbound 2 [.trailerOrCombination] wideExt (m 4) 60 22 k ]

/-- `branch_6` (not_applicable): The wide truck follows a goods truck only 60 inches wide, 40 m ahead in the same lane: the vehicle followed is under the width the text names, so the duty is not engaged. -/
def branch_6Trace : Trace :=
  traceOf ruralRoad fun k =>
    [ northbound 1 [.truck] wideExt (m 4) 0 22 k
    , northbound 2 [.truck] narrowExt (m 4) 60 22 k ]

/-- `branch_7` (not_applicable): A goods truck only 60 inches wide follows a 100-inch truck 40 m ahead in the same lane: the subject is under the width the text names, so the duty does not bind it. -/
def branch_7Trace : Trace :=
  traceOf ruralRoad fun k =>
    [ northbound 1 [.truck] narrowExt (m 4) 0 22 k
    , northbound 2 [.truck] wideExt (m 4) 60 22 k ]

def witness (name : String) (τ : Trace) (expected : Verdict) (lastMs : Timestamp := 2000)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_127_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, lastMs)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) 2000 ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_127_2
