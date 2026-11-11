/-
  Witnesses for NRS_484B_223_4a.

  The carriageway runs north on a highway region (10, the rectangle (-20,-20)–(60,120) m). The
  through lane 11 is x 0–4 m, y 0–62 m; the single right turn lane 12 is x 4–8 m, y 30–60 m, the
  through lane its left neighbour, itself last of the lanes in its direction; both enter the
  intersection 13 (x -8–14 m, y 60–76 m). Beyond it lie an eastbound exit lane 17 (x 14–60 m,
  y 62–68 m) for the right turn and a northbound exit lane 18 (x 0–8 m, y 76–120 m) for the
  straight crossing; a side street lane 14 (x 8–60 m, y 40–44 m) leaves the turn lane to the right.
  `idle` has the through lane alone; `branch_1` has two right turn lanes 15 (x 4–8 m) and 16
  (x 8–12 m) side by side; in `branch_5` lane 11 is a left turn lane instead of a through lane.

  The car (track 1, half-extents 2 m × 1 m × 0.75 m) runs at 10 m/s, sampled every 50 ms (the
  acquisition's step): 0.5 m per step. Its heading is an index of 4.5° steps clockwise from north;
  a step of the index between two scenes is a yaw rate of ∓90 deg/s held over the interval before
  the later scene, and its position is integrated from its headings. Its occupancy is computed from
  its footprint against every region's polygon. The quarter turn to the right is twenty such steps:
  a heading change of -90° since it entered the intersection, well past minus the 45° recognition
  angle; the straight crossing has none (0°, well short of it). Each witness speaks about the
  instants from 50 ms on: the first observation has no predecessor for `rises` and `since`.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_4a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_4a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

/-- cos(4.5°·n), n = 0 … 20, in millionths. -/
def cosTable : List Int :=
  [1000000, 996917, 987688, 972370, 951057, 923880, 891007, 852640, 809017, 760406, 707107,
   649448, 587785, 522499, 453990, 382683, 309017, 233445, 156434, 78459, 0]
def cosAt (n : Nat) : Q := Units.ratio (cosTable.getD n 0) 1000000

/-- The heading 4.5°·j clockwise from north (j negative: to the left). -/
def hd (j : Int) : Vec :=
  let n := j.natAbs
  let s := cosAt (20 - n)
  if j < 0 then (Q.neg s, cosAt n) else (s, cosAt n)

/-- The position after k steps of 0.5 m along the headings of the profile `ang`. -/
def posAt (p0 : Vec) (ang : Nat → Int) : Nat → Vec
  | 0 => p0
  | k + 1 =>
    let p := posAt p0 ang k
    let h := hd (ang (k + 1))
    (Q.add p.1 (Q.mul h.1 (cm 50)), Q.add p.2 (Q.mul h.2 (cm 50)))

/-- The yaw rate (deg/s, left positive) held over the interval before scene k. -/
def yawAt (ang : Nat → Int) : Nat → Int
  | 0 => 0
  | k + 1 => -90 * (ang (k + 1) - ang k)

def car (p : Vec) (h : Vec) (yaw : Int) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] p h (Units.metresPerSecond 10) (m 2, m 1, cm 75))
    fun kn => { kn with yawRate := some (Units.degrees yaw) }

/-- The car at scene k of a run from `p0` along the heading profile `ang`. -/
def mover (p0 : Vec) (ang : Nat → Int) (k : Nat) : RoadUser :=
  car (posAt p0 ang k) (hd (ang k)) (yawAt ang k)

/-- A stationary car of the through queue. -/
def queued (track : TrackId) (p : Vec) : RoadUser :=
  Build.withKin (Build.user track [.motorVehicle] p Build.north (Units.metresPerSecond 0) (m 2, m 1, cm 75))
    fun kn => { kn with yawRate := some (Units.degrees 0) }

/-- Every region each body's footprint overlaps. -/
def occAll (t : Timestamp) (us : List RoadUser) (sts : List Structure) : List (TrackId × RegionId) :=
  let s : Scene := { t := t, users := us }
  us.flatMap fun u => sts.filterMap fun st =>
    match footprint s u.track, st.boundary with
    | some fp, some poly => if Geom.polygonsOverlap fp poly then some (u.track, st.id) else none
    | _, _ => none

def sceneOf (t : Timestamp) (us : List RoadUser) (sts : List Structure) : Scene :=
  Build.scene t (some 1) us sts [] (some (occAll t us sts))

def hwy : Structure := Build.rect 10 .highway (m (-20)) (m (-20)) (m 60) (m 120)
def onHwy (s : Structure) : Structure := { s with ways := some [10] }
def throughLane (right : Option RegionId) (count : Nat) : Structure :=
  onHwy (Build.lane 11 (box 0 0 4 62) Build.north none right (some 1) (some count) none (some 13))
def rightTurnLane (id : RegionId) (x0 : Int) (left right : Option RegionId) (ord count : Nat) : Structure :=
  { onHwy (Build.lane id (box x0 30 (x0 + 4) 60) Build.north left right (some ord) (some count) none (some 13)) with
    kind := .turnLane, turnSide := some .right }
