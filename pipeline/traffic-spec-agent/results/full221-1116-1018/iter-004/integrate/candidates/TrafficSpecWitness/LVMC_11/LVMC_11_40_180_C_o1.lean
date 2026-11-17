/-
  Witnesses for LVMC_11_40_180_C_o1.

  Geometry (the witness's own figures, nowhere in the rule): a sidewalk (region 10) is the strip
  x ∈ [0, 100] m, y ∈ [0, 3] m; the roadway (region 20) lies beside it, y ∈ [-10, 0] m. Three
  instants, one second apart (t = 0, 1000, 2000 ms).

  The subject (track 1) rides east at 4 m/s along y = 1.5 m (on the sidewalk) from x = 10 m;
  body half-extent 0.9 × 0.3 m. A pedestrian (track 2) walks at 1 m/s, half-extent 0.3 × 0.3 m.
  - forbid / branch_2 / blind: the pedestrian walks west along y = 2 m from x = 22 m; the centres
    close at 5 m/s from 12, 7, 2 m apart, so the closest approach comes at 2.4, 1.4, 0.4 s
    (inside the 3 s horizon) at a centre distance of 0.5 m (well below the 3 m clearance); the
    bodies never touch (longitudinal gap ≥ 0.8 m).
  - permit: the pedestrian walks west along y = 2 m from x = 5 m, behind the bicycle; the two
    diverge, so no approach lies ahead within the horizon; centres stay ≥ 5 m apart.
  - idle: the bicycle rides on the roadway (y = -2 m), the pedestrian walks on the sidewalk.
  - branch_1: the bicycle alone on the sidewalk.
  - branch_3: the subject is a pedestrian walking on the sidewalk toward another pedestrian: no
    bicycle, electric bicycle or electric scooter, so not applicable.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_180_C_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_180_C_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 60)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

def sidewalk : Structure := Build.rect 10 .sidewalk (m 0) (m 0) (m 100) (m 3)
def roadway : Structure := Build.rect 20 .roadway (m 0) (m (-10)) (m 100) (m 0)
def structures : List Structure := [sidewalk, roadway]

/-- The subject riding east along the sidewalk (or along `y` cm) at 4 m/s. -/
def rider (cls : List RoadUserClass) (k : Nat) (y : Int := 150) : RoadUser :=
  Build.user 1 cls (cm (1000 + 400 * (k : Int)), cm y) Build.east (Units.metresPerSecond 4) bikeExtent

/-- A pedestrian walking west along y = 2 m at 1 m/s from `x0` m. -/
def walker (x0 : Int) (k : Nat) : RoadUser :=
  Build.user 2 [.pedestrian] (cm (100 * x0 - 100 * (k : Int)), cm 200) Build.west
    (Units.metresPerSecond 1) pedExtent

/-- `forbid` (violated): A bicycle (ru.bicycle) rides along the sidewalk toward a pedestrian walking toward it; their closest approach falls within the conflict horizon and below the clearance, and the bicycle keeps riding. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [rider [.bicycle] k, walker 22 k] structures []

/-- `permit` (compliant): A bicycle (ru.bicycle) rides along the sidewalk; a pedestrian on it walks away on a diverging course whose closest approach stays above the clearance. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [rider [.bicycle] k, walker 5 k] structures []

/-- `idle` (not_applicable): A bicycle (ru.bicycle) rides on the roadway beside the sidewalk where pedestrians walk. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [rider [.bicycle] k (-200), walker 22 k] structures []

/-- `blind` (unknown): A bicycle moves near a pedestrian, and the source does not observe which regions the bicycle occupies. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [rider [.bicycle] k, walker 22 k] structures []

/-- `branch_1` (compliant): A bicycle (ru.bicycle) rides along an empty sidewalk with no pedestrian in the scene: the duty binds the subject alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [rider [.bicycle] k] structures []

/-- `branch_2` (violated): An electric bicycle (ru.electric_bicycle) rides along the sidewalk toward a pedestrian walking toward it; their closest approach falls within the conflict horizon and below the clearance. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [rider [.electricBicycle] k, walker 22 k] structures []

/-- `branch_3` (not_applicable): a pedestrian (no bicycle, electric bicycle or electric scooter)
    walks along the sidewalk toward another pedestrian: the words exclude a person afoot. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (cm (1000 + 100 * (k : Int)), cm 150) Build.east
          (Units.metresPerSecond 1) pedExtent
      , walker 16 k ] structures []

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
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_40_180_C_o1
