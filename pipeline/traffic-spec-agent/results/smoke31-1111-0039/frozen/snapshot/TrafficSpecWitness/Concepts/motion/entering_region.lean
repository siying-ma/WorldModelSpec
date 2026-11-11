/-
  Witnesses for drv.motion.entering_region.

  Geometry: region 100 is a lane, the rectangle x ∈ [10, 20] m, y ∈ [-2, 2] m. Road user 1 is a
  motor vehicle heading east, half-extents 2 m × 1 m × 1 m. Three observations, t0 = 0 ms,
  t1 = 1000 ms, t2 = 2000 ms; every scenario is judged at t1 alone (`window := (1000, 1000)`).
  - holds: x at (5, 0) at t0 (footprint to x = 7, clear of the lane), at (15, 0) at t1 and t2.
  - fails: x at (15, 0) at every observation: the overlap continues and is no entry.
  - blind: the holds geometry, with `rel.occupies` unobserved.
  The concept has no parameters; the instance fills none.
-/
import TrafficSpec.Concepts.motion.entering_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.entering_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: r ↦ 100

/-- The instance every scenario speaks about: the concept has no literal formals and no parameters. -/
def inst : Concept.Instance :=
  { name := "drv.motion.entering_region@w"
    concept := "drv.motion.entering_region"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The region r: a lane x ∈ [10, 20] m, y ∈ [-2, 2] m. -/
def laneR : Structure := Build.rect 100 .lane (m 10) (m (-2)) (m 20) (m 2)

/-- Road user x at abscissa `px`, heading east. -/
def userX (px : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m px, m 0) Build.east (Units.metresPerSecond 10) (m 2, m 1, m 1)

/-- `holds` (compliant): x's footprint does not overlap r at t0 and overlaps r at t1; judged at t1. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX (if k == 0 then 5 else 15) ]
      [ laneR ]
      [ ]

/-- `fails` (violated): x's footprint overlaps r at t0 and at t1; judged at t1, the overlap continues and is no entry. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ userX 15 ]
      [ laneR ]
      [ ]

/-- `blind` (unknown): rel.occupies of x and r is not observed at t0; judged at t1. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX (if k == 0 then 5 else 15) ]
      [ laneR ]
      [ ]

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

end TrafficSpecWitness.Concepts.motion.entering_region
