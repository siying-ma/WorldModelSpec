/-
  Witnesses for drv.motion.heading_change_since_entry.

  Region r ↦ 100: an intersection, the square (0,0)–(20,20) m. Track x ↦ 1: a car, half-extents
  2.5 × 1 × 0.75 m, observed every second (t = 0 … 6 s, 7 scenes).

  `holds`: x approaches from the west along y = 15 heading east (t = 0 s at (-10,15), outside r),
  enters r at t = 1 s ((2,15), yaw rate 0), turns right with a yaw rate of -30 deg/s at t = 2, 3, 4 s
  (heading swinging from east to south), and is outside r heading south at t = 5 s ((15,-3), yaw
  rate 0), then at (15,-13) at t = 6 s. The yaw-rate samples since the entry are 0, -30, -30, -30, 0
  deg/s one second apart, so the change at the exit is -90 deg whichever rule integrates them.
  `fails`: x drives straight east along y = 10 with a yaw rate of 0 throughout: enters at t = 1 s,
  leaves at t = 3 s ((22,10)); the change at the exit is 0 deg.
  `blind`: the `holds` trace with kin.yaw_rate declared absent.

  Every scenario speaks about the exit instant (`window`): the value the narratives name. The
  instance: step = 2 s (twice the sampling interval); bounds [-100, -80] deg, a band about minus a
  right angle.
-/
import TrafficSpec.Concepts.motion.heading_change_since_entry
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.heading_change_since_entry

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: r ↦ 100 (the intersection, a structure of every scene)

/-- The instance every scenario speaks about: the sampling step bound 2 s, the value expected in
    [-100, -80] degrees. -/
def inst : Concept.Instance :=
  { name := "drv.motion.heading_change_since_entry@w"
    concept := "drv.motion.heading_change_since_entry"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 2) .second)]
    bounds := some (.lit (Units.degrees (-100)) .degree, .lit (Units.degrees (-80)) .degree)
  }

def instances : List Concept.Instance := [inst]

def intersection : Structure := Build.rect 100 .intersection (m 0) (m 0) (m 20) (m 20)

def car (pos : Vec) (heading : Vec) (yaw : Int) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond 8) (cm 250, m 1, cm 75))
    fun k => { k with yawRate := some (Units.degrees yaw) }

/-- Headings between east and south during the right turn. -/
def eastSouthEast : Vec := (Units.ratio 4 5, Units.ratio (-3) 5)
def southSouthEast : Vec := (Units.ratio 3 5, Units.ratio (-4) 5)

/-- x, scene by scene, through a right turn in the intersection. -/
def turningCar : Nat → RoadUser
  | 0 => car (m (-10), m 15) Build.east 0
  | 1 => car (m 2, m 15) Build.east 0
  | 2 => car (m 8, m 13) eastSouthEast (-30)
  | 3 => car (m 12, m 9) southSouthEast (-30)
  | 4 => car (m 14, m 4) Build.south (-30)
  | 5 => car (m 15, m (-3)) Build.south 0
  | _ => car (m 15, m (-13)) Build.south 0

/-- x, scene by scene, straight through the intersection. -/
def straightCar (k : Nat) : RoadUser :=
  car (m (8 * (Int.ofNat k) - 2), m 10) Build.east 0

/-- `holds` (compliant): x enters an intersection and turns a quarter turn to the right before leaving; the value at the exit lies in the band about minus a right angle that the instance's bounds state. -/
def holdsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [turningCar k] [intersection] []

/-- `fails` (violated): x drives straight through the intersection; the value at the exit stays near zero, outside that band. -/
def failsTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [straightCar k] [intersection] []

/-- `blind` (unknown): x enters and leaves the intersection; the source declares kin.yaw_rate absent. -/
def blindTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [turningCar k] [intersection] []

def witness (name : String) (τ : Trace) (expected : Verdict) (at_ : Timestamp)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some (at_, at_) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant 5000
  , witness "fails" failsTrace .violated 3000
  , witness "blind" blindTrace (.unknown []) 5000 ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.heading_change_since_entry
