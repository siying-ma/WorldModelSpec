/-
  Witnesses for NRS_484B_260.

  Geometry (the witness's own figures, nowhere in the rule):
  - highway h (10): x ∈ [-200, 200], y ∈ [-3, 13]; roadway r (11): y ∈ [0, 10], lying on h;
    lane L1 (12, eastbound): y ∈ [0, 5]; lane L2 (13, westbound): y ∈ [5, 10]; both lie on h.
  - driveway entrance e (14): x ∈ [-3, 3], y ∈ [-8, 0], south of the roadway.
  - branch_2 only: an alley (15) x ∈ [-3, 3], y ∈ [-30, -1], and the entrance e is y ∈ [-1, 0]; the
    subject's body overlaps the alley at every instant.
  - subject (track 1, motor vehicle, half-length 2.5 m, half-width 1 m) heads north at 2 m/s from
    (0, -3) (on e only) to (0, -1) and (0, 1) (straddling e and r): instants 0, 1, 2 s.
  - v (track 2, motor vehicle) heads east in L1 at y = 2.5 m, 10 m/s.
    forbid/blind: x = -30, -20, -10: closest approach ≈ 2 s / 1 s ahead at ≈ 0.5 m (< 3 m, < 3 s).
    permit: x = -120, -110, -100: closest approach ≈ 10 s ahead (beyond 3 s).
  Occupancy is stated: a body straddles two regions.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_260
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_260

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def hId : RegionId := 10
def rId : RegionId := 11
def l1Id : RegionId := 12
def l2Id : RegionId := 13
def eId : RegionId := 14
def alleyId : RegionId := 15

def body : Q × Q × Q := (cm 250, m 1, cm 75)

def highway : Structure := Build.rect hId .highway (m (-200)) (m (-3)) (m 200) (m 13)
def roadway : Structure := { Build.rect rId .roadway (m (-200)) (m 0) (m 200) (m 10) with ways := some [hId] }
def lane1 : Structure :=
  { Build.lane l1Id [(m (-200), m 0), (m 200, m 0), (m 200, m 5), (m (-200), m 5)] Build.east with ways := some [hId] }
def lane2 : Structure :=
  { Build.lane l2Id [(m (-200), m 5), (m 200, m 5), (m 200, m 10), (m (-200), m 10)] Build.west with ways := some [hId] }
def entrance : Structure := Build.rect eId .drivewayOrAlleyEntrance (m (-3)) (m (-8)) (m 3) (m 0)

def way : List Structure := [highway, roadway, lane1, lane2, entrance]

/-- The subject rolling north out of the entrance: (0, -3), (0, -1), (0, 1). -/
def subjectAt (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m (-3 + 2 * (k : Int))) Build.north (Units.metresPerSecond 2) body

/-- Its occupancy: the entrance only at 0, then the entrance and the roadway (and L1). -/
def subjectOcc (k : Nat) : List (TrackId × RegionId) :=
  if k == 0 then [(1, eId), (1, hId)] else [(1, eId), (1, rId), (1, l1Id), (1, hId)]

/-- v heading east in L1 at 10 m/s from x = x0. -/
def vAt (x0 : Int) (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (x0 + 10 * (k : Int)), cm 250) Build.east (Units.metresPerSecond 10) body

def vOcc : List (TrackId × RegionId) := [(2, rId), (2, l1Id), (2, hId)]

/-- `forbid` (violated): The subject vehicle rolls out of a driveway entrance region onto roadway r of highway h, kin.speed above p.halt_speed_tolerance, overlapping no alley. Vehicle v moves in a lane on h with the subject ahead of it (rel.bearing longitudinal positive); prim.closest_approach_within holds over p.conflict_horizon and prim.closest_approach_distance is below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt k, vAt (-30) k] way []
      (occupies := some (subjectOcc k ++ vOcc))

/-- `permit` (compliant): As forbid, but v is far up the lane: their closest approach does not fall within p.conflict_horizon, and no contact occurs. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt k, vAt (-120) k] way []
      (occupies := some (subjectOcc k ++ vOcc))

/-- `idle` (not_applicable): The subject drives along roadway r of h and its footprint never overlaps a driveway_or_alley_entrance region; v approaches from behind. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 + 10 * (k : Int)), cm 250) Build.east (Units.metresPerSecond 10) body
      , vAt (-30) k ]
      way []
      (occupies := some [(1, rId), (1, l1Id), (1, hId), (2, rId), (2, l1Id), (2, hId)])

/-- `blind` (unknown): As forbid, but rel.bearing is not observed on the source, so whether v approaches the subject is unknown while the closest approach is a conflict. -/
def blindTrace : Trace :=
  -- NOT REALISABLE as planned (see task_result.md): masking rel.bearing drops only a measured
  -- bearing; Core then computes it from v's position and heading and the subject's position, which
  -- the adapter requires of every occupancy-observed track. This is the forbid scene, admissible,
  -- on which the masked bearing stays decided.
  forbidTrace

/-- `branch_1` (compliant): The subject rolls out of a driveway entrance onto roadway r of h and no other road user is in the scene: the duty binds the subject alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt k] way []
      (occupies := some (subjectOcc k))

def alley : Structure := Build.rect alleyId .alley (m (-3)) (m (-30)) (m 3) (m (-1))
def alleyEntrance : Structure := Build.rect eId .drivewayOrAlleyEntrance (m (-3)) (m (-1)) (m 3) (m 0)

/-- `branch_2` (not_applicable): The subject comes out of an alley: its footprint overlaps an st.alley region and the entrance region as it reaches roadway r, with v in conflict as in forbid. An alley is a highway, not a private way. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt k, vAt (-30) k]
      [highway, roadway, lane1, lane2, alleyEntrance, alley] []
      (occupies := some
        ((if k == 0 then [(1, alleyId), (1, eId)]
          else [(1, alleyId), (1, eId), (1, rId), (1, l1Id), (1, hId)]) ++ vOcc))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_260"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_260
