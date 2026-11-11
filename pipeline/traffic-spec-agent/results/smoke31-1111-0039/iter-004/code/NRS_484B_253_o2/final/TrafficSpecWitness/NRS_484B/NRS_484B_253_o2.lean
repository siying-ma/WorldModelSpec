/-
  Witnesses for NRS_484B_253_o2.

  The map (static in every scene; +x east, +y north, metres):
    intersection i (20): the square x ∈ [-20, 20], y ∈ [-20, 20].
    c2 (11): eastbound approach lane of i from the west, x ∈ [-40, -20], y ∈ [-4, 0], entering i.
    u0 (10): eastbound lane upstream of c2, x ∈ [-60, -40], y ∈ [-4, 0], leading to c2 (enters no
      intersection).
    c (12): westbound approach lane of i from the east, x ∈ [20, 140], y ∈ [0, 4], entering i;
      its direction is opposed to c2's.
    n_out (13): northbound exit lane, x ∈ [0, 4], y ∈ [20, 60].
  Bodies: x (track 1) and y (track 2) are motor vehicles 4 m long and 2 m wide. Occupancy is stated
  from the footprints (a body touching a region's edge occupies it): an axis-aligned body by its
  rectangle, y while turning by a 6 m square around it that lies inside i.

  The turning family (forbid, blind, branch_1, branch_3 … branch_6), sampled every 50 ms (k is the
  observation index, t = 50·k ms):
    k 0–1: y on u0 at 10 m/s; k 2: y comes onto c2 (touches it); k 42: y enters i (body across c2
    and i until k 50, in i only from k 51); k 56–60: y waits at (-15, -2); from k 61: y turns left
    inside i at 4 m/s and 15 deg/s, a quarter turn by k 180; int.left_turn declared for y at i
    throughout. x is in the recording from k 160 only (no opposing vehicle near while y waits and
    begins its turn), drives west on c at 10 m/s and enters i at the judged observation k 180.
    Signals: forbid and blind: turn indicator left at k 10–30 (y on c2 only from k 11), off
    elsewhere; hand signal none. blind masks both signal atoms.
  branch_1: no signal at any observation (indicator off, hand signal none).
  branch_2: y turns at 2 m/s and 6 deg/s from k 61 (4 m/s and 15 deg/s over the last ten
    observations); x, in the recording throughout, drives at 15 m/s and is 15 m from i (front of
    its body) when y's turn begins at k 61; it enters i at k 81.
  branch_3: the left signal is a hand signal (k 10–30), the indicator stays off.
  branch_4: the indicator is lit only after y is wholly in i (k 52–70).
  branch_5: y turns at 4 m/s and 15 deg/s from k 61 to k 140 (60°) and then stands still: it is
    not turning at x's entry, but has turned past the recognition angle since entering i.
  branch_6: as forbid, with the observation at k 50 missing, so y's heading change since its entry
    into i is unknown and its turning alone shows the turn.
  permit: y has crossed i northbound and is on n_out; x waits on c at standstill, then enters i at
    k 42 as the only road user in it.
  idle: x drives west on c far from i and enters no intersection.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1
def trX : TrackId := 1
def trY : TrackId := 2

def rU0 : RegionId := 10
def rC2 : RegionId := 11
def rC : RegionId := 12
def rN : RegionId := 13
def rI : RegionId := 20

/-- An axis-aligned box: x0, y0, x1, y1. -/
abbrev Box := Q × Q × Q × Q

def u0Box : Box := (m (-60), m (-4), m (-40), m 0)
def c2Box : Box := (m (-40), m (-4), m (-20), m 0)
def cBox : Box := (m 20, m 0, m 140, m 4)
def nBox : Box := (m 0, m 20, m 4, m 60)
def iBox : Box := (m (-20), m (-20), m 20, m 20)

def corners (b : Box) : List Vec :=
  match b with
  | (x0, y0, x1, y1) => [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def boxes : List (RegionId × Box) :=
  [(rU0, u0Box), (rC2, c2Box), (rC, cBox), (rN, nBox), (rI, iBox)]

def structures : List Structure :=
  [ Build.lane rU0 (corners u0Box) Build.east (leadsTo := some [rC2])
  , Build.lane rC2 (corners c2Box) Build.east (enters := some rI)
  , Build.lane rC (corners cBox) Build.west (enters := some rI)
  , Build.lane rN (corners nBox) Build.north
  , Build.region rI .intersection (corners iBox) ]

/-- A body's state at one observation; `hx`, `hy` are the half-sizes of the axis-aligned box
    that holds its footprint. -/
structure Pose where
  pos : Vec
  heading : Vec
  speed : Q
  yaw : Q
  hx : Q
  hy : Q

def touches (b : Box) (p : Vec) (hx hy : Q) : Bool :=
  match b with
  | (x0, y0, x1, y1) =>
    Q.le x0 (Q.add p.1 hx) && Q.le (Q.sub p.1 hx) x1 && Q.le y0 (Q.add p.2 hy) && Q.le (Q.sub p.2 hy) y1

def occ (tr : TrackId) (p : Pose) : List (TrackId × RegionId) :=
  boxes.filterMap fun (r, b) => if touches b p.pos p.hx p.hy then some (tr, r) else none

def mkUser (tr : TrackId) (p : Pose) (ti : TurnIndicatorState) (hs : HandSignal) : RoadUser :=
  Build.withSignals
    (Build.withKin (Build.user tr [.motorVehicle] p.pos p.heading p.speed (m 2, m 1, m 1))
      fun k => { k with yawRate := some p.yaw })
    fun s => { s with turnIndicator := some ti, handSignal := some hs }

def leftTurnIntent : List DeclaredIntent :=
  [{ vehicle := trY, target := rI, values := [("int.left_turn", true)] }]

/-- x on c, driving west at `step` per observation, entering i at observation kJ. -/
def xOnC (kJ : Nat) (step speed : Q) (k : Nat) : Pose :=
  { pos := (Q.add (m 22) (Q.mul step (Q.ofInt ((kJ - k : Nat) : Int))), m 2)
    heading := Build.west, speed := speed, yaw := Q.zero, hx := m 2, hy := m 1 }

/-- y from u0 over c2 into i, then waiting at (-15, -2) (observations 0 … 60). -/
def yApproach (k : Nat) : Pose :=
  if k ≤ 56 then
    { pos := (Q.add (m (-43)) (cm (50 * (k : Int))), m (-2)), heading := Build.east
      speed := Units.metresPerSecond 10, yaw := Q.zero, hx := m 2, hy := m 1 }
  else
    { pos := (m (-15), m (-2)), heading := Build.east
      speed := Q.zero, yaw := Q.zero, hx := m 2, hy := m 1 }

/-- y turning left inside i from observation 61 until x's entry at kJ, faster over the last ten. -/
def ySlowTurn (kJ : Nat) (k : Nat) : Pose :=
  if k ≤ 60 then yApproach k
  else
    let j : Int := ((k - 60 : Nat) : Int)
    let fast : Bool := decide (kJ < k + 10)
    { pos := (Q.add (m (-15)) (cm (10 * j)), Q.add (m (-2)) (Units.micrometres (500 * j * j)))
      heading := (Q.ofInt 1, Units.ratio j 200)
      speed := if fast then Units.metresPerSecond 4 else Units.metresPerSecond 2
      yaw := if fast then Units.degrees 15 else Units.degrees 6
      hx := m 3, hy := m 3 }

/-- y turning left at 4 m/s and 15 deg/s from observation 61 on, a quarter turn by observation 180. -/
def yTurnOn (k : Nat) : Pose :=
  if k ≤ 60 then yApproach k
  else
    let j : Int := ((k - 60 : Nat) : Int)
    { pos := (Q.add (m (-15)) (Units.millimetres (125 * j)), Q.add (m (-2)) (Units.micrometres (1000 * j * j)))
      heading := (Q.ofInt (120 - j), Q.ofInt j)
      speed := Units.metresPerSecond 4, yaw := Units.degrees 15, hx := m 3, hy := m 3 }

/-- y turning left at 15 deg/s from observation 61 to 140 (60°), then standing still. -/
def yTurnThenStop (k : Nat) : Pose :=
  if k ≤ 60 then yApproach k
  else if k ≤ 140 then
    let j : Int := ((k - 60 : Nat) : Int)
    { pos := (Q.add (m (-15)) (cm (20 * j)), Q.add (m (-2)) (Units.micrometres (1250 * j * j)))
      heading := (Q.ofInt 1, Units.ratio j 50)
      speed := Units.metresPerSecond 4, yaw := Units.degrees 15, hx := m 3, hy := m 3 }
  else
    { pos := (m 1, m 6), heading := (Q.ofInt 1, Units.ratio 80 50)
      speed := Q.zero, yaw := Q.zero, hx := m 3, hy := m 3 }

def between (a b k : Nat) : Bool := a ≤ k && k ≤ b

def sigIndicator (k : Nat) : TurnIndicatorState × HandSignal :=
  if between 10 30 k then (.left, .noSignal) else (.off, .noSignal)
def sigNone (_k : Nat) : TurnIndicatorState × HandSignal := (.off, .noSignal)
def sigHand (k : Nat) : TurnIndicatorState × HandSignal :=
  if between 10 30 k then (.off, .left) else (.off, .noSignal)
def sigLate (k : Nat) : TurnIndicatorState × HandSignal :=
  if between 52 70 k then (.left, .noSignal) else (.off, .noSignal)

/-- The turning family: x is in the recording from observation kA, and enters i at kJ. -/
def turnTrace (kJ kA : Nat) (xStep xSpeed : Q) (yPose : Nat → Pose)
    (sig : Nat → TurnIndicatorState × HandSignal) : Trace :=
  Build.trace (kJ + 1) 0 (Units.milliseconds 50) fun k t =>
    let xp := xOnC kJ xStep xSpeed k
    let yp := yPose k
    let yu := mkUser trY yp (sig k).1 (sig k).2
    if kA ≤ k then
      Build.scene t (some 1)
        [ mkUser trX xp .off .noSignal, yu ]
        structures
        [ ]
        (occupies := some (occ trX xp ++ occ trY yp))
        (intents := leftTurnIntent)
    else
      Build.scene t none
        [ yu ]
        structures
        [ ]
        (occupies := some (occ trY yp))
        (intents := leftTurnIntent)

/-- `forbid` (violated): The recording begins with y on a carrier upstream of c2; y comes onto c2 and signals with sig.turn_indicator left on c2, int.left_turn y i declared, enters i through c2 (recorded), waits in i while no opposing vehicle is near, and now turns left (kin.yaw_rate 15 deg/s, 4 m/s); x on c (opposed to c2) enters i. -/
def forbidTrace : Trace :=
  turnTrace 180 160 (cm 50) (Units.metresPerSecond 10) yTurnOn sigIndicator

/-- `permit` (compliant): x waits on c and enters i after y has left it, as the only road user in i. -/
def permitTrace : Trace :=
  Build.trace 43 0 (Units.milliseconds 50) fun k t =>
    let xp : Pose :=
      if k ≤ 36 then
        { pos := (m 25, m 2), heading := Build.west, speed := Q.zero, yaw := Q.zero, hx := m 2, hy := m 1 }
      else
        { pos := (Q.sub (m 25) (cm (50 * ((k - 36 : Nat) : Int))), m 2), heading := Build.west
          speed := Units.metresPerSecond 10, yaw := Q.zero, hx := m 2, hy := m 1 }
    let yp : Pose :=
      { pos := (m 2, Q.add (m 10) (cm (50 * (k : Int)))), heading := Build.north
        speed := Units.metresPerSecond 10, yaw := Q.zero, hx := m 1, hy := m 2 }
    Build.scene t (some 1)
      [ mkUser trX xp .off .noSignal, mkUser trY yp .off .noSignal ]
      structures
      [ ]
      (occupies := some (occ trX xp ++ occ trY yp))

/-- `idle` (not_applicable): x drives along a road segment and enters no intersection. -/
def idleTrace : Trace :=
  Build.trace 10 0 (Units.milliseconds 50) fun k t =>
    let xp : Pose :=
      { pos := (Q.sub (m 100) (cm (50 * (k : Int))), m 2), heading := Build.west
        speed := Units.metresPerSecond 10, yaw := Q.zero, hx := m 2, hy := m 1 }
    Build.scene t (some 1)
      [ mkUser trX xp .off .noSignal ]
      structures
      [ ]
      (occupies := some (occ trX xp))

/-- `blind` (unknown): As forbid, with y's arrival on c2 and its entry into i recorded, but neither sig.turn_indicator nor sig.hand_signal of y is observed. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): As forbid, but y's sig.turn_indicator is off and sig.hand_signal no_signal at every observation: y gave no signal, and x owes it no precedence under this duty. -/
def branch_1Trace : Trace :=
  turnTrace 180 160 (cm 50) (Units.metresPerSecond 10) yTurnOn sigNone

/-- `branch_2` (compliant): As forbid, but y began its turn while x was 15 m from i at 15 m/s on c, so NRS_484B_253_o1 was not complied with by y: y has not so yielded. -/
def branch_2Trace : Trace :=
  turnTrace 81 0 (cm 75) (Units.metresPerSecond 15) (ySlowTurn 81) sigIndicator

/-- `branch_3` (violated): As forbid, but y's signal is a left hand signal, its indicator off. -/
def branch_3Trace : Trace :=
  turnTrace 180 160 (cm 50) (Units.metresPerSecond 10) yTurnOn sigHand

/-- `branch_4` (violated): As forbid, but y lights its left indicator only once wholly in i. -/
def branch_4Trace : Trace :=
  turnTrace 180 160 (cm 50) (Units.metresPerSecond 10) yTurnOn sigLate

/-- `branch_6` (violated): As forbid, but the observation at 2.5 s (y across c2 and i) is missing, so
    y's heading change since its entry is unknown and its turning alone shows the turn. -/
def branch_6Trace : Trace :=
  (turnTrace 180 160 (cm 50) (Units.metresPerSecond 10) yTurnOn sigIndicator).filter
    fun s => s.t != 2500

/-- `branch_5` (violated): As forbid, but y has turned 60° since entering i and stands still when x enters. -/
def branch_5Trace : Trace :=
  turnTrace 180 160 (cm 50) (Units.metresPerSecond 10) yTurnThenStop sigIndicator

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_253_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window
    boundary := boundary }

/-- The judged observation: x's entry into i at observation kJ. -/
def judged (kJ : Nat) : Option (Timestamp × Timestamp) :=
  some (((50 * kJ : Nat) : Timestamp), ((50 * kJ : Nat) : Timestamp))

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := judged 180)
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator", "sig.hand_signal"] (window := judged 180)
  , witness "branch_1" branch_1Trace .compliant (window := judged 180)
  , witness "branch_2" branch_2Trace .compliant (window := judged 81)
  , witness "branch_3" branch_3Trace .violated (window := judged 180)
  , witness "branch_4" branch_4Trace .violated (window := judged 180)
  , witness "branch_5" branch_5Trace .violated (window := judged 180)
  , witness "branch_6" branch_6Trace .violated (window := judged 180) ]

end TrafficSpecWitness.NRS_484B_253_o2
