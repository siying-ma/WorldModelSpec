/-
  Witnesses for drv.motion.heading_change_since_entry.

  Geometry: region r (id 100) is an intersection, the square x ∈ [0, 20] m, y ∈ [-10, 10] m. Road
  user a (track 1) is a motor vehicle of half-extent 2 × 1 × 1 m, moving at 5 m/s; seven
  observations one second apart (t = 0 … 6 s). a is outside r at t = 0, 1 s, inside at t = 2, 3,
  4 s (its occupancy rises at t = 2 s: the entry, where the value is zero) and outside again at
  t = 5, 6 s.

  The instance: step bound 2 s (above the 1 s sampling, so no interval exceeds it); the value is
  bounded to the left band [60°, 120°]. Each scenario is judged at the exit, t ∈ [5 s, 6 s].

  - holds: a enters heading east, yaws left at 30 deg/s at t = 3, 4, 5 s (each rate held over the
    second before it; its heading turns through (4/5, 3/5) and (3/5, 4/5) to north) and leaves r;
    the value at the exit is 3 × 30 × 1 = 90°, inside the band.
  - fails: a crosses r heading east with zero yaw rate; the value at the exit is 0°, below the band.
  - blind: the holds trace with kin.yaw_rate masked: the integral since the entry lacks its rates.
-/
import TrafficSpec.Concepts.motion.heading_change_since_entry
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.heading_change_since_entry

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100 (the intersection of every trace)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.motion.heading_change_since_entry@w"
    concept := "drv.motion.heading_change_since_entry"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 2) .second)]
    bounds := some (.lit (Units.degrees 60) .degree, .lit (Units.degrees 120) .degree)
  }

def instances : List Concept.Instance := [inst]

/-- Region r: an intersection 20 m square. -/
def regionR : Structure := Build.rect 100 .intersection (m 0) (m (-10)) (m 20) (m 10)

/-- Road user a at a position and heading, with a yaw rate in deg/s. -/
def userA (pos : Vec) (heading : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond 5) (m 2, m 1, m 1))
    fun k => { k with yawRate := some yaw }

/-- a turning left a quarter turn inside r: east at the entry, north at the exit. -/
def turningA : Nat → RoadUser
  | 0 => userA (m (-10), m 0) Build.east (Units.degrees 0)
  | 1 => userA (m (-5), m 0) Build.east (Units.degrees 0)
  | 2 => userA (m 4, m 0) Build.east (Units.degrees 0)
  | 3 => userA (m 10, m 2) (Units.ratio 4 5, Units.ratio 3 5) (Units.degrees 30)
  | 4 => userA (m 12, m 6) (Units.ratio 3 5, Units.ratio 4 5) (Units.degrees 30)
  | 5 => userA (m 12, m 14) Build.north (Units.degrees 30)
  | _ => userA (m 12, m 20) Build.north (Units.degrees 0)

/-- a crossing r straight east without yawing. -/
def straightA (k : Nat) : RoadUser :=
  userA (m (-10 + 7 * (k : Int)), m 0) Build.east (Units.degrees 0)

/-- `holds` (compliant): a enters r heading along one axis, turns left a quarter turn inside r and leaves it; the instance bounds the value to a left band and the value read at the exit lies within it. -/
def holdsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [turningA k] [regionR] []

/-- `fails` (violated): a crosses r without turning; the value read at the exit stays near zero, outside the instance's left band. -/
def failsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [straightA k] [regionR] []

/-- `blind` (unknown): as in holds, but the source supplies no yaw rate, so the heading change is unknown. -/
def blindTrace : Trace := holdsTrace

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
    window := some (5000, 6000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.heading_change_since_entry
