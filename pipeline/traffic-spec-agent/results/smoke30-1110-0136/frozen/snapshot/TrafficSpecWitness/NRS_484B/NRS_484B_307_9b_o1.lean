/-
  Witnesses for NRS_484B_307_9b_o1.

  Geometry (metres, +x east, +y north):
    approach lane 10   x ∈ [-60, 0],  y ∈ [-2, 2], eastbound, enters intersection 20
    intersection 20    x ∈ [0, 20],   y ∈ [-10, 10]
    exit lanes         30 east x ∈ [20, 80] y ∈ [-2, 2]; 31 north x ∈ [2, 8] y ∈ [10, 60];
                       32 south x ∈ [12, 18] y ∈ [-60, -10]
    stop line 40       x ∈ [-4, -3.5] across lane 10, recorded as marking lane 10's entrance
    crosswalk 41       x ∈ [-4, -1], y ∈ [-6, 6], recorded as marking lane 10 (branch_1 only)
    signal 50          governs lane 10 (the intersection in branch_5), shows circular_red with a
                       green arrow left or right throughout
  Road user 1: half-extents 1 m × 0.4 m × 0.7 m, 10 m/s (0.5 m per 50 ms scene), yaw rate 0 outside
  the intersection. Its progress `d` (cm) puts the reference point at x = 0.25 + d/100 on the lane's
  centre line before any turn. Occupancy is the body's footprint, so it enters the intersection at
  x = −0.75 (front edge past x = 0) and, inside, goes straight (out at x = 21.25), turns left at
  x = 5 (out at y = 11.25) or turns right at x = 15 (out at y = −11.25). Through the crossing the
  heading rotates by an equal step per scene and the yaw rate is the quarter turn over the crossing's
  duration, so the heading change since entry is 90° for a turn and 0° straight.
  A halt holds the reference point still with speed 0 for 20 scenes (1 s).
  The scenes are 50 ms apart, the reading's heading-integration step. Each witness speaks about every
  instant but the first (whose previous observation is not recorded).

  Halting places: at the stop line the reference point at x = −5.75 (body front −4.75, 0.75 m from the
  line, 1.75 m short of it); at the intersection x = −1.75 (front −0.75); past the stop line
  x = −2.25 (body 0.25 m from the line, the line 1.25 m behind the reference point). The approach start
  of the forbid trace lies at x = −20.25, 15.25 m from the line, beyond the 2 m tolerance; the
  history-boundary trace begins at x = −5.75, already within it.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- The movement through the intersection. -/
inductive Turn
  | straight
  | left
  | right

/-- Progress (cm) of the entry: the body's front touches the intersection's edge first at x = −0.75. -/
def entryAt : Int := -100

/-- Progress (cm) at which the body is out of the intersection. -/
def exitAt : Turn → Int
  | .straight => 2100
  | .left => 1600
  | .right => 2600

/-- Scenes from the entry to the exit. -/
def crossing (turn : Turn) : Int := (exitAt turn - entryAt) / 50

/-- Yaw rate over the crossing: a quarter turn spread over its scenes. -/
def turnRate : Turn → Q
  | .straight => Q.zero
  | .left => Q.div (Units.degrees 90) (Units.milliseconds (50 * crossing .left))
  | .right => Q.div (Units.degrees (-90)) (Units.milliseconds (50 * crossing .right))

/-- Heading at progress `d`: east before the entry, rotating by an equal step per scene through the
    crossing, north (left) or south (right) from the exit. -/
def heading (turn : Turn) (d : Int) : Vec :=
  let n := crossing turn
  let j := max 0 (min n ((d - entryAt) / 50))
  match turn with
  | .straight => Build.east
  | .left => (Q.ofInt (n - j), Q.ofInt j)
  | .right => (Q.ofInt (n - j), Q.ofInt (-j))

/-- Reference point at progress `d`. -/
def position (turn : Turn) (d : Int) : Vec :=
  match turn with
  | .straight => (cm (25 + d), Q.zero)
  | .left => if d ≤ 475 then (cm (25 + d), Q.zero) else (m 5, cm (d - 475))
  | .right => if d ≤ 1475 then (cm (25 + d), Q.zero) else (m 15, cm (1475 - d))

def lane10 : Structure :=
  Build.lane 10 [(m (-60), m (-2)), (m 0, m (-2)), (m 0, m 2), (m (-60), m 2)] Build.east (enters := some 20)
def junction : Structure := Build.rect 20 .intersection (m 0) (m (-10)) (m 20) (m 10)
def lane30 : Structure := Build.lane 30 [(m 20, m (-2)), (m 80, m (-2)), (m 80, m 2), (m 20, m 2)] Build.east
def lane31 : Structure := Build.lane 31 [(m 2, m 10), (m 8, m 10), (m 8, m 60), (m 2, m 60)] Build.north
def lane32 : Structure := Build.lane 32 [(m 12, m (-60)), (m 18, m (-60)), (m 18, m (-10)), (m 12, m (-10))] Build.south
def stopLine : Structure :=
  { Build.rect 40 .stopLine (m (-4)) (m (-2)) (cm (-350)) (m 2) with entranceOf := [10], entranceObserved := true }
def crosswalk : Structure :=
  { Build.rect 41 .crosswalk (m (-4)) (m (-6)) (m (-1)) (m 6) with entranceOf := [10], entranceObserved := true }

def roads : List Structure := [lane10, junction, lane30, lane31, lane32]

def redLeft (governs : List RegionId := [10]) : Device :=
  Build.signal 50 governs [.circularRed, .greenArrow .left]
def redRight (governs : List RegionId := [10]) : Device :=
  Build.signal 50 governs [.circularRed, .greenArrow .right]

