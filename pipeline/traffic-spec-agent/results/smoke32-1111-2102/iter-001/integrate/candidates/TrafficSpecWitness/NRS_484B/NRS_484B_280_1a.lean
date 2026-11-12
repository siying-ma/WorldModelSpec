/-
  Witnesses for NRS_484B_280_1a.

  The carriageway: a roadway from y = -4 m to y = 4 m along x, with a sidewalk from y = 6 m to
  y = 10 m. Instants every 1 s from t = 0.

  ego (track 1) drives east along y = 0 at 10 m/s (a passenger car, half-extent 2.25 × 0.9 m);
  the pedestrian (track 2) has a 0.3 m body radius.

  forbid  — the pedestrian crosses north at 1.5 m/s from (20, -3); under constant velocities the
            centres meet at t* = 2 s with a centre distance of 0 m (below 2.5 m by the whole bound,
            within the 3 s horizon); ego never slows (10 m/s against the 0.1 m/s rest tolerance).
  permit  — the pedestrian walks east at 1.5 m/s on the sidewalk at y = 8: the closest centre
            distance is 8 m, over three times the clearance; the bodies never touch.
  idle    — ego is a bicycle at 5 m/s passing 2 m from a standing pedestrian: no motor vehicle.
  blind   — the permit trace with rel.contact unobserved: the source supplies no contact and no
            body extent of the pedestrian, so contact cannot be computed from the footprints
            either (masking blanks a computed relation only where its kinematics are lacking);
            with no footprint, the pedestrian's occupancy is not observed (ego's alone is).
  branch_1 — ego alone on the roadway.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_280_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_280_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: ego ↦ 1

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 90)

def roadway : Structure := Build.rect 100 .roadway (m (-50)) (m (-4)) (m 150) (m 4)
def sidewalk : Structure := Build.rect 101 .sidewalk (m (-50)) (m 6) (m 150) (m 10)
def structures : List Structure := [roadway, sidewalk]

/-- ego, a passenger car, at 10 m/s east along y = 0, at instant k. -/
def egoCar (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 0) Build.east (Units.metresPerSecond 10) carExtent

/-- `forbid` (violated): ego, a passenger car (ru.motor_vehicle), drives along a roadway toward a pedestrian crossing in front of it; the centres are projected to approach within the horizon to a distance below the pedestrian clearance, and ego keeps moving. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ egoCar k
      , Build.user 2 [.pedestrian] (m 20, cm (-300 + 150 * (k : Int))) Build.north (Units.ratio 3 2) pedExtent ]
      structures
      [ ]

/-- `permit` (compliant): ego drives past a pedestrian walking on the sidewalk well clear of the roadway; no projected approach falls below the clearance within the horizon and there is no contact. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ egoCar k
      , Build.user 2 [.pedestrian] (cm (1000 + 150 * (k : Int)), m 8) Build.east (Units.ratio 3 2) pedExtent ]
      structures
      [ ]

/-- `idle` (not_applicable): ego is a bicycle (ru.bicycle), which the motor vehicle aggregate does not include; it rides close past a pedestrian. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (5 * (k : Int)), m 0) Build.east (Units.metresPerSecond 5) bikeExtent
      , Build.user 2 [.pedestrian] (m 6, m 2) Build.north Q.zero pedExtent ]
      structures
      [ ]

/-- `blind` (unknown): as in permit, the projected approach stays above the clearance, but the source does not observe contact between bodies, so whether ego touches the pedestrian it passes is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    { Build.scene t (some 1)
        [ egoCar k
        , Build.withKin
            (Build.user 2 [.pedestrian] (cm (1000 + 150 * (k : Int)), m 8) Build.east (Units.ratio 3 2) pedExtent)
            fun kin => { kin with extent := none } ]
        structures
        [ ]
      with occupancyObserved := [1] }

/-- `branch_1` (compliant): ego drives along an empty road with no pedestrian anywhere in the scene: the duty binds ego alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ egoCar k ]
      structures
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_280_1a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.contact"]
  , witness "branch_1" branch_1Trace .compliant ]

end TrafficSpecWitness.NRS_484B_280_1a
