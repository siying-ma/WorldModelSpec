/-
  Witnesses for NRS_484B_253_o2.

  Geometry (metres, +x east, +y north). Intersection 10 is the square [-10, 10]². Vehicle t
  (track 2) comes from the south: upstream lane 12 (x ∈ [0, 4], y ∈ [-200, -60], northbound)
  leads to its approach lane 11 (x ∈ [0, 4], y ∈ [-60, -10], northbound, entering 10). Ego
  (track 1) comes from the north on lane 13 (x ∈ [-4, 0], y ∈ [10, 300], southbound, entering
  10): the two approaches are exactly opposed. Lane 14 (x ∈ [-200, -10], y ∈ [0, 4],
  westbound) is t's exit after its left turn. Both are passenger cars, half-extent 2 × 1 m.

  Five scenes one second apart. t is on lane 12 at 0, on lane 11 at 1, waits at rest in the
  intersection at (2, 2) at 2 and 3, and at 4 turns left from (-0.4, 5) heading (-4/5, 3/5) at
  0.75 m/s, yaw rate 20 deg/s. In `forbid` ego keeps 30 m/s south at x = -2 and is at y = 86 at
  4 (76 m short of the intersection): projected, the centres meet about 2.66 s ahead, closer than
  0.1 m, inside the 3 s horizon and far below the 3 m clearance. In `permit` ego has stopped at
  y = 15 by 3. In `branch_2` t starts its turn at 3 from (1, 0) heading (-5/13, 12/13) at
  6.5 m/s while ego at 15 m/s is at y = 25, 15 m short of the intersection, so t does not yield
  as NRS_484B_253_o1 requires. Every figure is the witness's own and appears nowhere in the rule.

  `forbid`, `blind` and `branch_3` do not reach their verdicts: at the observation where ego is in
  conflict with the turning t, t is in conflict with ego and not at rest, so t has not complied
  with NRS_484B_253_o1 at that observation (the gate found the same with ego 263 m out at
  100 m/s), and the f10 condition fails. See task_result.md: the node is wrong at f10.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def cmps (n : Int) : Q := Units.micrometresPerSecond (n * 10000)
def degps (n : Int) : Q := Units.degrees n

-- Binders ↦ tracks: ego ↦ 1; the left-turning vehicle t is track 2.

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def structures : List Structure :=
  [ Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
  , Build.lane 11 (box 0 (-60) 4 (-10)) Build.north (enters := some 10)
  , Build.lane 12 (box 0 (-200) 4 (-60)) Build.north (leadsTo := some [11])
  , Build.lane 13 (box (-4) 10 0 300) Build.south (enters := some 10)
  , Build.lane 14 (box (-200) 0 (-10) 4) Build.west ]

/-- A pose: position, heading, speed, yaw rate. -/
structure Pose where
  pos : Vec
  heading : Vec
  speed : Q
  yaw : Q := Q.zero

def car (track : TrackId) (p : Pose) (ind : TurnIndicatorState) (hand : HandSignal) : RoadUser :=
  Build.withSignals
    (Build.withKin (Build.user track [.motorVehicle] p.pos p.heading p.speed (m 2, m 1, cm 75))
      fun k => { k with yawRate := some p.yaw })
    fun s => { s with turnIndicator := some ind, handSignal := some hand }

def at' (x y : Int) : Vec := (m x, m y)

/-- Heading (-4/5, 3/5), well into the left turn; (-5/13, 12/13), at its start. -/
def northWest : Vec := (Units.ratio (-4) 5, Units.ratio 3 5)
def northNorthWest : Vec := (Units.ratio (-5) 13, Units.ratio 12 13)

