/-
  Witnesses for NRS_484B_250_1.

  Geometry (metres, +x east, +y north): intersection i (10) is the square [-5, 5] × [-5, 5], lying on
  highways A (20, west of it), B (21, north–south) and C (22, east of it). Approach carriers, each
  entering i: cA (11) eastbound, x ∈ [-60, -5], y ∈ [-5, 0], on A; cB (12) northbound, x ∈ [0, 5],
  y ∈ [-60, -5], on B; cW (13) westbound, x ∈ [5, 60], y ∈ [0, 5], on C (A changes name to C across
  the junction, so cW is opposed to cA yet on a different highway).
  x (track 1) is a 4 m × 2 m car eastbound on cA at y = -2.5; y (track 2) is a car of the same size.
  Instants 1 s apart. A body across two regions has the second one stated in `occupies`.
  At x's entry (x at -4.5, 5 m/s) with y at (2.5, -4.5) northbound at 2 m/s, the predicted closest
  approach is about 0.74 m after about 1.34 s: well inside 4 m and 3 s. In the opposed scenes y
  runs westbound at y = 0.5, 3 m laterally from x, in conflict with x at its entry (closest
  approach 2–3 m within about 1.3 s); the exception decides whether it counts. z (track 3) entered
  i from cB and is leaving it northwards, over 9 m from x at closest approach: it keeps the rule
  engaged without a conflict of its own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def iR : Structure :=
  { Build.rect 10 .intersection (m (-5)) (m (-5)) (m 5) (m 5) with ways := some [20, 21, 22] }
def cA : Structure :=
  { Build.lane 11 [(m (-60), m (-5)), (m (-5), m (-5)), (m (-5), m 0), (m (-60), m 0)] Build.east
      (enters := some 10) with ways := some [20] }
def cB : Structure :=
  { Build.lane 12 [(m 0, m (-60)), (m 5, m (-60)), (m 5, m (-5)), (m 0, m (-5))] Build.north
      (enters := some 10) with ways := some [21] }
def cW : Structure :=
  { Build.lane 13 [(m 5, m 0), (m 60, m 0), (m 60, m 5), (m 5, m 5)] Build.west
      (enters := some 10) with ways := some [22] }
def hA : Structure := Build.rect 20 .highway (m (-100)) (m (-5)) (m 5) (m 5)
def hB : Structure := Build.rect 21 .highway (m (-5)) (m (-100)) (m 5) (m 100)
def hC : Structure := Build.rect 22 .highway (m 5) (m (-5)) (m 100) (m 5)

def structs : List Structure := [iR, cA, cB, cW, hA, hB, hC]

def withYaw (u : RoadUser) (yaw : Q) : RoadUser :=
  Build.withKin u (fun k => { k with yawRate := some yaw })

/-- A unit heading given to 10⁻⁸ (cosine, sine of its angle). -/
def hdg (c s : Int) : Vec := (Units.ratio c 100000000, Units.ratio s 100000000)
/-- East turned 10° to the left; west turned 10° and 20° to the left. -/
def east10 : Vec := hdg 98480775 17364818
def west10 : Vec := hdg (-98480775) (-17364818)
def west20 : Vec := hdg (-93969262) (-34202014)

/-- x eastbound on cA at y = -2.5. -/
def xAt (px : Q) (speed : Int) (yaw : Int := 0) (heading : Vec := Build.east) : RoadUser :=
  withYaw (Build.user 1 [.motorVehicle] (px, cm (-250)) heading (Units.metresPerSecond speed) (m 2, m 1, m 1))
    (Units.degrees yaw)
/-- y northbound on cB at x = 2.5. -/
def yNorth (py : Q) (speed : Int) : RoadUser :=
  withYaw (Build.user 2 [.motorVehicle] (cm 250, py) Build.north (Units.metresPerSecond speed) (m 2, m 1, m 1))
    (Units.degrees 0)
/-- y westbound on cW at y = 0.5 (its right edge on the centre of the way, 3 m laterally from x). -/
def yWest (px : Q) (speed : Int) (yaw : Int := 0) (heading : Vec := Build.west) : RoadUser :=
  withYaw (Build.user 2 [.motorVehicle] (px, cm 50) heading (Units.metresPerSecond speed) (m 2, m 1, m 1))
    (Units.degrees yaw)
