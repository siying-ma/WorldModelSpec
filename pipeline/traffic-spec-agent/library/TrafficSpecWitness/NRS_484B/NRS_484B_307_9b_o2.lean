/-
  Witnesses for NRS_484B_307_9b_o2.

  Geometry (all witnesses): an eastbound approach lane 10 (x ∈ [-30, 0], y ∈ [-3, 3]) entering the
  intersection 20 (x ∈ [0, 12], y ∈ [-6, 6]); a traffic signal 100 governing lane 10 (branch_5:
  governing the intersection instead). Scenes every 50 ms (the acquisition step), x is track 1.
  k = 0, 1: x rolls along the lane at 5 m/s; from k = 2 it stands at (-2, 0), speed 0, until the
  entry index E; from E it is in the intersection for six scenes and leaves it at E + 6 (straight:
  eastwards; left turn: northwards; right turn: southwards, yaw rate ±300 deg/s from E to E + 6,
  the heading turned 15° per scene, 90 degrees between the entry and the exit; straight: yaw
  rate 0). The signal shows circular_red, with the
  green arrow lit at the listed scenes and from E on; the arrow is out otherwise.
  The window starts at the second scene: the first has no previous observation.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- The crossing: straight, a left turn, or a right turn. -/
inductive Path
  | straight | left | right

def laneA : Structure :=
  Build.lane 10 [(m (-30), m (-3)), (m 0, m (-3)), (m 0, m 3), (m (-30), m 3)] Build.east (enters := some 20)
def junction : Structure := Build.rect 20 .intersection (m 0) (m (-6)) (m 12) (m 6)

/-- Position of x at scene k for entry index e. -/
def posAt (p : Path) (e k : Nat) : Vec :=
  if k < 2 then (m (-8 + 3 * (k : Int)), m 0)
  else if k < e then (m (-2), m 0)
  else
    let j : Int := (k - e : Nat)
    match p with
    | .straight => (m (1 + 2 * j), m 0)
    | .left => if j < 6 then (m (1 + j), m j) else (m 6, m 9)
    | .right => if j < 6 then (m (1 + j), m (-j)) else (m 6, m (-9))

def speedAt (e k : Nat) : Q :=
  if k < 2 then Units.metresPerSecond 5 else if k < e then Q.zero else Units.metresPerSecond 5

/-- The yaw rate from the entry to the exit; the rate at a scene is held over the interval before it. -/
def yawAt (p : Path) (e k : Nat) : Q :=
  if k < e || k > e + 6 then Q.zero
  else match p with
    | .straight => Q.zero
    | .left => Units.degrees 300
    | .right => Units.degrees (-300)

/-- cos and sin of 15° · n, n ≤ 7, to four decimals. -/
def unitAt (n : Nat) : Vec :=
  let c : List Int := [10000, 9659, 8660, 7071, 5000, 2588, 0, -2588]
  let s : List Int := [0, 2588, 5000, 7071, 8660, 9659, 10000, 9659]
  (Units.ratio (c.getD n 0) 10000, Units.ratio (s.getD n 0) 10000)

/-- The heading, turned 15° per scene from the entry to the exit (the yaw rate integrated). -/
def headingAt (p : Path) (e k : Nat) : Vec :=
  if k < e then Build.east
  else
    let n := min k (e + 6) - e + 1
    match p with
    | .straight => Build.east
    | .left => unitAt n
    | .right => ((unitAt n).1, Q.neg (unitAt n).2)

/-- A witness trace: class of x, crossing, entry index, indications per scene, governed regions. -/
def mkTrace (cls : RoadUserClass) (p : Path) (e : Nat) (inds : Nat → List SignalIndication)
    (governs : List RegionId := [10]) : Trace :=
  Build.trace (e + 8) 0 (Units.milliseconds 50) fun k t =>
    let u := Build.withKin (Build.user 1 [cls] (posAt p e k) (headingAt p e k) (speedAt e k) (cm 100, cm 40, cm 70))
      (fun kin => { kin with yawRate := some (yawAt p e k) })
    Build.scene t (some 1) [u] [laneA, junction] [Build.signal 100 governs (inds k)]

