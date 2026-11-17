/-
  Witnesses for NRS_484B_627_1b.

  Geometry (the witness's own figures; none appears in the rule):
  - Highway region 10: x ∈ [-200, 3000], y ∈ [-4, 16]. Three eastbound lanes on it (`ways = [10]`),
    4 m wide, count 3 in their direction: lane 11 (ordinal 1, leftmost) y ∈ [8, 12], lane 12
    (ordinal 2) y ∈ [4, 8], lane 13 (ordinal 3, rightmost) y ∈ [0, 4].
  - Device 100: a 30 m/s `maximum` speed limit sign governing lanes 11, 12, 13.
  - Subject (track 1): a motor vehicle 4 m × 2 m heading east at x = 100 + v·t; follower (track 2):
    a motor vehicle of the same size 16 m behind centre to centre (12 m body gap), same speed.
  - Instants every 1 s from 0 to 14 s; each scenario speaks about 12–14 s (`window`), where the
    10 s move-over window behind is fully observed.
  - Slow scenes: 18 m/s (18 + 4.5 = 22.5 < 30); idle: 29 m/s (33.5 > 30).
  - Truck (track 3, 12 m × 2.5 m, 12 m/s) in lane 12 (y = 6), on the subject's right: branch_1 side
    by side (centre offset 6, 0, −6 m over the window); branch_2 about 200 m body gap ahead (bound
    6 m/s × 10 s = 60 m); branch_3 about 24–36 m ahead (within the bound).
  - branch_4: the subject straddles lanes 12 and 13 (stated occupancy).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_627_1b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_627_1b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneStrip (id : RegionId) (y0 : Int) (left right : Option RegionId) (ord : Nat) : Structure :=
  { Build.lane id [(m (-200), m y0), (m 3000, m y0), (m 3000, m (y0 + 4)), (m (-200), m (y0 + 4))]
      Build.east left right (some ord) (some 3) with ways := some [10] }

def highway : Structure := Build.rect 10 .highway (m (-200)) (m (-4)) (m 3000) (m 16)

def structures : List Structure :=
  [ highway
  , laneStrip 11 8 none (some 12) 1
  , laneStrip 12 4 (some 11) (some 13) 2
  , laneStrip 13 0 (some 12) none 3 ]

def maxSign : Device := Build.speedLimit 100 [11, 12, 13] (Units.metresPerSecond 30) .maximum

def car (track : TrackId) (x y v : Int) : RoadUser :=
  Build.user track [.motorVehicle] (m x, m y) Build.east (Units.metresPerSecond v) (m 2, m 1, m 1)

def truck (x : Int) : RoadUser :=
  Build.user 3 [.truck] (m x, m 6) Build.east (Units.metresPerSecond 12) (m 6, cm 125, m 2)

/-- The subject at speed `v` at lateral position `y`, its follower 12 m behind, and `others`. -/
def slowTrace (v y : Int) (others : Int → List RoadUser)
    (occ : Option (List (TrackId × RegionId)) := none) : Trace :=
  Build.trace 15 0 (Units.seconds 1) fun k t =>
    let ki : Int := k
    Build.scene t (some 1)
      ([car 1 (100 + v * ki) y v, car 2 (84 + v * ki) y v] ++ others ki)
      structures
      [maxSign]
      occ

/-- `forbid` (violated): A car on a highway with three lanes in its direction occupies lane 1 (leftmost) under a 30 m/s maximum sign; for longer than the move-over time it has moved at 18 m/s with a car 12 m behind it in its lane and no one ahead; no slower vehicle lies on its right. -/
def forbidTrace : Trace := slowTrace 18 10 (fun _ => [])

/-- `permit` (compliant): The same slow car occupies lane 3, the rightmost of its direction. -/
def permitTrace : Trace := slowTrace 18 2 (fun _ => [])

/-- `idle` (not_applicable): The same car in lane 1 travels at 29 m/s under the 30 m/s maximum: it is not slow. -/
def idleTrace : Trace := slowTrace 29 10 (fun _ => [])

/-- `blind` (unknown): As in forbid, but the source does not supply lane adjacency (ordinals and counts), so neither the lane count nor which lane is rightmost is observed. -/
def blindTrace : Trace := Build.masked (Build.manifest ["st.lane_adjacency"]) forbidTrace

/-- `branch_1` (compliant): As in forbid, but a truck moving at 12 m/s lies on the car's right, side by side with it: the car is passing a slower vehicle. -/
def branch_1Trace : Trace := slowTrace 18 10 (fun k => [truck (178 + 12 * k)])

/-- `branch_2` (violated): As in branch_1, but the truck on the right is 200 m ahead; at a 6 m/s speed difference the car would not close it within the overtaking window. -/
def branch_2Trace : Trace := slowTrace 18 10 (fun k => [truck (386 + 12 * k)])

/-- `branch_3` (compliant): As in branch_2, but the truck on the right is about 30 m ahead: the car closes it within the overtaking window. -/
def branch_3Trace : Trace := slowTrace 18 10 (fun k => [truck (216 + 12 * k)])

/-- `branch_4` (violated): The same slow car straddles lane 3 (rightmost) and lane 2: it occupies another lane of its direction. -/
def branch_4Trace : Trace :=
  slowTrace 18 4 (fun _ => []) (some [(1, 10), (1, 12), (1, 13), (2, 10), (2, 12), (2, 13)])

/-- `branch_5` (violated): As in forbid, but a car travels 100 m ahead of the subject in its lane, beyond the rear-signal reach: nothing ahead holds the subject back. -/
def branch_5Trace : Trace := slowTrace 18 10 (fun k => [car 4 (204 + 18 * k) 10 18])

def judged : Option (Timestamp × Timestamp) := some (12000, 14000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_627_1b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_627_1b
