/-
  Witnesses for LVMC_11_40_180_C_o1.

  Geometry (the witness's own figures, none in the rule): a sidewalk `10`, the rectangle
  x ∈ [-50, 50], y ∈ [0, 4]; beside it a roadway `20`, x ∈ [-50, 50], y ∈ [-8, 0]. Three scenes
  one second apart (t = 0, 1000, 2000 ms). The subject (track 1) rides east at 5 m/s with half-extents
  0.9 × 0.3 × 0.8 m; a pedestrian (track 2) walks at 1 m/s with half-extents 0.3 × 0.3 × 0.9 m.

  Against the reading (horizon 3 s, centre clearance 3 m, halt tolerance 0.1 m/s):
  - forbid / blind / branch_2 / branch_3: head-on on the line y = 2; the centre gap is 15, 9, 3 m,
    closing at 6 m/s, so the closest approach comes in 2.5, 1.5, 0.5 s at a centre distance of 0 m.
  - permit: the pedestrian is behind the subject and walks west: the centres separate (closest
    approach in the past), so no approach within the horizon.
  - idle: the subject rides on the roadway at y = -3, never in the sidewalk.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_180_C_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_180_C_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def riderExtent : Q × Q × Q := (cm 90, cm 30, cm 80)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

def sidewalk : Structure := Build.rect 10 .sidewalk (m (-50)) (m 0) (m 50) (m 4)
def roadway : Structure := Build.rect 20 .roadway (m (-50)) (m (-8)) (m 50) (m 0)

/-- The subject riding east along y = 2 at 5 m/s, from x = -9. -/
def rider (cls : List RoadUserClass) (k : Nat) (ext : Q × Q × Q := riderExtent) : RoadUser :=
  Build.user 1 cls (m (-9 + 5 * (k : Int)), m 2) Build.east (Units.metresPerSecond 5) ext

/-- A pedestrian walking west along y = 2 at 1 m/s, from x = 6: head-on with the rider. -/
def oncomingPed (k : Nat) : RoadUser :=
  Build.user 2 [.pedestrian] (m (6 - (k : Int)), m 2) Build.west (Units.metresPerSecond 1) pedExtent

/-- `forbid` (violated): A bicycle rides along the sidewalk toward a pedestrian walking toward it; their closest approach falls within the conflict horizon and below the clearance, and the bicycle keeps riding. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider [.bicycle] k, oncomingPed k ]
      [ sidewalk, roadway ]
      [ ]

/-- `permit` (compliant): A bicycle rides along the sidewalk; a pedestrian on it walks away on a diverging course whose closest approach stays above the clearance. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (5 * (k : Int)), m 1) Build.east (Units.metresPerSecond 5) riderExtent
      , Build.user 2 [.pedestrian] (m (-4 - (k : Int)), m 3) Build.west (Units.metresPerSecond 1) pedExtent ]
      [ sidewalk, roadway ]
      [ ]

/-- `idle` (not_applicable): A bicycle rides on the roadway beside the sidewalk where pedestrians walk. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (-9 + 5 * (k : Int)), m (-3)) Build.east (Units.metresPerSecond 5) riderExtent
      , oncomingPed k ]
      [ sidewalk, roadway ]
      [ ]

/-- `blind` (unknown): A bicycle moves near a pedestrian, and the source does not observe which regions the bicycle occupies. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider [.bicycle] k, oncomingPed k ]
      [ sidewalk, roadway ]
      [ ]

/-- `branch_1` (compliant): A bicycle rides along an empty sidewalk with no pedestrian in the scene: the duty binds the subject alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider [.bicycle] k ]
      [ sidewalk, roadway ]
      [ ]

/-- `branch_2` (violated): An electric bicycle rides along the sidewalk toward a pedestrian walking toward it; their closest approach falls within the conflict horizon and below the clearance. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider [.electricBicycle] k, oncomingPed k ]
      [ sidewalk, roadway ]
      [ ]

/-- `branch_3` (not_applicable): A passenger car moves along the sidewalk toward a pedestrian: it is none of the three devices the words name. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider [.motorVehicle] k carExtent, oncomingPed k ]
      [ sidewalk, roadway ]
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
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_40_180_C_o1
