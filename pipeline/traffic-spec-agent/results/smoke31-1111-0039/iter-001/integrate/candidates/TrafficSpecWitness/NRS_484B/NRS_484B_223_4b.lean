/-
  Witnesses for NRS_484B_223_4b.

  The carriageway: an eastbound approach (+x) ending at x = 0, where the intersection (region 10,
  x ∈ [0, 20] m, y ∈ [−20, 20] m) begins; a highway (region 1) spans the whole scene and every
  lane and the intersection lie on it. The approach has a through lane (region 2, y ∈ [−3, 0] m,
  ordinal 1) and, on its right, a right turn lane (region 3, y ∈ [−6, −3] m, ordinal 2 of 2); both
  enter the intersection. `idle` has the through lane alone; `branch_2` adds a second right turn
  lane (region 4, y ∈ [−9, −6] m, ordinal 3 of 3) to the right of region 3.

  The body: one car (track 1), 4 m by 2 m, at 10 m/s, scenes every 50 ms (the reading's heading
  step): 0.5 m per scene. Its heading is a whole number of 4.5° steps from east; a change of one
  step between scenes is a yaw rate of ±90°/s held over the interval before the scene, and each
  position is the previous one plus the scene's velocity over that interval. Occupancy is stated
  (the footprint lies across two regions at the entry): a region while the footprint overlaps it.
  Every scene judged lies after the first (`window`): the exit and the entry are read against the
  previous scene.

  Heading: none on a straight passage (change 0°, well above −45°); the right turn of `permit`
  turns 20 steps to the right inside the intersection (−90°, well below −45°).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_4b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_4b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- The scene spacing: 50 ms. -/
def dt : Q := Units.milliseconds 50

def highway : Structure := Build.rect 1 .highway (m (-60)) (m (-30)) (m 60) (m 30)
def intersection : Structure :=
  { Build.rect 10 .intersection (m 0) (m (-20)) (m 20) (m 20) with ways := some [1] }

/-- An approach strip of the eastbound side between `y0` and `y1` metres. -/
def strip (y0 y1 : Int) : List Vec := [(m (-60), m y0), (m 0, m y0), (m 0, m y1), (m (-60), m y1)]

/-- The through lane of a two-lane approach, its right neighbour the turn lane. -/
def throughLane : Structure :=
  { Build.lane 2 (strip (-3) 0) Build.east none (some 3) (some 1) (some 2) none (some 10) with
    ways := some [1] }
/-- The single right turn lane. -/
def turnLane : Structure :=
  { Build.lane 3 (strip (-6) (-3)) Build.east (some 2) none (some 2) (some 2) none (some 10) with
    kind := .turnLane, turnSide := some .right, ways := some [1] }

def structures : List Structure := [highway, throughLane, turnLane, intersection]

/-- cos and sin of j · 4.5°, j = 0 … 20, in millionths. -/
def trig : List (Int × Int) :=
  [ (1000000, 0), (996917, 78459), (987688, 156434), (972370, 233445), (951057, 309017)
  , (923880, 382683), (891007, 453990), (852640, 522499), (809017, 587785), (760406, 649448)
  , (707107, 707107), (649448, 760406), (587785, 809017), (522499, 852640), (453990, 891007)
  , (382683, 923880), (309017, 951057), (233445, 972370), (156434, 987688), (78459, 996917)
  , (0, 1000000) ]

/-- The unit heading `a` steps of 4.5° from east, left (north) positive. -/
def dirOf (a : Int) : Vec :=
  let (c, s) := trig.getD a.natAbs (0, 1000000)
  (Units.ratio c 1000000, Units.ratio (if a < 0 then -s else s) 1000000)

/-- The position at scene `k`: from `p0`, each scene adds its velocity (10 m/s) over 50 ms. -/
def posAt (p0 : Vec) (ang : Nat → Int) (k : Nat) : Vec :=
  (List.range k).foldl (fun p i =>
    let d := dirOf (ang (i + 1))
    (Q.add p.1 (Q.half d.1), Q.add p.2 (Q.half d.2))) p0

