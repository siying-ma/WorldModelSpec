/-
  Witnesses for LVMC_11_38_030.

  Geometry (all figures the witness's own): an east-west roadway y ∈ [0, 7] m, x ∈ [0, 100] m,
  with one eastbound lane y ∈ [0, 3.5] m; a sidewalk y ∈ [7, 10] m along its north edge. Every
  scene is inside declared city limits (asm.within_city_limits = true). Three instants 1 s apart.
  A moving machine runs at 2 m/s (walking pace, ten times the 0.2 m/s resolution) on the sidewalk
  or at 10 m/s in the lane; a parked one has speed zero. A two-wheeler's half extents are
  1.1 m × 0.4 m × 0.7 m, so a body centred at y = 8.5 lies wholly on the sidewalk and one centred
  at y = 1.75 wholly in the lane.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_38_030
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_38_030

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def twoWheeler : Q × Q × Q := (cm 110, cm 40, cm 70)

def roadway : Structure := Build.rect 10 .roadway (m 0) (m 0) (m 100) (m 7)
def eastLane : Structure :=
  Build.lane 11 [(m 0, m 0), (m 100, m 0), (m 100, cm 350), (m 0, cm 350)] Build.east
def sidewalk : Structure := Build.rect 12 .sidewalk (m 0) (m 7) (m 100) (m 10)

def structures : List Structure := [roadway, eastLane, sidewalk]

def inCity : List (AsmId × Bool) := [("asm.within_city_limits", true)]

/-- `forbid` (violated): Inside declared city limits, a motorcycle travels along a sidewalk at walking pace; its footprint overlaps the sidewalk region and its speed is well above the resolution. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorcycle] (m (10 + 2 * k), cm 850) Build.east (Units.metresPerSecond 2) twoWheeler ]
      structures
      [ ]
      (assumptions := inCity)

/-- `permit` (compliant): Inside declared city limits, a motorcycle travels in a lane of the roadway, overlapping no sidewalk. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorcycle] (m (10 + 10 * k), cm 175) Build.east (Units.metresPerSecond 10) twoWheeler ]
      structures
      [ ]
      (assumptions := inCity)

/-- `idle` (not_applicable): A bicycle is ridden along a sidewalk inside declared city limits; it is neither in the motorcycle aggregate nor a moped nor an electric scooter. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (10 + 2 * k), cm 850) Build.east (Units.metresPerSecond 2) (cm 90, cm 30, cm 60) ]
      structures
      [ ]
      (assumptions := inCity)

/-- `blind` (unknown): Inside declared city limits, a moped moves near the curb; the source declares rel.occupies absent, so whether it is on the sidewalk is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.moped] (m (10 + 2 * k), cm 700) Build.east (Units.metresPerSecond 2) twoWheeler ]
      structures
      [ ]
      (assumptions := inCity)

/-- `branch_1` (compliant): Inside declared city limits, a motorcycle stands parked on a sidewalk with zero speed: it is not ridden there. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorcycle] (m 20, cm 850) Build.east Q.zero twoWheeler ]
      structures
      [ ]
      (assumptions := inCity)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_38_030"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant ]

end TrafficSpecWitness.LVMC_11_38_030
