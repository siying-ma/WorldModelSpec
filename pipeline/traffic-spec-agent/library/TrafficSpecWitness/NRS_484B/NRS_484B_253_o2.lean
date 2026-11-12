/-
  Witnesses for NRS_484B_253_o2.

  Geometry (+x east, +y north, metres). The intersection 100 is the square [-10, 10]². The
  northbound approach lane 101 (x ∈ [0, 10], y ∈ [-40, -10]) enters it from the south: t's carrier.
  The southbound approach lane 102 (x ∈ [-10, 0], y ∈ [10, 120]) enters it from the north: ego's
  carrier, opposed to 101. The westbound approach lane 103 (x ∈ [10, 120], y ∈ [0, 10]) enters it
  from the east, perpendicular to 101. Both vehicles are 4.5 m × 1.8 m (half-extents 2.25, 0.9).

  Instants k = 0 … 7, one second apart. t (track 2) is south of its lane at k = 0, on lane 101 at
  k = 1, stopped inside the intersection at (2.5, -5) at k = 2, 3, and turns left from k = 4 (the
  onset: 2 m/s, yaw rate 13–16 deg/s, heading 16° left of north) through (1.5, -3), (0, 0) and
  (-1, 1.5). Ego (track 1) drives south at x = -2.5 at 10 m/s, from y = 85 at k = 0 to y = 15 at
  k = 7. At the onset ego is 50 m from t and their projected closest approach lies 4.2 s ahead
  (beyond the 3 s horizon); at k = 6 it lies 2.2 s ahead at about 0.5 m, at k = 7 1.2 s ahead at
  under 0.6 m (below the 3 m clearance).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def deg (n : Int) : Q := Units.degrees n

-- Binders ↦ tracks: ego ↦ 1; the left-turning vehicle t is track 2

/-- Headings of the turn, unit vectors turned left of north by about 16°, 31°, 44° and 58°, so
    that each step of heading matches the yaw rate held over the interval before it. -/
def turn16 : Vec := (Units.ratio (-7) 25, Units.ratio 24 25)
def turn31 : Vec := (Units.ratio (-33) 65, Units.ratio 56 65)
def turn44 : Vec := (Units.ratio (-20) 29, Units.ratio 21 29)
def turn58 : Vec := (Units.ratio (-45) 53, Units.ratio 28 53)

def bodyExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

def intersection : Structure := Build.rect 100 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def tLane : Structure :=
  Build.lane 101 [(m 0, m (-40)), (m 10, m (-40)), (m 10, m (-10)), (m 0, m (-10))] Build.north
    (enters := some 100)
def egoLane : Structure :=
  Build.lane 102 [(m (-10), m 10), (m 0, m 10), (m 0, m 120), (m (-10), m 120)] Build.south
    (enters := some 100)
def crossLane : Structure :=
  Build.lane 103 [(m 10, m 0), (m 120, m 0), (m 120, m 10), (m 10, m 10)] Build.west
    (enters := some 100)

def structures : List Structure := [intersection, tLane, egoLane, crossLane]

/-- A road user with position, heading, speed and yaw rate. -/
def mover (track : TrackId) (classes : List RoadUserClass) (x y : Q) (h : Vec) (v w : Q) : RoadUser :=
  Build.withKin (Build.user track classes (x, y) h v bodyExtent) fun k => { k with yawRate := some w }

def car (track : TrackId) (x y : Q) (h : Vec) (v w : Q) : RoadUser := mover track [.motorVehicle] x y h v w

/-- t's signals: indicator state and arm signal. -/
def signalling (ind : TurnIndicatorState) (hand : HandSignal) (u : RoadUser) : RoadUser :=
  Build.withSignals u fun s => { s with turnIndicator := some ind, handSignal := some hand }

