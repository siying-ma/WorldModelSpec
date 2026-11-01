/-
  Witnesses for drv.motion.turn_left.

  The instance fills the formals with figures of this file's own: `window` = 4 s (long enough to
  span a turn at junction speeds) and `min_heading_change` = 60° (above the yaw a lane change or a
  road bend carries in four seconds, below a quarter turn).

  One body, track 1, a car 4 m long and 1.8 m wide, judged alone: the concept reads nothing but
  that body's yaw rate, so no region and no second user is built. Every trace runs at 2 Hz (0.5 s
  between observations, half the 2 s the 4 s window needs to be adequately sampled), and each
  witness names the instants it speaks about, since a window behind is truncated over the first
  4 s of any trace.

  `holds` (t = 0 … 11.5 s): the car runs east at 6 m/s to t = 5.5 s with no yaw, then swings
  counter-clockwise at 21.25 °/s for 4 s — eight intervals of 10.625° each — so its heading
  has come round from east to 85° at t = 9.5 s and the window behind that observation carries the
  whole 85°, the quarter turn through the junction; after t = 10 s it runs straight on the new
  heading. The witness judges t = 9.5 s, where 85° ≥ 60°.

  `fails` (t = 0 … 11.5 s): the car follows a gentle left-hand bend at 20 m/s (a radius of about
  570 m), yawing 2 °/s throughout, so every window behind carries 8° — a bend followed, not a turn
  taken. The witness judges t = 5 s … 11.5 s, every instant whose window is covered, and the
  comparison 8° ≥ 60° is false at each.

  `blind`: the same sweep through the junction as `holds`, with `kin.yaw_rate` masked, so the
  integral cannot be formed and the comparison is unknown at the instant judged.
-/
import TrafficSpec.Concepts.motion.turn_left
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turn_left

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- Half-length, half-width, half-height of the car: 4 m × 1.8 m × 1.5 m. -/
def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- A heading from (cos, sin) in thousandths; a heading is read for its direction only. -/
def dir (cx cy : Int) : Vec := (Units.ratio cx 1000, Units.ratio cy 1000)

/-- The heading after `j` intervals of the counter-clockwise swing: 10.625° to the left each,
    from east (j = 0) to 85° (j = 8). -/
def turnHeading (j : Nat) : Vec :=
  match j with
  | 0 => dir 1000 0
  | 1 => dir 983 184
  | 2 => dir 932 362
  | 3 => dir 850 528
  | 4 => dir 737 676
  | 5 => dir 600 800
  | 6 => dir 442 897
  | 7 => dir 270 963
  | _ => dir 87 996

/-- The swing runs over the observations 12 … 19 (t = 6 s … 9.5 s); before and after it the car
    keeps its heading. -/
def holdsHeading (k : Nat) : Vec :=
  if k < 12 then turnHeading 0
  else if k ≥ 20 then turnHeading 8
  else turnHeading (k - 11)

/-- The car's position: straight east at 3 m per observation, then an arc of about 16 m radius
    through the junction, then straight north-north-east. -/
def holdsPos (k : Nat) : Vec :=
  if k ≤ 11 then (m (3 * (k : Int)), m 0)
  else
    match k - 11 with
    | 1 => (cm 3590, cm 27)
    | 2 => (cm 3880, cm 110)
    | 3 => (cm 4150, cm 240)
    | 4 => (cm 4380, cm 420)
    | 5 => (cm 4580, cm 640)
    | 6 => (cm 4740, cm 890)
    | 7 => (cm 4840, cm 1170)
    | 8 => (cm 4890, cm 1460)
    | j => (cm 4890, cm (1460 + 300 * ((j : Int) - 8)))

/-- 21.25 °/s over the four seconds of the swing, nothing before or after it. -/
def holdsYaw (k : Nat) : Q :=
  if k < 12 || k ≥ 20 then Q.zero else Units.millidegrees 21250

/-- The heading along the gentle bend: 1° to the left per observation, written through the
    half-angle parametrization (1 − t², 2t) with t = tan(0.5° · k). -/
def bendHeading (k : Nat) : Vec :=
  let t := Units.ratio (8727 * (k : Int)) 1000000
  (Q.sub (Units.ratio 1 1) (Q.mul t t), Q.mul (Units.ratio 2 1) t)

/-- The position along the bend: 10 m east per observation, drifting north as a 570 m radius. -/
def bendPos (k : Nat) : Vec :=
  (m (10 * (k : Int)), Units.millimetres (87 * (k : Int) * (k : Int)))

/-- The car, with the yaw rate the scene observes. -/
def carUser (pos heading : Vec) (speed ω : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading speed carExtent)
    fun kin => { kin with yawRate := some ω }

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a 4 s window and a 60° bound. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turn_left@w"
    concept := "drv.motion.turn_left"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 4) .second),
               ("min_heading_change", .lit (Units.degrees 60) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car approaches a junction at 6 m/s and swings counter-clockwise through
    the junction; its yaw rate is positive throughout and the integrated heading change over the
    window behind reaches 85 degrees to the left at the observation judged (t = 9.5 s). -/
def holdsTrace : Trace :=
  Build.trace 24 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ carUser (holdsPos k) (holdsHeading k) (Units.metresPerSecond 6) (holdsYaw k) ]
      []  -- structures: the concept reads no region
      []  -- devices

/-- `fails` (violated): A car follows a gentle left-hand bend of a road at 20 m/s; the integrated
    heading change over the window behind is 8 degrees to the left, below min_heading_change, so no
    turn is recognized. -/
def failsTrace : Trace :=
  Build.trace 24 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ carUser (bendPos k) (bendHeading k) (Units.metresPerSecond 20) (Units.degrees 2) ]
      []  -- structures
      []  -- devices

/-- `blind` (unknown): A car sweeps left through a junction, but the trace carries no yaw rate for
    it, so the integrated heading change cannot be formed. The sweep of `holds`, with
    `kin.yaw_rate` masked by the witness's manifest. -/
def blindTrace : Trace := holdsTrace

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
  [ witness "holds" holdsTrace .compliant [] (some (9500, 9500))
  , witness "fails" failsTrace .violated [] (some (5000, 11500))
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (some (9500, 9500)) ]

end TrafficSpecWitness.Concepts.motion.turn_left
