/-
  Witnesses for NRS_484B_263_o1.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
  - Region 10, kind controlled_access: the rectangle x ∈ [0, 300] m, y ∈ [0, 10] m (+x east).
  - Subject (track 1): a motor vehicle heading east at 10 m/s, half-extent 2 m × 1 m.
  - Other vehicle v (track 2): a motor vehicle heading east at 20 m/s on the region, y = 5 m.
  - Three observations at 0, 1 and 2 s; each witness speaks of the instants 1 s and 2 s (`window`),
    since an entry or exit is judged against the previous observation.
  Entry: the subject is at y = −3 m (off the region) at 0 s and at y = 4 m (on it) from 1 s.
  Conflict: at 1 s v is 20 m behind the subject, closing at 10 m/s with 1 m lateral offset: the
  closest approach is at 2 s (horizon 3 s) at 1 m (clearance 3 m). Permit: 100 m behind, the
  closest approach is at 10 s, beyond the horizon. Exit (branch_2): the subject leaves the region's
  east end (x = 295 → 305 m) with v 20 m behind in the same line, closest approach 0 m at 2 s.
  Blind: as forbid, but the source does not observe v's heading, so Core cannot compute the bearing
  or the contact; the source supplies them measured (subject 20 m ahead of v at 1 s, no contact).
  Masking rel.bearing drops the measured bearing, and whether v approaches is then unknown.
  Without v's heading its footprint is undefined, so the source observes the subject's occupancy only
  (on region 10 from 1 s); v's occupancy is not observed.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (m 2, m 1, cm 75)

def region : Structure := Build.rect 10 .controlledAccess (m 0) (m 0) (m 300) (m 10)

def subjectAt (x y : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) Build.east (Units.metresPerSecond 10) body

def otherAt (x : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (m x, m 5) Build.east (Units.metresPerSecond 20) body

/-- The subject's lateral place: off the region at 0 s, on it from 1 s (entry at 1 s). -/
def entryY (k : Nat) : Int := if k = 0 then -3 else 4

/-- `forbid` (violated): The subject's footprint comes to overlap controlled-access region c (it did not at the previous observation), kin.speed above p.halt_speed_tolerance. Vehicle v moves on c with the subject ahead of it; prim.closest_approach_within holds over p.conflict_horizon and prim.closest_approach_distance is below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (100 + 10 * k) (entryY k), otherAt (70 + 20 * k) ]
      [ region ]
      [ ]

/-- `permit` (compliant): As forbid, but v is far behind on c: the closest approach does not fall within p.conflict_horizon, and no contact occurs. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (150 + 10 * k) (entryY k), otherAt (30 + 20 * k) ]
      [ region ]
      [ ]

/-- `idle` (not_applicable): The subject travels within c throughout: its overlap with c neither begins nor ends during the trace. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (100 + 10 * k) 4, otherAt (70 + 20 * k) ]
      [ region ]
      [ ]

/-- `blind` (unknown): As forbid, but rel.bearing is not observed, so whether v approaches the subject is unknown while the closest approach is a conflict. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let v := Build.withKin (otherAt (70 + 20 * k)) fun kn => { kn with heading := none }
    let s := Build.scene t (some 1)
        [ subjectAt (100 + 10 * k) (entryY k), v ]
        [ region ]
        [ ]
        (some (if k = 0 then [] else [(1, 10)]))
    Build.withRelations { s with occupancyObserved := [1] }
      [ Build.relation 2 1 fun r => { r with bearing := some (m (30 - 10 * k), m (entryY k - 5)) }
      , Build.relation 1 2 fun r => { r with contact := some false } ]

/-- `branch_1` (compliant): The subject enters c and no other road user is in the scene: the duty binds the subject alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (100 + 10 * k) (entryY k) ]
      [ region ]
      [ ]

/-- `branch_2` (violated): The subject's footprint ceases to overlap c (exit) while a vehicle v moving on c, with the subject ahead of it, is in a closest-approach conflict with the subject. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (295 + 10 * k) 5, otherAt (265 + 20 * k) ]
      [ region ]
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
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_263_o1
