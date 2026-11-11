/-
  Witnesses for drv.motion.against_carrier_direction.

  One car, track 1, half-extents 2.25 m × 0.9 m × 0.75 m, observed at three instants 1 s apart, on a
  one-way roadway (region 100, x ∈ [−50, 100], y ∈ [0, 7]) whose designated direction is east.
  The instance sets speed_floor to 0.1 m/s and opposed_cosine to 1/2 (against: wider than 120°).
  - holds: the car faces west and drives west at 10 m/s along the roadway's middle (y = 3.5 m),
    from x = 50 m; its velocity is (−10, 0), the component along the direction is −10 m/s, below
    −(1/2 · 10) = −5 m/s, and it is moving.
  - fails: the car faces east and drives east at 10 m/s from x = 0; the component is +10 m/s.
  - blind: the car of `holds` on the same roadway, with st.lane_direction declared absent by the
    source: the car is moving, but the component cannot be formed, so the body is unknown.
-/
import TrafficSpec.Concepts.motion.against_carrier_direction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.against_carrier_direction

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: r ↦ 100  (the one-way roadway, a structure of every trace)

/-- The instance every scenario speaks about: speed_floor is 0.1 m/s, opposed_cosine is 1/2. -/
def inst : Concept.Instance :=
  { name := "drv.motion.against_carrier_direction@w"
    concept := "drv.motion.against_carrier_direction"
    literals := []
    nats := []
    params := [("speed_floor", .lit (Units.micrometresPerSecond 100000) .metrePerSecond),
               ("opposed_cosine", .lit (Units.ratio 1 2) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The one-way roadway, x ∈ [−50, 100], y ∈ [0, 7], designated direction east. -/
def roadway : Structure :=
  { Build.rect 100 .oneWayRoadway (m (-50)) (m 0) (m 100) (m 7) with
    lane := some { direction := some Build.east } }

/-- A car driving west at 10 m/s along the roadway's middle, against its direction. -/
def wrongWayCar (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (50 - 10 * Int.ofNat k), cm 350) Build.west
    (Units.metresPerSecond 10) carExtent

/-- `holds` (compliant): A car drives along a one-way roadway opposite to its designated direction. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ wrongWayCar k ]
      [ roadway ]
      [ ]

/-- `fails` (violated): A car drives along the same roadway in its designated direction. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (10 * Int.ofNat k), cm 350) Build.east
          (Units.metresPerSecond 10) carExtent ]
      [ roadway ]
      [ ]

/-- `blind` (unknown): A car drives along a roadway; the source declares st.lane_direction absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ wrongWayCar k ]
      [ roadway ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("r", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.motion.against_carrier_direction
