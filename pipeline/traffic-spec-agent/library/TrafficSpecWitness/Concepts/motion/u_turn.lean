/-
  Witnesses for drv.motion.u_turn.

  The instance fills the three formal parameters with figures of this file's own: a window of 10
  seconds, long enough to span a reversal made in several movements (a swing, a halt, a reverse and
  a pull away); min_heading_change 150 degrees, a change short of a half turn at which the
  direction of travel counts as reversed; max_heading_change 300 degrees, a change well beyond a
  half turn and short of the full circle that restores the direction a body set out in.

  Every trace runs one observation a second (dt = 1 s), which the primitive's adequacy test accepts
  for a 10 second window (the largest gap must be at most half the window). The back window is
  truncated before t = 10 s on every finite trace, so each scenario names the instants it speaks
  about with `window`: the heading change over the 10 seconds behind is formed at t = 10 s and
  after, and nothing before that is decided either way.

  In every trace the one road user is the car, track 1, 4.5 m long, 1.8 m wide and 1.5 m tall, the
  subject of the scene and the road user the formal `u` is grounded to. Region 100 is the public
  way — a `highway` region, the entire way between its boundary lines — and the car's footprint lies
  wholly inside it at every observation of every trace, so the first conjunct is true throughout and
  the band on the heading change is what decides each witness.

  `holdsTrace` (compliant, 14 observations, t = 0 … 13 s) — a two-way street, region 100 running
  120 m east-west and 16 m wide. The car comes east along the right-hand side at 10 m/s, slows to
  walking pace by t = 3 s, swings left across the centre of the way through t = 4 … 6 s (yaw rates
  40, 45 and 40 degrees a second, 125 degrees of heading), stands still with its nose at the far
  kerb at t = 7 s (no yaw), backs once at t = 8 s with its wheels turned (17 degrees more) and comes
  forward again at t = 9 s (30 degrees more), leaving it at 172 degrees from the heading it had at
  t = 3 s and running back west the way it came. From t = 10 s to t = 13 s the whole turn lies inside
  the 10 seconds behind and no part of it has fallen out, so the integrated change is 172 degrees at
  every one of those four observations: at least 150 and at most 300, and the car is on the way.

  `failsTrace` (violated, 13 observations, t = 0 … 12 s) — a wide public way, region 100 running
  120 m east-west and 40 m deep, on which the car sweeps round a complete circle of radius 16 m at
  10 m/s, yawing steadily 36 degrees a second to the left, a revolution every 10 seconds. At
  t = 10 s, 11 s and 12 s the integrated change over the window behind is exactly 360 degrees, above
  max_heading_change: the body is travelling again in the direction it set out in, no reversal is
  recognized, and the witness is violated though the car's footprint is on the way throughout.

  `blindTrace` is the street and the manoeuvre of `holdsTrace`, judged with kin.yaw_rate masked: the
  signed heading change cannot be integrated, so neither bound of the band decides, and the witness
  is unknown for that atom alone at the instants it names.
-/
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.u_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A yaw rate, in degrees a second, left positive. -/
def degPerSec (n : Int) : Q := Units.degrees n
def mps (n : Int) : Q := Units.metresPerSecond n
/-- A heading from its components in ten-thousandths; it is read as a direction only. `dir 7660
    6428` is 40 degrees left of due east. -/
def dir (x y : Int) : Vec := (Units.ratio x 10000, Units.ratio y 10000)
/-- The car: 4.5 m long, 1.8 m wide, 1.5 m tall. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a window of 10 seconds, a reversal recognized from
    150 degrees of integrated change, and read no longer as a reversal above 300. -/
