/-
  Witnesses for NRS_484B_307_9b.

  Geometry (metres, +x east, +y north). Intersection i (10): the square x −10…10, y −10…10.
  Approach lane c (11): x 0…4, y −60…−10, direction north, entering i. Stop line (12): x 0…4,
  y −11…−10.5, recorded as marking c. Opposite approach lane (13): x −4…0, y 10…60, direction
  south, entering i; north crosswalk (14): x −10…10, y 11…14, recorded as marking lane 13.
  Branch scenes add a south crosswalk (16, y −14…−11, marking c) or remove the marks, or add a
  second northbound approach lane c2 (15, x 4…8) governed by its own head (31, circular_green).
  The head (30) governs c and shows the display of each scene; a regulatory sign (32) governs c or i.

  The motorcycle (track 1; half-extents 1 × 0.4 m) rides at x = 2 heading north. Every scene is
  sampled at 50 ms (the step bound of the turn concepts), so the integration of the yaw rate
  (observed, zero when straight) is defined across the passage. Occupancy is stated from the body
  rectangle (a body across c and i at its entry overlaps both).
  Halting scenes: approach at 4 m/s from 5 m behind the halt point (the first frames are the
  approach start: the body is more than 2 m short of the mark), at rest from frame 25 to 45 with
  its front 1.25 m short of the mark, then 10 m/s: entry at frame 50, straight exit at frame 94.
  Non-halting scenes: 10 m/s from y = −25. Display cycles: red alone, then red with the arrow from
  frame 30, red alone from 35, red with the arrow from 40 (two rises during the wait); the forbid
  display rises once (frame 30). Turning scenes: from frame 60 a quarter-circle arc of radius 20/π m
  over 20 intervals (yaw rate ±90 deg/s, heading rotated 4.5° per interval, sin/cos to six
  decimals), then straight east (right turn, exit at frame 86) or west (left turn, exit at frame 94).
  Pedestrians and the car are built with Build.user; their occupancy is stated the same way.
  Each witness speaks about the instants from 50 ms on: the first observation has no previous one,
  so its entries and exits are not decided.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mm (n : Int) : Q := Units.millimetres n
def qk (k : Nat) : Q := Q.ofInt (Int.ofNat k)

-- Binders ↦ tracks: subject ↦ 1

-- ---------------------------------------------------------------------------------------------
-- Occupancy from body rectangles
-- ---------------------------------------------------------------------------------------------
structure Box where
  x0 : Q
  y0 : Q
  x1 : Q
  y1 : Q

def overlaps (a b : Box) : Bool :=
  Q.lt a.x0 b.x1 && Q.lt b.x0 a.x1 && Q.lt a.y0 b.y1 && Q.lt b.y0 a.y1

def bbox (poly : List Vec) : Box :=
  match poly with
  | [] => ⟨Q.zero, Q.zero, Q.zero, Q.zero⟩
  | p :: ps => ps.foldl (fun b q => ⟨Q.min b.x0 q.1, Q.min b.y0 q.2, Q.max b.x1 q.1, Q.max b.y1 q.2⟩)
      ⟨p.1, p.2, p.1, p.2⟩

/-- The body rectangle of a user heading along an axis. -/
def userBox (u : RoadUser) : Option Box := do
  let p ← u.kin.position
  let h ← u.kin.heading
  let (hl, hw, _) ← u.kin.extent
  let diag := !(Q.isZero h.1) && !(Q.isZero h.2)
  let ax := if diag then hl else if Q.isZero h.1 then hw else hl
  let ay := if diag then hl else if Q.isZero h.1 then hl else hw
  pure ⟨Q.sub p.1 ax, Q.sub p.2 ay, Q.add p.1 ax, Q.add p.2 ay⟩

def occupancy (users : List RoadUser) (structs : List Structure) : List (TrackId × RegionId) :=
  users.flatMap fun u =>
    match userBox u with
    | none => []
    | some b => structs.filterMap fun st =>
        match st.boundary with
        | some poly => if overlaps b (bbox poly) then some (u.track, st.id) else none
        | none => none

