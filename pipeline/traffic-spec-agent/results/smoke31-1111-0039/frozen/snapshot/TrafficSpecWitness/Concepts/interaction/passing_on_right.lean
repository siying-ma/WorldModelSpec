/-
  Witnesses for drv.interaction.passing_on_right.

  A straight eastbound road: a shoulder s (id 10) for y ∈ [-2, 1.5] and the rightmost lane l
  (id 11) for y ∈ [1.5, 5.5], both x ∈ [-100, 200]. Both road users are cars, 5 m long and 2 m wide
  (half-extents 2.5 m, 1 m, 0.75 m), heading east. Three instants 0.5 s apart.

  holds: x (track 1) on the shoulder centre line y = 0 at 20 m/s, starting at x = 0; y (track 2)
  in the lane at y = 3.5 at 15 m/s, starting 3 m ahead. y's lead over x is 3 m, 0.5 m, -2 m: the
  projections on x's heading share 2 m, 4.5 m, 3 m — side by side throughout; y 3.5 m to x's left;
  x gaining by 5 m/s.
  fails: both in the lane at y = 3.5, x at 20 m/s behind y at 15 m/s, y's lead 15 m, 12.5 m, 10 m:
  the projections are 10 m, 7.5 m, 5 m apart (overlap negative), y straight ahead, not to the left.
  blind: the holds motion, as a source that declares `rel.bearing` absent and does not report y's
  position (so Core cannot compute the bearing from the kinematics; masking `rel.bearing` blanks only
  a measured bearing). Headings and speeds are reported; the overlap along x's heading is a
  measured relation from x to y (2 m, 4.5 m, 3 m), since without y's position Core cannot compute it.
  Without y's footprint its occupancy is not observed: only x's is.

  Instance: aligned_cosine = 9/10 (about 25.8°), speed_margin = 1 m/s.
-/
import TrafficSpec.Concepts.interaction.passing_on_right
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.passing_on_right

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1, y ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.passing_on_right@w"
    concept := "drv.interaction.passing_on_right"
    literals := []
    nats := []
    params := [("aligned_cosine", .lit (Units.ratio 9 10) .ratio),
               ("speed_margin", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def car : Q × Q × Q := (cm 250, m 1, cm 75)

def road : List Structure :=
  [ Build.rect 10 .shoulder (m (-100)) (cm (-200)) (m 200) (cm 150)
  , Build.rect 11 .lane (m (-100)) (cm 150) (m 200) (cm 550) ]

/-- x's distance along the road at step k (20 m/s, 0.5 s steps). -/
def xAlong (k : Nat) : Q := m (10 * (k : Int))
/-- y's distance along the road at step k, from a start `y0` (15 m/s, 0.5 s steps). -/
def yAlong (y0 : Int) (k : Nat) : Q := Q.add (m y0) (cm (750 * (k : Int)))

def sideBySide : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (xAlong k, m 0) Build.east (Units.metresPerSecond 20) car
      , Build.user 2 [.motorVehicle] (yAlong 3 k, cm 350) Build.east (Units.metresPerSecond 15) car ]
      road
      [ ]

/-- `holds` (compliant): x drives on the shoulder alongside a slower y in the rightmost lane, y on x's left, the bodies side by side, x gaining. -/
def holdsTrace : Trace := sideBySide

/-- `fails` (violated): x follows y in the same lane, its body wholly behind y's. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (xAlong k, cm 350) Build.east (Units.metresPerSecond 20) car
      , Build.user 2 [.motorVehicle] (yAlong 15 k, cm 350) Build.east (Units.metresPerSecond 15) car ]
      road
      [ ]

/-- The overlap the blind source measures at step k: the holds geometry's 2 m, 4.5 m, 3 m. -/
def blindOverlap : Nat → Q
  | 0 => cm 200
  | 1 => cm 450
  | _ => cm 300

/-- `blind` (unknown): x and y are side by side and x is faster; the source declares rel.bearing absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.withRelations
      { Build.scene t (some 1)
        [ Build.user 1 [.motorVehicle] (xAlong k, m 0) Build.east (Units.metresPerSecond 20) car
        , Build.withKin
            (Build.user 2 [.motorVehicle] (yAlong 3 k, cm 350) Build.east (Units.metresPerSecond 15) car)
            fun kin => { kin with position := none } ]
        road
        [ ] with occupancyObserved := [1] }
      [ Build.relation 1 2 fun r => { r with longitudinalOverlap := some (blindOverlap k) } ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1), ("y", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"] ]

end TrafficSpecWitness.Concepts.interaction.passing_on_right
