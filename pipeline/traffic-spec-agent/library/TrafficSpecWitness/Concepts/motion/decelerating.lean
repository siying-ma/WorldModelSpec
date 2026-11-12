/-
  Witnesses for drv.motion.decelerating.

  One motor vehicle, track 1 (half-extents 2.5 m × 1 m × 0.75 m), its body pointing east and moving
  east, observed at 0, 1 and 2 s; no region, no device. The instance gives the deceleration
  tolerance 50 cm/s² and the speed tolerance 10 cm/s.
  - holds: it brakes at −2 m/s²: speed 20, 18, 16 m/s (x = 0, 19, 36 m), velocity along the heading
    positive (not backing), acceleration −2 m/s² ≤ −0.5 m/s² at every instant.
  - fails: it moves at a constant 15 m/s (x = 0, 15, 30 m) with acceleration 0 and its brake lamp
    lit: 0 is not ≤ −0.5 m/s², so the body is false.
  - blind: the holds scene, with kin.accel_longitudinal declared absent by the manifest: the
    comparison is unknown while not-backing holds, so the body is unknown.
-/
import TrafficSpec.Concepts.motion.decelerating
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.decelerating

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: deceleration tolerance 50 cm/s², speed tolerance
    10 cm/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.decelerating@w"
    concept := "drv.motion.decelerating"
    literals := []
    nats := []
    params := [("decel_tolerance", .lit (Units.micrometresPerSecondSq 500000) .metrePerSecondSq),
               ("speed_tolerance", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Track 1, body pointing east, moving east at `speed` from `x`, with longitudinal acceleration
    `accel` and brake lamp `lamp`. -/
def driving (x : Q) (speed : Q) (accel : Q) (lamp : Bool) : RoadUser :=
  Build.withSignals
    (Build.withKin (Build.user 1 [.motorVehicle] (x, m 0) Build.east speed (cm 250, m 1, cm 75))
      fun k => { k with accelLongitudinal := some accel, gear := some 1 })
    fun s => { s with brakeLamp := some lamp }

/-- Braking at 2 m/s² from 20 m/s: speed 20 − 2k, position 20k − k². -/
def braking (k : Nat) : RoadUser :=
  let i := Int.ofNat k
  driving (m (20 * i - i * i)) (Units.metresPerSecond (20 - 2 * i)) (Units.metresPerSecondSq (-2)) true

/-- `holds` (compliant): A vehicle moving forward brakes; its longitudinal acceleration is below the negative tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ braking k ]
      [ ]
      [ ]

/-- `fails` (violated): A vehicle moves forward at constant speed with its brake lamp lit. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ driving (m (15 * Int.ofNat k)) (Units.metresPerSecond 15) Q.zero true ]
      [ ]
      [ ]

/-- `blind` (unknown): The source declares kin.accel_longitudinal absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ braking k ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.accel_longitudinal"] ]

end TrafficSpecWitness.Concepts.motion.decelerating
