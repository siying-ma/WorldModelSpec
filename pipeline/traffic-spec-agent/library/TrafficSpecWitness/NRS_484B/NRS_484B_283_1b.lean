/-
  Witnesses for NRS_484B_283_1b.

  Geometry (the witness's own figures; none appears in the rule): a roadway, the rectangle
  x ∈ [-200, 50], y ∈ [0, 10] m; a place of safety beside it, x ∈ [-200, 50], y ∈ [10, 14] m (a
  sidewalk, or in branch_4 a safety zone, in branch_5 a median or divider). The roadway carries an
  eastbound direction and one eastbound lane over it (the composed exceptions read lane direction),
  and a marked crosswalk x ∈ [-3, 3] where the pedestrian steps off (so that the composed
  crossing-outside-a-crosswalk exceptions are not engaged). Three instants 1 s
  apart. The pedestrian (track 1) walks south at 1 m/s: (0, 10.5) on the place of safety at k = 0,
  (0, 9.5) on the roadway at k = 1 (the instant of leaving), (0, 8.5) at k = 2. A car (track 2)
  drives east in the roadway; placed at k = 1 at (-v·T, 9.5 - T) with speed v, its centre meets the
  pedestrian's after T seconds (closest approach distance 0).
    forbid: v = 12, T = 1 (dry): 2·6·1 = 12 < 2·6·1.5 + 12 = 30.
    permit: car 70 m away: closest approach after ≈ 5.8 s, beyond the 3 s horizon.
    branch_2 (wet): v = 12, T = 2.75: 2·4·2.75 = 22 < 24; dry would give 33 ≥ 30.
    branch_3 (ice): v = 6, T = 2.6: 2·1·2.6 = 5.2 < 9; wet would give 20.8 ≥ 18, dry 31.2 ≥ 24.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_283_1b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_283_1b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def dry : Env := { wetRoad := some false, iceOrSnow := some false }
def wet : Env := { wetRoad := some true, iceOrSnow := some false }
def icy : Env := { wetRoad := some false, iceOrSnow := some true }

def roadway : Structure :=
  { Build.rect 100 .roadway (m (-200)) (m 0) (m 50) (m 10) with
    lane := some { direction := some Build.east } }

/-- A marked crosswalk across the roadway where the pedestrian steps off. -/
def crosswalk : Structure :=
  { Build.rect 103 .crosswalk (m (-3)) (m 0) (m 3) (m 10) with marked := some true }
def safePlace (k : StructureKind) : Structure := Build.rect 101 k (m (-200)) (m 10) (m 50) (m 14)

/-- The roadway's single eastbound lane, covering it (its direction is observed). -/
def eastLane : Structure :=
  Build.lane 102 [(m (-200), m 0), (m 50, m 0), (m 50, m 10), (m (-200), m 10)] Build.east
    none none (some 1) (some 1)

/-- The pedestrian stepping south off the place of safety at 1 m/s. -/
def stepper (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (m 0, cm (1050 - 100 * (k : Int))) Build.south (Units.metresPerSecond 1)
    (cm 30, cm 30, cm 90)

/-- The pedestrian standing on the place of safety. -/
def stander : RoadUser :=
  Build.user 1 [.pedestrian] (m 0, m 12) Build.south (Units.metresPerSecond 0) (cm 30, cm 30, cm 90)

/-- A car driving east: x = x0 + v·k (cm), at lateral position y (cm). -/
def car (k : Nat) (x0cm : Int) (ycm : Int) (v : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm (x0cm + 100 * v * (k : Int)), cm ycm) Build.east
    (Units.metresPerSecond v) (cm 225, cm 90, cm 75)

def sceneOf (t : Timestamp) (users : List RoadUser) (place : StructureKind) (env : Env) : Scene :=
  Build.scene t (some 1) users [roadway, eastLane, crosswalk, safePlace place] [] (env := env)

/-- `forbid` (violated): Dry road. The pedestrian steps from the sidewalk onto the roadway while a car 12 m away moves toward it at 12 m/s; predicted closest approach 0.5 m in 1.0 s, below 1.5 s + 12/(2·6) s. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t [stepper k, car k (-2400) 850 12] .sidewalk dry

/-- `permit` (compliant): The pedestrian steps off while the car is 70 m away at 12 m/s: no closest approach within the horizon. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t [stepper k, car k (-8200) 850 12] .sidewalk dry

/-- `idle` (not_applicable): The pedestrian stays on the sidewalk throughout. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t [stander, car k (-2400) 850 12] .sidewalk dry

/-- `blind` (unknown): A car is 12 m away at 12 m/s on a collision course, but whether the pedestrian's footprint overlaps the roadway or the sidewalk is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t [stepper k, car k (-2400) 850 12] .sidewalk dry

/-- `branch_1` (compliant): The pedestrian steps off the sidewalk with no vehicle in the scene: the duty binds the pedestrian alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t [stepper k] .sidewalk dry

/-- `branch_2` (violated): Wet road; car at 12 m/s, closest approach in 2.75 s: too close on a
    wet surface (it would not be on a dry one). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t [stepper k, car k (-4500) 675 12] .sidewalk wet

/-- `branch_3` (violated): Icy road; car at 6 m/s, closest approach in 2.6 s: too close on ice
    (it would not be on a wet or dry one). -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t [stepper k, car k (-2160) 690 6] .sidewalk icy

/-- `branch_4` (violated): As forbid, but the pedestrian steps off a safety zone. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t [stepper k, car k (-2400) 850 12] .safetyZone dry

/-- `branch_5` (violated): As forbid, but the pedestrian steps off a median or divider. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t [stepper k, car k (-2400) 850 12] .medianOrDivider dry

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_283_1b"
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
  , { witness "blind" blindTrace (.unknown []) ["rel.occupies"] with window := some (1000, 2000) }
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_283_1b
