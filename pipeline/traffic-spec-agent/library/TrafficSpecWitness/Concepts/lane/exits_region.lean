/-
  Witnesses for drv.lane.exits_region.

  One body, track 1, a car 5 m long and 2 m wide (half-extents 2.5 m, 1 m, 0.75 m), on a
  two-lane one-way carriageway running east: region 100, the right lane, is the strip
  0 m ≤ y ≤ 3.5 m, and region 101, the left lane beside it, the strip 3.5 m ≤ y ≤ 7 m, both
  reaching from x = −50 m to x = 50 m and both directed east. The formal region `r` is the right
  lane, region 100; the left lane is built only so that the car has somewhere to be when it is no
  longer in the right lane — the concept reads occupancy of `r` alone, so no device and no other
  structure is built.

  Each trace is three instants one second apart (t = 0, 1000, 2000 ms). Occupancy is derived from
  the geometry: a body at y = 1.75 m lies with its whole 2 m width inside the right lane
  (0.75 m … 2.75 m), a body at y = 5.25 m with its whole width inside the left lane
  (4.25 m … 6.25 m) and clear of the right.

  The concept reads the previous observation, so the first instant of a trace has nothing to
  compare with: every scenario's `window` starts at t = 1000 ms, the first instant that has a
  predecessor inside the trace.

  The instance has no literal formal and no parameter: no figure of the witness's own enters it.

    holds — the car's footprint overlaps the right lane at t = 0 (at (0, 1.75)) and, at t = 1000,
            lies wholly within the left lane at (10, 5.25) and no longer overlaps the right: the
            window is the single instant t = 1000, at which it is read as leaving the right lane.
    fails — the same car is at (0, 5.25), (10, 5.25) and (20, 5.25): wholly in the left lane
            throughout, overlapping the right lane at neither t = 1000 nor its predecessor and
            neither at t = 2000 nor its predecessor, so no leaving is read at either instant of
            the window.
    blind — the geometry of `holds`, but the source does not observe region occupancy for the car:
            the manifest declares rel.occupies absent, so the overlap is unknown at t = 1000 and
            at its predecessor and whether the car left the right lane is unknown.
-/
import TrafficSpec.Concepts.lane.exits_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.exits_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100  (the right lane, a structure of every trace)

/-- The instance every scenario speaks about: the concept has no literal formal, no nat formal and
    no formal parameter, and it is a formula, so it needs no bounds. -/
def inst : Concept.Instance :=
  { name := "drv.lane.exits_region@w"
    concept := "drv.lane.exits_region"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The right lane, region 100: the strip 0 m ≤ y ≤ 3.5 m from x = −50 m to x = 50 m, directed
    east, with the left lane on its left. -/
def rightLane : Structure :=
  Build.lane 100
    [ (m (-50), m 0), (m 50, m 0), (m 50, cm 350), (m (-50), cm 350) ]
    Build.east (left := some 101)

/-- The left lane, region 101: the strip 3.5 m ≤ y ≤ 7 m beside it, directed east. -/
def leftLane : Structure :=
  Build.lane 101
    [ (m (-50), cm 350), (m 50, cm 350), (m 50, m 7), (m (-50), m 7) ]
    Build.east (right := some 100)

/-- The car at an instant: 5 m long, 2 m wide, facing east at the position given, travelling at
    10 m/s. -/
def car (pos : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.east (m 10) (cm 250, m 1, cm 75)

/-- Three instants a second apart, the car at the position given, the two lanes beside each other;
    occupancy is derived from the geometry. -/
def laneTrace (pos : Nat → Vec) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (pos k) ]
      [ rightLane, leftLane ]
      [ ]  -- devices

/-- Leaving: in the right lane at the first instant, wholly in the left lane afterwards. -/
def leavingPos (k : Nat) : Vec :=
  (m (10 * Int.ofNat k), if k = 0 then cm 175 else cm 525)

/-- Never in the right lane: wholly in the left lane at every instant. -/
def leftLanePos (k : Nat) : Vec := (m (10 * Int.ofNat k), cm 525)

/-- `holds` (compliant): A car's footprint overlaps the right lane at one observation and, at the next, lies wholly within the left lane and no longer overlaps the right: at that observation it is read as leaving the right lane. -/
def holdsTrace : Trace := laneTrace leavingPos

/-- `fails` (violated): The same car has been wholly in the left lane for several observations, its footprint overlapping the right lane at neither this observation nor the previous one: no leaving is read. -/
def failsTrace : Trace := laneTrace leftLanePos

/-- `blind` (unknown): The car moves across the lane line but the source does not observe region occupancy for it: rel.occupies is absent at this observation and the previous one, so whether it left the lane is unknown. -/
def blindTrace : Trace := laneTrace leavingPos

def witness (name : String) (τ : Trace) (expected : Verdict)
    (window : Option (Timestamp × Timestamp) := none)
    (absent : List String := []) : Scenario :=
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

end TrafficSpecWitness.Concepts.lane.exits_region
