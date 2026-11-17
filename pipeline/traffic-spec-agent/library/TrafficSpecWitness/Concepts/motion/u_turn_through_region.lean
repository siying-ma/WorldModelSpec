/-
  Witnesses for drv.motion.u_turn_through_region.

  Geometry (every figure here is the witness's own):
    - region r = 100, a roundabout, the square (0,0)–(40,40) m.
    - road user a = track 1, a motor vehicle of half-extent 2 m × 1 m × 1 m, speed 10 m/s.
    - six scenes, one per second (t = 0 … 5000 ms); occupancy is derived from the geometry.
      k0 (-10,10) east, outside r;  k1 (5,10) east, inside r: the entry.
      holds/blind: k2 (30,20) north, yaw 90°/s; k3 (20,30) west, yaw 90°/s;
                   k4 (-10,30) west, outside r: the exit; k5 (-20,30) west.
                   Heading change since the entry: Σ yaw·dt over k2…k4 = 90 + 90 + 0 = 180°.
      fails:       k2 (20,20) north, yaw 90°/s; k3 (20,30) north; k4 (20,50) north, outside r:
                   the exit; k5 (20,60) north. Heading change since the entry: 90°.
    - each scenario judges the exit instant only (window 4000–4000 ms): the concept is an event
      recognized at the exit, and is false at every other observation by its own contract.
  Instance: step = 1 s (the scenes' spacing), u_turn_min = 150°, so the band is [150°, 210°].
  blind masks kin.yaw_rate: the integral since the entry is unknown, and so is the concept.
-/
import TrafficSpec.Concepts.motion.u_turn_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.u_turn_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100 (a roundabout, in every scene)

def inst : Concept.Instance :=
  { name := "drv.motion.u_turn_through_region@w"
    concept := "drv.motion.u_turn_through_region"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 1) .second), ("u_turn_min", .lit (Units.degrees 150) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The roundabout region r. -/
def roundabout : Structure := Build.rect 100 .roundabout (m 0) (m 0) (m 40) (m 40)

/-- Road user a at a position, with a heading and a yaw rate (deg/s). -/
def userA (pos : Vec) (h : Vec) (yaw : Int) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos h (Units.metresPerSecond 10) (m 2, m 1, m 1))
    fun k => { k with yawRate := some (Units.degrees yaw) }

/-- a's pose at scene k of the reversal: enters heading east, leaves heading west. -/
def reversal (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m (-10), m 10) Build.east 0
  | 1 => userA (m 5, m 10) Build.east 0
  | 2 => userA (m 30, m 20) Build.north 90
  | 3 => userA (m 20, m 30) Build.west 90
  | 4 => userA (m (-10), m 30) Build.west 0
  | _ => userA (m (-20), m 30) Build.west 0

/-- a's pose at scene k of the quarter turn: enters heading east, leaves heading north. -/
def quarter (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m (-10), m 10) Build.east 0
  | 1 => userA (m 5, m 10) Build.east 0
  | 2 => userA (m 20, m 20) Build.north 90
  | 3 => userA (m 20, m 30) Build.north 0
  | 4 => userA (m 20, m 50) Build.north 0
  | _ => userA (m 20, m 60) Build.north 0

/-- `holds` (compliant): Region r is a roundabout region. Road user a enters r heading east, circulates counter-clockwise and leaves r heading west, its yaw rate observed at every scene at the sampling standard: the magnitude of its heading change since the entry is a half turn, inside the band, so the concept holds at the exit. -/
def holdsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [reversal k] [roundabout] []

/-- `fails` (violated): Same region; a enters heading east and leaves heading north after a quarter turn to the left: the magnitude of its heading change is below u_turn_min, so the concept does not hold at the exit. -/
def failsTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [quarter k] [roundabout] []

/-- `blind` (unknown): As in holds, but a's yaw rate is missing at the scenes inside r: the heading change since the entry is unknown, and so is the concept at the exit. -/
def blindTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [reversal k] [roundabout] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some (4000, 4000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.u_turn_through_region
