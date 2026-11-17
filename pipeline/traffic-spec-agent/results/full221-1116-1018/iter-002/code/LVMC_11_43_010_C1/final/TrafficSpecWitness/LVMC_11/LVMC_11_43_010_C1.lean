/-
  Witnesses for LVMC_11_43_010_C1.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
  - one scene every 50 ms (the sampling standard), 46 scenes (0 … 2250 ms);
  - the subject (track 1), a passenger car (ru.motor_vehicle), 4.5 m × 1.8 m, travels 1 m per scene
    (20 m/s) along its heading: p(k) = p(k−1) + 1 m · heading(k), starting at (−6.75, 0) heading
    east. Its yaw rate is held over the interval before each scene: zero on scenes 0–15 and 36–45,
    and on scenes 16–35 (twenty intervals, 1 s) +90 deg/s (a quarter turn left), +180 deg/s (a half
    turn left, the U-turn) or −90 deg/s (a quarter turn right). Its heading at every scene is the
    integral of that rate (cos/sin by series, rounded to 1e-6), so heading, velocity and position
    agree with the yaw rate;
  - roundabout r (region 10): its west edge at x = 0, which the car's front crosses between scene 4
    (front at −0.5 m) and scene 5 (front at +0.5 m): the entry, at 250 ms. After the turn the car
    runs straight; the exit edge, perpendicular to its final heading, lies 0.5 m beyond its rear at
    scene 39 and 0.5 m short of it at scene 40: the exit, at 2000 ms. Its other edges lie metres
    away from the footprint. For the U-turn r is stepped (west edge at x = 0 below y = 6 m, at the
    exit edge above), since the car leaves heading west above where it came in;
  - two lanes of one direction: the lane the subject uses has r's outline; the other lane is a
    small strip (30–38 m × −8 to −4 m) the footprint never touches. Lane 11 is ordinal 1 of 2
    (leftmost), lane 12 ordinal 2 of 2. The subject's footprint overlaps r and its lane on scenes
    5–39 and no region otherwise (occupancy stated, footprint overlap);
  - every witness judges the instants from 50 ms on (window), so the first scene, whose previous
    observation the recording lacks, is not judged.
  Heading change from the entry to the exit: +90°, +180° or −90°, each far from the bands' edges.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_C1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_C1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

-- ---------------------------------------------------------------------------------------------
-- Kinematics: headings integrated from the yaw rate, positions from the headings.
-- ---------------------------------------------------------------------------------------------
def roundMicro (q : Q) : Q :=
  Q.mk' ((Q.mul q (Q.ofInt 1000000)).num / ((Q.mul q (Q.ofInt 1000000)).den : Int)) 1000000

/-- (cos x, sin x) for x in radians, by series to degree 17, rounded to 1e-6. -/
def trig (x : Q) : Q × Q :=
  let r := (List.range 18).foldl (fun (acc : Q × Q × Q) n =>
    let term := acc.1
    let c := acc.2.1
    let s := acc.2.2
    let c' := if n % 4 == 0 then Q.add c term else if n % 4 == 2 then Q.sub c term else c
    let s' := if n % 4 == 1 then Q.add s term else if n % 4 == 3 then Q.sub s term else s
    (Q.div (Q.mul term x) (Q.ofInt (Int.ofNat (n + 1))), c', s')) (Q.ofInt 1, Q.zero, Q.zero)
  (roundMicro r.2.1, roundMicro r.2.2)

/-- The witness's own π for the conversion of degrees, 355/113. -/
def piApprox : Q := Units.ratio 355 113

def nScenes : Nat := 46
def entryScene : Nat := 5
def exitScene : Nat := 40
def turnFirst : Nat := 16
def turnLast : Nat := 35

def turning (k : Nat) : Bool := turnFirst ≤ k && k ≤ turnLast

/-- Intervals of turning up to scene k. -/
def turnSteps (k : Nat) : Nat := if k < turnFirst then 0 else (min k turnLast) + 1 - turnFirst

/-- Heading at scene k for a yaw rate `yaw` (deg/s) held over 50 ms intervals. -/
def headingAt (yaw : Q) (k : Nat) : Vec :=
  let deg := Q.mul (Q.mul yaw (Units.milliseconds 50)) (Q.ofInt (Int.ofNat (turnSteps k)))
  trig (Q.div (Q.mul deg piApprox) (Q.ofInt 180))

def vadd (a b : Vec) : Vec := (Q.add a.1 b.1, Q.add a.2 b.2)
def dot (a b : Vec) : Q := Q.add (Q.mul a.1 b.1) (Q.mul a.2 b.2)

def start : Vec := (cm (-675), m 0)

/-- Position at scene k: 1 m per scene along the heading held over the interval before it. -/
def posAt (yaw : Q) (k : Nat) : Vec :=
  (List.range k).foldl (fun p j => vadd p (headingAt yaw (j + 1))) start

