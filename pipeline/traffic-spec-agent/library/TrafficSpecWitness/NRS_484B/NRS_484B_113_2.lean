/-
  Witnesses for NRS_484B_113_2.

  The world. Two streets cross at the origin: an east–west roadway (region 11, x ∈ [-60, 60],
  y ∈ [-4, 4]) and a north–south roadway (region 12, x ∈ [-4, 4], y ∈ [-60, 60]). The junction
  they make is an intersection region (region 10, the square [-4, 4] × [-4, 4]). Region 13 is a
  marked crosswalk, laid across the east–west roadway either just east of the junction
  (x ∈ [6, 10]) or well down the block (x ∈ [40, 44]); region 14 is a parking bay off the north
  side of the east–west roadway (x ∈ [40, 46], y ∈ [4, 7]).

  The body. One car, track 1, a motor vehicle 5 m long and 2 m wide (half-extents 2.5 m, 1 m,
  0.75 m). Its heading is a unit vector; its velocity follows the heading, so a negative speed is
  travel rearward. Occupancy is stated scene by scene (the footprint overlapping a region), not
  derived from the reference point.

  The instants. Every trace is thirteen scenes a quarter-second apart, t = 0 … 3000 ms, so that
  the one-second window behind is covered and densely sampled from t = 1000 ms on. Each witness
  speaks about [2000, 3000] — the five instants at which every lookback of the rule is covered.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_113_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_113_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
/-- A yaw rate in degrees per second, written to a thousandth. -/
def mdegPerSec (n : Int) : Q := Units.millidegrees n

/-- The sampling interval and the instants the witnesses speak about. -/
def dt : Q := Units.milliseconds 250
def winFrom : Timestamp := 2000
def winTo : Timestamp := 3000

/-- Half-length, half-width, half-height of the car. -/
def halfExt : Q × Q × Q := (cm 250, m 1, cm 75)

/-- The car: position, the direction it points, its speed along that direction (negative is
    rearward travel) and the yaw rate its source reports. -/
def car (pos : Vec) (hdg : Vec) (speed : Q) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [RoadUserClass.motorVehicle] pos hdg speed halfExt)
    (fun kn => { kn with speed := some (Q.abs speed), yawRate := some yaw })

-- The regions.
def junction : Structure := Build.rect 10 .intersection (m (-4)) (m (-4)) (m 4) (m 4)
def streetEW : Structure := Build.rect 11 .roadway (m (-60)) (m (-4)) (m 60) (m 4)
def streetNS : Structure := Build.rect 12 .roadway (m (-4)) (m (-60)) (m 4) (m 60)
/-- A marked crosswalk just east of the junction. -/
def crosswalkAtJunction : Structure :=
  { Build.rect 13 .crosswalk (m 6) (m (-4)) (m 10) (m 4) with marked := some true }
/-- A marked crosswalk in the middle of the block, far from any junction. -/
def crosswalkMidBlock : Structure :=
  { Build.rect 13 .crosswalk (m 40) (m (-4)) (m 44) (m 4) with marked := some true }
def parkingBay : Structure := Build.rect 14 .parkingSpace (m 40) (m 4) (m 46) (m 7)

/-- `forbid` (violated): A car stands on a street just beyond a junction, facing away from it. It reverses steadily back toward the junction over the whole backing window, its velocity opposed to its heading, and its footprint comes to overlap the junction region, which it did not overlap when the backing began. No crosswalk is marked or prolonged at that approach, its heading holds steady throughout, and no other road user is in the scene. -/
-- Facing east at x = 14 m, reversing west at 4 m/s (1 m a step) to x = 2 m; the footprint
-- (x ± 2.5 m) first reaches the junction's east edge at k = 8, t = 2000 ms.
def forbidTrace : Trace :=
  Build.trace 13 0 dt fun k t =>
    Build.scene t (some 1)
      [ car (m (14 - (k : Int)), m (-2)) Build.east (mps (-4)) Q.zero ]
      [ junction, streetEW, streetNS ]
      []
      (some (if 8 ≤ k then [(1, 11), (1, 10)] else [(1, 11)]))

