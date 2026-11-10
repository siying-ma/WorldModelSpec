/-
  Witnesses for drv.lane.facing_against_direction.

  A one-way roadway (region 100), the rectangle x ∈ [0, 100] m, y ∈ [0, 8] m, its designated
  direction east. A car (track 1, half-extents 2.5 × 1 × 0.75 m) sits at (50, 4) m inside it at
  each of three instants 1 s apart, at rest (speed 0: what is judged is where it points, not how it
  moves).
  - holds: the car points west, against the designated direction (cosine −1).
  - fails: the car points east, along it (cosine +1).
  - blind: as holds, with kin.heading absent from the manifest.
  The instance gives `cos_tol` 9/10 (headings within about 26° of exactly opposed count as against).
-/
import TrafficSpec.Concepts.lane.facing_against_direction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.facing_against_direction

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: c ↦ 100

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.lane.facing_against_direction@w"
    concept := "drv.lane.facing_against_direction"
    literals := []
    nats := []
    params := [("cos_tol", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The one-way roadway, designated direction east. -/
def roadway : Structure :=
  { Build.rect 100 .oneWayRoadway (m 0) (m 0) (m 100) (m 8) with
    lane := some { direction := some Build.east } }

/-- The car at (50, 4) m, pointing along `h`, at rest. -/
def car (h : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 50, m 4) h (Units.metresPerSecond 0) (cm 250, m 1, cm 75)

/-- `holds` (compliant): A car on a one-way roadway points opposite its designated direction. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [car Build.west] [roadway] []

/-- `fails` (violated): A car points along the roadway's designated direction. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [car Build.east] [roadway] []

/-- `blind` (unknown): As holds, with kin.heading declared absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [car Build.west] [roadway] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("c", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.heading"] ]

end TrafficSpecWitness.Concepts.lane.facing_against_direction
