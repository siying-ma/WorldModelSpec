/-
  Witnesses for drv.motion.stopping_distance.

  The geometry. One straight street, dry: a single eastbound lane (region 10), a rectangle from
  (-10 m, -3 m) to (200 m, 3 m) with its direction due east, and a kerb line along its south edge
  (region 11). Two bodies, both classed motor_vehicle, both heading east, half extents
  2 m x 0.9 m x 0.75 m: the car, track 1, which proceeds along the lane, and the obstacle, track 2,
  which stands still in the same lane ahead of it (speed 0 m/s, path length 0 m). Three instants,
  one second apart, at t = 0, 1000, 2000 ms.

  The instance's figures, the witness's own. The reaction time is 1 s — how long this witness's
  caller allows between the observation and the brakes taking effect — and the deceleration is
  5 m/s^2, what the caller takes a dry surface and sound brakes to sustain. Neither is read from
  the trace; both are the caller's convention. The expected interval is [15 m, 25 m]: the band of
  halting distances the caller's standard admits here.

    holds: the car rolls east at 10 m/s, from (0 m, 0 m) to (20 m, 0 m), path length 0/10/20 m,
           with the obstacle standing at (60 m, 0 m). The reaction leg is 10 m/s x 1 s = 10 m and
           the braking leg (10 m/s)^2 / (2 x 5 m/s^2) = 10 m, so the car would need 20 m to halt
           at every instant — inside [15 m, 25 m], and well short of the 60 m, then 40 m, of lane
           between it and the obstacle.
    fails: the same car approaches the same standing obstacle, now at (100 m, 0 m), at 30 m/s,
           from (0 m, 0 m) to (60 m, 0 m), path length 0/30/60 m. At the same reaction time and
           deceleration the reaction leg is 30 m and the braking leg 900 / 10 = 90 m, so it would
           need 120 m to halt — outside [15 m, 25 m] at every instant, and longer than the 100 m
           of lane ahead of it when it is first seen.
    blind: the holds geometry, with `kin.speed` absent from the manifest: the source does not
           observe the car's speed, so neither the reaction leg nor the braking leg can be
           computed and the distance has no reading at all.
-/
import TrafficSpec.Concepts.motion.stopping_distance
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.stopping_distance

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: user ↦ 1

/-- Half-length, half-width, half-height of either vehicle. -/
private def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- The street: one eastbound lane and the kerb at its south edge. -/
private def street : List Structure :=
  [ Build.lane 10 [(m (-10), m (-3)), (m 200, m (-3)), (m 200, m 3), (m (-10), m 3)] Build.east
  , Build.rect 11 .roadEdge (m (-10)) (m (-3)) (m 200) (m (-2)) ]

/-- The obstacle: a vehicle standing still in the lane, `ahead` metres east of the origin. -/
private def obstacle (ahead : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (m ahead, m 0) Build.east
    (Units.metresPerSecond 0) carExtent (some (m 0))

/-- The instance every scenario speaks about: a reaction time of 1 s and a deceleration of
    5 m/s^2, the caller's convention for a dry surface, and the band of halting distances the
    caller's standard admits, 15 m to 25 m. -/
def inst : Concept.Instance :=
  { name := "drv.motion.stopping_distance@w"
    concept := "drv.motion.stopping_distance"
    literals := []
    nats := []
    params :=
      [ ("reaction_time", .lit (Units.seconds 1) .second)
      , ("deceleration", .lit (Units.metresPerSecondSq 5) .metrePerSecondSq) ]
    bounds := some (.lit (Units.metres 15) .metre, .lit (Units.metres 25) .metre) }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car proceeds at a moderate speed along a dry road, with an obstacle standing far ahead of it in its lane. The distance it would need to halt - the reaction leg at its present speed, then the braking leg at the deceleration the caller sets - is shorter than the gap to the obstacle, and the caller's test that it could halt short of it is met. -/
private def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (10 * Int.ofNat k), m 0) Build.east
          (Units.metresPerSecond 10) carExtent (some (m (10 * Int.ofNat k)))
      , obstacle 60 ]
      street
      []

/-- `fails` (violated): The same car approaches the same standing obstacle much faster. The distance it would need to halt, at the same reaction time and deceleration, is longer than the gap to the obstacle, and the caller's test that it could halt short of it fails. -/
private def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (30 * Int.ofNat k), m 0) Build.east
          (Units.metresPerSecond 30) carExtent (some (m (30 * Int.ofNat k)))
      , obstacle 100 ]
      street
      []

/-- `blind` (unknown): The same scene, except that the source does not observe the car's speed - the capability manifest declares it absent - so neither the reaction leg nor the braking leg can be computed, and the caller's test reports unknown. -/
private def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (10 * Int.ofNat k), m 0) Build.east
          (Units.metresPerSecond 10) carExtent (some (m (10 * Int.ofNat k)))
      , obstacle 60 ]
      street
      []

private def witness (name : String) (τ : Trace) (expected : Verdict)
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.stopping_distance
