/-
  Witnesses for LVMC_11_30_090.

  Geometry (the witness's own figures, none in the rule): a highway 10, x ∈ [-50, 50],
  y ∈ [-20, 20]; on it a roadway 20, y ∈ [-7, 7], designated direction east (a roadway carries a
  direction under st.lane_direction's contract), and an eastbound lane 30, y ∈ [0, 7]; a
  sidewalk 40, y ∈ [7, 10], lying on the same highway (st.on_way). The pedestrian (track 1, half
  extents 0.3 × 0.3 × 0.9 m) moves at 1.4 m/s (well above p.halt_speed_tolerance 0.1 m/s), its
  position advanced by its velocity over three instants 1 s apart.
  - forbid: walking east in the lane (|cos| = 1 > 0.94 with both carriers).
  - permit: walking north across the lane (|cos| = 0 ≤ 0.94).
  - idle: as forbid, no sidewalk on the highway.
  - blind: as forbid, kin.velocity masked.
  - branch_1: standing at rest in the lane (speed 0).
  - branch_2: walking east on the sidewalk, on no roadway.
  - branch_3: walking north across the lane of a roadway that carries no designated direction:
    the occupied lane alone decides the crossing.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_090
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_090

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- The walking speed, 1.4 m/s. -/
def walk : Q := Units.micrometresPerSecond 1400000

def body : Q × Q × Q := (cm 30, cm 30, cm 90)

/-- Distance walked after `k` seconds. -/
def walked (k : Nat) : Q := Q.mul walk (Q.ofInt (Int.ofNat k))

def highway : Structure := Build.rect 10 .highway (m (-50)) (m (-20)) (m 50) (m 20)

def roadway : Structure :=
  { Build.rect 20 .roadway (m (-50)) (m (-7)) (m 50) (m 7) with
    ways := some [10], lane := some { direction := some Build.east } }

def roadwayNoDirection : Structure :=
  { Build.rect 20 .roadway (m (-50)) (m (-7)) (m 50) (m 7) with ways := some [10] }

def lane : Structure :=
  { Build.lane 30 [(m (-50), m 0), (m 50, m 0), (m 50, m 7), (m (-50), m 7)] Build.east with
    ways := some [10] }

def sidewalk : Structure :=
  { Build.rect 40 .sidewalk (m (-50)) (m 7) (m 50) (m 10) with ways := some [10] }

/-- Pedestrian walking east along the lane. -/
def alongLane (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (Q.add (m (-5)) (walked k), m 3) Build.east walk body

/-- Pedestrian walking north across the lane. -/
def acrossLane (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (m 0, Q.add (m 1) (walked k)) Build.north walk body

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): A pedestrian (ru.pedestrian) walks at 1.4 m/s along a lane, velocity parallel to its st.lane_direction, footprint on the roadway; a st.sidewalk lies on the same st.highway (st.on_way). -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [alongLane k] [highway, roadway, lane, sidewalk] []

/-- `permit` (compliant): On the same roadway the pedestrian walks across the lane at right angles to its st.lane_direction (drv.motion.moving_across_carrier holds). -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [acrossLane k] [highway, roadway, lane, sidewalk] []

/-- `idle` (not_applicable): A pedestrian walks along a lane of a roadway whose highway carries no st.sidewalk (no sidewalk lies on it). -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [alongLane k] [highway, roadway, lane] []

/-- `blind` (unknown): A pedestrian moves on the roadway beside which a sidewalk lies; the source does not observe kin.velocity, so whether it moves along or across the lane is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [alongLane k] [highway, roadway, lane, sidewalk] []

/-- `branch_1` (compliant): A pedestrian stands at rest on the roadway (kin.speed at or below p.halt_speed_tolerance), a sidewalk lying on the same highway. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [Build.user 1 [.pedestrian] (m 0, m 3) Build.east Q.zero body]
      [highway, roadway, lane, sidewalk] []

/-- `branch_2` (not_applicable): A pedestrian walks along the sidewalk and occupies no roadway. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [Build.user 1 [.pedestrian] (Q.add (m (-5)) (walked k), cm 850) Build.east walk body]
      [highway, roadway, lane, sidewalk] []

/-- `branch_3` (compliant): A pedestrian walks north across an eastbound lane of a roadway that
    carries no designated direction; crossing the occupied lane is crossing. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [acrossLane k] [highway, roadwayNoDirection, lane, sidewalk] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_30_090"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.LVMC_11_30_090
