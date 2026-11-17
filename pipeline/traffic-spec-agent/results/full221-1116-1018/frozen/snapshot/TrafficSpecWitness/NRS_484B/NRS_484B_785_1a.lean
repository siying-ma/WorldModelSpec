/-
  Witnesses for NRS_484B_785_1a.

  Geometry (the witness's own figures, none of them in the rule): an east-west strip with a
  roadway `1` (y ∈ [-5, 5]), a bicycle lane `2` (y ∈ [5, 7]) north of it and a sidewalk `3`
  (y ∈ [7, 10]) north of that, all from x = 0 to x = 200. The scooter (track 1, half-extent
  0.6 m × 0.3 m × 0.6 m) heads east; its reference point lies well inside one strip, so the
  occupancy derived from the polygons puts it in that strip alone. Three instants 1 s apart.
  15 mph = 6.7056 m/s: the forbid and idle scooters ride at 8 m/s, the permit one at 5 m/s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_785_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_785_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def scooterExtent : Q × Q × Q := (cm 60, cm 30, cm 60)

def structures : List Structure :=
  [ Build.rect 1 .roadway (m 0) (m (-5)) (m 200) (m 5)
  , Build.rect 2 .bicycleLaneOrPath (m 0) (m 5) (m 200) (m 7)
  , Build.rect 3 .sidewalk (m 0) (m 7) (m 200) (m 10) ]

/-- The scooter at instant `k`, at lateral position `y`, riding east at `v`. -/
def scooter (k : Nat) (y : Q) (v : Q) (x0 : Int) (dx : Int) : RoadUser :=
  Build.user 1 [.electricScooter] (m (x0 + dx * k), y) Build.east v scooterExtent

/-- `forbid` (violated): An electric scooter rides on a roadway at 8 m/s, above 15 mph. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ scooter k (m 0) (Units.metresPerSecond 8) 20 8 ]
      structures
      [ ]

/-- `permit` (compliant): An electric scooter rides in a bicycle lane at 5 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ scooter k (m 6) (Units.metresPerSecond 5) 20 5 ]
      structures
      [ ]

/-- `idle` (not_applicable): An electric scooter rides on a sidewalk at 8 m/s and overlaps no roadway, bicycle lane or path. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ scooter k (cm 850) (Units.metresPerSecond 8) 20 8 ]
      structures
      [ ]

/-- `blind` (unknown): An electric scooter rides on a roadway, and the source does not observe its speed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ scooter k (m 0) (Units.metresPerSecond 8) 20 8 ]
      structures
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_785_1a"
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

end TrafficSpecWitness.NRS_484B_785_1a
