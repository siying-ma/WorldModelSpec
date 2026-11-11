/-
  Witnesses for drv.motion.reversing.

  One car, track 1, half-extents 2.25 m × 0.9 m × 0.75 m, observed at three instants 1 s apart.
  The instance sets speed_floor to 0.1 m/s.
  - holds: the car faces north and backs south out of a parking bay (a 3 m × 6 m rectangle) at
    1 m/s; its velocity is (0, −1) and its heading (0, 1), so the component along the heading is
    −1 m/s, below −0.1 m/s. Its gear is set forward to show the gear is not read.
  - fails: the car faces east and drives east along a lane at 10 m/s; the component is +10 m/s.
    Its gear is set to reverse to show the gear is not read.
  - blind: the car of `holds` beside the bay, with kin.heading declared absent by the source:
    the component cannot be formed, so the body is unknown.
-/
import TrafficSpec.Concepts.motion.reversing
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.reversing

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: speed_floor is 0.1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.reversing@w"
    concept := "drv.motion.reversing"
    literals := []
    nats := []
    params := [("speed_floor", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The parking bay, x ∈ [0, 3], y ∈ [0, 6]. -/
def bay : Structure := Build.rect 10 .parkingSpace (m 0) (m 0) (m 3) (m 6)

/-- A car facing north, rolling south at 1 m/s (velocity opposite its heading), in a forward gear. -/
def backingCar (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (cm 150, m (4 - Int.ofNat k)) Build.north (Units.metresPerSecond 1)
      carExtent)
    fun kin => { kin with velocity := some (Build.scale Build.south (Units.metresPerSecond 1))
                          gear := some 1 }

/-- `holds` (compliant): A car moves backwards out of a parking bay, its velocity opposite to its heading. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backingCar k ]
      [ bay ]
      [ ]

/-- `fails` (violated): A car drives forward along a lane. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m (10 * Int.ofNat k), cm 175) Build.east
            (Units.metresPerSecond 10) carExtent)
          fun kin => { kin with gear := some (-1) } ]
      [ Build.lane 20 [(m (-10), m 0), (m 100, m 0), (m 100, cm 350), (m (-10), cm 350)] Build.east ]
      [ ]

/-- `blind` (unknown): A car moves near a parking bay; the source declares kin.heading absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backingCar k ]
      [ bay ]
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
  , witness "blind" blindTrace (.unknown []) ["kin.heading"] ]

end TrafficSpecWitness.Concepts.motion.reversing