/-- t's motion in the forbid scene, by instant; `cls` its classes. -/
def tTurning (cls : List RoadUserClass) (k : Nat) : RoadUser :=
  match k with
  | 0 => mover 2 cls (cm 250) (m (-50)) Build.north (mps 8) Q.zero
  | 1 => mover 2 cls (cm 250) (m (-15)) Build.north (mps 8) Q.zero
  | 2 => mover 2 cls (cm 250) (m (-5)) Build.north Q.zero Q.zero
  | 3 => mover 2 cls (cm 250) (m (-5)) Build.north Q.zero Q.zero
  | 4 => mover 2 cls (cm 250) (m (-5)) turn16 (mps 2) (deg 16)
  | 5 => mover 2 cls (cm 150) (m (-3)) turn31 (mps 2) (deg 14)
  | 6 => mover 2 cls Q.zero Q.zero turn44 (mps 2) (deg 13)
  | _ => mover 2 cls (m (-1)) (cm 150) turn58 (mps 2) (deg 15)

/-- Ego driving south at 10 m/s at x = `x`, from y = 85 at k = 0. -/
def egoDriving (x : Q) (k : Nat) : RoadUser :=
  car 1 x (m (85 - 10 * (k : Int))) Build.south (mps 10) Q.zero

/-- t's declared intention at the intersection. -/
def leftIntent (declared : Bool) : List DeclaredIntent :=
  [{ vehicle := 2, target := 100, values := [("int.left_turn", declared)] }]

def episode (n : Nat) (ego : Nat → RoadUser) (t : Nat → RoadUser) (declared : Bool := true) : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k ts =>
    Build.scene ts (some 1) [ego k, t k] structures [] (intents := leftIntent declared)

/-- `forbid` (violated): Vehicle t entered the intersection from its approach lane with int.left_turn and its left indicator on since its approach, waited at rest while ego, approaching from the opposite direction, was far off, and began its left turn at an observation at which its projected closest approach with ego did not lie within p.conflict_horizon below p.conflict_clearance (so t complied with NRS_484B_253_o1 up to its onset). t turns slowly; ego keeps moving without slowing, and at a later observation of the same turn their projected closest approach lies within p.conflict_horizon below p.conflict_clearance. -/
def forbidTrace : Trace :=
  episode 8 (egoDriving (cm (-250))) fun k => signalling .left .noSignal (tTurning [.motorVehicle] k)

/-- `permit` (compliant): Same scene as forbid; ego slows and comes to rest at the edge of the intersection, and is at rest at every observation at which its projected closest approach with the turning t would lie within p.conflict_horizon below p.conflict_clearance, until t completes its turn. -/
def egoStopping (k : Nat) : RoadUser :=
  if k < 4 then car 1 (cm (-250)) (m (55 - 10 * (k : Int))) Build.south (mps 10) Q.zero
  else car 1 (cm (-250)) (m 13) Build.south Q.zero Q.zero

def permitTrace : Trace :=
  episode 8 egoStopping fun k => signalling .left .noSignal (tTurning [.motorVehicle] k)

/-- `idle` (not_applicable): t crosses the intersection straight ahead (int.left_turn false, not turning left); ego approaches from the opposite direction. -/
def tStraight (k : Nat) : RoadUser :=
  match k with
  | 0 => car 2 (cm 250) (m (-50)) Build.north (mps 8) Q.zero
  | 1 => car 2 (cm 250) (m (-15)) Build.north (mps 8) Q.zero
  | k => car 2 (cm 250) (m (2 * (k : Int) - 11)) Build.north (mps 2) Q.zero

def idleTrace : Trace :=
  episode 8 (egoDriving (cm (-250))) (fun k => signalling .off .noSignal (tStraight k)) (declared := false)

/-- `blind` (unknown): Scene of forbid, but the source declares sig.turn_indicator and sig.hand_signal absent: whether t signalled cannot be read. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["sig.turn_indicator", "sig.hand_signal"]) forbidTrace

