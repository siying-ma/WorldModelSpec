/-
  Witnesses for drv.interaction.overtaking.

  A bicycle (track 1, a, the subject; 1.8 m long, 0.6 m wide) and a car (track 2, b; 4.5 m long,
  1.8 m wide), both heading east on an open plane, the car's centre line 2 m north of the
  bicycle's; no regions or devices. Three observations 0.5 s apart. The bicycle rides at 6 m/s
  (3 m per step), the car drives at 3 m/s (1.5 m per step). The instance sets `cos_tol` to 9/10
  and `speed_tol` to 0.1 m/s. The relations are computed by Core from the kinematics; none is
  supplied.
  - holds: the bicycle's centre is at x = 3k m, the car's at x = 1.5k + 1.5 m: the bicycle's centre
    goes from 1.5 m behind the car's to 1.5 m ahead of it, within the 3.15 m of the half-lengths'
    sum, so the projections on the bicycle's heading overlap at every observation.
  - fails: the car's centre is at x = 1.5k + 14 m: the bicycle's front stays more than 10 m behind
    the car's rear, the overlap negative at every observation.
  - blind: the geometry of `holds`, but the source supplies no speed for either road user (the
    manifest masks kin.speed and both fields are unset), so the speed comparison is unknown while
    the other two conjuncts hold.
-/
import TrafficSpec.Concepts.interaction.overtaking
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.overtaking

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: `cos_tol` is 9/10 (about 26°), `speed_tol` a
    0.1 m/s speed resolution. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.overtaking@w"
    concept := "drv.interaction.overtaking"
    literals := []
    nats := []
    params := [("cos_tol", .lit (Units.ratio 9 10) .ratio),
               ("speed_tol", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A bicycle 1.8 m long, 0.6 m wide, 1.6 m high (half-extents). -/
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 80)

/-- A car 4.5 m long, 1.8 m wide, 1.5 m high (half-extents). -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The bicycle heading east at 6 m/s, its centre `x` centimetres along the x axis. -/
def bike (x : Int) : RoadUser :=
  Build.user 1 [.bicycle] (cm x, m 0) Build.east (Units.metresPerSecond 6) bikeExtent

/-- The car heading east at 3 m/s, its centre `x` centimetres along the x axis, 2 m north. -/
def car (x : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm x, m 2) Build.east (Units.metresPerSecond 3) carExtent

def noSpeed (u : RoadUser) : RoadUser :=
  Build.withKin u fun kin => { kin with speed := none }

/-- `holds` (compliant): A bicycle at 6 m/s beside a car at 3 m/s heading the same way, their footprints overlapping along the bicycle's heading. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike (300 * k), car (150 * k + 150) ]
      [ ]
      [ ]

/-- `fails` (violated): The bicycle at 6 m/s is 10 m behind the car at 3 m/s: the projections do not overlap. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ bike (300 * k), car (150 * k + 1400) ]
      [ ]
      [ ]

/-- `blind` (unknown): Side by side, but the source supplies no speeds. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ noSpeed (bike (300 * k)), noSpeed (car (150 * k + 150)) ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.interaction.overtaking
