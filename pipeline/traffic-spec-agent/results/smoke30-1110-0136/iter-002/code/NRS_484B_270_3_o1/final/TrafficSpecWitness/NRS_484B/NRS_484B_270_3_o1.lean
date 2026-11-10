/-
  Witnesses for NRS_484B_270_3_o1.

  A north–south street: a travel lane L (region 1, x ∈ [-4, 0]), a bicycle lane b (region 2,
  x ∈ [0, 2]) east of it, and a sidewalk (region 3, x ∈ [2, 4]) beyond, all y ∈ [-50, 50].
  The car x (track 1, half-extents 2.3 × 0.9 × 0.75 m) turns right across b: its reference point
  stands in b at (1, 0), heading east. The other road user is track 2. Each trace repeats one
  scene at 0, 1 and 2 s; positions and velocities are the instant's, and every conflict below is
  computed from them under constant velocities against the run's horizon (3 s) and clearance
  (4 m), by a clear margin either way. Every figure here is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_3_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_3_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def travelLane : Structure := Build.rect 1 .lane (m (-4)) (m (-50)) (m 0) (m 50)
def bikeLane : Structure := Build.rect 2 .bicycleLaneOrPath (m 0) (m (-50)) (m 2) (m 50)
def sidewalk : Structure := Build.rect 3 .sidewalk (m 2) (m (-50)) (m 4) (m 50)
/-- A crosswalk across the street just south of x. -/
def crosswalk : Structure := Build.rect 4 .crosswalk (m (-4)) (m (-4)) (m 4) (m (-1))
/-- A sidewalk fixture blocking the sidewalk across its width, on the sidewalk. -/
def obstruction : Structure :=
  { Build.rect 5 .obstruction (m 2) (m (-8)) (m 4) (m (-3)) with
    obstructionKind := some .sidewalkFixture, ways := some [3] }

def street : List Structure := [travelLane, bikeLane, sidewalk]

def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 80)
def pedExtent : Q × Q × Q := (cm 25, cm 25, cm 85)

/-- x on b at (1, 0), heading east at `v`. -/
def carOnLane (v : Q) : RoadUser := Build.user 1 [.motorVehicle] (m 1, m 0) Build.east v carExtent

def still (users : List RoadUser) (structures : List Structure) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => Build.scene t (some 1) users structures []

/-- `forbid` (violated): x (passenger car) turns right across bicycle lane b and moves onto it while a bicycle y rides in b behind it at 6 m/s; predicted closest approach 1 m in 1.5 s. -/
-- x at 1 m/s east; bicycle 9 m south in b at 6 m/s north: closest approach ≈ 1.5 m after ≈ 1.46 s.
def forbidTrace : Trace :=
  still
    [ carOnLane (Units.metresPerSecond 1)
    , Build.user 2 [.bicycle] (m 1, m (-9)) Build.north (Units.metresPerSecond 6) bikeExtent ]
    street

/-- `permit` (compliant): x crosses b while bicycle y in b is 40 m away at 5 m/s and predicted to pass 15 m from x. -/
-- x at 2 m/s east; bicycle 40 m south at 5 m/s north: closest approach ≈ 14.9 m, ≈ 6.9 s ahead,
-- beyond the horizon.
def permitTrace : Trace :=
  still
    [ carOnLane (Units.metresPerSecond 2)
    , Build.user 2 [.bicycle] (m 1, m (-40)) Build.north (Units.metresPerSecond 5) bikeExtent ]
    street

/-- `idle` (not_applicable): x never occupies a bicycle lane or path. -/
-- x drives north in the travel lane at 10 m/s; a bicycle rides in b beside it.
def idleTrace : Trace :=
  still
    [ Build.user 1 [.motorVehicle] (m (-2), m 0) Build.north (Units.metresPerSecond 10) carExtent
    , Build.user 2 [.bicycle] (m 1, m (-9)) Build.north (Units.metresPerSecond 6) bikeExtent ]
    street

/-- `blind` (unknown): As forbid, but rel.occupies is not observed, so whether x and y are on b is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): x crosses b while a pedestrian who walked into b from a crosswalk (no sidewalk detour, NRS_484B_297_6_o2 not applying) is in predicted conflict: that pedestrian is not one the duty protects. -/
-- Pedestrian at (1, -2) on b and the crosswalk, walking north at 1 m/s; the sidewalk is clear.
-- Closest approach ≈ 1.4 m after 1 s.
def branch_1Trace : Trace :=
  still
    [ carOnLane (Units.metresPerSecond 1)
    , Build.user 2 [.pedestrian] (m 1, m (-2)) Build.north (Units.metresPerSecond 1) pedExtent ]
    (street ++ [crosswalk])

/-- `branch_2` (violated): x crosses b while a pedestrian detouring around a sidewalk obstruction walks in b, predicted closest approach 1 m in 1 s. -/
-- The pedestrian walks north on the sidewalk at 1 m/s (0–3 s, x = 3, y = -12 … -9), meets the
-- fixture blocking it (y ∈ [-8, -3]) and walks on in b hugging it (4–9 s, x = 1.9, y = -8 … -3):
-- its body, 0.5 m wide, then laps 0.15 m over the sidewalk edge and the fixture, which is stated.
-- x stands across b at (1, 0) throughout, moving east at 1 m/s. From 7 s the pedestrian, 5 m or
-- less behind x, is predicted to pass within ≈ 2.9 m (7 s) down to ≈ 1.5 m (9 s) of it, inside 3 s.
def onDetour (k : Nat) : Bool := k ≥ 4

def detourPosition (k : Nat) : Vec :=
  if onDetour k then (cm 190, m (-12 + (k : Int))) else (m 3, m (-12 + (k : Int)))

def detourOccupancy (k : Nat) : List (TrackId × RegionId) :=
  if onDetour k then [(1, 2), (2, 2), (2, 3), (2, 5)] else [(1, 2), (2, 3)]

def branch_2Trace : Trace :=
  Build.trace 10 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ carOnLane (Units.metresPerSecond 1)
      , Build.user 2 [.pedestrian] (detourPosition k) Build.north (Units.metresPerSecond 1) pedExtent ]
      (street ++ [obstruction]) [] (some (detourOccupancy k))

/-- `branch_3` (not_applicable): x crosses b with no other road user in the scene. -/
def branch_3Trace : Trace :=
  still [ carOnLane (Units.metresPerSecond 1) ] street

-- `branch_4` (violated): as forbid, the road user behind x in b an electric bicycle.
def branch_4Trace : Trace :=
  still
    [ carOnLane (Units.metresPerSecond 1)
    , Build.user 2 [.electricBicycle] (m 1, m (-9)) Build.north (Units.metresPerSecond 6) bikeExtent ]
    street

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_3_o1"
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
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.NRS_484B_270_3_o1
