/-
  Witnesses for NRS_484B_263_o2.

  Geometry (the witness's own figures, none of them in the rule): a controlled-access carriageway
  c (region 10) is the rectangle x ∈ [0, 1000] m, y ∈ [0, 10] m, traffic running east. Every body
  is a passenger car (half-length 2.5 m, half-width 1 m) on the line y = 5 m heading east. Scenes
  are 1 s apart from t = 0. The subject (track 1) runs at 20 m/s from x = -30 m, so it is off c at
  t = 0 s and 1 s and enters c at t = 2 s (x = 10 m): the entry event. Each witness judges the
  instants named by its `window`; before the entry the time since the event is unobserved.

  - forbid: v (track 2) at 30 m/s from x = -80 m: on c from t = 3 s, 20 m behind the subject then
    and 10 m at t = 4 s, closing at 10 m/s: closest approach (distance 0) within 2 s and 1 s, below
    the 3 m clearance and inside the 3 s horizon; bodies 15 m and 5 m apart, no contact. Window
    t = 3–4 s, 1–2 s after the entry (merge window 10 s).
  - permit: v at the subject's own 20 m/s, 25 m behind (x = -55 m at t = 0): on c from t = 3 s, no
    relative motion so no closest approach within the horizon, no contact.
  - idle: as forbid, but the window is t = 13–14 s, 11–12 s after the entry (beyond 10 s); v closes
    from behind (20 m then 10 m gap at 10 m/s).
  - blind: the forbid trace with rel.bearing masked. This cannot be unknown: Core computes the
    bearing from kinematics the trace must keep (see the note at `blindTrace`).
  - branch_1: the subject alone, window t = 3–4 s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The controlled-access carriageway. -/
def carriageway : Structure := Build.rect 10 .controlledAccess (m 0) (m 0) (m 1000) (m 10)

/-- A passenger car on the line y = 5 m heading east. -/
def car (track : TrackId) (x : Int) (speed : Int) : RoadUser :=
  Build.user track [.motorVehicle] (m x, m 5) Build.east (Units.metresPerSecond speed) (cm 250, m 1, cm 75)

/-- The subject at instant k: 20 m/s from x = -30 m, entering c at k = 2. -/
def subjectAt (k : Nat) : RoadUser := car 1 (-30 + 20 * (k : Int)) 20

/-- `forbid` (violated): The subject entered controlled-access region c a short time ago (within p.merge_window, after the entry observation) and keeps moving; vehicle v (traffic and vehicle aggregates) moves on c with the subject ahead of it and their closest approach falls within p.conflict_horizon below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, car 2 (-80 + 30 * (k : Int)) 30 ]
      [ carriageway ]
      [ ]

/-- `permit` (compliant): As forbid, but every vehicle on c is far behind: no closest approach within p.conflict_horizon, no contact. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, car 2 (-55 + 20 * (k : Int)) 20 ]
      [ carriageway ]
      [ ]

/-- `idle` (not_applicable): The subject entered c long before, more than p.merge_window ago, and travels within it; v closes from behind. -/
def idleTrace : Trace :=
  Build.trace 15 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, car 2 (-180 + 30 * (k : Int)) 30 ]
      [ carriageway ]
      [ ]

/-- `blind` (unknown): As forbid, but rel.bearing is not observed, so whether v approaches the subject is unknown while the closest approach is a conflict. -/
-- NOT REACHABLE as planned (see task_result.md): masking `rel.bearing` drops only a measured
-- bearing; Core recomputes it from v's position and heading, which v's footprint (needed for its
-- observed occupancy of c) requires. A trace without v's heading is refused by admission. The
-- forbid geometry is kept here so the file builds; the gate reports it violated.
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): Within p.merge_window after its entry into c, the subject moves and no other road user is in the scene: the duty binds the subject alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k ]
      [ carriageway ]
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
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"] (window := some (3000, 4000))
  , witness "branch_1" branch_1Trace .compliant (window := some (3000, 4000)) ]

end TrafficSpecWitness.NRS_484B_263_o2
