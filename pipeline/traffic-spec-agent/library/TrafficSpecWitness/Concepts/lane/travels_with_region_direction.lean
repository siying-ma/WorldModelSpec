/-
  Witnesses for drv.lane.travels_with_region_direction.

  The geometry, one scene repeated at three instants one second apart (the body reads the
  observation only, so nothing varies in time):

  - Region 100 is a roadway, the rectangle from (-100 m, -6 m) to (100 m, 6 m), carrying the
    direction designated for travel: east, (1, 0) in the world frame, a unit vector already.
  - Track 1 is a motor vehicle at the origin, 4.4 m long and 1.8 m wide (half-extents
    2.2 m / 0.9 m / 0.75 m), travelling at 8 m/s: in `holds` and `blind` heading east, in `fails`
    heading west, so its velocity is (8, 0) m/s east and (-8, 0) m/s west respectively. Occupancy
    follows the geometry; the concept does not read it.

  The figures of the instance are this witness's own: cos_min = 0.9 (an angle of about 25 degrees
  either side of the designated direction still counts as travelling with it) and
  speed_floor = 0.1 m/s (a tenth of a metre per second, below which the velocity's direction is
  noise). At 8 m/s east the component along the direction is 8 m/s, above zero and above
  0.9 x 8 = 7.2 m/s, so `holds` is compliant; at 8 m/s west it is -8 m/s, below both, so `fails`
  is violated. `blind` is the `holds` scene with `st.lane_direction` declared unobserved: the
  component is then unknown while the speed still clears the floor, so the body is unknown.
-/
import TrafficSpec.Concepts.lane.travels_with_region_direction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.travels_with_region_direction

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100 (the roadway of every trace below)

/-- The instance every scenario speaks about: every parameter given a value through a `Units`
    constructor. -/
def inst : Concept.Instance :=
  { name := "drv.lane.travels_with_region_direction@w"
    concept := "drv.lane.travels_with_region_direction"
    literals := []
    nats := []
    params :=
      [ ("cos_min", .lit (Units.ratio 9 10) .ratio)
      , ("speed_floor", .lit (Units.micrometresPerSecond 100000) .metrePerSecond) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The roadway, region 100, with the direction it designates for travel: east. -/
def roadway : Structure :=
  { Build.rect 100 .roadway (m (-100)) (m (-6)) (m 100) (m 6) with
      lane := some { direction := some Build.east } }

/-- The car, 4.4 m by 1.8 m, at the origin, at 8 m/s on the given heading. -/
def car (heading : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m 0) heading (Units.metresPerSecond 8)
    (Units.centimetres 220, Units.centimetres 90, Units.centimetres 75)

/-- `holds` (compliant): A car travels east at 8 m/s on a roadway whose designated direction points east. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ car Build.east ] [ roadway ] [ ]

/-- `fails` (violated): A car travels west at 8 m/s on the same roadway, its velocity opposed to the designated direction. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ car Build.west ] [ roadway ] [ ]

/-- `blind` (unknown): A car travels at 8 m/s on a roadway for which the source declares the designated direction absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ car Build.east ] [ roadway ] [ ]

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

end TrafficSpecWitness.Concepts.lane.travels_with_region_direction
