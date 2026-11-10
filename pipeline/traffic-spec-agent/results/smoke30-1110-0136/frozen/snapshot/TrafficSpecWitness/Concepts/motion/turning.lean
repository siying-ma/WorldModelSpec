/-
  Witnesses for drv.motion.turning.

  One car, track 1, half-extent 2.25 m × 0.9 m × 0.75 m, no regions, no devices; three
  observations one second apart (t = 0, 1000, 2000 ms). The instance gives `tol` 1 deg/s.

  - holds: the car rounds a left-hand corner at 5 m/s; its heading swings from east through
    (24/25, 7/25) to (527/625, 336/625), about 16 degrees a second, through (0, 0),
    (4.9, 0.7) and (9.5, 2.4) m (each chord shorter than the 5 m of path between them); its yaw
    rate reads 16 deg/s throughout, well above the 1 deg/s tolerance.
  - fails: the car drives straight east at 5 m/s with a yaw rate of zero.
  - blind: the same straight drive, with kin.yaw_rate declared absent by the source and its
    field left unobserved.
-/
import TrafficSpec.Concepts.motion.turning
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turning

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: `tol`, the yaw-rate resolution, is 1 deg/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turning@w"
    concept := "drv.motion.turning"
    literals := []
    nats := []
    params := [("tol", .lit (Units.degrees 1) .degreePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The car's heading at observation `k` of the corner: east, then about 16 and 33 degrees left. -/
def cornerHeading : Nat → Vec
  | 0 => Build.east
  | 1 => (Units.ratio 24 25, Units.ratio 7 25)
  | _ => (Units.ratio 527 625, Units.ratio 336 625)

/-- The car's position at observation `k` of the corner. -/
def cornerPosition : Nat → Vec
  | 0 => (m 0, m 0)
  | 1 => (cm 490, cm 70)
  | _ => (cm 950, cm 240)

/-- `holds` (compliant): A car rounds a corner with a yaw rate well above the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (cornerPosition k) (cornerHeading k)
            (Units.metresPerSecond 5) carExtent (some (m (5 * k))))
          (fun kin => { kin with yawRate := some (Units.degrees 16) }) ]
      [ ]
      [ ]

/-- `fails` (violated): A car drives straight: its yaw rate is zero. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m (5 * k), m 0) Build.east
            (Units.metresPerSecond 5) carExtent (some (m (5 * k))))
          (fun kin => { kin with yawRate := some Q.zero }) ]
      [ ]
      [ ]

/-- `blind` (unknown): The source declares kin.yaw_rate absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m (5 * k), m 0) Build.east
            (Units.metresPerSecond 5) carExtent (some (m (5 * k))))
          (fun kin => { kin with yawRate := none }) ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.turning
