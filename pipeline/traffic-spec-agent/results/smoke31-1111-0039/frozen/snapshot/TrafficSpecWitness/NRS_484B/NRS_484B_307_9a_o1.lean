/-
  Witnesses for NRS_484B_307_9a_o1.

  The geometry: an eastbound lane c (region 10) from x = -60 m to x = 0, y 0..4 m, direction
  east, entering intersection i (region 20), the square x 0..20 m, y -10..10 m. A stop line
  (region 30, x -3..-2.5 m) marks c (its entrances observed); in branch_7 a crosswalk (region 40,
  x -4..-1 m) marks c instead, and in branch_8 c has no mark. Signal s (device 50) governs c
  (in branch_5 the intersection i). x is track 1, its reference point at y = 1.75 m, moving at
  10 m/s, one scene every 50 ms (the step of the heading change). A straight passage from
  x = -20.25 m enters i at step 41 and leaves it at step 81; a left turn bends north at
  x = 8.25 m and leaves at step 74, a right turn bends south and leaves at step 81; inside i
  the yaw rate is +60 deg/s (left) or -60 deg/s (right), some 100 to 120 deg in all, against a
  45 deg recognition angle; a straight passage has a yaw rate of 0. Bodies: a bus 12 m by 2.5 m,
  a motorcycle 2 m by 0.8 m, a bicycle 2 m by 0.6 m. Each witness speaks from its second scene
  on (the first has no observation before it, on which an entry or an exit is unknown).

  The path is integrated from the yaw rate (3° per 50 ms step at 60 deg/s, for 30 steps from the
  first overlap of i), and occupancy is the footprint's: every region the body's rectangle
  overlaps, so at the entry the body lies on both c and i.

  branch_6: the motorcycle approaches at 5 m/s in 1 s steps, halts at x = -4.25 m (its front
  0.25 m short of the line) from 5 s to 604 s while the signal cycles every 60 s over a steady
  circular red (green left arrow 20 s, yellow left arrow 4 s, red alone 36 s: ten cycles), then
  crosses straight at 10 m/s in 50 ms steps under red with the green left arrow.
  branch_9: as branch_6 at the crosswalk, the motorcycle halted at x = -5.25 m.
  history_boundary: a motorcycle first seen at x = -5.25 m, its front 1.25 m short of the line.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def laneId : RegionId := 10
def interId : RegionId := 20
def lineId : RegionId := 30
def walkId : RegionId := 40
def sigId : DeviceId := 50

def laneC : Structure :=
  Build.lane laneId [(m (-60), m 0), (m 0, m 0), (m 0, m 4), (m (-60), m 4)] Build.east
    (enters := some interId)
def inter : Structure := Build.rect interId .intersection (m 0) (m (-10)) (m 20) (m 10)
def stopLine : Structure :=
  { Build.rect lineId .stopLine (cm (-300)) (m 0) (cm (-250)) (m 4) with
    entranceOf := [laneId], entranceObserved := true }
def crosswalk : Structure :=
  { Build.rect walkId .crosswalk (m (-4)) (m 0) (m (-1)) (m 4) with
    entranceOf := [laneId], entranceObserved := true, marked := some true }

def withLine : List Structure := [laneC, inter, stopLine]

def busBody : Q × Q × Q := (m 6, cm 125, cm 150)
def mcBody : Q × Q × Q := (m 1, cm 40, cm 70)
def bikeBody : Q × Q × Q := (m 1, cm 30, cm 90)

def redLeft : List SignalIndication := [.circularRed, .greenArrow .left]
def redRight : List SignalIndication := [.circularRed, .greenArrow .right]

/-- A state of x on its path: position (µm), heading (cos, sin scaled by 10⁶), yaw rate (deg/s). -/
structure St where
  x : Int
  y : Int
  c : Int
  s : Int
  yaw : Int

/-- cos 3°, sin 3° scaled by 10⁶: the turn over one 50 ms step at 60 deg/s. -/
def cos3 : Int := 998630
def sin3 : Int := 52336

/-- The heading turned by 3° to the left (`dir` = 1) or to the right (`dir` = -1). -/
def rot (dir c s : Int) : Int × Int :=
  ((c * cos3 - dir * s * sin3) / 1000000, (s * cos3 + dir * c * sin3) / 1000000)

/-- The path at 10 m/s in 50 ms steps from (`x0` µm, 1.75 m) heading east: from step `turnStart`
    the yaw rate is 60 deg/s to the side `dir` (0 straight) for 30 steps (90°); the rate and the
    velocity at a scene are held over the interval before it. -/
def path (x0 dir : Int) (turnStart n : Nat) : List St :=
  (List.range n).foldl (fun acc k =>
    match acc.getLast? with
    | none => acc ++ [{ x := x0, y := 1750000, c := 1000000, s := 0, yaw := 0 }]
    | some p =>
      let turning := dir != 0 && decide (turnStart ≤ k) && decide (k < turnStart + 30)
      let (c, s) := if turning then rot dir p.c p.s else (p.c, p.s)
      acc ++ [{ x := p.x + c / 2, y := p.y + s / 2, c := c, s := s, yaw := if turning then 60 * dir else 0 }]) []

