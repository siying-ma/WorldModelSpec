/-
  Witnesses for drv.lane.exits_region.

  The map, the same in every scene of every trace: two lanes of one laned roadway, both running
  east (+x), each 3 m wide and 200 m long. Region 100 is the right lane (y ∈ [0, 3]), region 101
  the centre lane (y ∈ [3, 6]) immediately to its left; 100 is the second lane from the left of
  two, 101 the first. The region formal `r` is the right lane, 100.

  The body, track 1: a car (class motor_vehicle) heading east at 20 m/s, half-extents 2 m long,
  0.90 m wide, 0.75 m high, so its footprint is a 4 m × 1.8 m rectangle centred on its position.
  Every trace has three observations a quarter of a second apart (t = 0, 250, 500 ms), the car
  advancing 5 m along x between them from x = 10 m.

  Occupancy is not written here: the admission derives it from the footprint and the lane
  boundaries as closed sets, so the lateral placement of the car is what decides every reading.

  - `holds`: y = 2.80 m at t = 0 (footprint y ∈ [1.90, 3.70]: both lanes, the right lane among
    them), y = 3.95 m at t = 250 (footprint y ∈ [3.05, 4.85]: the centre lane only), y = 4.50 m at
    t = 500. The right lane is left at t = 250, and the witness speaks of that observation alone
    (`window`): the concept is an event, false at t = 0 (the car still overlaps the right lane)
    and at t = 500 (it no longer overlapped it at the previous observation either).
  - `fails`: y = 2.80, 2.90, 3.00 m (footprints y ∈ [1.90, 3.70], [2.00, 3.80], [2.10, 3.90]): the
    car straddles the two lanes throughout, never ceasing to overlap the right lane, so the body
    is false at every observation of the trace.
  - `blind`: the geometry of `holds`, with `rel.occupies` absent from the manifest. The witness
    speaks of t ∈ [250, 500], the observations whose previous observation the trace holds: there
    the body is unknown for the masked overlap alone, and not for a past the trace lacks.

  There are no formal parameters, so the instance gives no magnitude of its own.
-/
import TrafficSpec.Concepts.lane.exits_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.exits_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100 (the right lane, a structure of every scene of every trace)

/-- The instance every scenario speaks about: no literal formal, no parameter, a formula body. -/
def inst : Concept.Instance :=
  { name := "drv.lane.exits_region@w"
    concept := "drv.lane.exits_region"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The right lane, y ∈ [0, 3] m: the region the formal `r` is bound to. -/
def rightLane : TrafficSpec.Structure :=
  Build.lane 100 [(m 0, m 0), (m 200, m 0), (m 200, m 3), (m 0, m 3)] Build.east
    (left := some 101) (ordinal := some 2) (count := some 2)

/-- The centre lane, y ∈ [3, 6] m, immediately left of the right lane. -/
def centreLane : TrafficSpec.Structure :=
  Build.lane 101 [(m 0, m 3), (m 200, m 3), (m 200, m 6), (m 0, m 6)] Build.east
    (right := some 100) (ordinal := some 1) (count := some 2)

def lanes : List TrafficSpec.Structure := [rightLane, centreLane]

/-- The car at the `k`-th observation, at the lateral offset the scenario gives it. -/
def car (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (10 + 5 * (Int.ofNat k)), y) Build.east (m 20) (m 2, cm 90, cm 75)

/-- A scene of the common map, with the car at one lateral offset. -/
def sceneAt (k : Nat) (t : Timestamp) (y : Q) : Scene :=
  Build.scene t (some 1) [car k y] lanes []

/-- The lateral offsets of the leaving: the right lane overlapped, then not. -/
def leavingY : Nat → Q
  | 0 => cm 280
  | 1 => cm 395
  | _ => cm 450

/-- The lateral offsets of the straddle: the right lane overlapped throughout. -/
def straddlingY : Nat → Q
  | 0 => cm 280
  | 1 => cm 290
  | _ => cm 300

/-- `holds` (compliant): A car's footprint overlaps the right lane at one observation and, a quarter of a second later, overlaps only the centre lane: it has left the right lane. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 250) fun k t => sceneAt k t (leavingY k)

/-- `fails` (violated): A car's footprint straddles the right lane and the centre lane at both observations, still overlapping the right lane: it has not left it. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 250) fun k t => sceneAt k t (straddlingY k)

/-- `blind` (unknown): A car travels on a laned roadway whose source declares region occupancy absent, so whether it overlapped the lane cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 250) fun k t => sceneAt k t (leavingY k)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
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
  [ witness "holds" holdsTrace .compliant [] (some (250, 250))
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] (some (250, 500)) ]

end TrafficSpecWitness.Concepts.lane.exits_region
