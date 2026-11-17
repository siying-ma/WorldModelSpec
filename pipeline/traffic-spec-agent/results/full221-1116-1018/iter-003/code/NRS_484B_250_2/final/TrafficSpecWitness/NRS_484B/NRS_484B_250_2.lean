/-
  Witnesses for NRS_484B_250_2.

  Bodies: every road user is a car of half-length 2 m, half-width 1 m; the subject is track 1, the
  other vehicle v is track 2. Every figure here is the witness's own and appears nowhere in the rule.

  Map G1 (forbid, permit, idle, blind, branch_1..3; one scene per second): intersection X (10) is the
  square [-10, 10]²; highway H1 (20) runs north–south (x ∈ [-10, 10]), highway H2 (21) east–west
  (y ∈ [-10, 10]); X lies on both. Approach lanes entering X: c1 (11) northbound, x ∈ [0, 6],
  y ∈ [-30, -10], on H1 (the subject's); c2 (12) westbound, y ∈ [0, 6], x ∈ [10, 30], on H2 (v from
  the subject's right); c4 (13) eastbound, y ∈ [-6, 0], x ∈ [-30, -10], on H2 (v from the subject's
  left). A second intersection Y (30) north of X, y ∈ [50, 70], is entered by lane c3 (31) on H1,
  which a stop sign (1) governs: a device near X that controls no approach of X.
  Instants: k0 both vehicles are off the approach lanes; k1 both bodies are 0.5 m from X's edge on
  their lanes (the arrival); from k2 the scene of each witness.

  Map G2 (branch_4, branch_5; 50 ms steps around v's entry into X, so v's heading change since its
  entry is integrated): X as in G1, lying on H1 (south) and H2 (north); c1 northbound
  x ∈ [-1, 3.25], c2 southbound x ∈ [3.25, 8], y ∈ [10, 30]: opposed approaches from different
  highways, v (x = 4.5) on the right of the subject (x = 2).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- A car with its yaw rate observed (deg/s). -/
def car (id : TrackId) (pos : Vec) (h : Vec) (speed : Q) (yaw : Q := Units.degrees 0) : RoadUser :=
  Build.withKin (Build.user id [.motorVehicle] pos h speed carExtent) (fun k => { k with yawRate := some yaw })

def noLeftTurn (users : List RoadUser) : List DeclaredIntent :=
  users.map fun u => { vehicle := u.track, target := 10, values := [("int.left_turn", false)] }

-- ---------------------------------------------------------------------------------------------
-- Map G1
-- ---------------------------------------------------------------------------------------------
def g1X : Structure := { Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10) with ways := some [20, 21] }
def g1H1 : Structure := Build.rect 20 .highway (m (-10)) (m (-60)) (m 10) (m 80)
def g1H2 : Structure := Build.rect 21 .highway (m (-60)) (m (-10)) (m 60) (m 10)
def g1C1 : Structure := { Build.lane 11 (box (m 0) (m (-30)) (m 6) (m (-10))) Build.north (enters := some 10) with ways := some [20] }
def g1C2 : Structure := { Build.lane 12 (box (m 10) (m 0) (m 30) (m 6)) Build.west (enters := some 10) with ways := some [21] }
def g1C4 : Structure := { Build.lane 13 (box (m (-30)) (m (-6)) (m (-10)) (m 0)) Build.east (enters := some 10) with ways := some [21] }
def g1Y : Structure := { Build.rect 30 .intersection (m (-10)) (m 50) (m 10) (m 70) with ways := some [20] }
def g1C3 : Structure := { Build.lane 31 (box (m 0) (m 10) (m 6) (m 50)) Build.north (enters := some 30) with ways := some [20] }

def g1Structures : List Structure := [g1X, g1H1, g1H2, g1C1, g1C2, g1C4, g1Y, g1C3]

def stopAtY : Device := Build.sign 1 .stopSign [31]
def yieldOnC1 : Device := Build.sign 2 .yieldSign [11]