def body (cls : List RoadUserClass) (half : Q × Q × Q) (p : Vec) (h : Vec) (spd yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 cls p h spd half) fun k => { k with yawRate := some yaw }

/-- A scene whose occupancy is the body's: every region its footprint overlaps. -/
def mkScene (t : Timestamp) (u : RoadUser) (structs : List Structure) (devs : List Device) : Scene :=
  let s0 := Build.scene t (some 1) [u] structs devs
  let occ : List (TrackId × RegionId) := match footprint s0 1 with
    | some fp => structs.filterMap fun st => match st.boundary with
        | some poly => if Geom.polygonsOverlap fp poly then some (1, st.id) else none
        | none => none
    | none => []
  { s0 with occupies := occ }

/-- A passage at 10 m/s in 50 ms steps. -/
def run (cls : List RoadUserClass) (half : Q × Q × Q) (x0 dir : Int) (turnStart : Nat)
    (structs : List Structure) (governs : List RegionId) (sh : List SignalIndication) (n : Nat) : Trace :=
  ((path x0 dir turnStart n).zip (List.range n)).map fun (p, k) =>
    mkScene (50 * Int.ofNat k)
      (body cls half (Units.micrometres p.x, Units.micrometres p.y)
        (Units.ratio p.c 1000000, Units.ratio p.s 1000000) (Units.metresPerSecond 10) (Units.degrees p.yaw))
      structs
      [Build.signal sigId governs sh]

def steps : Nat := 100
/-- The start (µm east) of every passage recorded from well upstream. -/
def x0 : Int := -20250000
/-- The step at which the body first overlaps i: a bus's front (6 m ahead), a short body's (1 m). -/
def busEntry : Nat := 29
def shortEntry : Nat := 39
def lastT (n : Nat) : Timestamp := 50 * (Int.ofNat n - 1)

