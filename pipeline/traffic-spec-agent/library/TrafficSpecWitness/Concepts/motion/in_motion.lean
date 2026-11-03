/-
  Witnesses for drv.motion.in_motion.

  The geometry, and every figure in it, is this file's own.

  The instance passes speed_floor = 0.1 m/s (100000 µm/s): a resolution for a halted body, below
  which a reading is noise about rest.

  `holds`: one car, track 1, a 4 m long and 2 m wide body at the origin heading east, measured
  speed 4 m/s at each of the three observations (t = 0, 1, 2 s) — above the floor, so the body holds
  throughout and the scenario is compliant.

  `fails`: the same car, track 1, standing at x = −5 m heading east with a measured speed of
  0.02 m/s (20000 µm/s) at each observation — below the floor, so the body is false and the
  scenario is violated.

  `blind`: two cars — track 2, the subject, at the origin, and track 1, another car 20 m east of it,
  both with a measured speed of 4 m/s in the scene. The manifest declares `kin.speed` absent, which
  is the source not reporting the speed, and the concept is read for track 1; with the speed
  unobserved the comparison is unknown. The masked atom is the one that decides: with it observed
  the scenario would be compliant.
-/
import TrafficSpec.Concepts.motion.in_motion
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.in_motion

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A speed in micrometres per second, so that 0.02 m/s is exact. -/
def mps (n : Int) : Q := Units.micrometresPerSecond n

/-- Half-length, half-width, half-height of a passenger car: 4 m × 2 m × 1.5 m. -/
def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.in_motion@w"
    concept := "drv.motion.in_motion"
    literals := []
    nats := []
    params := [("speed_floor", .lit (mps 100000) .metrePerSecond)]  -- 0.1 m/s
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car crossing a junction has a measured speed of 4 m/s at the observation, well above the resolution floor the caller passes, so the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (mps 4000000) carExtent ]
      [ ]  -- structures: the concept reads no region
      [ ]  -- devices

/-- `fails` (violated): The same car waiting at a line has a measured speed of 0.02 m/s at the observation, below the floor, so the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (-5), m 0) Build.east (mps 20000) carExtent ]
      [ ]  -- structures: the concept reads no region
      [ ]  -- devices

/-- `blind` (unknown): The source declares speed absent for road users other than the subject, and the concept is read for another car, so whether it is moving is unobserved. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 2)
      [ Build.user 2 [.motorVehicle] (m 0, m 0) Build.east (mps 4000000) carExtent
      , Build.user 1 [.motorVehicle] (m 20, m 0) Build.east (mps 4000000) carExtent ]
      [ ]  -- structures: the concept reads no region
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.in_motion
