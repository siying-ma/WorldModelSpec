/-
  Witnesses for NRS_484B_203_1_o1.

  Geometry (the witness's own figures, appearing nowhere in the rule): a two-way highway, the
  rectangle x ∈ [-100, 100] m, y ∈ [-10, 10] m (region 100). The subject (track 1) is a car at the
  origin heading east at 10 m/s, half-extents 2 m × 1 m. The other car (track 2), same size, heads
  west at 10 m/s with its centre 1 m ahead of the subject's and 4 m to one side: its headings are
  exactly opposed (cosine -1, well below -0.9), the two close (relative position · relative
  velocity = -20 < 0), and their projections on the subject's heading share 3 m. At y = -4 it is
  on the subject's right (lateral -4 m), at y = +4 on its left. Three identical instants 1 s apart;
  the rule reads no history.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_203_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_203_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (m 2, m 1, cm 75)

/-- A road user of the given classes. -/
def mover (track : TrackId) (classes : List RoadUserClass) (x y : Int) (heading : Vec) (speed : Int) : RoadUser :=
  Build.user track classes (m x, m y) heading (Units.metresPerSecond speed) body

def car (track : TrackId) (x y : Int) (heading : Vec) (speed : Int) : RoadUser :=
  mover track [.motorVehicle] x y heading speed

/-- The two-way highway. -/
def road : Structure := Build.rect 100 .highway (m (-100)) (m (-10)) (m 100) (m 10)

/-- Three identical instants of a scene. -/
def still (users : List RoadUser) (structures : List Structure) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures []

/-- `forbid` (violated): On a two-way road, an oncoming car passes the moving subject car on the subject's right side. -/
def forbidTrace : Trace :=
  still [car 1 0 0 Build.east 10, car 2 1 (-4) Build.west 10] [road]

/-- `permit` (compliant): On a two-way road, an oncoming car passes the moving subject car on the subject's left side. -/
def permitTrace : Trace :=
  still [car 1 0 0 Build.east 10, car 2 1 4 Build.west 10] [road]

/-- `idle` (not_applicable): The subject car is at rest at the curb while an oncoming car passes. -/
def idleTrace : Trace :=
  still [car 1 0 (-8) Build.east 0, car 2 1 (-3) Build.west 10] [road]

/-- `blind` (unknown): An oncoming car passes the moving subject car; the source declares rel.bearing absent.
    NOT REACHABLE as planned (see task_result.md): masking rel.bearing drops only a measured bearing;
    Core computes it from the positions and the subject's heading, which every track whose
    occupancy is observed must carry (the adapter requires its footprint), and the obligation needs
    both tracks' occupancy. This scene, the forbid geometry, therefore evaluates violated. -/
def blindTrace : Trace :=
  still [car 1 0 0 Build.east 10, car 2 1 (-4) Build.west 10] [road]

/-- `branch_1` (compliant): The subject car drives alone on the road: no vehicle meets it. -/
def branch_1Trace : Trace :=
  still [car 1 0 0 Build.east 10] [road]

/-- `branch_2` (compliant): an oncoming bicycle, not a vehicle, passes the subject car on its right. -/
def branch_2Trace : Trace :=
  still [car 1 0 0 Build.east 10, mover 2 [.bicycle] 1 (-4) Build.west 5] [road]

/-- `branch_3` (compliant): an oncoming car passes on the subject's right but on another highway
    (two separate ways side by side: the subject's at y ∈ [-3, 10], the other's at y ∈ [-20, -4]). -/
def branch_3Trace : Trace :=
  still [car 1 0 0 Build.east 10, car 2 1 (-6) Build.west 10]
    [ Build.rect 100 .highway (m (-100)) (m (-3)) (m 100) (m 10)
    , Build.rect 101 .highway (m (-100)) (m (-20)) (m 100) (m (-4)) ]

/-- `branch_4` (compliant): a car travelling the subject's way, not oncoming, is alongside on its right. -/
def branch_4Trace : Trace :=
  still [car 1 0 0 Build.east 10, car 2 1 (-4) Build.east 12] [road]

/-- `branch_5` (compliant): an oncoming car on the subject's right is still 30 m ahead, not yet alongside. -/
def branch_5Trace : Trace :=
  still [car 1 0 0 Build.east 10, car 2 30 (-4) Build.west 10] [road]

/-- `branch_6` (not_applicable): the subject is a bicycle, not a vehicle, met by an oncoming car on its right. -/
def branch_6Trace : Trace :=
  still [mover 1 [.bicycle] 0 0 Build.east 5, car 2 1 (-4) Build.west 10] [road]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_203_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_203_1_o1
