/-
  Witnesses for drv.motion.veering_left.

  The instance sets speed_floor to 0.1 m/s and sine_tolerance to 1/10. Every trace is three scenes,
  one second apart, of one car (track 1, half-extents 2.25 m × 0.9 m × 0.75 m) on a straight
  two-lane carriageway running east: lane 100 (x from -10 m to 100 m, y from -2 m to 2 m), its
  designated direction east, and lane 101 to its left (y from 2 m to 6 m), also east.

  - holds: the car starts a lane change to the left: its velocity is (9.6 m/s, 2.8 m/s), speed
    10 m/s, its heading the same unit vector (24/25, 7/25); it passes (0, -1.5 m), (9.6 m, 1.3 m),
    (19.2 m, 4.1 m). Along lane 100's direction (east) the velocity component is 9.6 m/s > 0; the
    cross product east × v is 2.8 m/s, above 1/10 × 10 m/s = 1 m/s (sine 0.28 > 0.1).
  - fails: the car drives east at 10 m/s along lane 100 (y = 0), velocity parallel to the
    designated direction: cross product 0, not above 1 m/s.
  - blind: the veering car of `holds`, with lane 100 carrying no direction and the source declaring
    st.lane_direction absent.
-/
import TrafficSpec.Concepts.motion.veering_left
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.veering_left

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: c ↦ 100  (lane 100, a structure of every trace)

/-- The instance every scenario speaks about: speed_floor 0.1 m/s, sine_tolerance 1/10. -/
def inst : Concept.Instance :=
  { name := "drv.motion.veering_left@w"
    concept := "drv.motion.veering_left"
    literals := []
    nats := []
    params := [("speed_floor", .lit (Units.micrometresPerSecond 100000) .metrePerSecond),
               ("sine_tolerance", .lit (Units.ratio 1 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- Lane c: east-bound, with lane 101 on its left. -/
def laneC : Structure :=
  Build.lane 100 [(m (-10), m (-2)), (m 100, m (-2)), (m 100, m 2), (m (-10), m 2)] Build.east
    (left := some 101)

/-- The lane to the left of c, also east-bound. -/
def laneLeft : Structure :=
  Build.lane 101 [(m (-10), m 2), (m 100, m 2), (m 100, m 6), (m (-10), m 6)] Build.east
    (right := some 100)

/-- Lane c with its designated direction unobserved. -/
def laneCBlind : Structure :=
  { laneC with lane := laneC.lane.map fun l => { l with direction := none } }

/-- The unit vector (24/25, 7/25): about 16 degrees to the left of east. -/
def veerHeading : Vec := (Units.ratio 24 25, Units.ratio 7 25)

/-- The car veering left out of lane c at scene `k`: velocity (9.6, 2.8) m/s, speed 10 m/s. -/
def veeringCar (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (cm (960 * (k : Int)), cm (-150 + 280 * (k : Int))) veerHeading
      (Units.metresPerSecond 10) carExtent (some (m (10 * (k : Int)))))
    fun kin => { kin with gear := some 1 }

/-- `holds` (compliant): x moves along lane c with its velocity turned to the left of c's designated direction by more than the angle whose sine is sine_tolerance, as at the start of a lane change to the left. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ veeringCar k ]
      [ laneC, laneLeft ]
      [ ]

/-- `fails` (violated): x moves along lane c with its velocity parallel to c's designated direction. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 0) Build.east (Units.metresPerSecond 10)
            carExtent (some (m (10 * (k : Int)))))
          fun kin => { kin with gear := some 1 } ]
      [ laneC, laneLeft ]
      [ ]

/-- `blind` (unknown): x moves to the left across lane c, but c's designated direction is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ veeringCar k ]
      [ laneCBlind, laneLeft ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("c", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.motion.veering_left
