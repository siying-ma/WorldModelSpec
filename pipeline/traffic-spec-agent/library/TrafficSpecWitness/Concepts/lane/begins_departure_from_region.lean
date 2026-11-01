/-
  Witnesses for drv.lane.begins_departure_from_region.

  The concept takes no formal parameter and no literal formal, so the instance fills nothing: every
  figure below is geometry the witness chooses.

  Every trace runs three observations a second apart (t = 0, 1000, 2000 ms) over a static map of two
  lanes designated due east, one car (track 1, 4.5 m long and 1.8 m wide, running east at 10 m/s,
  the trace's subject). Region 100 is the right-hand lane, the region the concept is asked about
  (the region formal `r`); region 101 is the left-hand lane beside it, their shared boundary the
  lane line at y = 0. The concept reads no marking, so the line is that boundary and nothing else.

  Occupancy is given explicitly, as a footprint's overlap with a boundary and not as a centre point
  inside one: in each scene the pairs listed are exactly those whose rectangles overlap, the car's
  footprint being its 4.5 m × 1.8 m rectangle about its position.

  `holdsTrace` — the right-hand lane (region 100, y in [-4, 0] m) and the left-hand lane (region
  101, y in [0, 4] m), both 100 m long. The car runs east and drifts left: at t = 0 it is at
  (-10, -2) m, its footprint wholly within the right-hand lane; at t = 1000 ms at (0, -0.5) m, its
  near-side corner 0.4 m over the lane line, so its footprint overlaps both lanes; at t = 2000 ms at
  (10, -0.3) m, still straddling. The window is the single observation t = 1000 ms: there the
  footprint overlapped region 100 at the previous observation and overlaps region 101, a travel
  region other than it, which it did not overlap before — the departure begins. At t = 2000 ms
  region 101 is no longer newly overlapped and the concept does not hold again, which is why the
  witness speaks about the one observation the event has.

  `failsTrace` — the same two lanes, except that the right-hand lane (region 100) ends at x = 5 m
  while the left-hand lane (region 101) runs the whole 100 m. The car runs straight along y = -2 m,
  from (-10, -2) to (0, -2) to (10, -2) m: its footprint overlaps region 100 at t = 0 and
  t = 1000 ms, and at t = 2000 ms it lies beyond x = 5 m and overlaps no region at all. Region 101
  is a travel region of the scene and is overlapped at no observation. Over the window
  t = 1000..2000 ms the first element holds at both observations (the footprint overlapped the lane
  at the previous one, at t = 2000 ms having just ceased to overlap it), no travel region other than
  it is newly overlapped, and the concept is violated: the lane simply ended ahead of the car.

  `blindTrace` is the drift of `holdsTrace`, judged with rel.occupies masked: the source declares no
  footprint occupancy for any region, so neither the earlier overlap of region 100 nor a new overlap
  of region 101 can be told, and the concept is unknown over the same window. The window starts at
  t = 1000 ms because at the first observation of a trace there is no previous observation at all:
  the witness is about the masked atom, not about the start of the recording.
-/
import TrafficSpec.Concepts.lane.begins_departure_from_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.begins_departure_from_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- The car: 4.5 m long, 1.8 m wide, 1.5 m tall. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
/-- Ten metres a second, the speed of the one car of every trace. -/
def speed : Q := Units.metresPerSecond 10

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100

/-- The instance every scenario speaks about: the concept has no literal formal and no parameter,
    so the instance fills nothing and the formals are the scenario's grounding and regions. -/
def inst : Concept.Instance :=
  { name := "drv.lane.begins_departure_from_region@w"
    concept := "drv.lane.begins_departure_from_region"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The map pieces and the car
-- ---------------------------------------------------------------------------------------------
/-- A lane designated due east, from `x0` to `x1` and from `y0` to `y1`. -/
def eastLane (id : RegionId) (x0 y0 x1 y1 : Q) : Structure :=
  Build.lane id [(x0, y0), (x1, y0), (x1, y1), (x0, y1)] Build.east

/-- The right-hand lane, the region the concept is asked about, ending at `xEnd`. -/
def rightLane (xEnd : Q) : Structure := eastLane 100 (m (-50)) (m (-4)) xEnd (m 0)
/-- The left-hand lane beside it, the whole 100 m. -/
def leftLane : Structure := eastLane 101 (m (-50)) (m 0) (m 50) (m 4)

/-- The car, eastward at 10 m/s, at the position given. -/
def car (x y : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, y) Build.east speed carExtent

-- ---------------------------------------------------------------------------------------------
-- The traces
-- ---------------------------------------------------------------------------------------------
/-- `holds` (compliant): A car travelling in the right-hand of two marked lanes overlapped that lane
    with its footprint at the previous observation and now puts its near-side corner over the lane
    line, so that at this observation its footprint also overlaps the left lane, which it did not
    overlap at the previous observation. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let (pos, occ) :=
      match k with
      | 0 => ((m (-10), m (-2)), [((1 : TrackId), (100 : RegionId))])
      | 1 => ((m 0, cm (-50)), [((1 : TrackId), (100 : RegionId)), (1, 101)])
      | _ => ((m 10, cm (-30)), [((1 : TrackId), (100 : RegionId)), (1, 101)])
    Build.scene t (some 1)
      [ car pos.1 pos.2 ]
      [ rightLane (m 50), leftLane ]
      []
      (some occ)

/-- `fails` (violated): A car travels straight along its lane and on past the point where the lane's
    boundary ends: its footprint overlapped the lane at the previous observation and overlaps it no
    longer, but no other travel region of the scene is overlapped at any observation, so its region
    simply ended ahead of it and no departure begins. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let (x, occ) :=
      match k with
      | 0 => (m (-10), [((1 : TrackId), (100 : RegionId))])
      | 1 => (m 0, [((1 : TrackId), (100 : RegionId))])
      | _ => (m 10, ([] : List (TrackId × RegionId)))
    Build.scene t (some 1)
      [ car x (m (-2)) ]
      [ rightLane (m 5), leftLane ]
      []
      (some occ)

/-- `blind` (unknown): The car drifts towards the lane line, but the source declares no footprint
    occupancy for any region, so neither the earlier overlap of its own lane nor a new overlap of
    the neighbouring lane can be told. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (window : Option (Timestamp × Timestamp)) (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant (some (1000, 1000))
  , witness "fails" failsTrace .violated (some (1000, 2000))
  , witness "blind" blindTrace (.unknown []) (some (1000, 2000)) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.lane.begins_departure_from_region
