/-
  Witnesses for NRS_484D_165_3.

  Geometry (the witness's own figures, nowhere in the rule): a highway region 10 spanning
  x ∈ [-50, 50] m, y ∈ [-10, 10] m; on it (ways [10]) a roadway 11 at y ∈ [-4, 4] m and a paved
  shoulder 12 at y ∈ [4, 7] m. A car (track 1, motor vehicle) of half-extent 2.25 × 0.9 × 0.75 m
  stands at speed 0 (well under the 0.1 m/s tolerance), heading east, either at (0, 0) on the
  roadway or at (0, 5.5) on the shoulder. Three instants, 1 s apart, all alike.

  Light: night is env.darkness true with visibility 2,000 m; day is darkness false with visibility
  5,000 m (both far above 1,000 ft = 304.8 m); fog is darkness false with visibility 120 m (far
  below 304.8 m).
-/
import TrafficSpec.Rules.NRS_484D.NRS_484D_165_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484D_165_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 10 .highway (m (-50)) (m (-10)) (m 50) (m 10)
def roadway : Structure :=
  { Build.rect 11 .roadway (m (-50)) (m (-4)) (m 50) (m 4) with ways := some [10], paved := some true }
def shoulder : Structure :=
  { Build.rect 12 .shoulder (m (-50)) (m 4) (m 50) (m 7) with ways := some [10], paved := some true }

def structures : List Structure := [highway, roadway, shoulder]

def car (pos : Vec) (lamps : Option Bool) : RoadUser :=
  Build.withSignals
    (Build.user 1 [.motorVehicle] pos Build.east Q.zero (cm 225, cm 90, cm 75))
    (fun s => { s with positionLamp := lamps })

def onRoadway : Vec := (m 0, m 0)
def onShoulder : Vec := (m 0, cm 550)

def night : Env := { darkness := some true, visibility := some (m 2000) }
def day : Env := { darkness := some false, visibility := some (m 5000) }
def fog : Env := { darkness := some false, visibility := some (m 120) }

def standing (pos : Vec) (lamps : Option Bool) (env : Env) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [car pos lamps] structures [] (env := env)

/-- `forbid` (violated): A car of the vehicle aggregate stands at rest on the roadway at night (env.darkness true), position lamps off. -/
def forbidTrace : Trace := standing onRoadway (some false) night

/-- `permit` (compliant): As forbid, but its position lamps are lit. -/
def permitTrace : Trace := standing onRoadway (some true) night

/-- `idle` (not_applicable): A car stands at rest on the roadway by day, visibility 5,000 m. -/
def idleTrace : Trace := standing onRoadway (some false) day

/-- `blind` (unknown): A car stands at rest on the roadway at night; the source does not observe position lamps. -/
def blindTrace : Trace := standing onRoadway none night

/-- `branch_1` (violated): A car stands at rest on the paved shoulder of the highway by day in fog, env.visibility 120 m, position lamps off. -/
def branch_1Trace : Trace := standing onShoulder (some false) fog

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484D_165_3"
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
  , witness "blind" blindTrace (.unknown []) ["sig.position_lamp"]
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484D_165_3