/-- z (track 3) northbound from cB at x = 2.5, 5 m/s: entered i at instant 0 and is leaving it
    northwards when x enters, its predicted closest approach to x over 9 m. -/
def zNorth (py : Q) : RoadUser :=
  withYaw (Build.user 3 [.motorVehicle] (cm 250, py) Build.north (Units.metresPerSecond 5) (m 2, m 1, m 1))
    (Units.degrees 0)

/-- A second intersection i2 (40) on highway B, 95 m north, and its northbound approach L2 (41). -/
def i2 : Structure :=
  { Build.rect 40 .intersection (m (-5)) (m 95) (m 5) (m 105) with ways := some [21] }
def l2 : Structure :=
  { Build.lane 41 [(m 0, m 60), (m 5, m 60), (m 5, m 95), (m 0, m 95)] Build.north
      (enters := some 40) with ways := some [21] }

def mkScene (t : Timestamp) (users : List RoadUser) (devices : List Device)
    (extra : List (TrackId × RegionId)) (intents : List DeclaredIntent := [])
    (more : List Structure := []) : Scene :=
  Build.scene t (some 1) users (structs ++ more) devices
    (occupies := some (Build.occupancyFromGeometry users (structs ++ more) ++ extra)) (intents := intents)

def turnLeft (who : TrackId) (v : Bool) : DeclaredIntent :=
  { vehicle := who, target := 10, values := [("int.turn_left", v)] }

/-- x on cA moving into i (entry at instant 2); y entered i from cB at instant 1 and crosses. -/
def crossingTrace (devices : List Device) (more : List Structure := []) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => mkScene t [xAt (cm (-1450)) 5, yNorth (cm (-850)) 2] devices [] (more := more)
    | 1 => mkScene t [xAt (cm (-950)) 5, yNorth (cm (-650)) 2] devices [(2, 10)] (more := more)
    | _ => mkScene t [xAt (cm (-450)) 5, yNorth (cm (-450)) 2] devices [(1, 11), (2, 12)] (more := more)

/-- `forbid` (violated): No device governs i or its approaches. x approaches on lane c (st.lane_enters c i, on highway A); y entered i from lane cy on highway B and is crossing. x moves into i; predicted closest approach 1 m in 1.5 s. -/
def forbidTrace : Trace := crossingTrace []

/-- `permit` (compliant): Same, but x halts on c while y crosses i and enters only after y has left. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => mkScene t [xAt (cm (-1450)) 5, yNorth (cm (-850)) 4] [] []
    | 1 => mkScene t [xAt (cm (-950)) 0, yNorth (cm (-450)) 4] [] [(2, 12)]
    | 2 => mkScene t [xAt (cm (-950)) 0, yNorth (cm (-50)) 4] [] []
    | 3 => mkScene t [xAt (cm (-950)) 0, yNorth (cm 350) 4] [] []
    | _ => mkScene t [xAt (cm (-450)) 5, yNorth (cm 750) 4] [] [(1, 11)]

/-- `idle` (not_applicable): A dev.stop_sign governs c; the intersection is controlled by an official device and no signal is inoperative. -/
def idleTrace : Trace := crossingTrace [Build.sign 30 .stopSign [11]]

/-- `blind` (unknown): As forbid, but st.lane_enters is not observed, so whether x approaches i and from which carrier y entered is unknown. -/
def blindTrace : Trace := crossingTrace []

/-- y westbound on cW (opposed to cA): `yPos`, yaw rates, headings and the declarations per
    instant; each heading is the previous one turned by its yaw rate over the 1 s interval. -/
