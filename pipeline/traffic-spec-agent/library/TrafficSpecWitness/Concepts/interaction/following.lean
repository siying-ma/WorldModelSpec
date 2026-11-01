/-
  Witnesses for drv.interaction.following.

  The world: a straight way running east, +x east and +y north, every body a car 4.8 m long and
  1.8 m wide (half-extents 2.40 m, 0.90 m, 0.75 m), three observations one second apart, every car
  at 20 m/s.

  `holds`: one lane (region 1, 4 m wide, y ∈ [-2, 2], direction east). Track 1 (the subject, u) runs
  along its centre from the origin, track 2 (v) thirty metres ahead of it on the same centre line;
  both head east. Centre to centre thirty metres, so the longitudinal component of the surface gap
  is 30 − 2.40 − 2.40 = 25.20 m: above zero and below the reach the instance gives.

  `fails`: two lanes of one roadway, region 1 (y ∈ [0, 4], direction east) and region 2
  (y ∈ [-4, 0], direction west). Track 1 (u) runs east along y = 2 m, track 2 (v) west along
  y = −2 m, the two passing each other. No lane holds both bodies and the headings are opposed.

  `blind`: the geometry of `holds` (track 2 thirty metres ahead of track 1 in lane 1), with a source
  that declares surface gaps absent and does not measure the bodies' extents, so no gap can be
  measured or computed and whether the car ahead is within reach cannot be decided. Occupancy, the
  positions and the headings are observed, so every other conjunct of the body is decided.

  The instance's figures are this witness's own: same_direction_cosine = 0.95 (headings within
  about 18° count as the same direction), reach = 50 m.
-/
import TrafficSpec.Concepts.interaction.following
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.following

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1, v ↦ 2
-- Formals ↦ regions: (no region formal)

/-- A car: half-length 2.40 m, half-width 0.90 m, half-height 0.75 m. -/
def car : Q × Q × Q := (cm 240, cm 90, cm 75)

/-- Twenty metres a second, the speed every body here runs at. -/
def cruise : Q := Units.metresPerSecond 20

/-- The distance a body at `cruise` has run by the `k`th observation, one second apart. -/
def run (k : Nat) : Int := 20 * Int.ofNat k

/-- The single lane of the `holds` and `blind` worlds: 4 m wide, running east. -/
def oneLane : Structure :=
  Build.lane 1 [(m (-60), m (-2)), (m 400, m (-2)), (m 400, m 2), (m (-60), m 2)] Build.east

/-- The eastbound lane of the `fails` world. -/
def eastLane : Structure :=
  Build.lane 1 [(m (-60), m 0), (m 400, m 0), (m 400, m 4), (m (-60), m 4)] Build.east

/-- The westbound lane of the `fails` world. -/
def westLane : Structure :=
  Build.lane 2 [(m (-60), m (-4)), (m 400, m (-4)), (m 400, m 0), (m (-60), m 0)] Build.west

/-- The instance every scenario speaks about: every parameter given a value through a `Units`
    constructor. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.following@w"
    concept := "drv.interaction.following"
    literals := []
    nats := []
    params := [("same_direction_cosine", .lit (Units.ratio 95 100) .ratio),
               ("reach", .lit (Units.metres 50) .metre)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): Two cars run in the same lane of a rural highway, both heading the same way, the second thirty metres behind the first. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (run k), m 0) Build.east cruise car (some (m (run k)))
      , Build.user 2 [.motorVehicle] (m (30 + run k), m 0) Build.east cruise car (some (m (run k))) ]
      [ oneLane ]
      [ ]

/-- `fails` (violated): Two cars pass each other in opposite directions on a two-lane road, in different lanes and with opposed headings. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (run k), m 2) Build.east cruise car (some (m (run k)))
      , Build.user 2 [.motorVehicle] (m (60 - run k), m (-2)) Build.west cruise car (some (m (run k))) ]
      [ eastLane, westLane ]
      [ ]

/-- `blind` (unknown): A car runs behind another in the same lane, but the source declares surface gaps absent, so whether the vehicle ahead is within reach cannot be decided. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (run k), m 0) Build.east cruise car (some (m (run k)))
      , Build.user 2 [.motorVehicle] (m (30 + run k), m 0) Build.east cruise car (some (m (run k))) ]
      [ oneLane ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1), ("v", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
    -- the gap is the source's to supply or Core's to compute from the bodies' footprints: a source
    -- that declares gaps absent and measures no extent leaves it unmeasurable either way
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap", "kin.extent"] ]

end TrafficSpecWitness.Concepts.interaction.following
