/-
  Witnesses for LVMC_11_40_180_C_o1.

  Geometry (the witness's own figures): a sidewalk region 100 (x 0..100 m, y 0..4 m) beside a
  roadway region 101 (x 0..100 m, y -10..0 m); +x east. Three instants at 1 s spacing.
  Track 1 is the subject (a bicycle, electric bicycle or electric scooter, half-extent
  0.9 × 0.3 × 1.0 m); track 2 is a pedestrian (half-extent 0.3 × 0.3 × 0.9 m).
  - forbid: bicycle at y 1.5 m riding east at 5 m/s from x 10 m; pedestrian at y 2.5 m walking
    west at 1 m/s from x 24 m. Closing at 6 m/s with 1 m lateral offset: closest approach at
    2.33 s, 1.33 s, 0.33 s (inside the 3 s horizon), centre distance 1 m (below 3 m).
  - permit: same bicycle; the pedestrian starts behind it at x 4 m and walks west: the centres
    never approach (closest approach outside the horizon), no contact.
  - idle: the bicycle rides east on the roadway at y -3 m; pedestrians on the sidewalk.
  - blind: the forbid scene with rel.occupies unobserved.
  - branch_1: an electric scooter rides east on an empty sidewalk; no other road user.
  - branch_2: bicycle at 2 m/s east, pedestrian 0.5 m ahead overlapping its body walking east at
    3 m/s: contact at the first instant, while the centres separate (no approach).
  - branch_3: the bicycle stands at rest on the sidewalk while a pedestrian approaches it.
  - branch_4: the forbid scene with an electric bicycle as the subject.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_180_C_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_180_C_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def bikeExt : Q × Q × Q := (cm 90, cm 30, cm 100)
def pedExt : Q × Q × Q := (cm 30, cm 30, cm 90)

def sidewalk : Structure := Build.rect 100 .sidewalk (m 0) (m 0) (m 100) (m 4)
def roadway : Structure := Build.rect 101 .roadway (m 0) (m (-10)) (m 100) (m 0)
def structs : List Structure := [sidewalk, roadway]

/-- The subject of class `cls` riding east at 5 m/s on the sidewalk at y 1.5 m. -/
def rider (cls : RoadUserClass) (k : Nat) : RoadUser :=
  Build.user 1 [cls] (m (10 + 5 * (k : Int)), cm 150) Build.east (Units.metresPerSecond 5) bikeExt

/-- A pedestrian walking west at 1 m/s at y 2.5 m, from x `x0`. -/
def walkerWest (x0 : Int) (k : Nat) : RoadUser :=
  Build.user 2 [.pedestrian] (m (x0 - (k : Int)), cm 250) Build.west (Units.metresPerSecond 1) pedExt

/-- `forbid` (violated): A bicycle rides along the sidewalk toward a pedestrian walking toward it; their closest approach falls within the conflict horizon and below the clearance, and the bicycle keeps riding. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider .bicycle k, walkerWest 24 k ]
      structs
      [ ]

/-- `permit` (compliant): A bicycle rides along the sidewalk; a pedestrian on it walks away on a diverging course whose closest approach stays above the clearance. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider .bicycle k, walkerWest 4 k ]
      structs
      [ ]

/-- `idle` (not_applicable): A bicycle rides on the roadway beside the sidewalk where pedestrians walk. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (10 + 5 * (k : Int)), m (-3)) Build.east (Units.metresPerSecond 5) bikeExt
      , walkerWest 24 k ]
      structs
      [ ]

/-- `blind` (unknown): A bicycle moves near a pedestrian, and the source does not observe which regions the bicycle occupies. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): An electric scooter rides on an empty sidewalk with no pedestrian in the scene: the duty binds the subject alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider .electricScooter k ]
      structs
      [ ]

/-- `branch_2` (violated): the bicycle touches a pedestrian whose centre moves away from it — the
    contact leaf alone decides. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (10 + 2 * (k : Int)), cm 150) Build.east (Units.metresPerSecond 2) bikeExt
      , Build.user 2 [.pedestrian] (cm (1050 + 300 * (k : Int)), cm 150) Build.east (Units.metresPerSecond 3) pedExt ]
      structs
      [ ]

/-- `branch_3` (not_applicable): the bicycle stands at rest on the sidewalk (not ridden) while a
    pedestrian approaches it. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m 10, cm 150) Build.east Q.zero bikeExt
      , walkerWest 13 k ]
      structs
      [ ]

/-- `branch_4` (violated): an electric bicycle rides toward an oncoming pedestrian on the sidewalk. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider .electricBicycle k, walkerWest 24 k ]
      structs
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_40_180_C_o1"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.LVMC_11_40_180_C_o1
