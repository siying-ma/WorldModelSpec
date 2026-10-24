/-
  Witnesses for drv.interaction.following_in_lane.

  One straight roadway running north carries the three scenarios. Every figure below is the
  witness's own, including the two the instance gives the formal parameters: an alignment
  tolerance of 0.9 (the cosine of about 26 degrees) and a reach of 20 m.

  The two bodies are cars, 4 m long and 1.8 m wide (half-extents 2 m, 0.9 m, 0.75 m): the
  follower is track 1, the formal `f`, and the leader is track 2, the formal `l`. Both run north
  at 10 m/s, 10 m further on at each observation. Three instants one second apart from t = 0, so
  t = 0 s, 1 s, 2 s. Nothing in the body looks behind or ahead of the observation, so no padding
  and no window are needed: every scenario is read over the whole of its trace.

  Occupancy is derived from the geometry, so each scene says which lanes a footprint overlaps by
  where the body stands; the lanes are 4 m wide and the cars run down the middle of one.

  holds:  a roadway 8 m wide from x = -8 m to x = 0 m with one lane in it, from x = -4 m to
          x = 0 m, running north. Both cars run down the middle of that lane at x = -2 m, the
          leader 12 m north of the follower, so the longitudinal clearance between the two bodies
          is 12 m less the two half-lengths, 8 m, well inside the reach of 20 m; the headings are
          identical, so the cosine between them is 1, well above the tolerance of 0.9; and the
          leader lies ahead of the follower along the lane. The concept holds at each of the three
          observations.
  fails:  the same roadway with two neighbouring lanes in it, from x = -8 m to x = -4 m and from
          x = -4 m to x = 0 m, both running north. The follower runs down the middle of the left
          lane at x = -6 m and the leader down the middle of the right lane at x = -2 m, abreast
          of it at the same northing. No single lane is overlapped by both footprints, so the
          existential over the lanes is false, and neither body is ahead of the other along one
          lane's direction. The headings are still aligned and the bodies are still within the
          reach of each other: the concept fails on the lane and the order alone, at each of the
          three observations.
  blind:  the holds trace itself, read by a source that reports no gap between the bodies: its
          manifest declares rel.surface_gap absent. A manifest that drops the gap alone would not
          leave it unreported, since the library computes a clearance between two bodies from
          their places, headings and extents wherever the source does not measure one; and a
          scene may not withhold the extent of a body whose occupancy is observed, the adapter
          lint requiring a footprint of it. The source therefore declares kin.extent absent as
          well: a source that cannot tell how big a body is cannot report a gap between the
          nearest points of two bodies, measured or computed. Everything else is as in holds — the
          lane both footprints overlap, the order along the lane and the two headings are all
          observed and all decided — so the concept is unknown, and unknown for the gap alone.
-/
import TrafficSpec.Concepts.interaction.following_in_lane
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.following_in_lane

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: f ↦ 1, l ↦ 2

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor. The alignment tolerance is 0.9, the cosine of about 26
    degrees, and the reach is 20 m — the witness's own figures for how nearly the two bodies must
    point one way and for how far ahead the body followed may lie. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.following_in_lane@w"
    concept := "drv.interaction.following_in_lane"
    literals := []
    nats := []
    params := [("heading_alignment_cosine", .lit (Units.ratio 9 10) .ratio),
               ("following_reach", .lit (Units.metres 20) .metre)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The way: a straight roadway running north, with the lanes each scenario needs in it
-- ---------------------------------------------------------------------------------------------
/-- A lane of the way between two eastings, running north the whole length of the scene. -/
def northLane (id : RegionId) (x0 x1 : Q) (left right : Option RegionId) : Structure :=
  Build.lane id [(x0, m (-100)), (x1, m (-100)), (x1, m 100), (x0, m 100)] Build.north left right

/-- The roadway the lanes lie in: no lane itself, and read by nothing in the body. -/
def roadway (id : RegionId) : Structure := Build.rect id .roadway (m (-8)) (m (-100)) (m 0) (m 100)

/-- A car of the witness at a place on the way, heading north at 10 m/s. -/
def car (track : TrackId) (x y : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) Build.north (Units.metresPerSecond 10) (m 2, cm 90, cm 75)

/-- The northing of the follower at the observation at second `k`: 10 m further on each second. -/
def northing (k : Nat) : Q := m (10 * Int.ofNat k)

-- ---------------------------------------------------------------------------------------------
-- holds (and blind): one lane, the leader 12 m ahead of the follower in it
-- ---------------------------------------------------------------------------------------------
def holdsStructures : List Structure := [roadway 10, northLane 11 (m (-4)) (m 0) none none]

/-- `holds` (compliant): Two vehicles run in one marked lane of a straight roadway, both footprints overlapping that lane and the headings aligned well within the cosine the caller sets. The leading body lies ahead of the following body along the lane's direction and the longitudinal component of the gap between the two bodies is well inside the reach the caller sets. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (-2)) (northing k)
      , car 2 (m (-2)) (Q.add (northing k) (m 12)) ]
      holdsStructures
      []

-- ---------------------------------------------------------------------------------------------
-- fails: two neighbouring lanes, the two bodies abreast, one in each
-- ---------------------------------------------------------------------------------------------
def failsStructures : List Structure :=
  [ roadway 20
  , northLane 21 (m (-8)) (m (-4)) none (some 22)
  , northLane 22 (m (-4)) (m 0) (some 21) none ]

/-- `fails` (violated): The same two vehicles run side by side in neighbouring lanes of the same roadway, each footprint overlapping a lane of its own, so that no single lane is overlapped by both and neither lies ahead of the other along one lane's direction. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (-6)) (northing k)
      , car 2 (m (-2)) (northing k) ]
      failsStructures
      []

-- ---------------------------------------------------------------------------------------------
-- blind: the holds scene from a source that reports no gap between the bodies
-- ---------------------------------------------------------------------------------------------
/-- `blind` (unknown): The two vehicles run in one lane with aligned headings and the leading body ahead of the following one, but the source reports no gap between the bodies, so whether the leader lies within the reach cannot be told. -/
def blindTrace : Trace := holdsTrace

/-- The atoms the blind source does not observe: the gap between two bodies, and the extent of a
    body, from which a gap would otherwise be computed. -/
def blindAbsent : List String := ["rel.surface_gap", "kin.extent"]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("f", 1), ("l", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) blindAbsent ]

end TrafficSpecWitness.Concepts.interaction.following_in_lane
