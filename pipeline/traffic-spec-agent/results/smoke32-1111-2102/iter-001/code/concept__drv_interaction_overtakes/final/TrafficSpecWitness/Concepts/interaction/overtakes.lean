/-
  Witnesses for drv.interaction.overtakes.

  Geometry: two east-bound lanes, the left lane 10 (y from 0 to 4 m) and the right lane 11 (y from
  -4 to 0 m), 200 m long from x = -20 m. Both road users are cars of half-length 2 m, half-width 1 m,
  heading east, so their headings are aligned (cosine 1, above the instance's alignment 9/10).
  Seven instants k = 0 … 6, one second apart (t = 1000·k ms).
    holds: a (track 1) in the left lane at x = 10k m, 10 m/s; b (track 2) in the right lane at
      x = 20 + 5k m, 5 m/s. a spans 10k ± 2, b 20 + 5k ± 2 along the heading: a wholly behind b at
      k ≤ 3 (gap 16 − 5k m), alongside at k = 4 (both 38 to 42 m), wholly ahead at k ≥ 5 (gap
      5k − 24 m). b behind a rises at k = 5 (t = 5000 ms): the witness speaks of that observation,
      the recognition, at which alone the concept holds.
    fails: b as in holds; a at x = 10k m up to k = 4, then keeps pace with b at 20 + 5k m (5 m/s):
      a comes alongside at k = 4 and stays alongside to the end, never wholly ahead, so b behind a
      never rises and the concept is false at every observation.
    blind: the holds geometry; from k = 4 on the source lacks b's extent and declares
      rel.longitudinal_overlap absent, so Core cannot compute the overlap from the footprints there
      (masking blanks a computed relation only where its inputs are missing too). At k ≤ 3 a is
      decidedly behind b and the headings stay aligned, so only the recognition at k = 5 — whether
      b is wholly behind a there and was not at k = 4 — is undecided, by the masked atom alone.
      Without b's footprint its occupancy is not observed either.
  Every relation is computed by Core from the scene; none is supplied.
-/
import TrafficSpec.Concepts.interaction.overtakes
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.overtakes

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: headings within the angle whose cosine is 9/10 count
    as aligned. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.overtakes@w"
    concept := "drv.interaction.overtakes"
    literals := []
    nats := []
    params := [("alignment", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- The left lane (10) and the right lane (11), both east-bound. -/
def lanes : List Structure :=
  [ Build.lane 10 [(m (-20), m 0), (m 180, m 0), (m 180, m 4), (m (-20), m 4)] Build.east
      none (some 11) (some 1) (some 2)
  , Build.lane 11 [(m (-20), m (-4)), (m 180, m (-4)), (m 180, m 0), (m (-20), m 0)] Build.east
      (some 10) none (some 2) (some 2) ]

/-- b in the right lane at 5 m/s. -/
def userB (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (20 + 5 * k), m (-2)) Build.east (Units.metresPerSecond 5) carExtent

/-- a in the left lane at 10 m/s, passing b. -/
def passScene (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1)
    [ Build.user 1 [.motorVehicle] (m (10 * k), m 2) Build.east (Units.metresPerSecond 10) carExtent
    , userB k ]
    lanes
    []

/-- The recognition observation: a becomes wholly ahead of b at k = 5. -/
def recognition : Timestamp := 5000

/-- `holds` (compliant): a, in the left lane wholly behind b with aligned headings, comes alongside and becomes wholly ahead of b; the concept holds at that observation. -/
def holdsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t => passScene k t

/-- `fails` (violated): a comes alongside b and stays alongside to the end of the recording, never wholly ahead. -/
def failsTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    let a :=
      if k ≤ 4 then
        Build.user 1 [.motorVehicle] (m (10 * k), m 2) Build.east (Units.metresPerSecond 10) carExtent
      else
        Build.user 1 [.motorVehicle] (m (20 + 5 * k), m 2) Build.east (Units.metresPerSecond 5) carExtent
    Build.scene t (some 1) [a, userB k] lanes []

/-- `blind` (unknown): The source declares rel.longitudinal_overlap absent. -/
def blindTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    let s := passScene k t
    if k < 4 then s
    else
      { s with users := s.users.map fun u =>
                 if u.track == 2 then Build.withKin u fun kn => { kn with extent := none } else u
               occupancyObserved := s.occupancyObserved.filter (· != 2)
               occupies := s.occupies.filter fun (x, _) => x != 2 }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (recognition, recognition))
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"] (some (recognition, recognition)) ]

end TrafficSpecWitness.Concepts.interaction.overtakes
