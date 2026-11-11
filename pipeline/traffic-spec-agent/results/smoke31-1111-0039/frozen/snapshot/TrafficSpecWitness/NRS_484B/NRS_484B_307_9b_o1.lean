/-
  Witnesses for NRS_484B_307_9b_o1.

  The map (static): intersection i (region 1) is the rectangle x ∈ [0, 10] m, y ∈ [-6, 10] m. The
  approach lane c (region 10) runs east over x ∈ [-60, 0] m, y ∈ [0, 4] m and enters i. Its marks,
  per witness: a stop line (region 20) at x ∈ [-3, -2.5] m across c, recorded as marking c; or a
  crosswalk (region 21) at x ∈ [-4, -1] m, y ∈ [-6, 10] m, recorded as marking c; or none. The
  traffic signal s (device 30) governs c (or, in branch_5, i) and shows circular_red with
  green_arrow(left) (green_arrow(right) in branch_6; circular_green alone in idle).

  x (track 1) is 2 m long and 0.8 m wide (half-extents 1 m, 0.4 m), on the lane's centre line
  y = 2 m, heading east with zero yaw rate. Its approach is sampled at 1 s steps, k = 0 … 8, at
  5 m/s, ending at the point h where a rider that halts stands (speed 0 at k = 7 and 8). From
  t = 9 s the passage is sampled at 50 ms (the profile's step), at 10 m/s: its centre moves 0.5 m a
  step, so its body first overlaps i at centre -1 m and leaves it at centre 11.5 m. The halt points
  h: 5 m short of the stop line's centre (centre -5 m, front -4 m: 1 m from the line, the line 2 m
  ahead of the centre); centre -6.5 m before the crosswalk (1.5 m from it); centre -2.5 m before
  the intersection (1.5 m from it). A rider that does not halt is at h - 5 m at k = 7 (5.5 m or
  more from the place: the approach start) and passes h moving at k = 8.

  Turns (branch_5, branch_6): from centre x = 3 m inside i the heading turns by 9° per 50 ms step
  for ten steps (yaw rate ∓180 °/s, 90° in all), then x runs south (north) out of i.

  Against the reading: p.speed_resolution 0.2 m/s (halted at 0, moving at 5 and 10 m/s),
  p.stop_point_tolerance 2 m (halts at 1-1.5 m, approach starts at 5.5 m or more),
  p.turn_recognition_angle 45° (straight: 0°, turns: 90°), step 50 ms (the passage's sampling).
  Occupancy is the body's (footprint overlap), as the admission derives it.
  Each witness speaks about the instants from t = 1 s on (`window`): at the first observation no
  entry or leaving can be read.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def junction : Structure := Build.rect 1 .intersection (m 0) (m (-6)) (m 10) (m 10)
def approachLane : Structure := Build.lane 10 (box (m (-60)) (m 0) (m 0) (m 4)) Build.east (enters := some 1)
def stopLine : Structure :=
  { Build.rect 20 .stopLine (cm (-300)) (m 0) (cm (-250)) (m 4) with
    entranceOf := [10], entranceObserved := true }
def crosswalk : Structure :=
  { Build.rect 21 .crosswalk (m (-4)) (m (-6)) (m (-1)) (m 10) with
    marked := some true, entranceOf := [10], entranceObserved := true }

def redWith (arrow : ArrowDir) (governs : List RegionId) : Device :=
  Build.signal 30 governs [.circularRed, .greenArrow arrow]
def greenOnly : Device := Build.signal 30 [10] [.circularGreen]

def rider (cls : RoadUserClass) (pos heading : Vec) (speed yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [cls] pos heading speed (m 1, cm 40, cm 60))
    fun k => { k with yawRate := some yaw }

/-- The approach, k = 0 … 8 at 1 s steps, ending at the halt point `h`. -/
def approachAt (cls : RoadUserClass) (h : Q) (halts : Bool) (k : Nat) : RoadUser :=
  let lag : Int := if halts then (if k ≥ 7 then 0 else 7 - (k : Int)) else 8 - (k : Int)
  let speed := if halts && k ≥ 7 then Q.zero else Units.metresPerSecond 5
  rider cls (Q.sub h (m (5 * lag)), m 2) Build.east speed Q.zero

/-- The passage at 50 ms steps from `h`: straight (`turn = 0`), or turning right (`-1`) or left
    (`1`) between steps 16 and 25 (for `h` = -5 m the turn starts at centre x = 3 m). -/
def passAt (cls : RoadUserClass) (h : Q) (turn : Int) (j : Nat) : RoadUser :=
  let ji : Int := j
  let speed := Units.metresPerSecond 10
  if turn == 0 || j ≤ 15 then
    rider cls (Q.add h (cm (50 * (ji + 1))), m 2) Build.east speed Q.zero
  else if j ≤ 25 then
    let s := ji - 15
    rider cls (Q.add (m 3) (cm (50 * s)), Q.add (m 2) (cm (50 * turn * s)))
      (Q.ofInt (10 - s), Q.ofInt (turn * s)) speed (Units.degrees (180 * turn))
  else
    rider cls (m 8, Q.add (m (2 + 5 * turn)) (cm (50 * turn * (ji - 25))))
      (Q.zero, Q.ofInt turn) speed Q.zero

/-- A scene whose occupancy is the body's: every region x's footprint overlaps (closed sets), so
    a body across the lane's end and the intersection occupies both. -/
def sceneOf (marks : List Structure) (signal : Device) (u : RoadUser) (t : Timestamp) : Scene :=
  let s := Build.scene t (some 1) [u] ([junction, approachLane] ++ marks) [signal]
  let body := s.structures.filterMap fun st =>
    match footprint s 1, st.boundary with
    | some fp, some poly => if Geom.polygonsOverlap fp poly then some ((1 : TrackId), st.id) else none
    | _, _ => none
  Build.scene t (some 1) [u] ([junction, approachLane] ++ marks) [signal] (occupies := some body)

def run (cls : RoadUserClass) (marks : List Structure) (signal : Device) (h : Q) (halts : Bool)
    (turn : Int) (steps : Nat) : Trace :=
  Build.trace 9 0 (Units.seconds 1) (fun k t => sceneOf marks signal (approachAt cls h halts k) t)
  ++ Build.trace steps 9000 (Units.milliseconds 50) (fun j t => sceneOf marks signal (passAt cls h turn j) t)

/-- `forbid` (violated): x (ru.motorcycle) is first recorded far upstream on lane c, which a stop line marks (st.entrance_of); it never halts on c, enters i while s governing c displays circular_red with green_arrow(left), and leaves straight through. The search back from the entry reaches the approach start without a halt. -/
def forbidTrace : Trace := run .motorcycle [stopLine] (redWith .left [10]) (m (-5)) false 0 36

/-- `permit` (compliant): x (ru.bicycle), first recorded far upstream on c, halts on c within p.stop_point_tolerance of the stop line marking c, short of it, then enters i under circular_red with green_arrow(left) and leaves straight through. -/
def permitTrace : Trace := run .bicycle [stopLine] (redWith .left [10]) (m (-5)) true 0 36

/-- `idle` (not_applicable): x (ru.motorcycle) enters i while s displays circular_green and leaves straight through. -/
def idleTrace : Trace := run .motorcycle [stopLine] greenOnly (m (-5)) false 0 36

/-- `blind` (unknown): x, first recorded far upstream on c, halts on c short of a stop line within p.stop_point_tolerance and then goes straight through under circular_red with green_arrow(left), but the source does not observe which carriers the line marks, so whether the halt was at the governing place is unknown. -/
def blindTrace : Trace := run .bicycle [stopLine] (redWith .left [10]) (m (-5)) true 0 36

/-- `history_boundary` (unknown): x's recording begins with x already on c inside the stopping zone of the stop line, rolling slowly; no halt is recorded before it enters i under circular_red with green_arrow(left) and leaves straight through. The search reaches neither the approach start nor a previous entry. -/
def history_boundaryTrace : Trace :=
  Build.trace 36 0 (Units.milliseconds 50)
    (fun j t => sceneOf [stopLine] (redWith .left [10]) (passAt .motorcycle (m (-5)) 0 j) t)

/-- `branch_1` (compliant): only a crosswalk marks c; x (ru.moped) halts 1.5 m short of it, off it,
    then goes straight through under circular_red with green_arrow(left). -/
def branch_1Trace : Trace := run .moped [crosswalk] (redWith .left [10]) (cm (-650)) true 0 39

/-- `branch_2` (violated): only a crosswalk marks c; x (ru.moped) never halts before it. -/
def branch_2Trace : Trace := run .moped [crosswalk] (redWith .left [10]) (cm (-650)) false 0 39

/-- `branch_3` (compliant): c has no mark; x (ru.bicycle) halts 1.5 m short of the intersection. -/
def branch_3Trace : Trace := run .bicycle [] (redWith .left [10]) (cm (-250)) true 0 31

/-- `branch_4` (violated): c has no mark; x (ru.bicycle) never halts before the intersection. -/
def branch_4Trace : Trace := run .bicycle [] (redWith .left [10]) (cm (-250)) false 0 31

/-- `branch_5` (violated): s governs the intersection itself and shows circular_red with
    green_arrow(left); x (ru.motorcycle) turns right (opposite the arrow) without halting at the
    stop line. -/
def branch_5Trace : Trace := run .motorcycle [stopLine] (redWith .left [1]) (m (-5)) false (-1) 38

/-- `branch_6` (violated): s governing c shows circular_red with green_arrow(right); x
    (ru.motorcycle) turns left (opposite the arrow) without halting at the stop line. -/
def branch_6Trace : Trace := run .motorcycle [stopLine] (redWith .right [10]) (m (-5)) false 1 38

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") (from_ : Timestamp := 1000) : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (from_, 60000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.entrance_of"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the start of x's approach on c, outside the stop line's stopping zone upstream, which lies before the recording") (from_ := 50)
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_9b_o1
