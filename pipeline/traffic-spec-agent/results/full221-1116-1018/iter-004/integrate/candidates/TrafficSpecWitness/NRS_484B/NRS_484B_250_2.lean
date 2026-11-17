/-
  Witnesses for NRS_484B_250_2.

  Layout A (perpendicular approaches, 2 Hz unless stated):
    intersection 100: the square (−5,−5)–(5,5), on highways 101 (east–west strip |y| ≤ 5) and
      102 (north–south strip |x| ≤ 5);
    carrier 110: eastbound lane (−18,−5)–(−5,0), enters 100, on 101 — the subject's approach;
    carrier 120: northbound lane (0,−18)–(5,−5), enters 100, on 102 — v from the south;
    carrier 130: southbound lane (−5,5)–(0,14), enters 100, on 102 — v from the north.
    The subject (track 1) drives east at y = −2.5; v (track 2) drives north at x = 2.5 or south at
    x = −2.5. Bodies are 4 m × 2 m. Arrival is the observation at which the body first comes
    within the stop-point tolerance (2 m) of the intersection: the subject at x ≥ −9, v from the
    south at y ≥ −9. Every road user starts off every carrier, so the `since` of the arrival is
    decided from the first observation.
  Layout B (opposed approaches, for the left-turn exception):
    intersection 300: (−10,−10)–(10,10) on highways 301 and 303;
    carrier 310: eastbound (−20,−5)–(−10,0), enters 300, on 301 (subject at y = −3.5);
    carrier 320: westbound (10,−10)–(20,−5), enters 300, on 303 (v at y = −6, on the subject's
      right, 2.5 m off its line, so the closest approach of the centres is 2.5 m).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def highway (id : RegionId) (b : List Vec) : Structure := Build.region id .highway b

def junction (id : RegionId) (b : List Vec) (ways : List RegionId) : Structure :=
  { Build.region id .intersection b with ways := some ways }

def carrier (id : RegionId) (b : List Vec) (dir : Vec) (enters way : RegionId) : Structure :=
  { Build.lane id b dir (enters := some enters) with ways := some [way] }

def car (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos heading speed (m 2, m 1, m 1)

def layoutA : List Structure :=
  [ highway 101 (box (m (-30)) (m (-5)) (m 30) (m 5))
  , highway 102 (box (m (-5)) (m (-30)) (m 5) (m 30))
  , junction 100 (box (m (-5)) (m (-5)) (m 5) (m 5)) [101, 102]
  , carrier 110 (box (m (-18)) (m (-5)) (m (-5)) (m 0)) Build.east 100 101
  , carrier 120 (box (m 0) (m (-18)) (m 5) (m (-5))) Build.north 100 102
  , carrier 130 (box (m (-5)) (m 5) (m 0) (m 14)) Build.south 100 102 ]

def layoutB : List Structure :=
  [ highway 301 (box (m (-30)) (m (-10)) (m 10) (m 10))
  , highway 303 (box (m (-10)) (m (-10)) (m 30) (m 10))
  , junction 300 (box (m (-10)) (m (-10)) (m 10) (m 10)) [301, 303]
  , carrier 310 (box (m (-20)) (m (-5)) (m (-10)) (m 0)) Build.east 300 301
  , carrier 320 (box (m 10) (m (-10)) (m 20) (m (-5))) Build.west 300 303 ]

/-- Layout A, subject at 10 m/s east: x = −21, −16, −11, −6 (arrival, k = 3), −1 (in X). -/
def subjectThrough (k : Nat) : RoadUser :=
  car 1 (m (-21 + 5 * (k : Int)), cm (-250)) Build.east (mps 10)

/-- Layout A, v at 10 m/s north: y = −26, −21, −16, −11, −6 (arrival, k = 4), −1, 4, 9 (out). -/
def vFromSouth (k : Nat) : RoadUser :=
  car 2 (cm 250, m (-26 + 5 * (k : Int))) Build.north (mps 10)

/-- Layout A, both proceeding: arrivals 0.5 s apart, v on the right; at k = 4 the centres close
    to 0 m within 0.35 s while the subject moves at 10 m/s; no contact up to k = 4. -/
def crossTrace (n : Nat) (devices : List Device) : Trace :=
  Build.trace n 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1) [subjectThrough k, vFromSouth k] layoutA devices

/-- `forbid` (violated): Uncontrolled X. The subject on c1 and v on c2 (on another highway) arrive within p.same_time_arrival_window of each other; v lies to the subject's right (rel.bearing). The subject proceeds with kin.speed above p.halt_speed_tolerance and its closest approach to v lies within p.conflict_horizon at a centre distance below p.conflict_centre_clearance. -/
def forbidTrace : Trace := crossTrace 5 []

/-- `permit` (compliant): Same arrivals; the subject comes to rest at X's edge until v has crossed, then proceeds.
    The subject halts at x = −8 (1 m from X) from k = 3 to 7, v crosses and leaves X at k = 7,
    the subject proceeds from k = 8. -/
