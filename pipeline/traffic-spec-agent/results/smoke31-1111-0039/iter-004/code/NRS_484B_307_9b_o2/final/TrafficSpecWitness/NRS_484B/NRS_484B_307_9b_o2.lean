/-
  Witnesses for NRS_484B_307_9b_o2.

  One approach and one junction for every scene. The approach lane c (region 10) runs north,
  x ∈ [0, 4] m, y ∈ [-60, 0] m, and enters the intersection i (region 20), x ∈ [-6, 10] m,
  y ∈ [0, 10] m. The signal head s (device 30) governs c (or, in `branch_11`, i only). x (track 1)
  has half-extents 1 m × 0.4 m × 0.8 m.

  Instants: 100 scenes 50 ms apart (the acquisition's 20 Hz), t = 0 … 4950 ms, index k.
    k 0–9    x rides north on c at 5 m/s (absent in `history_boundary`, where x is halted from k 0);
    k 10–69  x halted on c (speed 0), its front 0.2 m short of i;
    k 70     x moves off at 10 m/s and enters i (footprint over c and i, k 70–73);
    k 74–93  x inside i only;
    k 94     x leaves i; k 95–99 beyond it.
  The yaw rate is zero except, in a turn, at k 80 and 81 inside i: +900 deg/s (left) or −900
  deg/s (right), each held over the 50 ms before its scene, so the heading turns 45° twice (north,
  then north-west or north-east, then west or east): 90° over the passage, far beyond the 45°
  turn recognition angle, while a straight passage keeps 0°. Occupancy is stated per instant (a body over two
  regions). Speeds of 0 and 5/10 m/s lie far either side of the 0.2 m/s resolution.

  Displays (s), by index:
    one rise     circular_red to k 54, circular_red + green_arrow(d) from k 55 (one rise in the wait);
    three rises  red, red+arrow k 15–24, red k 25–34, red+arrow k 35–44, red k 45–54, red+arrow from
                 k 55 (rises at 15, 35, 55: three, more than the literal two);
    green        as three rises, but circular_green at k 25–34 (x stays halted through it).
  The red-with-arrow display is on at the entry (k 70) in every scene.

  Every witness speaks about k 1–99 (`window`): at k 0 there is no earlier observation of x for
  the entry and leaving concepts to compare with.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1
def xId : TrackId := 1
def cId : RegionId := 10
def iId : RegionId := 20
def sId : DeviceId := 30

def laneC : Structure :=
  Build.lane cId [(m 0, m (-60)), (m 4, m (-60)), (m 4, m 0), (m 0, m 0)] Build.north (enters := some iId)
def junction : Structure := Build.rect iId .intersection (m (-6)) (m 0) (m 10) (m 10)

/-- x's reference point (cm north of the stop) at index k. -/
def yCm (startHalted : Bool) (k : Nat) : Int :=
  if k < 10 && !startHalted then -120 - 25 * (10 - (k : Int))
  else if k < 70 then -120
  else -120 + 50 * ((k : Int) - 69)

def speedAt (startHalted : Bool) (k : Nat) : Q :=
  if k < 10 && !startHalted then Units.metresPerSecond 5
  else if k < 70 then Q.zero
  else Units.metresPerSecond 10

/-- The passage's turn: 0 straight, +1 left, −1 right. A turn is two steps of 45° inside i, at
    k 80 and 81 (900 deg/s held over the 50 ms before each), so every heading is exact. -/
def yawAt (turn : Int) (k : Nat) : Q :=
  if turn != 0 && (k == 80 || k == 81) then Units.degrees (900 * turn) else Q.zero

def headingAt (turn : Int) (k : Nat) : Vec :=
  if turn == 0 || k < 80 then Build.north
  else if k == 80 then (if turn > 0 then (m (-1), m 1) else (m 1, m 1))
  else if turn > 0 then Build.west else Build.east

def occAt (k : Nat) : List (TrackId × RegionId) :=
  (if k ≤ 73 then [(xId, cId)] else []) ++ (if 70 ≤ k && k ≤ 93 then [(xId, iId)] else [])

def rider (cls : List RoadUserClass) (startHalted : Bool) (turn : Int) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user xId cls (m 2, cm (yCm startHalted k)) (headingAt turn k) (speedAt startHalted k) (m 1, cm 40, cm 80))
    fun kn => { kn with
      yawRate := some (yawAt turn k)
      -- the diagonal heading is not a unit vector: its velocity is left unobserved
      velocity := if turn != 0 && k == 80 then none else kn.velocity }

def red : List SignalIndication := [.circularRed]
def redArrow (d : ArrowDir) : List SignalIndication := [.circularRed, .greenArrow d]

def oneRise (d : ArrowDir) (k : Nat) : List SignalIndication :=
  if k < 55 then red else redArrow d

def threeRises (d : ArrowDir) (k : Nat) : List SignalIndication :=
  if k < 15 then red else if k < 25 then redArrow d else if k < 35 then red
  else if k < 45 then redArrow d else if k < 55 then red else redArrow d

