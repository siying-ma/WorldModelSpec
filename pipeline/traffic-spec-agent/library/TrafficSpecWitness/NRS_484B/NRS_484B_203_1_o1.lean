/-
  Witnesses for NRS_484B_203_1_o1.

  Geometry (the witness's own figures, nowhere in the rule): a two-way highway region 10, the
  rectangle x ∈ [-50, 50] m, y ∈ [-5, 5] m. Cars are 5 m long and 2 m wide (half-extents
  2.5 m × 1 m × 0.75 m). The subject (track 1) heads east; the other car (track 2) heads west,
  headings exactly opposed (cosine −1, well below −0.9), its centre 2 m ahead of the subject's
  along the east axis, so the footprints' projections share 3 m and the two still close
  (relative position · relative velocity < 0). The two centres are 3.5 m apart across the road:
  in `forbid` (and `blind`) the other car is 3.5 m to the subject's right, in `permit` 3.5 m to its
  left. Moving speed is 10 m/s, far above the 0.1 m/s halt tolerance; the idle subject's speed is 0.
  Every scene repeats over three instants one second apart; nothing looks back in time.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_203_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_203_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 250, cm 100, cm 75)

def highway : Structure := Build.rect 10 .highway (m (-50)) (m (-5)) (m 50) (m 5)

def subjectCar (y : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, y) Build.east speed carExtent

def otherCar (y : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (m 2, y) Build.west (Units.metresPerSecond 10) carExtent

/-- Subject at lateral `ys`, oncoming car at lateral `yo`, subject speed `v`. -/
def meeting (ys yo v : Q) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectCar ys v, otherCar yo ]
      [ highway ]
      [ ]

/-- `forbid` (violated): On a two-way road, an oncoming car passes the moving subject car on the subject's right side. -/
def forbidTrace : Trace := meeting (cm 175) (cm (-175)) (Units.metresPerSecond 10)

/-- `permit` (compliant): On a two-way road, an oncoming car passes the moving subject car on the subject's left side. -/
def permitTrace : Trace := meeting (cm (-175)) (cm 175) (Units.metresPerSecond 10)

/-- `idle` (not_applicable): The subject car is at rest at the curb while an oncoming car passes. -/
def idleTrace : Trace := meeting (cm (-375)) (cm 175) (Units.metresPerSecond 0)

/-- `blind` (unknown): An oncoming car passes the moving subject car on the subject's right side; the source declares rel.occupies and rel.bearing absent, so whether the two occupy the same highway is not observed (and the measured bearing is not supplied), and the duty is unknown. -/
def blindTrace : Trace := meeting (cm 175) (cm (-175)) (Units.metresPerSecond 10)

/-- `branch_1` (compliant): The subject car drives alone on the road: no vehicle meets it. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectCar (cm (-175)) (Units.metresPerSecond 10) ]
      [ highway ]
      [ ]

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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies", "rel.bearing"]
  , witness "branch_1" branch_1Trace .compliant ]

end TrafficSpecWitness.NRS_484B_203_1_o1
