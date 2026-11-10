/-
  Witnesses for NRS_484B_307_9b_o2.

  Geometry (every figure here is the witness's own and appears nowhere in the rule). An eastbound
  approach lane L (region 10, x from -40 m to 0 m, y 0–4 m) enters intersection I (region 20,
  x 0–6 m, y -4–8 m). A through movement leaves into the eastbound lane O (region 30, x 6–46 m); a
  left turn into the northbound lane N (region 31, above I), a right turn into the southbound
  lane S (region 32, below I). Signal 100 governs L (in branch_5 it governs I instead).

  Instants: 60 scenes 50 ms apart (the acquisition standard's spacing, which the heading change
  of the movement concepts needs). Road user 1:
    k 0–2   approaches on L at 4 m/s;
    k 3–24  halted on L at the stop line (speed 0): the wait begins at k 3;
    k 25    moves off at 4 m/s, still on L (the observation before the entry);
    k 26–55 inside I (entry at k 26), yaw rate 0 for a through movement, +60 deg/s for a left
            turn, -60 deg/s for a right turn: 30 steps of 50 ms, a heading change of 0 or about
            ±90 deg (straight bound 30 deg, turn band 60–150 deg);
    k 56–59 on the exit lane (exit at k 56, the judged observation).
  Positions follow a schematic line along x; occupancy is stated per scene (the rule reads
  occupancy, not positions). The signal shows circular_red throughout, with green_arrow(dir) lit
  in the listed intervals and lit again from k 20 on (so it is lit at the entry); branch_1 shows
  circular_green alone at k 5–6. Arrow intervals:
    one cycle  (forbid, branch_2, branch_4): lit 6–8, then 20 on — one complete cycle in the wait;
    two cycles (permit, idle, blind, branch_3, branch_5): lit 6–8, 12–14, then 20 on;
    branch_1: green 5–6, arrow lit 10–11, 14–15, then 20 on — two cycles after a green.
  The verdicts are read over k 1–59 (`window`): the exit's `rises`/`since` need an observation
  before them.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def laneL : RegionId := 10
def interI : RegionId := 20
def laneO : RegionId := 30
def laneN : RegionId := 31
def laneS : RegionId := 32
def sig : DeviceId := 100

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def structures : List Structure :=
  [ Build.lane laneL (box (m (-40)) (m 0) (m 0) (m 4)) Build.east (enters := some interI)
  , Build.rect interI .intersection (m 0) (m (-4)) (m 6) (m 8)
  , Build.lane laneO (box (m 6) (m 0) (m 46) (m 4)) Build.east
  , Build.lane laneN (box (m 2) (m 8) (m 6) (m 48)) Build.north
  , Build.lane laneS (box (m 0) (m (-44)) (m 4) (m (-4))) Build.south ]

def within (k a b : Nat) : Bool := a ≤ k && k ≤ b

def oneCycle (k : Nat) : Bool := within k 6 8 || 20 ≤ k
def twoCycles (k : Nat) : Bool := within k 6 8 || within k 12 14 || 20 ≤ k
def afterGreen (k : Nat) : Bool := within k 10 11 || within k 14 15 || 20 ≤ k
def noGreen (_k : Nat) : Bool := false
def greenEarly (k : Nat) : Bool := within k 5 6

/-- The signal's indications at scene `k`. -/
def indications (dir : ArrowDir) (arrowAt greenAt : Nat → Bool) (k : Nat) : List SignalIndication :=
  if greenAt k then [.circularGreen]
  else if arrowAt k then [.circularRed, .greenArrow dir] else [.circularRed]

/-- Road user 1 at scene `k`, x along the schematic line (cm). -/
def posX (k : Nat) : Q :=
  if k ≤ 2 then cm (-90 + 20 * (k : Int))
  else if k ≤ 24 then cm (-30)
  else if k = 25 then cm (-10)
  else cm (10 + 20 * ((k : Int) - 26))

def speedAt (k : Nat) : Q :=
  if within k 3 24 then Q.zero else Units.metresPerSecond 4

/-- The region user 1 occupies at scene `k`. -/
def regionAt (exitLane : RegionId) (k : Nat) : RegionId :=
  if k ≤ 25 then laneL else if k ≤ 55 then interI else exitLane

/-- The crossing: classes of user 1, its yaw rate inside I (deg/s), the lane it leaves into, the
    regions the signal governs, the arrow's direction and its timeline. -/
def crossTrace (classes : List RoadUserClass) (yaw : Q) (exitLane : RegionId)
    (governs : List RegionId) (dir : ArrowDir) (arrowAt greenAt : Nat → Bool) : Trace :=
  Build.trace 60 0 (Units.milliseconds 50) fun k t =>
    let u := Build.withKin
      (Build.user 1 classes (posX k, cm 200) Build.east (speedAt k) (cm 110, cm 40, cm 70))
      (fun kin => { kin with yawRate := some (if within k 26 55 then yaw else Q.zero) })
    Build.scene t (some 1) [u] structures
      [Build.signal sig governs (indications dir arrowAt greenAt k)]
      (occupies := some [(1, regionAt exitLane k)])

/-- `forbid` (violated): A motorcycle halts at the stop line of a lane governed by a signal showing circular_red with green_arrow(left); the left arrow lights and goes out once; the motorcycle then enters and goes straight through. -/
def forbidTrace : Trace :=
  crossTrace [.motorcycle] Q.zero laneO [laneL] .left oneCycle noGreen

/-- `permit` (compliant): The motorcycle halts, the left arrow lights and goes out twice while the circular red stays on and no circular_green is ever shown, then it enters and goes straight through. -/
def permitTrace : Trace :=
  crossTrace [.motorcycle] Q.zero laneO [laneL] .left twoCycles noGreen

/-- `idle` (not_applicable): A bicycle enters on circular_red with green_arrow(left) and turns left with the arrow. -/
def idleTrace : Trace :=
  crossTrace [.bicycle] (Units.degrees 60) laneN [laneL] .left twoCycles noGreen

/-- `blind` (unknown): A moped waits and goes straight through; the source does not observe signal states. -/
def blindTrace : Trace :=
  crossTrace [.moped] Q.zero laneO [laneL] .left twoCycles noGreen

/-- `branch_1` (violated): A bicycle halts, the signal shows circular_green once during its wait and returns to red with a left arrow; after two further arrow displays the bicycle goes straight through on red. -/
def branch_1Trace : Trace :=
  crossTrace [.bicycle] Q.zero laneO [laneL] .left afterGreen greenEarly

/-- `branch_2` (not_applicable): a pedestrian, none of the listed vehicles, waits one arrow cycle in the lane and crosses straight. -/
def branch_2Trace : Trace :=
  crossTrace [.pedestrian] Q.zero laneO [laneL] .left oneCycle noGreen

/-- `branch_3` (compliant): a motorcycle waits two left-arrow cycles and turns right, opposite the arrow. -/
def branch_3Trace : Trace :=
  crossTrace [.motorcycle] (Units.degrees (-60)) laneS [laneL] .left twoCycles noGreen

/-- `branch_4` (violated): an electric bicycle waits one right-arrow cycle and turns left, opposite the arrow. -/
def branch_4Trace : Trace :=
  crossTrace [.electricBicycle] (Units.degrees 60) laneN [laneL] .right oneCycle noGreen

/-- `branch_5` (compliant): the signal governs the intersection itself; a motorcycle waits two left-arrow cycles and goes straight. -/
def branch_5Trace : Trace :=
  crossTrace [.motorcycle] Q.zero laneO [interI] .left twoCycles noGreen

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, 2950)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_307_9b_o2
