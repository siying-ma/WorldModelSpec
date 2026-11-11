/-
  Witnesses for drv.motion.yawing.

  The instance sets yaw_floor to 1 deg/s. Every trace is three scenes, one second apart, of one car
  (track 1, half-extents 2.25 m × 0.9 m × 0.75 m).

  - holds: the car backs at 1 m/s in reverse gear around a curb, its nose turning east, south, west
    over the three scenes (through (0, 0), (-0.64 m, 0.64 m), (0, 1.28 m)); its yaw rate is -90 deg/s
    (a right-hand swing, consistent with the headings), well above the floor in absolute value — the
    right hand counts as well as the left.
  - fails: the car drives east at 10 m/s along a straight lane (x from -10 m to 100 m, y from -2 m to
    2 m) with a yaw rate of 0 deg/s, at or below the floor.
  - blind: the backing car of `holds`, with the source declaring kin.yaw_rate absent and the field
    unobserved.
-/
import TrafficSpec.Concepts.motion.yawing
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.yawing

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: yaw_floor of 1 deg/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.yawing@w"
    concept := "drv.motion.yawing"
    literals := []
    nats := []
    params := [("yaw_floor", .lit (Units.degrees 1) .degreePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The backing car's nose at scene `k`: east, south, west — a quarter turn to the right a second. -/
def backingHeading : Nat → Vec
  | 0 => Build.east
  | 1 => Build.south
  | _ => Build.west

/-- Its reference point at scene `k`, along the arc it backs around the curb. -/
def backingPos : Nat → Vec
  | 0 => (cm 0, cm 0)
  | 1 => (cm (-64), cm 64)
  | _ => (cm 0, cm 128)

/-- The car backing around a curb at scene `k`, its yaw rate as given. -/
def backingCar (k : Nat) (yaw : Option Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (backingPos k) (backingHeading k) (Units.metresPerSecond 1) carExtent
      (some (m (k : Int))))
    fun kin => { kin with
      velocity := some (Build.scale (backingHeading k) (Units.metresPerSecond (-1)))
      gear := some (-1)
      yawRate := yaw }

/-- `holds` (compliant): A car swings its heading while backing around a curb, its yaw rate well above the floor. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backingCar k (some (Units.degrees (-90))) ]
      [ ]
      [ ]

def straightLane : Structure :=
  Build.lane 10 [(m (-10), m (-2)), (m 100, m (-2)), (m 100, m 2), (m (-10), m 2)] Build.east

/-- `fails` (violated): A car drives along a straight lane with zero yaw rate. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 0) Build.east (Units.metresPerSecond 10) carExtent
            (some (m (10 * (k : Int)))))
          fun kin => { kin with gear := some 1, yawRate := some (Units.degrees 0) } ]
      [ straightLane ]
      [ ]

/-- `blind` (unknown): The source declares kin.yaw_rate absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backingCar k none ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.yawing
