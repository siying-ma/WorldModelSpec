/-
  Witnesses for drv.interaction.precedence_granted.

  The geometry, and every figure in it, is this file's own.

  One junction: an east–west roadway along y = 0 and a north–south roadway along x = 0 crossing in
  a 12 m square intersection built as a region from (−6, −6) to (6, 6). The region is inert — the
  concept reads no structure — and is built only because the narratives speak of a junction.

  Two bodies, both motor vehicles 4.5 m long, 1.8 m wide and 1.5 m high (half-extents 2.25 m,
  0.90 m, 0.75 m): track 1 is `a`, the granting party, on the east–west roadway heading east;
  track 2 is `b`, the receiving party, on the north–south roadway heading north, and it is b's
  kin.accel_longitudinal that the braking leaf reads. Each trace is ten observations one second
  apart, t = 0 ms … 9000 ms, and every position is the running integral of the speed carried at the
  observation before it, so each body moves as its kinematics say it does.

  The instance fills the formals with: window = 2 s, horizon = 5 s, clearance_margin = 10 m,
  induced_decel = 2 m/s² (a positive magnitude; the body compares b's signed acceleration against
  its negation, so the bound is −2 m/s²). Two seconds is twice the one-second sampling of these
  traces, which is what the window's adequacy asks for. With a 2 s window the look-back behind
  t = 0 ms and t = 1000 ms reaches past the start of the trace, so no scenario counts an
  observation before t = 2000 ms.

  `holds`   b runs north at an unchanged 10 m/s from y = −70 m, crossing y = 0 at t = 7000 ms; a
            waits at (−30 m, 0) until t = 8000 ms and then pulls away east at 10 m/s, crossing
            behind b. At t = 0 and 1000 ms the predicted closest approach of the two reference
            points lies 7 s and 6 s ahead, past the 5 s horizon, so none is predicted within it; at
            every later observation one is predicted and its centre distance is 30 m (while a
            stands) or about 28.3 m (once a moves), both far above the 10 m margin. b's
            acceleration is zero throughout, so it is never below −2 m/s². Over t = 2000 … 9000 the
            look-back behind each observation is full and wholly inside that conduct, and the
            concept holds of (a, b).
  `fails`   The same junction. a pulls out east at 10 m/s from x = −60 m while b runs north at
            10 m/s from y = −70 m: the two reference points are predicted to pass about 7.07 m
            apart, inside the 10 m margin, and that approach lies within the 5 s horizon at every
            observation from t = 2000 ms to t = 6000 ms. Over the counted t = 4000 … 6000 the
            look-back reaches back only to t = 2000 ms, so at each counted observation and
            throughout its window an approach is predicted and the distance at it is below the
            margin: the clearance alone decides, and both of its leaves are load-bearing. b brakes
            hard for a at t = 8000 and 9000 ms (−5 m/s², past the 2 m/s² bound), after the counted
            observations and out of reach of their look-back. The concept fails of (a, b) — and
            would be judged separately of (b, a).
  `blind`   The same crossing geometry as `fails`, but the source's capability manifest declares
            kin.velocity and kin.speed absent and the scenes carry the two bodies' positions,
            headings and extents and nothing of their motion. Neither primitive has velocities to
            predict from, so both are unknown at every observation; b's acceleration is observed
            and zero, within the bound, so nothing else decides the conjunction. Over the same
            t = 2000 … 9000 the look-back is full, and the concept reports unknown, for the absent
            kin.velocity and for nothing else.
-/
import TrafficSpec.Concepts.interaction.precedence_granted
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.precedence_granted

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n
private def mps2 (n : Int) : Q := Units.metresPerSecondSq n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.precedence_granted@w"
    concept := "drv.interaction.precedence_granted"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 2) .second), ("horizon", .lit (Units.seconds 5) .second),
               ("clearance_margin", .lit (Units.metres 10) .metre),
               ("induced_decel", .lit (Units.metresPerSecondSq 2) .metrePerSecondSq)]
    bounds := none }

def instances : List Concept.Instance := [inst]

/-- The half-extents of either vehicle: 2.25 m × 0.90 m × 0.75 m. -/
private def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The junction itself: a 12 m square where the two roadways cross. The concept reads no region;
    the narratives name a junction, so one is built. -/
private def junction : Structure := Build.rect 10 .intersection (m (-6)) (m (-6)) (m 6) (m 6)

/-- `a`, the granting party: on the east–west roadway at y = 0, `x` metres east of the crossing,
    heading east at `speed`. -/
private def aCar (x speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, m 0) Build.east speed carExtent

/-- `b`, the receiving party: on the north–south roadway at x = 0, `y` metres north of the
    crossing, heading north at `speed`, with `accel` m/s² along that heading. -/
private def bCar (y speed accel : Q) : RoadUser :=
  Build.withKin (Build.user 2 [.motorVehicle] (m 0, y) Build.north speed carExtent)
    fun k => { k with accelLongitudinal := some accel }

