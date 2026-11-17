/-
  Witnesses for LVMC_11_38_030.

  Geometry: a roadway rectangle x ∈ [0, 100], y ∈ [0, 7] and a sidewalk rectangle beside it,
  x ∈ [0, 100], y ∈ [7, 11]. The subject (track 1) is a two-wheeler with half-extents
  1.0 × 0.4 × 0.7 m heading east. On the sidewalk its centre runs along y = 9 m (2 m from either
  edge of the sidewalk, so its footprint lies wholly on it); on the roadway along y = 3 m. Three
  instants, one second apart. Moving speeds are 3 m/s (motorcycle) and 2 m/s (moped), far above
  the reading's halt tolerance (0.1 m/s); the permit machine has speed zero. Every figure here is
  the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_38_030
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_38_030

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def roadway : Structure := Build.rect 10 .roadway (m 0) (m 0) (m 100) (m 7)
def sidewalk : Structure := Build.rect 11 .sidewalk (m 0) (m 7) (m 100) (m 11)
def structures : List Structure := [roadway, sidewalk]

def halfExt : Q × Q × Q := (cm 100, cm 40, cm 70)

def withinCity (b : Bool) : List (AsmId × Bool) := [("asm.within_city_limits", b)]

/-- A machine of the given classes at `x` on the line `y`, moving east at `v` m/s. -/
def rider (cls : List RoadUserClass) (x y v : Int) : RoadUser :=
  Build.user 1 cls (m x, m y) Build.east (Units.metresPerSecond v) halfExt

/-- `forbid` (violated): A motorcycle (ru.motorcycle) moves at 3 m/s with its footprint on a st.sidewalk, at a place declared asm.within_city_limits true. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider [.motorcycle] (20 + 3 * k) 9 3 ]
      structures
      []
      (assumptions := withinCity true)

/-- `permit` (compliant): A motorcycle stands at rest (kin.speed at or below p.halt_speed_tolerance) on a sidewalk within the city. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ rider [.motorcycle] 20 9 0 ]
      structures
      []
      (assumptions := withinCity true)

/-- `idle` (not_applicable): A motorcycle moves on the roadway and occupies no sidewalk. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider [.motorcycle] (20 + 3 * k) 3 3 ]
      structures
      []
      (assumptions := withinCity true)

/-- `blind` (unknown): A motorcycle is on a sidewalk within the city; the source does not observe kin.speed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (rider [.motorcycle] (20 + 3 * k) 9 3) fun kn => { kn with speed := none } ]
      structures
      []
      (assumptions := withinCity true)

/-- `branch_1` (violated): A moped (ru.moped) moves at 2 m/s on a sidewalk within the city. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider [.moped] (20 + 2 * k) 9 2 ]
      structures
      []
      (assumptions := withinCity true)

/-- `branch_2` (not_applicable): A motorcycle moves on a sidewalk at a place declared asm.within_city_limits false. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider [.motorcycle] (20 + 3 * k) 9 3 ]
      structures
      []
      (assumptions := withinCity false)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_38_030"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_38_030
