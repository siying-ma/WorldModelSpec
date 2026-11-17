/-
  Witnesses for NRS_484B_250_1.

  Right-angle junction (forbid, permit, idle, blind, branch_1, branch_2): intersection X (region 10)
  is the square (-10,-10)–(10,10). The subject's carrier c1 (lane 11, x 0..10, y -100..-10) runs
  north into X and lies on highway h1 (20, the north–south way). Carrier c2 (lane 12, x -100..-10,
  y -10..0) runs east into X and lies on highway h2 (21, the east–west way). X lies on both. The
  subject (track 1) runs north at x = 5; v (track 2) runs east at y = -5. At the judged instant
  (t = 1 s) the subject is at (5,-14) and v at (-4,-5), both at 10 m/s: both centres reach (5,-5)
  0.9 s later (inside the 3 s horizon, centre distance 0 m against the 3 m clearance), and the
  bodies (half-length 2 m, half-width 1 m) are about 13 m apart (no contact). v was on c2 at the
  instant before. Decoys in forbid/blind: lane 19 entering another intersection 15 on highway 23,
  governed by a traffic signal (30), a stop sign (31) and a yield sign (32): none governs X or a
  carrier entering X. The subject never enters X in any witness.

  Skewed junction (branch_3, branch_4, branch_5), 50 ms sampling: c1 and h1 as above; carrier c3
  (lane 13, a parallelogram north of X) carries direction (5,-12) (dot with c1's north ≈ -0.92,
  beyond -0.9) and lies on highway h3 (22). v moves at velocity (5,-12) m/s from (-3.5,15.5) and
  enters X between 0.45 s and 0.5 s; the subject waits at (5,-14.4) until 0.7 s, then runs north at
  10 m/s; from 0.75 s both centres converge on one point within about 1 s (closest approach about
  0.1 m); v goes straight (heading change 0°). In branch_5 v instead comes south at 4 m/s at
  x = -5.28, enters X at 0.5 s, turns left 30° per 50 ms to head east at y = 9.63 (heading change
  90° from 0.65 s), and converges with the moving subject on (5, 9.63) about 2.35 s ahead.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def ext : Q × Q × Q := (m 2, m 1, m 1)

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

-- Right-angle junction
def regX : Structure := { Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10) with ways := some [20, 21] }
def regC1 : Structure := { Build.lane 11 (box 0 (-100) 10 (-10)) Build.north (enters := some 10) with ways := some [20] }
def regC2 : Structure := { Build.lane 12 (box (-100) (-10) (-10) 0) Build.east (enters := some 10) with ways := some [21] }
def regH1 : Structure := Build.rect 20 .highway (m (-10)) (m (-100)) (m 10) (m 100)
def regH2 : Structure := Build.rect 21 .highway (m (-100)) (m (-10)) (m 100) (m 10)
-- Decoy junction far to the east
def regX2 : Structure := { Build.rect 15 .intersection (m 100) (m (-10)) (m 120) (m 10) with ways := some [23] }
def regC9 : Structure := { Build.lane 19 (box 105 (-100) 115 (-10)) Build.north (enters := some 15) with ways := some [23] }
def regH9 : Structure := Build.rect 23 .highway (m 100) (m (-100)) (m 120) (m 100)

def crossStructures : List Structure := [regX, regC1, regC2, regH1, regH2]
def decoyStructures : List Structure := [regX2, regC9, regH9]
def decoyDevices : List Device :=
  [ Build.signal 30 [19] [.circularGreen]
  , Build.sign 31 .stopSign [19]
  , Build.sign 32 .yieldSign [19] ]

def subj (pos : Vec) (speed : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos Build.north speed ext) fun k => { k with yawRate := some Q.zero }
def eastbound (x : Q) : RoadUser :=
  Build.withKin (Build.user 2 [.motorVehicle] (x, m (-5)) Build.east (Units.metresPerSecond 10) ext)
    fun k => { k with yawRate := some Q.zero }

/-- The crossing at 1 s spacing: the subject north on c1 at 10 m/s, v east from c2 into X. -/
def crossTrace (decoys : Bool) (devices : List Device := []) : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    let ki : Int := k
    Build.scene t (some 1)
      [ subj (m 5, m (-24 + 10 * ki)) (Units.metresPerSecond 10)
      , eastbound (m (-14 + 10 * ki)) ]
      (crossStructures ++ (if decoys then decoyStructures else []))
      ((if decoys then decoyDevices else []) ++ devices)

/-- `forbid` (violated): No device governs X or its carriers. Vehicle v entered X from carrier c2 on highway h2, on which the subject's carrier c1 does not lie, and is crossing X. The subject on c1 keeps kin.speed well above p.halt_speed_tolerance and its closest approach to v lies within p.conflict_horizon at a centre distance below p.conflict_centre_clearance. -/
def forbidTrace : Trace := crossTrace true

/-- `permit` (compliant): Same scene; the subject comes to rest on c1 short of X until v has cleared, then proceeds. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let ki : Int := k
    Build.scene t (some 1)
      [ subj (m 5, m (-14)) (if k < 3 then Q.zero else Units.metresPerSecond 10)
      , eastbound (m (-14 + 10 * ki)) ]
      crossStructures
      []

