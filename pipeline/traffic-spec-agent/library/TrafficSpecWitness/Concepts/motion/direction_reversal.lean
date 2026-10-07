/-
  Witnesses for drv.motion.direction_reversal.

  THE GEOMETRY (every figure here is this witness's own).

  One body, track 1, a motor vehicle 4 m long and 1.8 m wide (half-extents 2 m, 90 cm, 75 cm).
  Two regions, both of kind roadway: `mainRoadway`, the way it starts on, running east–west from
  x = −100 m to x = 100 m and 40 m wide in the model; `sideStreet`, the crossing way `fails` turns
  into, x ∈ [22, 38] m and running north to y = 80 m. A roadway region is drawn generously here
  because the concept reads only whether the footprint overlaps one — `rel.occupies` is derived
  from the body's position inside the polygon — and nothing in the body reads lanes, markings or
  width.

  THE INSTANTS. Every trace is 28 observations at 500 ms, t = 0 … 13 500 ms, and the instance's
  window is 8 s, so the back window spans 16 observations. The scenarios speak about
  t ∈ [8 000, 11 500] ms (observations 16 … 23): the earliest instant whose 8 s back window is
  covered is observation 16, and at observation 23 the window still reaches back to observation 7.
  Before observation 16 the window is truncated at the start of the trace and the concept is
  unknown by its own contract, which is not what any of the three scenarios is about — hence the
  explicit `window` on each.

  THE YAW. The yaw rate is reported at every observation (0 deg/s on the straights). The heading
  change the primitive integrates is a right-endpoint sum, ω_k · (t_k − t_{k−1}) over the
  observations inside the window:
    holds — 45 deg/s at observations 8 … 15 (4 s of turning): 8 × 45 × 0.5 s = 180 deg, the whole
      of it inside the back window of every observation 16 … 23. 180 ≥ 150, the reversal angle.
    fails — 45 deg/s at observations 8 … 11 only (2 s): 4 × 45 × 0.5 s = 90 deg, a quarter turn,
      below the reversal angle at every observation 16 … 23, while the body stays on a roadway
      (the side street) above the motion speed. The heading change alone decides.
    blind — the scene of holds unchanged; the manifest declares kin.yaw_rate absent, so the
      primitive reports a missing yaw rate over a window that is covered and adequately sampled.

  THE INSTANCE. window 8 s, reversal angle 150 deg, motion speed 1 m/s. The car travels at
  8 m/s on the straights and 3 m/s through the turn, so it is above the motion speed throughout.
-/
import TrafficSpec.Concepts.motion.direction_reversal
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.direction_reversal

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n
/-- Degrees per second: the yaw rate field's unit; `Units` spells the angle. -/
private def degPerSecond (n : Int) : Q := Units.degrees n

-- Formals ↦ tracks: user ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.direction_reversal@w"
    concept := "drv.motion.direction_reversal"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 8) .second), ("reversal_angle", .lit (Units.degrees 150) .degree), ("motion_speed", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none }

def instances : List Concept.Instance := [inst]

/-- The one body: position, heading, speed and the yaw rate the primitive integrates. -/
private def car (pos : Vec) (heading : Vec) (speed : Q) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading speed (m 2, cm 90, cm 75))
    (fun k => { k with yawRate := some yaw })

/-- The way the car starts on, east–west. -/
private def mainRoadway : Structure := Build.rect 1 .roadway (m (-100)) (m (-20)) (m 100) (m 20)
/-- The crossing way `fails` turns into — a roadway of its own. -/
private def sideStreet : Structure := Build.rect 2 .roadway (m 22) (m (-20)) (m 38) (m 80)

/-- `holds` (compliant): A car on a two-lane roadway (rel.occupies on st.roadway) slows, swings through a single continuous turn that leaves it heading back the way it came, and drives off. Integrated over the window, prim.heading_change exceeds the reversal angle in magnitude, and kin.speed at the observation is above the motion speed. The yaw rate is reported at every observation of the window, so the integration is decided. -/
private def holdsTrace : Trace :=
  Build.trace 28 0 (Units.milliseconds 500) fun k t =>
    let i : Int := Int.ofNat k
    let u :=
      if k ≤ 7 then
        -- running east at 8 m/s, straight: no yaw
        car (m (4 * i), m (-3)) Build.east (mps 8) Q.zero
      else if k ≤ 15 then
        -- swinging through half a turn at 45 deg/s for 4 s, slowed to 3 m/s
        car (m 30, m (i - 7)) Build.north (mps 3) (degPerSecond 45)
      else
        -- away west at 8 m/s on the other side of the way, straight again
        car (m (30 - 4 * (i - 15)), m 6) Build.west (mps 8) Q.zero
    Build.scene t (some 1) [u] [mainRoadway] []

/-- `fails` (violated): The same car, on the same roadway and above the motion speed, turns out of the roadway into a side street: integrated over the window, prim.heading_change is about a quarter turn, far below the reversal angle, and it proceeds along the new way. Every atom is observed throughout the window. -/
private def failsTrace : Trace :=
  Build.trace 28 0 (Units.milliseconds 500) fun k t =>
    let i : Int := Int.ofNat k
    let u :=
      if k ≤ 7 then
        car (m (4 * i), m (-3)) Build.east (mps 8) Q.zero
      else if k ≤ 11 then
        -- a quarter turn only: 45 deg/s for 2 s
        car (m 30, m (i - 9)) Build.north (mps 3) (degPerSecond 45)
      else
        -- along the side street at 8 m/s, straight
        car (m 30, m (3 + 4 * (i - 11))) Build.north (mps 8) Q.zero
    Build.scene t (some 1) [u] [mainRoadway, sideStreet] []

/-- `blind` (unknown): The scene of holds — the car swings about on the roadway and drives off above the motion speed — but the source's capability manifest declares kin.yaw_rate absent for the trace, so prim.heading_change is unknown by its own contract (“unknown where … a yaw rate is missing”) while occupancy and speed stay observed. -/
private def blindTrace : Trace := holdsTrace

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("user", 1)]
    expected := expected
    -- observations 16 … 23: the instants whose 8 s back window the trace covers
    window := some (8000, 11500) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.direction_reversal
