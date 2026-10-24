/-
  Witnesses for drv.motion.halted.

  The geometry is the same in all three scenarios: an east–west lane `10`, the rectangle
  x ∈ [-50, 50], y ∈ [-2, 2], with a stop line `11` as a point region at (0, 0), the east end of
  the approach. The road user `u` is track 1, a motor vehicle heading east, half-extents
  2 m × 1 m × 0.75 m. Three observations one second apart, at t = 0, 1, 2 s.

  The instance fills the one formal parameter: `halt_speed_tolerance` = 0.1 m/s, the witness's own
  figure for the magnitude below which a measured speed counts as none.

  `holds`: the vehicle stands with its front at x = -1 m, just behind the stop line, with a measured
  speed of 0.0 m/s at every observation: 0.0 ≤ 0.1, so the body is true throughout — compliant.

  `fails`: the same vehicle creeps east at 1.5 m/s, from x = -3 m through x = 0 m, one and a half
  metres per observation: 1.5 > 0.1 at every observation, so the body is false — violated.

  `blind`: the standing vehicle of `holds`, but the source's manifest declares `kin.speed` and the
  `kin.velocity` it is the magnitude of absent, so both fields are blanked before evaluation and
  the comparison has nothing to decide on — unknown, for the masked atom and for nothing else.
-/
import TrafficSpec.Concepts.motion.halted
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.halted

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- Speeds, in millionths of a metre per second, so that fractions of a metre per second are exact. -/
def umps (n : Int) : Q := Units.micrometresPerSecond n

/-- The tolerance the caller sets in these scenarios: 0.1 m/s. -/
def tolerance : Q := umps 100000
/-- The creeping speed of the `fails` scenario: 1.5 m/s. -/
def creepSpeed : Q := umps 1500000
/-- The distance the creeping vehicle covers between two observations one second apart: 1.5 m. -/
def creepStep : Q := cm 150

/-- Half-length, half-width, half-height of the vehicle. -/
def vehicleExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- The lane the vehicle stands in, and the stop line at its east end. -/
def structures : List Structure :=
  [ Build.lane 10 [(m (-50), m (-2)), (m 50, m (-2)), (m 50, m 2), (m (-50), m 2)] Build.east
  , Build.point 11 .stopLine (m 0, m 0) ]

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.halted@w"
    concept := "drv.motion.halted"
    literals := []
    nats := []
    params := [("halt_speed_tolerance", .lit tolerance .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The standing vehicle: front at x = -1 m, speed 0.0 m/s. -/
def standingUser : RoadUser :=
  Build.user 1 [.motorVehicle] (m (-3), m 0) Build.east Q.zero vehicleExtent

/-- `holds` (compliant): A vehicle stands at a stop line with a measured speed of 0.0 m/s at the observation; the tolerance is filled with p.halt_speed_tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ standingUser ]
      structures
      [ ]  -- devices

/-- `fails` (violated): The same vehicle creeps forward at 1.5 m/s at the observation, well above the tolerance. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle]
          (Q.add (m (-3)) (Q.mul creepStep (Q.ofInt (Int.ofNat k))), m 0)
          Build.east creepSpeed vehicleExtent
          (some (Q.mul creepStep (Q.ofInt (Int.ofNat k)))) ]
      structures
      [ ]  -- devices

/-- `blind` (unknown): The vehicle is in the scene but the source's manifest declares kin.speed, and the kin.velocity it is the magnitude of, absent, so no speed is observed at the observation. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ standingUser ]
      structures
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed", "kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.halted