def g1Scene (t : Timestamp) (users : List RoadUser) (devs : List Device := [stopAtY]) : Scene :=
  Build.scene t (some 1) users g1Structures devs (intents := noLeftTurn users)

/-- The subject northbound on c1 (x = 3). -/
def sAt (y : Q) (speed : Q) : RoadUser := car 1 (m 3, y) Build.north speed
/-- v westbound on c2 / through X (y = 3). -/
def vWest (x : Q) (speed : Q) : RoadUser := car 2 (x, m 3) Build.west speed

/-- `forbid` (violated): Uncontrolled X. The subject on c1 and v on c2 (on another highway) arrive within p.same_time_arrival_window of each other; v lies to the subject's right (rel.bearing). The subject proceeds with kin.speed above p.halt_speed_tolerance and its closest approach to v lies within p.conflict_horizon at a centre distance below p.conflict_centre_clearance.
    k1 both arrive at once (v to the right); k2 both bodies wholly inside X, the subject at 5 m/s
    north at (3, -3), v at 2 m/s west at (6, 3): closest approach after about 1.2 s at about 0.6 m. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => g1Scene t [sAt (m (-40)) (Units.metresPerSecond 5), vWest (m 40) (Units.metresPerSecond 5)]
    | 1 => g1Scene t [sAt (cm (-1250)) (Units.metresPerSecond 0), vWest (cm 1250) (Units.metresPerSecond 0)]
    | _ => g1Scene t [sAt (m (-3)) (Units.metresPerSecond 5), vWest (m 6) (Units.metresPerSecond 2)]

/-- `permit` (compliant): Same arrivals; the subject comes to rest at X's edge until v has crossed, then proceeds.
    k1–k3 the subject at rest at the edge while v crosses X; k4 v has left X westward, the subject
    proceeds; k5 the subject inside X. -/
def permitTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => g1Scene t [sAt (m (-40)) (Units.metresPerSecond 5), vWest (m 40) (Units.metresPerSecond 5)]
    | 1 => g1Scene t [sAt (cm (-1250)) (Units.metresPerSecond 0), vWest (cm 1250) (Units.metresPerSecond 5)]
    | 2 => g1Scene t [sAt (cm (-1250)) (Units.metresPerSecond 0), vWest (m 0) (Units.metresPerSecond 5)]
    | 3 => g1Scene t [sAt (cm (-1250)) (Units.metresPerSecond 0), vWest (m (-8)) (Units.metresPerSecond 5)]
    | 4 => g1Scene t [sAt (m (-3)) (Units.metresPerSecond 5), vWest (m (-20)) (Units.metresPerSecond 5)]
    | _ => g1Scene t [sAt (m 5) (Units.metresPerSecond 5), vWest (m (-32)) (Units.metresPerSecond 5)]

/-- `idle` (not_applicable): A dev.yield_sign governs c1: X is controlled. (The forbid motion.) -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => g1Scene t [sAt (m (-40)) (Units.metresPerSecond 5), vWest (m 40) (Units.metresPerSecond 5)] [stopAtY, yieldOnC1]
    | 1 => g1Scene t [sAt (cm (-1250)) (Units.metresPerSecond 0), vWest (cm 1250) (Units.metresPerSecond 0)] [stopAtY, yieldOnC1]
    | _ => g1Scene t [sAt (m (-3)) (Units.metresPerSecond 5), vWest (m 6) (Units.metresPerSecond 2)] [stopAtY, yieldOnC1]

/-- `blind` (unknown): Uncontrolled X; simultaneous arrivals from different highways; the subject proceeds in conflict with v; rel.bearing is absent, so which vehicle is on the right is unknown.
    k2 the subject inside X at 5 m/s, v still at its edge of X moving west at 5 m/s: closest
    approach after about 1.6 s at about 2.5 m. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => g1Scene t [sAt (m (-40)) (Units.metresPerSecond 5), vWest (m 40) (Units.metresPerSecond 5)]
    | 1 => g1Scene t [sAt (cm (-1250)) (Units.metresPerSecond 0), vWest (cm 1250) (Units.metresPerSecond 0)]
    | _ => g1Scene t [sAt (m (-3)) (Units.metresPerSecond 5), vWest (cm 1250) (Units.metresPerSecond 5)]

