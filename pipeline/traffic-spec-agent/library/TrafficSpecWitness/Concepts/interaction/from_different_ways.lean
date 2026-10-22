/-
  Witnesses for drv.interaction.from_different_ways.

  One crossroads carries all three scenarios. Every figure below is the witness's own, including
  the five seconds the instance gives the formal parameter `approach_window`.

  The crossroads, six regions (+x east, +y north):

    - region 11, the east-west street: a highway from x = -200 m to x = 200 m, y = -8 m to y = 8 m;
    - region 12, the north-south street: a highway from x = -8 m to x = 8 m, y = -200 m to y = 200 m;
    - region 13, the junction: the intersection where they meet, x and y from -8 m to 8 m, lying
      on both ways;
    - region 14, an eastbound approach lane of the east-west street: x = -200 m to x = -8 m,
      y = 0 m to y = 4 m, running east, entering junction 13, lying on way 11;
    - region 15, the eastbound lane beside it: the same stretch, y = 4 m to y = 8 m, running east,
      entering junction 13, lying on way 11;
    - region 16, a southbound approach lane of the north-south street: x = -8 m to x = 0 m,
      y = 8 m to y = 200 m, running south, entering junction 13, lying on way 12.

  Two cars, each 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m): track 1 is the formal `a`,
  track 2 the formal `b`. Three instants 1 s apart from t = 10 s; `witness` pads every trace with
  six seconds of the first scene before it and names the three instants as the window it speaks
  about, so the five-second look-back behind each of them is covered rather than truncated.

  holds: car 1 runs east at 6 m/s along lane 14 and is at x = -12 m at the first instant, inside
         the junction (x = -6 m, then x = 0 m) at the other two; car 2 stands at (-4 m, 20 m) in
         lane 16, facing south. Both approach lanes run into junction 13; lane 14 lies on way 11
         and lane 16 on way 12, so no way carries both. At the first instant car 1's membership of
         lane 14 is read at the observation itself; at the later two it is found 1 s and 2 s back,
         within the five-second window. The body is true at every instant of the window.
  fails: the same crossroads, both cars on the east-west street in the two adjacent lanes: car 1
         at y = 2 m in lane 14, car 2 at y = 6 m in lane 15, both running east at 6 m/s from
         x = -40 m, neither reaching the junction. Each is in its own approach lane at every
         instant and both lanes run into junction 13, but both lie on way 11, so way 11 is a way
         both approaches lie on and the body is false at every instant. Lane 16 is there and
         empty: no binding of either lane variable reaches it, because neither car's footprint
         ever overlaps it.
  blind: the holds scene on a source whose manifest declares st.on_way absent, so no region is
         mapped to the way it lies on. The junction, the lanes and the memberships are all still
         read, and each car's approach is still found, but whether lanes 14 and 16 lie on a common
         way cannot be read: every `st_on_way` conjunct is unknown, no binding of the quantifiers
         is true, and the body is unknown for that atom alone.
-/
import TrafficSpec.Concepts.interaction.from_different_ways
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.from_different_ways

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. The window
    behind within which an approach lane is looked for is five seconds, the witness's own figure. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.from_different_ways@w"
    concept := "drv.interaction.from_different_ways"
    literals := []
    nats := []
    params := [("approach_window", .lit (Units.seconds 5) .second)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The first of the three instants the witnesses speak about, in milliseconds. -/
def t0 : Timestamp := 10000

/-- The junction both streets run into. -/
def junction : RegionId := 13

/-- A rectangular approach lane: its corners, the direction it runs, the junction it enters and
    the public way it lies on. -/
def approachLane (id : RegionId) (x0 y0 x1 y1 : Q) (dir : Vec) (way : RegionId) : Structure :=
  { Build.lane id [(x0, y0), (x1, y0), (x1, y1), (x0, y1)] dir (enters := some junction) with
      ways := some [way] }

/-- The crossroads: the two streets, the junction where they meet, and the three approach lanes
    that run into it. -/
def crossroads : List Structure :=
  [ Build.rect 11 .highway (m (-200)) (m (-8)) (m 200) (m 8)
  , Build.rect 12 .highway (m (-8)) (m (-200)) (m 8) (m 200)
  , { Build.rect junction .intersection (m (-8)) (m (-8)) (m 8) (m 8) with ways := some [11, 12] }
  , approachLane 14 (m (-200)) (m 0) (m (-8)) (m 4) Build.east 11
  , approachLane 15 (m (-200)) (m 4) (m (-8)) (m 8) Build.east 11
  , approachLane 16 (m (-8)) (m 8) (m 0) (m 200) Build.south 12 ]

/-- A car of the witness: 4 m long and 2 m wide. -/
def car (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos heading speed (m 2, m 1, m 1)

/-- `holds` (compliant): Two cars meet at a crossroads: one came in on a lane of the east-west street and is now in the junction, the other stands in a lane of the north-south street that runs into the same junction. -/
def holdsTrace : Trace :=
  Build.trace 3 t0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (-12 + 6 * (k : Int)), m 2) Build.east (Units.metresPerSecond 6)
      , car 2 (m (-4), m 20) Build.south Q.zero ]
      crossroads
      []

/-- `fails` (violated): Two cars approach the same junction in adjacent lanes of one and the same street, both lanes lying on that street. -/
def failsTrace : Trace :=
  Build.trace 3 t0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (-40 + 6 * (k : Int)), m 2) Build.east (Units.metresPerSecond 6)
      , car 2 (m (-40 + 6 * (k : Int)), m 6) Build.east (Units.metresPerSecond 6) ]
      crossroads
      []

/-- `blind` (unknown): Two cars come to the same junction on lanes that run into it, but the source maps no region to the way it lies on. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := Build.pad τ (Units.seconds 6) Q.zero (Units.seconds 1)
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected
    window := some (t0, t0 + 2000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.on_way"] ]

end TrafficSpecWitness.Concepts.interaction.from_different_ways