/-- `idle` (not_applicable): A dev.stop_sign governs c1: the intersection is controlled. -/
def idleTrace : Trace := crossTrace false [Build.sign 31 .stopSign [11]]

/-- `blind` (unknown): Uncontrolled X; v crossing X from a different highway on a conflicting path; kin.speed is absent, so whether the subject proceeds into the conflict is unknown. -/
def blindTrace : Trace := crossTrace true

/-- `branch_1` (compliant): The subject approaches the uncontrolled X with no other road user in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    let ki : Int := k
    Build.scene t (some 1)
      [ subj (m 5, m (-24 + 10 * ki)) (Units.metresPerSecond 10) ]
      crossStructures
      []

/-- `branch_2` (compliant): v is approaching X on its own carrier and has not entered X; the subject's closest approach to v is in conflict, but v is not a vehicle which has entered the intersection. -/
def branch_2Trace : Trace :=
  Build.trace 2 0 (Units.milliseconds 200) fun k t =>
    let ki : Int := k
    Build.scene t (some 1)
      [ subj (m 5, m (-24 + 2 * ki)) (Units.metresPerSecond 10)
      , eastbound (m (-14 + 2 * ki)) ]
      crossStructures
      []

-- Skewed junction
def regX' : Structure := { Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10) with ways := some [20, 22] }
def regC3 : Structure :=
  { Build.lane 13 [(m (-6), m 10), (m 4, m 10), (m (-21), m 70), (m (-31), m 70)] (m 5, m (-12))
      (enters := some 10) with ways := some [22] }
def regH3 : Structure := Build.region 22 .highway [(m (-10), m 10), (m 10, m 10), (m (-15), m 70), (m (-35), m 70)]
def skewStructures : List Structure := [regX', regC1, regC3, regH1, regH3]

/-- v on the skewed approach: velocity (5,-12) m/s, the given yaw rate (deg/s). -/
def skewV (k : Nat) (yaw : Q) : RoadUser :=
  let ki : Int := k
  Build.withKin
    (Build.user 2 [.motorVehicle] (cm (-350 + 25 * ki), cm (1550 - 60 * ki))
      (Units.ratio 5 13, Units.ratio (-12) 13) (Units.metresPerSecond 13) ext)
    fun kn => { kn with yawRate := some yaw }

/-- The subject waits at (5,-14.4) up to 0.7 s, then runs north at 10 m/s. -/
def skewSubject (k : Nat) : RoadUser :=
  let ki : Int := k
  if k ≤ 14 then subj (m 5, cm (-1440)) Q.zero
  else subj (m 5, cm (-1440 + 50 * (ki - 14))) (Units.metresPerSecond 10)

def skewTrace (yaw : Q) (intents : List DeclaredIntent) : Trace :=
  Build.trace 23 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1) [skewSubject k, skewV k yaw] skewStructures [] (intents := intents)

def leftTurnIntent (who : TrackId) (b : Bool) : DeclaredIntent :=
  { vehicle := who, target := 10, values := [("int.left_turn", b)] }

/-- `branch_3` (compliant): At a skewed junction v entered X from c2 on another highway whose designated direction is opposed to c1's within p.oncoming_heading_cos, and v declares int.left_turn at X; the subject proceeds in conflict with v: the pair is excepted. -/
def branch_3Trace : Trace := skewTrace Q.zero [leftTurnIntent 2 true]

-- `branch_4` (violated): same skewed junction, neither driver declares a left turn and v goes straight
-- through X (heading change 0°): the pair is not excepted and the subject proceeds into the conflict.
def branch_4Trace : Trace := skewTrace Q.zero [leftTurnIntent 1 false, leftTurnIntent 2 false]

/-- v on the skewed approach making a left turn in X at 4 m/s: heading south at x = -5.28 until it
    enters X (0.5 s, at y = 9.9), then turning 30° per 50 ms (600°/s held over the interval before
    each of the scenes at 0.55, 0.6 and 0.65 s) to head east at y = 9.63; heading change 90° since
    its entry from 0.65 s on. -/
def turningV (k : Nat) : RoadUser :=
  let ki : Int := k
  let sq3 : Q := Units.ratio 8660254 10000000
  let (pos, hd, yaw) : Vec × Vec × Q :=
    if k ≤ 10 then ((cm (-528), cm (990 + 20 * (10 - ki))), Build.south, Q.zero)
    else if k = 11 then ((cm (-518), cm 973), (Units.ratio 1 2, Q.neg sq3), Units.degrees 600)
    else if k = 12 then ((cm (-501), cm 963), (sq3, Units.ratio (-1) 2), Units.degrees 600)
    else if k = 13 then ((cm (-481), cm 963), Build.east, Units.degrees 600)
    else ((cm (-501 + 20 * (ki - 12)), cm 963), Build.east, Q.zero)
  Build.withKin (Build.user 2 [.motorVehicle] pos hd (Units.metresPerSecond 4) ext)
    fun kn => { kn with yawRate := some yaw }

-- `branch_5` (compliant): same skewed junction, no left turn declared, but v is making a left turn in X
-- (heading change 90° since its entry while the subject moves, converging on it): the pair is excepted.
def branch_5Trace : Trace :=
  Build.trace 23 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1) [skewSubject k, turningV k] skewStructures []
      (intents := [leftTurnIntent 1 false, leftTurnIntent 2 false])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_1"
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
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_250_1