/-- v eastbound on c4 / through X. -/
def vEast (pos : Vec) (speed : Q) : RoadUser := car 2 pos Build.east speed

/-- `branch_1` (compliant): Simultaneous arrivals; v lies to the subject's left; the subject proceeds first in conflict with v: no vehicle on its right is owed the right-of-way.
    v arrives on c4 from the west; k2 the subject at (3, -3) at 5 m/s, v at (-3, 1) at 5 m/s east:
    closest approach after 1 s at about 1.4 m. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => g1Scene t [sAt (m (-40)) (Units.metresPerSecond 5), vEast (m (-40), m (-3)) (Units.metresPerSecond 5)]
    | 1 => g1Scene t [sAt (cm (-1250)) (Units.metresPerSecond 0), vEast (cm (-1250), m (-3)) (Units.metresPerSecond 0)]
    | _ => g1Scene t [sAt (m (-3)) (Units.metresPerSecond 5), vEast (m (-3), m 1) (Units.metresPerSecond 5)]

/-- `branch_2` (compliant): v on the subject's right arrives several times p.same_time_arrival_window after the subject; the subject proceeds: not approximately the same time.
    The subject arrives at k1 and waits at the edge; v arrives at k7 (6 s later); k8 the subject
    proceeds in conflict with v as in forbid. -/
def branch_2Trace : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t =>
    let vx : Q := match k with
      | 0 => m 60 | 1 => m 55 | 2 => m 48 | 3 => m 41 | 4 => m 34 | 5 => m 27 | 6 => m 20 | 7 => cm 1250 | _ => m 6
    let s : RoadUser := match k with
      | 0 => sAt (m (-40)) (Units.metresPerSecond 5)
      | 8 => sAt (m (-3)) (Units.metresPerSecond 5)
      | _ => sAt (cm (-1250)) (Units.metresPerSecond 0)
    g1Scene t [s, vWest vx (if k == 8 then Units.metresPerSecond 2 else Units.metresPerSecond 5)]

/-- `branch_3` (compliant): The subject arrives at uncontrolled X with no other road user in the scene. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => g1Scene t [sAt (m (-40)) (Units.metresPerSecond 5)]
    | 1 => g1Scene t [sAt (cm (-1250)) (Units.metresPerSecond 5)]
    | _ => g1Scene t [sAt (m (-3)) (Units.metresPerSecond 5)]

-- ---------------------------------------------------------------------------------------------
-- Map G2: opposed approaches from different highways
-- ---------------------------------------------------------------------------------------------
def g2X : Structure := { Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10) with ways := some [20, 21] }
def g2H1 : Structure := Build.rect 20 .highway (m (-10)) (m (-60)) (m 10) (m 10)
def g2H2 : Structure := Build.rect 21 .highway (m (-10)) (m (-10)) (m 10) (m 60)
def g2C1 : Structure := { Build.lane 11 (box (m (-1)) (m (-30)) (cm 325) (m (-10))) Build.north (enters := some 10) with ways := some [20] }
def g2C2 : Structure := { Build.lane 12 (box (cm 325) (m 10) (m 8) (m 30)) Build.south (enters := some 10) with ways := some [21] }

def g2Scene (t : Timestamp) (users : List RoadUser) : Scene :=
  Build.scene t (some 1) users [g2X, g2H1, g2H2, g2C1, g2C2] [] (intents := noLeftTurn users)

/-- The subject northbound on c1 (x = 2). -/
def s2 (y : Q) (speed : Q) : RoadUser := car 1 (m 2, y) Build.north speed
/-- v southbound on c2 (x = 4.5), with its heading and yaw rate. -/
def v2 (pos : Vec) (h : Vec) (speed : Q) (yaw : Q := Units.degrees 0) : RoadUser := car 2 pos h speed yaw

