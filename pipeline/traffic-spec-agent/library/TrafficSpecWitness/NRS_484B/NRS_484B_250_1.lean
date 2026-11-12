/-
  Witnesses for NRS_484B_250_1.

  The crossing: intersection 10 is the square x, y ∈ [-5, 5] m. Highway A (region 1) runs north–
  south, highway B (region 2) east–west; in branch_6/7 the way north of the crossing is a third
  highway C (region 3). Approach carriers, each a lane entering 10 and lying on one way:
    11 — northbound from the south, x ∈ [0, 5], y ∈ [-60, -5], on A (ego's approach);
    12 — southbound from the north, x ∈ [-5, 0], y ∈ [5, 60], on A (on C in branch_6/7);
    21 — eastbound from the west, x ∈ [-60, -5], y ∈ [-5, 0], on B;
    22 — westbound from the east, x ∈ [5, 60], y ∈ [0, 5], on B.
  branch_3, branch_8 and branch_9 add a narrow second crossing 50 south of 10 (`southCrossing`).
  Ego is track 1, the other vehicle track 2; both are motor vehicles, 4 m × 2 m, with a yaw rate
  of zero unless said. Every trace has three observations one second apart: at 0 ego is on its
  approach and b on its own, at 1 b is inside the crossing and ego either enters it (forbid, idle,
  blind, branch_1/2/4–7) or is at rest just short of it (permit), at 2 ego is inside. Every scene
  declares that no vehicle present intends a left turn at 10.

  Conflict figures (horizon 3 s, clearance 3 m in the reading): in forbid at 1 s ego (2.5, -4.5)
  north 5 m/s, b (-1.5, -3.5) east 5 m/s: closest approach after 0.5 s at about 2.12 m. In permit
  at 1 s ego at rest at (2.5, -6), b (-1.5, -3.5) east 5 m/s: after 0.8 s at 2.5 m. In branch_1/7
  at 1 s ego (1.5, -4.5) north 5 m/s, b (-0.5, 4.5) south 5 m/s: after 0.9 s at 2 m. In branch_6 at
  1 s ego (1.5, -3) north 5 m/s, b (0, 1) east 5 m/s: after 0.55 s at about 1.77 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: ego ↦ 1

/-- A point, in centimetres. -/
def at_ (x y : Int) : Vec := (cm x, cm y)

def box (x0 y0 x1 y1 : Int) : List Vec := [at_ x0 y0, at_ x1 y0, at_ x1 y1, at_ x0 y1]

/-- An approach lane entering intersection 10, lying on highway `way`. -/
def approach (id : RegionId) (bd : List Vec) (dir : Vec) (way : RegionId) : Structure :=
  { Build.lane id bd dir (enters := some 10) with ways := some [way] }

/-- The crossing; `northWay` is the highway the north approach lies on. -/
def structures (northWay : RegionId := 1) : List Structure :=
  [ Build.rect 1 .highway (m (-5)) (m (-130)) (m 5) (m 60)
  , Build.rect 2 .highway (m (-60)) (m (-5)) (m 60) (m 5) ]
  ++ (if northWay == 1 then [] else [Build.rect northWay .highway (m (-5)) (m 5) (m 5) (m 60)])
  ++
  [ Build.rect 10 .intersection (m (-5)) (m (-5)) (m 5) (m 5)
  , approach 11 (box 0 (-6000) 500 (-500)) Build.north 1
  , approach 12 (box (-500) 500 0 6000) Build.south northWay
  , approach 21 (box (-6000) (-500) (-500) 0) Build.east 2
  , approach 22 (box 500 0 6000 500) Build.west 2 ]

/-- A motor vehicle at a point, with heading, speed and yaw rate. -/
def car (track : TrackId) (pos : Vec) (h : Vec) (v : Q) (yaw : Q := Q.zero) : RoadUser :=
  Build.withKin (Build.user track [.motorVehicle] pos h v (m 2, m 1, m 1)) fun k => { k with yawRate := some yaw }

/-- Neither vehicle intends a left turn at the crossing. -/
def noLeft : List DeclaredIntent :=
  [ { vehicle := 1, target := 10, values := [("int.left_turn", false)] }
  , { vehicle := 2, target := 10, values := [("int.left_turn", false)] } ]

def sc (t : Timestamp) (users : List RoadUser) (devices : List Device) (northWay : RegionId := 1) : Scene :=
  Build.scene t (some 1) users (structures northWay) devices
    (intents := noLeft.filter fun d => users.any (·.track == d.vehicle))

def mps (n : Int) : Q := Units.metresPerSecond n

/-- Ego enters at 1 s while b, from highway B, crosses its path (the forbid motion). -/
def crossingTrace (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sc t [car 1 (at_ 250 (-950)) Build.north (mps 5), car 2 (at_ (-650) (-350)) Build.east (mps 5)] devices
    | 1 => sc t [car 1 (at_ 250 (-450)) Build.north (mps 5), car 2 (at_ (-150) (-350)) Build.east (mps 5)] devices
    | _ => sc t [car 1 (at_ 250 50) Build.north (mps 5), car 2 (at_ 350 (-350)) Build.east (mps 5)] devices

/-- `forbid` (violated): No device governs the intersection or its approaches. Ego approaches on highway A; vehicle b has entered from highway B and is crossing; ego keeps moving and enters while their projected closest approach lies within p.conflict_horizon below p.conflict_clearance. -/
def forbidTrace : Trace := crossingTrace []

/-- `permit` (compliant): Same scene; ego slows and comes to rest at the edge of the intersection until b has cleared, then enters with no projected conflict. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sc t [car 1 (at_ 250 (-1100)) Build.north (mps 5), car 2 (at_ (-650) (-350)) Build.east (mps 5)] []
    | 1 => sc t [car 1 (at_ 250 (-600)) Build.north Q.zero, car 2 (at_ (-150) (-350)) Build.east (mps 5)] []
    | _ => sc t [car 1 (at_ 250 (-450)) Build.north (mps 3), car 2 (at_ 850 (-350)) Build.east (mps 5)] []

/-- `idle` (not_applicable): Stop signs govern the approaches of highway B: the intersection is controlled by official traffic-control devices, and no inoperative signal is involved. -/
def idleTrace : Trace :=
  crossingTrace [Build.sign 40 .stopSign [21], Build.sign 41 .stopSign [22]]

/-- `blind` (unknown): Scene of forbid, but the source declares st.lane_enters absent: whether ego approaches the intersection cannot be read. -/
def blindTrace : Trace := crossingTrace []

/-- Ego northbound enters at 1 s; b from the north approach (on `northWay`) passes 2 m to its
    left, southbound, without turning. -/
def opposingTrace (northWay : RegionId) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sc t [car 1 (at_ 150 (-950)) Build.north (mps 5), car 2 (at_ (-50) 950) Build.south (mps 5)] [] northWay
    | 1 => sc t [car 1 (at_ 150 (-450)) Build.north (mps 5), car 2 (at_ (-50) 450) Build.south (mps 5)] [] northWay
    | _ => sc t [car 1 (at_ 150 50) Build.north (mps 5), car 2 (at_ (-50) (-50)) Build.south (mps 5)] [] northWay

/-- `branch_1` (compliant): No device governs the intersection. Vehicle b entered from the opposite approach of ego's own highway A; no vehicle from a different highway is within the intersection; ego enters. -/
def branch_1Trace : Trace := opposingTrace 1

/-- `branch_2` (violated): An inoperative traffic signal governs the intersection (NRS_484B_250_4_o1 applies to ego's entry), so the device exception is suspended; ego enters in conflict with b, which entered from highway B. -/
def branch_2Trace : Trace :=
  crossingTrace [{ Build.signal 30 [10] [.dark] with inoperative := some true, uncovered := some true }]

/-- `branch_4` (not_applicable): the forbid motion, but a yield sign governs the intersection itself. -/
def branch_4Trace : Trace := crossingTrace [Build.sign 42 .yieldSign [10]]

/-- `branch_5` (not_applicable): the forbid motion, but an operating traffic signal (circular green,
    not inoperative) governs ego's approach lane. -/
def branch_5Trace : Trace :=
  crossingTrace [{ Build.signal 31 [11] [.circularGreen] with inoperative := some false, uncovered := some true }]

/-- `branch_6` (compliant): b enters from the opposite approach, which lies on a different highway
    (C), turning left — south to east over the second before 1 s, a yaw rate of 90 deg/s — as ego
    enters in conflict with it: the opposing-left-turn exception lifts the duty. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sc t [car 1 (at_ 150 (-800)) Build.north (mps 5), car 2 (at_ (-50) 600) Build.south (mps 5)] [] 3
    | 1 => sc t [car 1 (at_ 150 (-300)) Build.north (mps 5), car 2 (at_ 0 100) Build.east (mps 5) (Units.degrees 90)] [] 3
    | _ => sc t [car 1 (at_ 150 200) Build.north (mps 5), car 2 (at_ 450 100) Build.east (mps 5)] [] 3

/-- `branch_7` (violated): as branch_6, but nobody turns or intends to turn left: ego proceeds in
    conflict with b, which entered from a different highway. -/
def branch_7Trace : Trace := opposingTrace 3

/-- A second, narrow crossing just south of 10: intersection 50 (x ∈ [-5, 5], y ∈ [-63, -60]) where
    highway A meets a one-lane highway D (region 4); lane 31 (x ∈ [0, 5], y ∈ [-120, -63], on A)
    is the northbound approach to 50, lane 41 (x ∈ [-60, -5], y ∈ [-63, -60], on D) the eastbound
    one. Lane 11 begins where 50 ends. -/
def southCrossing : List Structure :=
  [ Build.rect 4 .highway (m (-60)) (m (-63)) (m 60) (m (-60))
  , Build.rect 50 .intersection (m (-5)) (m (-63)) (m 5) (m (-60))
  , { Build.lane 31 (box 0 (-12000) 500 (-6300)) Build.north (enters := some 50) with ways := some [1] }
  , { Build.lane 41 (box (-6000) (-6300) (-500) (-6000)) Build.east (enters := some 50) with ways := some [4] } ]

/-- At 1 s ego's body (centre (2.5, -61.5)) spans lane 31, crossing 50 and lane 11: it enters 50
    from 31 and approaches 10 through 11 at once. b, from highway D, is inside 50 in conflict with
    it (closest approach after about 0.39 s at about 2.56 m). Occupancy is stated from the bodies. -/
def twoCrossings (devices : List Device) : Trace :=
  let scn (t : Timestamp) (users : List RoadUser) (occ : List (TrackId × RegionId)) : Scene :=
    Build.scene t (some 1) users (structures 1 ++ southCrossing) devices (occupies := some occ)
      (intents := noLeft)
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => scn t [car 1 (at_ 250 (-6650)) Build.north (mps 5), car 2 (at_ (-750) (-6150)) Build.east (mps 6)]
        [(1, 31), (1, 1), (2, 41), (2, 4)]
    | 1 => scn t [car 1 (at_ 250 (-6150)) Build.north (mps 5), car 2 (at_ (-150) (-6150)) Build.east (mps 6)]
        [(1, 31), (1, 50), (1, 11), (1, 1), (1, 4), (2, 50), (2, 1), (2, 4)]
    | _ => scn t [car 1 (at_ 250 (-5650)) Build.north (mps 5), car 2 (at_ 450 (-6150)) Build.east (mps 6)]
        [(1, 11), (1, 1), (2, 50), (2, 1), (2, 4)]

/-- `branch_8` (compliant): a stop sign governs ego's approach 31 to crossing 50, so 50 is excepted;
    ego approaches the uncontrolled crossing 10, where no vehicle has entered, while entering 50 in
    conflict with b. -/
def branch_8Trace : Trace := twoCrossings [Build.sign 43 .stopSign [31]]

/-- `branch_9` (compliant): as branch_8, with a yield sign governing crossing 50 itself. -/
def branch_9Trace : Trace := twoCrossings [Build.sign 44 .yieldSign [50]]

/-- `branch_3` (compliant): No device governs the intersection and ego approaches and enters with no other road user in the scene.
    The south crossing 50 is present too, far behind ego: at 2 s ego is inside 10 and on no
    carrier, so no carrier selects either intersection (10 is no carrier into 50). -/
def branch_3Trace : Trace :=
  let scn (t : Timestamp) (u : RoadUser) : Scene :=
    Build.scene t (some 1) [u] (structures 1 ++ southCrossing) [] (intents := noLeft.filter (·.vehicle == 1))
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => scn t (car 1 (at_ 250 (-950)) Build.north (mps 5))
    | 1 => scn t (car 1 (at_ 250 (-450)) Build.north (mps 5))
    | _ => scn t (car 1 (at_ 250 50) Build.north (mps 5))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_enters"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant ]

end TrafficSpecWitness.NRS_484B_250_1
