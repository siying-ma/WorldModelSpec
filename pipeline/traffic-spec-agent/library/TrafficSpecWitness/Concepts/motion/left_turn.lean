/-
  Witnesses for drv.motion.left_turn.

  Geometry (every figure here is the witness's own):
    - road user a = track 1, a bicycle of half-extent 1 m × 30 cm × 1 m, speed 5 m/s; no
      structures, no devices.
    - thirty scenes, one per second (t = 0 … 29000 ms). Headings are direction vectors given to
      the nearest thousandth of (cos θ, sin θ); the yaw rate at a scene is held over the interval
      before it, so each heading is the one before turned by that rate times 1 s. Positions
      advance by the heading times 5 m per scene.
      holds/blind: k 0…14 east, yaw 0; k 15…20 yaw 15°/s, headings 15°, 30°, …, 90°;
                   k 21…29 north, yaw 0. At k = 21 (21000 ms) the window behind (10 s) spans
                   k 11…21: heading change 6 × 15° = 90°, yaw 0 — the first such observation
                   (at k = 20 the yaw rate is 15°/s): the concept holds.
      fails:       k 0…14 east, yaw 0; k 15, 16 yaw +5°/s, headings 5°, 10°; k 17, 18 yaw −5°/s,
                   headings 5°, 0°; k 19…29 east, yaw 0. The heading change over every covered
                   window is at most 10°, below turn_min: the concept never holds.
    - holds and blind judge the recognition instant (21000 ms); fails judges every covered
      instant (10000 … 29000 ms).
  Instance: window = 10 s, turn_min = 45°, u_turn_min = 150°, yaw_tol = 1 °/s.
  blind masks kin.yaw_rate: at 21000 ms neither the heading change nor the yaw rate is known.
-/
import TrafficSpec.Concepts.motion.left_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

def inst : Concept.Instance :=
  { name := "drv.motion.left_turn@w"
    concept := "drv.motion.left_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 10) .second),
               ("turn_min", .lit (Units.degrees 45) .degree),
               ("u_turn_min", .lit (Units.degrees 150) .degree),
               ("yaw_tol", .lit (Units.degrees 1) .degreePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A heading direction from thousandths of (cos θ, sin θ). -/
def dir (c s : Int) : Vec := (Units.ratio c 1000, Units.ratio s 1000)

/-- Heading at 0°, 5°, 10°, 15°, …, 90° (to the nearest thousandth). -/
def h0 : Vec := dir 1000 0
def h5 : Vec := dir 996 87
def h10 : Vec := dir 985 174
def h15 : Vec := dir 966 259
def h30 : Vec := dir 866 500
def h45 : Vec := dir 707 707
def h60 : Vec := dir 500 866
def h75 : Vec := dir 259 966
def h90 : Vec := dir 0 1000

/-- The left turn: heading and yaw rate (deg/s) at scene k. -/
def turnPose (k : Nat) : Vec × Int :=
  if k < 15 then (h0, 0)
  else match k with
    | 15 => (h15, 15)
    | 16 => (h30, 15)
    | 17 => (h45, 15)
    | 18 => (h60, 15)
    | 19 => (h75, 15)
    | 20 => (h90, 15)
    | _ => (h90, 0)

/-- The lane change: heading and yaw rate (deg/s) at scene k. -/
def lanePose (k : Nat) : Vec × Int :=
  match k with
  | 15 => (h5, 5)
  | 16 => (h10, 5)
  | 17 => (h5, -5)
  | 18 => (h0, -5)
  | _ => (h0, 0)

/-- Position at scene k: each scene advances by its heading times 5 m. -/
def posOf (pose : Nat → Vec × Int) : Nat → Vec
  | 0 => (m 0, m 0)
  | k + 1 =>
    let p := posOf pose k
    let h := (pose (k + 1)).1
    (Q.add p.1 (Q.mul h.1 (m 5)), Q.add p.2 (Q.mul h.2 (m 5)))

/-- The bicycle at scene k of a pose sequence. -/
def bike (pose : Nat → Vec × Int) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.bicycle] (posOf pose k) (pose k).1 (Units.metresPerSecond 5) (m 1, cm 30, m 1))
    fun kk => { kk with yawRate := some (Units.degrees (pose k).2) }

/-- `holds` (compliant): A bicycle riding straight turns to the left at a constant yaw rate for 6 s, 90 degrees in total, then rides straight with zero yaw rate; the trace is observed at a steady interval from well before the window behind the recognition, and the bicycle's heading at every observation is its heading at the observation before turned by the yaw rate of this observation times the interval between them, so that heading and yaw rate agree. At the first observation with zero yaw rate after the turn, the heading change over the window behind is 90 degrees and the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 30 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [bike turnPose k] [] []

/-- `fails` (violated): A bicycle changes lane to the left: its yaw rate is positive for a few observations, turning its heading 10 degrees to the left, then negative for as many, turning it back; its heading at every observation is its heading at the observation before turned by the yaw rate of this observation times the interval between them. Over every covered window the heading change stays at or below 10 degrees, below turn_min, and the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 30 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [bike lanePose k] [] []

/-- `blind` (unknown): The holds trace, but the source does not observe the bicycle's yaw rate: at the observation where the turn would be recognized, neither the heading change over the window behind nor the yaw rate is known, and the concept is unknown. -/
def blindTrace : Trace :=
  Build.trace 30 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [bike turnPose k] [] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (win : Timestamp × Timestamp) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected
    window := some win }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (21000, 21000)
  , witness "fails" failsTrace .violated [] (10000, 29000)
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (21000, 21000) ]

end TrafficSpecWitness.Concepts.motion.left_turn