def greenInWait (d : ArrowDir) (k : Nat) : List SignalIndication :=
  if k < 15 then red else if k < 25 then redArrow d else if k < 35 then [.circularGreen]
  else if k < 45 then redArrow d else if k < 55 then red else redArrow d

/-- The episode: x of classes `cls` waits on c and passes i straight (`turn` 0) or turning left (+1)
    or right (−1) under the displays `display`. -/
def episode (cls : List RoadUserClass) (turn : Int) (display : Nat → List SignalIndication)
    (startHalted : Bool := false) (governs : List RegionId := [cId]) : Trace :=
  Build.trace 100 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some xId) [rider cls startHalted turn k] [laneC, junction]
      [Build.signal sId governs (display k)] (some (occAt k))

/-- `forbid` (violated): x (ru.motorcycle), recorded from upstream, halts on c; s governing c rises to circular_red with green_arrow(left) once during the wait; x then enters i under that display and leaves straight through: the rises counted do not exceed the literal. -/
def forbidTrace : Trace := episode [.motorcycle] 0 (oneRise .left)

/-- `permit` (compliant): x (ru.bicycle), recorded from upstream, halts on c and stays halted while s's circular_red with green_arrow(left) display rises more times than the literal, never showing circular_green or green_arrow(straight); x then enters under the display and leaves straight through. -/
def permitTrace : Trace := episode [.bicycle] 0 (threeRises .left)

/-- `idle` (not_applicable): x carries none of the five aggregates; it waits and then goes straight through under circular_red with green_arrow(left). Built as a pedestrian: under the run's reading every motor-vehicle class is unresolved for the motorcycle aggregate, so a passenger car leaves the class unknown, not false. -/
def idleTrace : Trace := episode [.pedestrian] 0 (threeRises .left)

/-- `blind` (unknown): x, recorded from upstream, halts on c, waits and then goes straight through, but the source does not observe s's state during the wait or at the entry. -/
def blindTrace : Trace := episode [.motorcycle] 0 (threeRises .left)

/-- `branch_1` (violated): x halts on c through more rises of circular_red with green_arrow(left) than the literal, but during the wait s also displays circular_green for c, which x lets pass; x later enters straight through under the red with the arrow: the signal did change, so the condition fails. -/
def branch_1Trace : Trace := episode [.moped] 0 (greenInWait .left)

/-- `history_boundary` (unknown): x's recording begins with x already halted on c; a single rise of circular_red with green_arrow(left) is recorded before x enters i straight through, and the start of the wait is not recorded. -/
def history_boundaryTrace : Trace := episode [.motorcycle] 0 (oneRise .left) (startHalted := true)

-- branch_2 (violated): green_arrow(right); one rise in the wait; straight through.
def branch_2Trace : Trace := episode [.electricBicycle] 0 (oneRise .right)
-- branch_3 (compliant): green_arrow(right); three rises in the wait; straight through.
def branch_3Trace : Trace := episode [.motorcycle] 0 (threeRises .right)
-- branch_4 (violated): green_arrow(right); three rises, but circular_green in the wait; straight through.
def branch_4Trace : Trace := episode [.bicycle] 0 (greenInWait .right)
-- branch_5 (violated): green_arrow(left); one rise in the wait; right turn.
def branch_5Trace : Trace := episode [.motorcycle] (-1) (oneRise .left)
-- branch_6 (compliant): green_arrow(left); three rises in the wait; right turn.
def branch_6Trace : Trace := episode [.bicycle] (-1) (threeRises .left)
-- branch_7 (violated): green_arrow(left); three rises, circular_green in the wait; right turn.
def branch_7Trace : Trace := episode [.moped] (-1) (greenInWait .left)
-- branch_8 (violated): green_arrow(right); one rise in the wait; left turn.
def branch_8Trace : Trace := episode [.motorcycle] 1 (oneRise .right)
-- branch_9 (compliant): green_arrow(right); three rises in the wait; left turn.
def branch_9Trace : Trace := episode [.bicycle] 1 (threeRises .right)
-- branch_10 (violated): green_arrow(right); three rises, circular_green in the wait; left turn.
def branch_10Trace : Trace := episode [.moped] 1 (greenInWait .right)
-- branch_11 (violated): s governs the intersection, not c; one rise in the wait; straight through.
def branch_11Trace : Trace := episode [.motorcycle] 0 (oneRise .left) (governs := [iId])
-- branch_12 (not_applicable): a left turn under green_arrow(left), the arrow's own direction.
def branch_12Trace : Trace := episode [.motorcycle] 1 (threeRises .left)
-- branch_13 (not_applicable): a right turn under green_arrow(right), the arrow's own direction.
def branch_13Trace : Trace := episode [.motorcycle] (-1) (threeRises .right)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, 4950)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch_1Trace .violated
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the start of x's halt on c, which lies before the recording")
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .notApplicable
  , witness "branch_13" branch_13Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_9b_o2
