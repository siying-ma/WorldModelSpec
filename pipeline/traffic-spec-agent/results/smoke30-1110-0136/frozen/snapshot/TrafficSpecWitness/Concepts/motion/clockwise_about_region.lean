/-
  Witnesses for drv.motion.clockwise_about_region.

  Geometry: region 100 is a roundabout's island, a 20 m square from (−10, −10) to (10, 10) with its
  reference point at the origin (in `blind` the same square mapped without the reference point).
  Car 1 (half-extent 2 m × 1 m × 75 cm) drives around it at 10 m/s on a 20 m circle, seen at three
  instants a second apart: at (0, 20), (20, 0) and (0, −20).
  - holds: heading east, south, west in turn — clockwise; c = −200 m²/s at each instant, and
    c² = 40000 exceeds tol²·|offset|² = 1·400.
  - fails: heading west, north, east in turn — counterclockwise; c = +200 m²/s.
  - blind: the clockwise drive of `holds`, the island without its reference point and
    st.region_geometry absent from the manifest.
  The instance gives tol = 1 m/s.
-/
import TrafficSpec.Concepts.motion.clockwise_about_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.clockwise_about_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: r ↦ 100

/-- The instance every scenario speaks about: tol = 1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.clockwise_about_region@w"
    concept := "drv.motion.clockwise_about_region"
    literals := []
    nats := []
    params := [("tol", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def halfExt : Q × Q × Q := (m 2, m 1, cm 75)
def speed : Q := Units.metresPerSecond 10

/-- The island, mapped with its boundary only. -/
def islandOutline : Structure := Build.rect 100 .roundabout (m (-10)) (m (-10)) (m 10) (m 10)

/-- The island with its reference point at the origin. -/
def island : Structure := { islandOutline with position := some (m 0, m 0) }

/-- The car's position on the 20 m circle at instant k. -/
def posAt (k : Nat) : Vec :=
  match k with
  | 0 => (m 0, m 20)
  | 1 => (m 20, m 0)
  | _ => (m 0, m (-20))

/-- Clockwise heading at instant k: east at the north, south at the east, west at the south. -/
def cwHeading (k : Nat) : Vec :=
  match k with
  | 0 => Build.east
  | 1 => Build.south
  | _ => Build.west

/-- Counterclockwise heading at instant k: the reverse. -/
def ccwHeading (k : Nat) : Vec :=
  match k with
  | 0 => Build.west
  | 1 => Build.north
  | _ => Build.east

/-- `holds` (compliant): A car circles a roundabout's island clockwise at speed: the cross product is negative and its tangential speed exceeds the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (posAt k) (cwHeading k) speed halfExt ]
      [ island ]
      [ ]

/-- `fails` (violated): The car circles the island counterclockwise. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (posAt k) (ccwHeading k) speed halfExt ]
      [ island ]
      [ ]

/-- `blind` (unknown): The region is mapped without its reference point (st.region_geometry absent). -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (posAt k) (cwHeading k) speed halfExt ]
      [ islandOutline ]
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
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"] ]

end TrafficSpecWitness.Concepts.motion.clockwise_about_region
