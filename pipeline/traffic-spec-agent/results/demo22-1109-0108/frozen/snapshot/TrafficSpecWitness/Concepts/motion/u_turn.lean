/-
  Witnesses for drv.motion.u_turn.

  The geometry. A flat city street as one highway region, 120 m east–west and 28 m wide
  (`street`, region 10, the rectangle (−60, −14)–(60, 14)); the `fails` trace adds the side street
  the car turns into as a second highway region, 28 m wide north–south (`sideStreet`, region 11,
  the rectangle (−14, −60)–(14, 60)). The road user the formal `u` is grounded to is track 1, a
  motor vehicle 4.8 m long and 1.8 m wide (half-extents 2.40 m, 0.90 m, 0.75 m), whose position,
  heading, speed, gear and yaw rate every scene carries. Every trace is sampled at 1 s, so the
  instance's heading step (2 s) covers every interval, the one ending at the onset included.

  The instance's figures are the witness's own: heading_step 2 s, onset_yaw_rate 4 deg/s,
  reversal_angle 150 deg (below a half turn, as the contract requires).

  The heading change the body reads is integrated as Σ ω_k · (t_k − t_{k−1}) over the observations
  after the onset, so each trace below is written with its accumulated figure per observation.

  `holds` (window 7–9 s): track 1 runs east at 8 m/s with no yaw (the onset condition false), then
  swings left at 25, 40 and 40 deg/s, creeps at 2 km/h while a westbound car (track 2, at y = 8 m)
  passes and backs up a metre with the wheel reversed — which keeps the rotation counter-clockwise
  at 10 deg/s, so the yaw rate magnitude never falls back to the onset rate and the count is not
  started again — then completes the swing at 40 and 30 deg/s and runs west with no yaw. The
  accumulated change per observation is 0, 40, 80, 90, 100, 140, 170, 170, 170 deg from the onset
  at t = 1 s: it reaches the reversal angle at t = 7 s and still holds it at 8 s and 9 s, while the
  footprint overlaps the street throughout. The window is the three observations the concept
  speaks about; before them the body is false (the angle not yet reached) or unknown (no onset yet
  observed), which is what the contract says of them.

  `fails` (window 1–6 s): the same car turns left out of the main street into the side street at
  30 deg/s for three observations and then runs north with no yaw: the accumulated change is
  0, 30, 60, 90, 90, 90 deg and never reaches 150, so the body is false at every observation of
  the window while the footprint overlaps a way.

  `blind` (no window, `kin.yaw_rate` absent): the car is already turning at 35 deg/s at the first
  observation of the recording and goes on turning, so no onset is observed with the yaw rate
  known at every observation since; with the atom absent the condition is unknown at every
  observation as well. The accumulated change is unknown and the body with it, never false.
-/
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.u_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A rate of change of heading, in deg/s (the unit `kin.yaw_rate` carries). -/
def dps (n : Int) : Q := Units.degrees n
/-- A direction vector, +x east and +y north; its length is not read. -/
def dir (x y : Int) : Vec := (Units.ratio x 1, Units.ratio y 1)
def mps (n : Int) : Q := Units.metresPerSecond n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the heading step the 1 s sampling needs, the onset
    yaw rate that tells turning from running straight, and the reversal angle, below a half turn. -/
