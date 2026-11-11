/-
  Witnesses for NRS_484B_297_6_o3.

  Geometry (world frame, +x east, +y north): a highway 10 spans x ∈ [-10, 80], y ∈ [-8, 3]; the
  sidewalk 11 lies on it (ways = [10]) along its north edge, y ∈ [0, 3]; an excavation 12 (an
  obstruction) cuts the sidewalk at x ∈ [10, 14], y ∈ [0, 3]. The pedestrian 1 (half-extent
  0.3 × 0.3 × 0.9 m) walks east at 1 m/s, one observation a second, at x = 4 + k.

  On the sidewalk it walks at y = 1.5; on the roadway part of the highway at y = -1.
  - k = 4 (x = 8, on the sidewalk): 1.7 m from the excavation — the encounter.
  - k = 5 … 12 (x = 9 … 16, on the roadway): within 1 m to 1.7 m of the excavation.
  - k = 13 (x = 17): 2.7 m from it — passed; from k = 16 (x = 20) more than 5 m.
  forbid: stays on the roadway to k = 46 (30 s beyond 5 m) — no return within the return time.
  permit: back on the sidewalk at k = 15, 2 s after k = 13.
  idle: stays on the sidewalk throughout.
  blind: forbid's trace with st.region_geometry absent, so no distance to the excavation is known.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_297_6_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_297_6_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def highway : Structure := Build.rect 10 .highway (m (-10)) (m (-8)) (m 80) (m 3)

def sidewalk : Structure :=
  { Build.rect 11 .sidewalk (m (-10)) (m 0) (m 80) (m 3) with ways := some [10] }

def excavation : Structure :=
  { Build.rect 12 .obstruction (m 10) (m 0) (m 14) (m 3) with
    obstructionKind := some .excavation
    ways := some [10] }

/-- The pedestrian at observation `k`, on the sidewalk or on the roadway. -/
def pedestrian (k : Nat) (onSidewalk : Bool) : RoadUser :=
  Build.user 1 [.pedestrian]
    (m (4 + (k : Int)), if onSidewalk then cm 150 else cm (-100))
    Build.east (Units.metresPerSecond 1) (cm 30, cm 30, cm 90)

def walkScene (t : Timestamp) (k : Nat) (onSidewalk : Bool) : Scene :=
  Build.scene t (some 1) [pedestrian k onSidewalk] [highway, sidewalk, excavation] []

/-- `forbid` (violated): x leaves sidewalk w at a st.obstruction of kind excavation, walks past it on the roadway, and keeps walking on the roadway for 30 s with no obstruction within 5 m. -/
def forbidTrace : Trace :=
  Build.trace 47 0 (Units.seconds 1) fun k t => walkScene t k (decide (k ≤ 4))

/-- `permit` (compliant): x leaves w at the excavation, passes it, and is back on w 2 s after the excavation is beyond the encounter reach. -/
def permitTrace : Trace :=
  Build.trace 26 0 (Units.seconds 1) fun k t => walkScene t k (decide (k ≤ 4 ∨ 15 ≤ k))

/-- `idle` (not_applicable): x walks on sidewalk w and never leaves it. -/
def idleTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t => walkScene t k true

/-- `blind` (unknown): As forbid, but st.region_geometry is absent from the source. -/
def blindTrace : Trace := forbidTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_297_6_o3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"] ]

end TrafficSpecWitness.NRS_484B_297_6_o3
