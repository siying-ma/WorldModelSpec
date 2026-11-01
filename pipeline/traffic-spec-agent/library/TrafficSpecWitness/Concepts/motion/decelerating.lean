/-
  Witnesses for drv.motion.decelerating.

  The instance fills speed_tolerance with 0.1 m/s: a sampled ground speed within a tenth of a metre
  a second counts as no movement, which is inside the noise a tracked speed of a halted body carries
  and far below any speed at which a body is plainly rolling. It fills decel_tolerance with
  0.2 m/s2: a sampled longitudinal acceleration whose magnitude is within a fifth of a metre a
  second squared cannot be told from travel at a steady speed, which covers the jitter of a
  differentiated speed trace and lies well below the one to two metres a second squared of an
  ordinary easing off or braking.

  The concept reads one body and no map, so every trace is one car (track 1, a motor vehicle 4.5 m
  long, 1.8 m wide and 1.5 m tall) on an empty record: no regions and no devices, the car being the
  trace's subject and the track the formal `u` is grounded to. Every trace runs three observations a
  second apart (t = 0, 1000, 2000 ms); the body is a state at an observation and looks neither back
  nor ahead, so no window is named and no padding is needed.

  `holdsTrace` — a car approaching a junction eastward along y = 0, at x = -10, 0 and 10 m: its
  ground speed reads 10 m/s at every observation, far above 0.1 m/s, so it is plainly not at a halt,
  and its acceleration along its heading reads -1.5 m/s2 at every observation, negative and of
  magnitude 1.5 m/s2, far above 0.2 m/s2. It is reducing its own speed at every instant. (The speed
  is held at the one figure the narrative states rather than stepped down with the acceleration: the
  concept reads the speed only to tell a rolling body from a halted one, and nothing of the body's
  motion over the trace enters it.)

  `failsTrace` — the same car at a kerb, then rolling. At t = 0 it stands at (0, -3) with a ground
  speed of zero, below 0.1 m/s, while its acceleration along its heading reads -1 m/s2, the reading
  of the instant it begins to roll: it is at a complete halt, sheds no further speed and is not
  denoted, whatever that acceleration reads. At t = 1000 and t = 2000 it is out on the level street
  at (5, 0) and (15, 0) holding 10 m/s with its acceleration along its heading reading +0.05 m/s2, a
  magnitude of 0.05 m/s2 below 0.2 m/s2 and in any case not negative, so it is not denoted there
  either. The body is false at every observation of the trace.

  `blindTrace` is the rolling car of `holdsTrace`, judged on a source that declares
  kin.accel_longitudinal absent: the ground speed still reads 10 m/s, so the body is decidedly not
  at a halt, but whether it is losing speed along its heading cannot be read and the concept is
  unknown.
-/
import TrafficSpec.Concepts.motion.decelerating
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.decelerating

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A ground speed in millimetres a second, so that a tenth of a metre a second is exact. -/
def mmps (n : Int) : Q := Units.micrometresPerSecond (n * 1000)
/-- A longitudinal acceleration in millimetres a second squared, signed along the heading. -/
def mmpss (n : Int) : Q := Units.micrometresPerSecondSq (n * 1000)
/-- The car: 4.5 m long, 1.8 m wide, 1.5 m tall. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
/-- Ten metres a second, the rolling speed of every trace. -/
def rolling : Q := Units.metresPerSecond 10

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a sampled ground speed counts as no movement within
    0.1 m/s, and a sampled longitudinal acceleration cannot be told from travel at a steady speed
    within 0.2 m/s2. -/
def inst : Concept.Instance :=
  { name := "drv.motion.decelerating@w"
    concept := "drv.motion.decelerating"
    literals := []
    nats := []
    params :=
      [ ("speed_tolerance", .lit (mmps 100) .metrePerSecond)
      , ("decel_tolerance", .lit (mmpss 200) .metrePerSecondSq) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car, heading east at the given ground speed from the given point, its acceleration along
    its heading reading `accel`. -/
def car (x y : Q) (speed accel : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (x, y) Build.east speed carExtent)
    (fun k => { k with accelLongitudinal := some accel })

/-- `holds` (compliant): A vehicle approaching a junction at 10 m/s, a ground speed well above
    speed_tolerance, eases off and brakes: its acceleration along its heading reads minus 1.5 m/s2
    at the observation, a magnitude well above decel_tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (-10 + 10 * (k : Int))) (m 0) rolling (mmpss (-1500)) ]
      []
      []

/-- `fails` (violated): A vehicle stands at a kerb with zero ground speed, below speed_tolerance,
    while its acceleration along its heading reads minus 1 m/s2, as at the instant it begins to
    roll: a body at rest sheds no further speed and is not denoted, whatever that reading. At a
    later observation it holds 10 m/s on a level street with its acceleration along its heading
    reading plus 0.05 m/s2, a magnitude below decel_tolerance and in any case not negative, so it is
    not denoted there either. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ if k == 0 then car (m 0) (m (-3)) Q.zero (mmpss (-1000))
        else car (m (5 + 10 * ((k : Int) - 1))) (m 0) rolling (mmpss 50) ]
      []
      []

/-- `blind` (unknown): A vehicle rolls along a street at 10 m/s, a ground speed above
    speed_tolerance so that it is plainly not at a halt, on a source that declares longitudinal
    acceleration absent, so whether it is losing speed along its heading cannot be read. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.accel_longitudinal"] ]

end TrafficSpecWitness.Concepts.motion.decelerating
