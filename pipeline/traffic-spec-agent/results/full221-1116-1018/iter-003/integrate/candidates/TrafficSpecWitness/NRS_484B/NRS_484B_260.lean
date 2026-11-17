/-
  Witnesses for NRS_484B_260.

  Geometry (metres, +x east, +y north), three observations 1 s apart (t = 0, 1000, 2000 ms):
  - highway h (10): x ∈ [-200, 200], y ∈ [-2, 10];
  - roadway r (11): x ∈ [-200, 200], y ∈ [0, 8], lying on h;
  - lane L (12): x ∈ [-200, 200], y ∈ [0, 4], eastbound, lying on h;
  - driveway entrance e (13): x ∈ [-3, 3], y ∈ [-10, 0], south of the roadway;
  - alley a (14, branch_2 only): x ∈ [-3, 3], y ∈ [-30, -2].
  The subject (1), half-extent 2 × 1 m, heads north at 2 m/s from (0, -5): at t = 0 and 1 s its body
  (y ≤ -1) lies on e only, at t = 2 s, centre (0, -1), it straddles e and r (stated occupancy).
  Vehicle v (2), half-extent 2 × 1 m, heads east at 10 m/s along the centre of L (y = 2).
  forbid: v at x = -20 at t = 2 s: closest approach of the centres after ≈1.98 s at ≈0.98 m.
  permit: v at x = -100 at t = 2 s: closest approach after ≈9.7 s, beyond the horizon.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_260
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_260

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def hwy : Structure := Build.rect 10 .highway (m (-200)) (m (-2)) (m 200) (m 10)
def road : Structure := { Build.rect 11 .roadway (m (-200)) (m 0) (m 200) (m 8) with ways := some [10] }
def laneL : Structure :=
  { Build.lane 12 [(m (-200), m 0), (m 200, m 0), (m 200, m 4), (m (-200), m 4)] Build.east
      with ways := some [10] }
def entrance : Structure := Build.rect 13 .drivewayOrAlleyEntrance (m (-3)) (m (-10)) (m 3) (m 0)
def alley : Structure := Build.rect 14 .alley (m (-3)) (m (-30)) (m 3) (m (-2))

def structs : List Structure := [hwy, road, laneL, entrance]

def half : Q × Q × Q := (m 2, m 1, m 1)

/-- The subject rolling north out of the entrance. -/
def subjectAt (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m (-5 + 2 * (k : Int))) Build.north (Units.metresPerSecond 2) half

/-- The subject's occupancy: the entrance throughout, the roadway (and highway) at the last instant. -/
def subjectOcc (k : Nat) : List (TrackId × RegionId) :=
  if k == 2 then [(1, 13), (1, 11), (1, 10)] else [(1, 13)]

/-- Vehicle v eastbound along lane L, at x = x2 at the last instant. -/
def vAt (x2 : Int) (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (x2 - 20 + 10 * (k : Int)), m 2) Build.east (Units.metresPerSecond 10) half

def vOcc : List (TrackId × RegionId) := [(2, 10), (2, 11), (2, 12)]

/-- `forbid` (violated): The subject vehicle rolls out of a driveway entrance region onto roadway r of highway h, kin.speed above p.halt_speed_tolerance, overlapping no alley. Vehicle v moves in a lane on h with the subject ahead of it (rel.bearing longitudinal positive); prim.closest_approach_within holds over p.conflict_horizon and prim.closest_approach_distance is below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, vAt (-20) k ]
      structs
      [ ]
      (occupies := some (subjectOcc k ++ vOcc))

/-- `permit` (compliant): As forbid, but v is far up the lane: their closest approach does not fall within p.conflict_horizon, and no contact occurs. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, vAt (-100) k ]
      structs
      [ ]
      (occupies := some (subjectOcc k ++ vOcc))

/-- `idle` (not_applicable): The subject drives along roadway r of h and its footprint never overlaps a driveway_or_alley_entrance region; v approaches from behind. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 6) Build.east (Units.metresPerSecond 10) half
      , Build.user 2 [.motorVehicle] (m (-30 + 10 * (k : Int)), m 6) Build.east (Units.metresPerSecond 10) half ]
      structs
      [ ]
      (occupies := some [(1, 10), (1, 11), (2, 10), (2, 11)])

/-- `blind` (unknown): As forbid, but st.on_way is not observed on the source: which highway the roadway r and v's lane lie on is unknown, so whether the subject is entering such a highway and whether v approaches on that same highway are unknown, while the subject straddles the entrance and the roadway and the closest approach is a conflict. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): The subject rolls out of a driveway entrance onto roadway r of h and no other road user is in the scene: the duty binds the subject alone and is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k ]
      structs
      [ ]
      (occupies := some (subjectOcc k))

/-- `branch_2` (not_applicable): The subject comes out of an alley: its footprint overlaps an st.alley region and the entrance region as it reaches roadway r, with v in conflict as in forbid. An alley is a highway, not a private way. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, vAt (-20) k ]
      (structs ++ [alley])
      [ ]
      (occupies := some ((1, 14) :: subjectOcc k ++ vOcc))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_260"
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
  , witness "blind" blindTrace (.unknown []) ["st.on_way"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_260
