/-
  Witnesses for NRS_484B_263_o1.

  Geometry: one controlled-access region `c` (id 10), the rectangle x ∈ [-500, 500] m,
  y ∈ [-2, 2] m, traffic eastbound. Every body is a car, half-extents 2 m × 1 m × 0.75 m,
  heading east. Three observations at t = 0, 1, 2 s; every witness judges t = 1 s and 2 s
  (`window`), since the entry/exit edge reads the previous observation and is unknown at t = 0.

  - Subject (track 1), 10 m/s. Entry: (20, 6) → (30, 1) → (40, 1): off `c` at t = 0, on it from
    t = 1 s. Exit: (20, 1) → (30, 4) → (40, 6).
  - Other vehicle v (track 2), 20 m/s, on `c`, behind the subject at t = 1 s.
    forbid/blind: v at (22, 0): centre offset (8, 1), closing at 10 m/s → closest approach at
    0.8 s (≤ 3 s horizon) at 1 m (< 3 m clearance); bodies 4 m apart, no contact.
    permit: v at (-200, 0): closest approach 23 s ahead, beyond the 3 s horizon.
    branch_2: v at (22, 1.5), subject at (30, 4): offset (8, 2.5) → 2.5 m at 0.8 s.
  At t = 2 s no entry or exit occurs in any witness, so that instant is not applicable.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def half : Q × Q × Q := (m 2, m 1, cm 75)

/-- The controlled-access region. -/
def ca : Structure := Build.rect 10 .controlledAccess (m (-500)) (m (-2)) (m 500) (m 2)

def subjectAt (x y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) Build.east (Units.metresPerSecond 10) half

def otherAt (x y : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (x, y) Build.east (Units.metresPerSecond 20) half

/-- Subject entering `c`: off it at t = 0, on it after. -/
def subjectEntering (k : Nat) : RoadUser :=
  match k with
  | 0 => subjectAt (m 20) (m 6)
  | _ => subjectAt (m (20 + 10 * (k : Int))) (m 1)

/-- Subject exiting `c`: on it at t = 0, off it after. -/
def subjectExiting (k : Nat) : RoadUser :=
  match k with
  | 0 => subjectAt (m 20) (m 1)
  | 1 => subjectAt (m 30) (m 4)
  | _ => subjectAt (m 40) (m 6)

/-- `forbid` (violated): The subject's footprint comes to overlap controlled-access region c (it did not at the previous observation), kin.speed above p.halt_speed_tolerance. Vehicle v moves on c with the subject ahead of it; prim.closest_approach_within holds over p.conflict_horizon and prim.closest_approach_distance is below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k, otherAt (m (2 + 20 * (k : Int))) (m 0) ]
      [ ca ]
      [ ]

/-- `permit` (compliant): As forbid, but v is far behind on c: the closest approach does not fall within p.conflict_horizon, and no contact occurs. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k, otherAt (m (-220 + 20 * (k : Int))) (m 0) ]
      [ ca ]
      [ ]

/-- `idle` (not_applicable): The subject travels within c throughout: its overlap with c neither begins nor ends during the trace. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (m (10 * (k : Int))) (m 0) ]
      [ ca ]
      [ ]

/-- `blind` (unknown): As forbid, with every position, heading, speed, footprint and occupancy observed, but the source does not observe membership of the legal aggregate (ru.aggregate absent): whether the road users belong to DEF-NRS-484A-320::vehicle, and so whether v is a vehicle the subject must yield to, is unknown while v moves on c with the subject ahead of it in a closest-approach conflict. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k, otherAt (m (2 + 20 * (k : Int))) (m 0) ]
      [ ca ]
      [ ]

/-- `branch_1` (compliant): The subject enters c and no other road user is in the scene: the duty binds the subject alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectEntering k ]
      [ ca ]
      [ ]

/-- `branch_2` (violated): The subject's footprint ceases to overlap c (exit) while a vehicle v moving on c, with the subject ahead of it, is in a closest-approach conflict with the subject. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectExiting k, otherAt (m (2 + 20 * (k : Int))) (cm 150) ]
      [ ca ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_263_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (1000, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["ru.aggregate"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_263_o1