/-- Scenes moved through by scene `k`, with a halt over scenes `[h0, h1)`. -/
def moved (halt : Option (Nat × Nat)) (k : Nat) : Nat :=
  match halt with
  | none => k
  | some (h0, h1) => if k ≤ h0 then k else if k < h1 then h0 else k - (h1 - h0)

def halted (halt : Option (Nat × Nat)) (k : Nat) : Bool :=
  match halt with
  | none => false
  | some (h0, h1) => decide (h0 ≤ k ∧ k < h1)

/-- A trace from progress `d0`: the approach, an optional halt, the entry and the movement, three
    scenes past the exit. -/
def run (classes : List RoadUserClass) (turn : Turn) (d0 : Int) (halt : Option (Nat × Nat))
    (structures : List Structure) (devices : List Device) : Trace :=
  let haltLen : Nat := match halt with | none => 0 | some (h0, h1) => h1 - h0
  let n : Nat := ((exitAt turn - d0) / 50).toNat + haltLen + 3
  Build.trace n 0 (Units.milliseconds 50) fun k t =>
    let d : Int := d0 + 50 * (moved halt k : Int)
    let speed : Q := if halted halt k then Q.zero else Units.metresPerSecond 10
    -- the rate at a scene is held over the interval before it
    let yaw : Q := if entryAt < d ∧ d ≤ exitAt turn then turnRate turn else Q.zero
    let u := Build.withKin (Build.user 1 classes (position turn d) (heading turn d) speed (m 1, cm 40, cm 70))
      fun kn => { kn with yawRate := some yaw }
    Build.scene t (some 1) [u] structures devices

/-- The instants a witness speaks about: every one but the first. -/
def window (τ : Trace) : Option (Timestamp × Timestamp) :=
  match τ.getLast? with
  | some s => some (50, s.t)
  | none => none

/-- `forbid` (violated): A motorcycle in an approach lane with a recorded stop line faces circular_red with green_arrow(left) from the approach start onwards, rolls across the stop line without halting, enters the intersection and leaves it with a heading change below the straight-through bound. -/
def forbidTrace : Trace :=
  run [.motorcycle] .straight (-2050) none (roads ++ [stopLine]) [redLeft]

/-- `permit` (compliant): The same motorcycle halts at the stop line within the stop-point tolerance, later enters and goes straight through. -/
def permitTrace : Trace :=
  run [.motorcycle] .straight (-2050) (some (29, 49)) (roads ++ [stopLine]) [redLeft]

/-- `idle` (not_applicable): A bicycle enters on circular_red with green_arrow(left) and makes a left turn through the intersection, the movement the arrow indicates. -/
def idleTrace : Trace :=
  run [.bicycle] .left (-2050) none (roads ++ [stopLine]) [redLeft]

/-- `blind` (unknown): A moped goes straight through on red with a green left arrow; the source supplies no speed, so whether it halted on the approach is unknown. -/
def blindTrace : Trace :=
  run [.moped] .straight (-2050) none (roads ++ [stopLine]) [redLeft]

/-- `history_boundary` (unknown): The recording begins with the road user already within the
    stopping zone of the stop line of its approach (0.75 m from it); it enters on red with a green
    right arrow and makes a left turn; no halt is recorded and neither the approach start nor a
    previous entry lies in the recording. The road user is a motorcycle, not the planned electric
    scooter: under the run's reading every electric scooter's class membership is unknown
    (DEF-NRS-484B-018::electric_scooter includes no class and leaves ru.electric_scooter
    unresolved), which would make this witness unknown for a reason other than the history. -/
def history_boundaryTrace : Trace :=
  run [.motorcycle] .left (-600) none (roads ++ [stopLine]) [redRight]

/-- `branch_1` (compliant): no stop line; the crosswalk recorded as marking the approach governs, and
    the motorcycle halts short of it within the tolerance, then goes straight through. -/
def branch_1Trace : Trace :=
  run [.motorcycle] .straight (-2050) (some (29, 49)) (roads ++ [crosswalk]) [redLeft]

/-- `branch_2` (compliant): neither stop line nor crosswalk; the motorcycle halts 0.75 m short of the
    intersection, then goes straight through. -/
def branch_2Trace : Trace :=
  run [.motorcycle] .straight (-2050) (some (37, 57)) roads [redLeft]

/-- `branch_3` (violated): on red with a green left arrow the motorcycle turns right, opposite the
    arrow, without halting at the stop line. -/
def branch_3Trace : Trace :=
  run [.motorcycle] .right (-2050) none (roads ++ [stopLine]) [redLeft]

/-- `branch_4` (compliant): on red with a green right arrow the motorcycle halts at the stop line and
    then turns left, opposite the arrow. -/
def branch_4Trace : Trace :=
  run [.motorcycle] .left (-2050) (some (29, 49)) (roads ++ [stopLine]) [redRight]

/-- `branch_5` (violated): the signal governs the intersection itself; the motorcycle goes straight
    through on red with a green left arrow without halting at the stop line. -/
def branch_5Trace : Trace :=
  run [.motorcycle] .straight (-2050) none (roads ++ [stopLine]) [redLeft [20]]

/-- `branch_6` (violated): the motorcycle halts past the stop line (the line 1.25 m behind its
    reference point, though its body is within the tolerance of it), then goes straight through. -/
def branch_6Trace : Trace :=
  run [.motorcycle] .straight (-2050) (some (36, 56)) (roads ++ [stopLine]) [redLeft]

/-- `branch_7` (violated): on red with a green right arrow the motorcycle turns left, opposite the
    arrow, without halting at the stop line. -/
def branch_7Trace : Trace :=
  run [.motorcycle] .left (-2050) none (roads ++ [stopLine]) [redRight]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window τ
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach start upstream of the stop line, which lies before the recording begins")
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_9b_o1