/-- `forbid` (violated): x (ru.bus, a vehicle of no class paragraph (b) names), recorded from well upstream on lane c, whose entrance into intersection i is marked by a stop line (st.entrance_of observed, c's st.lane_direction observed), passes the stop line moving without ever halting and enters i while signal s governing c displays circular_red with green_arrow(left); x crosses i and leaves it with a heading change since entry well inside p.turn_recognition_angle (straight through). The exception fails on E2 (no halt; the search reaches the approach start), whatever x's class under paragraph (b). -/
def forbidTrace : Trace := run [.bus] busBody x0 0 busEntry withLine [laneId] redLeft steps

/-- `permit` (compliant): x (ru.bus), recorded from upstream, makes the same entry under circular_red with green_arrow(left) without halting; x leaves i with a heading change since entry above p.turn_recognition_angle to the left. -/
def permitTrace : Trace := run [.bus] busBody x0 1 busEntry withLine [laneId] redLeft steps

/-- `idle` (not_applicable): x (ru.bus): s displays circular_green at x's entry into i; x crosses straight through. -/
def idleTrace : Trace := run [.bus] busBody x0 0 busEntry withLine [laneId] [.circularGreen] steps

/-- `blind` (unknown): x (ru.bus), recorded from upstream on lane c with a stop line marking c, passes the line without halting, enters i and crosses straight through, but the source does not observe s's state at the entry. -/
def blindTrace : Trace := run [.bus] busBody x0 0 busEntry withLine [laneId] redLeft steps

/-- `branch_1` (violated): As forbid, but x is a ru.motorcycle (a vehicle, and a motorcycle under paragraph (b)): NRS_484B_307_9b_o1 applies, but x made no halt before the stop line, so paragraph (b)'s permission does not hold and this duty is judged: straight through under a left arrow is violated. Differs from forbid only in x's class. -/
def branch_1Trace : Trace := run [.motorcycle] mcBody x0 0 shortEntry withLine [laneId] redLeft steps

/-- `branch_2` (not_applicable): x is a ru.bicycle, a device moved by human power and so no vehicle: it is not vehicular traffic; it enters i under circular_red with green_arrow(left) and leaves after a left turn. -/
def branch_2Trace : Trace := run [.bicycle] bikeBody x0 1 shortEntry withLine [laneId] redLeft steps

/-- `branch_3` (violated): x (ru.bus), recorded from upstream, passes the stop line of lane c without halting, enters i under circular_red with green_arrow(right) on s governing c, and leaves i after a left turn (heading change above p.turn_recognition_angle to the left). -/
def branch_3Trace : Trace := run [.bus] busBody x0 1 busEntry withLine [laneId] redRight steps

/-- `branch_4` (compliant): x (ru.bus) enters i under circular_red with green_arrow(right) and leaves i after a right turn (heading change at most minus p.turn_recognition_angle). -/
def branch_4Trace : Trace := run [.bus] busBody x0 (-1) busEntry withLine [laneId] redRight steps

/-- `branch_5` (violated): s governs the intersection i itself, not the approach lane; it displays circular_red with green_arrow(left) at x's (ru.bus) entry; x, recorded from upstream, passed the stop line of its lane c without halting and crosses straight through. -/
def branch_5Trace : Trace := run [.bus] busBody x0 0 busEntry withLine [interId] redLeft steps

/-- A signal cycle of `period` s over the circular red: the green left arrow for `ga` s, the
    yellow left arrow up to `ya` s, then the red alone (second `k` of the recording). -/
def cycle (period ga ya : Nat) (k : Nat) : List SignalIndication :=
  if k % period < ga then redLeft
  else if k % period < ya then [.circularRed, .yellowArrow .left]
  else [.circularRed]

/-- A motorcycle approaching at 5 m/s in 1 s steps, halted 0.25 m short of the stop line for
    `wait` s while the signal shows `sh`, then crossing straight at 10 m/s in 50 ms steps under
    the red with the green left arrow. -/
def waitTrace (structs : List Structure) (haltX : Int) (wait : Nat) (sh : Nat → List SignalIndication) : Trace :=
  let waiting := (List.range (5 + wait)).map fun (k : Nat) =>
    let ki : Int := Int.ofNat k
    let x : Int := if k ≤ 4 then haltX - 2000 + 500 * ki else haltX
    let spd : Q := if k ≤ 4 then Units.metresPerSecond 5 else Q.zero
    mkScene (1000 * ki)
      (body [.motorcycle] mcBody (cm x, cm 175) Build.east spd Q.zero)
      structs
      [Build.signal sigId [laneId] (sh k)]
  let t0 : Int := 1000 * (4 + Int.ofNat wait)
  let going := (List.range 60).map fun (j : Nat) =>
    let ji : Int := Int.ofNat j + 1
    let x : Int := haltX + 50 * ji
    mkScene (t0 + 50 * ji)
      (body [.motorcycle] mcBody (cm x, cm 175) Build.east (Units.metresPerSecond 10) Q.zero)
      structs
      [Build.signal sigId [laneId] redLeft]
  waiting ++ going

def waitEnd (wait : Nat) : Timestamp := 1000 * (4 + Int.ofNat wait) + 50 * 60

/-- `branch_6` (not_applicable): As branch_1 (x a ru.motorcycle, straight through under a left arrow), but x halts on c at the stop line within p.stop_point_tolerance before it, then meets paragraph (b)'s further conditions as NRS_484B_307_9b_o2, NRS_484B_307_9b_o3 and NRS_484B_307_9b_o4 read them (it waits there through two complete cycles in which the signal does not change for it, no other device prohibits the movement, and no pedestrian or other road user is in the scene): the permission holds and this duty is not engaged. Differs from branch_1 only in the facts of paragraph (b)'s conditions. -/
def branch_6Trace : Trace := waitTrace withLine (-425) 600 (cycle 60 20 24)

/-- `history_boundary` (unknown): x (ru.bus) is first observed on lane c already inside the approach to i (past where its approach start would lie), moving; it passes the stop line without a recorded halt, enters i under circular_red with green_arrow(left) and crosses straight through. Whether a halt before the recording met condition (1) is undecided, and x's class under paragraph (b) is unresolved, so the exception is unknown. -/
-- Written with a ru.motorcycle, not the narrative's ru.bus: a bus's class under paragraph (b)
-- is unresolved, which leaves the exception unknown for `aggregate_unresolved`, a reason a
-- history-boundary witness may not carry; with a motorcycle (E1 decided) the exception turns on
-- the halt before the recording alone. First seen at x = -5.25 m, its front 1.25 m short of the
-- line: inside the stopping zone, so no approach start is recorded.
def history_boundaryTrace : Trace := run [.motorcycle] mcBody (-5250000) 0 0 withLine [laneId] redLeft 80

-- branch_7 (violated): as forbid, but c's entrance is marked by a crosswalk and no stop line;
-- x passes it without halting and crosses straight under a left arrow.
def branch_7Trace : Trace :=
  run [.bus] busBody x0 0 busEntry [laneC, inter, crosswalk] [laneId] redLeft steps

-- branch_8 (violated): as forbid, but c's entrance carries no mark (the place is the edge of i);
-- x enters without halting and crosses straight under a left arrow.
def branch_8Trace : Trace :=
  run [.bus] busBody x0 0 busEntry [laneC, inter] [laneId] redLeft steps

-- branch_9 (not_applicable): as branch_6, but c's entrance is marked by a crosswalk and no stop
-- line: the motorcycle halts at x = -5.25 m, its front 0.25 m short of the crosswalk and off it,
-- waits through the cycles, then crosses straight: paragraph (b)'s permission holds.
def branch_9Trace : Trace := waitTrace [laneC, inter, crosswalk] (-525) 600 (cycle 60 20 24)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") (upto : Timestamp := lastT steps) : Scenario :=
  { name := name
    rule := "NRS_484B_307_9a_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, upto)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable (upto := waitEnd 600)
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach start on lane c before x's entry into i, and any halt at the stop line before the recording began") (upto := lastT 80)
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .notApplicable (upto := waitEnd 600) ]

end TrafficSpecWitness.NRS_484B_307_9a_o1
