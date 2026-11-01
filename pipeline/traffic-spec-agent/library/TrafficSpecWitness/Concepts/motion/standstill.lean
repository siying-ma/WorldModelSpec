/-
  Witnesses for drv.motion.standstill.

  The geometry is the same place in all three scenes: one straight east-bound lane, region 10, the
  rectangle from (0, -2) to (60, 2) m, with a stop line, region 11, the 40 cm band across it from
  x = 29.8 to 30.2 m. One body, track 1, a motor vehicle of half-extents (2.4, 0.9, 0.75) m,
  heading east. Three observations a second apart, at t = 0, 1000 and 2000 ms.

  The instance sets speed_tolerance to 0.2 m/s (200000 µm/s), a sampling bound wide enough to
  swallow sensor noise at rest and far below any travelling speed.

  holds:  the car waits just short of the stop line at (27.6, 0) m, its reported speed a steady
          0.03 m/s of noise and its path length not advancing — 0.03 ≤ 0.2, so the body holds at
          every instant.
  fails:  the car rolls through the same place at 2 m/s, passing x = 20, 22, 24 m with a path
          length that grows by 2 m a step — 2 > 0.2 at every instant, so the body is false.
  blind:  the car stands at the same spot as in `holds`, but the source reports no speed (and no
          velocity) for it and the manifest declares `kin.speed` absent, so the one atom the body
          reads is unobserved and the halt cannot be decided.
-/
import TrafficSpec.Concepts.motion.standstill
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.standstill

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A speed in micrometres per second, the exact way to write a fraction of a metre per second. -/
def mps (n : Int) : Q := Units.micrometresPerSecond n

/-- The lane the body stands in and the stop line across it. -/
def places : List Structure :=
  [ Build.lane 10 [(m 0, m (-2)), (m 60, m (-2)), (m 60, m 2), (m 0, m 2)] Build.east
  , Build.rect 11 .stopLine (cm 2980) (m (-2)) (cm 3020) (m 2) ]

/-- The half-extents of the car: half-length, half-width, half-height, in metres. -/
def carExtent : Q × Q × Q := (cm 240, cm 90, cm 75)

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.standstill@w"
    concept := "drv.motion.standstill"
    literals := []
    nats := []
    params := [("speed_tolerance", .lit (mps 200000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car at a stop line is stationary for three seconds, its reported speed hovering at a few centimetres per second of sensor noise. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (cm 2760, m 0) Build.east
          (mps 30000) carExtent (some (m 0)) ]
      places
      [ ]  -- devices

/-- `fails` (violated): A car rolls through the same place at two metres per second, never dropping below walking pace. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 + 2 * Int.ofNat k), m 0) Build.east
          (Units.metresPerSecond 2) carExtent (some (m (2 * Int.ofNat k))) ]
      places
      [ ]  -- devices

/-- `blind` (unknown): A car is at the stop line but the source declares speed absent for it, so whether it has ceased movement cannot be decided. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (cm 2760, m 0) Build.east
            (mps 30000) carExtent (some (m 0)))
          (fun kin => { kin with speed := none, velocity := none }) ]
      places
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.standstill
