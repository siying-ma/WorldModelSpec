/-
  Witnesses for NRS_484D_400_5.

  One vehicle (track 1) drives east along y = 0 at 10 m/s for three instants one second apart,
  starting at x = 0; no structures or devices are needed (the rule reads only the subject's class,
  its warning lamps and its siren). The police car carries the classes emergency_vehicle and
  motor_vehicle with emergency kind police; the private car carries motor_vehicle only. Warning
  lamps are observed in every scene (`some []` when none is lit). Every figure here is the
  witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484D.NRS_484D_400_5
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484D_400_5

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The subject's body at instant `k`: driving east at 10 m/s. -/
def body (classes : List RoadUserClass) (k : Nat) : RoadUser :=
  Build.user 1 classes (m (10 * (k : Int)), m 0) Build.east (Units.metresPerSecond 10)
    (cm 240, cm 95, cm 75) (some (m (10 * (k : Int))))

def policeCar (k : Nat) : RoadUser :=
  { body [.emergencyVehicle, .motorVehicle] k with emergencyKind := some .police }

def privateCar (k : Nat) : RoadUser := body [.motorVehicle] k

/-- `forbid` (violated): A police car (authorized emergency vehicle) drives with sig.siren sounding and no sig.warning_lamp lit. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withSignals (policeCar k) fun s =>
          { s with siren := some true, warningLamps := some [] } ]
      [ ]
      [ ]

/-- `permit` (compliant): The police car drives with sig.siren silent and no warning lamp lit. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withSignals (policeCar k) fun s =>
          { s with siren := some false, warningLamps := some [] } ]
      [ ]
      [ ]

/-- `idle` (not_applicable): The subject is a private passenger car, not an authorized emergency vehicle; its siren is not observed to sound. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withSignals (privateCar k) fun s =>
          { s with siren := some false, warningLamps := some [] } ]
      [ ]
      [ ]

/-- `blind` (unknown): The police car drives with no warning lamp lit; the source has no audio, sig.siren absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withSignals (policeCar k) fun s =>
          { s with siren := none, warningLamps := some [] } ]
      [ ]
      [ ]

/-- `branch_1` (not_applicable): The police car drives with red and blue sig.warning_lamp flashing and sig.siren sounding: operated in response to a call. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withSignals (policeCar k) fun s =>
          { s with siren := some true,
                   warningLamps := some [ { colour := .red, mode := .flashing, facing := .front }
                                        , { colour := .blue, mode := .flashing, facing := .front } ] } ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484D_400_5"
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
  , witness "blind" blindTrace (.unknown []) ["sig.siren"]
  , witness "branch_1" branch_1Trace .notApplicable ]

end TrafficSpecWitness.NRS_484D_400_5
