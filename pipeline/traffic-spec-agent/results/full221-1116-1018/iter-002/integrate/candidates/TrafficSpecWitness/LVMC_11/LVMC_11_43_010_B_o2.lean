/-
  Witnesses for LVMC_11_43_010_B_o2.

  Geometry (the witness's own figures, nowhere in the rule): a roundabout region R, the square
  (0,0)–(40,40); its west entry approach is the line y = 20, on which the subject car (track 1,
  half-extents 2 × 1 × 1 m) drives east. Instants t = 0, 1, 2 s; the subject's reference point
  crosses x = 0 between t = 1 and t = 2, so it enters R at t = 2 (rel.occupies true at 2, false
  at 1). Against the reading (critical gap 4.5 s, clearance 3.0 m):
  - forbid: a pedestrian (track 2) on a crosswalk inside R at (8, 21) at t = 2 walks south at
    1 m/s; the car is at (2, 20) at 4 m/s east: closest approach after ≈ 1.5 s at ≈ 0.5 m.
  - permit: the car waits at (-3, 20) for t = 0, 1 and enters at (1, 20), 2 m/s, at t = 2;
    car 2 circulates west at (20, 30), 3 m/s: closest approach after 3.8 s at 10 m; car 3 at
    (30, 10) drives east at 5 m/s away from it: no approach.
  - idle: a straight roadway, no roundabout.
  - blind: the forbid geometry with rel.occupies masked.
  - branch_1: the car enters R with no other road user in the scene.
  - branch_2: the car enters R while a faster car behind it on the approach (outside R) closes
    to 0 m within 2 s — only road users in the roundabout count: compliant.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_B_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_B_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

def carExtent : Q × Q × Q := (m 2, m 1, m 1)
def pedExtent : Q × Q × Q := (cm 30, cm 30, m 1)

def roundabout : Structure := Build.rect 10 .roundabout (m 0) (m 0) (m 40) (m 40)
def crosswalk : Structure := Build.rect 11 .crosswalk (m 6) (m 14) (m 10) (m 26)

-- Binders ↦ tracks: subject ↦ 1

/-- The subject driving east on y = 20 at 4 m/s: x = -6, -2, 2 at t = 0, 1, 2. -/
def entering (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (4 * (k : Int) - 6), m 20) Build.east (mps 4) carExtent

/-- `forbid` (violated): A car enters the roundabout while a pedestrian on one of its crosswalks is on a course whose closest approach to the car comes within the clearance sooner than the critical gap. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k
      , Build.user 2 [.pedestrian] (m 8, m (23 - (k : Int))) Build.south (mps 1) pedExtent ]
      [ roundabout, crosswalk ]
      [ ]

/-- `permit` (compliant): A car waits at the edge and enters once no road user in the roundabout comes within the clearance of it within the critical gap. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let subj :=
      if k < 2 then Build.user 1 [.motorVehicle] (m (-3), m 20) Build.east (mps 0) carExtent
      else Build.user 1 [.motorVehicle] (m 1, m 20) Build.east (mps 2) carExtent
    Build.scene t (some 1)
      [ subj
      , Build.user 2 [.motorVehicle] (m (26 - 3 * (k : Int)), m 30) Build.west (mps 3) carExtent
      , Build.user 3 [.motorVehicle] (m (20 + 5 * (k : Int)), m 10) Build.east (mps 5) carExtent ]
      [ roundabout ]
      [ ]

/-- `idle` (not_applicable): A car drives on a street away from any roundabout. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 2) Build.east (mps 10) carExtent ]
      [ Build.rect 20 .roadway (m (-50)) (m 0) (m 100) (m 8) ]
      [ ]

/-- `blind` (unknown): A car at the roundabout's edge beside circulating traffic, where the source does not observe which regions the road users occupy. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): A car enters an empty roundabout: no other road user is in the scene, and the duty is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k ]
      [ roundabout ]
      [ ]

/-- `branch_2` (compliant): A car enters the roundabout while a faster car behind it, still on the
    approach outside the roundabout, closes on it: only road users in the roundabout count. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ entering k
      , Build.user 2 [.motorVehicle] (m (8 * (k : Int) - 22), m 20) Build.east (mps 8) carExtent ]
      [ roundabout ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_43_010_B_o2"
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
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.LVMC_11_43_010_B_o2
