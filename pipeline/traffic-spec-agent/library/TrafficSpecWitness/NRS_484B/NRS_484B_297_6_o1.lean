/-
  Witnesses for NRS_484B_297_6_o1.

  Geometry (world frame, +x east, +y north): highway h (region 10) spans y ∈ [-13, 6]; its roadway
  (11) y ∈ [-10, 3]; the sidewalk w (20) y ∈ [3, 6] along the north edge of the roadway, and a far
  sidewalk (21) y ∈ [-13, -10] along the south edge, both lying on h. An excavation (30) occupies
  the sidewalk at x ∈ [2, 6] (or, where the narrative has none in the way, x ∈ [30, 34]). A bicycle
  lane (40) on h spans y ∈ [-1.5, 0.5].

  The pedestrian x (track 1, half-extents 0.25 × 0.25 × 0.9 m, 1.4 m/s east) is observed at
  t = 0, 1, 2, 3 s: at t = 0 on w at (1, 4.5), its front 0.75 m from the excavation; from t = 1 on
  the roadway at x = 2, 4, 6 m and a fixed y: y = -1.25 (body 4.0 m from w), y = 2.35 (0.4 m from
  w), or y = -0.25 (in the bicycle lane, 3.0 m from w). Every figure here is the witness's own and
  appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_297_6_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_297_6_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def walkSpeed : Q := Units.micrometresPerSecond 1400000
def body : Q × Q × Q := (cm 25, cm 25, cm 90)

def highway : Structure := Build.rect 10 .highway (m (-50)) (m (-13)) (m 50) (m 6)
def roadway : Structure := { Build.rect 11 .roadway (m (-50)) (m (-10)) (m 50) (m 3) with ways := some [10] }
def sidewalk : Structure := { Build.rect 20 .sidewalk (m (-50)) (m 3) (m 50) (m 6) with ways := some [10] }
def farSidewalk : Structure := { Build.rect 21 .sidewalk (m (-50)) (m (-13)) (m 50) (m (-10)) with ways := some [10] }
def excavation (x0 x1 : Q) : Structure :=
  { Build.rect 30 .obstruction x0 (m 3) x1 (m 6) with obstructionKind := some .excavation, ways := some [10] }
def nearExcavation : Structure := excavation (m 2) (m 6)
def farExcavation : Structure := excavation (m 30) (m 34)
def bikeLane : Structure :=
  { Build.rect 40 .bicycleLaneOrPath (m (-50)) (cm (-150)) (m 50) (cm 50) with ways := some [10] }

def ped (p : Vec) (speed : Q := walkSpeed) : RoadUser := Build.user 1 [.pedestrian] p Build.east speed body

/-- x on w at (1, 4.5) at t = 0 (moving at `speed0`), then on the highway at (2k, `offY`). -/
def detour (offY : Q) (obst : Structure) (extra : List Structure := [])
    (asms : List (AsmId × Bool) := []) (speed0 : Q := walkSpeed) : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let u := if k == 0 then ped (m 1, cm 450) speed0 else ped (m (2 * Int.ofNat k), offY)
    Build.scene t (some 1) [u] ([highway, roadway, sidewalk, farSidewalk, obst] ++ extra) []
      (assumptions := asms)

/-- Only the excavation is in x's way: no section of the sidewalk is declared missing or impassable. -/
def sidewalkPassable : List (AsmId × Bool) := [("asm.sidewalk_section_missing_or_impassable", false)]

/-- `forbid` (violated): Pedestrian x walks on sidewalk w (on highway h), comes within 1 m of a st.obstruction of kind excavation, steps onto the roadway of h and walks 4 m from w. -/
def forbidTrace : Trace := detour (cm (-125)) nearExcavation [] sidewalkPassable

/-- `permit` (compliant): Same, but x walks on the roadway 0.4 m from the edge of w. -/
def permitTrace : Trace := detour (cm 235) nearExcavation [] sidewalkPassable

/-- `idle` (not_applicable): x walks on the sidewalk throughout. -/
def idleTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ped (m (Int.ofNat k - 2), cm 450)]
      [highway, roadway, sidewalk, farSidewalk, nearExcavation] []

/-- `blind` (unknown): As forbid, but st.region_geometry is absent, so neither the encounter nor x's distance to the sidewalk can be read. -/
def blindTrace : Trace := detour (cm (-125)) nearExcavation [] sidewalkPassable

/-- `branch_1` (not_applicable): On its detour x walks in a bicycle lane 3 m from w and the trace declares asm.area_beside_bicycle_lane_impassable true. -/
def branch_1Trace : Trace :=
  detour (cm (-25)) nearExcavation [bikeLane] [("asm.area_beside_bicycle_lane_impassable", true)]

/-- `branch_2` (violated): As branch_1, but the trace declares asm.area_beside_bicycle_lane_impassable false. -/
def branch_2Trace : Trace :=
  detour (cm (-25)) nearExcavation [bikeLane] [("asm.area_beside_bicycle_lane_impassable", false)]

/-- `branch_3` (violated): no obstruction in reach, but the sidewalk section is declared missing or
    impassable where x leaves it; x walks 4 m from w. -/
def branch_3Trace : Trace :=
  detour (cm (-125)) farExcavation [] [("asm.sidewalk_section_missing_or_impassable", true)]

/-- `branch_4` (not_applicable): no obstruction in reach and the sidewalk declared passable; x
    leaves it for the roadway 4 m from w — no detour. -/
def branch_4Trace : Trace :=
  detour (cm (-125)) farExcavation [] [("asm.sidewalk_section_missing_or_impassable", false)]

/-- `branch_5` (not_applicable): as forbid, but x stands still on the sidewalk at its last
    observation there — it was not walking or traveling on the sidewalk when it left. -/
def branch_5Trace : Trace := detour (cm (-125)) nearExcavation (speed0 := Q.zero)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_297_6_o1"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_297_6_o1
