/-
  Witnesses for NRS_484B_267_2f_o2.

  Geometry (the witness's own figures, nowhere in the rule): a straight eastbound carriageway of
  three lanes along +x, x from -50 m to 300 m — lane 101 y ∈ [-2, 2) (the subject's), lane 102
  y ∈ [2, 6) (the official vehicle's, adjacent to 101), lane 103 y ∈ [-6, -2) (not adjacent to 102).
  Six observations, one second apart. The subject (track 1, a motor vehicle) starts at x = 0 at
  15 m/s. Track 2 is an official vehicle of a regulatory agency with a red flashing front warning
  lamp, no arm signal and no turn indicator; it moves at 5 m/s from x = 100 m (k = 0, 1) and, where
  it stops, stands at x = 110 m from k = 2. The subject stays behind it, its centre distance
  between about 35 m and 100 m: well within the 150 m approach reach, and its speed well above the
  0.1 m/s halt tolerance. The subject's line of sight to track 2 is supplied (`visible`), since Core
  never computes it.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_2f_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_267_2f_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def lanes : List Structure :=
  [ Build.rect 101 .lane (m (-50)) (m (-2)) (m 300) (m 2)
  , Build.rect 102 .lane (m (-50)) (m 2) (m 300) (m 6)
  , Build.rect 103 .lane (m (-50)) (m (-6)) (m 300) (m (-2)) ]

/-- The subject: at 15 m/s in lane 101, or (`moveOver`) slowing to 5 m/s into lane 103 from k = 2. -/
def subjectAt (k : Nat) (moveOver : Bool) : RoadUser :=
  let kk : Int := Int.ofNat k
  let late := decide (k ≥ 2)
  let x : Int := if moveOver && late then 15 + 5 * (kk - 1) else 15 * kk
  let y : Int := if moveOver && late then -4 else 0
  let v : Int := if moveOver && late then 5 else 15
  Build.user 1 [.motorVehicle] (m x, m y) Build.east (Units.metresPerSecond v) (cm 225, cm 90, cm 75)

/-- The official vehicle of a regulatory agency, red lamp flashing to the front; it halts at k = 2
    when `halts`, else keeps moving at 5 m/s. -/
def officialAt (k : Nat) (halts : Bool) : RoadUser :=
  let kk : Int := Int.ofNat k
  let stopped := halts && decide (k ≥ 2)
  let x : Int := if stopped then 110 else 100 + 5 * kk
  let v : Int := if stopped then 0 else 5
  let u := Build.user 2 [.officialVehicle] (m x, m 4) Build.east (Units.metresPerSecond v) (cm 250, cm 95, cm 80)
  Build.withSignals { u with officialKind := some .regulatoryAgency } fun s =>
    { s with warningLamps := some [{ colour := .red, mode := .flashing, facing := .front }]
             handSignal := some .noSignal
             turnIndicator := some .off }

def seen : List MeasuredRelation := [Build.relation 1 2 (fun r => { r with visible := some true })]

/-- A police officer directing traffic, governing the subject's lane. -/
def officer : Device :=
  { Build.device 10 .humanDirection [101] (some (m 120, m (-8))) with
      humanRole := some .policeOfficer, humanIndication := some .proceed }

def sceneTrace (moveOver halts : Bool) (devices : List Device) : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      (Build.scene t (some 1) [subjectAt k moveOver, officialAt k halts] lanes devices)
      seen

/-- `forbid` (violated): A police car with its red front lamp flashing moves ahead of the subject within the reach, then halts; the subject drives past it in the adjacent lane without slowing or moving over. -/
def forbidTrace : Trace := sceneTrace false true []

/-- `permit` (compliant): Same scene; the subject slows and moves to a lane not adjacent to the halted police car as it passes. -/
def permitTrace : Trace := sceneTrace true true []

/-- `idle` (not_applicable): The subject drives; no emergency or regulatory-agency vehicle is in the scene. The duty binds the subject alone. -/
def idleTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt k false] lanes []

/-- `blind` (unknown): As in forbid, but the source does not observe warning lamps. -/
def blindTrace : Trace := sceneTrace false true []

/-- `branch_1` (not_applicable): The police car, lamp flashing, keeps moving ahead of the subject and never stops. -/
def branch_1Trace : Trace := sceneTrace false false []

/-- `branch_2` (not_applicable): As in forbid, but a police officer directs traffic in the subject's lane (s6). -/
def branch_2Trace : Trace := sceneTrace false true [officer]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_267_2f_o2"
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
  , witness "blind" blindTrace (.unknown []) ["sig.warning_lamp"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_267_2f_o2
