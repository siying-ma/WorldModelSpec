/-
  Witnesses for NRS_484B_213_2b.

  Geometry (the witness's own figures; none appears in the rule):
  - highway 10: x ∈ [-300, 300] m, y ∈ [-8, 8] m, running east–west.
  - centre line 11: a thin strip y ∈ [-10, 10] cm along the whole highway, lying on highway 10.
  - intersection 20: x ∈ [0, 20] m across the highway, reference point (10, 0); in `idle` it is
    moved 200 m east (x ∈ [200, 220], reference point (210, 0)).
  - railway crossing 30: x ∈ [0, 10] m across the highway, reference point (5, 0).
  - one-way roadway 40 (branch_2 only, which has no centre line): the whole carriageway.
  - subject 1: a motor vehicle, half-extent 2.5 × 1 × 0.75 m, heading east at 2 m/s from
    x = -25 m (front bumper 22.5 m, then 20.5 m, then 18.5 m from x = 0: well inside 100 ft =
    30.48 m), at y = +3 m (left of the centre line, offset -2.9 m) or y = -3 m (right, +2.9 m).
    Three instants, one second apart.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_213_2b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_213_2b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def halfCar : Q × Q × Q := (cm 250, m 1, cm 75)

def highway : Structure := Build.rect 10 .highway (m (-300)) (m (-8)) (m 300) (m 8)
def centreLine : Structure :=
  { Build.rect 11 .centreLine (m (-300)) (cm (-10)) (m 300) (cm 10) with ways := some [10] }
def intersectionAt (x0 : Int) : Structure :=
  { Build.rect 20 .intersection (m x0) (m (-8)) (m (x0 + 20)) (m 8) with
      position := some (m (x0 + 10), m 0), ways := some [10] }
def crossing : Structure :=
  { Build.rect 30 .railwayCrossing (m 0) (m (-8)) (m 10) (m 8) with
      position := some (m 5, m 0), ways := some [10] }
def oneWay : Structure :=
  { Build.rect 40 .oneWayRoadway (m (-300)) (m (-8)) (m 300) (m 8) with ways := some [10] }

/-- The subject heading east at 2 m/s from x = -25 m, at lateral position y. -/
def approacher (k : Nat) (y : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (-25 + 2 * (Int.ofNat k)), m y) Build.east (Units.metresPerSecond 2) halfCar

/-- `forbid` (violated): The subject moves toward an st.intersection whose ground distance from its body is below the stated 100 feet, with its reference point left of the centre line of the highway it occupies. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ approacher k 3 ]
      [ highway, centreLine, intersectionAt 0 ]
      [ ]

/-- `permit` (compliant): The same approach with the subject right of the centre line. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ approacher k (-3) ]
      [ highway, centreLine, intersectionAt 0 ]
      [ ]

/-- `idle` (not_applicable): The subject is left of the centre line far from any intersection or railway crossing. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ approacher k 3 ]
      [ highway, centreLine, intersectionAt 200 ]
      [ ]

/-- `blind` (unknown): The subject moves toward an intersection with st.region_geometry not observed: its distance to the intersection and its offset from the centre line are unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ approacher k 3 ]
      [ highway, centreLine, intersectionAt 0 ]
      [ ]

/-- `branch_1` (violated): The subject's footprint overlaps an st.railway_crossing while its reference point is left of the centre line.
    The subject is already past the crossing's reference point (x = 6, 7, 8 m against 5 m), so
    it is not approaching it: only the traversal engages the duty. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (6 + Int.ofNat k), m 3) Build.east (Units.metresPerSecond 1) halfCar ]
      [ highway, centreLine, crossing ]
      [ ]

/-- `branch_2` (not_applicable): The subject approaches an intersection within the stated distance on an st.one_way_roadway. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ approacher k 3 ]
      [ highway, oneWay, intersectionAt 0 ]
      [ ]

/-- `branch_3` (violated): the subject approaches a railway crossing (no intersection in the
    scene) within the stated distance, left of the centre line. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ approacher k 3 ]
      [ highway, centreLine, crossing ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_213_2b"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_213_2b
