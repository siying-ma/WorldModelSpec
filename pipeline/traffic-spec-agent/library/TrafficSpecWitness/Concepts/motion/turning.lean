/-
  Witnesses for drv.motion.turning.

  One body, track 1, at the origin of an empty world: no region and no device is read, because the
  concept reads the body's own yaw alone. Each trace is a single instant (t = 0): the concept is
  read at the observation itself, and across several instants an observed heading would have to be
  the exact rotation the observed yaw rate produces over the interval, which no rational unit
  vector is for 7 deg/s.

  The instance's own figure: a tolerance of 1 deg/s, the magnitude below which a rate of turn is
  taken for sensor noise or the jitter of holding a straight course.

    holds — a van reversing round a corner, yaw rate 7 deg/s (above 1 deg/s): the body is turning.
    fails — a car running straight, yaw rate 0.2 deg/s (below 1 deg/s): the heading is steady.
    blind — the same body with kin.yaw_rate unobserved (the field is `none` and the manifest
            declares the atom absent), so whether the heading changes cannot be read.
-/
import TrafficSpec.Concepts.motion.turning
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turning

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turning@w"
    concept := "drv.motion.turning"
    literals := []
    nats := []
    params := [("yaw_rate_tolerance", .lit (Units.degrees 1) .degreePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The body of the witnesses: a vehicle 5 m long and 2 m wide at the origin, heading east at
    2 m/s; `f` supplies what this scenario observes of its yaw. -/
def body (f : Kin → Kin) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (Units.metresPerSecond 2)
      (Units.centimetres 250, Units.centimetres 100, Units.centimetres 100))
    f

/-- `holds` (compliant): A van reversing round a corner has a yaw rate of 7 deg/s, above the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ body fun k => { k with yawRate := some (Units.degrees 7) } ]
      [ ]  -- no structure is read
      [ ]  -- devices

/-- `fails` (violated): A car running straight has a yaw rate of 0.2 deg/s, below the tolerance. -/
def failsTrace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ body fun k => { k with yawRate := some (Units.millidegrees 200) } ]
      [ ]  -- no structure is read
      [ ]  -- devices

/-- `blind` (unknown): The source declares kin.yaw_rate absent for the road user, so whether its heading is changing cannot be read. -/
def blindTrace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ body id ]  -- the yaw rate is unobserved
      [ ]  -- no structure is read
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
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.turning
