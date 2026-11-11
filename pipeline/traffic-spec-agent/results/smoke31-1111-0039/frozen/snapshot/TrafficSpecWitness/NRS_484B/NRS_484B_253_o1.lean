/-
  Witnesses for NRS_484B_253_o1.

  Geometry (metres, +x east, +y north): intersection 1 is the square (-10,-10)–(10,10). Lane 11 is
  x's approach from the south (x 0…4, y -100…-10, northbound, entering 1); lane 12 the opposed
  approach from the north (x -4…0, y 10…300, southbound, entering 1); lane 13 a crossing approach
  from the west (x -100…-10, y -4…0, eastbound, entering 1). Vehicles are 4 m long and 2 m wide.
  Scenes are 1 s apart; occupancy is stated (a body across a lane end and the intersection
  occupies both). x is track 1, the opposing vehicle y track 2.

  Against the reading (gap 4.1 s, speed resolution 0.2 m/s, yaw-rate resolution 2 deg/s): y 20 m
  from the intersection at 15 m/s is within 61.5 m, an immediate hazard; at 200 m it is not. A left
  turn is 4 m/s with a yaw rate of 12 or 15 deg/s; going straight or waiting has yaw rate 0.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def intersection : Structure := Build.rect 1 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def southApproach : Structure :=
  Build.lane 11 [(m 0, m (-100)), (m 4, m (-100)), (m 4, m (-10)), (m 0, m (-10))] Build.north (enters := some 1)
def northApproach : Structure :=
  Build.lane 12 [(m (-4), m 10), (m 0, m 10), (m 0, m 300), (m (-4), m 300)] Build.south (enters := some 1)
def westApproach : Structure :=
  Build.lane 13 [(m (-100), m (-4)), (m (-10), m (-4)), (m (-10), m 0), (m (-100), m 0)] Build.east (enters := some 1)

def structures : List Structure := [intersection, southApproach, northApproach, westApproach]

/-- A motor vehicle at a position, heading, speed (m/s) and yaw rate (deg/s, `none` unobserved). -/
def car (track : TrackId) (x y : Int) (heading : Vec) (speed : Int) (yaw : Option Int) : RoadUser :=
  Build.withKin (Build.user track [.motorVehicle] (m x, m y) heading (Units.metresPerSecond speed) (m 2, m 1, m 1))
    (fun k => { k with yawRate := yaw.map Units.degrees })

