/-
  Witnesses for NRS_484B_777_1_o1.

  Geometry (world frame, +x east, +y north; one observation at t = 0):
  - highway 100: x −100…200, y −3…13 (sidewalk, roadway and verge);
  - roadway 101: x −100…200, y 0…10, designated direction east, lying on 100;
  - outside lane 102: x −100…200, y 0…5 (or 0…3.5), width 5.0 m (3.5 m in branch_2), on 100;
  - right road edge 103: the strip x −100…200, y −0.2…0, on 100;
  - sidewalk 104: x −100…200, y −3…−0.2, on 100.
  The subject (track 1) is a bicycle heading east at 5 m/s, half-extent 0.9 × 0.3 × 0.9 m, at
  x = 0. Its reference point at y = 2.8 puts its body 2.5 m from the edge (forbid); y = 0.9 puts
  it 0.6 m from the edge (permit). The car (track 2) is a motor vehicle heading east at 13 m/s,
  half-extent 2.3 × 0.9 × 0.8 m, centre (−23.2, 2.5): its front 20 m behind the bicycle's rear.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_777_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_777_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def hwy : RegionId := 100
def roadwayId : RegionId := 101
def laneId : RegionId := 102
def edgeId : RegionId := 103
def sidewalkId : RegionId := 104

def highway : Structure := Build.rect hwy .highway (m (-100)) (m (-3)) (m 200) (m 13)
def roadway : Structure :=
  { Build.rect roadwayId .roadway (m (-100)) (m 0) (m 200) (m 10) with
    lane := some { direction := some Build.east }, ways := some [hwy] }
def outsideLane (widthCm : Int) : Structure :=
  { Build.rect laneId .lane (m (-100)) (m 0) (m 200) (cm widthCm) with
    lane := some { direction := some Build.east, width := some (cm widthCm) }, ways := some [hwy] }
def roadEdge : Structure :=
  { Build.rect edgeId .roadEdge (m (-100)) (cm (-20)) (m 200) (m 0) with ways := some [hwy] }
def sidewalk : Structure :=
  { Build.rect sidewalkId .sidewalk (m (-100)) (m (-3)) (m 200) (cm (-20)) with ways := some [hwy] }

def street (laneWidthCm : Int := 500) : List Structure :=
  [highway, roadway, outsideLane laneWidthCm, roadEdge, sidewalk]

def bike (y : Q) (cls : RoadUserClass := .bicycle) : RoadUser :=
  Build.user 1 [cls] (m 0, y) Build.east (Units.metresPerSecond 5) (cm 90, cm 30, cm 90)

def car : RoadUser :=
  Build.user 2 [.motorVehicle] (cm (-2320), cm 250) Build.east (Units.metresPerSecond 13) (cm 230, cm 90, cm 80)

def oneScene (users : List RoadUser) (structures : List Structure)
    (intents : List DeclaredIntent := []) : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures [] (intents := intents)

/-- `forbid` (violated): A bicycle rides at 5 m/s on a roadway whose outside lane is 5.0 m wide, its body 2.5 m from the right road edge; a car of the vehicle and traffic aggregates travels the same way at 13 m/s with a body gap of 20 m behind it; no obstruction or other road user is on its right, no intersection or driveway entrance is in the scene, so no left turn is declared. -/
def forbidTrace : Trace := oneScene [bike (cm 280), car] (street)

/-- `permit` (compliant): As forbid, but the bicycle rides with its body 0.6 m from the right road edge. -/
def permitTrace : Trace := oneScene [bike (cm 90), car] (street)

/-- `idle` (not_applicable): A bicycle rides on a sidewalk, its footprint overlapping no roadway. -/
def idleTrace : Trace := oneScene [bike (cm (-150))] (street)

/-- `blind` (unknown): As forbid, but the source maps regions without their outlines, so the road edge's lateral offset from the bicycle is unobserved. -/
def blindTrace : Trace := oneScene [bike (cm 280), car] (street)

/-- `branch_1` (not_applicable): A bicycle rides alone at 5 m/s in the middle of a 5.0 m outside lane, 2.5 m from the right edge; no other road user is in the scene, so its speed is commensurate with any nearby traffic vacuously and, a bicycle not being engaged by NRS_484B_785_1a, lawful: exception (a) holds and the duty does not arise. -/
def branch_1Trace : Trace := oneScene [bike (cm 280)] (street)

