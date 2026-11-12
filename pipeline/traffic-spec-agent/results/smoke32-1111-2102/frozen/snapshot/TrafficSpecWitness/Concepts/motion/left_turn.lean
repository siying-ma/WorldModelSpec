/-
  Witnesses for drv.motion.left_turn.

  One car, track 1, the subject, observed every second at t = 0 … 8 s (nine instants); no region and
  no device. The car (half-extent 2.25 m × 0.9 m × 0.75 m) moves at 5 m/s from the origin along its
  heading. The body reads only `kin.yaw_rate` (through `prim.heading_change`); the heading is drawn
  from rational unit vectors near the integrated yaw rate (about 20° per second left in `holds`,
  east, then about 4°, 8°, 4° left of east and east again in the lane change of `fails`), and the
  yaw rate is the figure each scenario is about.

  The instance: window 4 s, lower bound 30°, upper bound 150°. With samples 1 s apart the window is
  adequately sampled (≤ window/2), and it is covered from t = 4 s on (the oldest sample in it, t − 4 s,
  is exactly the window behind); each scenario is judged over [4 s, 8 s], so no window is truncated.
  The heading change at t is Σ yaw rate × 1 s over the four samples after t − 4 s.

    holds — yaw rate 20°/s throughout: 80° over every window, inside [30°, 150°].
    fails — a lane change to the left: yaw rate 0, 0, 0, 4, 4, −4, −4, 0, 0 °/s; the change over the
            window is 8°, 4°, 0°, −4°, −8° at t = 4 … 8 s, below 30° throughout.
    blind — the holds trace with `kin.yaw_rate` declared absent: every window misses its yaw rates.
-/
import TrafficSpec.Concepts.motion.left_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a 4 s window and a turn band of 30° to 150°. -/
def inst : Concept.Instance :=
  { name := "drv.motion.left_turn@w"
    concept := "drv.motion.left_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 4) .second),
               ("min_angle", .lit (Units.degrees 30) .degree),
               ("max_angle", .lit (Units.degrees 150) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A rational unit heading at roughly 20° × k left of east (Pythagorean triples), for the turning car. -/
def turnHeading (k : Nat) : Vec :=
  match k with
  | 0 => Build.east
  | 1 => (Units.ratio 24 25, Units.ratio 7 25)
  | 2 => (Units.ratio 4 5, Units.ratio 3 5)
  | 3 => (Units.ratio 3 5, Units.ratio 4 5)
  | 4 => (Units.ratio 7 25, Units.ratio 24 25)
  | 5 => (Units.ratio (-7) 25, Units.ratio 24 25)
  | 6 => (Units.ratio (-3) 5, Units.ratio 4 5)
  | 7 => (Units.ratio (-4) 5, Units.ratio 3 5)
  | _ => (Units.ratio (-24) 25, Units.ratio 7 25)

/-- The position at instant `k` of a car that moves 5 m per second along `heading`. -/
def posAlong (heading : Nat → Vec) : Nat → Vec
  | 0 => (m 0, m 0)
  | k + 1 => let p := posAlong heading k
             (Q.add p.1 (Q.mul (heading k).1 (m 5)), Q.add p.2 (Q.mul (heading k).2 (m 5)))

/-- The car at instant `k`: heading, 5 m/s, a 2.25 m × 0.9 m × 0.75 m half-extent, and its yaw rate
    (degrees per second). -/
def car (heading : Nat → Vec) (k : Nat) (yaw : Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (posAlong heading k) (heading k) (Units.metresPerSecond 5)
      (cm 225, cm 90, cm 75))
    fun kin => { kin with yawRate := some yaw }

/-- The instants judged: the windows behind them are covered. -/
def judged : Timestamp × Timestamp := (4000, 8000)

/-- `holds` (compliant): Within the window a vehicle's heading turns left by an angle inside the band. -/
def holdsTrace : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car turnHeading k (Units.degrees 20) ]
      [ ]
      [ ]

/-- The lane change's yaw rate (degrees per second) at instant `k`: left, then back. -/
def laneChangeYaw (k : Nat) : Q :=
  if k = 3 || k = 4 then Units.degrees 4
  else if k = 5 || k = 6 then Units.degrees (-4)
  else Units.degrees 0

/-- The lane change's heading at instant `k`, integrated from `laneChangeYaw` (the rate at a scene is
    held over the interval before it): east, then about 4°, 8°, 4° left of east, then east again. -/
def laneChangeHeading (k : Nat) : Vec :=
  if k = 3 || k = 5 then (Units.ratio 420 421, Units.ratio 29 421)
  else if k = 4 then (Units.ratio 112 113, Units.ratio 15 113)
  else Build.east

/-- `fails` (violated): A vehicle changes lane to the left; its heading changes by less than the lower bound. -/
def failsTrace : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car laneChangeHeading k (laneChangeYaw k) ]
      [ ]
      [ ]

/-- `blind` (unknown): The source declares kin.yaw_rate absent. -/
def blindTrace : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car turnHeading k (Units.degrees 20) ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected
    window := some judged }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.left_turn