/-- The yaw rate at scene `k`: one 4.5° step over 50 ms is 90°/s. -/
def yawAt (ang : Nat → Int) (k : Nat) : Q :=
  if k = 0 then Units.degrees 0 else Units.degrees (90 * (ang k - ang (k - 1)))

/-- The car, with its yaw rate. -/
def car (pos heading : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond 10) (m 2, m 1, cm 75))
    fun k => { k with yawRate := some yaw }

/-- `n` scenes of the car driving the headings `ang` from `p0`, with the stated occupancy. -/
def drive (n : Nat) (p0 : Vec) (ang : Nat → Int) (structs : List Structure)
    (occ : Nat → List (TrackId × RegionId)) : Trace :=
  Build.trace n 0 dt fun k t =>
    Build.scene t (some 1) [car (posAt p0 ang k) (dirOf (ang k)) (yawAt ang k)] structs [] (some (occ k))

/-- A straight eastbound passage from 6 m short of the intersection, 61 scenes (3 s), in lane `ln`
    at lateral position `y` (cm): in the lane while the rear is short of x = 0 (scenes 0–15), in
    the intersection from scene 9 (front past x = 0) to scene 55; it leaves at scene 56. -/
def straightTrace (ln : RegionId) (y : Int) (structs : List Structure) : Trace :=
  drive 61 (m (-6), cm y) (fun _ => 0) structs fun k =>
    [(1, 1)] ++ (if k ≤ 15 then [(1, ln)] else []) ++ (if 9 ≤ k ∧ k ≤ 55 then [(1, 10)] else [])

/-- `forbid` (violated): A car in the single right turn lane enters the intersection the lane runs into and drives straight across it, leaving with its heading unchanged. -/
def forbidTrace : Trace := straightTrace 3 (-450) structures

/-- `permit` (compliant): A car in the single right turn lane enters the intersection and turns a quarter turn to the right before leaving it.
    Scenes 0–14 straight east (entry at scene 9, x = −1.5 m); scenes 15–34 turning one step right
    each (to south at scene 34, near (7.1, −11.1) m); then south; the rear clears the
    intersection's south edge (y = −20 m) at scene 56. -/
def permitTrace : Trace :=
  let ang : Nat → Int := fun k => if k ≤ 14 then 0 else if k ≤ 34 then -((k : Int) - 14) else -20
  drive 58 (m (-6), cm (-450)) ang structures fun k =>
    [(1, 1)] ++ (if k ≤ 15 then [(1, 3)] else []) ++ (if 9 ≤ k ∧ k ≤ 55 then [(1, 10)] else [])

/-- `idle` (not_applicable): A car drives straight through an intersection from a through lane on a highway whose approach has no right turn lane. -/
def idleTrace : Trace :=
  let onlyLane : Structure :=
    { Build.lane 2 (strip (-3) 0) Build.east none none (some 1) (some 1) none (some 10) with
      ways := some [1] }
  straightTrace 2 (-150) [highway, onlyLane, intersection]

/-- `blind` (unknown): A car enters the intersection from the single right turn lane and leaves it; the source declares kin.yaw_rate absent, so whether it turned right is not observed. -/
def blindTrace : Trace := Build.masked (Build.manifest ["kin.yaw_rate"]) forbidTrace

/-- `branch_1` (compliant): A car in the single right turn lane moves back into the through lane on its left before the intersection and later crosses the intersection from the through lane: it never entered the intersection from the turn lane.
    From (−20, −4.75) m: scenes 6–15 one step left each (to 45°), scenes 16–25 back to east, at
    y ≈ −1.0 m (in the turn lane to scene 17, in the through lane from scene 11); the front passes
    x = 0 at scene 39, from the through lane; the rear clears x = 20 m at scene 86. -/
def branch_1Trace : Trace :=
  let ang : Nat → Int := fun k =>
    if k ≤ 5 then 0 else if k ≤ 15 then (k : Int) - 5 else if k ≤ 25 then 25 - (k : Int) else 0
  drive 89 (m (-20), cm (-475)) ang structures fun k =>
    [(1, 1)] ++ (if k ≤ 17 then [(1, 3)] else []) ++ (if 11 ≤ k ∧ k ≤ 45 then [(1, 2)] else [])
      ++ (if 39 ≤ k ∧ k ≤ 85 then [(1, 10)] else [])