def opposedTrace (yPos : Nat → Q) (ySpeed : Int) (yYaw xYaw : Nat → Int) (yHdg xHdg : Nat → Vec)
    (yExtra : Nat → List (TrackId × RegionId)) (intents : List DeclaredIntent)
    (withZ : Bool := false) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let xPos := match k with | 0 => cm (-1450) | 1 => cm (-950) | _ => cm (-450)
    let xExtra : List (TrackId × RegionId) := if k ≥ 2 then [(1, 11)] else []
    let zs := if withZ then [zNorth (match k with | 0 => m (-6) | 1 => m (-1) | _ => m 4)] else []
    let zExtra : List (TrackId × RegionId) := if withZ && k == 0 then [(3, 10)] else []
    mkScene t ([xAt xPos 5 (xYaw k) (xHdg k), yWest (yPos k) ySpeed (yYaw k) (yHdg k)] ++ zs) []
      (xExtra ++ yExtra k ++ zExtra) intents

/-- `branch_1` (not_applicable): x and y approach on opposed carriers (dot product of directions -1); y has int.turn_left at i and is turning left within i when x moves in: y is excepted and no other vehicle has entered i. At instant 1 y is in i declaring the turn but not yet turning. -/
def branch_1Trace : Trace :=
  opposedTrace (fun k => match k with | 0 => cm 850 | 1 => cm 650 | _ => cm 450) 2
    (fun k => if k ≥ 2 then 10 else 0) (fun _ => 0)
    (fun k => if k ≥ 2 then west10 else Build.west) (fun _ => Build.east)
    (fun k => match k with | 0 => [] | 1 => [(2, 10)] | _ => [(2, 13)])
    [turnLeft 2 true]

/-- `branch_2` (violated): i is governed by a dev.traffic_signal that is dev.inoperative at x's entry; the device exception is suspended; y crossing from highway B, conflict predicted when x moves in. -/
def branch_2Trace : Trace :=
  crossingTrace [{ Build.signal 30 [10, 11, 12] [.dark] with inoperative := some true, uncovered := some true }]

/-- `branch_3` (not_applicable): x approaches and enters an uncontrolled intersection with no other road user in the scene. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => mkScene t [xAt (cm (-1450)) 5] [] []
    | 1 => mkScene t [xAt (cm (-950)) 5] [] []
    | _ => mkScene t [xAt (cm (-450)) 5] [] [(1, 11)]

/-- `branch_4` (not_applicable): opposed approaches; y, declaring nothing, is turning left within i
    from its entry: the turn alone excepts it. -/
def branch_4Trace : Trace :=
  opposedTrace (fun k => match k with | 0 => cm 850 | 1 => cm 650 | _ => cm 450) 2
    (fun k => if k ≥ 1 then 10 else 0) (fun _ => 0)
    (fun k => match k with | 0 => Build.west | 1 => west10 | _ => west20) (fun _ => Build.east)
    (fun k => match k with | 0 => [] | 1 => [(2, 10)] | _ => [(2, 13)])
    []

/-- `branch_5` (not_applicable): opposed approaches; x declares int.turn_left at i, y declares no
    left turn and goes straight: x's intention excepts y. -/
def branch_5Trace : Trace :=
  opposedTrace (fun k => match k with | 0 => cm 850 | 1 => cm 650 | _ => cm 450) 2
    (fun _ => 0) (fun _ => 0)
    (fun _ => Build.west) (fun _ => Build.east)
    (fun k => match k with | 0 => [] | 1 => [(2, 10)] | _ => [(2, 13)])
    [turnLeft 1 true, turnLeft 2 false]

/-- `branch_6` (not_applicable): opposed approaches, neither declaring a left turn; y reaches i at
    the instant x enters it turning left: x's turn within i excepts y. -/
def branch_6Trace : Trace :=
  opposedTrace (fun k => match k with | 0 => cm 1450 | 1 => cm 1050 | _ => cm 650) 4
    (fun _ => 0) (fun k => if k ≥ 2 then 10 else 0)
    (fun _ => Build.west) (fun k => if k ≥ 2 then east10 else Build.east)
    (fun k => match k with | 0 => [] | 1 => [] | _ => [(2, 10)])
    [turnLeft 1 false, turnLeft 2 false]

/-- `branch_7` (not_applicable): as forbid, but a yield sign governs i itself. -/
def branch_7Trace : Trace := crossingTrace [Build.sign 30 .yieldSign [10]]

/-- `branch_8` (not_applicable): as forbid, but an operating traffic signal governs i and its approaches. -/
def branch_8Trace : Trace :=
  crossingTrace [{ Build.signal 30 [10, 11, 12] [.circularGreen] with inoperative := some false, uncovered := some true }]

