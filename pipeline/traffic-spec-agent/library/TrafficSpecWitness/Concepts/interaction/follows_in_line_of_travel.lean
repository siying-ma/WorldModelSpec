/-
  Witnesses for drv.interaction.follows_in_line_of_travel.

  One straight road running east and west carries the three scenarios. Every figure below is the
  witness's own, including the five values the instance gives the formal parameters: a travel-speed
  tolerance of 1 m/s, an alignment cosine of 0.8, an ahead offset of 1 m, a reach of 30 m and a
  line offset of 2 m.

  The road: a roadway region (id 10), its boundary polygon carried, from x = -200 m to x = 200 m
  and y = -5 m to y = 5 m, with no lane regions and no designated direction of its own — the body
  reads no region, no marking and no device, so the road is scenery that shows the relation is
  decided on a roadway a scene carries without lanes.

  The bodies are two cars, 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m): track 1 is the
  formal `f` and track 2 the formal `l`. Three observations one second apart from t = 0, so
  t = 0 s, 1 s, 2 s; both cars travel, so each scene's positions advance by the velocity. Nothing
  of the body looks before or after the observation, so no padding and no window are needed, and
  the verdict is the same at each of the three instants.

  holds:  both cars go due east at 10 m/s and point due east, f's reference point at x = 0 m and
          l's at x = 12 m at t = 0 s, both advancing 10 m a second. The offset of l from f is
          (12, 0) m; f's velocity is (10, 0) m/s and its speed 10 m/s, so the offset along f's
          course is 12 m — at least the ahead offset of 1 m and at most the reach of 30 m — and
          the offset across the course is nil, at most the line offset of 2 m. The inner product
          of the two velocities is 100 m²/s², at least 0.8 × 10 × 10 = 80, so the cosine of the
          angle between the two courses is one, above the alignment cosine. f travels behind l.
  fails:  both cars reverse due west at 2 m/s while their bodies still point due east — the
          velocity is (-2, 0) m/s and the heading is east — f's reference point at x = -6 m and
          l's at x = 0 m at t = 0 s, both retreating 2 m a second. f's speed, 2 m/s, stands clear
          of the tolerance, so its velocity fixes a direction of travel, and that direction runs
          west. The offset of l from f is (6, 0) m, whose component along f's westward course is
          -6 m: below the ahead offset of 1 m, so l lies behind f in the direction both of them
          travel and f travels behind nobody, although l stands 6 m ahead of f along the direction
          the two bodies point.
  blind:  the holds scene on a source whose manifest declares kin.velocity absent. Both positions,
          both speeds and both headings are observed, but neither velocity vector is, so neither
          the direction f travels nor the alignment of the two courses can be computed and the
          concept is unknown for that atom alone.
  creeps: a fourth witness, compliant, for the contract's "a body at rest being no bar to being
          travelled behind" — the one span the record's three narratives leave unexercised. f goes
          due east at 10 m/s from x = 0 m; l stands at x = 29 m and creeps due north at 0.5 m/s,
          below the travel-speed tolerance of 1 m/s, its body pointing north. The offset along f's
          course is 29 m, 19 m and 9 m at the three instants, inside [1 m, 30 m]; the offset across
          it is nil, 0.5 m and 1 m, within the line offset of 2 m. The two courses do not align —
          the inner product of the velocities is nil against 0.8 × 10 × 0.5 = 4 m²/s² — so the
          relation holds only through the second disjunct, l's own speed not standing clear of the
          travel-speed tolerance. A leader strictly at rest would not exercise that disjunct: with
          l's speed nil both sides of the alignment comparison are nil and the first disjunct
          already decides it true; a leader creeping across f's course below the tolerance is what
          makes the disjunct decide the verdict.
-/
import TrafficSpec.Concepts.interaction.follows_in_line_of_travel
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.follows_in_line_of_travel

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: f ↦ 1, l ↦ 2

