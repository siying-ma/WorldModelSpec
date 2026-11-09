/-
  Witnesses for NRS_484B_600_1e.

  The geometry. One straight highway region, a 20 m wide strip from x = -50 m to x = 2000 m
  centred on y = 0, running east. The subject is track 1, a motor vehicle 4.6 m long and 1.8 m
  wide (half-extents below), travelling east along the strip. Each trace is three instants one
  second apart; the subject's position advances by about the distance its speed carries it, and
  its speed is held constant over the recording.

  The parking bay of the `idle` scene is a separate 6 m × 3 m rectangle beside the strip at
  x = 300 m, y = 14 m; the subject stands in it with its engine running at zero speed.

  Every figure here is the witness's own and appears nowhere in the rule. The run's reading
  supplies p.standstill_speed_tolerance = 0.1 m/s and the rule carries the statute's 80 mph
  (35.76 m/s), so the speeds are set to break or keep each bound by a clear margin: 95 mph
  (42.47 m/s) above the cap, 65 mph (29.06 m/s) below it, and 0 m/s well inside the tolerance.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

/-- Half-length, half-width, half-height of the subject car: 2.3 m × 0.9 m × 0.75 m. -/
def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)

/-- The highway the subject runs on. -/
def highway : Structure := Build.rect 10 .highway (m (-50)) (m (-10)) (m 2000) (m 10)

/-- The parking bay beside the highway, where the `idle` subject stands. -/
def parkingBay : Structure := Build.rect 11 .parkingSpace (m 297) (m 12) (m 303) (m 15)

/-- The subject at instant `k`, running east along the highway at `speed` m/s, advancing
    `step` metres per instant. -/
def runner (k : Nat) (speed step : Q) (classes : List RoadUserClass) : RoadUser :=
  Build.user 1 classes (Q.add (m 100) (Q.mul step (Q.ofInt (Int.ofNat k))), Q.zero)
    Build.east speed carExtent (some (Q.mul step (Q.ofInt (Int.ofNat k))))

/-- `forbid` (violated): The subject runs along an open highway at a speed above the figure the
    text states — 95 mph against the stated 80. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k (Units.mph 95) (m 42) [.motorVehicle] ]
      [ highway ]
      []

/-- `permit` (compliant): The subject runs along the same highway at a speed below the figure the
    text states — 65 mph — holding it for the whole recording. No other road user is present. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k (Units.mph 65) (m 29) [.motorVehicle] ]
      [ highway ]
      []

/-- `idle` (not_applicable): The subject stands in the parking bay with its engine running, its
    speed zero and so within the standstill tolerance: it is not driven or operated. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m 300, m 13) Build.east Q.zero carExtent (some Q.zero))
          (fun kin => { kin with engineRunning := some true, parkingBrake := some true }) ]
      [ highway, parkingBay ]
      []

/-- `blind` (unknown): The subject is on the highway and the source supplies no magnitude of
    velocity for it, so neither whether it is in motion nor whether its speed exceeds the stated
    figure can be told. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k (Units.mph 65) (m 29) [.motorVehicle] ]
      [ highway ]
      []

/-- `branch_1` (not_applicable): the same fast run along the highway, but the body is a bicycle,
    a class the admitted aggregate does not include, so no vehicle of the statute is before us. -/
def branch1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runner k (Units.mph 95) (m 42) [.bicycle] ]
      [ highway ]
      []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1e"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch1Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_600_1e
