/-
  Witnesses for NRS_484B_307_9a_o2.

  Geometry (metres, +x east, +y north): the intersection 100 is the square (-10,-10)–(10,10). The
  northbound approach lane 101 is (0,-40)–(5,-10) and enters 100; the eastbound approach lane 102
  of the cross street to the west is (-40,-10)–(-10,0) and enters 100. The crosswalk 103,
  (-14,-10)–(-10,10), runs across the west leg and is recorded as marking the entrance of 102.
  Signal 200 governs lane 101 (in `branch_2`, the intersection 100 instead).

  The car (track 1, half-extent 2 × 1 m) is in lane 101 at (2.5,-14) heading north at 5 m/s at
  t = 0 s, then inside the intersection heading west for its left turn. The pedestrian (track 2)
  walks south along x = -12 in the crosswalk. Instants are 1 s apart. With the reading's horizon
  of 3 s and clearance of 4 m: in `forbid` at t = 2 s the car at (-6,2) at 5 m/s and the pedestrian
  at (-12,4) at 1 m/s reach their closest approach after about 1.2 s at about 0.8 m; in `permit`
  the car stands at (0,-2) at t = 1, 2 s and moves at t = 3 s from (-4,2) with the pedestrian at
  (-12,-1) going south at 3 m/s, closest approach about 6.7 m. Every figure here is the witness's
  own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9a_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9a_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def intersectionId : RegionId := 100
def northApproachId : RegionId := 101
def westApproachId : RegionId := 102
def crosswalkId : RegionId := 103
def signalId : DeviceId := 200

def intersection : Structure := Build.rect intersectionId .intersection (m (-10)) (m (-10)) (m 10) (m 10)

def northApproach : Structure :=
  Build.lane northApproachId [(m 0, m (-40)), (m 5, m (-40)), (m 5, m (-10)), (m 0, m (-10))] Build.north
    (enters := some intersectionId)

def westApproach : Structure :=
  Build.lane westApproachId [(m (-40), m (-10)), (m (-10), m (-10)), (m (-10), m 0), (m (-40), m 0)] Build.east
    (enters := some intersectionId)

/-- The crosswalk on the west leg; `observed` says whether the source records which approach it marks. -/
def crosswalk (observed : Bool) : Structure :=
  { Build.rect crosswalkId .crosswalk (m (-14)) (m (-10)) (m (-10)) (m 10) with
    marked := some true
    entranceOf := if observed then [westApproachId] else []
    entranceObserved := observed }

def structures (observed : Bool := true) : List Structure :=
  [intersection, northApproach, westApproach, crosswalk observed]

def redWithLeftArrow : Device := Build.signal signalId [northApproachId] [.circularRed, .greenArrow .left]

def car (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading speed (m 2, m 1, cm 75)

def pedestrian (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 2 [.pedestrian] pos Build.south speed (cm 30, cm 30, cm 90)

/-- The car's turn: in the approach lane, then inside the intersection heading west. -/
def turningCar : Nat → RoadUser
  | 0 => car (cm 250, m (-14)) Build.north (m 5)
  | 1 => car (m 0, m (-2)) Build.west (m 5)
  | _ => car (m (-6), m 2) Build.west (m 5)

/-- The pedestrian walking south in the crosswalk at 1 m/s. -/
def walkingPedestrian (k : Nat) : RoadUser :=
  pedestrian (m (-12), m (6 - (k : Int))) (m 1)

/-- `forbid` (violated): A car enters on circular_red with green_arrow(left) and turns left while a pedestrian walks in the crosswalk marking the entrance of the cross street's approach; while the car moves their predicted closest approach within the horizon is below the conflict clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar k, walkingPedestrian k ]
      (structures)
      [ redWithLeftArrow ]

/-- `permit` (compliant): The car halts inside the intersection until the pedestrian has cleared and turns with no predicted conflict while it moves. -/
def permitCar : Nat → RoadUser
  | 0 => car (cm 250, m (-14)) Build.north (m 5)
  | 1 => car (m 0, m (-2)) Build.west Q.zero
  | 2 => car (m 0, m (-2)) Build.west Q.zero
  | _ => car (m (-4), m 2) Build.west (m 5)

def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ permitCar k, pedestrian (m (-12), m (8 - 3 * (k : Int))) (m 3) ]
      (structures)
      [ redWithLeftArrow ]

/-- `idle` (not_applicable): The car enters on circular_green and turns left. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar k, walkingPedestrian k ]
      (structures)
      [ Build.signal signalId [northApproachId] [.circularGreen] ]

/-- `blind` (unknown): The car turns on the arrow while a pedestrian on a crosswalk at the intersection is in predicted conflict with it; the source does not record which approach the crosswalk marks. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar k, walkingPedestrian k ]
      (structures (observed := false))
      [ redWithLeftArrow ]

/-- `branch_1` (compliant): A car enters on red with a green left arrow and turns left with no other road user in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar k ]
      (structures)
      [ redWithLeftArrow ]

/-- `branch_2` (violated): the signal showing red with the left arrow governs the intersection
    itself; the car turns into predicted conflict with the pedestrian in the crosswalk. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar k, walkingPedestrian k ]
      (structures)
      [ Build.signal signalId [intersectionId] [.circularRed, .greenArrow .left] ]

/-- `branch_3` (violated): no pedestrian; a car (track 3) stands inside the intersection at
    (-8,1) and the turning car, entered on the arrow, heads at it (closest approach 3 m within 1.6 s). -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turningCar k, Build.user 3 [.motorVehicle] (m (-8), m 1) Build.north Q.zero (m 2, m 1, cm 75) ]
      (structures)
      [ redWithLeftArrow ]

/-- `branch_4` (not_applicable): the road user entering on the arrow is a pedestrian, not
    vehicular traffic. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (cm 250, m (-13 + 4 * (k : Int))) Build.north (m 2) (cm 30, cm 30, cm 90) ]
      (structures)
      [ redWithLeftArrow ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9a_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.entrance_of"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_9a_o2
