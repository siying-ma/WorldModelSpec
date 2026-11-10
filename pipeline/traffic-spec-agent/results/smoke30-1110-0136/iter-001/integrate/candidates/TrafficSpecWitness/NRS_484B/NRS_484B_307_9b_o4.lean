/-
  Witnesses for NRS_484B_307_9b_o4.

  The junction: intersection 10 is the square x, y ∈ [-6, 6] m. Four approach lanes run up to its
  edges, each entering it: 11 northbound (x ∈ [0, 4], south of it), 12 southbound (x ∈ [-4, 0],
  north), 13 westbound (y ∈ [0, 4], east), 14 eastbound (y ∈ [-4, 0], west). Four 3 m crosswalks
  lie across the approaches at the intersection's edges, each marking the entrance of the
  approach it lies on: 20 south (lane 11), 21 north (lane 12), 22 east (lane 13), 23 west
  (lane 14). Signal 30 shows circular_red with one green arrow; it governs lane 11, except in
  branch_3, where it governs the intersection itself.

  x (track 1) comes up lane 11 along x = 2 m. Scenes are 50 ms apart (the acquisition standard's
  step, so the heading change since the entry is integrated across every interval). A straight
  crossing keeps the heading north with zero yaw rate. A turn starts at (2, -4) m and is a
  quarter circle on the rational parametrisation of the circle, (cos θ, sin θ) =
  ((n² − j²)/(n² + j²), 2jn/(n² + j²)) for j = 0 … n, with yaw rate ±1800/n °/s at j ≥ 1, so the
  heading changes by 90° over the turn: a left turn of radius 6 m (n = 40) ending at (-4, 2)
  heading west, a right turn of radius 3 m (n = 20) ending at (5, -1) heading east; turning users
  move 0.24 m per scene (4.8 m/s). Pedestrians (track 2) walk at 1.5 m/s, 3 m/s in permit; the car
  of branch_2 (track 3) moves east at 1 m/s inside the intersection.

  Every witness names its instants from 50 ms: at the first scene the observation before is
  missing, so the exit and entry edges are unknown there.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b_o4
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b_o4

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mm (n : Int) : Q := Units.millimetres n

def dt : Q := Units.milliseconds 50

-- Binders ↦ tracks: x ↦ 1

def crosswalk (id : RegionId) (x0 y0 x1 y1 : Q) (marks : RegionId) : Structure :=
  { Build.rect id .crosswalk x0 y0 x1 y1 with
    entranceOf := [marks], entranceObserved := true, marked := some true }

def junction : List Structure :=
  [ Build.rect 10 .intersection (m (-6)) (m (-6)) (m 6) (m 6)
  , Build.lane 11 [(m 0, m (-40)), (m 4, m (-40)), (m 4, m (-6)), (m 0, m (-6))] Build.north
      (enters := some 10)
  , Build.lane 12 [(m (-4), m 6), (m 0, m 6), (m 0, m 40), (m (-4), m 40)] Build.south
      (enters := some 10)
  , Build.lane 13 [(m 6, m 0), (m 40, m 0), (m 40, m 4), (m 6, m 4)] Build.west
      (enters := some 10)
  , Build.lane 14 [(m (-40), m (-4)), (m (-6), m (-4)), (m (-6), m 0), (m (-40), m 0)] Build.east
      (enters := some 10)
  , crosswalk 20 (m (-6)) (m (-9)) (m 6) (m (-6)) 11
  , crosswalk 21 (m (-6)) (m 6) (m 6) (m 9) 12
  , crosswalk 22 (m 6) (m (-6)) (m 9) (m 6) 13
  , crosswalk 23 (m (-9)) (m (-6)) (m (-6)) (m 6) 14 ]

def signal (governs : List RegionId) (arrow : ArrowDir) : Device :=
  Build.signal 30 governs [.circularRed, .greenArrow arrow]

def bike : Q × Q × Q := (cm 90, cm 30, cm 60)
def motorbike : Q × Q × Q := (cm 110, cm 40, cm 70)
def person : Q × Q × Q := (cm 30, cm 30, cm 90)

