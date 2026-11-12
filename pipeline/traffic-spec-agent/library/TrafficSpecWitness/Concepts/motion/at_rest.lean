/-
  Witnesses for drv.motion.at_rest.

  One passenger car, track 1, half-extent 2.25 m × 0.9 m × 0.75 m, at (0, 0) heading east, over three
  instants one second apart (t = 0, 1000, 2000 ms). No structures, no devices.
  The instance sets the speed tolerance to 0.1 m/s.
  - holds: the car's speed reads 0 m/s at every instant.
  - fails: the car's speed reads 10 m/s at every instant while its brake lamp is lit.
  - blind: the car is the stationary one of `holds`, but the source declares kin.speed absent.
-/
import TrafficSpec.Concepts.motion.at_rest
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.at_rest

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the speed tolerance 0.1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.at_rest@w"
    concept := "drv.motion.at_rest"
    literals := []
    nats := []
    params := [("speed_tolerance", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car of every scene, at speed `v`. -/
def car (v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m 0) Build.east v (cm 225, cm 90, cm 75)

/-- `holds` (compliant): A vehicle's kin.speed reads zero at the observation. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (Units.metresPerSecond 0) ]
      [ ]
      [ ]

/-- `fails` (violated): A vehicle's kin.speed is well above the speed tolerance while its brake lamp is lit. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withSignals (car (Units.metresPerSecond 10)) fun s => { s with brakeLamp := some true } ]
      [ ]
      [ ]

/-- `blind` (unknown): The source declares kin.speed absent. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.speed"]) holdsTrace

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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.at_rest
