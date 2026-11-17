/-
  Witnesses for LVMC_11_20_060_o3.

  Geometry (the witness's own figures, nowhere in the rule): an east–west roadway (region 10)
  x ∈ [-60, 60], y ∈ [0, 10] (in `branch_5` split into two roadways of a divided highway, 10 at
  y ∈ [0, 5] and 11 at y ∈ [5, 10]); a driveway-or-alley-entrance (region 20, or an alley in
  `branch_3`) x ∈ [-3, 3], y ∈ [-10, 0] meeting it from the south. The subject (track 1), a car of
  half-length 2.4 m and half-width 1 m, heads north out of region 20; its body straddles the edge
  at y = 0 from its second scene on, so occupancy is stated (the reference point lies in one
  polygon only). The other road user (track 2) drives east along y = 3 at 10 m/s. Scenes 1 s apart.
  Reading: horizon 3 s, centre clearance 3 m, speed resolution 0.1 m/s.

  forbid at t = 1 s: subject (0,-1) at 2 m/s north, car (-12,3): closest approach at ≈1.23 s,
  ≈1.57 m apart — inside both bounds by a clear margin, while the subject moves.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_20_060_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_20_060_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def district : List (AsmId × Bool) := [("asm.business_or_residence_district", true)]

def carExt : Q × Q × Q := (cm 240, m 1, cm 80)

def roadway : Structure := Build.rect 10 .roadway (m (-60)) (m 0) (m 60) (m 10)
def roadwayNear : Structure := Build.rect 10 .roadway (m (-60)) (m 0) (m 60) (m 5)
def roadwayFar : Structure := Build.rect 11 .roadway (m (-60)) (m 5) (m 60) (m 10)
def driveway : Structure := Build.rect 20 .drivewayOrAlleyEntrance (m (-3)) (m (-10)) (m 3) (m 0)
def alley : Structure := Build.rect 20 .alley (m (-3)) (m (-10)) (m 3) (m 0)

def subj (y : Int) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m y) heading speed carExt

/-- The other road user on y = 3, driving east at 10 m/s, at `x` metres. -/
def car (x : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (m x, m 3) Build.east (Units.metresPerSecond 10) carExt

def mk (t : Timestamp) (users : List RoadUser) (structures : List Structure)
    (occ : List (TrackId × RegionId)) : Scene :=
  Build.scene t (some 1) users structures [] (occupies := some occ) (assumptions := district)

/-- The subject's emergence: driveway only at k = 0, straddling the roadway edge after. -/
def emergeY (k : Nat) : Int := if k == 0 then -3 else if k == 1 then -1 else 1

def emergeOcc (k : Nat) : List (TrackId × RegionId) :=
  if k == 0 then [(1, 20)] else [(1, 10), (1, 20)]

/-- `forbid` (violated): District assumed; the subject pulls out of a driveway into the roadway in front of a car approaching on it; the closest approach falls below the clearance within the horizon while the subject keeps moving. -/
def forbidTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    mk t
      [ subj (emergeY k) Build.north (Units.metresPerSecond 2)
      , car (10 * (k : Int) - 22) ]
      [ roadway, driveway ]
      (emergeOcc k ++ [(2, 10)])

/-- `permit` (compliant): Same, but the subject waits at the roadway edge, halted, until the car has passed. -/
def permitTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    let y : Int := if k == 0 then -3 else if k ≤ 4 then -1 else 1
    let v : Q := if k == 0 || k == 5 then Units.metresPerSecond 2 else Q.zero
    mk t
      [ subj y Build.north v
      , car (10 * (k : Int) - 22) ]
      [ roadway, driveway ]
      (emergeOcc k ++ [(2, 10)])

/-- `idle` (not_applicable): The subject turns from the roadway into a driveway (it occupied the roadway before the driveway): it is not emerging. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let y : Int := if k == 0 then 5 else if k == 1 then 1 else -3
    let occ : List (TrackId × RegionId) :=
      if k == 0 then [(1, 10)] else if k == 1 then [(1, 10), (1, 20)] else [(1, 20)]
    mk t
      [ subj y Build.south (Units.metresPerSecond 2)
      , car (10 * (k : Int) - 22) ]
      [ roadway, driveway ]
      (occ ++ [(2, 10)])

/-- `blind` (unknown): District assumed; the subject emerges in front of an approaching car, but the source does not supply roadway occupancy. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): District assumed; the subject emerges onto the roadway with no other road user in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mk t
      [ subj (emergeY k) Build.north (Units.metresPerSecond 2) ]
      [ roadway, driveway ]
      (emergeOcc k)

/-- `branch_2` (violated): the subject creeps out and halts touching the side of a car standing
    on the roadway; no closest approach is pending, the contact alone breaks the duty. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let v : Q := if k == 2 then Q.zero else Units.metresPerSecond 2
    mk t
      [ subj (emergeY k) Build.north v
      , Build.user 2 [.motorVehicle] (cm 340, m 3) Build.east Q.zero (cm 250, m 1, cm 80) ]
      [ roadway, driveway ]
      (emergeOcc k ++ [(2, 10)])

/-- `branch_3` (violated): as `forbid`, but the subject emerges from an alley. -/
def branch_3Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    mk t
      [ subj (emergeY k) Build.north (Units.metresPerSecond 2)
      , car (10 * (k : Int) - 22) ]
      [ roadway, alley ]
      (emergeOcc k ++ [(2, 10)])

/-- `branch_4` (compliant): as `forbid`, but the road user crossing the subject's path on the
    roadway is a pedestrian, not a vehicle (the pedestrian duty is a sibling node's). -/
def branch_4Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    mk t
      [ subj (emergeY k) Build.north (Units.metresPerSecond 2)
      , Build.user 2 [.pedestrian] (m (10 * (k : Int) - 22), m 3) Build.east
          (Units.metresPerSecond 10) (cm 30, cm 30, m 1) ]
      [ roadway, driveway ]
      (emergeOcc k ++ [(2, 10)])

/-- `branch_5` (compliant): the subject emerges onto the near roadway of a divided highway at
    4 m/s; a car on the far roadway would pass within the clearance, but it is not on said roadway. -/
def branch_5Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    let y : Int := if k == 0 then -5 else -1
    mk t
      [ subj y Build.north (Units.metresPerSecond 4)
      , Build.user 2 [.motorVehicle] (m (10 * (k : Int) - 22), m 6) Build.east
          (Units.metresPerSecond 10) carExt ]
      [ roadwayNear, roadwayFar, driveway ]
      (emergeOcc k ++ [(2, 11)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_20_060_o3"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.LVMC_11_20_060_o3