/-- North turned 15° to the left (−tan 15°, 1): the heading one second of 15 deg/s yaw after north. -/
def north15 : Vec := (Q.mk' (-267949) 1000000, Q.ofInt 1)
/-- North turned 12° to the left (−tan 12°, 1). -/
def north12 : Vec := (Q.mk' (-212557) 1000000, Q.ofInt 1)

/-- The source's declaration of int.left_turn for x at intersection 1. -/
def leftTurn (v : Bool) : List DeclaredIntent := [{ vehicle := 1, target := 1, values := [("int.left_turn", v)] }]

def scene (t : Timestamp) (users : List RoadUser) (occupies : List (TrackId × RegionId)) (turn : Bool := true) : Scene :=
  Build.scene t (some 1) users structures [] (occupies := some occupies) (intents := leftTurn turn)

/-- `forbid` (violated): The recording begins with x on c upstream of i; x enters i through c (recorded) and int.left_turn x i is declared; vehicle y on c2 (opposed to c, st.lane_enters c2 i) is 20 m from i at 15 m/s; x moves at 4 m/s with kin.yaw_rate 15 deg/s. -/
def forbidScenes (yaw : Option Int) (turnYaw : Option Int) : Trace :=
  [ scene 0 [car 1 2 (-13) Build.north 4 yaw, car 2 (-2) 77 Build.south 15 yaw] [(1, 11), (2, 12)]
  , scene 1000 [car 1 2 (-9) Build.north 4 yaw, car 2 (-2) 62 Build.south 15 yaw] [(1, 1), (1, 11), (2, 12)]
  , scene 2000 [car 1 2 (-5) Build.north 4 yaw, car 2 (-2) 47 Build.south 15 yaw] [(1, 1), (2, 12)]
  , scene 3000 [car 1 2 (-1) north15 4 turnYaw, car 2 (-2) 32 Build.south 15 yaw] [(1, 1), (2, 12)] ]

def forbidTrace : Trace := forbidScenes (some 0) (some 15)

/-- `permit` (compliant): As forbid up to x's entry, but x waits halted in i until y has passed, then turns left (kin.yaw_rate 15 deg/s, 4 m/s) as the only road user in the scene. -/
def permitTrace : Trace :=
  [ scene 0 [car 1 2 (-13) Build.north 4 (some 0), car 2 (-2) 40 Build.south 15 (some 0)] [(1, 11), (2, 12)]
  , scene 1000 [car 1 2 (-9) Build.north 2 (some 0), car 2 (-2) 25 Build.south 15 (some 0)] [(1, 1), (1, 11), (2, 12)]
  , scene 2000 [car 1 2 (-7) Build.north 0 (some 0), car 2 (-2) 10 Build.south 15 (some 0)] [(1, 1), (2, 1), (2, 12)]
  , scene 3000 [car 1 2 (-7) Build.north 0 (some 0), car 2 (-2) (-5) Build.south 15 (some 0)] [(1, 1), (2, 1)]
  , scene 4000 [car 1 2 (-7) Build.north 0 (some 0), car 2 (-2) (-20) Build.south 15 (some 0)] [(1, 1)]
  , scene 5000 [car 1 1 (-3) north15 4 (some 15)] [(1, 1)] ]

/-- `idle` (not_applicable): x enters i through c (recorded) and occupies i; the source declares int.left_turn x i false (x goes straight). -/
def idleTrace : Trace :=
  [ scene 0 [car 1 2 (-13) Build.north 4 (some 0)] [(1, 11)] (turn := false)
  , scene 1000 [car 1 2 (-9) Build.north 4 (some 0)] [(1, 1), (1, 11)] (turn := false)
  , scene 2000 [car 1 2 (-5) Build.north 4 (some 0)] [(1, 1)] (turn := false) ]

/-- `blind` (unknown): As forbid, with x's entry recorded, but kin.yaw_rate of x is not observed. -/
def blindTrace : Trace := forbidScenes none none

/-- `branch_1` (violated): Vehicle y occupies i, having entered (recorded) through c2 opposed to c; x, in i after a recorded entry through c with int.left_turn x i declared, turns left (moving, kin.yaw_rate 12 deg/s). -/
def branch_1Trace : Trace :=
  [ scene 0 [car 1 2 (-13) Build.north 4 (some 0), car 2 (-2) 14 Build.south 5 (some 0)] [(1, 11), (2, 12)]
  , scene 1000 [car 1 2 (-9) Build.north 4 (some 0), car 2 (-2) 9 Build.south 5 (some 0)] [(1, 1), (1, 11), (2, 1), (2, 12)]
  , scene 2000 [car 1 2 (-5) north12 4 (some 12), car 2 (-2) 4 Build.south 5 (some 0)] [(1, 1), (2, 1)] ]

/-- `branch_2` (compliant): Vehicle y on c2 opposed to c is 200 m from i at 15 m/s; x, in i after a recorded entry through c with int.left_turn x i declared, turns left. -/
def branch_2Trace : Trace :=
  [ scene 0 [car 1 2 (-13) Build.north 4 (some 0), car 2 (-2) 242 Build.south 15 (some 0)] [(1, 11), (2, 12)]
  , scene 1000 [car 1 2 (-9) Build.north 4 (some 0), car 2 (-2) 227 Build.south 15 (some 0)] [(1, 1), (1, 11), (2, 12)]
  , scene 2000 [car 1 2 (-5) north15 4 (some 15), car 2 (-2) 212 Build.south 15 (some 0)] [(1, 1), (2, 12)] ]

/-- `branch_3` (violated): x first crosses i from the west approach 13 and leaves it; it then
    re-enters i through 11 and turns left, its body sweeping over the end of 13, with y 20 m away
    at 15 m/s on 12, opposed to 11. Only x's latest entry fixes its approach: the earlier entry
    through 13, not opposed to 12, does not govern. -/
def branch_3Trace : Trace :=
  [ scene 0 [car 1 (-13) (-2) Build.east 4 (some 0)] [(1, 13)]
  , scene 1000 [car 1 (-9) (-2) Build.east 4 (some 0)] [(1, 1), (1, 13)]
  , scene 2000 [car 1 2 20 Build.north 4 (some 0)] []
  , scene 3000 [car 1 2 (-13) Build.north 4 (some 0), car 2 (-2) 62 Build.south 15 (some 0)] [(1, 11), (2, 12)]
  , scene 4000 [car 1 2 (-9) Build.north 4 (some 0), car 2 (-2) 47 Build.south 15 (some 0)] [(1, 1), (1, 11), (2, 12)]
  , scene 5000 [car 1 (-9) (-2) north15 4 (some 15), car 2 (-2) 32 Build.south 15 (some 0)] [(1, 1), (1, 13), (2, 12)] ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (1000, (τ.getLast?.map (·.t)).getD 0)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_253_o1
