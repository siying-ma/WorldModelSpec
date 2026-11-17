/-
  Witnesses for NRS_484B_263_o2.

  Geometry (the witness's own figures, none of them in the rule):
  - region 10: the controlled-access highway, a rectangle x ∈ [-1000, 1000] m, y ∈ [0, 10] m;
  - region 20: the approach roadway beside it, x ∈ [-1000, 1000] m, y ∈ [-10, 0) m (a plain
    roadway, not controlled-access).
  - the subject (track 1), a passenger car (half extents 2.5 × 1 × 0.75 m), heads east at 20 m/s,
    x = 20·k m; it runs on the approach (y = -5 m) at k = 0, 1 and on the highway (y = 3 m) from
    k = 2: its entry into region 10 is observed at t = 2 s (the observation before it, t = 1 s, it
    is off the highway, so the rise is definite).
  - samples every 1 s. Before the entry no event is recorded, so the time since the latest entry or
    exit is unknown there; each witness names the instants it speaks about (`window`).
  - forbid: v (track 2, a passenger car) on the highway at y = 3 m, east at 30 m/s,
    x = 30·k − 50 m: 20 m behind the subject at t = 3 s and 10 m at t = 4 s, closing at 10 m/s,
    so the centres meet within 2 s (well within the 3 s horizon, at a distance 0 m < 3 m); no
    contact yet (centre gap ≥ 10 m > 5 m of half-lengths). Judged at t = 3, 4 s (1–2 s after
    the entry, inside the 10 s merge window).
  - permit: v on the highway 400 m and more behind, east at 15 m/s (slower: the centres separate).
  - idle: as forbid's closing v, but the instants judged are t = 13, 14 s, 11–12 s after the entry
    (more than the 10 s merge window): v (x = 30·k − 150 m) is 20 m, then 10 m behind.
  - blind: forbid's trace with kin.speed masked.
  - branch_1: the subject alone, entering at t = 2 s, judged at t = 3, 4 s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 250, cm 100, cm 75)

/-- The controlled-access highway and the approach roadway beside it. -/
def structures : List Structure :=
  [ Build.rect 10 .controlledAccess (m (-1000)) (m 0) (m 1000) (m 10)
  , Build.rect 20 .roadway (m (-1000)) (m (-10)) (m 1000) (cm (-1)) ]

/-- The subject at sample k: on the approach for k < 2, on the highway from k = 2. -/
def subjectAt (k : Nat) : RoadUser :=
  let y : Int := if k < 2 then -5 else 3
  Build.user 1 [.motorVehicle] (m (20 * (k : Int)), m y) Build.east (Units.metresPerSecond 20) carExtent

/-- A vehicle on the highway lane at y = 3 m, heading east. -/
def otherAt (x : Int) (speed : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (m x, m 3) Build.east (Units.metresPerSecond speed) carExtent

/-- `forbid` (violated): The subject entered controlled-access region c a short time ago (within p.merge_window, after the entry observation) and keeps moving; vehicle v (traffic and vehicle aggregates) moves on c with the subject ahead of it and their closest approach falls within p.conflict_horizon below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, otherAt (30 * (k : Int) - 50) 30 ]
      structures
      [ ]

/-- `permit` (compliant): As forbid, but every vehicle on c is far behind: no closest approach within p.conflict_horizon, no contact. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, otherAt (15 * (k : Int) - 400) 15 ]
      structures
      [ ]

/-- `idle` (not_applicable): The subject entered c long before, more than p.merge_window ago, and travels within it; v closes from behind. -/
def idleTrace : Trace :=
  Build.trace 15 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, otherAt (30 * (k : Int) - 150) 30 ]
      structures
      [ ]

/-- `blind` (unknown): As forbid (velocities, positions and headings observed, so the closest approach is a conflict), but kin.speed is not observed: whether the subject is still moving and whether v is a moving vehicle approaching it are unknown while the conflict holds. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): Within p.merge_window after its entry into c, the subject moves and no other road user is in the scene: the duty binds the subject alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k ]
      structures
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_263_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (3000, 4000))
  , witness "permit" permitTrace .compliant (window := some (3000, 4000))
  , witness "idle" idleTrace .notApplicable (window := some (13000, 14000))
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] (window := some (3000, 4000))
  , witness "branch_1" branch_1Trace .compliant (window := some (3000, 4000)) ]

end TrafficSpecWitness.NRS_484B_263_o2
