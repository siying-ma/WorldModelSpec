/-
  Witnesses for NRS_484B_297_6_o2.

  The highway h (region 1) is the rectangle x ∈ [-50, 50] m, y ∈ [-10, 5] m; the sidewalk w
  (region 2, lying on h) is its strip y ∈ [2, 5] m, so the sidewalk edge is the line y = 2 m. A
  barrier (region 3, an obstruction) blocks the sidewalk at x ∈ [0, 1] m. The pedestrian x (track 1)
  is 0.5 m by 0.5 m, heading east at 1 m/s; scenes are 1 s apart.

  At t = 0 s x walks on w at (-1, 3.5) m, its body 0.75 m from the barrier. From t = 1 s:
  - forbid / blind: x walks east at y = -2.25 m, its body 4 m from w, in no bicycle lane;
  - permit: x walks east at y = 1.25 m, its body 0.5 m from w, and at t = 3 s is back on w;
  - idle: x stays on w;
  - branch_1: x walks in a bicycle lane (region 4, y ∈ [-3, 0] m) at y = -1.25 m, its body 3 m
    from w, with a second barrier (region 5, x ∈ [-1, 8] m, y ∈ [-0.5, 1.5] m) 0.5 m from its body.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_297_6_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_297_6_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def highway : Structure := Build.rect 1 .highway (m (-50)) (m (-10)) (m 50) (m 5)
def sidewalk : Structure := { Build.rect 2 .sidewalk (m (-50)) (m 2) (m 50) (m 5) with ways := some [1] }
def barrier : Structure :=
  { Build.rect 3 .obstruction (m 0) (m 2) (m 1) (m 5) with obstructionKind := some .barrier, ways := some [1] }
def bikeLane : Structure :=
  { Build.rect 4 .bicycleLaneOrPath (m (-50)) (m (-3)) (m 50) (m 0) with ways := some [1] }
def laneBarrier : Structure :=
  { Build.rect 5 .obstruction (m (-1)) (cm (-50)) (m 8) (cm 150) with obstructionKind := some .barrier, ways := some [1] }

def pedestrian (pos : Vec) : RoadUser :=
  Build.user 1 [.pedestrian] pos Build.east (Units.metresPerSecond 1) (cm 25, cm 25, cm 90)

/-- x on the sidewalk at k = 0, then at `y` on the highway, eastward. -/
def detourPos (y : Q) (k : Nat) : Vec :=
  if k == 0 then (m (-1), cm 350) else (m (Int.ofNat (2 * k)), y)

/-- `forbid` (violated): x leaves sidewalk w at a st.obstruction of kind barrier and walks on the roadway of h 4 m from w, outside any bicycle lane. -/
def forbidTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian (detourPos (cm (-225)) k) ]
      [ highway, sidewalk, barrier ]
      [ ]

/-- `permit` (compliant): x leaves w at the barrier and walks 0.5 m from w until it returns to the sidewalk. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian (if k == 3 then (m 6, cm 350) else detourPos (cm 125) k) ]
      [ highway, sidewalk, barrier ]
      [ ]

/-- `idle` (not_applicable): x walks on sidewalk w and never leaves it. -/
def idleTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian (m (Int.ofNat k - 6), cm 350) ]
      [ highway, sidewalk, barrier ]
      [ ]

/-- `blind` (unknown): As forbid, but st.region_geometry is absent from the source. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): x walks in a st.bicycle_lane_or_path 3 m from w while a st.obstruction lies within 1 m of x. -/
def branch_1Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian (detourPos (cm (-125)) k) ]
      [ highway, sidewalk, barrier, bikeLane, laneBarrier ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_297_6_o2"
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
  , witness "branch_1" branch_1Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_297_6_o2