def permitSubject (k : Nat) : RoadUser :=
  if k ≤ 2 then subjectThrough k
  else if k ≤ 7 then car 1 (m (-8), cm (-250)) Build.east (mps 0)
  else car 1 (m (-8 + 5 * ((k : Int) - 8)), cm (-250)) Build.east (mps 10)

def permitTrace : Trace :=
  Build.trace 11 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1) [permitSubject k, vFromSouth k] layoutA []

/-- `idle` (not_applicable): A dev.yield_sign governs c1: X is controlled. -/
def idleTrace : Trace := crossTrace 5 [Build.sign 200 .yieldSign [110]]

/-- `blind` (unknown): Uncontrolled X; simultaneous arrivals from different highways with v on the subject's right; the subject and v are not in contact and their centres' closest approach lies within p.conflict_horizon below p.conflict_centre_clearance; kin.speed is not observed, so whether the subject proceeds rather than holding at rest is unknown. (rel.bearing is computed from positions and headings and is not a mask that can blank which vehicle is on the right.) -/
def blindTrace : Trace := crossTrace 5 []

/-- Layout A, v at 10 m/s south on carrier 130: y = 16, 11, 6 (arrival, k = 2), 1. -/
def vFromNorth (k : Nat) : RoadUser :=
  car 2 (cm (-250), m (16 - 5 * (k : Int))) Build.south (mps 10)

/-- `branch_1` (compliant): Simultaneous arrivals; v lies to the subject's left; the subject proceeds first in conflict with v: no vehicle on its right is owed the right-of-way.
    At k = 3 (the later arrival) the centres close to 0 m within 0.35 s, v to the left. -/
def branch_1Trace : Trace :=
  Build.trace 4 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1) [subjectThrough k, vFromNorth k] layoutA []

/-- `branch_2` (compliant): v on the subject's right arrives several times p.same_time_arrival_window after the subject; the subject proceeds: not approximately the same time.
    The subject arrives at k = 3 (1.5 s) and waits at x = −8; v waits off the map until k = 15,
    arrives at k = 19 (9.5 s, 8 s later); the subject proceeds from k = 18 and at k = 19 the
    centres close to 1.4 m within 0.45 s. -/
def branch_2Subject (k : Nat) : RoadUser :=
  if k ≤ 2 then subjectThrough k
  else if k ≤ 17 then car 1 (m (-8), cm (-250)) Build.east (mps 0)
  else car 1 (m (-8 + 5 * ((k : Int) - 18)), cm (-250)) Build.east (mps 10)

def branch_2V (k : Nat) : RoadUser :=
  if k ≤ 15 then car 2 (cm 250, m (-26)) Build.north (mps 0)
  else car 2 (cm 250, m (-21 + 5 * ((k : Int) - 16))) Build.north (mps 10)

def branch_2Trace : Trace :=
  Build.trace 20 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1) [branch_2Subject k, branch_2V k] layoutA []

/-- `branch_3` (compliant): The subject arrives at uncontrolled X with no other road user in the scene. -/
def branch_3Trace : Trace :=
  Build.trace 5 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1) [subjectThrough k] layoutA []

/-- `branch_4` (not_applicable): the forbid scene, but a traffic signal governs the intersection
    itself: X is controlled. -/
def branch_4Trace : Trace := crossTrace 5 [Build.signal 201 [100] [.circularGreen]]

/-- `branch_5` (not_applicable): the forbid scene, but a stop sign governs c1: X is controlled. -/
def branch_5Trace : Trace := crossTrace 5 [Build.sign 202 .stopSign [110]]

/-- `branch_6` (violated): arrivals 1.5 s apart, v on the right; the subject enters X and halts
    at (1, −2.5) before v arrives (k = 6), so it never moves in conflict with v; v then runs
    into its body at k = 7: the bodies are in contact. -/
def branch_6Subject (k : Nat) : RoadUser :=
  if k ≤ 4 then subjectThrough k
  else car 1 (m 1, cm (-250)) Build.east (mps 0)

def branch_6Vy : Nat → Q
  | 3 => m (-21)
  | 4 => m (-16)
  | 5 => m (-11)
  | 6 => m (-7)
  | 7 => cm (-450)
  | _ => m (-26)

def branch_6V (k : Nat) : RoadUser :=
  car 2 (cm 250, branch_6Vy k) Build.north (if k ≤ 2 then mps 0 else mps 10)

def branch_6Trace : Trace :=
  Build.trace 8 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1) [branch_6Subject k, branch_6V k] layoutA []

/-- Declared intentions at intersection 300: the subject's and v's left-turn plans. -/
def leftTurnIntents (s v : Bool) : List DeclaredIntent :=
  [ { vehicle := 1, target := 300, values := [("int.left_turn", s)] }
  , { vehicle := 2, target := 300, values := [("int.left_turn", v)] } ]

/-- Layout B, both at 10 m/s, 2 Hz: the subject east x = −21, −16, −11 (arrival, k = 2), −6;
    v west x = 21, 16, 11 (arrival, k = 2), 6, on the subject's right; at k = 2 and 3 the
    centres close to 2.5 m within 1.1 s and 0.6 s while the subject moves. -/
