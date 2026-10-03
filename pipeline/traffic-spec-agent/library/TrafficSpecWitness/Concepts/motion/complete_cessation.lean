/-
  Witnesses for drv.motion.complete_cessation.

  The geometry, one straight eastbound roadway for all three scenarios: a lane (region 10) from
  x = -60 m to x = 60 m, four metres wide, and a stop line (region 11) across it just east of the
  origin, from x = -0.5 m to x = 0 m. One tracked motor vehicle (track 1, a 4 m × 2 m body) drives
  east along y = 0. Each trace is eight observations one second apart, t = 0 ms … 7000 ms.

  The instance's own figures: stop_speed_tolerance = 0.2 m/s (a speed at which a vehicle of this
  size is not moving by any measure a tracker resolves), stop_hold_time = 3 s.

  The instants the witnesses speak about: t = 6000 ms and t = 7000 ms. A three-second lookback is
  truncated — unknown, by Core's finite-trace policy — at every observation before t = 3000 ms,
  and the `holds` dwell begins at t = 3000 ms, so the window of all three scenarios is the last
  two observations, at which the lookback is both covered (an observation precedes it) and
  adequately sampled (the one-second spacing is at most half the hold time).

    holds: speeds 5, 3, 1 m/s as the vehicle brakes to the line (x = -14, -9, -6 m), then standing
      still at x = -5 m from t = 3000 ms on. At t = 6000 ms and t = 7000 ms the whole three-second
      window behind is at 0 m/s ≤ 0.2 m/s, so the concept holds: compliant.
    fails: the same approach rolled through at a steady 3 m/s, from x = -14 m to x = 7 m. Every
      sample is above the tolerance, so no window is wholly within it: violated.
    blind: the `holds` trace, under a manifest that declares kin.speed absent together with the
      kin.velocity it could be recovered from. The windows are covered and adequately sampled, so
      the only reason left is the masked measurement: unknown.
-/
import TrafficSpec.Concepts.motion.complete_cessation
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.complete_cessation

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n

-- Formals ↦ tracks: a ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.complete_cessation@w"
    concept := "drv.motion.complete_cessation"
    literals := []
    nats := []
    params :=
      [ ("stop_speed_tolerance", .lit (Units.micrometresPerSecond 200000) .metrePerSecond)   -- 0.2 m/s
      , ("stop_hold_time", .lit (Units.seconds 3) .second) ]
    bounds := none }

def instances : List Concept.Instance := [inst]

-- The place: one lane and the stop line across it.
private def theLane : Structure :=
  Build.lane 10 [(m (-60), m (-2)), (m 60, m (-2)), (m 60, m 2), (m (-60), m 2)] Build.east
private def theStopLine : Structure :=
  Build.rect 11 .stopLine (cm (-50)) (m (-2)) Q.zero (m 2)

/-- The vehicle at an instant: a 4 m × 2 m car heading east at `(x, 0)` with speed `v`. -/
private def car (x v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, Q.zero) Build.east v (m 2, m 1, m 1)

private def place (t : Timestamp) (u : RoadUser) : Scene :=
  Build.scene t (some 1) [u] [theLane, theStopLine] []

-- The braking approach: slowing to a standstill at x = -5 m by t = 3000 ms, then standing still.
private def dwellX : Nat → Q
  | 0 => m (-14)
  | 1 => m (-9)
  | 2 => m (-6)
  | _ => m (-5)

private def dwellSpeed : Nat → Q
  | 0 => mps 5
  | 1 => mps 3
  | 2 => mps 1
  | _ => Q.zero

/-- `holds` (compliant): A tracked vehicle's kin.speed falls at a stop line and stays at or below stop_speed_tolerance for longer than stop_hold_time; at the end of that dwell the concept holds of the vehicle. -/
private def holdsTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    place t (car (dwellX k) (dwellSpeed k))

/-- `fails` (violated): A tracked vehicle rolls through the same place with kin.speed above stop_speed_tolerance at every sample, so no window of length stop_hold_time ending at any observation is entirely at or below the tolerance. -/
private def failsTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    place t (car (m (-14 + 3 * (Int.ofNat k))) (mps 3))

/-- `blind` (unknown): The same approach, but the source's capability manifest declares kin.speed absent, together with the kin.velocity from which Core would otherwise compute it; no dwell can be read and the concept reports unknown at every instant. -/
private def blindTrace : Trace := holdsTrace

/-- Every witness speaks about the last two observations: before t = 3000 ms the three-second
    lookback runs off the start of the trace, which is unknown for truncation and not about the
    concept. -/
private def spoken : Timestamp × Timestamp := (6000, 7000)

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected
    window := some spoken }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed", "kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.complete_cessation
