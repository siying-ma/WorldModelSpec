/-
  Witnesses for NRS_484B_263_o2.

  The controlled-access carriageway is region 10, the rectangle x ∈ [-500, 500], y ∈ [0, 10]
  (east–west). x (track 1, a motor vehicle, half-extents 2 × 1 m) comes up an on-ramp heading north
  at 15 m/s: at y = -25, -10, 5 at t = 0, 1, 2 s, so it enters region 10 at t = 2 s. y (track 2, a
  motor vehicle, half-extents 2 × 1 m) travels east at 30 m/s along y = 5 in region 10. In `forbid`
  y is at x = -23 at t = 2 s: the bodies are 20 m apart (needed: 30 m/s × 2 s = 60 m) and the centres'
  closest approach is 0.61 s ahead (horizon 4.1 s). In `branch_1` y is at x = -93: 90 m apart, closest
  approach 2.48 s ahead. `blind` is `forbid` under the manifest that masks rel.surface_gap.
  `branch_2` has x leave region 10 southward at 6 m/s (y = 8, 2, -4) with y at
  x = -23, y = 4 at t = 2 s: about 20.6 m apart, closest approach 0.69 s ahead. `idle` has x drive east
  on an arterial roadway (region 20), no controlled-access region in the scene. Every scenario is
  judged at t = 1 s and t = 2 s: entry and exit read the observation before.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def halfCar : Q × Q × Q := (m 2, m 1, m 1)

/-- The controlled-access carriageway. -/
def highway : Structure := Build.rect 10 .controlledAccess (m (-500)) (m 0) (m 500) (m 10)

/-- x on the on-ramp, entering the carriageway at k = 2. -/
def xEntering (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m (-25 + 15 * (k : Int))) Build.north (Units.metresPerSecond 15) halfCar

/-- y on the carriageway, eastbound at 30 m/s, at `x0` at k = 2. -/
def yEastbound (x0 lat : Int) (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (x0 - 60 + 30 * (k : Int)), m lat) Build.east (Units.metresPerSecond 30) halfCar

/-- `forbid` (violated): x enters controlled-access region a at 15 m/s while vehicle y in a, moving at 30 m/s and approaching x, is at rel.surface_gap 20 m. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k, yEastbound (-23) 5 k ]
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
      [ Build.user 1 [.motorVehicle] (m (15 * (k : Int)), m 5) Build.east (Units.metresPerSecond 15) halfCar ]
      [ Build.rect 20 .roadway (m (-500)) (m 0) (m 500) (m 10) ]
      [ ]

/-- `blind` (unknown): As forbid, but rel.surface_gap is not observed. Not reachable: masking
    rel.surface_gap drops only a measured gap, and Core computes it from the footprints, which the
    admission requires of every occupancy-observed track (and the rule reads x's and y's occupancy).
    See task_result.md. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): x enters a while y, approaching at 30 m/s, is at rel.surface_gap 90 m. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k, yEastbound (-93) 5 k ]
      [ highway ]
      [ ]

/-- `branch_2` (violated): x leaves a southward at 6 m/s while y in a, approaching at 30 m/s, is
    about 20.6 m away (the exit limb). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m (8 - 6 * (k : Int))) Build.south (Units.metresPerSecond 6) halfCar
      , yEastbound (-23) 4 k ]
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
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_263_o2
