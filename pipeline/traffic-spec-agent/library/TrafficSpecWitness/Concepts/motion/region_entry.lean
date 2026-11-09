/-
  Witnesses for drv.motion.region_entry.

  The geometry, the same in all three traces: region 100 is a square junction polygon spanning
  x ∈ [-10 m, 10 m], y ∈ [-10 m, 10 m]; track 1 is a car (half-extents 2 m × 1 m × 1 m) heading
  north at 10 m/s along x = 0. Each trace has three scenes, one second apart, at t = 0, 1000 and
  2000 ms. Occupancy is the geometry's: the car occupies the junction at the scenes where its
  position lies inside the polygon.

    holds:  y = -15 m, -5 m, 5 m — clear of the junction at t = 0, inside from t = 1000 on, so the
            overlap begins at t = 1000, the instant the window names.
    fails:  y = -5 m, 0 m, 5 m — inside the junction at every scene, so the overlap has already
            begun before t = 1000 and the event is false at t = 1000 and t = 2000, the window.
    blind:  the holds geometry with `rel.occupies` masked, so whether the car overlaps the junction
            is unreported at both t = 0 and t = 1000 and whether the overlap has just begun is
            unknown at t = 1000, the instant the window names.

  Each window starts at t = 1000: the event looks back one observation, so at the trace's first
  scene it is truncated, and the witnesses speak about the instants after it. The concept declares
  no formal parameter and no literal formal, so the instance gives no value.
-/
import TrafficSpec.Concepts.motion.region_entry
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.region_entry

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100  (the junction polygon of every trace)

/-- The instance every scenario speaks about: a formula concept with no literal formal, no nat and
    no parameter, so there is nothing to fill and no bounds to expect. -/
def inst : Concept.Instance :=
  { name := "drv.motion.region_entry@w"
    concept := "drv.motion.region_entry"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The junction polygon the region formal `r` is bound to. -/
def junction : Structure := Build.rect 100 .intersection (m (-10)) (m (-10)) (m 10) (m 10)

/-- The car, heading north at 10 m/s, at the northing the scene gives it. -/
def car (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, y) Build.north (Units.metresPerSecond 10) (m 2, m 1, m 1)

/-- A scene of the car at `y` and the junction polygon; occupancy follows the geometry. -/
def sceneAt (t : Timestamp) (y : Q) : Scene :=
  Build.scene t (some 1) [car y] [junction] []

/-- `holds` (compliant): A car's footprint is clear of the junction polygon at one scene and overlaps it at the next: the concept is true at that next scene. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneAt t (match k with | 0 => m (-15) | 1 => m (-5) | _ => m 5)

/-- `fails` (violated): A car's footprint overlaps the junction polygon at both scenes: it is already inside, so the concept is false at the later scene. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneAt t (match k with | 0 => m (-5) | 1 => m 0 | _ => m 5)

/-- `blind` (unknown): The source does not report whether the car's footprint overlaps the junction polygon at the earlier scene, so whether the overlap has just begun is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneAt t (match k with | 0 => m (-15) | 1 => m (-5) | _ => m 5)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (window : Timestamp × Timestamp) (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant (1000, 1000)
  , witness "fails" failsTrace .violated (1000, 2000)
  , witness "blind" blindTrace (.unknown []) (1000, 1000) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.motion.region_entry
