/-
  Witnesses for NRS_484B_307_7a_o1.

  Geometry (every figure the witness's own): lane 10 (c), x ∈ [0, 4] m, y ∈ [−40, 0] m, northbound,
  entering intersection 20 (i), x ∈ [−8, 8] m, y ∈ [0, 7.5] m. Signal head 1 governs lane 10.
  Subject car (track 1, motor vehicle, half-extents 2.3 × 0.9 × 0.75 m) on x = 2 m, its centre at
  y = −3.5 + 0.3·k m at scene k (a 6 m/s pace), heading north. 50 scenes at 50 ms (t = 0 … 2450 ms,
  the reviewed 20 Hz sampling, so the heading integration is decided).
  Occupancy, stated: lane 10 for k < 20 (rear behind y = 0), intersection 20 for 5 ≤ k < 45
  (front past y = 0, rear short of y = 7.5): entry at k = 5 (t = 250 ms) from lane 10, exit at
  k = 45 (t = 2250 ms).
  Yaw rate ω for 5 < k ≤ 45, zero elsewhere: the heading change entry → exit is 2 s · ω.
  Straight: ω = 0.5 °/s (1°); left: 44 °/s (+88°); right: −44 °/s (−88°); U-turn: 90 °/s (+180°).
  The heading turns with the yaw rate (each scene's rate held over the interval before it): north
  turned left by the integrated change, its sine and cosine by power series to 10⁻¹⁵. Positions
  follow the straight 6 m/s pace in every scene (branch_1's speed field is 10 m/s: only the state at
  the entry is read by the closest-approach primitives).
  Window: 50 … 2450 ms (the first scene, where `rises` and `since` have no past, is not judged).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_7a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_7a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def nScenes : Nat := 50
def entryK : Nat := 5
def exitK : Nat := 45
def laneC : RegionId := 10
def interI : RegionId := 20
def headS : DeviceId := 1

def structures : List Structure :=
  [ Build.lane laneC [(m 0, m (-40)), (m 4, m (-40)), (m 4, m 0), (m 0, m 0)] Build.north
      (enters := some interI)
  , Build.rect interI .intersection (m (-8)) (m 0) (m 8) (cm 750) ]

def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)

def subjectPos (k : Nat) : Vec := (m 2, cm (30 * (k : Int) - 350))

def yawAt (ω : Q) (k : Nat) : Q := if entryK < k ∧ k ≤ exitK then ω else Q.zero

/-- Rounding to 10⁻¹⁵, so that the series below keep small denominators. -/
def rnd (x : Q) : Q :=
  Units.ratio ((x.num * (1000000000000000 : Int)) / (x.den : Int)) 1000000000000000

/-- π to 16 digits, and degrees to radians. -/
def piQ : Q := Units.ratio 3141592653589793 1000000000000000
def radians (deg : Q) : Q := rnd (Q.div (Q.mul deg piQ) (Units.ratio 180 1))

/-- Power series of sine and cosine (25 terms; the angles here are at most π). -/
def sinAux (x2 : Q) : Nat → Nat → Q → Q → Q
  | 0, _, _, acc => acc
  | fuel + 1, i, term, acc =>
    let next := rnd (Q.neg (Q.div (Q.mul term x2) (Units.ratio (Int.ofNat ((2 * i + 2) * (2 * i + 3))) 1)))
    sinAux x2 fuel (i + 1) next (Q.add acc next)
def cosAux (x2 : Q) : Nat → Nat → Q → Q → Q
  | 0, _, _, acc => acc
  | fuel + 1, i, term, acc =>
    let next := rnd (Q.neg (Q.div (Q.mul term x2) (Units.ratio (Int.ofNat ((2 * i + 1) * (2 * i + 2))) 1)))
    cosAux x2 fuel (i + 1) next (Q.add acc next)
def sinQ (x : Q) : Q := sinAux (rnd (Q.mul x x)) 25 0 x x
def cosQ (x : Q) : Q := cosAux (rnd (Q.mul x x)) 25 0 (Units.ratio 1 1) (Units.ratio 1 1)

/-- The heading change since the start (degrees, left positive): the yaw rate of each scene held
    over the interval before it, as the adapter integrates it. -/
def headingChangeAt (ω : Q) (k : Nat) : Q :=
  Q.mul ω (Q.mul (Units.milliseconds 50) (Units.ratio (Int.ofNat ((min k exitK) - entryK)) 1))

/-- The unit heading at scene k: north turned left by the heading change. -/
def headingAt (ω : Q) (k : Nat) : Vec :=
  let δ := radians (headingChangeAt ω k)
  (Q.neg (sinQ δ), cosQ δ)

def subjectAt (speed ω : Q) (k : Nat) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (subjectPos k) (headingAt ω k) speed carExtent)
    (fun kin => { kin with yawRate := some (yawAt ω k) })

def occAt (k : Nat) : List (TrackId × RegionId) :=
  (if k < 20 then [(1, laneC)] else []) ++ (if entryK ≤ k ∧ k < exitK then [(1, interI)] else [])

