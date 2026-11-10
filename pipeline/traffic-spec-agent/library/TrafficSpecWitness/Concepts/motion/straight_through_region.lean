/-
  Witnesses for drv.motion.straight_through_region.

  Geometry. Region 100 is an intersection, the rectangle x ∈ [0, 20] m, y ∈ [-10, 10] m. Car 1
  (half-extents 2 m × 1 m × 1 m) is observed at four instants, t = 0, 1, 2, 3 s, occupancy derived
  from its position. At t = 0 it is outside, west of the intersection; at t = 1 s it is inside (the
  entry, where the overlap rises); at t = 2 s still inside; at t = 3 s outside again (the exit).
  Each scenario is judged over the window [3000, 3000] ms: the exit observation, the only one at
  which the concept can hold.

  - holds: heading east at 10 m/s throughout, x = -5, 5, 15, 25 m on y = 0, yaw rate 0 deg/s; the
    heading change since entry is 0°, below `max_angle`.
  - fails: enters heading east at (-5, 0) → (5, 0), then turns right: (11, -6) and (11, -16)
    heading south, leaving across the south edge; the yaw rate (held over the interval before the
    scene that carries it) is -90 deg/s at t = 2 s and 0 elsewhere, so the heading change since
    entry is -90°, beyond `max_angle`.
  - blind: as holds, with kin.yaw_rate declared absent: the exit is decided, the heading change
    since entry is not.

  Instance figures (the witness's own): `step` = 2 s (the sampling interval is 1 s), `max_angle` =
  30°.
-/
import TrafficSpec.Concepts.motion.straight_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.straight_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: i ↦ 100 (the intersection, in every trace)

/-- The instance every scenario speaks about: every parameter given a value through a `Units`
    constructor. -/
def inst : Concept.Instance :=
  { name := "drv.motion.straight_through_region@w"
    concept := "drv.motion.straight_through_region"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 2) .second), ("max_angle", .lit (Units.degrees 30) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The intersection the car passes. -/
def intersection : Structure := Build.rect 100 .intersection (m 0) (m (-10)) (m 20) (m 10)

def half : Q × Q × Q := (m 2, m 1, m 1)

/-- The car of `holds` and `blind`: straight east through the intersection, yaw rate zero. -/
def straightCar (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m (-5 + 10 * (k : Int)), m 0) Build.east (Units.metresPerSecond 10) half)
    fun kin => { kin with yawRate := some (Units.degrees 0) }

/-- The car of `fails`: enters heading east, turns right and leaves heading south. -/
def turningCar (k : Nat) : RoadUser :=
  let (pos, hdg, yaw) : Vec × Vec × Q :=
    match k with
    | 0 => ((m (-5), m 0), Build.east, Units.degrees 0)
    | 1 => ((m 5, m 0), Build.east, Units.degrees 0)
    | 2 => ((m 11, m (-6)), Build.south, Units.degrees (-90))
    | _ => ((m 11, m (-16)), Build.south, Units.degrees 0)
  Build.withKin (Build.user 1 [.motorVehicle] pos hdg (Units.metresPerSecond 10) half)
    fun kin => { kin with yawRate := some yaw }

/-- `holds` (compliant): A car enters an intersection and leaves it on the far side heading as it entered. -/
def holdsTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ straightCar k ]
      [ intersection ]
      [ ]

/-- `fails` (violated): A car enters an intersection, turns right and leaves it. -/
def failsTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar k ]
      [ intersection ]
      [ ]

/-- `blind` (unknown): As holds, with kin.yaw_rate declared absent. -/
def blindTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ straightCar k ]
      [ intersection ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("i", 100)]
    expected := expected
    window := some (3000, 3000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.straight_through_region