def rider (track : TrackId) (cls : List RoadUserClass) (pos heading : Vec) (speed yaw : Q)
    (half : Q × Q × Q) : RoadUser :=
  Build.withKin (Build.user track cls pos heading speed half) fun kn => { kn with yawRate := some yaw }

def walker (pos heading : Vec) (speed : Q) : RoadUser :=
  Build.user 2 [.pedestrian] pos heading speed person

/-- Straight up lane 11 at 5 m/s: y = -9.9 m + 0.25 m per scene; enters the intersection by
    k = 12, leaves it (whole body past y = 6) by k = 69. -/
def straightPos (k : Nat) : Vec := (mm 2000, mm (-9900 + 250 * (k : Int)))

/-- Quarter-turn point j of n on the unit circle. -/
def cosAt (j n : Nat) : Q := Q.mk' ((n : Int) * n - (j : Int) * j) (n * n + j * j)
def sinAt (j n : Nat) : Q := Q.mk' (2 * (j : Int) * n) (n * n + j * j)

/-- A left turn: 20 scenes up lane 11 to (2, -4), a quarter circle of radius 6 m about (-4, -4)
    over 40 scenes, then west along y = 2; position, heading, yaw rate. -/
def leftPath (k : Nat) : Vec × Vec × Q :=
  if k ≤ 20 then ((mm 2000, mm (-4000 - 240 * (20 - (k : Int)))), Build.north, Q.zero)
  else if k ≤ 60 then
    let c := cosAt (k - 20) 40
    let s := sinAt (k - 20) 40
    ((Q.add (m (-4)) (Q.mul (m 6) c), Q.add (m (-4)) (Q.mul (m 6) s)), (Q.neg s, c), Q.mk' 45 1)
  else ((mm (-4000 - 240 * ((k : Int) - 60)), mm 2000), Build.west, Q.zero)

/-- A right turn: 20 scenes up lane 11 to (2, -4), a quarter circle of radius 3 m about (5, -4)
    over 20 scenes, then east along y = -1. -/
def rightPath (k : Nat) : Vec × Vec × Q :=
  if k ≤ 20 then ((mm 2000, mm (-4000 - 240 * (20 - (k : Int)))), Build.north, Q.zero)
  else if k ≤ 40 then
    let c := cosAt (k - 20) 20
    let s := sinAt (k - 20) 20
    ((Q.sub (m 5) (Q.mul (m 3) c), Q.add (m (-4)) (Q.mul (m 3) s)), (s, c), Q.mk' (-90) 1)
  else ((mm (5000 + 240 * ((k : Int) - 40)), mm (-1000)), Build.east, Q.zero)

/-- `forbid` (violated): A bicycle enters on circular_red with green_arrow(left) and goes straight; a pedestrian in the far-side crosswalk, which marks the entrance of the opposing approach, walks across its path, and while the bicycle moves their predicted closest approach within the horizon is below the conflict clearance.
    The pedestrian walks east along y = 7.5 m in crosswalk 21 from x = -5 m; with the bicycle at
    (2, 0.1) and the pedestrian at (-2, 7.5) the closest approach is 1.6 s ahead at about 1.7 m. -/
def forbidTrace : Trace :=
  Build.trace 74 0 dt fun k t =>
    Build.scene t (some 1)
      [ rider 1 [.bicycle] (straightPos k) Build.north (m 5) Q.zero bike
      , walker (mm (-5000 + 75 * (k : Int)), mm 7500) Build.east (cm 150) ]
      junction
      [ signal [11] .left ]

/-- `permit` (compliant): The bicycle waits in the intersection until the pedestrian has cleared, so no predicted conflict arises while it moves.
    The bicycle rides at 8 m/s to (2, 4.5) (k = 32) while the pedestrian is still west of the
    crosswalk, stands there while the pedestrian (3 m/s along y = 7.5) crosses crosswalk 21 in
    front of it (k = 34 … 118; a closest approach 3 m away, which would be a conflict were the
    bicycle moving), and rides on from k = 125, the crosswalk clear. -/
def permitY (k : Nat) : Q :=
  if k ≤ 32 then mm (-8300 + 400 * (k : Int))
  else if k ≤ 124 then mm 4500
  else mm (4500 + 400 * ((k : Int) - 124))

def permitTrace : Trace :=
  Build.trace 136 0 dt fun k t =>
    Build.scene t (some 1)
      [ rider 1 [.bicycle] (mm 2000, permitY k) Build.north
          (if k ≤ 31 ∨ k ≥ 125 then m 8 else Q.zero) Q.zero bike
      , walker (mm (-11400 + 150 * (k : Int)), mm 7500) Build.east (m 3) ]
      junction
      [ signal [11] .left ]

/-- `idle` (not_applicable): The bicycle enters on red with a green left arrow and turns left with the arrow. -/
def idleTrace : Trace :=
  Build.trace 78 0 dt fun k t =>
    let (pos, hd, yaw) := leftPath k
    Build.scene t (some 1)
      [ rider 1 [.bicycle] pos hd (cm 480) yaw bike ]
      junction
      [ signal [11] .left ]

/-- `blind` (unknown): A motorcycle goes straight through on red with a green left arrow while a pedestrian on a crosswalk at the intersection is in predicted conflict with it; the source does not record which approach the crosswalk marks.
    The forbid scene with a motorcycle; the manifest masks st.entrance_of. -/
def blindTrace : Trace :=
  Build.trace 74 0 dt fun k t =>
    Build.scene t (some 1)
      [ rider 1 [.motorcycle] (straightPos k) Build.north (m 5) Q.zero motorbike
      , walker (mm (-5000 + 75 * (k : Int)), mm 7500) Build.east (cm 150) ]
      junction
      [ signal [11] .left ]

/-- `branch_1` (compliant): A motorcycle goes straight through on red with a green left arrow and no other road user is in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 74 0 dt fun k t =>
    Build.scene t (some 1)
      [ rider 1 [.motorcycle] (straightPos k) Build.north (m 5) Q.zero motorbike ]
      junction
      [ signal [11] .left ]

/-- `branch_2` (violated): A moped turns right on red with a green left arrow while a car turning left with the arrow, already in the intersection, is in predicted conflict with it as it moves.
    The car, finishing its turn from lane 12, moves east along y = -2 from x = 3 m; with the moped
    at (2, -5.9) and the car at (3.6, -2) the closest approach is 0.7 s ahead at about 2.4 m. -/
def branch_2Trace : Trace :=
  Build.trace 53 0 dt fun k t =>
    let (pos, hd, yaw) := rightPath k
    Build.scene t (some 1)
      [ rider 1 [.moped] pos hd (cm 480) yaw bike
      , rider 3 [.motorVehicle] (mm (3000 + 50 * (k : Int)), mm (-2000)) Build.east (m 1) Q.zero
          (cm 220, cm 90, cm 75) ]
      junction
      [ signal [11] .left ]

/-- `branch_3` (violated): An electric bicycle turns left on red with a green right arrow, the
    signal governing the intersection itself, while a pedestrian walks north in the west crosswalk
    (23, marking lane 14's entrance) across its exit; at the end of the turn, the bicycle at
    (-4, 2) heading west and the pedestrian at (-7.5, 1), the closest approach is 0.7 s ahead at
    under 0.1 m. -/
def branch_3Trace : Trace :=
  Build.trace 78 0 dt fun k t =>
    let (pos, hd, yaw) := leftPath k
    Build.scene t (some 1)
      [ rider 1 [.electricBicycle] pos hd (cm 480) yaw bike
      , walker (mm (-7500), mm (-3500 + 75 * (k : Int))) Build.north (cm 150) ]
      junction
      [ signal [10] .right ]

def witness (name : String) (τ : Trace) (expected : Verdict) (last : Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b_o4"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, last)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 3650
  , witness "permit" permitTrace .compliant 6750
  , witness "idle" idleTrace .notApplicable 3850
  , witness "blind" blindTrace (.unknown []) 3650 ["st.entrance_of"]
  , witness "branch_1" branch_1Trace .compliant 3650
  , witness "branch_2" branch_2Trace .violated 2600
  , witness "branch_3" branch_3Trace .violated 3850 ]

end TrafficSpecWitness.NRS_484B_307_9b_o4