-- ---------------------------------------------------------------------------------------------
-- Structures and devices
-- ---------------------------------------------------------------------------------------------
def rectPts (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def interS : Structure := Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def laneC : Structure := Build.lane 11 (rectPts (m 0) (m (-60)) (m 4) (m (-10))) Build.north (enters := some 10)
def stopLineS : Structure :=
  { Build.rect 12 .stopLine (m 0) (m (-11)) (m 4) (cm (-1050)) with entranceOf := [11], entranceObserved := true }
def laneOpp : Structure := Build.lane 13 (rectPts (m (-4)) (m 10) (m 0) (m 60)) Build.south (enters := some 10)
def cwNorth : Structure :=
  { Build.rect 14 .crosswalk (m (-10)) (m 11) (m 10) (m 14) with
    entranceOf := [13], entranceObserved := true, marked := some true }
def laneC2 : Structure := Build.lane 15 (rectPts (m 4) (m (-60)) (m 8) (m (-10))) Build.north (enters := some 10)
def cwSouth : Structure :=
  { Build.rect 16 .crosswalk (m (-10)) (m (-14)) (m 10) (m (-11)) with
    entranceOf := [11], entranceObserved := true, marked := some true }

/-- A stop line on the opposite lane, marking that lane only. -/
def stopLineOpp : Structure :=
  { Build.rect 17 .stopLine (m (-4)) (cm 1450) (m 0) (m 15) with entranceOf := [13], entranceObserved := true }

def baseStructs : List Structure := [interS, laneC, stopLineS, laneOpp, cwNorth]
def cwStructs : List Structure := [interS, laneC, laneOpp, cwNorth, cwSouth]
def noMarkStructs : List Structure := [interS, laneC, laneOpp, cwNorth, stopLineOpp]

def head2 : Device := Build.signal 31 [15] [.circularGreen]
def turnSign (code : SignCode) (gov : List RegionId) : Device :=
  { Build.sign 32 .regulatorySign gov with code := some code, conditions := some {} }

-- ---------------------------------------------------------------------------------------------
-- Displays
-- ---------------------------------------------------------------------------------------------
def steady (dir : ArrowDir) : List SignalIndication := [.circularRed, .greenArrow dir]
/-- Two rises of red-with-arrow during the wait (frames 30 and 40). -/
def dispCycles (dir : ArrowDir) (k : Nat) : List SignalIndication :=
  if k < 30 then [.circularRed] else if k < 35 then steady dir
  else if k < 40 then [.circularRed] else steady dir
/-- One rise only (frame 30). -/
def dispOnce (k : Nat) : List SignalIndication :=
  if k < 30 then [.circularRed] else steady .left
/-- Two rises, but circular_green for frames 35–37 of the wait. -/
def dispGreenInWait (k : Nat) : List SignalIndication :=
  if k < 30 then [.circularRed] else if k < 35 then steady .left
  else if k < 38 then [.circularGreen] else if k < 40 then [.circularRed] else steady .left

-- ---------------------------------------------------------------------------------------------
-- Motion profiles: distance travelled and speed by frame
-- ---------------------------------------------------------------------------------------------
def profHalt (kh kg : Nat) (k : Nat) : Q :=
  if k ≤ kh then Q.mul (cm 20) (qk k)
  else if k ≤ kg then Q.mul (cm 20) (qk kh)
  else Q.add (Q.mul (cm 20) (qk kh)) (Q.mul (cm 50) (qk (k - kg)))
def speedHalt (kh kg : Nat) (k : Nat) : Q :=
  if k < kh then Units.metresPerSecond 4 else if k ≤ kg then Q.zero else Units.metresPerSecond 10
def profConst (k : Nat) : Q := Q.mul (cm 50) (qk k)
def speedConst (_k : Nat) : Q := Units.metresPerSecond 10
def profSlow (ks : Nat) (k : Nat) : Q :=
  if k ≤ ks then Q.mul (mm 25) (qk k) else Q.add (Q.mul (mm 25) (qk ks)) (Q.mul (cm 50) (qk (k - ks)))
def speedSlow (ks : Nat) (k : Nat) : Q :=
  if k < ks then cm 50 else Units.metresPerSecond 10

-- ---------------------------------------------------------------------------------------------
-- A scene configuration
-- ---------------------------------------------------------------------------------------------
structure Cfg where
  n : Nat := 100
  yStart : Q
  dist : Nat → Q
  speed : Nat → Q
  /-- 0 straight, 1 left, −1 right: a quarter-circle arc at 10 m/s over the 20 intervals after
      frame `kTurn` (yaw rate ±90 deg/s, held over the interval before each scene), then straight. -/
  turn : Int := 0
  kTurn : Nat := 60
  /-- Lane change to x = 6 (lane c2) once the reference point reaches this y. -/
  xShiftY : Option Q := none
  display : Nat → List SignalIndication
  headGov : List RegionId := [11]
  withHead2 : Bool := false
  sign : Option Device := none
  extraDevs : List Device := []
  structs : List Structure := baseStructs
  others : Nat → List RoadUser := fun _ => []
  subjClasses : List RoadUserClass := [.motorcycle]

/-- sin and cos of 4.5·j degrees, j = 0…20, to six decimals. -/
def sinTab : List Int :=
  [0, 78459, 156434, 233445, 309017, 382683, 453990, 522499, 587785, 649448, 707107,
   760406, 809017, 852640, 891007, 923880, 951057, 972370, 987688, 996917, 1000000]
def sinQ (j : Nat) : Q := Units.ratio (sinTab.getD j 0) 1000000
def cosQ (j : Nat) : Q := Units.ratio (sinTab.getD (20 - j) 0) 1000000
/-- The arc radius: 0.5 m per 4.5° interval, 20/π m. -/
def radius : Q := Units.micrometres 6366198

def subjectAt (c : Cfg) (k : Nat) : RoadUser :=
  let x0 : Q := match c.xShiftY with
    | some ys => if Q.le ys (Q.add c.yStart (c.dist k)) then m 6 else m 2
    | none => m 2
  let yA := Q.add c.yStart (c.dist c.kTurn)
  let left : Bool := decide (c.turn > 0)
  let sgn : Q := if left then Q.ofInt (-1) else Q.ofInt 1   -- +x for a right turn
  let (pos, hd) : Vec × Vec :=
    if c.turn == 0 || decide (k ≤ c.kTurn) then ((x0, Q.add c.yStart (c.dist k)), Build.north)
    else if k ≤ c.kTurn + 20 then
      let j := k - c.kTurn
      ((Q.add x0 (Q.mul sgn (Q.sub radius (Q.mul radius (cosQ j)))), Q.add yA (Q.mul radius (sinQ j))),
       (Q.mul sgn (sinQ j), cosQ j))
    else
      let e := Q.mul (cm 50) (qk (k - c.kTurn - 20))
      ((Q.add x0 (Q.mul sgn (Q.add radius e)), Q.add yA radius), if left then Build.west else Build.east)
  let yaw : Q :=
    if c.turn != 0 && decide (c.kTurn < k) && decide (k ≤ c.kTurn + 20) then
      (if left then Units.degrees 90 else Units.degrees (-90))
    else Q.zero
  Build.withKin (Build.user 1 c.subjClasses pos hd (c.speed k) (m 1, cm 40, cm 70))
    fun kin => { kin with yawRate := some yaw }

def sceneAt (c : Cfg) (k : Nat) (t : Timestamp) : Scene :=
  let users := subjectAt c k :: c.others k
  let devs := [Build.signal 30 c.headGov (c.display k)] ++ (if c.withHead2 then [head2] else []) ++
    c.sign.toList ++ c.extraDevs
  Build.scene t (some 1) users c.structs devs (occupies := some (occupancy users c.structs))

def traceOf (c : Cfg) : Trace := Build.trace c.n 0 (Units.milliseconds 50) (sceneAt c)
def windowOf (c : Cfg) : Option (Timestamp × Timestamp) := some (50, Int.ofNat ((c.n - 1) * 50))

-- ---------------------------------------------------------------------------------------------
-- Other road users
-- ---------------------------------------------------------------------------------------------
def ped (pos : Vec) (hd : Vec) (v : Q) : RoadUser := Build.user 2 [.pedestrian] pos hd v (cm 30, cm 30, cm 90)
def car (x : Q) : RoadUser := Build.user 3 [.motorVehicle] (x, m 3) Build.east (Units.metresPerSecond 8) (cm 225, m 1, cm 75)

/-- Standing in the north crosswalk (marking the opposite lane), 2 m left of the motorcycle's line. -/
def pedStanding (_k : Nat) : List RoadUser := [ped (m 0, cm 1250) Build.west Q.zero]
/-- North of the crosswalk until frame 50, then walking south at 1.5 m/s into it (from frame 67),
    1.5 m right of the motorcycle's line. -/
def pedCrossing (k : Nat) : List RoadUser :=
  if k ≤ 50 then [ped (cm 350, cm 1550) Build.south Q.zero]
  else [ped (cm 350, Q.sub (cm 1550) (Q.mul (mm 75) (qk (k - 50)))) Build.south (cm 150)]
/-- In the north crosswalk at the start, walking west at 1.5 m/s; off it from frame 35. -/
def pedLeaving (k : Nat) : List RoadUser :=
  [ped (Q.sub (m (-8)) (Q.mul (mm 75) (qk k)), cm 1250) Build.west (cm 150)]
/-- Eastbound at y = 3, 8 m/s, entering i at frame 51 on a course whose centre miss distance with
    the motorcycle is 2.7 m. -/
def carConflict (k : Nat) : List RoadUser := [car (Q.add (cm (-1250)) (Q.mul (cm 40) (Q.sub (qk k) (qk 50))))]
/-- Eastbound at y = 3, out of i from frame 44. -/
def carGone (k : Nat) : List RoadUser := [car (Q.add (m (-5)) (Q.mul (cm 40) (qk k)))]
/-- Eastbound at y = 3, already past the motorcycle's line at its entry and moving away; in i until frame 70. -/
def carAhead (k : Nat) : List RoadUser := [car (Q.add (m 4) (Q.mul (cm 40) (Q.sub (qk k) (qk 50))))]

-- ---------------------------------------------------------------------------------------------
-- Configurations
-- ---------------------------------------------------------------------------------------------
def permitCfg : Cfg :=
  { yStart := cm (-1825), dist := profHalt 25 45, speed := speedHalt 25 45, display := dispCycles .left }
def forbidCfg : Cfg := { permitCfg with display := dispOnce }
def runCfg : Cfg :=
  { yStart := m (-25), dist := profConst, speed := speedConst, display := fun _ => steady .left }

/-- `forbid` (violated): A motorcycle (ru.aggregate motorcycle) occupies approach lane c entering i, with a stop line recorded as marking c; the head governing c displays circular_red with green_arrow(left). The motorcycle halts at the stop line, waits while the red-with-arrow display comes on again once only, then enters i and exits straight ahead (no turn concept holds). No pedestrian or other road user is present. -/
def forbidTrace : Trace := traceOf forbidCfg

/-- `permit` (compliant): As in forbid, but the motorcycle remains at rest at the stop line while the red-with-arrow display rises twice, the head never displays circular_green, and it then proceeds straight through i. No other road user is in the scene, so the yield is decided on the subject alone. -/
def permitTrace : Trace := traceOf permitCfg

/-- `idle` (not_applicable): The head governing c displays circular_green at the motorcycle's entry; it proceeds straight through. -/
def idleCfg : Cfg := { runCfg with display := fun _ => [.circularGreen] }
def idleTrace : Trace := traceOf idleCfg

/-- `blind` (unknown): As in forbid, but the state of the head governing c is never observed (dev.traffic_signal absent). -/
def blindTrace : Trace := traceOf forbidCfg

/-- `history_boundary` (unknown): The recording begins with the motorcycle already within the stop line's stopping zone on c, moving slowly, under red with green_arrow(left); it enters i and exits straight. No halt is recorded, the approach start and any earlier wait lie before the recording, and no earlier entry into i is recorded. -/
def historyCfg : Cfg :=
  { yStart := cm (-1325), dist := profSlow 20, speed := speedSlow 20, display := fun _ => steady .left }
def history_boundaryTrace : Trace := traceOf historyCfg

/-- `branch_1` (violated): As in permit, but the motorcycle turns right (opposite the left arrow; drv.motion.right_turn_through_region at the exit) while a dev.regulatory_sign with code no_right_turn governs c. -/
def branch1Cfg : Cfg := { permitCfg with turn := -1, sign := some (turnSign .noRightTurn [11]) }
def branch_1Trace : Trace := traceOf branch1Cfg

/-- `branch_2` (violated): As in permit, but a pedestrian occupies the crosswalk recorded as marking the entrance of the opposite carrier; the moving motorcycle's closest approach to it lies within the horizon at a centre distance below the clearance. -/
def branch2Cfg : Cfg := { permitCfg with others := pedStanding }
def branch_2Trace : Trace := traceOf branch2Cfg

/-- `branch_3` (compliant): As in permit, but a car crossing i eastbound is already past the
    motorcycle's line at its entry and moving away: no closest approach ahead below the clearance,
    no contact. -/
def branch3Cfg : Cfg := { permitCfg with others := carAhead }

/-- `branch_4` (violated): The head shows circular_red with green_arrow(right); the motorcycle waits
    two cycles, turns left (opposite the arrow) while a no_left_turn sign governs i. -/
def branch4Cfg : Cfg :=
  { permitCfg with display := dispCycles .right, turn := 1, sign := some (turnSign .noLeftTurn [10]) }

/-- `branch_5` (violated): As in permit, but the head shows circular_green for part of the wait (the
    signal changed for the waiting motorcycle); red with the arrow again at the entry. -/
def branch5Cfg : Cfg := { permitCfg with display := dispGreenInWait }

/-- `branch_6` (compliant): No stop line; a crosswalk recorded as marking c; the motorcycle halts
    1.25 m short of it, waits two cycles and proceeds straight. -/
def branch6Cfg : Cfg :=
  { permitCfg with yStart := cm (-2125), n := 110, structs := cwStructs }

/-- `branch_7` (compliant): No stop line or crosswalk marks c (the crosswalk and the stop line
    present mark the opposite lane); the motorcycle halts 1.25 m short of i, waits two cycles and
    proceeds. -/
def branch7Cfg : Cfg := { permitCfg with yStart := cm (-1725), structs := noMarkStructs }

/-- `branch_8` (violated): No mark of c; the motorcycle rides into i without halting. -/
def branch8Cfg : Cfg := { runCfg with structs := noMarkStructs }

/-- `branch_9` (violated): As branch_6 (halt before the crosswalk marking c), but the display rises
    once only during the wait. -/
def branch9Cfg : Cfg := { branch6Cfg with display := dispOnce }

/-- `branch_10` (violated): The crosswalk marks c; the motorcycle rides into i without halting. -/
def branch10Cfg : Cfg := { runCfg with structs := cwStructs }

/-- `branch_11` (violated): As branch_7 (halt at i's edge, no mark of c), but the display rises once
    only during the wait. -/
def branch11Cfg : Cfg := { branch7Cfg with display := dispOnce }

/-- `branch_12` (compliant): As permit, but the motorcycle turns right (opposite the left arrow); a
    no_right_turn sign governs only the opposite lane. -/
def branch12Cfg : Cfg := { permitCfg with turn := -1, sign := some (turnSign .noRightTurn [13]) }

/-- `branch_13` (compliant): The head shows red with green_arrow(right), rising twice during the
    wait; the motorcycle turns left (opposite the arrow); a no_left_turn sign governs only the
    opposite lane. -/
def branch13Cfg : Cfg :=
  { permitCfg with display := dispCycles .right, turn := 1, sign := some (turnSign .noLeftTurn [13]) }

/-- `branch_14` (compliant): As permit, with a second head governing only the opposite lane,
    showing red with the left arrow throughout. -/
def branch14Cfg : Cfg := { permitCfg with extraDevs := [Build.signal 33 [13] (steady .left)] }

/-- `branch_15` (not_applicable): As permit, but the road user carries none of the named classes. -/
def branch15Cfg : Cfg := { permitCfg with subjClasses := [] }

/-- `occasion_s1` (violated): The head displays circular_red with green_arrow(left) at the motorcycle's entry into i, made without any halt; it changes to circular_green while the motorcycle is in i; it exits straight ahead. -/
def occS1Cfg : Cfg := { runCfg with display := fun k => if k < 40 then steady .left else [.circularGreen] }
def occasion_s1Trace : Trace := traceOf occS1Cfg

/-- `occasion_s1_outside` (not_applicable): The head displays red with the green arrow while the motorcycle approaches, and circular_green from before its entry into i; it proceeds straight without halting. -/
def occS1OutCfg : Cfg := { runCfg with display := fun k => if k < 20 then steady .left else [.circularGreen] }
def occasion_s1_outsideTrace : Trace := traceOf occS1OutCfg

/-- `occasion_s3` (violated): At its entry the motorcycle's footprint overlaps c (governed by the red-with-arrow head) and i; afterwards only i; it did not halt and exits straight. -/
def occasion_s3Trace : Trace := traceOf runCfg

/-- `occasion_s3_outside` (not_applicable): The motorcycle occupied c while c's head showed red with the green arrow, then moved into an adjacent approach lane c2 whose governing head displays circular_green, and entered i from c2 only, exiting straight. -/
def occS3OutCfg : Cfg :=
  { runCfg with xShiftY := some (m (-20)), withHead2 := true, structs := baseStructs ++ [laneC2]
                display := fun _ => [.circularRed, .greenArrow .left, .greenArrow .right] }
def occasion_s3_outsideTrace : Trace := traceOf occS3OutCfg

/-- `occasion_s8` (violated): As in permit, but for part of the passage a pedestrian occupies a crosswalk of i on a converging course; the moving motorcycle's closest approach to it lies within the horizon below the clearance while the pedestrian is in the crosswalk. -/
def occS8Cfg : Cfg := { permitCfg with others := pedCrossing }
def occasion_s8Trace : Trace := traceOf occS8Cfg

/-- `occasion_s8_outside` (compliant): As in permit, but a pedestrian occupied a crosswalk of i only before the motorcycle's entry and has left it before the entry; no other road user is present during the passage. -/
def occS8OutCfg : Cfg := { permitCfg with others := pedLeaving }
def occasion_s8_outsideTrace : Trace := traceOf occS8OutCfg

/-- `occasion_s9` (violated): As in permit, but for part of the passage another car occupies i on a converging course; the moving motorcycle's closest approach to it lies within the horizon below the clearance. -/
def occS9Cfg : Cfg := { permitCfg with others := carConflict }
def occasion_s9Trace : Trace := traceOf occS9Cfg

/-- `occasion_s9_outside` (compliant): As in permit, but another car occupied i only before the motorcycle's entry and left it before the entry. -/
def occS9OutCfg : Cfg := { permitCfg with others := carGone }
def occasion_s9_outsideTrace : Trace := traceOf occS9OutCfg

def witness (name : String) (c : Cfg) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b"
    trace := traceOf c
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := windowOf c
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidCfg .violated
  , witness "permit" permitCfg .compliant
  , witness "idle" idleCfg .notApplicable
  , witness "blind" forbidCfg (.unknown []) ["dev.traffic_signal"]
  , witness "history_boundary" historyCfg (.unknown []) (boundary := "the motorcycle's approach to the stop line on c and any run at rest there before the recording began")
  , witness "branch_1" branch1Cfg .violated
  , witness "branch_2" branch2Cfg .violated
  , witness "branch_3" branch3Cfg .compliant
  , witness "branch_4" branch4Cfg .violated
  , witness "branch_5" branch5Cfg .violated
  , witness "branch_6" branch6Cfg .compliant
  , witness "branch_7" branch7Cfg .compliant
  , witness "branch_8" branch8Cfg .violated
  , witness "branch_9" branch9Cfg .violated
  , witness "branch_10" branch10Cfg .violated
  , witness "branch_11" branch11Cfg .violated
  , witness "branch_12" branch12Cfg .compliant
  , witness "branch_13" branch13Cfg .compliant
  , witness "branch_14" branch14Cfg .compliant
  , witness "branch_15" branch15Cfg .notApplicable
  , witness "occasion_s1" occS1Cfg .violated
  , witness "occasion_s1_outside" occS1OutCfg .notApplicable
  , witness "occasion_s3" runCfg .violated
  , witness "occasion_s3_outside" occS3OutCfg .notApplicable
  , witness "occasion_s8" occS8Cfg .violated
  , witness "occasion_s8_outside" occS8OutCfg .compliant
  , witness "occasion_s9" occS9Cfg .violated
  , witness "occasion_s9_outside" occS9OutCfg .compliant ]

end TrafficSpecWitness.NRS_484B_307_9b
