/-
  Witnesses for drv.lane.enters_region.

  The geometry is the same in all three scenarios. One junction, region 100, is the square
  0 ≤ x ≤ 20, 0 ≤ y ≤ 20 (kind intersection). One car, track 1, runs east along y = 10 at 10 m/s,
  half-extents 2 m × 1 m × 1 m, with three observations one second apart:
    t = 0 ms     x = −5 m   outside the junction
    t = 1000 ms  x =  5 m   inside the junction  — the entry
    t = 2000 ms  x = 15 m   inside the junction  — the stay
  Occupancy is derived from the geometry, so `rel.occupies` is observed and decided at every
  instant unless the manifest masks it.

  Each witness names the instants it speaks about, because the body is an edge (`rises`) and so is
  truncated at the first observation of any finite trace:
    holds  window [1000, 1000]: the overlap begins — the concept holds;
    fails  window [2000, 2000]: the overlap continues — the entry has already happened;
    blind  window [1000, 2000]: `rel.occupies` masked, so neither overlap is read.
  The concept has no formal parameters, so the instance carries no figure of its own.
-/
import TrafficSpec.Concepts.lane.enters_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.enters_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100 (the junction, a structure of every scene of every trace)

/-- The instance every scenario speaks about: no literal formal, no parameter, no bounds. -/
def inst : Concept.Instance :=
  { name := "drv.lane.enters_region@w"
    concept := "drv.lane.enters_region"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The junction the car enters: the square 0 ≤ x ≤ 20, 0 ≤ y ≤ 20. -/
def junction : Structure := Build.rect 100 .intersection (m 0) (m 0) (m 20) (m 20)

/-- The car at the `k`-th observation: east along y = 10 at 10 m/s, from x = −5 m. -/
def car (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle]
    (m (10 * (Int.ofNat k) - 5), m 10) Build.east (Units.metresPerSecond 10)
    (m 2, m 1, m 1) (some (m (10 * (Int.ofNat k))))

/-- The three observations: outside, inside (the entry), inside (the stay). -/
def approach : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k] [junction] []

/-- `holds` (compliant): A car's footprint does not overlap the junction region at one observation
    and overlaps it at the next: the concept holds at the second (t = 1000 ms). -/
def holdsTrace : Trace := approach

/-- `fails` (violated): At the following observation (t = 2000 ms) the car's footprint still
    overlaps the junction: the entry has already happened, so the concept is false. -/
def failsTrace : Trace := approach

/-- `blind` (unknown): `rel.occupies` is masked, so whether the footprint overlaps the junction is
    unobserved at every instant and the entry cannot be read. -/
def blindTrace : Trace := approach

def witness (name : String) (τ : Trace) (expected : Verdict)
    (from_ to_ : Timestamp) (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some (from_, to_) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant 1000 1000
  , witness "fails" failsTrace .violated 2000 2000
  , witness "blind" blindTrace (.unknown []) 1000 2000 ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.lane.enters_region
