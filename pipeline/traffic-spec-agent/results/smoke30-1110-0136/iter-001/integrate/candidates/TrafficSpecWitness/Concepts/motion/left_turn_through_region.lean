/-
  Witnesses for drv.motion.left_turn_through_region.

  One road user, track 1 (x), a car 4.6 m long and 1.8 m wide (half-extents 2.3, 0.9, 0.75 m),
  at 5 m/s, and one structure, region 100 (i), an intersection: the square from (0, 0) to
  (20, 20). Occupancy follows the car's position. Seven instants, 1 s apart, at 0 … 6000 ms:
  the car is outside the intersection at 0 and 1000 ms, enters it at 2000 ms (the rise of the
  overlap, with the observation before it outside), is inside at 3000 … 5000 ms and has left it
  at 6000 ms, the exit observation. The concept holds only at the exit, so every scenario names
  the window [6000, 6000].
  The instance gives `step` 1 s (the sampling interval is 1 s), `min_angle` 45° and
  `max_angle` 150°.
  - holds: x approaches heading east at y = 5 and enters heading east (yaw rate 0 up to the
    entry), then yaws left at 22.5 °/s over each of the four 1 s intervals after it (the rate at
    a scene is held over the interval before it), its heading coming round from east through
    about 22.5°, 45° and 67.5° to north; it leaves across the north edge at (15, 23). A heading
    change of 90° since the entry, within [45°, 150°).
  - fails: x crosses heading east along y = 5 at yaw rate 0 and leaves across the east edge at
    (22, 5): a heading change of 0°, below 45°.
  - blind: the scene of `holds` with x's yaw rate unobserved, and `kin.yaw_rate` absent from the
    manifest: the exit is decided, the heading change since the entry is not.
-/
import TrafficSpec.Concepts.motion.left_turn_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: i ↦ 100  (the intersection, a structure of every trace)

/-- The instance every scenario speaks about: `step` 1 s, `min_angle` 45°, `max_angle` 150°. -/
def inst : Concept.Instance :=
  { name := "drv.motion.left_turn_through_region@w"
    concept := "drv.motion.left_turn_through_region"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 1) .second), ("min_angle", .lit (Units.degrees 45) .degree),
               ("max_angle", .lit (Units.degrees 150) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The intersection i: the square from (0, 0) to (20, 20). -/
def intersection : Structure := Build.rect 100 .intersection (m 0) (m 0) (m 20) (m 20)

/-- The car x at `pos`, heading `h`, at 5 m/s, yawing at `yaw` °/s. -/
def car (pos : Vec) (h : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos h (Units.metresPerSecond 5) (cm 230, cm 90, cm 75))
    (fun k => { k with yawRate := some yaw })

/-- The left turn: east at y = 5 up to the entry at k = 2, then yawing left at 22.5 °/s over each
    interval after it, heading coming round through about 22.5°, 45° and 67.5° to north, leaving
    across the north edge. -/
def turningCar (k : Nat) : RoadUser :=
  let yaw := Units.millidegrees 22500
  match k with
  | 0 => car (m (-6), m 5) Build.east Q.zero
  | 1 => car (m (-2), m 5) Build.east Q.zero
  | 2 => car (m 2, m 5) Build.east Q.zero
  | 3 => car (m 7, m 6) (Units.ratio 12 13, Units.ratio 5 13) yaw
  | 4 => car (m 11, m 9) (Units.ratio 119 169, Units.ratio 120 169) yaw
  | 5 => car (m 14, m 13) (Units.ratio 5 13, Units.ratio 12 13) yaw
  | _ => car (m 15, m 23) Build.north yaw

/-- `holds` (compliant): A car enters an intersection heading east and leaves it heading north, a heading change of about 90 degrees to the left. -/
def holdsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar k ]
      [ intersection ]
      [ ]

/-- `fails` (violated): The car enters heading east and leaves heading east. -/
def failsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (4 * k - 2), m 5) Build.east Q.zero ]
      [ intersection ]
      [ ]

/-- `blind` (unknown): The car leaves the intersection; the source supplies no yaw rate. -/
def blindTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (turningCar k) (fun kn => { kn with yawRate := none }) ]
      [ intersection ]
      [ ]

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
    window := some (6000, 6000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.left_turn_through_region
