/-
  Witnesses for drv.motion.halted.

  The map is the same in all three scenes: one eastbound lane (region 11), 100 m long and 4 m wide,
  centred on the x axis, and a stop line (region 12) across it, 40 cm deep, at x = 0. One body, the
  car, track 1, 4 m long and 2 m wide (half-extents 2 m, 1 m, 0.75 m), heading east. Each trace is
  three observations a second apart, at t = 0 s, 1 s, 2 s.

  The instance's own figure: `speed_tolerance` = 0.1 m/s — the speed at or below which a reading on
  a sampled track counts as no movement. It is the witness's, not the concept's.

  `holds`: the car stands with its front at the stop line, at x = 0, and the source reads
  0.02 m/s at every observation — residual jitter, below the 0.1 m/s tolerance, so the body is
  true at every instant and the episode is compliant.
  `fails`: the car rolls east through the stop line at a walking pace, 1.4 m/s, covering 1.4 m
  between observations (x = 0 m, 1.4 m, 2.8 m). 1.4 m/s is well above the tolerance, so the body is
  false at every instant and the episode is violated.
  `blind`: the same standing car — the source still gives position, heading and footprint, so the
  car is tracked on the map — but the manifest declares `kin.velocity` and `kin.speed` absent, so
  the one comparison the body makes has no reading and the episode is unknown for that masked atom.
-/
import TrafficSpec.Concepts.motion.halted
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.halted

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mm (n : Int) : Q := Units.millimetres n
/-- A speed in micrometres per second, so that a fraction of a metre per second is exact. -/
def mps (n : Int) : Q := Units.micrometresPerSecond n

-- Formals ↦ tracks: user ↦ 1

/-- The half-extents of the car: 2 m half-length, 1 m half-width, 0.75 m half-height. -/
def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- The eastbound lane the car is in: 100 m long, 4 m wide, centred on the x axis. -/
def theLane : Structure :=
  Build.lane 11 [(m (-50), m (-2)), (m 50, m (-2)), (m 50, m 2), (m (-50), m 2)] Build.east

/-- The stop line across that lane, 40 cm deep, at x = 0. -/
def theStopLine : Structure :=
  Build.rect 12 .stopLine (cm (-20)) (m (-2)) (cm 20) (m 2)

def theMap : List Structure := [theLane, theStopLine]

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.halted@w"
    concept := "drv.motion.halted"
    literals := []
    nats := []
    params := [("speed_tolerance", .lit (mps 100000) .metrePerSecond)]  -- 0.1 m/s
    bounds := none }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car stands at a stop line; its speed reading at the observation is below the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (mps 20000) carExtent (some (m 0)) ]
      theMap
      [ ]

/-- `fails` (violated): A car rolls past the stop line at a walking pace, its speed reading well above the tolerance at every observation. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (mm (1400 * Int.ofNat k), m 0) Build.east (mps 1400000)
          carExtent (some (mm (1400 * Int.ofNat k))) ]
      theMap
      [ ]

/-- `blind` (unknown): The source tracks the car's footprint on the map but declares the velocity vector and its magnitude absent, so whether the body was standing cannot be decided. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (mps 20000) carExtent (some (m 0)) ]
      theMap
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("user", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed", "kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.halted
