/-
  Witnesses for drv.lane.lane_change.

  The map, the same in every scene of every trace: a three-lane carriageway running east, each lane
  4 m wide and 200 m long, x from 0 to 200 —
    region 101, the left-hand lane,  y 8 … 12, ordinal 1, right neighbour 100;
    region 100, the middle lane,     y 4 …  8, ordinal 2, left neighbour 101, right neighbour 102;
    region 102, the right-hand lane, y 0 …  4, ordinal 3, left neighbour 100.
  The region formal `r` is the middle lane, 100.

  The body: track 1, a motor vehicle 5 m long and 2 m wide (half-extents 2.5 m × 1 m × 0.75 m),
  heading east at 20 m/s. Three observations a second apart, at t = 0, 1000 and 2000 ms; every
  scenario's window is the last observation alone, the observation at which the crossing has
  happened (the body reads the observation before, so the first instant of a trace is truncated).

  Occupancy is written out, and it is what the footprint's overlap with the lane boundaries gives:
    holds/blind: centre (10, 6) and (20, 6) — footprint y 5 … 7, the middle lane alone; then centre
      (30, 8.5) — footprint y 7.5 … 9.5, the middle lane and the left-hand lane.
    fails: centres (10, 6), (20, 6.8) — footprint y 5.8 … 7.8 — and (30, 6): the middle lane alone
      at every observation, no neighbour overlapped.
  The concept takes no formal parameter, so the instance gives no value of its own.
-/
import TrafficSpec.Concepts.lane.lane_change
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.lane_change

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100, the middle lane of every trace

/-- The instance every scenario speaks about: no literal formal, no parameter, no bounds. -/
def inst : Concept.Instance :=
  { name := "drv.lane.lane_change@w"
    concept := "drv.lane.lane_change"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The three lanes of the carriageway, in every scene of every trace. -/
def lanes : List Structure :=
  [ Build.lane 101 [(m 0, m 8), (m 200, m 8), (m 200, m 12), (m 0, m 12)] Build.east
      (right := some 100) (ordinal := some 1) (count := some 3)
  , Build.lane 100 [(m 0, m 4), (m 200, m 4), (m 200, m 8), (m 0, m 8)] Build.east
      (left := some 101) (right := some 102) (ordinal := some 2) (count := some 3)
  , Build.lane 102 [(m 0, m 0), (m 200, m 0), (m 200, m 4), (m 0, m 4)] Build.east
      (left := some 100) (ordinal := some 3) (count := some 3) ]

/-- The car at a position: 5 m by 2 m, heading east at 20 m/s. -/
def car (pos : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.east (Units.metresPerSecond 20) (cm 250, cm 100, cm 75)

/-- `holds` (compliant): A car running in the middle lane of a three-lane carriageway reaches the left-hand lane: at the observation before, its footprint overlapped the middle lane alone; at the observation it overlaps the left-hand lane as well. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let step : Vec × List (TrackId × RegionId) :=
      match k with
      | 0 => ((m 10, m 6), [(1, 100)])
      | 1 => ((m 20, m 6), [(1, 100)])
      | _ => ((m 30, cm 850), [(1, 100), (1, 101)])
    Build.scene t (some 1) [car step.1] lanes [] (some step.2)

/-- `fails` (violated): The same car drifts to the left within the middle lane and back again: its footprint overlaps the middle lane and no neighbouring lane at every observation. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let step : Vec × List (TrackId × RegionId) :=
      match k with
      | 0 => ((m 10, m 6), [(1, 100)])
      | 1 => ((m 20, cm 680), [(1, 100)])
      | _ => ((m 30, m 6), [(1, 100)])
    Build.scene t (some 1) [car step.1] lanes [] (some step.2)

/-- `blind` (unknown): The same movement with the source declaring the occupancy of regions by road users absent: whether the footprint overlapped the lane before and the neighbour now cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let step : Vec × List (TrackId × RegionId) :=
      match k with
      | 0 => ((m 10, m 6), [(1, 100)])
      | 1 => ((m 20, m 6), [(1, 100)])
      | _ => ((m 30, cm 850), [(1, 100), (1, 101)])
    Build.scene t (some 1) [car step.1] lanes [] (some step.2)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some (2000, 2000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.lane.lane_change
