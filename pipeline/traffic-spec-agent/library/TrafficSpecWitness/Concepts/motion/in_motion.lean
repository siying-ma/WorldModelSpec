/-
  Witnesses for drv.motion.in_motion.

  The geometry. One straight street: a single eastbound lane (region 10), a rectangle from
  (-10 m, -2 m) to (60 m, 2 m) with its direction due east, and a kerb line along its south edge
  (region 11). One body: car, track 1, classes [motor_vehicle], half extents 2 m × 0.9 m × 0.75 m,
  heading east throughout. Three instants, one second apart, at t = 0, 1000, 2000 ms.

  The instance's figure, the witness's own: the motion speed is 2 km/h (5/9 m/s exactly), the
  magnitude at which this witness's source stops telling a standing body from a moving one — a
  caller's parameter, not a figure of the contract.

    holds: the car rolls east at 5 m/s, from (0 m, 0 m) to (10 m, 0 m), path length 0/5/10 m.
           5 m/s is above 5/9 m/s at every instant, so it is proceeding over the ground.
    fails: the car stands at the kerb at (20 m, -1 m), speed 0 m/s, path length 0 m, engine
           running and forward gear selected — neither of which this concept reads. 0 m/s is not
           above 5/9 m/s at any instant, so it is not proceeding.
    blind: the holds geometry, with `kin.speed` absent from the manifest: the source does not
           observe the speed, so the comparison has no reading and the concept is unknown.
-/
import TrafficSpec.Concepts.motion.in_motion
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.in_motion

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: user ↦ 1

/-- Half-length, half-width, half-height of the car. -/
private def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- The street the car stands in or rolls along: one eastbound lane and the kerb at its south edge. -/
private def street : List Structure :=
  [ Build.lane 10 [(m (-10), m (-2)), (m 60, m (-2)), (m 60, m 2), (m (-10), m 2)] Build.east
  , Build.rect 11 .roadEdge (m (-10)) (m (-2)) (m 60) (m (-1)) ]

/-- The instance every scenario speaks about: the motion speed this witness's source can tell a
    standing body apart below, 2 km/h = 5/9 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.in_motion@w"
    concept := "drv.motion.in_motion"
    literals := []
    nats := []
    params := [("motion_speed", .lit (Units.kmh 2) .metrePerSecond)]
    bounds := none }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car rolls along a street at walking pace or better; its speed is above the motion speed the caller sets, so it is proceeding over the ground. -/
private def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (5 * Int.ofNat k), m 0) Build.east
          (Units.metresPerSecond 5) carExtent (some (m (5 * Int.ofNat k))) ]
      street
      []

/-- `fails` (violated): The same car stands at the kerb with its engine running and a gear selected; its speed is below the motion speed, which the sampled positions cannot tell apart from standing, so it is not proceeding. -/
private def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m 20, m (-1)) Build.east
            (Units.metresPerSecond 0) carExtent (some (m 0)))
          fun kn => { kn with engineRunning := some true, gear := some 1 } ]
      street
      []

/-- `blind` (unknown): The same car, except that the source does not observe its speed - the capability manifest declares it absent - so whether it is proceeding or standing cannot be decided and the concept reports unknown. -/
private def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (5 * Int.ofNat k), m 0) Build.east
          (Units.metresPerSecond 5) carExtent (some (m (5 * Int.ofNat k))) ]
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

end TrafficSpecWitness.Concepts.motion.in_motion
