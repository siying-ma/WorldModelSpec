/-
  Witnesses for NRS_484D_100_1.

  The highway is one rectangle 400 m long and 20 m wide (x from -100 to 300 m, y from -10 to 10 m).
  x (track 1) is a motor vehicle, half-extent 2 m × 1 m × 75 cm, heading east along y = 0; it drives
  at 10 m/s (moving 10 m a second, far above the speed tolerance) with its engine running, or, in
  the parked and halted scenes, stands at speed 0 at (0, 8), near the highway's edge. Three
  instants a second apart. Night is env.darkness true; daytime is false. Clear air is a visibility of
  5,000 m, fog one of 100 m (both far from the 1,000 ft ≈ 305 m bound). No device is built. Every
  figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484D.NRS_484D_100_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484D_100_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def highway : Structure := Build.rect 100 .highway (m (-100)) (m (-10)) (m 300) (m 10)

/-- x driving east at 10 m/s, engine running, with the given lamps. -/
def driving (k : Nat) (head : HeadlampState) (pos : Bool) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 1 [.motorVehicle] (m (10 * k), m 0) Build.east (Units.metresPerSecond 10)
        (m 2, m 1, cm 75))
      fun s => { s with headlamp := some head, positionLamp := some pos })
    fun kn => { kn with engineRunning := some true }

/-- x standing at (0, 8), speed 0, engine as given, lamps off. -/
def halted (engine : Bool) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 1 [.motorVehicle] (m 0, m 8) Build.east Q.zero (m 2, m 1, cm 75))
      fun s => { s with headlamp := some .off, positionLamp := some false })
    fun kn => { kn with engineRunning := some engine }

def night : Env := { darkness := some true, visibility := some (m 5000) }
def clearDay : Env := { darkness := some false, visibility := some (m 5000) }
def fogDay : Env := { darkness := some false, visibility := some (m 100) }
def clearUnlit : Env := { visibility := some (m 5000) }

def sceneTrace (env : Env) (u : Nat → RoadUser) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [u k] [highway] [] (env := env)

/-- `forbid` (violated): At night (env.darkness), x, a car, drives alone on a highway with its headlamps off and its position lamps off. -/
def forbidTrace : Trace := sceneTrace night fun k => driving k .off false

/-- `permit` (compliant): At night, x drives on a highway with low beams and position lamps lit. -/
def permitTrace : Trace := sceneTrace night fun k => driving k .lowBeam true

/-- `idle` (not_applicable): Daytime, clear air with visibility far beyond the stated distance, no device directing lamps; x drives on a highway with its lamps off. -/
def idleTrace : Trace := sceneTrace clearDay fun k => driving k .off false

/-- `blind` (unknown): The source declares env.darkness absent; the air is clear, no device directs lamps, and x drives with its lamps off. -/
def blindTrace : Trace := sceneTrace clearUnlit fun k => driving k .off false

/-- `branch_1` (violated): Daytime fog: visibility below the stated distance; x drives with its headlamps off. -/
def branch_1Trace : Trace := sceneTrace fogDay fun k => driving k .off false

/-- `branch_2` (not_applicable): At night, x stands halted beside the roadway with its engine off and its lamps off: it is parked. -/
def branch_2Trace : Trace := sceneTrace night fun _ => halted false

/-- `branch_3` (violated): At night, x drives with high beams lit but its position lamps off. -/
def branch_3Trace : Trace := sceneTrace night fun k => driving k .highBeam false

/-- `branch_4` (violated): At night, x stands halted on the highway with its engine running and its lamps off: it is not parked. -/
def branch_4Trace : Trace := sceneTrace night fun _ => halted true

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
  , witness "blind" blindTrace (.unknown []) ["env.darkness"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.NRS_484D_100_1
