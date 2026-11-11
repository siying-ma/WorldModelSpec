/-
  Witnesses for NRS_484B_440_1_o3.

  A rural two-lane highway running east: the highway region spans x ∈ [0, 400] m, y ∈ [-10, 10] m
  (shoulders included), its roadway x ∈ [0, 400] m, y ∈ [-4, 4] m. x (track 1, a motor vehicle,
  5 m × 2 m) stands on the roadway at (100, 0) or drives along it. The roadway's sight distance is
  30 m just beyond a crest (below the text's 200 ft = 60.96 m by a clear margin) and 300 m on the
  straight, level stretch. No scene lies in a business or residence district (the assumption is
  declared false); the engine runs and the hazard lamps are off unless the scene says otherwise.
  Three instants one second apart; the rule does not look back.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_440_1_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_440_1_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def rural : List (AsmId × Bool) := [("asm.within_business_or_residence_district", false)]

def highway : Structure := Build.rect 10 .highway (m 0) (m (-10)) (m 400) (m 10)

def roadway (sight : Q) : Structure :=
  { Build.rect 11 .roadway (m 0) (m (-4)) (m 400) (m 4) with sightDistance := some sight }

/-- x at `(px, 0)` heading east at `speed`, with its engine state and hazard lamps. -/
def car (px : Int) (speed : Q) (engine hazard : Bool) : RoadUser :=
  Build.withSignals
    (Build.withKin (Build.user 1 [.motorVehicle] (m px, m 0) Build.east speed (cm 250, cm 100, cm 80))
      (fun k => { k with engineRunning := some engine }))
    (fun s => { s with hazard := some hazard })

/-- `forbid` (violated): x (ru.motor_vehicle) halts on the roadway of a rural highway just beyond a crest, where st.sight_distance is below the literal of span g12. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 100 (Units.metresPerSecond 0) true false ]
      [ highway, roadway (m 30) ]
      [ ]
      (assumptions := rural)

/-- `permit` (compliant): x halts on a straight, level rural roadway where st.sight_distance is well above the literal. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 100 (Units.metresPerSecond 0) true false ]
      [ highway, roadway (m 300) ]
      [ ]
      (assumptions := rural)

/-- `idle` (not_applicable): x drives along the rural roadway without halting. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (100 + 15 * k) (Units.metresPerSecond 15) true false ]
      [ highway, roadway (m 30) ]
      [ ]
      (assumptions := rural)

/-- `blind` (unknown): x halts on the rural roadway near a crest, but the source does not supply sight distances. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 100 (Units.metresPerSecond 0) true false ]
      [ highway, roadway (m 30) ]
      [ ]
      (assumptions := rural)

/-- `branch_1` (not_applicable): x halts just beyond a crest with its engine not running and its hazard lamps flashing: the disabled-vehicle exception applies. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 100 (Units.metresPerSecond 0) false true ]
      [ highway, roadway (m 30) ]
      [ ]
      (assumptions := rural)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_440_1_o3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"]
  , witness "branch_1" branch_1Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_440_1_o3
