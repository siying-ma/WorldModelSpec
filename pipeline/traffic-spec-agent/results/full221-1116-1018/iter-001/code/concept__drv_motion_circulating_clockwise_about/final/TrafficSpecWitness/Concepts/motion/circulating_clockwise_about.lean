/-
  Witnesses for drv.motion.circulating_clockwise_about.

  Geometry (world frame, +x east, +y north): region 100 is a roundabout whose reference point is the
  origin (0, 0). Car 1 (half-extents 2 m × 1 m × 75 cm) moves at 5 m/s on a circle of radius 10 m
  about it, one quarter turn per second, three instants at t = 0, 1, 2 s.
  - holds: (0, 10) heading east → (10, 0) heading south → (0, −10) heading west. At each instant
    d × v = −50 m²/s (clockwise), (d × v)² = 2500 > (1/2)²·100·25 = 625, speed 5 > 1 m/s.
  - fails: (0, 10) heading west → (−10, 0) heading south → (0, −10) heading east: d × v = +50,
    counter-clockwise, the point on the car's left; the body is false at every instant.
  - blind: the holds motion, the region mapped without its reference point and boundary, and the
    manifest declaring st.region_geometry absent; position, velocity and speed are observed.
  Instance: speed_tol = 1 m/s, sin_tol = 1/2.
-/
import TrafficSpec.Concepts.motion.circulating_clockwise_about
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.circulating_clockwise_about

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100  (a structure of every trace)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.motion.circulating_clockwise_about@w"
    concept := "drv.motion.circulating_clockwise_about"
    literals := []
    nats := []
    params := [("speed_tol", .lit (Units.metresPerSecond 1) .metrePerSecond),
               ("sin_tol", .lit (Units.ratio 1 2) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- The roundabout with its reference point at the origin. -/
def hub : Structure := Build.point 100 .roundabout (m 0, m 0)

/-- The same roundabout mapped without reference point or boundary. -/
def hubBlind : Structure := { id := 100, kind := .roundabout }

/-- Car 1 on the radius-10 m circle, clockwise. -/
def clockwiseCar (k : Nat) : RoadUser :=
  match k with
  | 0 => Build.user 1 [.motorVehicle] (m 0, m 10) Build.east (Units.metresPerSecond 5) carExtent
  | 1 => Build.user 1 [.motorVehicle] (m 10, m 0) Build.south (Units.metresPerSecond 5) carExtent
  | _ => Build.user 1 [.motorVehicle] (m 0, m (-10)) Build.west (Units.metresPerSecond 5) carExtent

/-- Car 1 on the radius-10 m circle, counter-clockwise. -/
def counterClockwiseCar (k : Nat) : RoadUser :=
  match k with
  | 0 => Build.user 1 [.motorVehicle] (m 0, m 10) Build.west (Units.metresPerSecond 5) carExtent
  | 1 => Build.user 1 [.motorVehicle] (m (-10), m 0) Build.south (Units.metresPerSecond 5) carExtent
  | _ => Build.user 1 [.motorVehicle] (m 0, m (-10)) Build.east (Units.metresPerSecond 5) carExtent

/-- `holds` (compliant): A car moves around the reference point of the region keeping the point on its right, its velocity mostly across the line to the point. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ clockwiseCar k ]
      [ hub ]
      [ ]

/-- `fails` (violated): A car moves around the reference point keeping the point on its left (counter-clockwise). -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ counterClockwiseCar k ]
      [ hub ]
      [ ]

/-- `blind` (unknown): The region is mapped without its reference point and boundary. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ clockwiseCar k ]
      [ hubBlind ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    regions := [("r", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"] ]

end TrafficSpecWitness.Concepts.motion.circulating_clockwise_about
