/-
  Witnesses for NRS_484B_307_9b_o3.

  Geometry (the witness's own figures): an intersection 1, the square [−10, 10] m × [−10, 10] m,
  and its northbound approach lane 2, x ∈ [0, 4] m, y ∈ [−40, −10] m, entering 1. Ten scenes
  at 50 ms (the acquisition step), k = 0 … 9. x (track 1) is on lane 2 at k = 0, 1; at k = 2 its
  front has crossed into 1 while its rear is still on 2 (both stated); k = 3 … 7 inside 1; at k = 8
  it has left 1 (the leaving judged), k = 9 beyond. Its yaw rate is ±300 deg/s at k = 3 … 8 for a
  turn (−90° at the leaving for a right turn, +90° for a left one, against a 45° recognition
  angle), zero otherwise and throughout a straight passage. Signal head 10 shows circular_red with
  a green arrow; sign 11 (no_right_turn, unconditional legend) and red-arrow head 12 are the
  prohibitions. The window starts at k = 1: at k = 0 no earlier observation decides an entry.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def intersection : Structure := Build.rect 1 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def approachLane : Structure :=
  Build.lane 2 [(m 0, m (-40)), (m 4, m (-40)), (m 4, m (-10)), (m 0, m (-10))] Build.north
    (enters := some 1)

/-- x's reference point at scene k: `turn` −1 right, 0 straight, +1 left. -/
def pathPoint (turn : Int) (k : Nat) : Vec :=
  let common : List (Int × Int) := [(200, -1600), (200, -1200), (200, -950)]
  let rest : List (Int × Int) :=
    if turn < 0 then [(300, -700), (500, -500), (700, -300), (800, -200), (900, -200), (1200, -200), (1500, -200)]
    else if turn > 0 then [(100, -600), (0, -200), (-200, 100), (-500, 200), (-800, 200), (-1200, 200), (-1500, 200)]
    else [(200, -600), (200, -300), (200, 0), (200, 300), (200, 700), (200, 1200), (200, 1500)]
  let p := (common ++ rest).getD k (0, 0)
  (cm p.1, cm p.2)

/-- x's heading at scene k (not of unit length): north up to the entry, then turning a little
    further at every scene the yaw rate is non-zero, to east (right) or west (left) at the leaving. -/
def headingAt (turn : Int) (k : Nat) : Vec :=
  let turning : List (Int × Int) := [(1, 4), (1, 2), (1, 1), (2, 1), (4, 1), (1, 0), (1, 0)]
  if k ≤ 2 || turn == 0 then Build.north
  else
    let h := turning.getD (k - 3) (1, 0)
    (Q.ofInt (if turn < 0 then h.1 else -h.1), Q.ofInt h.2)

def subject (cls : RoadUserClass) (turn : Int) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [cls] (pathPoint turn k) (headingAt turn k) (Units.metresPerSecond 8)
      (m 1, cm 40, cm 70))
    fun kin => { kin with yawRate := some (if 3 ≤ k && k ≤ 8 then Units.degrees (turn * 300) else Q.zero) }

def passageTrace (cls : RoadUserClass) (turn : Int) (devices : List Device) : Trace :=
  Build.trace 10 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1) [subject cls turn k] [intersection, approachLane] devices
      (occupies := if k = 2 then some [(1, 1), (1, 2)] else none)

def redLeftArrowOnLane : Device := Build.signal 10 [2] [.circularRed, .greenArrow .left]
def noRightTurnOnLane : Device :=
  { Build.sign 11 .regulatorySign [2] with code := some .noRightTurn, conditions := some {} }

/-- `forbid` (violated): x (ru.motorcycle), recorded from upstream, enters i through c under circular_red with green_arrow(left) and turns right; a dev.regulatory_sign of code no_right_turn with empty conditions governs c. -/
def forbidTrace : Trace :=
  passageTrace .motorcycle (-1) [redLeftArrowOnLane, noRightTurnOnLane]

/-- `permit` (compliant): x (ru.bicycle), recorded from upstream, enters i through c under circular_red with green_arrow(left) and turns right; no sign or red arrow prohibiting a right turn governs c or i. -/
def permitTrace : Trace :=
  passageTrace .bicycle (-1) [redLeftArrowOnLane]

/-- `idle` (not_applicable): x (ru.motorcycle) enters under circular_red with green_arrow(left) and turns left, the movement the arrow indicates. -/
def idleTrace : Trace :=
  passageTrace .motorcycle 1 [redLeftArrowOnLane]

/-- `blind` (unknown): x, recorded from upstream, turns right under circular_red with green_arrow(left); a no_right_turn sign stands at the approach but the source does not observe which regions any device governs. -/
def blindTrace : Trace :=
  passageTrace .motorcycle (-1) [redLeftArrowOnLane, noRightTurnOnLane]

/-- `branch_1` (compliant): x (ru.moped) enters under circular_red with green_arrow(left) and goes straight through while a no_right_turn sign governs c: no turn is made, so the condition is met. -/
def branch_1Trace : Trace :=
  passageTrace .moped 0 [redLeftArrowOnLane, noRightTurnOnLane]

/-- `branch_2` (violated): x (ru.motorcycle) enters under circular_red with green_arrow(right) from a head governing i and turns left, while another head governing i shows red_arrow(left). -/
def branch_2Trace : Trace :=
  passageTrace .motorcycle 1
    [Build.signal 10 [1] [.circularRed, .greenArrow .right], Build.signal 12 [1] [.redArrow .left]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b_o3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, 450)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_9b_o3
