/-
  Witnesses for NRS_484B_113_2.

  Every trace samples every 50 ms (the step a heading change is integrated across). The subject is
  track 1, a motor vehicle with half-extents 2.5 m × 1 m × 0.75 m; backing is 2 m/s against its
  heading (0.1 m per step). Occupancy is stated per scene from the footprint (a body touching or
  overlapping a region's polygon), not from the reference point alone.

  - forbid: intersection 10 is x ∈ [−20, 0], y ∈ [−10, 10]; the car heads east and backs west from
    x = 2.75 m; its rear reaches the intersection at step 3 (x = 2.45 m).
  - permit: the same intersection and a crosswalk 11 at x ∈ [−23, −21]; the car backs at x ≈ 60 m.
  - idle: the car heads west at 10 m/s with its body over crosswalk 11 (x ∈ [0, 3]) and the
    intersection; it never backs.
  - blind: the forbid scene with the velocity masked; the window ends at the entry step.
  - branch_1: a marked mid-block crosswalk 11 (x ∈ [−2, 2]); the car backs over it, no intersection.
  - branch_2: the car, heading west, stands with its front in the intersection (x = 1.5 m), then
    backs east and straight out; its body leaves the intersection after step 10; yaw rate zero.
  - branch_3: intersection 10 is x, y ∈ [−20, 20]; the car stands at its centre, then backs with a
    yaw rate of 100 °/s for 16 steps (80°), its heading turning from east toward north, 5° per step (the rate at a scene held over the
    interval before it), and each step moving it 0.1 m against its heading.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_113_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_113_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def step : Q := Units.milliseconds 50
def ext : Q × Q × Q := (cm 250, m 1, cm 75)

/-- The subject at `pos` heading `h`, moving at signed speed `v` along `h` (negative: backing),
    with yaw rate `yaw` (deg/s). -/
def car (pos : Vec) (h : Vec) (v : Q) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos h v ext) fun k =>
    { k with speed := some (Q.abs v), yawRate := some yaw }

def backV : Q := Units.metresPerSecond (-2)
def zeroV : Q := Units.metresPerSecond 0
def noYaw : Q := Units.degrees 0

def intersectionA : Structure := Build.rect 10 .intersection (m (-20)) (m (-10)) (m 0) (m 10)

/-- `forbid` (violated): A car backs at 2 m/s along a street and its footprint comes to overlap the intersection while backing. -/
def forbidTrace : Trace :=
  Build.trace 6 0 step fun k t =>
    Build.scene t (some 1)
      [ car (cm (275 - 10 * k), m 0) Build.east backV noYaw ]
      [ intersectionA ]
      [ ]
      (occupies := some (if k ≥ 3 then [(1, 10)] else []))

/-- `permit` (compliant): A car backs at 2 m/s mid-block, away from any intersection or crosswalk. -/
def permitTrace : Trace :=
  Build.trace 6 0 step fun k t =>
    Build.scene t (some 1)
      [ car (cm (6000 - 10 * k), m 0) Build.east backV noYaw ]
      [ intersectionA, Build.rect 11 .crosswalk (m (-23)) (m (-10)) (m (-21)) (m 10) ]
      [ ]
      (occupies := some [])

/-- `idle` (not_applicable): A car drives forward through an intersection and over its crosswalks without ever backing. -/
def idleTrace : Trace :=
  Build.trace 6 0 step fun k t =>
    Build.scene t (some 1)
      [ car (cm (200 - 50 * k), m 0) Build.west (Units.metresPerSecond 10) noYaw ]
      [ intersectionA, { Build.rect 11 .crosswalk (m 0) (m (-10)) (m 3) (m 10) with marked := some true } ]
      [ ]
      (occupies := some [(1, 10), (1, 11)])

/-- `blind` (unknown): A car's footprint comes to overlap an intersection while the source supplies no velocity, so whether it was backing is unknown. -/
def blindTrace : Trace :=
  Build.trace 4 0 step fun k t =>
    Build.scene t (some 1)
      [ car (cm (275 - 10 * k), m 0) Build.east backV noYaw ]
      [ intersectionA ]
      [ ]
      (occupies := some (if k ≥ 3 then [(1, 10)] else []))

/-- `branch_1` (violated): A car backs over a marked mid-block crosswalk: its footprint overlaps the crosswalk while backing. -/
def branch_1Trace : Trace :=
  Build.trace 6 0 step fun k t =>
    Build.scene t (some 1)
      [ car (cm (100 - 10 * k), m 0) Build.east backV noYaw ]
      [ { Build.rect 11 .crosswalk (m (-2)) (m (-10)) (m 2) (m 10) with marked := some true } ]
      [ ]
      (occupies := some [(1, 11)])

/-- `branch_2` (compliant): A car that overshot into the intersection backs straight out of it, heading unchanged, on an approach with no crosswalk: it is not entering the intersection and its heading has not turned. -/
def branch_2Trace : Trace :=
  Build.trace 16 0 step fun k t =>
    Build.scene t (some 1)
      [ car (cm (150 + 10 * k), m 0) Build.west (if k = 0 then zeroV else backV) noYaw ]
      [ intersectionA ]
      [ ]
      (occupies := some (if k ≤ 10 then [(1, 10)] else []))

/-- cos, sin (thousandths) of 0°, 5°, …, 80°. -/
def turnTable : List (Int × Int) :=
  [ (1000, 0), (996, 87), (985, 174), (966, 259), (940, 342), (906, 423), (866, 500), (819, 574)
  , (766, 643), (707, 707), (643, 766), (574, 819), (500, 866), (423, 906), (342, 940), (259, 966)
  , (174, 985) ]

/-- The heading at step k: 5k degrees left of east (the yaw rate at a scene is held over the
    interval before it). -/
def headingAt (k : Nat) : Vec :=
  let (c, s) := turnTable.getD k (174, 985)
  (Units.ratio c 1000, Units.ratio s 1000)

/-- The position at step k: each step moves the car 0.1 m against its heading at that step. -/
def posAt (k : Nat) : Vec :=
  (List.range k).foldl (fun p j => Geom.vsub p (Build.scale (headingAt (j + 1)) (cm 10))) (m 0, m 0)

/-- `branch_3` (violated): A car standing within the intersection backs around the corner into the cross street, its heading turning 80 degrees while its footprint still overlaps the intersection. -/
def branch_3Trace : Trace :=
  Build.trace 17 0 step fun k t =>
    Build.scene t (some 1)
      [ if k = 0 then car (m 0, m 0) Build.east zeroV noYaw
        else car (posAt k) (headingAt k) backV (Units.degrees 100) ]
      [ Build.rect 10 .intersection (m (-20)) (m (-20)) (m 20) (m 20) ]
      [ ]
      (occupies := some [(1, 10)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_113_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] (window := some (0, 150))
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_113_2
