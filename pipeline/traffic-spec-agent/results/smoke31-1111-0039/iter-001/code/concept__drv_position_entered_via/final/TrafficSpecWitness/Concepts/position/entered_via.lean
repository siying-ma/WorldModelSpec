/-
  Witnesses for drv.position.entered_via.

  Geometry (metres, +x east): r (100) is an intersection, the rectangle x ∈ [8, 30], y ∈ [0, 4];
  c (101) is a lane. In `holds` and `blind`, c is x ∈ [0, 10], y ∈ [0, 4], so it overlaps r over
  x ∈ [8, 10]. In `fails`, c is moved off the path (y ∈ [10, 14]) and the lane c2 (102) takes its
  place, x ∈ [0, 10], y ∈ [0, 4]. Road user 1 (a motor vehicle, half-extents 2 × 1 × 1 m) drives
  east at 4 m/s; its reference point is at x = 5 at t0 = 0 s (in c or c2 only), x = 9 at t1 = 1 s
  (in c or c2 and in r), x = 20 at t2 = 2 s (in r only), all at y = 2. Occupancy is derived from
  the geometry. Every scenario is judged at t2 (`window` = [2000, 2000] ms): at t0 the overlap of r
  has not begun, so the body is false there by design. The instance fills no parameter: the
  concept has none.
-/
import TrafficSpec.Concepts.position.entered_via
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.position.entered_via

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: r ↦ 100, c ↦ 101  (each a structure of every trace)

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

/-- x's reference point at observation k: in the approach only, in both, in r only. -/
def xAt (k : Nat) : Q := if k = 0 then m 5 else if k = 1 then m 9 else m 20

def mover (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (xAt k, m 2) Build.east (Units.metresPerSecond 4) (m 2, m 1, m 1)

def regionR : Structure := Build.rect 100 .intersection (m 8) (m 0) (m 30) (m 4)

/-- `holds` (compliant): x overlaps c and not r at t0, overlaps c and r at t1, overlaps r only at t2; judged at t2. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover k ]
      [ regionR, Build.rect 101 .lane (m 0) (m 0) (m 10) (m 4) ]
      [ ]

/-- `fails` (violated): x overlaps region c2 and not r at t0, overlaps c2 and r at t1 without overlapping c, overlaps r at t2; judged at t2. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover k ]
      [ regionR
      , Build.rect 101 .lane (m 0) (m 10) (m 10) (m 14)
      , Build.rect 102 .lane (m 0) (m 0) (m 10) (m 4) ]
      [ ]

/-- `blind` (unknown): rel.occupies of x and c is not observed at t1, the observation at which x's overlap of r began; judged at t2.
    The scenes are those of `holds`, except that x's occupancy is not observed at t1; the manifest
    masks `rel.occupies` as the record declares, which blanks it at every observation (see
    task_result.md: the gate then also finds the onset search truncated at t0). -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s := Build.scene t (some 1)
      [ mover k ]
      [ regionR, Build.rect 101 .lane (m 0) (m 0) (m 10) (m 4) ]
      [ ]
    if k = 1 then { s with occupancyObserved := [], occupies := [] } else s

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
