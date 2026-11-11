/-
  Witnesses for drv.motion.clockwise_about_region.

  A roundabout, region 100: an octagon of radius 30 m about its reference point (0, 0). One car,
  track 1, half-extents 2.25 m × 0.9 m × 0.75 m, at 8 m/s on the circulatory roadway 20 m from the
  reference point, observed at three instants 2 s apart, its heading (hence velocity) tangential.
  The instance sets speed_floor to 0.1 m/s and sine_tolerance to 1/10.
  - holds: the car passes (0, 20) heading east, (20, 0) heading south, (0, −20) heading west:
    clockwise; at each the cross product of radius and velocity is −160 m²/s, and its square
    25600 exceeds (1/10)²·400·64 = 256.
  - fails: the car passes (0, 20) heading west, (−20, 0) heading south, (0, −20) heading east:
    counter-clockwise; the cross product is +160, not negative.
  - blind: the car of `holds`, with kin.velocity declared absent by the source: the cross product
    cannot be formed, so the body is unknown (kin.speed still decides that the car is moving).
-/
import TrafficSpec.Concepts.motion.clockwise_about_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.clockwise_about_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: r ↦ 100

/-- The instance every scenario speaks about: speed_floor is 0.1 m/s, sine_tolerance 1/10. -/
def inst : Concept.Instance :=
  { name := "drv.motion.clockwise_about_region@w"
    concept := "drv.motion.clockwise_about_region"
    literals := []
    nats := []
    params := [("speed_floor", .lit (Units.micrometresPerSecond 100000) .metrePerSecond),
               ("sine_tolerance", .lit (Units.ratio 1 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The roundabout: an octagon of radius 30 m about its reference point (0, 0). -/
def roundabout : Structure :=
  { Build.region 100 .roundabout
      [(m 30, m 0), (m 21, m 21), (m 0, m 30), (m (-21), m 21),
       (m (-30), m 0), (m (-21), m (-21)), (m 0, m (-30)), (m 21, m (-21))]
    with position := some (m 0, m 0) }

/-- The clockwise car at its k-th instant: on the radius-20 m circle, heading tangentially clockwise. -/
def clockwiseCar (k : Nat) : RoadUser :=
  let (pos, h) : Vec × Vec := match k with
    | 0 => ((m 0, m 20), Build.east)
    | 1 => ((m 20, m 0), Build.south)
    | _ => ((m 0, m (-20)), Build.west)
  Build.user 1 [.motorVehicle] pos h (Units.metresPerSecond 8) carExtent

/-- The counter-clockwise car at its k-th instant. -/
def counterCar (k : Nat) : RoadUser :=
  let (pos, h) : Vec × Vec := match k with
    | 0 => ((m 0, m 20), Build.west)
    | 1 => ((m (-20), m 0), Build.south)
    | _ => ((m 0, m (-20)), Build.east)
  Build.user 1 [.motorVehicle] pos h (Units.metresPerSecond 8) carExtent

/-- `holds` (compliant): A car on the circulatory roadway drives around the central island clockwise, its velocity tangential to the radius from the roundabout's reference point. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 2) fun k t =>
    Build.scene t (some 1)
      [ clockwiseCar k ]
      [ roundabout ]
      [ ]

/-- `fails` (violated): A car on the circulatory roadway drives around the central island counter-clockwise. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 2) fun k t =>
    Build.scene t (some 1)
      [ counterCar k ]
      [ roundabout ]
      [ ]

/-- `blind` (unknown): A car moves on the circulatory roadway; the source declares kin.velocity absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 2) fun k t =>
    Build.scene t (some 1)
      [ clockwiseCar k ]
      [ roundabout ]
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.clockwise_about_region
