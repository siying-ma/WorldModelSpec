/-
  Witnesses for drv.motion.veering_right.

  Geometry: lane c (region 100) a rectangle from (−20, −20) to (100, 4) m, designated direction
  east (+x). One road user x (track 1), a motor vehicle heading east, half-length 2 m, half-width
  1 m, half-height 1 m. Three instants, 1 s apart (k = 0, 1, 2).

  - holds: x heads east but its velocity is (8, −6) m/s, speed 10 m/s, centre at (8k, 2 − 6k) m:
    the velocity points to the right of the lane's direction, as at the start of a turn into a
    side street on the right. Along the direction 8 > 0; cross product 1·(−6) − 0·8 = −6 m/s,
    below −(1/10)·10 = −1 m/s (sine −3/5 < −1/10). Moving: 10 > 1 m/s.
  - fails: x heads east with velocity (10, 0) m/s, speed 10 m/s, centre at (10k, 0) m: parallel to
    the lane's direction; cross product 0, not below −1 m/s.
  - blind: the holds motion, with lane c's designated direction not observed (the lane carries no
    direction): the component along it and the cross product are unknown while x is moving.

  Instance: speed_floor = 1 m/s, sine_tolerance = 1/10 (ratio).
-/
import TrafficSpec.Concepts.motion.veering_right
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.veering_right

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: c ↦ 100

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.veering_right@w"
    concept := "drv.motion.veering_right"
    literals := []
    nats := []
    params := [("speed_floor", .lit (Units.metresPerSecond 1) .metrePerSecond),
               ("sine_tolerance", .lit (Units.ratio 1 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def body : Q × Q × Q := (m 2, m 1, m 1)

/-- Lane c: east-bound. -/
def laneC : Structure :=
  Build.lane 100 [(m (-20), m (-20)), (m 100, m (-20)), (m 100, m 4), (m (-20), m 4)] Build.east

/-- Lane c with no designated direction observed. -/
def laneCBlind : Structure :=
  { laneC with lane := laneC.lane.map fun l => { l with direction := none } }

/-- x heading east, moving with velocity (8, −6) m/s (speed 10 m/s). -/
def veeringUser (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m (8 * (k : Int)), m (2 - 6 * (k : Int))) Build.east
      (Units.metresPerSecond 10) body)
    fun kn => { kn with velocity := some (Units.metresPerSecond 8, Units.metresPerSecond (-6)) }

/-- `holds` (compliant): x moves along lane c with its velocity turned to the right of c's designated direction by more than the angle whose sine is sine_tolerance, as at the start of a turn into a side street on the right. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ veeringUser k ]
      [ laneC ]
      [ ]

/-- `fails` (violated): x moves along lane c with its velocity parallel to c's designated direction. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 0) Build.east (Units.metresPerSecond 10) body ]
      [ laneC ]
      [ ]

/-- `blind` (unknown): x moves to the right across lane c, but c's designated direction is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ veeringUser k ]
      [ laneCBlind ]
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

end TrafficSpecWitness.Concepts.motion.veering_right
