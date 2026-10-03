/-
  Witnesses for drv.interaction.precedence_granted.

  The place, one crossing for all three scenarios: a's eastbound lane (region 10) along y = 0, four
  metres wide, from x = -60 m to x = 60 m; b's northbound lane (region 11) along x = 7.5 m, four
  metres wide, from y = -30 m to y = 30 m; and the intersection of the two (region 12), x in
  [5.5, 9.5] m, y in [-2, 2] m. a is a tracked motor vehicle (track 1, a 4 m x 2 m body) heading
  east on y = 0; b is a tracked motor vehicle (track 2, a 4 m x 2 m body) heading north on
  x = 7.5 m, crossing in front of a at a steady 3 m/s from y = -9 m to y = 12 m. Each trace is
  eight observations one second apart, t = 0 ms ... 7000 ms.

  How the gap reads here. Core takes the components of the gap in a's frame, a heading east, so
  the longitudinal component is |b.x - a.x| less the two half-lengths (2 m each, so less 4 m) and
  the lateral component is |b.y - a.y| less the two half-widths (1 m each, so less 2 m).

  The instance's own figures: yield_clearance = 3 m (a body's width of daylight along an axis),
  yield_window = 3 s, yield_closure_allowance = 0.5 m (the depth attributed to noise in the gap,
  so the longitudinal floor is 2.5 m).

  The instants the witnesses speak about: t = 3000 ms to t = 7000 ms. A three-second lookback runs
  off the start of the trace before t = 3000 ms — unknown for truncation, by Core's finite-trace
  policy, and not about the concept — while at t = 3000 ms and after, the window is both covered
  (the observation three seconds back is in the trace) and adequately sampled (the one-second
  spacing is at most half the window).

    holds: a stands at the entrance of the intersection at x = 0 while b crosses in front of it,
      then edges 0.75 m forward once b has gone by and stands again. While b is crossing (t = 0 s
      ... 4000 ms, b from y = -9 m to y = 3 m) the longitudinal component is 3.5 m and carries the
      standing-apart condition on its own, which it must, since at t = 3000 ms b is square in
      front of a and the lateral component is -2 m. Once b has gone by, a edges forward and the
      longitudinal component drops to 2.75 m — below the clearance but above the 2.5 m floor — and
      the lateral component (4 m, 7 m, 10 m) carries the condition instead. Both disjuncts are
      therefore exercised, and the longitudinal component never sits below the floor: compliant.
    fails: the same crossing, but a does not wait — it comes east at a steady 3 m/s from x = -6 m.
      At t = 3000 ms b is square in front of a (lateral component -2 m) and a is 4.5 m from it,
      so the longitudinal component is 0.5 m: neither axis reaches the 3 m clearance and the
      longitudinal component sits 2 m below the clearance, far more than the 0.5 m allowance, so
      a has drawn in on b. Every window from t = 3000 ms on contains that observation: violated.
    blind: the `holds` trace, under a manifest that declares rel.surface_gap absent together with
      the kin.position and kin.extent from which Core would otherwise compute it. The windows are
      covered and adequately sampled, so the only reason left is the unreadable gap: unknown.

  Which axis carries which phase is this witness's own: the record's narrative pairs the lateral
  component with b's crossing and the longitudinal with b's departure, and the pairing is the
  other way round in any geometry where "crossing in front" means passing through a's longitudinal
  axis, since there the lateral component is at its smallest. The scenario the record asks for —
  one axis or the other reaching the clearance at every observation, the longitudinal never below
  the floor — is what is built.
-/
import TrafficSpec.Concepts.interaction.precedence_granted
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.precedence_granted

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.precedence_granted@w"
    concept := "drv.interaction.precedence_granted"
    literals := []
    nats := []
    params :=
      [ ("yield_clearance", .lit (Units.metres 3) .metre)                  -- 3 m
      , ("yield_window", .lit (Units.seconds 3) .second)                   -- 3 s
      , ("yield_closure_allowance", .lit (Units.centimetres 50) .metre) ]  -- 0.5 m
    bounds := none }

def instances : List Concept.Instance := [inst]

-- The place: a's eastbound lane, b's northbound lane, and the intersection of the two.
private def aLane : Structure :=
  Build.lane 10 [(m (-60), m (-2)), (m 60, m (-2)), (m 60, m 2), (m (-60), m 2)] Build.east
private def bLane : Structure :=
  Build.lane 11 [(cm 550, m (-30)), (cm 950, m (-30)), (cm 950, m 30), (cm 550, m 30)] Build.north
private def theCrossing : Structure :=
  Build.rect 12 .intersection (cm 550) (m (-2)) (cm 950) (m 2)

/-- a at an instant: a 4 m x 2 m car on y = 0 heading east at `(x, 0)` with speed `v`. -/
private def carA (x v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, Q.zero) Build.east v (m 2, m 1, m 1)

/-- b at an instant: a 4 m x 2 m car on x = 7.5 m heading north at `(7.5, y)` with speed `v`. -/
private def carB (y v : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm 750, y) Build.north v (m 2, m 1, m 1)

private def place (t : Timestamp) (a b : RoadUser) : Scene :=
  Build.scene t (some 1) [a, b] [aLane, bLane, theCrossing] []

/-- b crosses in front of a at a steady 3 m/s: y = -9 m, -6 m, … , 12 m. -/
private def crossY (k : Nat) : Q := m (-9 + 3 * Int.ofNat k)

-- The wait: a stands at x = 0 while b crosses, edges 0.75 m forward once b has gone by, stands.
private def waitX : Nat → Q
  | 0 | 1 | 2 | 3 | 4 => Q.zero
  | _ => cm 75

private def waitSpeed : Nat → Q
  | 5 => Units.micrometresPerSecond 750000   -- 0.75 m/s, the one second of edging forward
  | _ => Q.zero

/-- `holds` (compliant): a waits at the entrance of the crossing while b crosses in front of it and
    departs; at every observation of yield_window the two bodies stand apart by at least
    yield_clearance along one of a's axes — longitudinally while b crosses in front, laterally once
    b has gone by and a has edged forward — and the longitudinal component of the gap never sits
    below yield_clearance less yield_closure_allowance, so a has kept out of b's way. -/
private def holdsTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    place t (carA (waitX k) (waitSpeed k)) (carB (crossY k) (mps 3))

/-- `fails` (violated): a moves into b's path at a steady 3 m/s from x = -6 m: at t = 3000 ms,
    within yield_window of every later observation, the two bodies stand apart by yield_clearance
    along neither of a's axes, and the longitudinal component of the gap sits more than
    yield_closure_allowance below that clearance, so a has drawn in on b rather than kept out of
    its way. -/
private def failsTrace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    place t (carA (m (-6 + 3 * Int.ofNat k)) (mps 3)) (carB (crossY k) (mps 3))

/-- `blind` (unknown): The same pair of tracks as in holds, but the source's capability manifest
    declares rel.surface_gap absent together with the kin.position and kin.extent from which Core
    would otherwise compute it; neither component of the gap can be read at any observation of the
    window, so neither condition is decided and the concept reports unknown. -/
private def blindTrace : Trace := holdsTrace

/-- Every witness speaks about t = 3000 ms … 7000 ms: before t = 3000 ms the three-second lookback
    runs off the start of the trace, which is unknown for truncation and not about the concept. -/
private def spoken : Timestamp × Timestamp := (3000, 7000)

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected
    window := some spoken }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap", "kin.position", "kin.extent"] ]

end TrafficSpecWitness.Concepts.interaction.precedence_granted
