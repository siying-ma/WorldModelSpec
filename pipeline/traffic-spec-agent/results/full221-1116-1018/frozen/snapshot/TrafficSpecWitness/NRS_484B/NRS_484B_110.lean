/-
  Witnesses for NRS_484B_110.

  Geometry: a safety zone `10` is the rectangle x ∈ [21, 29], y ∈ [-2, 2] (m). The subject
  (track 1, a motor vehicle, half-extent 2.25 × 0.9 × 0.75 m) heads east.
  - forbid: at 8 m/s along y = 0, sampled every 0.5 s from x = 10 (x = 10, 14, …, 34): its
    reference point lies inside the zone at x = 22 and x = 26, so it occupies the zone there.
  - permit: at 8 m/s along y = 8, six metres clear of the zone's north edge: never occupies it.
  - idle: at rest (0 m/s, well under the 0.1 m/s tolerance) at the curb, y = 8, x = 25.
  - blind: as permit, with `rel.occupies` absent from the manifest.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_110
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_110

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

def zone : Structure := Build.rect 10 .safetyZone (m 21) (m (-2)) (m 29) (m 2)

/-- The car at `x` along the line `y`, heading east at `v`. -/
def car (x y : Int) (v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) Build.east v carExtent

/-- `forbid` (violated): A car moving at 8 m/s crosses a marked safety zone: its footprint overlaps the zone at several observations. -/
def forbidTrace : Trace :=
  Build.trace 7 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ car (10 + 4 * (k : Int)) 0 (Units.metresPerSecond 8) ]
      [ zone ]
      [ ]

/-- `permit` (compliant): A car moving at 8 m/s passes beside the safety zone, its footprint never overlapping it. -/
def permitTrace : Trace :=
  Build.trace 7 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ car (10 + 4 * (k : Int)) 8 (Units.metresPerSecond 8) ]
      [ zone ]
      [ ]

/-- `idle` (not_applicable): A car stays at rest at the curb for the whole recording. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 25 8 (Units.metresPerSecond 0) ]
      [ zone ]
      [ ]

/-- `blind` (unknown): A car moves past a safety zone; the source does not report which regions the car's footprint overlaps. -/
def blindTrace : Trace :=
  Build.trace 7 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ car (10 + 4 * (k : Int)) 8 (Units.metresPerSecond 8) ]
      [ zone ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_110"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] ]

end TrafficSpecWitness.NRS_484B_110
