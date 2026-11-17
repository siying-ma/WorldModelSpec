/-
  Witnesses for NRS_484B_785_1a.

  Geometry (the witness's own figures, none of them in the rule): a straight east-west strip
  100 m long. Depending on the scene, the strip is a roadway (y 0..7 m), a bicycle lane
  (y 0..2 m) with a roadway beside it (y 2..9 m), or a sidewalk (y 0..3 m) with a roadway
  beside it (y 3..10 m). Track 1 is an electric scooter (half-extent 60 × 30 × 60 cm) heading
  east along the strip's middle, its reference point well inside one region. Three instants
  1 s apart. 8 m/s is about 17.9 mph (above 15 mph = 6.7056 m/s); 5 m/s is about 11.2 mph.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_785_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_785_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def scooterExtent : Q × Q × Q := (cm 60, cm 30, cm 60)

/-- The scooter at instant `k`, at lateral position `y`, moving east at `v` m/s. -/
def scooter (k : Nat) (y : Q) (v : Int) : RoadUser :=
  Build.user 1 [.electricScooter] (Q.add (m 20) (Q.ofInt (v * k)), y) Build.east
    (Units.metresPerSecond v) scooterExtent

/-- `forbid` (violated): An electric scooter rides on a roadway at 8 m/s, above 15 mph. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ scooter k (cm 350) 8 ]
      [ Build.rect 10 .roadway (m 0) (m 0) (m 100) (m 7) ]
      [ ]

/-- `permit` (compliant): An electric scooter rides in a bicycle lane at 5 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ scooter k (m 1) 5 ]
      [ Build.rect 20 .bicycleLaneOrPath (m 0) (m 0) (m 100) (m 2)
      , Build.rect 10 .roadway (m 0) (m 2) (m 100) (m 9) ]
      [ ]

/-- `idle` (not_applicable): An electric scooter rides on a sidewalk at 8 m/s, overlapping no roadway, bicycle lane or path. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ scooter k (cm 150) 8 ]
      [ Build.rect 30 .sidewalk (m 0) (m 0) (m 100) (m 3)
      , Build.rect 10 .roadway (m 0) (m 3) (m 100) (m 10) ]
      [ ]

/-- `blind` (unknown): An electric scooter rides on a roadway; the source does not observe speed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (scooter k (cm 350) 8) (fun kn => { kn with speed := none }) ]
      [ Build.rect 10 .roadway (m 0) (m 0) (m 100) (m 7) ]
      [ ]

/-- `branch_1` (violated): the scooter rides in a bicycle lane at 8 m/s, above 15 mph. -/
def branch1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ scooter k (m 1) 8 ]
      [ Build.rect 20 .bicycleLaneOrPath (m 0) (m 0) (m 100) (m 2)
      , Build.rect 10 .roadway (m 0) (m 2) (m 100) (m 9) ]
      [ ]

/-- `branch_2` (compliant): the scooter rides on a roadway at 5 m/s, below 15 mph. -/
def branch2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ scooter k (cm 350) 5 ]
      [ Build.rect 10 .roadway (m 0) (m 0) (m 100) (m 7) ]
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_785_1a