def opposedTrace (s v : Bool) : Trace :=
  Build.trace 4 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ car 1 (m (-21 + 5 * (k : Int)), cm (-350)) Build.east (mps 10)
      , car 2 (m (21 - 5 * (k : Int)), m (-6)) Build.west (mps 10) ]
      layoutB [] (intents := leftTurnIntents s v)

/-- `branch_7` (compliant): opposed approaches, the subject declares a left turn at X: the pair
    is excepted, so proceeding in conflict with v is no failure to yield. -/
def branch_7Trace : Trace := opposedTrace true false

/-- `branch_8` (compliant): opposed approaches, v declares a left turn at X: the pair is excepted. -/
def branch_8Trace : Trace := opposedTrace false true

/-- `branch_9` (compliant): opposed approaches at 20 Hz, no left turn declared; both arrive at
    k = 15; the subject holds at x = −13.75 while v enters X (k = 23) and turns left at 120 °/s
    (k = 24 … 33, 60° in all, 48° at k = 31); the subject proceeds from k = 31, in conflict
    with v (centres to 2.5 m within 2.35 s), once v is making a left turn of at least 45°. -/
def branch_9Subject (k : Nat) : RoadUser :=
  if k ≤ 14 then car 1 (cm (-2125 + 50 * (k : Int)), cm (-350)) Build.east (mps 10)
  else if k ≤ 30 then car 1 (cm (-1375), cm (-350)) Build.east (mps 0)
  else car 1 (cm (-1375 + 50 * ((k : Int) - 31)), cm (-350)) Build.east (mps 10)

/-- West turned left (towards south) by 6° per step, `j` steps: (−cos 6j°, −sin 6j°) to 10⁻⁵. -/
def turnedFromWest : Nat → Vec
  | 1 => (Q.mk' (-99452) 100000, Q.mk' (-10453) 100000)
  | 2 => (Q.mk' (-97815) 100000, Q.mk' (-20791) 100000)
  | 3 => (Q.mk' (-95106) 100000, Q.mk' (-30902) 100000)
  | 4 => (Q.mk' (-91355) 100000, Q.mk' (-40674) 100000)
  | 5 => (Q.mk' (-86603) 100000, Q.mk' (-50000) 100000)
  | 6 => (Q.mk' (-80902) 100000, Q.mk' (-58779) 100000)
  | 7 => (Q.mk' (-74314) 100000, Q.mk' (-66913) 100000)
  | 8 => (Q.mk' (-66913) 100000, Q.mk' (-74314) 100000)
  | 9 => (Q.mk' (-58779) 100000, Q.mk' (-80902) 100000)
  | 10 => (Q.mk' (-50000) 100000, Q.mk' (-86603) 100000)
  | _ => Build.west

/-- v's heading: west until k = 23, then 6° further left at each of k = 24 … 33, 60° from k = 33. -/
def branch_9Heading (k : Nat) : Vec :=
  if k ≤ 23 then Build.west else turnedFromWest (min (k - 23) 10)

def branch_9V (k : Nat) : RoadUser :=
  let u := if k ≤ 22 then car 2 (cm (2125 - 50 * (k : Int)), m (-6)) Build.west (mps 10)
    else car 2 (cm 975, m (-6)) (branch_9Heading k) (mps 0)
  Build.withKin u fun kin =>
    { kin with yawRate := some (if 24 ≤ k && k ≤ 33 then Units.degrees 120 else Units.degrees 0) }

def branch_9Trace : Trace :=
  Build.trace 37 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1) [branch_9Subject k, branch_9V k] layoutB []
      (intents := leftTurnIntents false false)

/-- Layout A′: two intersection records over the same square, 100 (approached by carrier 110)
    and 105 (approached by carrier 111, the same eastbound strip, and by carrier 121, the
    northbound strip); a yield sign governs 121, so 105 is controlled and 100 is not. -/
def layoutTwoJunctions : List Structure :=
  [ highway 101 (box (m (-30)) (m (-5)) (m 30) (m 5))
  , highway 102 (box (m (-5)) (m (-30)) (m 5) (m 30))
  , junction 100 (box (m (-5)) (m (-5)) (m 5) (m 5)) [101, 102]
  , junction 105 (box (m (-5)) (m (-5)) (m 5) (m 5)) [101, 102]
  , carrier 110 (box (m (-18)) (m (-5)) (m (-5)) (m 0)) Build.east 100 101
  , carrier 111 (box (m (-18)) (m (-5)) (m (-5)) (m 0)) Build.east 105 101
  , carrier 121 (box (m 0) (m (-18)) (m 5) (m (-5))) Build.north 105 102 ]

/-- `branch_10` (compliant): the forbid motion, but v arrives through carrier 121, which enters
    only intersection 105, and 105 is controlled (a yield sign governs 121): at the uncontrolled
    intersection 100 no vehicle on the right arrived with the subject, and at 105 the section
    does not apply. -/
def branch_10Trace : Trace :=
  Build.trace 5 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1) [subjectThrough k, vFromSouth k] layoutTwoJunctions
      [Build.sign 203 .yieldSign [121]]

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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant ]

end TrafficSpecWitness.NRS_484B_250_2
