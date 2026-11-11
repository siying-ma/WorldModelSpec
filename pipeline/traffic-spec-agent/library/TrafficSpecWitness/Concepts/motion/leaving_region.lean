/-
  Witnesses for drv.motion.leaving_region.

  Geometry: region 100 is a lane-kind rectangle from (0, -2) to (20, 2). Road user 1 is a motor
  vehicle heading east at 10 m/s, half-extent 2 m × 1 m × 1 m. Three scenes at t = 0, 1000,
  2000 ms; every scenario is judged at t1 = 1000 ms (the `window`). Occupancy is derived from the
  geometry (the user's position inside the rectangle).
  - holds: x at (15, 0) at t0 (on r), at (25, 0) at t1 and (35, 0) at t2 (off r).
  - fails: x at (5, 0), (10, 0), (15, 0): on r throughout.
  - blind: the holds geometry with `rel.occupies` unobserved.
  The concept has no parameters; the instance fills nothing.
-/
import TrafficSpec.Concepts.motion.leaving_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.leaving_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: r ↦ 100  (a structure of every trace)

/-- The instance every scenario speaks about: the concept has no literal formals and no
    parameters. -/
def inst : Concept.Instance :=
  { name := "drv.motion.leaving_region@w"
    concept := "drv.motion.leaving_region"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The region r. -/
def regionR : Structure := Build.rect 100 .lane (m 0) (m (-2)) (m 20) (m 2)

/-- x at `(px, 0)` heading east. -/
def userX (px : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m px, m 0) Build.east (Units.metresPerSecond 10) (m 2, m 1, m 1)

/-- x on r at the first scene, off it from the second on. -/
def leavingPos (k : Nat) : Int := 15 + 10 * (k : Int)

/-- `holds` (compliant): x's footprint overlaps r at t0 and does not at t1; judged at t1. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [userX (leavingPos k)] [regionR] []

/-- `fails` (violated): x's footprint overlaps r at t0 and at t1; judged at t1. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [userX (5 + 5 * (k : Int))] [regionR] []

/-- `blind` (unknown): rel.occupies of x and r is not observed at t1. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [userX (leavingPos k)] [regionR] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some (1000, 1000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.motion.leaving_region