/-- `branch_2` (not_applicable): two adjacent right turn lanes: a car drives straight across the
    intersection from the outer one, which is no single right turn lane. -/
def branch_2Trace : Trace :=
  let through : Structure :=
    { Build.lane 2 (strip (-3) 0) Build.east none (some 3) (some 1) (some 3) none (some 10) with
      ways := some [1] }
  let inner : Structure :=
    { Build.lane 3 (strip (-6) (-3)) Build.east (some 2) (some 4) (some 2) (some 3) none (some 10) with
      kind := .turnLane, turnSide := some .right, ways := some [1] }
  let outer : Structure :=
    { Build.lane 4 (strip (-9) (-6)) Build.east (some 3) none (some 3) (some 3) none (some 10) with
      kind := .turnLane, turnSide := some .right, ways := some [1] }
  straightTrace 4 (-750) [highway, through, inner, outer, intersection]

/-- `branch_3` (compliant): a car leaves a single right turn lane, crosses the through lane into
    the inner one of two adjacent right turn lanes and drives straight across the intersection
    from it: no single right turn lane carries it into the intersection.
    Four eastbound lanes from the left: a right turn lane (3, y ∈ [−3, 0] m, its neighbour the
    through lane), the through lane (2), and two adjacent right turn lanes (4, 5). From
    (−30, −1.5) m: scenes 4–16 one step right each (to −58.5°), scenes 17–29 back to east, at
    y ≈ −7.6 m (in lane 3 to scene 17, lane 2 in scenes 6–25, lane 4 from scene 14); the front
    passes x = 0 at scene 61, from lane 4; the rear clears x = 20 m at scene 109. -/
def branch_3Trace : Trace :=
  let single : Structure :=
    { Build.lane 3 (strip (-3) 0) Build.east none (some 2) (some 1) (some 4) none (some 10) with
      kind := .turnLane, turnSide := some .right, ways := some [1] }
  let through : Structure :=
    { Build.lane 2 (strip (-6) (-3)) Build.east (some 3) (some 4) (some 2) (some 4) none (some 10) with
      ways := some [1] }
  let inner : Structure :=
    { Build.lane 4 (strip (-9) (-6)) Build.east (some 2) (some 5) (some 3) (some 4) none (some 10) with
      kind := .turnLane, turnSide := some .right, ways := some [1] }
  let outer : Structure :=
    { Build.lane 5 (strip (-12) (-9)) Build.east (some 4) none (some 4) (some 4) none (some 10) with
      kind := .turnLane, turnSide := some .right, ways := some [1] }
  let ang : Nat → Int := fun k =>
    if k ≤ 3 then 0 else if k ≤ 16 then 3 - (k : Int) else if k ≤ 29 then (k : Int) - 29 else 0
  drive 111 (m (-30), cm (-150)) ang [highway, single, through, inner, outer, intersection] fun k =>
    [(1, 1)] ++ (if k ≤ 17 then [(1, 3)] else []) ++ (if 6 ≤ k ∧ k ≤ 25 then [(1, 2)] else [])
      ++ (if 14 ≤ k ∧ k ≤ 68 then [(1, 4)] else []) ++ (if 61 ≤ k ∧ k ≤ 108 then [(1, 10)] else [])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_223_4b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (50, 3000))
  , witness "permit" permitTrace .compliant (window := some (50, 2850))
  , witness "idle" idleTrace .notApplicable (window := some (50, 3000))
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (window := some (50, 3000))
  , witness "branch_1" branch_1Trace .compliant (window := some (50, 4400))
  , witness "branch_2" branch_2Trace .notApplicable (window := some (50, 3000))
  , witness "branch_3" branch_3Trace .compliant (window := some (50, 5500)) ]

end TrafficSpecWitness.NRS_484B_223_4b
