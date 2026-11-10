/-
  Witnesses for NRS_484B_250_1.

  The plan: a four-leg junction `i` (110), the square −5 m … 5 m on both axes, where the east–west
  highway A (101) meets the north–south highway B (102). In the scenes with an east leg of its own
  name, A covers the west leg and the junction and C (103) the east leg and the junction; the
  junction lies on every way that meets there.
  - lane c (120): x's approach, eastbound on A, x from −60 to −5, y from −5 to 0, entering i;
  - lane cy (130): the crossing approach, northbound on B, x from 0 to 5, y from −60 to −5, entering i;
  - lane co (140): the opposed approach, westbound on the east leg (C, or A where the east leg is A),
    x from 5 to 60, y from 0 to 5, entering i;
  - a stop line (150) across c at x from −6 to −5.5, marking c's entrance (branch_4 only).
  Every car is 4 m × 2 m (half-extents 2, 1, 1), heading along an axis: x (track 1) eastbound in c
  at y = −2.5, the crossing y (track 2) northbound in cy at x = 2.5, the opposed y westbound in co
  at y = 2.5. Occupancy is stated: every region whose box shares an interior point with a car's
  box. Observations every second from t = 0. Yaw rates are observed (zero unless a car turns).

  Against the reading (horizon 3 s, clearance 4 m, speed tolerance 0.2 m/s, yaw tolerance 2 deg/s,
  opposed cosine 0.7): a conflict scene puts the centres' closest approach at 0 m in 1.5 s or 2 s;
  a clear scene at 9.4 m, or diverging; a turning car yaws 90 deg/s over the interval before the
  scene and its heading has turned a quarter turn; a halted car stands at 0 m/s;
  opposed carriers have direction cosine −1, crossing ones 0.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def hwA : RegionId := 101
def hwB : RegionId := 102
def hwC : RegionId := 103
def junction : RegionId := 110
def laneC : RegionId := 120
def laneCy : RegionId := 130
def laneCo : RegionId := 140
def stopLineC : RegionId := 150

/-- An axis-aligned box (x0, y0, x1, y1). -/
abbrev Box := Q × Q × Q × Q