/-- A trace over the listed instants (ms). -/
def atInstants (ts : List Timestamp) (f : Nat → Timestamp → Scene) : Trace :=
  (List.range ts.length).map fun k => f k (ts.getD k 0)

/-- `branch_4` (violated): opposed approaches from different highways, v on the subject's right,
    neither vehicle intends or makes a left turn (v enters X straight, yaw rate zero): the pair is
    not excepted, and the subject proceeds in conflict with v.
    1000 ms both arrive; 1050 v enters X; 1100 the subject at (2, -6) at 5 m/s north, v at (4.5, 4)
    at 5 m/s south: closest approach after 1 s at 2.5 m. -/
def branch_4Trace : Trace :=
  atInstants [0, 1000, 1050, 1100] fun k t =>
    match k with
    | 0 => g2Scene t [s2 (m (-40)) (Units.metresPerSecond 0), v2 (cm 450, m 40) Build.south (Units.metresPerSecond 0)]
    | 1 => g2Scene t [s2 (cm (-1250)) (Units.metresPerSecond 0), v2 (cm 450, cm 1250) Build.south (Units.metresPerSecond 0)]
    | 2 => g2Scene t [s2 (cm (-1250)) (Units.metresPerSecond 0), v2 (cm 450, cm 750) Build.south (Units.metresPerSecond 5)]
    | _ => g2Scene t [s2 (m (-6)) (Units.metresPerSecond 5), v2 (cm 450, m 4) Build.south (Units.metresPerSecond 5)]

/-- v's heading after turning left by 15°, 30°, 45°, 60° from south (toward east). -/
def rot15 : Vec := (Units.ratio 2588 10000, Units.ratio (-9659) 10000)
def rot30 : Vec := (Units.ratio 5000 10000, Units.ratio (-8660) 10000)
def rot45 : Vec := (Units.ratio 7071 10000, Units.ratio (-7071) 10000)
def rot60 : Vec := (Units.ratio 8660 10000, Units.ratio (-5000) 10000)

/-- `branch_5` (compliant): opposed approaches from different highways, v on the subject's right; v
    is making a left turn: the subject waits at the edge while v enters X (3550 ms, more than the
    window after the arrivals at 1000 ms) and turns left at 300 deg/s for four 50 ms steps (60°);
    at 3800 ms, v at rest at (4, 3), the subject proceeds at 5 m/s from (2, -6) in conflict with it
    (closest approach after 1.8 s at 2 m): the pair is excepted. -/
def branch_5Trace : Trace :=
  atInstants [0, 1000, 2000, 3000, 3500, 3550, 3600, 3650, 3700, 3750, 3800] fun k t =>
    let s : RoadUser := match k with
      | 0 => s2 (m (-40)) (Units.metresPerSecond 0)
      | 10 => s2 (m (-6)) (Units.metresPerSecond 5)
      | _ => s2 (cm (-1250)) (Units.metresPerSecond 0)
    let v : RoadUser := match k with
      | 0 => v2 (cm 450, m 40) Build.south (Units.metresPerSecond 0)
      | 1 | 2 | 3 | 4 => v2 (cm 450, cm 1250) Build.south (Units.metresPerSecond 0)
      | 5 => v2 (cm 450, cm 750) Build.south (Units.metresPerSecond 2)
      | 6 => v2 (cm 440, cm 650) rot15 (Units.metresPerSecond 2) (Units.degrees 300)
      | 7 => v2 (cm 430, cm 550) rot30 (Units.metresPerSecond 2) (Units.degrees 300)
      | 8 => v2 (cm 420, cm 450) rot45 (Units.metresPerSecond 2) (Units.degrees 300)
      | 9 => v2 (cm 400, cm 300) rot60 (Units.metresPerSecond 2) (Units.degrees 300)
      | _ => v2 (cm 400, cm 300) rot60 (Units.metresPerSecond 0)
    g2Scene t [s, v]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_250_2
