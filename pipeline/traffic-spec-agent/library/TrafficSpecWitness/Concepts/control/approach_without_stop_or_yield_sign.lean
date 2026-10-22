/-
  Witnesses for drv.control.approach_without_stop_or_yield_sign.

  One crossroads carries all three scenarios. Every figure below is the witness's own, including
  the five seconds the instance gives the formal parameter `approach_window`.

  The crossroads, eight regions (+x east, +y north):

    - region 11, the east-west street: a highway from x = -200 m to x = 200 m, y = -8 m to y = 8 m;
    - region 12, the north-south side street: a highway from x = -8 m to x = 8 m, y = -200 m to
      y = 200 m;
    - region 13, the junction: the intersection where they meet, x and y from -8 m to 8 m;
    - region 14, an eastbound approach lane of the east-west street: x = -200 m to x = -8 m,
      y = 0 m to y = 4 m, running east, entering junction 13;
    - region 15, the eastbound lane beside it: the same stretch, y = 4 m to y = 8 m, running east,
      entering junction 13;
    - regions 16 and 17, the two southbound lanes of the side street's north approach:
      x = -8 m to x = -4 m and x = -4 m to x = 0 m, y = 8 m to y = 200 m, running south, both
      entering junction 13;
    - region 18, the northbound approach lane of the side street from the south: x = 0 m to
      x = 8 m, y = -200 m to y = -8 m, running north, entering junction 13.

  One car, track 1, the formal `u`: 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m). Three
  instants 1 s apart from t = 10 s; `witness` pads every trace with six seconds of the first scene
  before it and names the three instants as the window it speaks about, so the five-second
  look-back behind each of them is covered rather than truncated — a lane the car never overlapped
  is then decidedly not its approach rather than unknown.

  holds: the car runs east at 6 m/s along lane 14 of the east-west street, at x = -12 m at the
         first instant and inside the junction (x = -6 m, then x = 0 m) at the other two. The only
         signs of the crossroads face the side street: stop sign 21 faces the two lanes of the
         north approach (16 and 17) and yield sign 22 faces the south approach (18). Lane 14 runs
         into junction 13 and the car's membership of it is read at the observation at the first
         instant and found 1 s and 2 s back at the other two; no stop sign and no yield sign is
         mapped to lane 14, so the body is true at every instant of the window.
  fails: the same crossroads, the car on the side street's north approach, running south at 6 m/s
         astride the line between its two lanes (x = -4 m, so its 2 m-wide footprint overlaps both
         lane 16 and lane 17), at y = 26 m, 20 m and 14 m. Here stop sign 21 faces lane 17 and
         yield sign 22 faces lane 16: of the two approach lanes the car came in on, one is faced
         by a stop sign and the other by a yield sign, so no approach lane of the junction that
         the car overlapped is free of both signs and the body is false at every instant. (The
         narrative's stop sign faces the car's approach; the second lane and its yield sign are
         the witness's own, so that the yield-sign reading of the body is exercised by a scene and
         not merely carried along: with the yield sign removed, lane 16 would make the body true.)
  blind: the fails scene on a source whose manifest declares dev.governs absent, so which traffic
         any device faces cannot be read. The junction, both approach lanes and the car's
         membership of them are all still read, and both signs are still read as a stop sign and a
         yield sign, but whether either faces lane 16 or lane 17 is unknown: every binding of the
         lane variable the car overlaps is unknown, none is true, and the body is unknown for that
         atom alone.
-/
import TrafficSpec.Concepts.control.approach_without_stop_or_yield_sign
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.control.approach_without_stop_or_yield_sign

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor. The window behind within which the approach lane is
    looked for is five seconds, the witness's own figure. -/
def inst : Concept.Instance :=
  { name := "drv.control.approach_without_stop_or_yield_sign@w"
    concept := "drv.control.approach_without_stop_or_yield_sign"
    literals := []
    nats := []
    params := [("approach_window", .lit (Units.seconds 5) .second)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The first of the three instants the witnesses speak about, in milliseconds. -/
def t0 : Timestamp := 10000

/-- The junction every approach lane of the crossroads runs into. -/
def junction : RegionId := 13

/-- A rectangular approach lane: its corners, the direction it runs, and the junction it enters. -/
def approachLane (id : RegionId) (x0 y0 x1 y1 : Q) (dir : Vec) : Structure :=
  Build.lane id [(x0, y0), (x1, y0), (x1, y1), (x0, y1)] dir (enters := some junction)

/-- The crossroads: the two streets, the junction where they meet, and the five approach lanes
    that run into it. -/
def crossroads : List Structure :=
  [ Build.rect 11 .highway (m (-200)) (m (-8)) (m 200) (m 8)
  , Build.rect 12 .highway (m (-8)) (m (-200)) (m 8) (m 200)
  , Build.rect junction .intersection (m (-8)) (m (-8)) (m 8) (m 8)
  , approachLane 14 (m (-200)) (m 0) (m (-8)) (m 4) Build.east
  , approachLane 15 (m (-200)) (m 4) (m (-8)) (m 8) Build.east
  , approachLane 16 (m (-8)) (m 8) (m (-4)) (m 200) Build.south
  , approachLane 17 (m (-4)) (m 8) (m 0) (m 200) Build.south
  , approachLane 18 (m 0) (m (-200)) (m 8) (m (-8)) Build.north ]

/-- A car of the witness: 4 m long and 2 m wide. -/
def car (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading speed (m 2, m 1, m 1)

/-- The signs of the crossroads in the `holds` scene: the stop sign faces the two lanes of the
    side street's north approach, the yield sign its south approach. -/
def signsFacingTheSideStreet : List Device :=
  [ Build.sign 21 .stopSign [16, 17]
  , Build.sign 22 .yieldSign [18] ]

/-- The signs of the crossroads in the `fails` and `blind` scenes: the stop sign faces the
    right-hand lane of the north approach, the yield sign the left-hand one. -/
def signsFacingTheApproach : List Device :=
  [ Build.sign 21 .stopSign [17]
  , Build.sign 22 .yieldSign [16] ]

/-- `holds` (compliant): A car runs along a lane of a two-lane road that ends at a crossroads; the only signs at the crossroads face the two side-road approaches, and nothing faces the car's lane. The concept holds for the car. -/
def holdsTrace : Trace :=
  Build.trace 3 t0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (-12 + 6 * (k : Int)), m 2) Build.east (Units.metresPerSecond 6) ]
      crossroads
      signsFacingTheSideStreet

/-- `fails` (violated): The same crossroads, but the car is on the side-road approach, whose lane a stop sign faces. The concept fails for the car. -/
def failsTrace : Trace :=
  Build.trace 3 t0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (-4), m (26 - 6 * (k : Int))) Build.south (Units.metresPerSecond 6) ]
      crossroads
      signsFacingTheApproach
      (some [(1, 12), (1, 16), (1, 17)])

/-- `blind` (unknown): The same side-road approach with a stop sign standing beside it, but the source does not report which traffic any device faces, so whether the sign faces the car's lane cannot be read. -/
def blindTrace : Trace := failsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := Build.pad τ (Units.seconds 6) Q.zero (Units.seconds 1)
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := some (t0, t0 + 2000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["dev.governs"] ]

end TrafficSpecWitness.Concepts.control.approach_without_stop_or_yield_sign
