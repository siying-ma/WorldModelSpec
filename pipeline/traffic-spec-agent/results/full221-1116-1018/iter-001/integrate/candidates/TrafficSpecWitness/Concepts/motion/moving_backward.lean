/-
  Witnesses for drv.motion.moving_backward.

  One car, track 1 (a ↦ 1), half-extent 2.3 m × 0.9 m × 0.75 m, heading east (1, 0) throughout, no
  structures, no devices. Three scenes at t = 0, 1000, 2000 ms (dt = 1 s).
  - holds: velocity (-1.5, 0) m/s (speed 1.5 m/s); the car starts at (20, 0) and its position moves
    1.5 m west per second. Component along the heading: -1.5 m/s < -0.1 m/s.
  - fails: velocity (2.0, 0.1) m/s; the car starts at (0, 0) and moves 2 m east, 0.1 m north per
    second. Component along the heading: +2.0 m/s, not below -0.1 m/s.
  - blind: as `holds`, but the velocity field is none at every scene and `kin.velocity` is masked;
    the heading is known, so only the velocity leaves the comparison undecided.
  The instance gives speed_tol = 0.1 m/s (100000 µm/s), the witness's own figure.
-/
import TrafficSpec.Concepts.motion.moving_backward
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.moving_backward

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: speed_tol = 0.1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.moving_backward@w"
    concept := "drv.motion.moving_backward"
    literals := []
    nats := []
    params := [("speed_tol", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def halfExtent : Q × Q × Q := (cm 230, cm 90, cm 75)

/-- The car backing: heading east, velocity (-1.5, 0) m/s, position moving west. -/
def backingCar (k : Nat) : RoadUser :=
  let x := Q.sub (m 20) (Q.mul (Units.micrometresPerSecond 1500000) (Q.ofInt k))
  Build.withKin (Build.user 1 [.motorVehicle] (x, m 0) Build.east (Units.micrometresPerSecond 1500000) halfExtent)
    fun kn => { kn with velocity := some (Units.micrometresPerSecond (-1500000), Units.metresPerSecond 0) }

/-- `holds` (compliant): A car with heading (1, 0) moves with velocity (-1.5, 0) m/s: the component along its heading is -1.5 m/s, below minus speed_tol; the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backingCar k ]
      [ ]
      [ ]

/-- `fails` (violated): The same car moves with velocity (2.0, 0.1) m/s: the component along its heading is positive; it is moving forward and the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pos : Vec := (Q.mul (m 2) (Q.ofInt k), Q.mul (Units.micrometresPerSecond 100000) (Q.ofInt k))
    Build.scene t (some 1)
      [ Build.withKin (Build.user 1 [.motorVehicle] pos Build.east (Units.metresPerSecond 2) halfExtent)
          fun kn => { kn with velocity := some (Units.metresPerSecond 2, Units.micrometresPerSecond 100000) } ]
      [ ]
      [ ]

/-- `blind` (unknown): The car's heading is known but the source supplies no velocity at the observation; whether it moves backward is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (backingCar k) fun kn => { kn with velocity := none } ]
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.moving_backward