def mkTrace (speed ω : Q) (shows : Nat → List SignalIndication)
    (others : Nat → List RoadUser := fun _ => []) : Trace :=
  Build.trace nScenes 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1) (subjectAt speed ω k :: others k) structures
      [Build.signal headS [laneC] (shows k)] (occupies := some (occAt k))

def redFyaLeft : List SignalIndication := [.circularRed, .flashingYellowArrow .left]

def straightYaw : Q := Units.millidegrees 500
def leftYaw : Q := Units.degrees 44
def rightYaw : Q := Units.degrees (-44)
def uTurnYaw : Q := Units.degrees 90
def pace : Q := Units.metresPerSecond 6

/-- `forbid` (violated): Head s governing lane c, which enters i, displays circular_red with flashing_yellow_arrow(left) throughout; the car enters i with no other road user near and passes straight through, heading change 1 degree. -/
def forbidTrace : Trace := mkTrace pace straightYaw (fun _ => redFyaLeft)

/-- `permit` (compliant): Same signal; the car enters i at 6 m/s with no other road user in the scene and turns left, heading change +88 degrees. -/
def permitTrace : Trace := mkTrace pace leftYaw (fun _ => redFyaLeft)

/-- `idle` (not_applicable): s displays circular_green alone from before the entry until after the exit; the car passes straight through i. -/
def idleTrace : Trace := mkTrace pace straightYaw (fun _ => [.circularGreen])

/-- `blind` (unknown): As forbid, but the source supplies no yaw rate for the car inside i: the movement made is unknown. -/
def blindTrace : Trace := Build.masked (Build.manifest ["kin.yaw_rate"]) forbidTrace

/-- `occasion_s1` (violated): s displays circular_red with flashing_yellow_arrow(left) at the car's entry and changes to circular_red with red_arrow(left) while the car is inside i (from k = 20); the car passes straight through: the flashing arrow was displayed for part of the passage only. -/
def occasion_s1Trace : Trace :=
  mkTrace pace straightYaw (fun k => if k < 20 then redFyaLeft else [.circularRed, .redArrow .left])

/-- `occasion_s1_outside` (not_applicable): s displays flashing_yellow_arrow(left) only while the car waits on c (k < 5); from the entry to the exit it displays circular_green alone; the car passes straight through. -/
def occasion_s1_outsideTrace : Trace :=
  mkTrace pace straightYaw (fun k => if k < entryK then redFyaLeft else [.circularGreen])

/-- `occasion_s5` (compliant): s displays flashing_yellow_arrow(left) throughout the passage, with circular_green at the entry and circular_red from midway (k = 25); the car passes straight through: the circular green, displayed with the arrow for part of the passage, permits the straight movement. -/
def occasion_s5Trace : Trace :=
  mkTrace pace straightYaw (fun k =>
    if k < 25 then [.circularGreen, .flashingYellowArrow .left] else redFyaLeft)

/-- `occasion_s5_outside` (violated): s displays flashing_yellow_arrow(left) with circular_green only while the car waits on c (k < 5); from the entry on it displays flashing_yellow_arrow(left) with circular_red; the car passes straight through. -/
def occasion_s5_outsideTrace : Trace :=
  mkTrace pace straightYaw (fun k =>
    if k < entryK then [.circularGreen, .flashingYellowArrow .left] else redFyaLeft)

/-- The oncoming car of `branch_1` (track 2): southbound at 12 m/s on x = 1 m, at the entry
    (k = 5) 15 m ahead of the subject's centre and 1 m to its left. -/
def oncomingAt (k : Nat) : List RoadUser :=
  [Build.user 2 [.motorVehicle] (m 1, cm (1600 - 60 * (k : Int))) Build.south
    (Units.metresPerSecond 12) carExtent]

/-- `branch_1` (violated): s displays circular_red with flashing_yellow_arrow(left); the car turns left but enters i at 10 m/s while an oncoming car 15 m away at 12 m/s closes on it, the closest approach of their centres 0.7 s ahead at 1 m: the entry was not cautious. -/
def branch_1Trace : Trace :=
  mkTrace (Units.metresPerSecond 10) leftYaw (fun _ => redFyaLeft) oncomingAt

/-- `branch_2` (compliant): s displays circular_red with flashing_yellow_arrow(right); the car enters with no one near and turns right, heading change −88 degrees: the movement the arrow indicates. -/
def branch_2Trace : Trace :=
  mkTrace pace rightYaw (fun _ => [.circularRed, .flashingYellowArrow .right])

/-- `branch_3` (compliant): s displays circular_red with flashing_yellow_arrow(left); the car enters with no one near and turns about, heading change +180 degrees: a left arrow indicates the U-turn. -/
def branch_3Trace : Trace := mkTrace pace uTurnYaw (fun _ => redFyaLeft)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_7a_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (50, 2450)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "occasion_s1" occasion_s1Trace .violated
  , witness "occasion_s1_outside" occasion_s1_outsideTrace .notApplicable
  , witness "occasion_s5" occasion_s5Trace .compliant
  , witness "occasion_s5_outside" occasion_s5_outsideTrace .violated
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.NRS_484B_307_7a_o1