def junction : Structure := onHwy (Build.rect 13 .intersection (m (-8)) (m 60) (m 14) (m 76))
def eastExit : Structure := onHwy (Build.lane 17 (box 14 62 60 68) Build.east)
def northExit : Structure := onHwy (Build.lane 18 (box 0 76 8 120) Build.north)
def sideStreet : Structure := onHwy (Build.lane 14 (box 8 40 60 44) Build.east)

/-- The approach with its single right turn lane. -/
def singleLane : List Structure :=
  [hwy, throughLane (some 12) 2, rightTurnLane 12 4 (some 11) none 2 2, junction, eastExit, northExit, sideStreet]

def dt : Q := Units.milliseconds 50

/-- Heading profiles. -/
def straightAng (_k : Nat) : Int := 0
/-- Straight to the intersection, a quarter turn right over scenes 14–33, then east. -/
def turnAng (k : Nat) : Int := if k ≤ 13 then 0 else if k ≤ 33 then (k : Int) - 13 else 20
/-- A lane change to the left: 18° left over scenes 3–6, held to 28, back to north by 32. -/
def leftChangeAng (k : Nat) : Int :=
  if k ≤ 2 then 0 else if k ≤ 6 then -((k : Int) - 2) else if k ≤ 28 then -4 else if k ≤ 32 then (k : Int) - 32 else 0
/-- A quarter turn right over scenes 4–23, then east. -/
def sideTurnAng (k : Nat) : Int := if k ≤ 3 then 0 else if k ≤ 23 then (k : Int) - 3 else 20

/-- `forbid` (violated): A car enters the single right turn lane to pass a queue of through traffic, then moves back into the through lane on its left before reaching the intersection. -/
def forbidTrace : Trace :=
  Build.trace 40 0 dt fun k t =>
    sceneOf t [mover (m 6, m 34) leftChangeAng k, queued 2 (m 2, m 30), queued 3 (m 2, m 36)] singleLane

/-- `permit` (compliant): A car drives in the single right turn lane, enters the intersection the lane runs into and turns a quarter turn to the right before leaving it. -/
def permitTrace : Trace :=
  Build.trace 46 0 dt fun k t => sceneOf t [mover (m 6, m 53) turnAng k] singleLane

/-- `idle` (not_applicable): A car approaches an intersection on a highway whose approach has no right turn lane. -/
def idleTrace : Trace :=
  Build.trace 20 0 dt fun k t =>
    sceneOf t [mover (m 2, m 50) straightAng k] [hwy, throughLane none 1, junction, northExit]

/-- `blind` (unknown): A car enters the intersection from the single right turn lane and leaves it; the source declares kin.yaw_rate absent, so whether it turned right is not observed. -/
def blindTrace : Trace :=
  Build.trace 46 0 dt fun k t => sceneOf t [mover (m 6, m 53) turnAng k] singleLane

/-- `branch_1` (not_applicable): A car changes back out of the rightmost of two adjacent right turn lanes: the highway provides a dual, not a single, right turn lane. -/
def branch_1Trace : Trace :=
  Build.trace 40 0 dt fun k t =>
    sceneOf t [mover (m 10, m 34) leftChangeAng k]
      [hwy, throughLane (some 15) 3, rightTurnLane 15 4 (some 11) (some 16) 2 3,
       rightTurnLane 16 8 (some 15) none 3 3, junction]

/-- `branch_2` (violated): A car in the single right turn lane drives straight through the intersection and leaves it with its heading unchanged. -/
def branch_2Trace : Trace :=
  Build.trace 56 0 dt fun k t => sceneOf t [mover (m 6, m 53) straightAng k] singleLane

/-- `branch_3` (compliant): A car straddling the turn lane and the through lane leaves the turn
    lane into the intersection, its body still over the through lane's end, and turns right. -/
def branch_3Trace : Trace :=
  Build.trace 50 0 dt fun k t => sceneOf t [mover (cm 450, m 53) turnAng k] singleLane

/-- `branch_4` (compliant): A car in the single right turn lane turns off to the right into a side
    street before the intersection: it leaves the lane by turning right, not back to its left. -/
def branch_4Trace : Trace :=
  Build.trace 30 0 dt fun k t => sceneOf t [mover (m 6, m 34) sideTurnAng k] singleLane

/-- `branch_5` (violated): On a T-junction approach whose left lane is for left turns only, a car
    in the single right turn lane moves back into the left turn lane on its left short of the
    intersection: a turn lane beside it that is not a right turn lane leaves it single. -/
def branch_5Trace : Trace :=
  Build.trace 40 0 dt fun k t =>
    sceneOf t [mover (m 6, m 34) leftChangeAng k]
      [hwy, { throughLane (some 12) 2 with kind := .turnLane, turnSide := some .left },
       rightTurnLane 12 4 (some 11) none 2 2, junction]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_223_4a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, 100000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_223_4a
