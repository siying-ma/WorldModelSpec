/-
  Witnesses for NRS_484B_600_1e.

  One road user, track 1 (the subject), travelling east along y = 0 over three instants one second
  apart; no structures or devices are needed, since the rule reads only the subject's class and speed.
    forbid: a motor vehicle at 38 m/s (≈ 85 mph), above the 80 mph (≈ 35.76 m/s) bound.
    permit: a motor vehicle at 33 m/s (≈ 74 mph), below it.
    idle:   a pedestrian walking at 1.4 m/s — not a member of DEF-NRS-484A-320::vehicle.
    blind:  a motor vehicle moving, its speed field unset and kin.speed absent from the manifest.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A car's half-extents: half-length 2.3 m, half-width 0.9 m, half-height 0.75 m. -/
def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)

/-- A pedestrian's half-extents. -/
def pedExtent : Q × Q × Q := (cm 25, cm 25, cm 90)

/-- The subject car at instant `k`, moving east at `v` m/s. -/
def car (k : Nat) (v : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (v * k), m 0) Build.east (Units.metresPerSecond v) carExtent

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): The subject car's kin.speed is 38 m/s (about 85 mph). -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k 38 ]
      [ ]
      [ ]

/-- `permit` (compliant): The subject car's kin.speed is 33 m/s (about 74 mph). -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k 33 ]
      [ ]
      [ ]

/-- `idle` (not_applicable): The subject is a pedestrian (not a vehicle) walking at 1.4 m/s. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (cm (140 * k), m 0) Build.east
          (Units.micrometresPerSecond 1400000) pedExtent ]
      [ ]
      [ ]

/-- `blind` (unknown): The subject car is moving; the source does not supply kin.speed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (car k 38) fun kin => { kin with speed := none } ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1e"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.NRS_484B_600_1e