/-- `branch_2` (not_applicable): As forbid, but the outside lane is 3.5 m wide, below the shared-lane width (exception (c), s14). -/
def branch_2Trace : Trace := oneScene [bike (cm 280), car] (street 350)

/-- `branch_3` (not_applicable): As forbid, but a parked car of the vehicle aggregate stands 10 m ahead of the bicycle on its right, at the curb (exception (c), s13). -/
def parkedCar : RoadUser :=
  Build.user 3 [.motorVehicle] (cm 1320, cm 110) Build.east (Units.metresPerSecond 0) (cm 230, cm 90, cm 80)
def branch_3Trace : Trace := oneScene [bike (cm 280), car, parkedCar] (street)

/-- `branch_4` (not_applicable): As forbid, but an intersection lying on the highway of the roadway the bicycle occupies lies ahead, and the source declares int.left_turn for the bicycle at it (exception (b)). -/
def intersectionAhead : Structure :=
  { Build.rect 105 .intersection (m 40) (m 0) (m 60) (m 10) with ways := some [hwy] }
def branch_4Trace : Trace :=
  oneScene [bike (cm 280), car] (street ++ [intersectionAhead])
    [{ vehicle := 1, target := 105, values := [("int.left_turn", true)] }]

/-- `branch_5` (violated): As forbid, but an intersection lying on another highway, on which no roadway the bicycle occupies lies, is in the scene, and the source declares int.left_turn for the bicycle at it: that is no left turn off the roadway the bicycle is upon, so exception (b) does not hold. -/
def otherHighway : Structure := Build.rect 110 .highway (m 300) (m (-50)) (m 320) (m 50)
def otherIntersection : Structure :=
  { Build.rect 111 .intersection (m 300) (m 0) (m 320) (m 10) with ways := some [110] }
def branch_5Trace : Trace :=
  oneScene [bike (cm 280), car] (street ++ [otherHighway, otherIntersection])
    [{ vehicle := 1, target := 111, values := [("int.left_turn", true)] }]

/-- `branch_6` (not_applicable): As forbid, but debris lies on the roadway near the curb 14 m ahead of the bicycle, on its right (exception (c), s13, an object). -/
def debris : Structure :=
  { Build.rect 107 .obstruction (m 14) (cm 30) (m 15) (cm 130) with obstructionKind := some .debris }
def branch_6Trace : Trace := oneScene [bike (cm 280), car] (street ++ [debris])

/-- `branch_7` (not_applicable): As forbid, but a pedestrian stands on the roadway at the curb 8 m ahead of the bicycle, on its right (exception (c), s13, a pedestrian). -/
def walker : RoadUser :=
  Build.user 4 [.pedestrian] (m 8, m 1) Build.east (Units.metresPerSecond 0) (cm 30, cm 30, cm 90)
def branch_7Trace : Trace := oneScene [bike (cm 280), car, walker] (street)

/-- `branch_8` (not_applicable): As forbid, but another bicycle rides at 5 m/s 8 m ahead of the subject, near the curb on its right (exception (c), s13, a bicycle). -/
def otherBike : RoadUser :=
  Build.user 5 [.bicycle] (m 8, m 1) Build.east (Units.metresPerSecond 5) (cm 90, cm 30, cm 90)
def branch_8Trace : Trace := oneScene [bike (cm 280), car, otherBike] (street)

/-- `branch_9` (not_applicable): As forbid, but a driveway entrance lying on the bicycle's highway lies ahead on its left, and the source declares int.left_turn for the bicycle at it (exception (b), a driveway). -/
def drivewayAhead : Structure :=
  { Build.rect 106 .drivewayOrAlleyEntrance (m 40) (m 10) (m 46) (m 13) with ways := some [hwy] }
def branch_9Trace : Trace :=
  oneScene [bike (cm 280), car] (street ++ [drivewayAhead])
    [{ vehicle := 1, target := 106, values := [("int.left_turn", true)] }]

/-- `branch_10` (violated): As forbid, but the subject is an electric bicycle. -/
def branch_10Trace : Trace := oneScene [bike (cm 280) .electricBicycle, car] (street)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_777_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .violated ]

end TrafficSpecWitness.NRS_484B_777_1_o1
