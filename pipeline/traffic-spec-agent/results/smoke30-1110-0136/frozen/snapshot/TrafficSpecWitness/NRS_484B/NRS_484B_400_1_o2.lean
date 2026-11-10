/-
  Witnesses for NRS_484B_400_1_o2.

  Geometry (the witness's own figures; none appears in the rule). An eastbound approach on the
  highway 30 (x from -60 m to 0 m) runs into the intersection 20 (x from 0 m to 20 m). Its lanes
  all enter 20 and lie on 30: lane 11 (y 4..8 m, ordinal 1, the leftmost looking east) and lane 12
  (y 0..4 m, ordinal 2). In `idle` a right turn lane 13 (y -4..0 m, ordinal 3 of 3, side right)
  lies to the right of 12 and also enters 20; there 11 and 12 count 3 lanes.

  The car (track 1, a motor vehicle) drives east at three instants, 1 s apart: x = -30 m and
  x = -6 m on the approach, then x = 4 m inside the intersection, so the entry is the third instant
  and the observation before it is the second. Its declaration `int.turn_right` at 20 is current
  throughout. Occupancy is stated per scene.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def highway : Structure := Build.rect 30 .highway (m (-60)) (m (-10)) (m 0) (m 10)
def intersection : Structure := Build.rect 20 .intersection (m 0) (m (-10)) (m 20) (m 20)

/-- An eastbound approach lane between `y0` and `y1`, entering 20, on the highway 30. -/
def approachLane (id : RegionId) (y0 y1 : Int) (left right : Option RegionId) (ord cnt : Nat) : Structure :=
  { Build.lane id [(m (-60), m y0), (m 0, m y0), (m 0, m y1), (m (-60), m y1)] Build.east
      left right (some ord) (some cnt) none (some 20) with ways := some [30] }

/-- Two lanes, no right turn lane. -/
def twoLanes : List Structure :=
  [ highway, intersection
  , approachLane 11 4 8 none (some 12) 1 2
  , approachLane 12 0 4 (some 11) none 2 2 ]

/-- Two through lanes and a right turn lane at the right edge. -/
def withRightTurnLane : List Structure :=
  [ highway, intersection
  , approachLane 11 4 8 none (some 12) 1 3
  , approachLane 12 0 4 (some 11) (some 13) 2 3
  , { approachLane 13 (-4) 0 (some 12) none 3 3 with kind := .turnLane, turnSide := some .right } ]

def xAt (k : Nat) : Int := match k with | 0 => -30 | 1 => -6 | _ => 4

def car (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (xAt k), y) Build.east (Units.metresPerSecond 10) (cm 225, cm 90, cm 75)

def turnRight : List DeclaredIntent := [{ vehicle := 1, target := 20, values := [("int.turn_right", true)] }]

/-- Three instants; on the approach the car occupies `approach` and the highway, then the intersection. -/
def drive (structures : List Structure) (y : Q) (approach : List RegionId) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k y] structures []
      (occupies := some (if k < 2 then (1, 30) :: approach.map (fun r => (1, r)) else [(1, 20)]))
      (intents := turnRight)

/-- `branch_2`: a second junction region 21, recorded overlapping 20, on a second way 31. Lane 14
    (ordinal 1 of 2) and the right turn lane 13 (ordinal 2 of 2, side right) lie on 31 and enter 21. -/
def twoJunctions : List Structure :=
  [ highway, intersection
  , Build.rect 31 .highway (m (-60)) (m (-10)) (m 0) (m 10)
  , Build.rect 21 .intersection (m 0) (m (-10)) (m 20) (m 20)
  , approachLane 11 4 8 none (some 12) 1 2
  , approachLane 12 0 4 (some 11) none 2 2
  , { approachLane 14 0 4 none (some 13) 1 2 with
        lane := some { direction := some Build.east, rightNeighbour := some 13, ordinalFromLeft := some 1,
                       countInDirection := some 2, entersIntersection := some 21 }
        ways := some [31] }
  , { approachLane 13 (-4) 0 (some 14) none 2 2 with
        kind := .turnLane, turnSide := some .right
        lane := some { direction := some Build.east, leftNeighbour := some 14, ordinalFromLeft := some 2,
                       countInDirection := some 2, entersIntersection := some 21 }
        ways := some [31] } ]

def branch2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k (m 2)] twoJunctions []
      (occupies := some (if k < 2 then [(1, 30), (1, 31), (1, 12), (1, 14)] else [(1, 20), (1, 21)]))
      (intents := [ { vehicle := 1, target := 20, values := [("int.turn_right", true)] }
                  , { vehicle := 1, target := 21, values := [("int.turn_right", true)] } ])

/-- `forbid` (violated): On a two-lane approach without a right turn lane, a car with int.turn_right declared at the intersection enters it from the lane of ordinal 1 of 2. -/
def forbidTrace : Trace := drive twoLanes (m 6) [11]

/-- `permit` (compliant): The same car enters the intersection from the lane of ordinal 2 of 2. -/
def permitTrace : Trace := drive twoLanes (m 2) [12]

/-- `idle` (not_applicable): The approach has a right turn lane entering the intersection; the extreme-right-lane requirement does not apply. -/
def idleTrace : Trace := drive withRightTurnLane (m 2) [12]

/-- `blind` (unknown): A car with int.turn_right enters from one of two lanes; the source does not supply lane ordinals. -/
def blindTrace : Trace := drive twoLanes (m 6) [11]

/-- `branch_1` (violated): the car straddles lanes 11 and 12 before the entry; it occupies the
    extreme right lane but also a lane that is not, so not every lane it approaches through is. -/
def branch1Trace : Trace := drive twoLanes (m 4) [11, 12]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_1_o2"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch1Trace .violated
    -- branch_2 (compliant): the car enters 20 and 21 at once, approaching 20 from its extreme right
    -- lane 12 and 21 from lane 14, which is not; 21's way has a right turn lane, so 21 is not judged.
  , witness "branch_2" branch2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_400_1_o2