/-- `branch_1` (not_applicable): As forbid, but t's indicator stayed off and it gave no arm signal: t gave no signal, so the opposing drivers' duty does not arise. -/
def branch_1Trace : Trace :=
  episode 8 (egoDriving (cm (-250))) fun k => signalling .off .noSignal (tTurning [.motorVehicle] k)

/-- `branch_2` (not_applicable): As forbid, but t began its turn at an observation at which ego, approaching from the opposite direction, was within the immediate-hazard distance of the intersection and their projected closest approach lay within p.conflict_horizon below p.conflict_clearance: t did not yield as NRS_484B_253_o1 requires up to its onset, so the duty to yield to it does not arise.
    t waits at (-0.5, -4) and starts its turn at k = 4 at 5 m/s while ego, 1 m short of the
    intersection at (-2.5, 11), drives south at 10 m/s: closest approach 1 s ahead at under 0.6 m. -/
def tEarly (k : Nat) : RoadUser :=
  match k with
  | 0 => car 2 (cm 250) (m (-50)) Build.north (mps 8) Q.zero
  | 1 => car 2 (cm 250) (m (-15)) Build.north (mps 8) Q.zero
  | 2 => car 2 (cm (-50)) (m (-4)) Build.north Q.zero Q.zero
  | 3 => car 2 (cm (-50)) (m (-4)) Build.north Q.zero Q.zero
  | _ => car 2 (cm (-50)) (m (-4)) turn16 (mps 5) (deg 16)

def egoClose (k : Nat) : RoadUser :=
  car 1 (cm (-250)) (m (51 - 10 * (k : Int))) Build.south (mps 10) Q.zero

def branch_2Trace : Trace :=
  episode 5 egoClose fun k => signalling .left .noSignal (tEarly k)

/-- `branch_3` (violated): As forbid, but t's indicator stays off and it gives a left arm signal (sig.hand_signal left) since its approach: the signal is given, and ego, in conflict with the turning t, has not yielded. -/
def branch_3Trace : Trace :=
  episode 8 (egoDriving (cm (-250))) fun k => signalling .off .left (tTurning [.motorVehicle] k)

/-- `branch_4` (not_applicable): Ego approaches the intersection alone on its approach lane; no other road user is in the scene. -/
def branch_4Trace : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k ts =>
    Build.scene ts (some 1) [egoDriving (cm (-250)) k] structures []

/-- `branch_5` (compliant): as forbid, but ego creeps south at 2 m/s from y = 98: its projected
    closest approach with the turning t lies far beyond p.conflict_horizon; ego, moving, does not
    conflict with t. -/
def egoFar (k : Nat) : RoadUser :=
  car 1 (cm (-250)) (m (98 - 2 * (k : Int))) Build.south (mps 2) Q.zero

def branch_5Trace : Trace :=
  episode 8 egoFar fun k => signalling .left .noSignal (tTurning [.motorVehicle] k)

/-- `branch_6` (compliant): as forbid, but ego drives at x = -9, the far side of its carrier: the
    projected closest approach with the turning t lies within p.conflict_horizon at over 5 m, above
    p.conflict_clearance. -/
def branch_6Trace : Trace :=
  episode 8 (egoDriving (m (-9))) fun k => signalling .left .noSignal (tTurning [.motorVehicle] k)

/-- `branch_7` (not_applicable): as forbid, but ego approaches on the westbound lane 103 from the
    east, perpendicular to t's approach: not from the opposite direction. -/
def egoCrossing (k : Nat) : RoadUser :=
  car 1 (m (85 - 10 * (k : Int))) (m 5) Build.west (mps 10) Q.zero

def branch_7Trace : Trace :=
  episode 8 egoCrossing fun k => signalling .left .noSignal (tTurning [.motorVehicle] k)

/-- `branch_8` (not_applicable): as forbid, but t is a bicycle, no vehicle of the aggregate. -/
def branch_8Trace : Trace :=
  episode 8 (egoDriving (cm (-250))) fun k => signalling .left .noSignal (tTurning [.bicycle] k)

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
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_253_o2
