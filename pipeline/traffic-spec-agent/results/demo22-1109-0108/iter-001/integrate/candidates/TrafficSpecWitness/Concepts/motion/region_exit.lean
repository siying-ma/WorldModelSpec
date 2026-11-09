/-
  Witnesses for drv.motion.region_exit.

  One geometry serves all three scenarios. Region 100 is an intersection: the axis-aligned square
  from (−10, −10) to (10, 10) m. Track 1 is a motor vehicle 4 m long and 2 m wide (half-extents
  2 m, 1 m, 1 m), heading east at 7 m/s, so its centre advances 7 m between observations, which are
  1 s apart from t = 0 ms. Its centre stands at x = −7, 0, 7, 14, 21 m at observations k = 0 … 4,
  i.e. its footprint spans [−9, −5], [−2, 2], [5, 9], [12, 16] and [19, 23] m along x: it overlaps
  the square at the first three observations and lies wholly clear of it at the last two, the
  footprint clearing the boundary at x = 10 with 2 m to spare at k = 3. Centre-in-polygon and
  footprint-overlap therefore agree at every observation, so the occupancy Build derives from the
  geometry is the occupancy the footprint has.

  The overlap thus ends at k = 3 (t = 3000 ms) and at no other observation, so that instant is the
  one the concept holds at:

    `holds`  — the four observations k = 0 … 3, judged at t = 3000 ms alone (the `window`): the
               footprint lay in the square at t = 2000 and lies clear at t = 3000, so the edge is
               true there. The earlier observations are not the event and are not judged.
    `fails`  — the same motion carried one observation further, k = 0 … 4, judged over the whole
               trace: the edge is false at t = 1000 and t = 2000 (the footprint overlapped the
               square at the observation before and overlaps it still, having only moved farther
               in), false at t = 0 as well (overlapping there), and false again at t = 4000, the
               observation after the departure, where the footprint lay clear of the square at the
               observation before. A single false instant is the violation.
    `blind`  — the `holds` motion with `rel.occupies` absent from the manifest, judged at the same
               t = 3000 ms: which regions the footprint overlaps is unobserved, so neither conjunct
               of the edge is decided and the verdict is unknown for that absent atom. The window
               keeps the judgement off t = 0, where the edge would also be unknown for the
               unobserved past before the first observation rather than for the masked atom.

  The instance has no literal formal, no nat and no parameter to fill, and the concept is a formula,
  so it needs no bounds: every figure above is the trace's own.
-/
import TrafficSpec.Concepts.motion.region_exit
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.region_exit

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100 (the intersection, a structure of every trace)

def vehicle : TrackId := 1
def intersectionId : RegionId := 100

/-- The region the vehicle leaves: a 20 m × 20 m intersection square about the origin. -/
def intersection : Structure :=
  Build.rect intersectionId .intersection (m (-10)) (m (-10)) (m 10) (m 10)

/-- The vehicle at centre abscissa `x`, on the x axis, heading east at 7 m/s. -/
def vehicleAt (x : Int) : RoadUser :=
  Build.user vehicle [.motorVehicle] (m x, m 0) Build.east (Units.metresPerSecond 7) (m 2, m 1, m 1)

/-- The centre abscissa at observation `k`: −7, 0, 7, 14, 21 m. -/
def xAt (k : Nat) : Int := 7 * (Int.ofNat k) - 7

/-- The scene at observation `k`: the vehicle and the intersection, occupancy from the geometry. -/
def sceneAt (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some vehicle) [vehicleAt (xAt k)] [intersection] []

/-- The instance every scenario speaks about: no literal formal, no nat, no parameter, and a
    formula body, so nothing is left for the witness to choose. -/
def inst : Concept.Instance :=
  { name := "drv.motion.region_exit@w"
    concept := "drv.motion.region_exit"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A vehicle's footprint overlaps an intersection region at one observation and, at the next, lies wholly clear of it: the concept holds at that next observation. -/
def holdsTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) sceneAt

/-- `fails` (violated): A vehicle's footprint overlaps the intersection region at both observations, having only moved farther into it: the concept fails. It fails as well at the observation after the departure, when the footprint lay clear of the region at the observation before. -/
def failsTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) sceneAt

/-- `blind` (unknown): The source does not observe which regions the vehicle's footprint overlaps, so whether the overlap with the region has just ended cannot be told. -/
def blindTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) sceneAt

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (3000, 3000))
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] (some (3000, 3000)) ]

end TrafficSpecWitness.Concepts.motion.region_exit