def inst : Concept.Instance :=
  { name := "drv.motion.u_turn@w"
    concept := "drv.motion.u_turn"
    literals := []
    nats := []
    params := [("heading_step", .lit (Units.seconds 2) .second),
               ("onset_yaw_rate", .lit (Units.degrees 4) .degreePerSecond),
               ("reversal_angle", .lit (Units.degrees 150) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The city street, as one highway region. -/
def street : Structure := Build.rect 10 .highway (m (-60)) (m (-14)) (m 60) (m 14)
/-- The side street of the `fails` trace, as a second highway region. -/
def sideStreet : Structure := Build.rect 11 .highway (m (-14)) (m (-60)) (m 14) (m 60)

/-- Track 1, with its position, heading, speed, gear and rate of change of heading. -/
def car (pos : Vec) (heading : Vec) (speed : Q) (yaw : Q) (gear : Int := 1) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading speed (cm 240, cm 90, cm 75))
    fun k => { k with yawRate := some yaw, gear := some gear }

/-- `holds` (compliant): A car on a city street swings left across the way, halts to let a vehicle pass, reverses a metre and completes the swing: from the onset of the turning the accumulated heading change reaches about a hundred and seventy degrees while its footprint overlaps the way. -/
def holdsTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         -- running east, no yaw: the onset condition is false here
         | 0 => car (m (-20), m (-5)) (dir 1 0) (mps 8) (dps 0)
         -- the onset: the yaw rate magnitude rises above the onset rate
         | 1 => car (m (-13), m (-5)) (dir 10 2) (mps 6) (dps 25)
         | 2 => car (m (-8), m (-4)) (dir 10 6) (mps 4) (dps 40)
         | 3 => car (m (-5), m (-2)) (dir 6 8) (mps 3) (dps 40)
         -- creeping while the westbound car passes
         | 4 => car (m (-3), m 0) (dir 5 9) (Units.kmh 2) (dps 10)
         -- backing up a metre, the wheel reversed: the rotation goes on counter-clockwise
         | 5 => car (m (-4), m (-1)) (dir 3 10) (Units.kmh 2) (dps 10) (-1)
         | 6 => car (m (-2), m 1) (dir (-2) 7) (mps 2) (dps 40)
         -- the angle is reached here: 170 deg accumulated since the onset
         | 7 => car (m 0, m 3) (dir (-10) 3) (mps 3) (dps 30)
         | 8 => car (m 4, m 5) (dir (-10) 3) (mps 5) (dps 0)
         | _ => car (m 10, m 5) (dir (-10) 3) (mps 7) (dps 0))
      , Build.withKin (Build.user 2 [.motorVehicle] (m (20 - 8 * (k : Int)), m 8) (dir (-1) 0) (mps 8)
          (cm 240, cm 90, cm 75)) fun kin => { kin with yawRate := some (dps 0) } ]
      [ street ]
      [ ]

/-- `fails` (violated): The same car turns left into a side street: the accumulated heading change since the onset peaks at about ninety degrees and never reaches the reversal angle. -/
def failsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => car (m (-30), m (-5)) (dir 1 0) (mps 10) (dps 0)
         -- the onset of the left turn into the side street
         | 1 => car (m (-20), m (-5)) (dir 10 2) (mps 9) (dps 30)
         | 2 => car (m (-12), m (-4)) (dir 10 6) (mps 8) (dps 30)
         | 3 => car (m (-6), m (-1)) (dir 4 7) (mps 7) (dps 30)
         -- 90 deg accumulated since the onset, and the turn is over
         | 4 => car (m (-4), m 4) (dir 1 6) (mps 7) (dps 30)
         | 5 => car (m (-4), m 12) (dir 0 1) (mps 8) (dps 0)
         | _ => car (m (-4), m 20) (dir 0 1) (mps 9) (dps 0)) ]
      [ street, sideStreet ]
      [ ]

/-- `blind` (unknown): The car is already mid-turn at the first observation of the recording, so no onset is observed with the yaw rate known at every observation since: whether the direction reversed cannot be read. -/
def blindTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         -- already turning at the first observation: the onset lies before the recording
         | 0 => car (m (-6), m (-2)) (dir 8 6) (mps 4) (dps 35)
         | 1 => car (m (-5), m 0) (dir 4 8) (mps 4) (dps 35)
         | 2 => car (m (-4), m 2) (dir 1 9) (mps 3) (dps 35)
         | 3 => car (m (-4), m 4) (dir (-3) 8) (mps 3) (dps 35)
         | _ => car (m (-5), m 6) (dir (-6) 5) (mps 3) (dps 35)) ]
      [ street ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (7000, 9000))
  , witness "fails" failsTrace .violated [] (some (1000, 6000))
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.u_turn