/-- Steady red, the arrow of `dir` lit at the scenes `lit` and from the entry `e` on. -/
def redArrow (dir : ArrowDir) (lit : List Nat) (e : Nat) (k : Nat) : List SignalIndication :=
  if k ≥ e || lit.contains k then [.circularRed, .greenArrow dir] else [.circularRed]

def endMs (e : Nat) : Timestamp := ((e + 7) * 50 : Nat)

/-- `forbid` (violated): A motorcycle halts at the stop line of a lane governed by a signal showing circular_red with green_arrow(left); the left arrow lights and goes out once; the motorcycle then enters and goes straight through. -/
def forbidTrace : Trace := mkTrace .motorcycle .straight 12 (redArrow .left [4, 5] 12)

/-- `permit` (compliant): The motorcycle halts, the left arrow lights and goes out twice while the circular red stays on and no circular_green is ever shown, then it enters and goes straight through. -/
def permitTrace : Trace := mkTrace .motorcycle .straight 12 (redArrow .left [4, 5, 8, 9] 12)

/-- `idle` (not_applicable): A bicycle enters on circular_red with green_arrow(left) and turns left with the arrow. -/
def idleTrace : Trace := mkTrace .bicycle .left 12 (redArrow .left [4, 5, 8, 9] 12)

/-- `blind` (unknown): A moped waits and goes straight through; the source does not observe signal states. -/
def blindTrace : Trace := mkTrace .moped .straight 12 (redArrow .left [4, 5, 8, 9] 12)

/-- `branch_1` (violated): A bicycle halts, the signal shows circular_green once during its wait and returns to red with a left arrow; after two further arrow displays the bicycle goes straight through on red. -/
def branch_1Trace : Trace :=
  mkTrace .bicycle .straight 14 fun k =>
    if k == 3 || k == 4 then [.circularGreen] else redArrow .left [6, 7, 10, 11] 14 k

/-- `branch_2` (violated): A motorcycle halts while the left arrow is already lit; the arrow goes out, then lights and goes out once more; the motorcycle then goes straight through on red: only one arrow display both began and ended within its wait. -/
def branch_2Trace : Trace := mkTrace .motorcycle .straight 12 (redArrow .left [0, 1, 2, 3, 6, 7] 12)

/-- `branch_3` (compliant): A motorcycle waits through two displays of a right arrow on steady red, then turns left, opposite the arrow. -/
def branch_3Trace : Trace := mkTrace .motorcycle .left 12 (redArrow .right [4, 5, 8, 9] 12)

/-- `branch_4` (violated): A moped waits through one display of the left arrow, then turns right, opposite the arrow. -/
def branch_4Trace : Trace := mkTrace .moped .right 12 (redArrow .left [4, 5] 12)

/-- `branch_5` (violated): The signal governs the intersection itself; a motorcycle waits through one arrow display and goes straight through. -/
def branch_5Trace : Trace := mkTrace .motorcycle .straight 12 (redArrow .left [4, 5] 12) [20]

/-- `branch_6` (not_applicable): A motorcycle goes straight through when the signal shows circular_green with the left arrow, not a steady red. -/
def branch_6Trace : Trace :=
  mkTrace .motorcycle .straight 12 fun k =>
    if k ≥ 12 then [.circularGreen, .greenArrow .left] else redArrow .left [4, 5] 12 k

/-- `branch_7` (violated): A motorcycle waits through one display of a right arrow on steady red, then turns left, opposite the arrow. -/
def branch_7Trace : Trace := mkTrace .motorcycle .left 12 (redArrow .right [4, 5] 12)

def witness (name : String) (τ : Trace) (e : Nat) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, endMs e)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace 12 .violated
  , witness "permit" permitTrace 12 .compliant
  , witness "idle" idleTrace 12 .notApplicable
  , witness "blind" blindTrace 12 (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch_1Trace 14 .violated
  , witness "branch_2" branch_2Trace 12 .violated
  , witness "branch_3" branch_3Trace 12 .compliant
  , witness "branch_4" branch_4Trace 12 .violated
  , witness "branch_5" branch_5Trace 12 .violated
  , witness "branch_6" branch_6Trace 12 .notApplicable
  , witness "branch_7" branch_7Trace 12 .violated ]

end TrafficSpecWitness.NRS_484B_307_9b_o2