/-- t waits in the intersection, then turns left. -/
def tWaitsThenTurns : Nat → Pose
  | 0 => { pos := at' 2 (-80), heading := Build.north, speed := mps 10 }
  | 1 => { pos := at' 2 (-30), heading := Build.north, speed := mps 8 }
  | 2 => { pos := at' 2 2, heading := Build.north, speed := Q.zero }
  | 3 => { pos := at' 2 2, heading := Build.north, speed := Q.zero }
  | _ => { pos := (cm (-40), m 5), heading := northWest, speed := cmps 75, yaw := degps 20 }

/-- t goes straight through the intersection. -/
def tStraight : Nat → Pose
  | 0 => { pos := at' 2 (-80), heading := Build.north, speed := mps 10 }
  | 1 => { pos := at' 2 (-30), heading := Build.north, speed := mps 10 }
  | 2 => { pos := at' 2 (-2), heading := Build.north, speed := mps 10 }
  | 3 => { pos := at' 2 6, heading := Build.north, speed := mps 10 }
  | _ => { pos := at' 2 8, heading := Build.north, speed := mps 10 }

/-- t starts its turn without waiting, ego close. -/
def tTurnsAtOnce : Nat → Pose
  | 0 => { pos := at' 2 (-80), heading := Build.north, speed := mps 10 }
  | 1 => { pos := at' 2 (-30), heading := Build.north, speed := mps 8 }
  | 2 => { pos := at' 2 (-2), heading := Build.north, speed := mps 3 }
  | 3 => { pos := at' 1 0, heading := northNorthWest, speed := cmps 650, yaw := degps 20 }
  | _ => { pos := at' (-1) 5, heading := northWest, speed := mps 5, yaw := degps 20 }

/-- Ego keeps 30 m/s south. -/
def egoKeepsGoing (k : Nat) : Pose :=
  { pos := at' (-2) (206 - 30 * (Int.ofNat k)), heading := Build.south, speed := mps 30 }

/-- Ego slows and comes to rest at the edge of the intersection. -/
def egoStops : Nat → Pose
  | 0 => { pos := at' (-2) 48, heading := Build.south, speed := mps 14 }
  | 1 => { pos := at' (-2) 34, heading := Build.south, speed := mps 12 }
  | 2 => { pos := at' (-2) 22, heading := Build.south, speed := mps 8 }
  | _ => { pos := at' (-2) 15, heading := Build.south, speed := Q.zero }

/-- Ego at 15 m/s, close to the intersection when t starts its turn. -/
def egoClose (k : Nat) : Pose :=
  { pos := at' (-2) (70 - 15 * (Int.ofNat k)), heading := Build.south, speed := mps 15 }

def traceOf (ego tt : Nat → Pose) (intent : Bool) (ind : TurnIndicatorState) (hand : HandSignal) : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (ego k) .off .noSignal, car 2 (tt k) ind hand ]
      structures
      []
      (intents := [{ vehicle := 2, target := 10, values := [("int.left_turn", intent)] }])

/-- `forbid` (violated): Vehicle t, within the intersection with int.left_turn and its left indicator on since its approach, waited while no oncoming vehicle was close and now turns left. Ego approaches from the opposite direction and keeps moving; their projected closest approach lies within p.conflict_horizon below p.conflict_clearance. -/
def forbidTrace : Trace := traceOf egoKeepsGoing tWaitsThenTurns true .left .noSignal

/-- `permit` (compliant): Same scene; ego slows and comes to rest at the edge of the intersection until t completes its turn. -/
def permitTrace : Trace := traceOf egoStops tWaitsThenTurns true .left .noSignal

/-- `idle` (not_applicable): t crosses the intersection straight ahead (no int.left_turn, not turning left); ego approaches from the opposite direction. -/
def idleTrace : Trace := traceOf egoKeepsGoing tStraight false .off .noSignal

/-- `blind` (unknown): Scene of forbid, but the source declares sig.turn_indicator and sig.hand_signal absent: whether t signalled cannot be read. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): As forbid, but t's indicator stayed off and it gave no arm signal: t gave no signal, so the opposing drivers' duty does not arise. -/
def branch_1Trace : Trace := traceOf egoKeepsGoing tWaitsThenTurns true .off .noSignal

/-- `branch_2` (not_applicable): As forbid, but t began its turn while ego was already within the immediate-hazard distance of the intersection: t did not yield as NRS_484B_253_o1 requires, so the duty to yield to it does not arise. -/
def branch_2Trace : Trace := traceOf egoClose tTurnsAtOnce true .left .noSignal

/-- `branch_3` (violated): as forbid, but t signals by arm, its indicator off. -/
def branch_3Trace : Trace := traceOf egoKeepsGoing tWaitsThenTurns true .off .left

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o2"
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
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator", "sig.hand_signal"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_253_o2
