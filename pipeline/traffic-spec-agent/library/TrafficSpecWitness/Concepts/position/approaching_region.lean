/-
  Witnesses for drv.position.approaching_region.

  The geometry is one junction, region 100: the intersection rectangle from (0, -10) to (20, 10)
  metres, whose reference point — the middle of it — is (10, 0). A straight way runs east through
  it along y = 0. Every trace is three observations one second apart, from t = 0.

  The bodies are motor vehicles two metres half-length, one metre half-width, one metre
  half-height, on the centre line y = 0:
    `holds`  — track 1 starts at x = -32 m heading due east at eleven metres per second. Its
               front is at x = -30, so its outline is thirty metres from the junction, well
               within the fifty-metre reach, its footprint clear of the region; the separation to
               the junction's reference point is due east, so the whole eleven metres per second
               is closing speed, above the floor. At the last observation it is at x = -10 (eight
               metres of outline distance), still outside the region.
    `fails`  — track 1 stands at x = -32 m with its engine running and does not move: its
               velocity is zero, so it is near the junction but not closing on it. Track 2 stands
               thirty metres east of the junction's far edge (x = 52 m, its rear at x = 50) and
               drives due east at eleven metres per second, straight away from the junction.
    `blind`  — the `holds` scene, with `st.region_geometry` absent from the manifest: the source
               maps regions without outlines or reference points, so the outline distance and the
               direction to the junction are both unknown, while the footprint still decidedly
               does not overlap the region.

  The instance's figures are this witness's own: the approach reach fifty metres (the thirty
  metres of the scenes inside it), the closing floor one metre per second (the eleven metres per
  second above it, the standing vehicle below it, the receding vehicle on the wrong side of it).
-/
import TrafficSpec.Concepts.position.approaching_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.position.approaching_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100  (the junction, a structure of every trace below)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.position.approaching_region@w"
    concept := "drv.position.approaching_region"
    literals := []
    nats := []
    params := [("approach_reach", .lit (Units.metres 50) .metre),
               ("closing_speed_floor", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The junction, region 100: the rectangle from (0, -10) to (20, 10) metres, its reference point
    the middle of it. -/
def junction : Structure :=
  { Build.rect 100 .intersection (m 0) (m (-10)) (m 20) (m 10) with
    position := some (m 10, m 0) }

/-- The vehicle's half-extents: two metres half-length, one metre half-width and half-height. -/
def carExtent : Q × Q × Q := (m 2, m 1, m 1)

/-- The x of a body that starts at `x0` and travels `step` metres each observation. -/
def xAt (x0 step : Q) (k : Nat) : Q := Q.add x0 (Q.mul (Q.ofInt (Int.ofNat k)) step)

/-- `holds` (compliant): A vehicle thirty metres from a junction travels straight towards the middle of it at eleven metres per second, its footprint clear of the junction region. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (xAt (m (-32)) (m 11) k, m 0) Build.east
          (Units.metresPerSecond 11) carExtent ]
      [ junction ]
      [ ]

/-- `fails` (violated): A vehicle stands thirty metres from the same junction with its engine running and does not move, its footprint clear of the junction region; a second vehicle at the same distance drives straight away from the junction. Both are near it and neither is closing on it. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m (-32), m 0) Build.east Q.zero carExtent)
          (fun kin => { kin with engineRunning := some true })
      , Build.user 2 [.motorVehicle] (xAt (m 52) (m 11) k, m 0) Build.east
          (Units.metresPerSecond 11) carExtent ]
      [ junction ]
      [ ]

/-- `blind` (unknown): A vehicle travels towards the junction as in the first scene, but the source maps regions without their outlines or their reference points, so the distance to the junction and the direction to it are both unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (xAt (m (-32)) (m 11) k, m 0) Build.east
          (Units.metresPerSecond 11) carExtent ]
      [ junction ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"] ]

end TrafficSpecWitness.Concepts.position.approaching_region
