/-
  Witnesses for drv.motion.complete_cessation.

  The geometry, and every figure in it, is this file's own.

  One body: track 1, a motor vehicle 4.5 m long, 1.8 m wide and 1.5 m high (half-extents 2.25 m,
  0.90 m, 0.75 m), heading east along y = 0 and moving east. No region and no device is built: the
  concept says nothing about where the body is, so there is nothing about the place for a witness to
  show. Each trace is eight observations one second apart, t = 0 ms … 7000 ms; the positions are the
  running integral of the speeds, so the body moves as its kin.speed says it does.

  The instance fills the formals with: speed_tolerance = 2 km/h (5/9 m/s — a magnitude below which a
  sampled velocity is taken for sensor noise rather than a roll), dwell = 2 s. Two seconds is also
  twice the one-second sampling of these traces, which is what the window's adequacy test asks for.

  `holds`   speeds 8, 5, 2, 0, 0, 0, 0, 4 m/s: the approach, four seconds standing, then away again.
            The window behind t = 5000 and t = 6000 lies wholly inside the standing stretch, so the
            scenario speaks about those two instants (earlier ones are the approach, and the window
            behind t = 0 ms and t = 1000 ms reaches past the start of the trace).
  `fails`   speeds 8, 7, 6, 5, 4, 3, 2, 1 m/s: the roll-through. Every sample is above the tolerance,
            so no window of the dwell holds the magnitude at or below it; the scenario speaks about
            t = 2000 … 7000, the instants whose window the trace covers.
  `blind`   the same roll-through positions, but the bodies carry position, heading and extent and no
            motion reading at all — no speed and no velocity vector one could be derived from — and
            the manifest declares kin.speed absent. Over the same t = 2000 … 7000 the comparison can
            never be made, so the concept is unknown, and for the masked kin.speed alone.
-/
import TrafficSpec.Concepts.motion.complete_cessation
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.complete_cessation

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.complete_cessation@w"
    concept := "drv.motion.complete_cessation"
    literals := []
    nats := []
    params := [("speed_tolerance", .lit (Units.kmh 2) .metrePerSecond), ("dwell", .lit (Units.seconds 2) .second)]
    bounds := none }

def instances : List Concept.Instance := [inst]

/-- The half-extents of the car: 2.25 m × 0.90 m × 0.75 m. -/
private def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The car at `x` metres east of the origin, heading east at `speed`. -/
private def car (x : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, m 0) Build.east speed carExtent

/-- The same car as a source with no motion reading sees it: position, heading and extent only. -/
private def stillUnreadCar (x : Q) : RoadUser :=
  Build.withKin (Build.sparseUser 1 [.motorVehicle] (x, m 0))
    fun k => { k with heading := some Build.east, extent := some carExtent }

/-- `holds` (compliant): A car approaches a junction; the trace starts well before the observation, so the window behind it is full. Its kin.speed falls through the approach and stays at or below the speed tolerance for longer than the dwell before it moves off again. At the observation at the end of that stationary stretch the concept holds. -/
private def holdsAt : Nat → Q × Q      -- position east, speed
  | 0 => (m 0, mps 8)
  | 1 => (m 8, mps 5)
  | 2 => (m 13, mps 2)
  | 3 => (m 15, mps 0)
  | 4 => (m 15, mps 0)
  | 5 => (m 15, mps 0)
  | 6 => (m 15, mps 0)
  | _ => (m 15, mps 4)

private def holdsTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (holdsAt k).1 (holdsAt k).2 ]
      [ ]  -- no structure: the concept says nothing about the place of the halt
      [ ]  -- devices

/-- `fails` (violated): The same approach, the same trace length, but the car rolls through: its kin.speed falls but never reaches the tolerance, so no window of the dwell's length behind any observation holds the magnitude at or below it. The concept fails at every observation of the approach. -/
private def rollAt : Nat → Q × Q       -- position east, speed
  | 0 => (m 0, mps 8)
  | 1 => (m 8, mps 7)
  | 2 => (m 15, mps 6)
  | 3 => (m 21, mps 5)
  | 4 => (m 26, mps 4)
  | 5 => (m 30, mps 3)
  | 6 => (m 33, mps 2)
  | _ => (m 35, mps 1)

private def failsTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (rollAt k).1 (rollAt k).2 ]
      [ ]  -- no structure
      [ ]  -- devices

/-- `blind` (unknown): The same rolling approach, but the source's capability manifest declares kin.speed absent, and the scenes it builds carry the car's position, heading and extent and no motion reading of any kind — neither a speed nor a velocity vector a speed could be derived from. No sampled magnitude can be compared with the tolerance, so the concept reports unknown at every observation of the window, for the absent kin.speed and for nothing else. -/
private def blindTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ stillUnreadCar (rollAt k).1 ]
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
  [ witness "holds" holdsTrace .compliant (some (5000, 6000))
  , witness "fails" failsTrace .violated (some (2000, 7000))
  , witness "blind" blindTrace (.unknown []) (some (2000, 7000)) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.complete_cessation
