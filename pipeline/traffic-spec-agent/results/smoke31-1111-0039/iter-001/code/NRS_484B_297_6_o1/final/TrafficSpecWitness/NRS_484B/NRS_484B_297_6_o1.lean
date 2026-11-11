/-
  Witnesses for NRS_484B_297_6_o1.

  Geometry (+x east, +y north): highway 1 spans x ∈ [-50, 50], y ∈ [-10, 3]; roadway 3 is its
  part y ∈ [-10, 0], sidewalk 2 its part y ∈ [0, 3], both lying on it. A barrier (obstruction 4)
  stands on the sidewalk at x ∈ [5, 6], y ∈ [0.5, 2.5].

  Instants at 1 s spacing (0, 1000, 2000 ms). Pedestrian 1 (half 0.25 × 0.25 m) walks east at
  1.3 m/s: at 0 s on the sidewalk at (4, 1.5), 0.75 m from the barrier; at 1 s and 2 s on the
  roadway at y = -0.5, at x = 4.5 and 5.8. Vehicle 2 (half 2.3 × 0.9 m) drives west at 10 m/s
  along y = -1.5, always 10 m east of the pedestrian: closing at 11.3 m/s, closest approach in
  about 0.9 s at 1 m between centres, well inside the 4.1 s gap and the 3 m clearance.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_297_6_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_297_6_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def highway : Structure := Build.rect 1 .highway (m (-50)) (m (-10)) (m 50) (m 3)
def sidewalk : Structure :=
  { Build.rect 2 .sidewalk (m (-50)) (m 0) (m 50) (m 3) with ways := some [1] }
def roadway : Structure :=
  { Build.rect 3 .roadway (m (-50)) (m (-10)) (m 50) (m 0) with ways := some [1] }
def barrier : Structure :=
  { Build.rect 4 .obstruction (m 5) (cm 50) (m 6) (cm 250) with
      ways := some [1], obstructionKind := some .barrier }

def pedHalf : Q × Q × Q := (cm 25, cm 25, cm 85)

/-- The pedestrian's position at instant `k`: on the sidewalk at the barrier, then on the roadway. -/
def pedPos : Nat → Vec
  | 0 => (m 4, cm 150)
  | 1 => (cm 450, cm (-50))
  | _ => (cm 580, cm (-50))

def pedestrian (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (pedPos k) Build.east (cm 130) pedHalf

def vehicle (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] ((pedPos k).1.add (m 10), cm (-150)) Build.west
    (Units.metresPerSecond 10) (cm 230, cm 90, cm 75)

/-- `forbid` (violated): x walks on sidewalk w, comes within 1 m of a st.obstruction of kind barrier, steps onto the roadway of h and walks on at 1.3 m/s while vehicle z, 10 m away at 10 m/s, is predicted to pass within 1 m of x in 1 s. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian k, vehicle k ]
      [ highway, sidewalk, roadway, barrier ]
      [ ]

/-- `permit` (compliant): As forbid, but x is the only road user in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian k ]
      [ highway, sidewalk, roadway, barrier ]
      [ ]

/-- `idle` (not_applicable): x walks on sidewalk w with no obstruction and never leaves it. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (cm (400 + 130 * (k : Int)), cm 150) Build.east (cm 130) pedHalf ]
      [ highway, sidewalk, roadway ]
      [ ]

/-- `blind` (unknown): As forbid, but rel.occupies of x and the sidewalk is not observed. -/
def blindTrace : Trace := forbidTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_297_6_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (0, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] ]

end TrafficSpecWitness.NRS_484B_297_6_o1
