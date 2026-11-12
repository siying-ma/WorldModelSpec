/-
  Witnesses for drv.motion.u_turn.

  The instance: window 10 s, the reversal band 160° … 200°.

  One car (track 1, half-extent 2.5 m × 1 m × 0.75 m), sampled every second, no map.

  `holds`: 21 scenes, t = 0 … 20 s. For t = 0 … 9 s it drives east at 3 m/s with no yaw, so the
  10 s window is covered from t = 10 s. It then turns in three movements, each at 30°/s to the
  left: forward at t = 10 … 12 s (heading 30°, 60°, 90°), reverse (gear −1, 2 m/s) at t = 13, 14 s
  (120°, 150°), forward again at t = 15 s (180°, west), and drives west at 3 m/s with no yaw after.
  The heading change over the window is 120° at t = 13 s, 150° at 14 s, 180° from 15 s to 19 s
  (the whole turn lies in the window), 150° at 20 s. The judged instants are t = 15 … 19 s.

  `fails`: 13 scenes, t = 0 … 12 s; the car backs west along the road (heading east, gear −1,
  2 m/s) with no yaw: the heading change is 0°. The judged instants are t = 10 … 12 s, where the
  window is covered.

  `blind`: the `holds` trace with kin.yaw_rate declared absent, judged at t = 15 … 19 s.
-/
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.u_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a 10 s window, the band 160° … 200°. -/
def inst : Concept.Instance :=
  { name := "drv.motion.u_turn@w"
    concept := "drv.motion.u_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 10) .second), ("min_angle", .lit (Units.degrees 160) .degree), ("max_angle", .lit (Units.degrees 200) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 250, m 1, cm 75)

/-- A car at a position and heading, moving at `speed` forward (gear 1) or in reverse (gear −1),
    turning at `yaw` degrees per second. -/
def car (pos : Vec) (heading : Vec) (speed : Q) (gear : Int) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading speed carExtent) fun k =>
    { k with velocity := some (Build.scale heading (if gear < 0 then Q.neg speed else speed))
             gear := some gear
             yawRate := some yaw }

def fwd : Q := Units.metresPerSecond 3
def rev : Q := Units.metresPerSecond 2

/-- The three-point turn at scene k (one scene a second). -/
def turnCar (k : Nat) : RoadUser :=
  if k < 10 then car (m (-30 + 3 * (k : Int)), m 0) Build.east fwd 1 (Units.degrees 0)
  else if k = 10 then car (m 0, m 1) (Units.ratio 2 1, Units.ratio 1 1) fwd 1 (Units.degrees 30)
  else if k = 11 then car (m 2, m 3) (Units.ratio 1 1, Units.ratio 2 1) fwd 1 (Units.degrees 30)
  else if k = 12 then car (m 2, m 6) Build.north fwd 1 (Units.degrees 30)
  else if k = 13 then car (m 3, m 4) (Units.ratio (-1) 1, Units.ratio 2 1) rev (-1) (Units.degrees 30)
  else if k = 14 then car (m 4, m 3) (Units.ratio (-2) 1, Units.ratio 1 1) rev (-1) (Units.degrees 30)
  else if k = 15 then car (m 1, m 4) Build.west fwd 1 (Units.degrees 30)
  else car (m (1 - 3 * ((k : Int) - 15)), m 4) Build.west fwd 1 (Units.degrees 0)

/-- `holds` (compliant): A vehicle reverses its direction by a forward, a reverse and a forward movement within the window; the magnitude of its heading change reaches the band. -/
def holdsTrace : Trace :=
  Build.trace 21 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [turnCar k] [] []

/-- `fails` (violated): A vehicle backs along the road with no change of heading. -/
def failsTrace : Trace :=
  Build.trace 13 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [car (m (30 - 2 * (k : Int)), m 0) Build.east rev (-1) (Units.degrees 0)]
      [] []

/-- `blind` (unknown): The source declares kin.yaw_rate absent. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (window : Option (Timestamp × Timestamp)) (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant (some (15000, 19000))
  , witness "fails" failsTrace .violated (some (10000, 12000))
  , witness "blind" blindTrace (.unknown []) (some (15000, 19000)) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.u_turn
