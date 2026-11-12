/-
  Witnesses for NRS_484B_253_o1.

  Geometry (metres, +x east, +y north): intersection 10 is the square (-10,-10)–(10,10). Lane 11
  (x 0..5, y -60..-10) is the northbound approach entering 10; lane 12 (x -5..0, y 10..200) is
  the southbound approach entering 10. Ego (track 1) comes up lane 11 and turns left (west) in 10;
  the oncoming vehicle b (track 2) comes down lane 12 at 10 m/s along x = -2. Bodies are
  half-length 2, half-width 1. Instants are 1 s apart; at instant 0 both are on their approaches,
  so the entry carriers are observed.

  forbid: at 1 s ego at (2,4) heads west at 4 m/s, b at (-2,14): b's body is 2 m from 10, far
    below 10 m/s times the critical headway; their centres meet at 1 s (distance 0).
  permit: ego waits at rest at (0.5,2) heading north (b's projected pass 2.5 m off its centre)
    while b passes at 1 s and 2 s, then at 3 s, with b gone south of every region, turns west.
  idle: forbid's scene with int.left_turn declared false.
  blind: forbid's scene with st.lane_direction masked.
  branch_1: ego turns with no other road user.
  branch_2: b on lane 12 at (-2,80): 68 m from 10, above 10 m/s times the critical headway.
  branch_3: (violated) b already within 10 at (-2,8) while ego crosses its path at 4 m/s; the
    centres come within 2.3 m. Exercises "which is within the intersection".
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: ego ↦ 1

def body : Q × Q × Q := (m 2, m 1, m 1)

def intersection : Structure := Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def northApproach : Structure :=
  Build.lane 11 [(m 0, m (-60)), (m 5, m (-60)), (m 5, m (-10)), (m 0, m (-10))] Build.north
    (enters := some 10)
def southApproach : Structure :=
  Build.lane 12 [(m (-5), m 10), (m 0, m 10), (m 0, m 200), (m (-5), m 200)] Build.south
    (enters := some 10)
def structures : List Structure := [intersection, northApproach, southApproach]

def leftTurn (v : Bool) : List DeclaredIntent :=
  [{ vehicle := 1, target := 10, values := [("int.left_turn", v)] }]

def vehicle (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos heading speed body

/-- Ego on its approach, northbound at 5 m/s. -/
def egoApproaching : RoadUser := vehicle 1 (m 2, m (-12)) Build.north (Units.metresPerSecond 5)
/-- Ego turning left in the intersection, westbound at 4 m/s. -/
def egoTurning : RoadUser := vehicle 1 (m 2, m 4) Build.west (Units.metresPerSecond 4)
def oncoming (y : Q) : RoadUser := vehicle 2 (m (-2), y) Build.south (Units.metresPerSecond 10)

def sceneOf (t : Timestamp) (users : List RoadUser) (intent : Bool := true) : Scene :=
  Build.scene t (some 1) users structures [] (intents := leftTurn intent)

/-- `forbid` (violated): Ego is within the intersection and declares int.left_turn there. An oncoming vehicle b on the opposite approach is at a distance from the intersection below its speed times p.immediate_hazard_time; ego moves across b's path and their projected closest approach falls within p.conflict_horizon below p.conflict_clearance. -/
def forbidScenes (intent : Bool) : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [egoApproaching, oncoming (m 24)] intent
    | _ => sceneOf t [egoTurning, oncoming (m 14)] intent

def forbidTrace : Trace := forbidScenes true

/-- `permit` (compliant): Same scene; ego stays at rest in the intersection until b has passed, then turns. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let egoWaiting := vehicle 1 (cm 50, m 2) Build.north Q.zero
    match k with
    | 0 => sceneOf t [egoApproaching, oncoming (m 24)]
    | 1 => sceneOf t [egoWaiting, oncoming (m 14)]
    | 2 => sceneOf t [egoWaiting, oncoming (m 4)]
    | _ => sceneOf t [vehicle 1 (cm 50, m 2) Build.west (Units.metresPerSecond 4), oncoming (m (-16))]

/-- `idle` (not_applicable): Ego is within the intersection with a declared plan to go straight (int.left_turn false). -/
def idleTrace : Trace := forbidScenes false

/-- `blind` (unknown): Scene of forbid, but the source declares st.lane_direction absent: whether b approaches from the opposite direction cannot be read. -/
def blindTrace : Trace := Build.masked (Build.manifest ["st.lane_direction"]) forbidTrace

/-- `branch_1` (compliant): Ego, within the intersection with int.left_turn, turns left with no other road user in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [egoApproaching]
    | _ => sceneOf t [egoTurning]

/-- `branch_2` (compliant): An oncoming vehicle b is on the opposite approach at a distance above its speed times p.immediate_hazard_time and not within the intersection; ego turns. -/
def branch_2Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [egoApproaching, oncoming (m 90)]
    | _ => sceneOf t [egoTurning, oncoming (m 80)]

/-- `branch_3` (violated): An oncoming vehicle b is already within the intersection; ego moves
    across its path, their projected centres within the clearance inside the horizon. -/
def branch_3Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [egoApproaching, oncoming (m 18)]
    | _ => sceneOf t [egoTurning, oncoming (m 8)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o1"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_253_o1
