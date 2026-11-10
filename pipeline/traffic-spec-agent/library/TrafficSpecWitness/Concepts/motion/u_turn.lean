/-
  Witnesses for drv.motion.u_turn.

  One car (track 1), observed once a second over 30 s (t = 0 … 29 000 ms), no structures, no
  devices. The instance: window 10 s, band 150° … 210°.

  holds: the car approaches heading east at 2 m/s (k ≤ 11), then makes a three-point turn at 1 m/s:
  forward left k = 12 … 14 (to north), backing with the wheels turned the other way k = 15, 16 (the
  heading keeps coming round to the left), forward left k = 17 (to west); yaw rate 30 °/s at each of
  those six observations, so 180° in all. It then drives west at 2 m/s. The 10 s window's change is
  180° at k = 17 … 21; the scenario speaks about t = 17 000 … 21 000 ms, every window covered.
  Intermediate headings are the unit vectors (4/5, 3/5), (3/5, 4/5), (-3/5, 4/5), (-4/5, 3/5).

  fails: the same approach, then a left turn at a junction, yaw rate 30 °/s at k = 12 … 14 only
  (90°), then north at 2 m/s. Over t = 17 000 … 21 000 ms the window's change is 90°, short of the
  band.

  blind: the holds trace with kin.yaw_rate declared absent, over the same instants.
-/
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.u_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a 10 s window, a band of 150° … 210°. -/
def inst : Concept.Instance :=
  { name := "drv.motion.u_turn@w"
    concept := "drv.motion.u_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 10) .second), ("min_angle", .lit (Units.degrees 150) .degree),
               ("max_angle", .lit (Units.degrees 210) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A car's half-length, half-width, half-height. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- Unit headings between the cardinal ones, as the turn comes round to the left. -/
def h1 : Vec := (Units.ratio 4 5, Units.ratio 3 5)
def h2 : Vec := (Units.ratio 3 5, Units.ratio 4 5)
def h4 : Vec := (Units.ratio (-3) 5, Units.ratio 4 5)
def h5 : Vec := (Units.ratio (-4) 5, Units.ratio 3 5)

/-- The car at observation k: position, heading, speed, yaw rate (°/s), and whether it is backing. -/
def car (pos : Vec) (heading : Vec) (speed : Q) (yaw : Q) (backing : Bool) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading speed carExtent) fun k =>
    { k with yawRate := some yaw
             gear := some (if backing then -1 else 1)
             velocity := some (Build.scale heading (if backing then Q.neg speed else speed)) }

/-- The three-point turn: six observations at 30 °/s, the middle two backing. -/
def threePoint (k : Nat) : RoadUser :=
  let turn := Units.degrees 30
  if k ≤ 11 then car (m (2 * (Int.ofNat k) - 22), m (-2)) Build.east (Units.metresPerSecond 2) (Units.degrees 0) false
  else if k = 12 then car (m 2, m (-1)) h1 (Units.metresPerSecond 1) turn false
  else if k = 13 then car (m 3, m 1) h2 (Units.metresPerSecond 1) turn false
  else if k = 14 then car (m 3, m 3) Build.north (Units.metresPerSecond 1) turn false
  else if k = 15 then car (m 4, m 2) h4 (Units.metresPerSecond 1) turn true
  else if k = 16 then car (m 5, m 1) h5 (Units.metresPerSecond 1) turn true
  else if k = 17 then car (m 3, m 2) Build.west (Units.metresPerSecond 1) turn false
  else car (m (3 - 2 * (Int.ofNat k - 17)), m 2) Build.west (Units.metresPerSecond 2) (Units.degrees 0) false

/-- The left turn at a junction: three observations at 30 °/s, then straight on north. -/
def leftTurn (k : Nat) : RoadUser :=
  let turn := Units.degrees 30
  if k ≤ 11 then car (m (2 * (Int.ofNat k) - 22), m (-2)) Build.east (Units.metresPerSecond 2) (Units.degrees 0) false
  else if k = 12 then car (m 2, m (-1)) h1 (Units.metresPerSecond 1) turn false
  else if k = 13 then car (m 3, m 1) h2 (Units.metresPerSecond 1) turn false
  else if k = 14 then car (m 3, m 3) Build.north (Units.metresPerSecond 1) turn false
  else car (m 3, m (3 + 2 * (Int.ofNat k - 14))) Build.north (Units.metresPerSecond 2) (Units.degrees 0) false

/-- `holds` (compliant): A car makes a three-point turn within the window and ends heading the opposite way. -/
def holdsTrace : Trace :=
  Build.trace 30 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [threePoint k] [] []

/-- `fails` (violated): A car turns left at a junction; its heading change stays short of a reversal. -/
def failsTrace : Trace :=
  Build.trace 30 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [leftTurn k] [] []

/-- `blind` (unknown): As holds, with kin.yaw_rate declared absent. -/
def blindTrace : Trace := holdsTrace

/-- The instants the scenarios speak about: every window behind them lies inside the trace. -/
def judged : Option (Timestamp × Timestamp) := some (17000, 21000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := judged }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.u_turn
