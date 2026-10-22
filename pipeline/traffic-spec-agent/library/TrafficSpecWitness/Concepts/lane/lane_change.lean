/-
  Witnesses for drv.lane.lane_change.

  The geometry, one straight eastbound three-lane one-way urban highway, is the same in all three
  scenarios:

    - region 13, the highway rectangle, x = -50 m to x = 400 m, y = -6 m to y = 6 m;
    - region 10, the left-hand lane, y = 2 m to y = 6 m, running east, first from the left of
      three, no left neighbour, right neighbour region 11;
    - region 11, the middle lane, y = -2 m to y = 2 m, second of three, left neighbour region 10,
      right neighbour region 12;
    - region 12, the right-hand lane, y = -6 m to y = -2 m, third of three, left neighbour region
      11, no right neighbour;
    - track 1 (u), a motor vehicle 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), heading
      east at 20 m/s, so it advances 20 m per instant;
    - eight instants 1 s apart, t = 0 s … 7 s.

  Heading east, the left hand is north, so region 10 is the left-hand neighbour of region 11 and
  the neighbour declarations and the geometry agree.

  The car's position lies inside the polygon of exactly one lane at every instant (y = 0 m is the
  middle of the middle lane, y = 4 m the middle of the left lane), so `Build.scene` derives the
  occupancy: the lane it is in, and the highway. Occupancy is observed for the one track built.

  The witness's own figures, the one the instance gives the formal parameter:
    lane_change_window = 3 s, and `side` = left.

  Every scenario names the instants it speaks about, t = 4 s … 6 s. With a 3 s window behind and
  observations 1 s apart, a window is covered from t = 3 s on (before that it reaches past the
  start of the trace and the concept is, as its contract says, unknown), and the gaps inside it
  are 1 s, under the 1.5 s adequacy bound. At t = 7 s the window behind no longer reaches back to
  an observation in the middle lane, which is where the concept stops holding.

  holds: the car runs in the middle lane at t = 0 … 3 s and in the left lane at t = 4 … 7 s. At
         t = 4, 5, 6 s its footprint is in the left lane, the left lane is the left-hand neighbour
         of the middle lane, and the window behind still reaches the middle-lane observation at
         t = 3 s (or earlier) at which it was in the middle lane and not the left — every conjunct
         true.
  fails: the same car holds the middle lane at every instant. The middle lane is the left-hand
         neighbour of the right lane, but the car never occupied the right lane, and it occupies
         the middle lane at every observation of the window behind, so no lane it could have come
         from is left — the body is false throughout the named instants.
  blind: the holds configuration on a source whose manifest declares st.lane_adjacency absent: it
         maps the lane regions and the car's membership of them, but no left or right neighbour
         (and no ordinal or count) for any lane, so which lane neighbours which is unobserved and
         the body is unknown; the lanes, the occupancy now and the occupancy in the window behind
         all stay decided.
-/
import TrafficSpec.Concepts.lane.lane_change
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.lane_change

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.lane.lane_change@w"
    concept := "drv.lane.lane_change"
    literals := [("side", "left")]
    nats := []
    params := [("lane_change_window", .lit (Units.seconds 3) .second)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- One lane of the carriageway: a rectangle between two y values, running east, with its
    neighbours and its place among the three lanes of the direction. -/
def laneBetween (id : RegionId) (y0 y1 : Q) (left right : Option RegionId) (ordinal : Nat) : Structure :=
  Build.lane id [(m (-50), y0), (m 400, y0), (m 400, y1), (m (-50), y1)] Build.east
    left right (some ordinal) (some 3)

/-- The three lanes and the highway they lie on. -/
def ways : List Structure :=
  [ laneBetween 10 (m 2) (m 6) none (some 11) 1
  , laneBetween 11 (m (-2)) (m 2) (some 10) (some 12) 2
  , laneBetween 12 (m (-6)) (m (-2)) (some 11) none 3
  , Build.rect 13 .highway (m (-50)) (m (-6)) (m 400) (m 6) ]

/-- The car at the `k`-th instant, `20 · k` metres along the highway, on the lane centre line `y`. -/
def car (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (Units.metres (20 * (k : Int)), y) Build.east
    (Units.metresPerSecond 20) (m 2, m 1, m 1)

/-- The centre line of the middle lane, and of the left-hand lane. -/
def middle : Q := m 0
def leftward : Q := m 4

/-- `holds` (compliant): A car runs in the middle of three lanes of a one-way urban highway, crosses the line and settles in the left-hand neighbour; at the observation its footprint is in the left lane only, and two seconds earlier it was in the middle lane only. -/
def holdsTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k (if k < 4 then middle else leftward)] ways []

/-- `fails` (violated): The same car holds the middle lane for the whole trace, its footprint within that lane at every observation of the window behind. -/
def failsTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k middle] ways []

/-- `blind` (unknown): The car crosses from the middle lane into the left lane as before, on a source that maps lane regions and road users' membership of them but declares no left or right neighbour for any lane. -/
def blindTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k (if k < 4 then middle else leftward)] ways []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    -- the instants the witness speaks about: the window behind is covered from t = 3 s on, and
    -- the movement is still within reach of the window until t = 6 s
    window := some (4000, 6000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"] ]

end TrafficSpecWitness.Concepts.lane.lane_change
