/-
  Witnesses for drv.position.entered_via.

  Geometry: road user 1 is a motor vehicle heading east along y = 0 at 10 m/s, half-extents
  2 m × 1 m × 1 m. Occupancy is derived from geometry (its reference point inside a region).
  Region r (100) is a lane, x ∈ [10, 20] m, y ∈ [-2, 2] m. Observations every 1 s from t = 0 ms;
  every scenario is judged at t2 = 2000.
  - holds: region c (101) is a lane x ∈ [0, 12] m, y ∈ [-2, 2] m, overlapping r on x ∈ [10, 12].
    x stands at px = 5 (c only, t0), 11 (c and r, t1: the beginning), 15 (r only, t2).
  - fails: region c2 (102) is a lane x ∈ [0, 12] m, y ∈ [-2, 2] m; c (101) is a lane beside it,
    x ∈ [0, 12] m, y ∈ [2, 6] m, which x never overlaps. x stands at px = 5 (c2 only, t0), 11 (c2
    and r, t1: the beginning, not through c), 15 (r only, t2).
  - blind: the holds trace with `rel.occupies` unobserved; the search for the beginning reaches
    x's first observation (t0), the history boundary, without finding it.
-/
import TrafficSpec.Concepts.position.entered_via
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.position.entered_via

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: r ↦ 100, c ↦ 101

/-- The instance every scenario speaks about: the concept has no literal formal and no parameter. -/
def inst : Concept.Instance :=
  { name := "drv.position.entered_via@w"
    concept := "drv.position.entered_via"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The region r: a lane x ∈ [10, 20] m, y ∈ [-2, 2] m. -/
def regionR : Structure := Build.rect 100 .lane (m 10) (m (-2)) (m 20) (m 2)

/-- The region c of holds and blind: a lane x ∈ [0, 12] m, y ∈ [-2, 2] m, overlapping r. -/
def regionCOnPath : Structure := Build.rect 101 .lane (m 0) (m (-2)) (m 12) (m 2)

/-- The region c of fails: a lane x ∈ [0, 12] m, y ∈ [2, 6] m, beside x's path. -/
def regionCAside : Structure := Build.rect 101 .lane (m 0) (m 2) (m 12) (m 6)

/-- The region c2 of fails: a lane x ∈ [0, 12] m, y ∈ [-2, 2] m, overlapping r. -/
def regionC2 : Structure := Build.rect 102 .lane (m 0) (m (-2)) (m 12) (m 2)

/-- Road user x with its reference point at abscissa `pxCm` (cm), heading east. -/
def userX (pxCm : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm pxCm, m 0) Build.east (Units.metresPerSecond 10) (m 2, m 1, m 1)

/-- x's abscissa (cm) at each observation. -/
def pos (k : Nat) : Int :=
  match k with
  | 0 => 500
  | 1 => 1100
  | _ => 1500

/-- `holds` (compliant): x overlaps c and not r at t0, overlaps c and r at t1, overlaps r only at t2; judged at t2. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX (pos k) ]
      [ regionR, regionCOnPath ]
      [ ]

/-- `fails` (violated): x overlaps region c2 and not r at t0, overlaps c2 and r at t1 without overlapping c, overlaps r at t2; judged at t2. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX (pos k) ]
      [ regionR, regionCAside, regionC2 ]
      [ ]

/-- `blind` (unknown): The scenes of holds with rel.occupies masked by the manifest: x's overlap of r and of c is unobserved at every observation, so the beginning of the current overlap is not observed and the search for it runs back to the history boundary the contract declares, x's first observation (t0), without finding it; the verdict is unknown for the masked atom and for the search reaching that boundary; judged at t2. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX (pos k) ]
      [ regionR, regionCOnPath ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("r", 100), ("c", 101)]
    expected := expected
    window := some (2000, 2000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.position.entered_via