/-- The exit edge's coordinate along the final heading `d`: 0.5 m beyond the rear at the scene
    before the exit (rear = centre − 2.25 m along d). -/
def exitEdge (yaw : Q) (d : Vec) : Q := Q.sub (dot (posAt yaw (exitScene - 1)) d) (cm 175)

-- ---------------------------------------------------------------------------------------------
-- Places
-- ---------------------------------------------------------------------------------------------
def rId : RegionId := 10
def inner : RegionId := 11   -- ordinal 1, leftmost
def outer : RegionId := 12   -- ordinal 2

/-- The roundabout's outline for a passage leaving with final heading north, south or west. -/
inductive Leaves | north | south | west

def outline (yaw : Q) : Leaves → List Vec
  | .north => let c := exitEdge yaw Build.north
      [(m 0, m (-10)), (m 40, m (-10)), (m 40, c), (m 0, c)]
  | .south => let c := Q.neg (exitEdge yaw Build.south)
      [(m 0, c), (m 40, c), (m 40, m 10), (m 0, m 10)]
  | .west => let c := Q.neg (exitEdge yaw Build.west)
      [(m 0, m (-10)), (m 40, m (-10)), (m 40, m 30), (c, m 30), (c, m 6), (m 0, m 6)]

def farStrip : List Vec := [(m 30, m (-8)), (m 38, m (-8)), (m 38, m (-4)), (m 30, m (-4))]

def lanes (used : RegionId) (o : List Vec) : List Structure :=
  let poly := fun (id : RegionId) => if id == used then o else farStrip
  [ Build.lane inner (poly inner) Build.east none (some outer) (some 1) (some 2)
  , Build.lane outer (poly outer) Build.east (some inner) none (some 2) (some 2) ]

/-- Scene k of a passage through r in lane `used`, yawing at `yaw` deg/s on the turning scenes. -/
def passage (used : RegionId) (yaw : Q) (leaves : Leaves) (k : Nat) (t : Timestamp) : Scene :=
  let o := outline yaw leaves
  let u := Build.withKin
    (Build.user 1 [.motorVehicle] (posAt yaw k) (headingAt yaw k) (m 20) (cm 225, cm 90, cm 75))
    (fun kin => { kin with yawRate := some (if turning k then yaw else Q.zero) })
  let inside := entryScene ≤ k && k < exitScene
  Build.scene t (some 1) [u] (Build.region rId .roundabout o :: lanes used o) []
    (occupies := some (if inside then [(1, rId), (1, used)] else []))

def passageTrace (used : RegionId) (yaw : Q) (leaves : Leaves) : Trace :=
  Build.trace nScenes 0 (Units.milliseconds 50) (passage used yaw leaves)

/-- `forbid` (violated): A two-lane roundabout r (st.roundabout) whose circulatory and approach lanes carry st.lane_adjacency ordinals 1 (inner, leftmost) and 2 (outer). The subject, a passenger car (ru.motor_vehicle), enters r heading east in the lane of ordinal 2, circulates counter-clockwise in the outer lane and leaves r heading north: its yaw rate, observed at every scene at the sampling standard, integrates to a quarter turn to the left since the entry. At the exit the left turn through r is recognized; the subject occupied a lane of ordinal 2 within r. -/
def forbidTrace : Trace := passageTrace outer (Units.degrees 90) .north

/-- `permit` (compliant): Same roundabout and the same left turn, but the subject enters and circulates in the lane of ordinal 1 only and leaves r heading north. -/
def permitTrace : Trace := passageTrace inner (Units.degrees 90) .north

/-- `idle` (not_applicable): Same roundabout; the subject enters heading east in the lane of ordinal 2 and leaves at the first exit heading south, a quarter turn to the right since the entry: no left turn or U-turn is recognized. -/
def idleTrace : Trace := passageTrace outer (Units.degrees (-90)) .south

/-- `blind` (unknown): As in forbid, but the source does not supply lane ordinals (st.lane_adjacency absent): which lane the subject used is unknown. -/
def blindTrace : Trace := passageTrace outer (Units.degrees 90) .north

/-- `branch_1` (violated): Same roundabout; the subject enters heading east in the lane of ordinal 2, circulates and leaves heading west, a half turn to the left since the entry: a U-turn through r made from the outer lane. -/
def branch_1Trace : Trace := passageTrace outer (Units.degrees 180) .west

/-- `branch_2` (compliant): Same roundabout; the subject makes the U-turn of branch_1 in the lane of ordinal 1 throughout. -/
def branch_2Trace : Trace := passageTrace inner (Units.degrees 180) .west

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_43_010_C1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (50, 2250)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.LVMC_11_43_010_C1
