/-
  Witnesses for drv.motion.right_turn_through_region.

  One car, track 1, half-extent 2.25 m × 0.9 m × 0.75 m, at 8 m/s; one intersection, region 100,
  the rectangle from (0, -10) to (20, 10) m; no devices. Five observations one second apart
  (t = 0 … 4000 ms): at t = 0 the car is west of the intersection at (-5, 0) heading east; at
  t = 1000 it is inside at (3, 0), still heading east (the entry); at t = 2000 and 3000 it is
  inside, turning; at t = 4000 it is outside (the exit). Occupancy follows the geometry.

  The instance gives `step` 1 s (the sampling interval, which is not longer), `min_angle`
  45 degrees and `max_angle` 180 degrees. Every scenario is judged at the exit observation only
  (`window` = [4000, 4000]), the one observation at which the concept can hold.

  - holds: the car turns right: (10, -1) heading (4/5, -3/5), (14, -6) heading (3/5, -4/5),
    (15, -13) heading south (each chord no longer than the 8 m of path between observations);
    yaw rate 0 at the first two observations and -30 deg/s after, so the heading change since
    the entry at the exit is -90 degrees, within (-180, -45].
  - fails: the mirror image: the car leaves heading north through (15, 13), yaw rate +30 deg/s,
    a change of +90 degrees, a left turn.
  - blind: the right turn of holds, with kin.yaw_rate declared absent by the source and its field
    left unobserved: the exit is decided, the heading change since entry is not.
-/
import TrafficSpec.Concepts.motion.right_turn_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.right_turn_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: i ↦ 100

/-- The instance every scenario speaks about: `step` 1 s, `min_angle` 45 degrees, `max_angle`
    180 degrees. -/
def inst : Concept.Instance :=
  { name := "drv.motion.right_turn_through_region@w"
    concept := "drv.motion.right_turn_through_region"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 1) .second),
               ("min_angle", .lit (Units.degrees 45) .degree),
               ("max_angle", .lit (Units.degrees 180) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The intersection, region 100. -/
def intersection : Structure := Build.rect 100 .intersection (m 0) (m (-10)) (m 20) (m 10)

/-- The car's position at observation `k` of a turn; `sgn` is -1 for a right turn, +1 for a left. -/
def turnPosition (sgn : Int) : Nat → Vec
  | 0 => (m (-5), m 0)
  | 1 => (m 3, m 0)
  | 2 => (m 10, m sgn)
  | 3 => (m 14, m (6 * sgn))
  | _ => (m 15, m (13 * sgn))

/-- The car's heading at observation `k` of a turn: east, east, then round to south or north. -/
def turnHeading (sgn : Int) : Nat → Vec
  | 0 => Build.east
  | 1 => Build.east
  | 2 => (Units.ratio 4 5, Units.ratio (3 * sgn) 5)
  | 3 => (Units.ratio 3 5, Units.ratio (4 * sgn) 5)
  | _ => (Q.zero, Q.ofInt sgn)

/-- The yaw rate at observation `k`: none while straight, 30 deg/s to the hand of the turn after. -/
def turnYaw (sgn : Int) : Nat → Q
  | 0 => Q.zero
  | 1 => Q.zero
  | _ => Units.degrees (30 * sgn)

def turnTrace (sgn : Int) (yaw : Bool) : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (turnPosition sgn k) (turnHeading sgn k)
            (Units.metresPerSecond 8) carExtent (some (m (8 * k))))
          (fun kin => { kin with yawRate := if yaw then some (turnYaw sgn k) else none }) ]
      [ intersection ]
      [ ]

/-- `holds` (compliant): A car enters an intersection heading east and leaves it heading south, a heading change of about 90 degrees to the right. -/
def holdsTrace : Trace := turnTrace (-1) true

/-- `fails` (violated): The car enters heading east and leaves heading north. -/
def failsTrace : Trace := turnTrace 1 true

/-- `blind` (unknown): The car leaves the intersection; the source supplies no yaw rate. -/
def blindTrace : Trace := turnTrace (-1) false

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("i", 100)]
    expected := expected
    window := some (4000, 4000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.right_turn_through_region
