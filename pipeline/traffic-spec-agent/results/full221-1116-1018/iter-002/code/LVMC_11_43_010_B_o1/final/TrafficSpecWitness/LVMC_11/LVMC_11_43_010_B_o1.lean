/-
  Witnesses for LVMC_11_43_010_B_o1.

  Geometry (the witness's own figures, none in the rule): one roundabout region 10, the
  rectangle x ∈ [0, 40], y ∈ [−20, 20] (m). Three instants, 1 s apart (t = 0, 1000, 2000 ms).
  The subject (track 1), a car 4.5 m × 1.8 m, approaches from the west along y = 0 heading east
  at 5 m/s: x = −6, −1, 4, so it enters the roundabout at t = 2000 (occupied there, not at
  t = 1000). Other road users are track 2. Occupancy is derived from the reference point.

  Against the reading (horizon 3 s, clearance 3 m) at the entry (subject at (4, 0), velocity (5, 0)):
  - forbid: car 2 circulates south along x = 10, (10, 16), (10, 11), (10, 6) at 5 m/s: closest
    approach at 1.2 s, centre distance 0 m (≪ 3 m), bodies ~8.5 m apart (no contact).
  - permit: car 2 on the far side along x = 36, northbound, (36, −18), (36, −13), (36, −8): the
    closest approach would be 4 s ahead (> 3 s), so none within the horizon.
  - idle: the subject circulates inside throughout (x = 6, 11, 16); judged at t = 1000, 2000.
  - blind: subject at the edge, car 2 alongside 5 m to its north at the same velocity; rel.occupies
    masked, so the entry is undecided.
  - branch_1: the subject enters with no other road user in the scene.
  - branch_2: car 2 runs alongside the subject, 2 m ahead and 1.5 m to its left (bodies overlap:
    contact), at the same velocity (no closest approach); inside at t = 1000 and 2000 → violated
    through rel.contact alone.
  - branch_3: a pedestrian (not a DEF-NRS-484A-320 vehicle) in the roundabout throughout at x = 8,
    southbound 2 m/s, (8, 6), (8, 4), (8, 2): closest approach 0.37 m at 0.83 s → compliant.
  - branch_4: car 2 enters at the same instant from the north along x = 8 southbound at 10 m/s,
    (8, 32), (8, 22), (8, 12): closest approach 1.79 m at 1.12 s, but it was not in the roundabout
    at the observation before → not "already in" → compliant.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_B_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_B_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

/-- The roundabout region. -/
def roundabout : Structure := Build.rect 10 .roundabout (m 0) (m (-20)) (m 40) (m 20)

/-- The subject entering from the west: x = −6, −1, 4 on y = 0, east at 5 m/s. -/
def subjectEntering (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (-6 + 5 * (k : Int)), m 0) Build.east (Units.metresPerSecond 5) carExtent

/-- `forbid` (violated): A car enters the roundabout while a circulating car, already in it, is on a course whose closest approach to the entering car falls within the conflict horizon and below the clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k
      , Build.user 2 [.motorVehicle] (m 10, m (16 - 5 * (k : Int))) Build.south (Units.metresPerSecond 5) carExtent ]
      [ roundabout ]
      [ ]

/-- `permit` (compliant): A car enters the roundabout while the only circulating car is on the far side, its closest approach above the clearance. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k
      , Build.user 2 [.motorVehicle] (m 36, m (-18 + 5 * (k : Int))) Build.north (Units.metresPerSecond 5) carExtent ]
      [ roundabout ]
      [ ]

/-- `idle` (not_applicable): A car circulates inside the roundabout throughout the recording without entering it. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (6 + 5 * (k : Int)), m 0) Build.east (Units.metresPerSecond 5) carExtent ]
      [ roundabout ]
      [ ]

/-- `blind` (unknown): A car near the roundabout's edge beside a circulating car, where the source does not observe which regions the cars occupy. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k
      , Build.user 2 [.motorVehicle] (m (-6 + 5 * (k : Int)), m 5) Build.east (Units.metresPerSecond 5) carExtent ]
      [ roundabout ]
      [ ]

/-- `branch_1` (compliant): A car enters an empty roundabout: no other vehicle is in the scene, and the duty is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k ]
      [ roundabout ]
      [ ]

/-- `branch_2` (violated): the subject enters touching a car already in the roundabout that moves
    with it (no closest approach ahead): the contact leaf alone decides. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k
      , Build.user 2 [.motorVehicle] (m (-4 + 5 * (k : Int)), cm 150) Build.east (Units.metresPerSecond 5) carExtent ]
      [ roundabout ]
      [ ]

/-- `branch_3` (compliant): the only road user in conflict in the roundabout is a pedestrian, not a vehicle. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k
      , Build.user 2 [.pedestrian] (m 8, m (6 - 2 * (k : Int))) Build.south (Units.metresPerSecond 2) pedExtent ]
      [ roundabout ]
      [ ]

/-- `branch_4` (compliant): a car in conflict enters the roundabout at the same instant: it is not already in it. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k
      , Build.user 2 [.motorVehicle] (m 8, m (32 - 10 * (k : Int))) Build.south (Units.metresPerSecond 10) carExtent ]
      [ roundabout ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "LVMC_11_43_010_B_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable (window := some (1000, 2000))
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.LVMC_11_43_010_B_o1