/-- The instance every scenario speaks about: every parameter given a value through a `Units`
    constructor. A travel-speed tolerance of 1 m/s is the speed below which this source's measured
    velocity is taken to fix no direction of travel; an alignment cosine of 0.8 absorbs the bend of
    the road and the noise of the trajectories; an ahead offset of 1 m, a reach of 30 m and a line
    offset of 2 m are this witness's own figures for standing ahead, for being within reach and for
    being in the line rather than beside it. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.follows_in_line_of_travel@w"
    concept := "drv.interaction.follows_in_line_of_travel"
    literals := []
    nats := []
    params :=
      [ ("travel_speed_tolerance", .lit (Units.metresPerSecond 1) .metrePerSecond)
      , ("travel_alignment_cosine", .lit (Units.ratio 8 10) .ratio)
      , ("ahead_offset", .lit (Units.metres 1) .metre)
      , ("following_reach", .lit (Units.metres 30) .metre)
      , ("line_offset", .lit (Units.metres 2) .metre) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The road: one roadway without lanes, scenery the body never reads
-- ---------------------------------------------------------------------------------------------
/-- The roadway the two cars are on: its boundary polygon carried, no lane information. -/
def roadway : Structure := Build.rect 10 .roadway (m (-200)) (m (-5)) (m 200) (m 5)

def structures : List Structure := [roadway]

/-- A car of the witness: at a place on the road, pointing `heading`, travelling at `speed` along
    `velocity`, with yaw rate zero. The velocity is given explicitly so that a car may travel one
    way while its body points another. -/
def carAt (track : TrackId) (pos : Vec) (heading : Vec) (velocity : Vec) (speed : Q) : RoadUser :=
  Build.withKin
    (Build.user track [.motorVehicle] pos heading speed (m 2, m 1, m 1))
    fun k => { k with velocity := some velocity, yawRate := some Q.zero }

/-- A car on the centre line of the road, at easting `x`. -/
def car (track : TrackId) (x : Q) (heading : Vec) (velocity : Vec) (speed : Q) : RoadUser :=
  carAt track (x, m 0) heading velocity speed

/-- The easting of a car at the observation at second `k`: `x0` metres at t = 0 s, `v` metres of
    travel each second. -/
def easting (x0 v : Int) (k : Nat) : Q := m (x0 + v * Int.ofNat k)

/-- Both cars going due east at 10 m/s and pointing due east. -/
def eastbound : Vec := Build.scale Build.east (Units.metresPerSecond 10)

/-- Both cars reversing due west at 2 m/s while their bodies point due east. -/
def reversing : Vec := Build.scale Build.west (Units.metresPerSecond 2)

/-- `holds` (compliant): Two cars go due east at 10 m/s on a straight road, the subject's reference point at the origin and the other's 12 m due east of it, both velocities (10, 0) m/s and both bodies pointing east. The offset along the subject's course is 12 m, clear of the ahead offset and within the reach; the offset across the course is nil; the cosine of the angle between the two velocities is one. The subject travels behind the other in its own line of travel. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (easting 0 10 k) Build.east eastbound (Units.metresPerSecond 10)
      , car 2 (easting 12 10 k) Build.east eastbound (Units.metresPerSecond 10) ]
      structures
      []

/-- `fails` (violated): Both cars reverse due west at 2 m/s while their bodies point east, the subject's reference point 6 m due west of the other's. The offset of the other car's reference point along the subject's course, which runs west, is minus 6 m, so the other car lies behind the subject in the direction both of them travel and the subject travels behind nobody, although the other car stands ahead of it along the direction the two bodies point. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (easting (-6) (-2) k) Build.east reversing (Units.metresPerSecond 2)
      , car 2 (easting 0 (-2) k) Build.east reversing (Units.metresPerSecond 2) ]
      structures
      []

/-- `blind` (unknown): The same two cars going east 12 m apart, on a source that reports positions, speeds and headings but declares the velocity vector absent. Neither the direction the subject travels nor the alignment of the two courses can be computed, so the concept is unknown. -/
def blindTrace : Trace := holdsTrace

/-- Half a metre a second: a creep below the travel-speed tolerance of 1 m/s. -/
def creepSpeed : Q := Units.micrometresPerSecond 500000

/-- Due north at 0.5 m/s. -/
def creeping : Vec := Build.scale Build.north creepSpeed

/-- The northing of the creeping car at the observation at second `k`: 0.5 m of travel a second. -/
def northing (k : Nat) : Q := cm (50 * Int.ofNat k)

/-- `creeps` (compliant): The subject goes due east at 10 m/s from the origin. The other car stands 29 m due east of it and creeps due north at 0.5 m/s, below the travel-speed tolerance, its body pointing north. The offset along the subject's course stays inside the ahead offset and the reach and the offset across it within the line offset, while the two courses do not align: the relation holds through the second disjunct alone, a body that does not stand clear of the travel-speed tolerance being no bar to being travelled behind. -/
def creepsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (easting 0 10 k) Build.east eastbound (Units.metresPerSecond 10)
      , carAt 2 (m 29, northing k) Build.north creeping creepSpeed ]
      structures
      []

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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "creeps" creepsTrace .compliant ]

end TrafficSpecWitness.Concepts.interaction.follows_in_line_of_travel
