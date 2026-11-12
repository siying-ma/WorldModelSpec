/-
  Witnesses for drv.position.behind.

  Geometry: two east-bound lanes, the left lane 10 (y from 0 to 4 m) and the right lane 11 (y from
  -4 to 0 m), 100 m long from x = -20 m. Both road users are cars of half-length 2 m, half-width 1 m,
  heading east, so their headings are aligned (cosine 1, above the instance's alignment 9/10).
  Three instants, one second apart.
    holds: a (track 1) in the left lane at x = 2k m (k = 0, 1, 2), 2 m/s; b (track 2) at rest in the
      right lane at x = 20 m. a's projection on its heading ends at x ≤ 6 m, b's begins at 18 m: a gap,
      overlap negative; b's bearing from a is forward.
    fails: a at rest in the left lane at x = 18 m, b at rest in the right lane at x = 20 m: a spans 16 to
      20 m, b 18 to 22 m along a's heading, so the projections share 2 m. b's bearing is still forward
      and the headings aligned, so only the overlap decides.
    blind: the holds geometry, with rel.longitudinal_overlap declared absent by the source; the
      source also lacks b's extent, so Core cannot compute the overlap from the footprints (masking
      blanks a computed relation only where its inputs are missing too). b's position and both
      headings stay observed, so the bearing and the alignment are still decided (forward, aligned).
      Without b's footprint its occupancy is not observed either.
  Every relation is computed by Core from the scene; none is supplied.
-/
import TrafficSpec.Concepts.position.behind
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.position.behind

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: headings within the angle whose cosine is 9/10 count
    as aligned. -/
def inst : Concept.Instance :=
  { name := "drv.position.behind@w"
    concept := "drv.position.behind"
    literals := []
    nats := []
    params := [("alignment", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- The left lane (10) and the right lane (11), both east-bound. -/
def lanes : List Structure :=
  [ Build.lane 10 [(m (-20), m 0), (m 80, m 0), (m 80, m 4), (m (-20), m 4)] Build.east
      none (some 11) (some 1) (some 2)
  , Build.lane 11 [(m (-20), m (-4)), (m 80, m (-4)), (m 80, m 0), (m (-20), m 0)] Build.east
      (some 10) none (some 2) (some 2) ]

/-- a travelling in the left lane behind b, which is at rest in the right lane. -/
def behindScene (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1)
    [ Build.user 1 [.motorVehicle] (m (2 * k), m 2) Build.east (Units.metresPerSecond 2) carExtent
    , Build.user 2 [.motorVehicle] (m 20, m (-2)) Build.east (Units.metresPerSecond 0) carExtent ]
    lanes
    []

/-- `holds` (compliant): a travels in the left lane with a gap between its front and the rear of b, which is at rest in the right lane, headings aligned. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => behindScene k t

/-- `fails` (violated): a is alongside b: their projections on a's heading share a length. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 18, m 2) Build.east (Units.metresPerSecond 0) carExtent
      , Build.user 2 [.motorVehicle] (m 20, m (-2)) Build.east (Units.metresPerSecond 0) carExtent ]
      lanes
      []

/-- `blind` (unknown): The source declares rel.longitudinal_overlap absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s := behindScene k t
    { s with users := s.users.map fun u =>
               if u.track == 2 then Build.withKin u fun kn => { kn with extent := none } else u
             occupancyObserved := s.occupancyObserved.filter (· != 2)
             occupies := s.occupies.filter fun (x, _) => x != 2 }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"] ]

end TrafficSpecWitness.Concepts.position.behind
