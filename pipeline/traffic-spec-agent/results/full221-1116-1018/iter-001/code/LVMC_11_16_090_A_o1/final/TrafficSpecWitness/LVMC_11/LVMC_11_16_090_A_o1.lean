/-
  Witnesses for LVMC_11_16_090_A_o1.

  Geometry (the witness's own figures, none of them in the rule): a highway region, the rectangle
  x ∈ [0, 2000] m, y ∈ [-10, 10] m, traffic eastbound. Cars are 5 m long and 2 m wide
  (half-extents 2.5 m × 1 m × 0.75 m). The subject (track 1) drives at y = -2 m; a second car
  (track 2), where present, drives abreast at y = +2 m with the same x, so the two bodies share
  their whole length along the heading. Six instants one second apart (t = 0 … 5000 ms); the
  judged instants are t = 4000 and 5000 ms, whose contest window behind is fully recorded.

  Against the reading (exhibition accel 4.0 m/s², exhibition speed 44.7 m/s, contest accel
  2.5 m/s², contest window 3 s, same-direction cosine 0.95):
    forbid    both cars accelerate at 3 m/s² abreast eastbound, speeds 10 … 25 m/s: a contest,
              below each exhibition bound.
    permit    the subject alone accelerates at 2 m/s² from 5 m/s: below every bound.
    idle      the subject, accelerating at 5 m/s², is in a parking lot north of the highway
              (y = 50 m), occupying no highway region.
    blind     the subject alone at 15 m/s; its acceleration is masked.
    branch_1  the subject alone accelerates at 5 m/s², speeds 10 … 35 m/s: exhibition of power.
    branch_2  the subject alone cruises at 50 m/s, no acceleration: exhibition of speed.
    branch_3  the forbid scene, but the other car accelerates at only 1 m/s²: no contest.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_16_090_A_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_16_090_A_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The highway region. -/
def highway : Structure := Build.rect 10 .highway (m 0) (m (-10)) (m 2000) (m 10)

/-- An eastbound motor vehicle with its speed and longitudinal acceleration. -/
def car (track : TrackId) (x y : Q) (speed accel : Q) : RoadUser :=
  Build.withKin
    (Build.user track [.motorVehicle] (x, y) Build.east speed (cm 250, m 1, cm 75))
    fun k => { k with accelLongitudinal := some accel }

/-- `forbid` (violated): Two motor vehicles side by side in the same direction on a highway both accelerating above p.contest_accel_min for the whole p.contest_window. -/
def forbidTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    let x := m (50 + 15 * (k : Int))
    let v := Units.metresPerSecond (10 + 3 * (k : Int))
    Build.scene t (some 1)
      [ car 1 x (m (-2)) v (Units.metresPerSecondSq 3)
      , car 2 x (m 2) v (Units.metresPerSecondSq 3) ]
      [ highway ]
      [ ]

/-- `permit` (compliant): The subject accelerates moderately from a light, below every bound, alone in its direction. -/
def permitTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (50 + 6 * (k : Int))) (m (-2)) (Units.metresPerSecond (5 + 2 * (k : Int)))
          (Units.metresPerSecondSq 2) ]
      [ highway ]
      [ ]

/-- `idle` (not_applicable): The subject is in a private parking lot that is no highway region. -/
def idleTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (100 + 5 * (k : Int))) (m 50) (Units.metresPerSecond (2 + 5 * (k : Int)))
          (Units.metresPerSecondSq 5) ]
      [ highway ]
      [ ]

/-- `blind` (unknown): Accelerations are not observed and the subject's speed is below the speed bound. -/
def blindTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (50 + 15 * (k : Int))) (m (-2)) (Units.metresPerSecond 15)
          (Units.metresPerSecondSq 2) ]
      [ highway ]
      [ ]

/-- `branch_1` (violated): No other road user in the scene; the subject alone accelerates above p.exhibition_accel_min (exhibition of power). -/
def branch_1Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (50 + 20 * (k : Int))) (m (-2)) (Units.metresPerSecond (10 + 5 * (k : Int)))
          (Units.metresPerSecondSq 5) ]
      [ highway ]
      [ ]

/-- `branch_2` (violated): the subject alone cruises at 50 m/s, far above p.exhibition_speed_min,
    without accelerating (exhibition of speed). -/
def branch_2Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (50 + 50 * (k : Int))) (m (-2)) (Units.metresPerSecond 50)
          (Units.metresPerSecondSq 0) ]
      [ highway ]
      [ ]

/-- `branch_3` (compliant): two motor vehicles abreast in the same direction, the subject
    accelerating at 3 m/s² but the other only at 1 m/s², below p.contest_accel_min: no contest. -/
def branch_3Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    let x := m (50 + 15 * (k : Int))
    let v := Units.metresPerSecond (10 + 3 * (k : Int))
    Build.scene t (some 1)
      [ car 1 x (m (-2)) v (Units.metresPerSecondSq 3)
      , car 2 x (m 2) v (Units.metresPerSecondSq 1) ]
      [ highway ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_16_090_A_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (4000, 5000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.accel_longitudinal"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.LVMC_11_16_090_A_o1
