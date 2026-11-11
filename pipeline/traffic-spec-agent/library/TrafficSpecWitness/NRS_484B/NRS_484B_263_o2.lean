/-
  Witnesses for NRS_484B_263_o2.

  The highway: a controlled-access region a (id 10), x ∈ [-200, 400], y ∈ [0, 10], running east;
  south of it (y < 0) lies the ramp, which is no structure of the scene. Bodies are 4 m × 2 m
  (half-extents 2, 1, 1). Three scenes at 0, 1000, 2000 ms; the witnesses speak of 1000–2000 ms
  (`window`), since an entry or exit needs the observation before it.

  - Entry (forbid, permit, blind, branch_1): x heads north at 15 m/s from the ramp, at (0, -28),
    (0, -13), (0, 2): outside a at 0 and 1000 ms, inside at 2000 ms — the entry. Its footprint
    then spans x ∈ [-1, 1], y ∈ [0, 4].
  - Vehicle y (track 2) heads east at 30 m/s along a at y = 5 (footprint y ∈ [4, 6]); at 2000 ms
    its centre is at x = -23 (forbid, blind: gap to x's body 20 m) or x = -93 (branch_1: 90 m).
    Needed margin: 30 m/s × p.merge_time_headway. Both approach x within p.immediate_hazard_gap
    (closest approach at ≈ 0.65 s and ≈ 2.52 s).
  - Exit (branch_2): x heads south at 5 m/s at (0, 8), (0, 3), (0, -2): inside a at 0 and 1000 ms,
    outside at 2000 ms — the exit. y at (-13, 5) at 2000 ms, ≈ 10.8 m from x's body, closest
    approach at ≈ 0.38 s.
  - Idle: x heads east at 15 m/s on an arterial roadway (id 11); no controlled-access region.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def body : Q × Q × Q := (m 2, m 1, m 1)

/-- The controlled-access highway a. -/
def highway : Structure := Build.rect 10 .controlledAccess (m (-200)) (m 0) (m 400) (m 10)

/-- x entering a from the ramp: northbound at 15 m/s. -/
def xEntering (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m (-28 + 15 * (k : Int))) Build.north (Units.metresPerSecond 15) body

/-- y on a, eastbound at 30 m/s, its centre at `x2` at the third scene. -/
def yOnHighway (x2 : Int) (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (x2 - 30 * (2 - (k : Int))), m 5) Build.east (Units.metresPerSecond 30) body

/-- `forbid` (violated): x enters controlled-access region a at 15 m/s while vehicle y in a, moving at 30 m/s and approaching x, is at rel.surface_gap 20 m (needed 60 m). -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k, yOnHighway (-23) k ]
      [ highway ]
      [ ]

/-- `permit` (compliant): x enters a as the only road user in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k ]
      [ highway ]
      [ ]

/-- `idle` (not_applicable): x drives on an arterial; no st.controlled_access region is entered or left. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (-20 + 15 * (k : Int)), m 5) Build.east (Units.metresPerSecond 15) body ]
      [ Build.rect 11 .roadway (m (-200)) (m 0) (m 400) (m 10) ]
      [ ]

/-- `blind` (unknown): As forbid, but kin.speed is not observed: whether y is moving and the speed-proportional margin it is owed are both unknown, while the gap stays 20 m. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): x enters a while y, approaching at 30 m/s, is at rel.surface_gap 90 m. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k, yOnHighway (-93) k ]
      [ highway ]
      [ ]

/-- `branch_2` (violated): x exits a southbound while y, approaching at 30 m/s, is ≈ 10.8 m from it. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m (8 - 5 * (k : Int))) Build.south (Units.metresPerSecond 5) body
      , yOnHighway (-13) k ]
      [ highway ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_263_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (1000, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_263_o2