def inst : Concept.Instance :=
  { name := "drv.motion.u_turn@w"
    concept := "drv.motion.u_turn"
    literals := []
    nats := []
    params :=
      [ ("window", .lit (Units.seconds 10) .second)
      , ("min_heading_change", .lit (Units.degrees 150) .degree)
      , ("max_heading_change", .lit (Units.degrees 300) .degree) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The two maps: the two-way street of the reversal, and the wide way of the circle
-- ---------------------------------------------------------------------------------------------
/-- The public way of `holdsTrace` and `blindTrace`: 120 m of street, 16 m between its boundary
    lines, sidewalks and shoulders included. -/
def street : Structure := Build.rect 100 .highway (m (-60)) (m (-8)) (m 60) (m 8)

/-- The public way of `failsTrace`: 120 m by 40 m, wide enough for the circle the car sweeps. -/
def wideWay : Structure := Build.rect 100 .highway (m (-60)) (m (-20)) (m 60) (m 20)

-- ---------------------------------------------------------------------------------------------
-- The car of the reversal: its yaw rate, heading, position and speed at each observation
-- ---------------------------------------------------------------------------------------------
/-- The yaw rate of the car of `holdsTrace` at observation `k`: zero while it runs straight, left
    through the swing (t = 4 … 6 s), zero at the standstill, left again while it backs and comes
    forward. The rates inside the 10 seconds behind t = 10 … 13 s sum to 172 degrees. -/
def holdsYaw (k : Nat) : Q :=
  match k with
  | 4 => degPerSec 40
  | 5 => degPerSec 45
  | 6 => degPerSec 40
  | 8 => degPerSec 17
  | 9 => degPerSec 30
  | _ => Q.zero

/-- The heading of that car: due east, then 40, 85 and 125 degrees left of east through the swing,
    held at 125 while it stands, 142 while it backs, and 172 — back the way it came — from the
    moment it comes forward again. -/
def holdsHeading (k : Nat) : Vec :=
  match k with
  | 0 | 1 | 2 | 3 => dir 10000 0
  | 4 => dir 7660 6428
  | 5 => dir 872 9962
  | 6 | 7 => dir (-5736) 8192
  | 8 => dir (-7880) 6157
  | _ => dir (-9903) 1392

/-- Its position: east along the right-hand side of the way, across the centre, a nose at the far
    kerb, and away again to the west. -/
def holdsPos (k : Nat) : Vec :=
  match k with
  | 0 => (m (-20), m (-2))
  | 1 => (m (-12), m (-2))
  | 2 => (m (-6), m (-2))
  | 3 => (m (-3), m (-2))
  | 4 => (cm (-100), cm (-150))
  | 5 => (cm 50, m 0)
  | 6 => (cm 150, cm 150)
  | 7 => (m 2, cm 250)
  | 8 => (cm 150, cm 250)
  | 9 => (cm 50, m 3)
  | 10 => (m (-3), m 3)
  | 11 => (m (-9), m 3)
  | 12 => (m (-17), m 3)
  | _ => (m (-27), m 3)

/-- Its speed: 10 m/s on the approach, walking pace through the turn, a standstill at the kerb, and
    10 m/s again on the way back. -/
def holdsSpeed (k : Nat) : Q :=
  match k with
  | 0 => mps 10
  | 1 => mps 8
  | 2 => mps 5
  | 3 => mps 3
  | 4 | 5 => mps 2
  | 6 => mps 1
  | 7 => Q.zero
  | 8 => mps 1
  | 9 => mps 2
  | 10 => mps 5
  | 11 => mps 7
  | 12 => mps 8
  | _ => mps 10

/-- The car of the reversal at observation `k`. -/
def holdsCar (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (holdsPos k) (holdsHeading k) (holdsSpeed k) carExtent)
    fun kin => { kin with yawRate := some (holdsYaw k) }

-- ---------------------------------------------------------------------------------------------
-- The car of the circle: a revolution every ten seconds, 36 degrees a second to the left
-- ---------------------------------------------------------------------------------------------
/-- The heading of the circling car, 36 degrees further left at each observation. -/
def circleHeading (k : Nat) : Vec :=
  match k % 10 with
  | 0 => dir 10000 0
  | 1 => dir 8090 5878
  | 2 => dir 3090 9511
  | 3 => dir (-3090) 9511
  | 4 => dir (-8090) 5878
  | 5 => dir (-10000) 0
  | 6 => dir (-8090) (-5878)
  | 7 => dir (-3090) (-9511)
  | 8 => dir 3090 (-9511)
  | _ => dir 8090 (-5878)

/-- Its position on a circle of radius 16 m about the middle of the wide way, a quarter turn behind
    its heading. -/
def circlePos (k : Nat) : Vec :=
  match k % 10 with
  | 0 => (m 0, m (-16))
  | 1 => (cm 940, cm (-1294))
  | 2 => (cm 1522, cm (-494))
  | 3 => (cm 1522, cm 494)
  | 4 => (cm 940, cm 1294)
  | 5 => (m 0, m 16)
  | 6 => (cm (-940), cm 1294)
  | 7 => (cm (-1522), cm 494)
  | 8 => (cm (-1522), cm (-494))
  | _ => (cm (-940), cm (-1294))

/-- The circling car at observation `k`: 10 m/s round a 16 m circle, yawing 36 degrees a second. -/
def circleCar (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (circlePos k) (circleHeading k) (mps 10) carExtent)
    fun kin => { kin with yawRate := some (degPerSec 36) }

-- ---------------------------------------------------------------------------------------------
-- The traces
-- ---------------------------------------------------------------------------------------------
/-- `holds` (compliant): A car on a two-way street slows, swings left across the centre of the way,
    stands with its nose at the far kerb, backs once and comes forward the way it came; over the 10
    seconds behind each of t = 10 … 13 s the integrated heading change is 172 degrees, inside the
    band, and its footprint is on the way throughout. -/
def holdsTrace : Trace :=
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ holdsCar k ] [ street ] []

/-- `fails` (violated): A car sweeps round a complete circle on a wide public way, yawing steadily
    to the left until it is travelling again in the direction it set out in: the integrated heading
    change over the window behind is 360 degrees, above max_heading_change, so no reversal is
    recognized even though its footprint is on the way throughout. -/
def failsTrace : Trace :=
  Build.trace 13 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ circleCar k ] [ wideWay ] []

/-- `blind` (unknown): The car reverses its direction in the street as in `holds`, but the source
    declares the yaw rate absent, so the integrated heading change cannot be formed and neither
    bound of the band can be decided. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict) (from_ to : Timestamp)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := some (from_, to) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant 10000 13000
  , witness "fails" failsTrace .violated 10000 12000
  , witness "blind" blindTrace (.unknown []) 10000 13000 ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.u_turn
