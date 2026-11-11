/-
  Witnesses for NRS_484D_100_1.

  Geometry: a highway 200 m long east–west, its boundary lines at y = −10 m and y = +10 m, with a
  roadway between y = −5 m and y = +5 m inside it (the strips beyond are shoulder and sidewalk,
  part of the highway). The car (track 1, a motor vehicle, 4.5 m × 1.8 m) drives east along
  y = 0 at 10 m/s with its engine running, three observations one second apart; parked, it stands
  at y = −7 m, on the highway beside the roadway, at 0 m/s with its engine off.
  Light: night is env.darkness true; day is false. Visibility: 2 km on a clear day or a clear
  night, 50 m in thick fog — far either side of 1,000 ft (304.8 m). The run's speed resolution
  (0.2 m/s) lies far from both 10 m/s and 0 m/s. No device in any scene.
-/
import TrafficSpec.Rules.NRS_484D.NRS_484D_100_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484D_100_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def structures : List Structure :=
  [ Build.rect 10 .highway (m 0) (m (-10)) (m 200) (m 10)
  , Build.rect 11 .roadway (m 0) (m (-5)) (m 200) (m 5) ]

def carBody : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The car driving east on the roadway at 10 m/s, engine running, with the given headlamps. -/
def movingCar (k : Nat) (lamp : HeadlampState) : RoadUser :=
  Build.withSignals
    (Build.withKin
      (Build.user 1 [.motorVehicle] (m (50 + 10 * (k : Int)), m 0) Build.east
        (Units.metresPerSecond 10) carBody)
      fun kn => { kn with engineRunning := some true })
    fun sg => { sg with headlamp := some lamp }

/-- The car standing beside the roadway on the highway, engine off, headlamps off. -/
def parkedCar : RoadUser :=
  Build.withSignals
    (Build.withKin
      (Build.user 1 [.motorVehicle] (m 50, m (-7)) Build.east Q.zero carBody)
      fun kn => { kn with engineRunning := some false })
    fun sg => { sg with headlamp := some .off }

def night : Env := { darkness := some true, visibility := some (m 2000) }
def clearDay : Env := { darkness := some false, visibility := some (m 2000) }
def foggyDay : Env := { darkness := some false, visibility := some (m 50) }

def drive (lamp : HeadlampState) (env : Env) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [movingCar k lamp] structures [] (env := env)

/-- `forbid` (violated): At night (env.darkness) a passenger car moves on a highway roadway with its headlamps off (sig.headlamp off). -/
def forbidTrace : Trace := drive .off night

/-- `permit` (compliant): At night the car moves on the highway with its low beam lit. -/
def permitTrace : Trace := drive .lowBeam night

/-- `idle` (not_applicable): In clear daylight with a long visibility distance and no sign in the scene, the car moves on the highway with its headlamps off. -/
def idleTrace : Trace := drive .off clearDay

/-- `blind` (unknown): As forbid, but the source does not observe headlamps. -/
def blindTrace : Trace := drive .off night

/-- `branch_1` (violated): By day in thick fog, with a visibility distance below 1,000 ft, the car moves on the highway with its headlamps off. -/
def branch_1Trace : Trace := drive .off foggyDay

/-- `branch_2` (not_applicable): At night a car stands parked at the side of the highway, halted with its engine off and its headlamps off. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [parkedCar] structures [] (env := night)

/-- `branch_3` (compliant): By day in thick fog, with a visibility distance below 1,000 ft, the car moves on the highway with its low beam lit. -/
def branch_3Trace : Trace := drive .lowBeam foggyDay

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484D_100_1"
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
  , witness "blind" blindTrace (.unknown []) ["sig.headlamp"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.NRS_484D_100_1
