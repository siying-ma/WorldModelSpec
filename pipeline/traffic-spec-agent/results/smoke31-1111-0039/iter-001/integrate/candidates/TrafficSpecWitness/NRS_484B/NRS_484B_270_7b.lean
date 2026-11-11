/-
  Witnesses for NRS_484B_270_7b.

  A straight eastbound carriageway, no structures built (the rule reads none). Three instants one
  second apart (k = 0, 1, 2).
  - The cycle x (track 1): half-extents 0.9 × 0.3 m, at (5k, 0) heading east at 5 m/s.
  - The car y (track 2): half-extents 2.3 × 0.9 m, heading east at 4 m/s, so x gains 1 m/s on it.
    Alongside, its centre is at (4k + 1, ·): the bodies' projections on x's heading overlap at every
    instant. Lateral offset 1.5 m (surface gap 0.3 m, below the 0.9 m clearance) in `forbid`;
    2.5 m (surface gap 1.3 m, above it) in `permit` and `branch_1`. `blind` keeps the `forbid`
    geometry, so that the unobserved overlap is what leaves the verdict open (with the clearance
    met the duty would be met whether or not x is overtaking); there the car's extent is not
    observed, so Core cannot compute the overlap or the gap from footprints, and the source supplies
    both as measured (overlap 1.8 m, gap 0.3 m across x's heading); the manifest then drops the
    measured overlap.
    In `idle` the car is 10 m ahead in x's line, (4k + 10, 0): the projections never overlap.
  - The oncoming car z (track 3, `branch_1` only): at (30 − 10k, −2) heading west at 10 m/s; at
    k = 0 the centres close at 15 m/s and reach their closest approach, 2 m apart, in 2 s — within
    the 4.1 s critical gap and below the 3 m conflict radius.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_7b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_7b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def cycleExtent : Q × Q × Q := (cm 90, cm 30, cm 60)
def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)

/-- The cycle x at instant k, of the given class. -/
def cycle (cls : RoadUserClass) (k : Nat) : RoadUser :=
  Build.user 1 [cls] (m (5 * (k : Int)), m 0) Build.east (Units.metresPerSecond 5) cycleExtent

/-- The car y alongside x at instant k, its centre `lat` centimetres to x's left. -/
def carAlongside (lat : Int) (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (4 * (k : Int) + 1), cm lat) Build.east (Units.metresPerSecond 4) carExtent

/-- `forbid` (violated): x (ru.bicycle) travels with rel.same_direction to a passenger car y (ru.motor_vehicle), rel.longitudinal_overlap positive and x's kin.speed above y's by more than p.overtaking_speed_margin, with rel.surface_gap between them below p.passing_lateral_clearance; no other road user is in the scene. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ cycle .bicycle k, carAlongside 150 k ]
      [ ]
      [ ]

/-- `permit` (compliant): The same overtaking alongside with rel.surface_gap above p.passing_lateral_clearance and no other road user in the scene: the duty binds x alone and is met. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ cycle .bicycle k, carAlongside 250 k ]
      [ ]
      [ ]

/-- `idle` (not_applicable): x (ru.bicycle) rides behind car y in the same lane with a negative rel.longitudinal_overlap and never draws alongside: no overtaking takes place. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ cycle .bicycle k
      , Build.user 2 [.motorVehicle] (m (4 * (k : Int) + 10), m 0) Build.east (Units.metresPerSecond 4) carExtent ]
      [ ]
      [ ]

/-- `blind` (unknown): x rides faster than car y in the same direction close beside it, but the source does not observe rel.longitudinal_overlap: whether x is overtaking alongside is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      { Build.scene t (some 1)
          [ cycle .bicycle k, Build.withKin (carAlongside 150 k) fun kn => { kn with extent := none } ]
          [ ]
          [ ]
        with occupancyObserved := [1] }   -- the car has no footprint, so its occupancy is not observed
      [ Build.relation 1 2 fun r =>
          { r with longitudinalOverlap := some (cm 180), surfaceGap := some (m 0, cm 30) } ]

/-- `branch_1` (violated): x (ru.electric_scooter) overtakes car y alongside with rel.surface_gap above p.passing_lateral_clearance, but an oncoming ru.motor_vehicle z satisfies prim.closest_approach_within with x over p.immediate_hazard_gap at a prim.closest_approach_distance below p.conflict_clearance.
    x is built as an electric bicycle: under the run's reading no class is included in
    DEF-NRS-484B-018::electric_scooter (ru.electric_scooter is unresolved), so a scooter's
    membership, and with it the verdict, would be unknown. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ cycle .electricBicycle k, carAlongside 250 k
      , Build.user 3 [.motorVehicle] (m (30 - 10 * (k : Int)), m (-2)) Build.west (Units.metresPerSecond 10) carExtent ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_7b"
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
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"]
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484B_270_7b
