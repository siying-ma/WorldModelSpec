/-
  Witnesses for drv.interaction.passing_on_right.

  Two cars on a straight eastbound road, no regions: b (track 2) drives along y = 0, a (track 1)
  along y = −4, so b is 4 m to a's left. Both are 5 m long and 2 m wide (half-extents 2.5 m, 1 m),
  both head east. Three instants one second apart (t = 0, 1, 2 s).
  - holds: b at 10 m/s, x = 10·k; a at 12 m/s, x = −2 + 12·k: a is 2 m behind, level, then 2 m ahead,
    so the projections on the east axis share 3 m, 5 m, 3 m; a gains on b by 2 m/s.
  - fails: b at 10 m/s, x = 10·k; a at 8 m/s, x = 2 + 8·k: side by side the same way, a slower.
  - blind: the holds trace, with rel.longitudinal_overlap not observed; as Core computes the overlap
    from the two footprints, the source of this trace reports no body extents (and so no occupancy)
    either.
  Instance: cos_tol = 98/100 (headings within about 11°), speed_tol = 0.5 m/s.
-/
import TrafficSpec.Concepts.interaction.passing_on_right
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.passing_on_right

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the cosine tolerance of a heading difference of about
    11°, and a speed resolution of half a metre per second. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.passing_on_right@w"
    concept := "drv.interaction.passing_on_right"
    literals := []
    nats := []
    params := [("cos_tol", .lit (Units.ratio 98 100) .ratio),
               ("speed_tol", .lit (Units.micrometresPerSecond 500000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A car's half-extents: 5 m long, 2 m wide, 1.5 m high. -/
def carHalf : Q × Q × Q := (cm 250, m 1, cm 75)

/-- Two eastbound cars, b on y = 0 and a on y = −4, at the given x positions and speeds. -/
def pair (t : Timestamp) (xa : Int) (va : Int) (xb : Int) (vb : Int) : Scene :=
  Build.scene t (some 1)
    [ Build.user 1 [.motorVehicle] (m xa, m (-4)) Build.east (Units.metresPerSecond va) carHalf
    , Build.user 2 [.motorVehicle] (m xb, m 0) Build.east (Units.metresPerSecond vb) carHalf ]
    []
    []

/-- `holds` (compliant): Car a, on the right of car b and side by side with it, both heading the same way, moves faster than b. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    pair t (-2 + 12 * (k : Int)) 12 (10 * (k : Int)) 10

/-- `fails` (violated): Car a is side by side with b on b's right but slower than b. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    pair t (2 + 8 * (k : Int)) 8 (10 * (k : Int)) 10

/-- `blind` (unknown): As holds, with rel.longitudinal_overlap declared absent. Core computes the
    overlap from the footprints when no measured value is given, so the source here also reports no
    body extents, and hence no occupancy (nothing else the body reads uses either): the overlap is
    then unobserved. -/
def blindTrace : Trace :=
  holdsTrace.map fun s =>
    { s with users := s.users.map fun u => Build.withKin u fun k => { k with extent := none }
             occupancyObserved := []
             occupies := [] }

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

end TrafficSpecWitness.Concepts.interaction.passing_on_right
