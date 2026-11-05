/-
  Witnesses for drv.motion.direction_reversal.

  One car, track 1, half-extents 2 m × 1 m × 1 m, travelling at 6 m/s throughout, observed every
  second for eighteen observations (t = 0 … 17000 ms). The scenes carry no region and no device:
  the concept reads the yaw rate (through prim.heading_change) and the speed, and nothing else.
  The instance gives the formal parameters the figures of this witness:
    reversal_window        12 s
    opposition_tolerance   10 deg   — the band is |heading change| in [170, 190] degrees
    motion_speed_tolerance  1 m/s

  The car runs north for the first five seconds (yaw rate zero), then turns left at 22 deg/s for a
  number of seconds, then runs straight again. The heading change over the 12 s window behind an
  observation of the final straight leg is therefore 22 deg/s × (the seconds of turning), and the
  speed is 6 m/s at every observation of that window. Every witness is judged over the window
  [14000, 17000] ms, the final straight leg: there the 12 s lookback is covered (an observation
  lies exactly 12 s behind, or earlier) and adequately sampled (the observations are 1 s apart,
  well under half the window), and it contains the whole turn.

    holds  eight seconds of turning: 22 × 8 = 176 deg, inside the band — the concept holds;
    fails  four seconds of turning: 22 × 4 = 88 deg, far below the band — the car turned into a
           side road and did not turn about;
    blind  the `holds` trace with kin.yaw_rate declared absent: prim.heading_change is unknown over
           the window, while the speed conjunct is true, so the reversal cannot be read.

  Position and heading are a coarse polyline — the turn's points step round an arc by chords of
  about 5 m (the second's 6 m of path is the arc, never less than the chord) and the heading vector
  is the nearest cardinal direction at each observation. Neither is read by the concept: the course
  change comes from the yaw rate and the motion from the speed.
-/
import TrafficSpec.Concepts.motion.direction_reversal
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.direction_reversal

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: no literal formal, the three formal parameters given
    this witness's figures through `Units` constructors. -/
def inst : Concept.Instance :=
  { name := "drv.motion.direction_reversal@w"
    concept := "drv.motion.direction_reversal"
    literals := []
    nats := []
    params :=
      [ ("reversal_window", .lit (Units.seconds 12) .second)
      , ("opposition_tolerance", .lit (Units.degrees 10) .degree)
      , ("motion_speed_tolerance", .lit (Units.metresPerSecond 1) .metrePerSecond) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car at one observation: 6 m/s, the yaw rate the source measured there, the path length it
    has travelled since the start of the trace. -/
def car (pos : Vec) (heading : Vec) (yaw : Q) (path : Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond 6) (m 2, m 1, m 1) (some path))
    (fun k => { k with yawRate := some yaw })

/-- Eighteen observations one second apart, from the three per-observation tables. -/
def leg (poss : List Vec) (heading : Nat → Vec) (yaw : Nat → Q) : Trace :=
  Build.trace 18 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (poss.getD k (m 0, m 0)) (heading k) (yaw k) (m (6 * Int.ofNat k)) ]
      [ ]   -- no structure: the concept reads no region
      [ ]   -- no device

/-- The reversal: north to k = 5, a left turn through 176 degrees over the next eight seconds,
    then south. The turning points step round an arc by chords of about 5 m — the car travels 6 m
    of path in each second, which is the arc, never less than the chord. -/
def reversalPath : List Vec :=
  [ (m 0, m 0), (m 0, m 6), (m 0, m 12), (m 0, m 18), (m 0, m 24), (m 0, m 30)
  , (m (-1), m 35), (m (-4), m 39), (m (-8), m 42), (m (-13), m 43)
  , (m (-18), m 42), (m (-22), m 39), (m (-25), m 35), (m (-26), m 30)
  , (m (-26), m 24), (m (-26), m 18), (m (-26), m 12), (m (-26), m 6) ]

/-- A unit heading from a Pythagorean triple: (a/d, b/d) with a² + b² = d². -/
def dir (a b : Int) (d : Nat) : Vec := (Units.ratio a d, Units.ratio b d)

/-- The heading at each observation of the reversal: north while the car runs straight, then a
    heading that turns left at every observation of the turn, ending south. -/
def reversalHeading (k : Nat) : Vec :=
  match k with
  | 6 => dir (-5) 12 13      -- about 23° west of north
  | 7 => dir (-3) 4 5        -- about 37°
  | 8 => dir (-15) 8 17      -- about 62°
  | 9 => dir (-24) 7 25      -- about 74°
  | 10 => dir (-24) (-7) 25  -- about 106°
  | 11 => dir (-15) (-8) 17  -- about 118°
  | 12 => dir (-3) (-4) 5    -- about 143°
  | k => if k ≤ 5 then Build.north else Build.south

/-- 22 deg/s (left) at the eight observations k = 6 … 13, zero elsewhere: 176 degrees of turning. -/
def reversalYaw (k : Nat) : Q :=
  if 6 ≤ k && k ≤ 13 then Units.degrees 22 else Q.zero

/-- The side road: the same approach, a left turn through 88 degrees over four seconds, then west. -/
def sideRoadPath : List Vec :=
  [ (m 0, m 0), (m 0, m 6), (m 0, m 12), (m 0, m 18), (m 0, m 24), (m 0, m 30)
  , (m (-1), m 35), (m (-4), m 39), (m (-8), m 42), (m (-13), m 43)
  , (m (-19), m 43), (m (-25), m 43), (m (-31), m 43), (m (-37), m 43)
  , (m (-43), m 43), (m (-49), m 43), (m (-55), m 43), (m (-61), m 43) ]

/-- The heading at each observation of the turn into the side road: north, four observations of
    turning left, then west. -/
def sideRoadHeading (k : Nat) : Vec :=
  match k with
  | 6 => dir (-5) 12 13      -- about 23° west of north
  | 7 => dir (-3) 4 5        -- about 37°
  | 8 => dir (-15) 8 17      -- about 62°
  | k => if k ≤ 5 then Build.north else Build.west

/-- 22 deg/s (left) at the four observations k = 6 … 9, zero elsewhere: 88 degrees of turning. -/
def sideRoadYaw (k : Nat) : Q :=
  if 6 ≤ k && k ≤ 9 then Units.degrees 22 else Q.zero

/-- `holds` (compliant): A car travelling north at 6 m/s turns left through 176 degrees over 12 s
    and travels south; its speed never falls below the motion tolerance. -/
def holdsTrace : Trace := leg reversalPath reversalHeading reversalYaw

/-- `fails` (violated): The same car turns left through 88 degrees into a side road: the course
    change is far below the band, so it has not turned about. -/
def failsTrace : Trace := leg sideRoadPath sideRoadHeading sideRoadYaw

/-- `blind` (unknown): The source declares kin.yaw_rate absent, so prim.heading_change is unknown
    over the window and the reversal cannot be read. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (from_ to_ : Timestamp) (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := some (from_, to_) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant 14000 17000
  , witness "fails" failsTrace .violated 14000 17000
  , witness "blind" blindTrace (.unknown []) 14000 17000 ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.direction_reversal
