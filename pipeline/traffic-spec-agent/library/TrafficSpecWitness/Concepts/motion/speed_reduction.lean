/-
  Witnesses for drv.motion.speed_reduction.

  The geometry, and every figure in it, is this file's own.

  One body: track 1, a motor vehicle 4.5 m long, 1.8 m wide and 1.5 m high (half-extents 2.25 m,
  0.90 m, 0.75 m), heading east along y = 0 and moving east on the approach to a yield-controlled
  junction. The junction itself is not built: the concept says nothing about where the road user is
  — only about how its acceleration along heading has run — so there is nothing about the place for
  a witness to show. Each trace is eight observations one second apart, t = 0 ms … 7000 ms; the
  positions are the running integral of the speeds, so the body moves as its kin.speed says it does,
  and the speeds fall at exactly the kin.accel_longitudinal each scene carries.

  The instance fills the formals with: decel_rate = 2 m/s² (a positive magnitude; the body compares
  the signed acceleration against its negation, so the bound is −2 m/s²), window = 2 s. Two seconds
  is also twice the one-second sampling of these traces, which is what the window's adequacy asks
  for. With a 2 s window the look-back behind t = 0 ms and t = 1000 ms reaches past the start of the
  trace, so every scenario's `window` starts at t = 2000 ms.

  `holds`   accel −3 m/s² at all eight observations, speeds 24, 21, 18, 15, 12, 9, 6, 3 m/s: steady
            braking on the approach. −3 ≤ −2 at every observation, so over t = 2000 … 7000 the
            window behind each observation is full and wholly inside the braking, and the concept
            holds.
  `fails`   accel 0 m/s² at all eight observations, speed held at 20 m/s, positions 0 … 140 m: the
            car does not slow. 0 ≤ −2 is false at every observation, so over the same t = 2000 …
            7000 the concept fails.
  `blind`   the same held-speed positions, but the bodies carry position, heading and extent and no
            acceleration at all, and the manifest declares kin.accel_longitudinal absent. Over the
            same t = 2000 … 7000 the look-back is full but no observation in it has an acceleration
            to compare against the rate, so the concept is unknown, and for the masked
            kin.accel_longitudinal alone.
-/
import TrafficSpec.Concepts.motion.speed_reduction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.speed_reduction

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n
private def mps2 (n : Int) : Q := Units.metresPerSecondSq n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.speed_reduction@w"
    concept := "drv.motion.speed_reduction"
    literals := []
    nats := []
    params := [("decel_rate", .lit (Units.metresPerSecondSq 2) .metrePerSecondSq), ("window", .lit (Units.seconds 2) .second)]
    bounds := none }

def instances : List Concept.Instance := [inst]

/-- The half-extents of the car: 2.25 m × 0.90 m × 0.75 m. -/
private def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The car at `x` metres east of the origin, heading east at `speed`, with `accel` m/s² along
    that heading. -/
private def car (x : Q) (speed : Q) (accel : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (x, m 0) Build.east speed carExtent)
    fun k => { k with accelLongitudinal := some accel }

/-- The same car as a source with no acceleration reading sees it: position, heading, speed and
    extent only. -/
private def unreadCar (x : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, m 0) Build.east speed carExtent

/-- `holds` (compliant): A car on a yield-controlled approach, the trace starting well before the
    window so the look-back behind the observation is full. At every observation in that window its
    kin.accel_longitudinal is −3 m/s², more negative than the negation of the 2 m/s² rate the
    instance sets: it has been braking steadily on the approach, and the concept holds. -/
private def brakingAt : Nat → Q × Q    -- position east, speed
  | 0 => (m 0, mps 24)
  | 1 => (cm 2250, mps 21)
  | 2 => (m 42, mps 18)
  | 3 => (cm 5850, mps 15)
  | 4 => (m 72, mps 12)
  | 5 => (cm 8250, mps 9)
  | 6 => (m 90, mps 6)
  | _ => (cm 9450, mps 3)

private def holdsTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (brakingAt k).1 (brakingAt k).2 (mps2 (-3)) ]
      [ ]  -- no structure: the concept says nothing about the place of the slowing
      [ ]  -- devices

/-- `fails` (violated): The same approach and the same trace length, so the look-back is again full,
    but the car holds its speed: its kin.accel_longitudinal is zero at every observation in the
    window, nowhere at or beyond the deceleration rate, so the concept fails. -/
private def heldAt : Nat → Q × Q       -- position east, speed
  | 0 => (m 0, mps 20)
  | 1 => (m 20, mps 20)
  | 2 => (m 40, mps 20)
  | 3 => (m 60, mps 20)
  | 4 => (m 80, mps 20)
  | 5 => (m 100, mps 20)
  | 6 => (m 120, mps 20)
  | _ => (m 140, mps 20)

private def failsTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (heldAt k).1 (heldAt k).2 Q.zero ]
      [ ]  -- no structure
      [ ]  -- devices

/-- `blind` (unknown): The same approach and the same full look-back, but the source's capability
    manifest declares kin.accel_longitudinal absent, and the scenes it builds carry the car's
    position, heading, speed and extent and no acceleration. No observation in the window has an
    acceleration to compare against the rate, so the concept reports unknown, for the absent
    kin.accel_longitudinal and for nothing else. -/
private def blindTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ unreadCar (heldAt k).1 (heldAt k).2 ]
      [ ]  -- no structure
      [ ]  -- devices

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (window : Option (Timestamp × Timestamp) := none) (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant (some (2000, 7000))
  , witness "fails" failsTrace .violated (some (2000, 7000))
  , witness "blind" blindTrace (.unknown []) (some (2000, 7000)) ["kin.accel_longitudinal"] ]

end TrafficSpecWitness.Concepts.motion.speed_reduction
