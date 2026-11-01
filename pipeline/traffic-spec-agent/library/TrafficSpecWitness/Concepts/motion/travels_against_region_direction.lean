/-
  Witnesses for drv.motion.travels_against_region_direction.

  The map is one straight roadway, region 100: the rectangle from (0 m, −4 m) to (120 m, 4 m), a
  one-way street whose designated direction points west (−1, 0). It is the region formal `r`; the
  concept takes it as an argument, so no witness needs any other structure.

  The body is track 1, a motor vehicle 4 m long and 2 m wide (half-extents 2 m, 1 m, 0.75 m),
  driving on the centre line of that roadway (y = 0) at six metres per second, so its whole
  footprint lies inside the rectangle at every instant. Each trace is three scenes, one second
  apart, at t = 0, 1000, 2000 ms.

    holds — heading east, x = 20, 26, 32 m: the velocity is (6, 0) m/s and the designated
      direction (−1, 0), so the component along it is −6 m/s, below −0.2 m/s at all three
      instants: the car travels against the direction.
    fails — the same roadway, heading west, x = 60, 54, 48 m: the velocity is (−6, 0) m/s, the
      component along the designated direction +6 m/s, so the body is false — the car travels
      *in* the designated direction.
    blind — the same drive as `holds`, but the roadway carries no designated direction (the
      structure has no lane record) and the manifest masks `st.lane_direction`: the sign of the
      component cannot be decided, so the body is unknown. Occupancy is still observed and true,
      so the unknown is the direction's alone.

  The instance gives speed_tolerance 0.2 m/s (200 000 µm/s), the witness's own figure: a bound
  within which a sampled velocity along the direction counts as no motion, well below the six
  metres per second both moving witnesses drive at.
-/
import TrafficSpec.Concepts.motion.travels_against_region_direction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.travels_against_region_direction

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100  (the roadway, a structure of every trace below)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.travels_against_region_direction@w"
    concept := "drv.motion.travels_against_region_direction"
    literals := []
    nats := []
    params := [("speed_tolerance", .lit (Units.micrometresPerSecond 200000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The roadway, region 100, with the direction of travel designated for it: west. -/
def roadway : Structure :=
  { Build.rect 100 .roadway (m 0) (m (-4)) (m 120) (m 4) with
      lane := some { direction := some Build.west } }

/-- The same roadway as a source that declares no designated direction for it records it. -/
def roadwayNoDirection : Structure :=
  Build.rect 100 .roadway (m 0) (m (-4)) (m 120) (m 4)

/-- The car: 4 m long, 2 m wide, 1.5 m tall. -/
def halfExtent : Q × Q × Q := (m 2, m 1, cm 75)

def speed : Q := Units.metresPerSecond 6

/-- `holds` (compliant): A car drives at six metres per second up a one-way street whose roadway's designated direction points the other way, its footprint on that roadway throughout. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 + 6 * Int.ofNat k), m 0) Build.east speed halfExtent ]
      [ roadway ]
      [ ]  -- devices

/-- `fails` (violated): The same car on the same roadway driving at six metres per second in the designated direction. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (60 - 6 * Int.ofNat k), m 0) Build.west speed halfExtent ]
      [ roadway ]
      [ ]  -- devices

/-- `blind` (unknown): The car travels along the roadway but the source declares no designated direction for any region, so the sign of the component cannot be decided. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 + 6 * Int.ofNat k), m 0) Build.east speed halfExtent ]
      [ roadwayNoDirection ]
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.motion.travels_against_region_direction
