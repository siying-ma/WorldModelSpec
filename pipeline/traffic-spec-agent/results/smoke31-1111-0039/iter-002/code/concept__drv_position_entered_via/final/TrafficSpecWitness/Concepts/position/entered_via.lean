/-
  Witnesses for drv.position.entered_via.

  Geometry: region r (100) is a lane, the rectangle x ∈ [10, 20] m, y ∈ [-2, 6] m; region c (101)
  is a lane x ∈ [0, 10] m, y ∈ [2, 6] m, abutting r on its west edge (north half); region c2 (102)
  is a lane x ∈ [0, 10] m, y ∈ [-2, 2] m, abutting r on its west edge (south half). Road user 1 is a
  motor vehicle heading east, half-extents 2 m × 1 m × 1 m, so its footprint spans [px − 2, px + 2]
  in x. Its abscissa is px = 6, 10, 14 m at the three observations (footprints [4, 8], [8, 12],
  [12, 16]): in the first it lies in the western region only, in the second it straddles the
  western region and r, in the third it lies in r only. Occupancy is given explicitly, as these
  footprints overlap the regions (the reference point alone would not show the straddle).
  The instance has no parameters. Observations every 1 s from t = 0 ms; every scenario is judged
  at the third observation (t = 2000).
  - holds: y = 4 m, the western region is c: occupies c at t0; c and r at t1; r at t2.
  - fails: y = 0 m, the western region is c2: occupies c2 at t0; c2 and r at t1 (not c); r at t2.
  - blind: the holds scenes with `rel.occupies` absent from the manifest. The search for the
    beginning of the overlap reaches the trace start (t0) through unknown overlaps, so the verdict
    also carries the truncation there; the plan declares no history boundary for it (see
    task_result.md).
-/
import TrafficSpec.Concepts.position.entered_via
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.position.entered_via

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: r ↦ 100, c ↦ 101

/-- The instance every scenario speaks about: the concept has no literal formals or parameters. -/
def inst : Concept.Instance :=
  { name := "drv.position.entered_via@w"
    concept := "drv.position.entered_via"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The region r: a lane x ∈ [10, 20] m, y ∈ [-2, 6] m. -/
def regionR : Structure := Build.rect 100 .lane (m 10) (m (-2)) (m 20) (m 6)

/-- The region c: a lane x ∈ [0, 10] m, y ∈ [2, 6] m. -/
def regionC : Structure := Build.rect 101 .lane (m 0) (m 2) (m 10) (m 6)

/-- The region c2: a lane x ∈ [0, 10] m, y ∈ [-2, 2] m. -/
def regionC2 : Structure := Build.rect 102 .lane (m 0) (m (-2)) (m 10) (m 2)

def structures : List Structure := [regionR, regionC, regionC2]

/-- x's abscissa (m) at each observation. -/
def px (k : Nat) : Int :=
  match k with
  | 0 => 6
  | 1 => 10
  | _ => 14

/-- Road user x at observation `k`, on the line of ordinate `y` (m), heading east. -/
def userX (k : Nat) (y : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (px k), m y) Build.east (Units.metresPerSecond 4) (m 2, m 1, m 1)

/-- The regions x's footprint overlaps at observation `k`, the western one being `west`. -/
def occ (k : Nat) (west : RegionId) : List (TrackId × RegionId) :=
  match k with
  | 0 => [(1, west)]
  | 1 => [(1, west), (1, 100)]
  | _ => [(1, 100)]

/-- `holds` (compliant): x overlaps c and not r at t0, overlaps c and r at t1, overlaps r only at t2; judged at t2. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX k 4 ]
      structures
      [ ]
      (occupies := some (occ k 101))

/-- `fails` (violated): x overlaps region c2 and not r at t0, overlaps c2 and r at t1 without overlapping c, overlaps r at t2; judged at t2. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX k 0 ]
      structures
      [ ]
      (occupies := some (occ k 102))

/-- `blind` (unknown): The scenes of holds with rel.occupies masked by the manifest: x's overlap of r and of c is unobserved at every observation, so the beginning of the current overlap is not observed and the search for it reaches x's first observation (t0) without finding it; judged at t2. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX k 4 ]
      structures
      [ ]
      (occupies := some (occ k 101))

def witness (name : String) (τ : Trace) (expected : Verdict) (window : Timestamp × Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    regions := [("r", 100), ("c", 101)]
    expected := expected
    window := some window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant (2000, 2000)
  , witness "fails" failsTrace .violated (2000, 2000)
  , witness "blind" blindTrace (.unknown []) (2000, 2000) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.position.entered_via