/-- `permit` (compliant): A car reverses out of a parking bay in the middle of a block; its footprint overlaps only the bay and the roadway. The nearest junction and the nearest crosswalk are far beyond the corner reach, and its heading swings well short of the corner angle. No other road user is in the scene. -/
-- Nose-in at x = 43 m, facing north, reversing south at 1 m/s from y = 6 m to y = 3 m; its
-- heading holds steady (a swing of nothing at all, well short of the corner angle), and the
-- junction is 38 m from its footprint — far beyond the corner reach.
def permitTrace : Trace :=
  Build.trace 13 0 dt fun k t =>
    Build.scene t (some 1)
      [ car (m 43, Q.sub (m 6) (cm (25 * (k : Int)))) Build.north (mps (-1)) Q.zero ]
      [ junction, streetEW, crosswalkAtJunction, parkingBay ]
      []
      (some [(1, 14), (1, 11)])

/-- `idle` (not_applicable): The same car drives forward along the street and through the junction, the component of its velocity along its heading positive at every observation, so the act is never recognized. -/
-- Facing east at x = -14 m, driving east at 4 m/s through the junction.
def idleTrace : Trace :=
  Build.trace 13 0 dt fun k t =>
    Build.scene t (some 1)
      [ car (m ((k : Int) - 14), m (-2)) Build.east (mps 4) Q.zero ]
      [ junction, streetEW, streetNS ]
      []
      (some (if 8 ≤ k then [(1, 11), (1, 10)] else [(1, 11)]))

/-- `blind` (unknown): A car's footprint comes to overlap the junction region, having been clear of it a moment earlier, on a source that maps the junction and tracks the footprint but declares kin.velocity absent: whether the car was travelling rearward — whether it backed into the junction or drove into it — cannot be decided. -/
-- The scene of `forbid`, read off a source whose manifest declares kin.velocity absent.
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): A car reverses straight back over a crosswalk marked in the middle of a block, far beyond the corner reach of any junction; its velocity is opposed to its heading over the whole backing window, its footprint overlaps the crosswalk region, and its heading holds steady. -/
-- Facing east at x = 52 m, reversing west at 4 m/s to x = 40 m; the footprint reaches the
-- crosswalk (x ∈ [40, 44]) at k = 6 and stays on it, 33 m from the junction.
def branch_1Trace : Trace :=
  Build.trace 13 0 dt fun k t =>
    Build.scene t (some 1)
      [ car (m (52 - (k : Int)), m (-2)) Build.east (mps (-4)) Q.zero ]
      [ junction, streetEW, crosswalkMidBlock ]
      []
      (some (if 6 ≤ k then [(1, 11), (1, 13)] else [(1, 11)]))

/-- `branch_2` (violated): A car has stalled with its footprint already overlapping a junction region. It then reverses out of the junction into the intersecting street, swinging its heading through more than the corner angle over the backing window while its body is within the corner reach of the junction. Because the overlap began before the backing did, it did not back into the junction, and no crosswalk is marked or prolonged there. -/
-- Stalled in the junction facing east for the first second (k ≤ 4), then reversing at 1 m/s:
-- west to x = -1 m (k ≤ 8), then, as the heading swings east → 36.87° → 53.13° → north
-- (exact 3-4-5 unit vectors), south to y = -1 m. The yaw rate integrates that swing: over the
-- window behind t = 3000 ms it is 90°, past the corner angle; over every earlier window it is
-- 53.13° or less. The footprint stays inside the junction square throughout, so the overlap
-- never rises.
def b2Pos (k : Nat) : Vec :=
  if k ≤ 4 then (Q.zero, Q.zero)
  else if k ≤ 8 then (Q.neg (cm (25 * ((k : Int) - 4))), Q.zero)
  else (Q.neg (m 1), Q.neg (cm (25 * ((k : Int) - 8))))

def b2Heading (k : Nat) : Vec :=
  if k ≤ 8 then Build.east
  else if k = 9 then (Q.mk' 4 5, Q.mk' 3 5)
  else if k ≤ 11 then (Q.mk' 3 5, Q.mk' 4 5)
  else Build.north

def b2Yaw (k : Nat) : Q :=
  if k = 9 then mdegPerSec 147480
  else if k = 10 then mdegPerSec 65040
  else if k = 12 then mdegPerSec 147480
  else Q.zero

def b2Speed (k : Nat) : Q := if k ≤ 4 then Q.zero else mps (-1)

def branch_2Trace : Trace :=
  Build.trace 13 0 dt fun k t =>
    Build.scene t (some 1)
      [ car (b2Pos k) (b2Heading k) (b2Speed k) (b2Yaw k) ]
      [ junction, streetEW, streetNS ]
      []
      (some [(1, 10), (1, 11), (1, 12)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_113_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := some (winFrom, winTo) }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_113_2
