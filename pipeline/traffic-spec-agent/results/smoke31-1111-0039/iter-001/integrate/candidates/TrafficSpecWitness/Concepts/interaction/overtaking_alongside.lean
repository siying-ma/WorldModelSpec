/-
  Witnesses for drv.interaction.overtaking_alongside.

  Geometry: a straight road along +x (east), no structures. Both road users are motor vehicles
  heading east, half-length 6 m, half-width 1 m. Three instants, 1 s apart (k = 0, 1, 2).

  - holds: x (track 1) in the left half of the road at y = 4 m, 20 m/s, centre at 20k − 4 m;
    y (track 2) at y = 0 m, 15 m/s, centre at 15k m. Their centres are −4, +1, +6 m apart along
    the heading, so the projections share 8, 11, 6 m: alongside throughout. Headings identical
    (cosine 1 > 9/10); speed difference 5 m/s > 1 m/s.
  - fails: x follows y in the same lane (both at y = 0 m), x 30 m behind at k = 0, 20 m/s against
    y's 15 m/s: centres −30, −25, −20 m apart, so the projections leave a gap of 18, 13, 8 m
    (negative overlap). Aligned and faster, but not alongside.
  - blind: the holds positions, headings and speeds, with rel.longitudinal_overlap unobserved by
    the source: no measured overlap, and no body extents from which Core could compute one
    (headings and speeds, which decide the other two conjuncts, are observed). Without
    footprints no occupancy is observed either.

  Instance: aligned_cosine = 9/10 (ratio), speed_margin = 1 m/s.
-/
import TrafficSpec.Concepts.interaction.overtaking_alongside
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.overtaking_alongside

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1, y ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.overtaking_alongside@w"
    concept := "drv.interaction.overtaking_alongside"
    literals := []
    nats := []
    params := [("aligned_cosine", .lit (Units.ratio 9 10) .ratio),
               ("speed_margin", .lit (Units.metresPerSecond 1) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def body : Q × Q × Q := (m 6, m 1, m 1)

/-- x beside y: x 4 m to the left, its centre at 20k − 4 m, y's at 15k m. -/
def besideScene (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1)
    [ Build.user 1 [.motorVehicle] (m (20 * (k : Int) - 4), m 4) Build.east (Units.metresPerSecond 20) body
    , Build.user 2 [.motorVehicle] (m (15 * (k : Int)), m 0) Build.east (Units.metresPerSecond 15) body ]
    [ ]
    [ ]

/-- `holds` (compliant): x and y head the same way within aligned_cosine, their footprints share a positive length along x's heading, and x's kin.speed exceeds y's by more than speed_margin: x is overtaking y alongside. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => besideScene k t

/-- `fails` (violated): x follows y in the same lane with a negative rel.longitudinal_overlap (a gap between the projections) at a higher speed: x has not drawn alongside, so the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 * (k : Int) - 30), m 0) Build.east (Units.metresPerSecond 20) body
      , Build.user 2 [.motorVehicle] (m (15 * (k : Int)), m 0) Build.east (Units.metresPerSecond 15) body ]
      [ ]
      [ ]

/-- `blind` (unknown): x and y head the same way and x is faster, but the source does not observe rel.longitudinal_overlap: whether they are side by side is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s := besideScene k t
    { s with users := s.users.map (fun u => Build.withKin u fun kn => { kn with extent := none })
             occupancyObserved := []
             occupies := [] }

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
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"] ]

end TrafficSpecWitness.Concepts.interaction.overtaking_alongside