/-- `branch_9` (compliant): as branch_4 (y turning left within i, opposed), and z, which entered i
    from cB, is leaving it: the rule applies through z, y is excepted, z is in no conflict. -/
def branch_9Trace : Trace :=
  opposedTrace (fun k => match k with | 0 => cm 850 | 1 => cm 650 | _ => cm 450) 2
    (fun k => if k ≥ 1 then 10 else 0) (fun _ => 0)
    (fun k => match k with | 0 => Build.west | 1 => west10 | _ => west20) (fun _ => Build.east)
    (fun k => match k with | 0 => [] | 1 => [(2, 10)] | _ => [(2, 13)])
    [] (withZ := true)

/-- `branch_10` (compliant): as branch_5 (x declares int.turn_left at i), with z. -/
def branch_10Trace : Trace :=
  opposedTrace (fun k => match k with | 0 => cm 850 | 1 => cm 650 | _ => cm 450) 2
    (fun _ => 0) (fun _ => 0)
    (fun _ => Build.west) (fun _ => Build.east)
    (fun k => match k with | 0 => [] | 1 => [(2, 10)] | _ => [(2, 13)])
    [turnLeft 1 true, turnLeft 2 false] (withZ := true)

/-- `branch_11` (compliant): as branch_6 (x turning left within i at its entry), with z. -/
def branch_11Trace : Trace :=
  opposedTrace (fun k => match k with | 0 => cm 1450 | 1 => cm 1050 | _ => cm 650) 4
    (fun _ => 0) (fun k => if k ≥ 2 then 10 else 0)
    (fun _ => Build.west) (fun k => if k ≥ 2 then east10 else Build.east)
    (fun k => match k with | 0 => [] | 1 => [] | _ => [(2, 10)])
    [turnLeft 1 false, turnLeft 2 false] (withZ := true)

/-- `branch_12` (compliant): opposed approaches; y declares int.turn_left at i and is not yet
    turning, x declares none; z as in branch_9. -/
def branch_12Trace : Trace :=
  opposedTrace (fun k => match k with | 0 => cm 850 | 1 => cm 650 | _ => cm 450) 2
    (fun _ => 0) (fun _ => 0)
    (fun _ => Build.west) (fun _ => Build.east)
    (fun k => match k with | 0 => [] | 1 => [(2, 10)] | _ => [(2, 13)])
    [turnLeft 1 false, turnLeft 2 true] (withZ := true)

/-- `branch_13` (violated): as forbid, but a stop sign governs L2, the approach to another
    intersection i2 95 m north: i is not controlled. -/
def branch_13Trace : Trace := crossingTrace [Build.sign 31 .stopSign [41]] [i2, l2]

/-- The stop line marking cA's entrance, 0.5 m deep, 5 m before i. -/
def stopLineA : Structure :=
  { Build.rect 50 .stopLine (m (-6)) (m (-5)) (cm (-550)) (m 0) with
      ways := some [20], entranceOf := [11], entranceObserved := true }

/-- `branch_14` (violated): as branch_2 (the signal governing i and its approaches is inoperative),
    but x halts at cA's stop line for two instants before moving into i while y, which entered i
    from cB, crosses: conflict predicted at x's entry. -/
def branch_14Trace : Trace :=
  let sig : Device := { Build.signal 30 [10, 11, 12] [.dark] with inoperative := some true, uncovered := some true }
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => mkScene t [xAt (cm (-1300)) 5, yNorth (cm (-1050)) 2] [sig] [] (more := [stopLineA])
    | 1 => mkScene t [xAt (cm (-820)) 0, yNorth (cm (-850)) 2] [sig] [] (more := [stopLineA])
    | 2 => mkScene t [xAt (cm (-820)) 0, yNorth (cm (-650)) 2] [sig] [(2, 10)] (more := [stopLineA])
    | _ => mkScene t [xAt (cm (-450)) 5, yNorth (cm (-450)) 2] [sig] [(1, 11), (2, 12)] (more := [stopLineA])

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
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .violated
  , witness "branch_14" branch_14Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_1