/-- `a` as a source with no reading of motion sees it: position, heading and extent only. -/
private def aSeen (x : Q) : RoadUser :=
  Build.withKin (Build.sparseUser 1 [.motorVehicle] (x, m 0))
    fun k => { k with heading := some Build.east, extent := some carExtent }

/-- `b` as the same source sees it: position, heading, extent and its longitudinal acceleration,
    which that source does observe. -/
private def bSeen (y accel : Q) : RoadUser :=
  Build.withKin (Build.sparseUser 2 [.motorVehicle] (m 0, y))
    fun k => { k with heading := some Build.north, extent := some carExtent,
                      accelLongitudinal := some accel }

/-- b's position north of the crossing at each observation: 10 m/s from y = −70 m, so it reaches
    the crossing at t = 7000 ms. Shared by every scenario. -/
private def bNorthAt : Nat → Q
  | 0 => m (-70)
  | 1 => m (-60)
  | 2 => m (-50)
  | 3 => m (-40)
  | 4 => m (-30)
  | 5 => m (-20)
  | 6 => m (-10)
  | 7 => m 0
  | 8 => m 10
  | _ => m 20

/-- `holds` (compliant): a waits at (−30 m, 0) while b crosses, then pulls away east behind it. At
    t = 0 and 1000 ms the closest approach the two reference points are predicted to reach lies 7 s
    and 6 s ahead, beyond the 5 s horizon, so none is predicted within the horizon there; at every
    later observation one is predicted and the centre distance at it — 30 m while a stands, about
    28.3 m once a moves — stays above the 10 m margin. b holds 10 m/s, so its longitudinal
    acceleration is zero at every observation and never passes the 2 m/s² bound. The concept holds
    of (a, b). The braking leaf is what this witness exercises: hold b to a deceleration past the
    bound anywhere in the window and the verdict turns violated. -/
private def aWaitsAt : Nat → Q × Q      -- position east, speed
  | 8 => (m (-30), mps 10)
  | 9 => (m (-20), mps 10)
  | _ => (m (-30), mps 0)

private def holdsTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ aCar (aWaitsAt k).1 (aWaitsAt k).2
      , bCar (bNorthAt k) (mps 10) Q.zero ]
      [ junction ]
      [ ]  -- devices

/-- `fails` (violated): a pulls out east at 10 m/s from x = −60 m across b's path. The two
    reference points are predicted to pass about 7.07 m apart, inside the 10 m margin, and that
    approach lies within the 5 s horizon at every observation from t = 2000 ms to t = 6000 ms, so
    at each counted observation (t = 4000 … 6000) and throughout its 2 s look-back a has not stayed
    clear of b. b's braking for a — −5 m/s², well past the 2 m/s² bound — comes at t = 8000 and
    9000 ms, after the counted observations, and the look-back never reaches it, so the clearance
    alone decides this witness and each of its two leaves is load-bearing. The concept fails of
    (a, b) — and would be judged separately of (b, a). -/
private def aCrossesAt : Nat → Q        -- position east
  | 0 => m (-60)
  | 1 => m (-50)
  | 2 => m (-40)
  | 3 => m (-30)
  | 4 => m (-20)
  | 5 => m (-10)
  | 6 => m 0
  | 7 => m 10
  | 8 => m 20
  | _ => m 30

/-- b north of the crossing, braking hard at the last two observations: position, speed and the
    signed acceleration along its heading. -/
private def bBrakesAt : Nat → Q × Q × Q
  | 8 => (m 10, mps 10, mps2 (-5))
  | 9 => (cm 1750, mps 5, mps2 (-5))
  | k => (bNorthAt k, mps 10, Q.zero)

private def failsTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ aCar (aCrossesAt k) (mps 10)
      , bCar (bBrakesAt k).1 (bBrakesAt k).2.1 (bBrakesAt k).2.2 ]
      [ junction ]
      [ ]  -- devices

/-- `blind` (unknown): the same crossing, but the source's capability manifest declares
    kin.velocity and kin.speed absent, and the scenes it builds carry the two bodies' positions,
    headings and extents and nothing of their motion. Neither primitive has velocities to predict
    from, so prim.closest_approach_within and prim.closest_approach_distance are unknown at every
    observation of every window. b's longitudinal acceleration is observed and zero, within the
    bound, so nothing else decides the conjunction. The concept reports unknown, for the absent
    kin.velocity and for nothing else. -/
private def blindTrace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ aSeen (aCrossesAt k)
      , bSeen (bNorthAt k) Q.zero ]
      [ junction ]
      [ ]  -- devices

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (window : Option (Timestamp × Timestamp) := none) (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant (some (2000, 9000))
  , witness "fails" failsTrace .violated (some (4000, 6000))
  , witness "blind" blindTrace (.unknown []) (some (2000, 9000)) ["kin.velocity", "kin.speed"] ]

end TrafficSpecWitness.Concepts.interaction.precedence_granted
