/-
  Witnesses for drv.position.near_region.

  Geometry (+x east, +y north). Region 100 is a crosswalk, the rectangle x ∈ [10, 14] m,
  y ∈ [-5, 5] m. Track 1 is a motor vehicle heading east, standing (speed 0), half-length 2 m,
  half-width 1 m, half-height 1 m. The instance gives `reach` 3 m. Three instants, 1 s apart.

  - holds: the vehicle's centre at (7, 0), its front at x = 9, 1 m before the crosswalk's edge:
    the body-to-region distance is 1 m ≤ 3 m at every instant.
  - fails: the vehicle's centre at (-40, 0), its front at x = -38, 48 m from the crosswalk: 48 m > 3 m.
  - blind: the holds geometry, but the crosswalk is mapped without an outline (no boundary, no
    reference point) and the manifest declares st.region_geometry absent: the distance is unknown.
    Without an outline the source observes no occupancy either (`occupancyObserved := []`).
-/
import TrafficSpec.Concepts.position.near_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.position.near_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100  (the crosswalk, a structure of every trace)

/-- The instance every scenario speaks about: `reach` is 3 m. -/
def inst : Concept.Instance :=
  { name := "drv.position.near_region@w"
    concept := "drv.position.near_region"
    literals := []
    nats := []
    params := [("reach", .lit (Units.metres 3) .metre)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The crosswalk with its outline. -/
def crosswalk : Structure := Build.rect 100 .crosswalk (m 10) (m (-5)) (m 14) (m 5)

/-- The vehicle standing with its centre at `x` on y = 0, heading east. -/
def vehicle (x : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, Q.zero) Build.east Q.zero (m 2, m 1, m 1)

/-- `holds` (compliant): A vehicle stands with its front a short distance before a crosswalk, within the reach. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ vehicle 7 ]
      [ crosswalk ]
      [ ]

/-- `fails` (violated): A vehicle stands far beyond the reach from the crosswalk. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ vehicle (-40) ]
      [ crosswalk ]
      [ ]

/-- `blind` (unknown): The source maps the crosswalk without its outline and declares st.region_geometry absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    -- without the outline the source does not observe occupancy either
    { Build.scene t (some 1)
        [ vehicle 7 ]
        [ { crosswalk with boundary := none, position := none } ]
        [ ]
      with occupancyObserved := [] }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    regions := [("r", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"] ]

end TrafficSpecWitness.Concepts.position.near_region