def boxPoly (b : Box) : List Vec :=
  let (x0, y0, x1, y1) := b
  [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

/-- Two boxes share an interior point. -/
def boxesOverlap (a b : Box) : Bool :=
  let (ax0, ay0, ax1, ay1) := a
  let (bx0, by0, bx1, by1) := b
  Q.lt ax0 bx1 && Q.lt bx0 ax1 && Q.lt ay0 by1 && Q.lt by0 ay1

/-- The regions with their boxes; `eastWay` is the highway the east leg lies on. -/
def regionBoxes (eastWay : RegionId) (stopLine : Bool) : List (RegionId × Box) :=
  (if eastWay == hwA then [(hwA, (m (-60), m (-5), m 60, m 5))]
   else [(hwA, (m (-60), m (-5), m 5, m 5)), (hwC, (m (-5), m (-5), m 60, m 5))])
  ++ [ (hwB, (m (-5), m (-60), m 5, m 60))
     , (junction, (m (-5), m (-5), m 5, m 5))
     , (laneC, (m (-60), m (-5), m (-5), Q.zero))
     , (laneCy, (Q.zero, m (-60), m 5, m (-5)))
     , (laneCo, (m 5, Q.zero, m 60, m 5)) ]
  ++ (if stopLine then [(stopLineC, (cm (-600), m (-5), cm (-550), Q.zero))] else [])

def boxOf (eastWay : RegionId) (stopLine : Bool) (r : RegionId) : Box :=
  ((regionBoxes eastWay stopLine).find? (·.1 == r)).map (·.2) |>.getD (Q.zero, Q.zero, Q.zero, Q.zero)

def structures (eastWay : RegionId) (stopLine : Bool) : List Structure :=
  let bx := boxOf eastWay stopLine
  (if eastWay == hwA then [Build.region hwA .highway (boxPoly (bx hwA))]
   else [Build.region hwA .highway (boxPoly (bx hwA)), Build.region hwC .highway (boxPoly (bx hwC))])
  ++ [ Build.region hwB .highway (boxPoly (bx hwB))
     , { Build.region junction .intersection (boxPoly (bx junction)) with
           ways := some ([hwA, hwB] ++ (if eastWay == hwA then [] else [hwC])) }
     , { Build.lane laneC (boxPoly (bx laneC)) Build.east (enters := some junction) with ways := some [hwA] }
     , { Build.lane laneCy (boxPoly (bx laneCy)) Build.north (enters := some junction) with ways := some [hwB] }
     , { Build.lane laneCo (boxPoly (bx laneCo)) Build.west (enters := some junction) with ways := some [eastWay] } ]
  ++ (if stopLine then
        [{ Build.region stopLineC .stopLine (boxPoly (bx stopLineC)) with
             ways := some [hwA], entranceOf := [laneC], entranceObserved := true }]
      else [])

/-- A car: track, reference point, heading (a cardinal unit vector), speed, yaw rate. -/
abbrev Car := TrackId × Vec × Vec × Q × Q

def carUser (c : Car) : RoadUser :=
  let (tr, p, h, v, w) := c
  Build.withKin (Build.user tr [.motorVehicle] p h v (m 2, m 1, m 1)) fun k => { k with yawRate := some w }

def carBox (c : Car) : Box :=
  let (_, p, h, _, _) := c
  let (a, b) := if Q.isZero h.2 then (m 2, m 1) else (m 1, m 2)
  (Q.sub p.1 a, Q.sub p.2 b, Q.add p.1 a, Q.add p.2 b)

def occupancyIn (boxes : List (RegionId × Box)) (cars : List Car) : List (TrackId × RegionId) :=
  cars.flatMap fun c =>
    (boxes.filter fun rb => boxesOverlap (carBox c) rb.2).map fun rb => (c.1, rb.1)

def mkScene (t : Timestamp) (cars : List Car) (devices : List Device := [])
    (intents : List DeclaredIntent := []) (eastWay : RegionId := hwA) (stopLine : Bool := false) : Scene :=
  Build.scene t (some 1) (cars.map carUser) (structures eastWay stopLine) devices
    (occupies := some (occupancyIn (regionBoxes eastWay stopLine) cars)) (intents := intents)

/-
  The two-junction plan (branch_19 … branch_27): A (101) and B (102) as before, meeting at i (110);
  a narrow way D (104), x from −23 to −20, crosses A at i2 (111), x from −23 to −20, y from −5 to 5.
  Lane c2 (121), x from −60 to −23, y from −5 to 0, eastbound on A, enters i2; lane c (120), x from
  −20 to −5, eastbound on A, enters i; lane cy (130) as before; lane dy (131), x from −23 to −20,
  y from −60 to −5, northbound on D, enters i2. A car's 4 m body at x = −21.5 spans c2, i2 and c.
-/
def hwD : RegionId := 104
def junction2 : RegionId := 111
def laneC2 : RegionId := 121
def laneDy : RegionId := 131

def w2Boxes : List (RegionId × Box) :=
  [ (hwA, (m (-60), m (-5), m 60, m 5))
  , (hwB, (m (-5), m (-60), m 5, m 60))
  , (hwD, (m (-23), m (-60), m (-20), m 60))
  , (junction, (m (-5), m (-5), m 5, m 5))
  , (junction2, (m (-23), m (-5), m (-20), m 5))
  , (laneC2, (m (-60), m (-5), m (-23), Q.zero))
  , (laneC, (m (-20), m (-5), m (-5), Q.zero))
  , (laneCy, (Q.zero, m (-60), m 5, m (-5)))
  , (laneDy, (m (-23), m (-60), m (-20), m (-5))) ]

def w2Box (r : RegionId) : Box :=
  (w2Boxes.find? (·.1 == r)).map (·.2) |>.getD (Q.zero, Q.zero, Q.zero, Q.zero)

def w2Structures : List Structure :=
  [ Build.region hwA .highway (boxPoly (w2Box hwA))
  , Build.region hwB .highway (boxPoly (w2Box hwB))
  , Build.region hwD .highway (boxPoly (w2Box hwD))
  , { Build.region junction .intersection (boxPoly (w2Box junction)) with ways := some [hwA, hwB] }
  , { Build.region junction2 .intersection (boxPoly (w2Box junction2)) with ways := some [hwA, hwD] }
  , { Build.lane laneC2 (boxPoly (w2Box laneC2)) Build.east (enters := some junction2) with ways := some [hwA] }
  , { Build.lane laneC (boxPoly (w2Box laneC)) Build.east (enters := some junction) with ways := some [hwA] }
  , { Build.lane laneCy (boxPoly (w2Box laneCy)) Build.north (enters := some junction) with ways := some [hwB] }
  , { Build.lane laneDy (boxPoly (w2Box laneDy)) Build.north (enters := some junction2) with ways := some [hwD] } ]

def mkScene2 (t : Timestamp) (cars : List Car) (devices : List Device) : Scene :=
  Build.scene t (some 1) (cars.map carUser) w2Structures devices
    (occupies := some (occupancyIn w2Boxes cars))

/-- x eastbound in c at reference x-coordinate `px`. -/
def xAt (px v : Q) (yaw : Q := Q.zero) : Car := (1, (px, cm (-250)), Build.east, v, yaw)
/-- y northbound in cy (or beyond) at reference y-coordinate `py`. -/
def yNorth (py v : Q) : Car := (2, (cm 250, py), Build.north, v, Q.zero)
/-- y westbound in co (or beyond) at reference x-coordinate `px`. -/
def yWest (px v : Q) (yaw : Q := Q.zero) : Car := (2, (px, cm 250), Build.west, v, yaw)

def turnLeftDecl (who : TrackId) (b : Bool) : DeclaredIntent :=
  { vehicle := who, target := junction, values := [("int.turn_left", b)] }

/-- x at −15, −10, −5 m at 5 m/s (across c and i at t = 2 s); y at −9.5, −7.5, −5.5 m at 2 m/s
    (across cy and i at t = 2 s): closest approach 0 m in 1.5 s at t = 2 s. -/
def crossingCars (k : Nat) : List Car :=
  match k with
  | 0 => [xAt (m (-15)) (m 5), yNorth (cm (-950)) (m 2)]
  | 1 => [xAt (m (-10)) (m 5), yNorth (cm (-750)) (m 2)]
  | _ => [xAt (m (-5)) (m 5), yNorth (cm (-550)) (m 2)]

/-- `forbid` (violated): No device governs i or its approaches. x approaches on lane c (st.lane_enters c i, on highway A); y entered i from lane cy on highway B and is crossing. x moves into i; predicted closest approach 1 m in 1.5 s. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => mkScene t (crossingCars k)

/-- `permit` (compliant): Same, but x halts on c while y crosses i and enters only after y has left.
    x stands at −8 m (box −10 … −6, c only) to t = 3 s, then moves in at 3 m/s; y at 5 m/s is in i
    from t = 1 s to t = 3 s and gone at t = 4 s. -/
def permitTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    let x := if k < 4 then xAt (m (-8)) Q.zero else if k == 4 then xAt (m (-5)) (m 3) else xAt (m (-1)) (m 3)
    let py : Q := m (5 * (Int.ofNat k) - 10)
    mkScene t [x, yNorth py (m 5)]

/-- `idle` (not_applicable): A dev.stop_sign governs c; the intersection is controlled by an official device and no signal is inoperative. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mkScene t (crossingCars k) [Build.sign 1 .stopSign [laneC]]

/-- `blind` (unknown): As forbid, but st.lane_enters is not observed, so whether x approaches i and from which carrier y entered is unknown. -/
def blindTrace : Trace := forbidTrace

/-- A left turn's yaw rate: a quarter turn over the one-second interval before the scene. -/
def quarterTurn : Q := Units.degrees 90

/-- x as in forbid; y westbound in co on the east leg at 4 m/s: at 12 and 8 m, then at 4 m inside
    i at t = 2 s. A car that `turns` there has yawed left 90 deg/s over the last interval: x then
    heads north (box −6 … −4 × −4.5 … −0.5, across c and i), y south (box 3 … 5 × 0.5 … 4.5, in i). -/
def opposedCars (k : Nat) (xTurns yTurns : Bool) : List Car :=
  match k with
  | 0 => [xAt (m (-15)) (m 5), yWest (m 12) (m 4)]
  | 1 => [xAt (m (-10)) (m 5), yWest (m 8) (m 4)]
  | _ =>
    [ if xTurns then (1, (m (-5), cm (-250)), Build.north, m 5, quarterTurn) else xAt (m (-5)) (m 5)
    , if yTurns then (2, (m 4, cm 250), Build.south, m 4, quarterTurn) else yWest (m 4) (m 4) ]

/-- `branch_1` (not_applicable): x and y approach on opposed carriers (dot product of directions -1); y has int.turn_left at i and is turning left within i when x moves in: y is excepted and no other vehicle has entered i. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mkScene t (opposedCars k false true) [] [turnLeftDecl 2 true] (eastWay := hwC)

/-- An inoperative, uncovered, dark signal head governing i and its approaches. -/
def deadSignal : Device :=
  { Build.signal 1 [junction, laneC, laneCy, laneCo] [.dark] with
      uncovered := some true, inoperative := some true }

/-- `branch_2` (violated): i is governed by a dev.traffic_signal that is dev.inoperative at x's entry; the device exception is suspended; y crossing from highway B, conflict predicted when x moves in. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => mkScene t (crossingCars k) [deadSignal]

/-- `branch_3` (not_applicable): x approaches and enters an uncontrolled intersection with no other road user in the scene. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => mkScene t ((crossingCars k).filter (·.1 == 1))

/-- `branch_4` (violated): A dev.traffic_signal governing i and its approaches is installed, uncovered and dev.inoperative throughout. x halts (drv.motion.stopped) at the stop line marking its approach carrier c (st.entrance_of) within p.stop_point_tolerance on its upstream side, then moves into i; at that entry observation no other vehicle overlaps i (y is still moving on cy, outside i, not halted), so nothing is owed there. At the next observation x is still moving with its footprint across c and i, and y, having entered i from cy on highway B, is crossing it with a predicted closest approach to x below p.conflict_centre_clearance within p.conflict_time_horizon. There NRS_484B_250_4_o1 does not apply to x (it is not x's entry) and NRS_484B_250_4_o2 does (x stopped before the entry, the signal was inoperative at the entry, y overlaps i), so the device exception is suspended through o2 alone and the conflict violates the duty; without that suspension the controlled intersection would make the rule not applicable.
    x stands at −8 m, its front touching the stop line (−6 m), to t = 3 s; enters at t = 4 s (−6.5 m,
    box −8.5 … −4.5) and is at −3.5 m (box −5.5 … −1.5, across c and i) at t = 5 s, at 3 m/s. y at
    1.75 m/s: −7.75 m (box −9.75 … −5.75, cy only) at t = 4 s, −6 m (across cy and i) at t = 5 s;
    closest approach 0 m in 2 s there. -/
def branch_4Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    let x := if k < 4 then xAt (m (-8)) Q.zero else if k == 4 then xAt (cm (-650)) (m 3) else xAt (cm (-350)) (m 3)
    let py : Q := cm (175 * (Int.ofNat k) - 1475)
    mkScene t [x, yNorth py (cm 175)] [deadSignal] (stopLine := true)

/-- `branch_5` (not_applicable): an operating signal (circular green, uncovered, not inoperative)
    governs i itself; otherwise as forbid: the intersection is controlled and nothing suspends that. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mkScene t (crossingCars k)
      [{ Build.signal 1 [junction] [.circularGreen] with uncovered := some true, inoperative := some false }]

/-- `branch_6` (not_applicable): a yield sign governs c; otherwise as forbid. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mkScene t (crossingCars k) [Build.sign 1 .yieldSign [laneC]]

/-- `branch_7` (not_applicable): as branch_1, but y declares no left turn; it is turning left
    within i, which alone excepts it. x declares none and does not yaw. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mkScene t (opposedCars k false true) [] [turnLeftDecl 1 false, turnLeftDecl 2 false]
      (eastWay := hwC)

/-- `branch_8` (not_applicable): as branch_1, but y is not yet turning (zero yaw); its declared
    left turn at i alone excepts it. x declares none and does not yaw. -/
def branch_8Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mkScene t (opposedCars k false false) [] [turnLeftDecl 1 false, turnLeftDecl 2 true]
      (eastWay := hwC)

/-- `branch_9` (not_applicable): opposed approaches, y going straight and declaring no left turn;
    x declares a left turn at i, which excepts y. -/
def branch_9Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mkScene t (opposedCars k false false) [] [turnLeftDecl 1 true, turnLeftDecl 2 false]
      (eastWay := hwC)

/-- `branch_10` (not_applicable): opposed approaches, neither declares a left turn, y goes
    straight; x is turning left as it moves into i, which excepts y. -/
def branch_10Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mkScene t (opposedCars k true false) [] [turnLeftDecl 1 false, turnLeftDecl 2 false]
      (eastWay := hwC)

/-- `branch_11` (not_applicable): y enters i from the opposed approach of the same highway A
    (the east leg is A), going straight: it did not enter from a different highway. -/
def branch_11Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => mkScene t (opposedCars k false false)

/-- `branch_12` (compliant): x stands with its nose in i (−6 m, box −8 … −4) while y crosses as
    in forbid: x is not moving into or within i. -/
def branch_12Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mkScene t ((crossingCars k).map fun c => if c.1 == 1 then xAt (m (-6)) Q.zero else c)

/-- `branch_13` (compliant): x moves in as in forbid; y, entered from cy, is leaving i ahead of it
    at 4 m/s (−4.5, −0.5, 3.5 m): the centres approach within the horizon but no closer than 9.4 m. -/
def branch_13Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let py : Q := cm (400 * (Int.ofNat k) - 450)
    mkScene t ((crossingCars k).map fun c => if c.1 == 2 then yNorth py (m 4) else c)

/-- `branch_14` (compliant): x moves in as in forbid; y, entered from cy, is leaving i at 8 m/s
    (−9.5, −1.5, 6.5 m): the centres are separating, no closest approach ahead. -/
def branch_14Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let py : Q := cm (800 * (Int.ofNat k) - 950)
    mkScene t ((crossingCars k).map fun c => if c.1 == 2 then yNorth py (m 8) else c)

/-- `branch_15` (not_applicable): no other road user; x itself came up cy (−10, −5 m), entered i
    from it and, turning left, swings west across c's end (−4 m, box −6 … −2): x is no other vehicle. -/
def branch_15Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let x : Car := match k with
      | 0 => (1, (cm 250, m (-10)), Build.north, m 4, Q.zero)
      | 1 => (1, (cm 250, m (-5)), Build.north, m 4, Q.zero)
      | _ => (1, (m (-4), cm (-250)), Build.west, m 4, quarterTurn)
    mkScene t [x]

/-- An operating signal head (circular green, uncovered, not inoperative) governing `gov`. -/
def greenSignal (gov : List RegionId) : Device :=
  { Build.signal 1 gov [.circularGreen] with uncovered := some true, inoperative := some false }

/-- `branch_16` (not_applicable): as forbid, but an operating signal governs c (not i itself). -/
def branch_16Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => mkScene t (crossingCars k) [greenSignal [laneC]]

/-- `branch_17` (not_applicable): as forbid, but a stop sign governs i itself. -/
def branch_17Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => mkScene t (crossingCars k) [Build.sign 1 .stopSign [junction]]

/-- `branch_18` (not_applicable): as forbid, but a yield sign governs i itself. -/
def branch_18Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => mkScene t (crossingCars k) [Build.sign 1 .yieldSign [junction]]

/-- The two-junction plan with forbid's cars at i (x within c, −15 … −5 m): a device governing
    the other junction i2 directly controls nothing at i. -/
def farControlTrace (d : Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => mkScene2 t (crossingCars k) [d]

/-- `branch_19` (violated): two-junction plan; an operating signal governs i2 only; at i, uncontrolled, x moves in against y as in forbid. -/
def branch_19Trace : Trace := farControlTrace (greenSignal [junction2])
/-- `branch_20` (violated): as branch_19 with a stop sign governing i2. -/
def branch_20Trace : Trace := farControlTrace (Build.sign 1 .stopSign [junction2])
/-- `branch_21` (violated): as branch_19 with a yield sign governing i2. -/
def branch_21Trace : Trace := farControlTrace (Build.sign 1 .yieldSign [junction2])

/-- The two-junction plan: x at 5 m/s from c2 into i2 (−26.5, then −21.5 m: across c2, i2 and c);
    y (track 2) enters i from cy at 2 m/s (−7.5, −5.5 m) and is clear of x (closest approach 4.3 s
    ahead); y2 (track 3) enters i2 from dy at 2 m/s (x = −21.5; −7.5, −5.5 m), closest approach to
    x 2.8 m in 0.2 s. -/
def twoJunctionCars (k : Nat) : List Car :=
  match k with
  | 0 => [ xAt (cm (-2650)) (m 5), yNorth (cm (-750)) (m 2), (3, (cm (-2150), cm (-750)), Build.north, m 2, Q.zero) ]
  | _ => [ xAt (cm (-2150)) (m 5), yNorth (cm (-550)) (m 2), (3, (cm (-2150), cm (-550)), Build.north, m 2, Q.zero) ]

/-- x approaches i through c and y is counted there, so the rule applies; at i2, where the conflict
    is, the device controls the junction and no duty is owed. -/
def controlledConflictTrace (d : Device) : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t => mkScene2 t (twoJunctionCars k) [d]

/-- `branch_22` (compliant): two-junction plan; an operating signal governs i2 itself. -/
def branch_22Trace : Trace := controlledConflictTrace (greenSignal [junction2])
/-- `branch_23` (compliant): two-junction plan; an operating signal governs c2. -/
def branch_23Trace : Trace := controlledConflictTrace (greenSignal [laneC2])
/-- `branch_24` (compliant): two-junction plan; a stop sign governs i2 itself. -/
def branch_24Trace : Trace := controlledConflictTrace (Build.sign 1 .stopSign [junction2])
/-- `branch_25` (compliant): two-junction plan; a stop sign governs c2. -/
def branch_25Trace : Trace := controlledConflictTrace (Build.sign 1 .stopSign [laneC2])
/-- `branch_26` (compliant): two-junction plan; a yield sign governs i2 itself. -/
def branch_26Trace : Trace := controlledConflictTrace (Build.sign 1 .yieldSign [junction2])
/-- `branch_27` (compliant): two-junction plan; a yield sign governs c2. -/
def branch_27Trace : Trace := controlledConflictTrace (Build.sign 1 .yieldSign [laneC2])

/-- One junction, east leg C. x moves in at 9.5 m/s (−24, −14.5, −5 m), or turns left there
    (`xTurns`: heading north at 5 m/s, yawing 90 deg/s). y (track 2) enters i from cy at 8 m/s
    (−9.5, −1.5, 6.5 m) and is leaving it, separating from x. y2 (track 3) enters i from co:
    - `y2Mode = 0`: turned south over the first second (90 deg/s) and creeping at 1 m/s, no longer
      yawing (8, then 4.5 m east; −0.5, −1.5 m north);
    - `y2Mode = 1`: westbound at 4 m/s (10.5, 6.5 m), turning south in i at the last (90 deg/s);
    - `y2Mode = 2`: straight westbound at 6 m/s (16, 10, 4 m).
    At t = 2 s y2's closest approach to x is 0 m in 1 s (modes 0 and 1, x straight) or 1.9 m in
    1.3 s (mode 2, x turning). -/
def leftTurnCars (k : Nat) (xTurns : Bool) (y2Mode : Nat) : List Car :=
  let x : Car := match k with
    | 0 => xAt (m (-24)) (cm 950)
    | 1 => xAt (cm (-1450)) (cm 950)
    | _ => if xTurns then (1, (m (-5), cm (-250)), Build.north, m 5, quarterTurn) else xAt (m (-5)) (cm 950)
  let y : Car := yNorth (cm (800 * (Int.ofNat k) - 950)) (m 8)
  let y2 : Car := match y2Mode, k with
    | 0, 0 => (3, (m 8, cm 250), Build.west, m 4, Q.zero)
    | 0, 1 => (3, (cm 450, cm (-50)), Build.south, m 1, quarterTurn)
    | 0, _ => (3, (cm 450, cm (-150)), Build.south, m 1, Q.zero)
    | 1, 0 => (3, (cm 1050, cm 250), Build.west, m 4, Q.zero)
    | 1, 1 => (3, (cm 650, cm 250), Build.west, m 4, Q.zero)
    | 1, _ => (3, (cm 450, cm (-150)), Build.south, m 1, quarterTurn)
    | _, 0 => (3, (m 16, cm 250), Build.west, m 6, Q.zero)
    | _, 1 => (3, (m 10, cm 250), Build.west, m 6, Q.zero)
    | _, _ => (3, (m 4, cm 250), Build.west, m 6, Q.zero)
  [x, y, y2]

/-- y counted at i keeps the rule applicable; y2, excepted by one left-turn limb alone, is the one
    in conflict with x, so the duty holds. -/
def leftTurnTrace (xTurns : Bool) (y2Mode : Nat) (xIntends y2Intends : Bool) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    mkScene t (leftTurnCars k xTurns y2Mode) [] [turnLeftDecl 1 xIntends, turnLeftDecl 3 y2Intends]
      (eastWay := hwC)

/-- `branch_28` (compliant): y2, in conflict, is excepted by its declared left turn alone. -/
def branch_28Trace : Trace := leftTurnTrace false 0 false true
/-- `branch_29` (compliant): y2, in conflict, is excepted by x's declared left turn alone. -/
def branch_29Trace : Trace := leftTurnTrace false 0 true false
/-- `branch_30` (compliant): y2, in conflict, is excepted by its turning left within i alone. -/
def branch_30Trace : Trace := leftTurnTrace false 1 false false
/-- `branch_31` (compliant): y2, in conflict, is excepted by x's turning left within i alone. -/
def branch_31Trace : Trace := leftTurnTrace true 2 false false

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_enters"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .notApplicable
  , witness "branch_11" branch_11Trace .notApplicable
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .compliant
  , witness "branch_14" branch_14Trace .compliant
  , witness "branch_15" branch_15Trace .notApplicable
  , witness "branch_16" branch_16Trace .notApplicable
  , witness "branch_17" branch_17Trace .notApplicable
  , witness "branch_18" branch_18Trace .notApplicable
  , witness "branch_19" branch_19Trace .violated
  , witness "branch_20" branch_20Trace .violated
  , witness "branch_21" branch_21Trace .violated
  , witness "branch_22" branch_22Trace .compliant
  , witness "branch_23" branch_23Trace .compliant
  , witness "branch_24" branch_24Trace .compliant
  , witness "branch_25" branch_25Trace .compliant
  , witness "branch_26" branch_26Trace .compliant
  , witness "branch_27" branch_27Trace .compliant
  , witness "branch_28" branch_28Trace .compliant
  , witness "branch_29" branch_29Trace .compliant
  , witness "branch_30" branch_30Trace .compliant
  , witness "branch_31" branch_31Trace .compliant ]

end TrafficSpecWitness.NRS_484B_250_1
