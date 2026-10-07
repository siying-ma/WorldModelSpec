/-
  Witnesses for drv.motion.braking_distance.

  The geometry: one straight east-bound lane (region 10), a rectangle from x = -20 m to x = 400 m
  and y = -2 m to y = +2 m, on a dry surface. One car (track 1, a motor vehicle, half-extents
  2.0 m × 0.9 m × 0.75 m) runs along its centre line (y = 0) heading east, from x = 0 at the first
  instant; three instants one second apart, the car advancing by its speed each second.

  The figures are this witness's own:
  - the deceleration the instance gives the formal parameter is 5 m/s², a plain dry-asphalt figure;
  - the bounds [0 m, 40 m] are the caller's test of the narratives — the 40 m clear stretch ahead
    of the car, which the concept does not read: it computes a distance, and the caller compares it
    with whatever the scene gives. The witness therefore puts the stretch in the bounds, not in a
    region, since the body reads nothing but the speed.

  holds: 10 m/s ⇒ 100 / (2·5) = 10 m, inside [0 m, 40 m] — compliant at every instant.
  fails: 30 m/s ⇒ 900 / (2·5) = 90 m, above 40 m — violated at every instant.
  blind: the holds scene with `kin.speed` absent from the manifest, so the quotient, and with it the
         caller's test, is unknown.
-/
import TrafficSpec.Concepts.motion.braking_distance
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.braking_distance

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n

-- Formals ↦ tracks: user ↦ 1

/-- The east-bound lane the car runs in. -/
private def theLane : Structure := Build.rect 10 .lane (m (-20)) (m (-2)) (m 400) (m 2)

/-- The car at instant `k`, having travelled `v` metres per second since the first instant. -/
private def car (k : Nat) (v : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (v * (k : Int)), m 0) Build.east (mps v)
    (m 2, cm 90, cm 75) (some (m (v * (k : Int))))

/-- A dry road: the surface is observed and it is not wet. -/
private def dry : Env := { wetRoad := some false }

/-- The instance every scenario speaks about: the deceleration the caller sets, and the interval
    the caller's test accepts — the distance must lie within the 40 m clear ahead. -/
def inst : Concept.Instance :=
  { name := "drv.motion.braking_distance@w"
    concept := "drv.motion.braking_distance"
    literals := []
    nats := []
    params := [("deceleration", .lit (Units.metresPerSecondSq 5) .metrePerSecondSq)]
    bounds := some (.lit Q.zero .metre, .lit (Units.metres 40) .metre) }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A car proceeds at a moderate speed along a dry road with a long clear stretch ahead of it. The distance over which its speed would fall to standing at the deceleration the caller sets is shorter than that clear stretch, and the caller's test that it could stop within the stretch is met. -/
private def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k 10] [theLane] [] (env := dry)

/-- `fails` (violated): The same car on the same road proceeds much faster. The distance over which its speed would fall to standing at the same deceleration is longer than the stretch clear ahead of it, and the caller's test that it could stop within the stretch fails. -/
private def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k 30] [theLane] [] (env := dry)

/-- `blind` (unknown): The same scene, except that the source does not observe the car's speed - the capability manifest declares it absent - so the distance cannot be computed and the caller's test reports unknown. -/
private def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k 10] [theLane] [] (env := dry)

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

end TrafficSpecWitness.Concepts.motion.braking_distance
