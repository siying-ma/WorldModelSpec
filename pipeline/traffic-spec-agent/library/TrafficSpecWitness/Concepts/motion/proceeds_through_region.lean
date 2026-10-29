/-
  Witnesses for drv.motion.proceeds_through_region.

  The geometry is one junction, region 100: the intersection rectangle from (0, -10) to (30, 10)
  metres, crossed by a straight way running east along y = 0. Every trace is nine observations
  half a second apart, from t = 0 to t = 4 s, and every scenario speaks about the instants
  t = 2 s … 4 s (`window`): the recognition window is two seconds long, so at the earlier
  instants it reaches past the start of the trace and the heading change is truncated rather than
  decided. Half a second between observations is at most half the window, so the window is
  adequately sampled.

  The bodies are motor vehicles two metres half-length, one metre half-width, one metre
  half-height, on the centre line y = 0, their yaw rate observed throughout:
    `holds`  — track 1 enters at x = 2 m heading due east at four metres per second, so it is
               inside the junction at every observation (x = 2 … 18 m) and well above the
               one-metre-per-second motion floor; its yaw rate is nil throughout, so the signed
               heading change over the two seconds behind is nil, below the fifteen-degree
               course-change threshold.
    `fails`  — track 1 stands at (10, 0) within the junction, its engine running, its yaw rate
               nil: its footprint overlaps the region and its course has not changed, but its
               speed is zero and so does not exceed the motion floor.
    `blind`  — the `holds` scene, with `kin.yaw_rate` absent from the manifest: the source tracks
               bodies without a yaw rate, so the heading change over the window cannot be
               integrated, while the overlap and the speed are still decidedly true.

  The instance's figures are this witness's own: the recognition window two seconds (the trace
  covering it), the course-change threshold fifteen degrees (the nil change of the scenes below
  it), the motion floor one metre per second (the four metres per second above it, the standing
  vehicle below it).
-/
import TrafficSpec.Concepts.motion.proceeds_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.proceeds_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100  (the junction, a structure of every trace below)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.proceeds_through_region@w"
    concept := "drv.motion.proceeds_through_region"
    literals := []
    nats := []
    params := [("straight_window", .lit (Units.seconds 2) .second),
               ("straight_heading_change", .lit (Units.degrees 15) .degree),
               ("motion_speed_floor", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The junction, region 100: the rectangle from (0, -10) to (30, 10) metres. -/
def junction : Structure := Build.rect 100 .intersection (m 0) (m (-10)) (m 30) (m 10)

/-- The vehicle's half-extents: two metres half-length, one metre half-width and half-height. -/
def carExtent : Q × Q × Q := (m 2, m 1, m 1)

/-- The x of a body that starts at `x0` and travels `step` metres each observation. -/
def xAt (x0 step : Q) (k : Nat) : Q := Q.add x0 (Q.mul (Q.ofInt (Int.ofNat k)) step)

/-- A body whose yaw rate the source observes as `ω` degrees per second. -/
def turning (u : RoadUser) (ω : Q) : RoadUser :=
  Build.withKin u (fun kin => { kin with yawRate := some ω })

/-- `holds` (compliant): The subject's footprint overlaps the intersection region named by the formal, it runs across that region at a speed well above the motion floor, and its yaw rate has been zero throughout the window behind, so its accumulated signed heading change is nil, below the course-change threshold: it is travelling across the region on an unchanged course. -/
def holdsTrace : Trace :=
  Build.trace 9 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ turning
          (Build.user 1 [.motorVehicle] (xAt (m 2) (Units.metres 2) k, m 0) Build.east
            (Units.metresPerSecond 4) carExtent)
          Q.zero ]
      [ junction ]
      [ ]

/-- `fails` (violated): The subject stands still within the region: its footprint overlaps the region and its yaw rate is zero throughout the window behind, so the heading change is nil, but its speed is zero and so does not exceed the motion floor — it merely occupies the region and is not denoted. -/
def failsTrace : Trace :=
  Build.trace 9 0 (Units.milliseconds 500) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (turning (Build.user 1 [.motorVehicle] (m 10, m 0) Build.east Q.zero carExtent) Q.zero)
          (fun kin => { kin with engineRunning := some true }) ]
      [ junction ]
      [ ]

/-- `blind` (unknown): The subject's footprint overlaps the region and its speed is above the motion floor, but the source's manifest declares the yaw rate absent, so the heading change over the window cannot be integrated and the concept reports unknown while the other two elements are decided true. -/
def blindTrace : Trace :=
  Build.trace 9 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ turning
          (Build.user 1 [.motorVehicle] (xAt (m 2) (Units.metres 2) k, m 0) Build.east
            (Units.metresPerSecond 4) carExtent)
          Q.zero ]
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
    expected := expected
    -- the instants at which the two-second window behind lies inside the trace
    window := some (2000, 4000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.proceeds_through_region
