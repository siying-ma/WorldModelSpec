/-
  Witnesses for NRS_484B_400_1_o1.

  Geometry (the witness's own figures, none of them in the rule). A northbound approach on
  highway 10 (y from −60 m to 0 m) into intersection 20 (y from 0 m to 30 m). Its lanes are
  3.5 m wide, side by side from x = 0 eastward: lane 30 + j has ordinal j of the count in that
  direction, its left and right neighbours are the lanes beside it, each lies on highway 10 and
  enters intersection 20. Where the approach has a right turn lane, it is the last (rightmost)
  lane, of kind `turn_lane` with side right.

  The car (track 1, a motor vehicle, half-extents 2 m × 0.9 m × 0.75 m, 7 m/s north) is at the
  centre of its lane at y = −12 m (t = 0 s) and y = −5 m (t = 1 s), and inside the intersection at
  y = 4 m (t = 2 s): its entry is the observation at 2 s, the observation before it is 1 s.
  Occupancy comes from the polygons, except in the straddling scene, where it is stated. The
  intention is declared at every observation, for the intersection.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def highwayId : RegionId := 10
def intersectionId : RegionId := 20
def laneId (j : Nat) : RegionId := 30 + j

/-- The western edge of lane `j` (1-based), in centimetres. -/
def laneEdge (j : Nat) : Int := (Int.ofNat j - 1) * 350

/-- Lane `j` of `n` in the northbound direction; the last one a right turn lane when `turn`. -/
def approachLane (n j : Nat) (turn : Bool) : Structure :=
  let base := Build.lane (laneId j)
    [(cm (laneEdge j), m (-60)), (cm (laneEdge (j + 1)), m (-60)),
     (cm (laneEdge (j + 1)), m 0), (cm (laneEdge j), m 0)]
    Build.north
    (if j > 1 then some (laneId (j - 1)) else none)
    (if j < n then some (laneId (j + 1)) else none)
    (some j) (some n) none (some intersectionId)
  let onHighway := { base with ways := some [highwayId] }
  if turn && j == n then { onHighway with kind := .turnLane, turnSide := some .right } else onHighway

/-- The highway, the intersection and the `n` lanes of the approach. -/
def layout (n : Nat) (turn : Bool) : List Structure :=
  let width := Int.ofNat n * 350
  [ Build.rect highwayId .highway (m (-10)) (m (-60)) (Q.add (cm width) (m 10)) (m 0)
  , { Build.rect intersectionId .intersection (m (-15)) (m 0) (Q.add (cm width) (m 15)) (m 30)
      with ways := some [highwayId] } ]
  ++ (List.range n).map fun k => approachLane n (k + 1) turn

/-- The car at instant `k`, starting at the centre of lane `j`. -/
def car (j k : Nat) : RoadUser :=
  let y := if k == 0 then m (-12) else if k == 1 then m (-5) else m 4
  Build.user 1 [.motorVehicle] (cm (laneEdge j + 175), y) Build.north (Units.metresPerSecond 7)
    (m 2, cm 90, cm 75)

def intends (values : List (IntId × Bool)) : List DeclaredIntent :=
  [{ vehicle := 1, target := intersectionId, values := values }]

def turnRight : List (IntId × Bool) := [("int.turn_right", true)]

/-- The car approaches in lane `j` of `n` and enters the intersection at 2 s. -/
def approach (n j : Nat) (turn : Bool) (values : List (IntId × Bool))
    (occupies : Nat → Option (List (TrackId × RegionId)) := fun _ => none) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car j k] (layout n turn) [] (occupies := occupies k)
      (intents := intends values)

/-- `forbid` (violated): A car with int.turn_right declared at the intersection enters it from the rightmost through lane although a right turn lane, the rightmost lane of the same direction, enters the same intersection. -/
def forbidTrace : Trace := approach 3 2 true turnRight

/-- `permit` (compliant): The same car enters the intersection from the right turn lane. -/
def permitTrace : Trace := approach 3 3 true turnRight

/-- `idle` (not_applicable): A car with int.turn_left declared and no right-turn intention enters the intersection from the through lane. -/
def idleTrace : Trace := approach 3 2 true [("int.turn_left", true), ("int.turn_right", false)]

/-- `blind` (unknown): A car with int.turn_right enters the intersection; the source does not record which intersection the lanes enter. -/
def blindTrace : Trace := approach 3 2 true turnRight

/-- `branch_1` (not_applicable): A car with int.turn_right enters an intersection whose approach has no right turn lane (that case is the extreme-right-lane node's). -/
def branch_1Trace : Trace := approach 2 2 false turnRight

/-- `branch_2` (violated): the car straddles the rightmost through lane and the right turn lane
    before entering: it occupies the turn lane, but also a carrier entering the intersection that
    is not the right turn lane. -/
def branch_2Trace : Trace :=
  approach 3 3 true turnRight fun k =>
    if k < 2 then some [(1, laneId 2), (1, laneId 3), (1, highwayId)] else some [(1, intersectionId)]

/-- `branch_3` (violated): six lanes; the car enters from lane 4, two right-neighbour links left of
    the right turn lane. -/
def branch_3Trace : Trace := approach 6 4 true turnRight

/-- `branch_4` (violated): six lanes; the car enters from lane 3, three links left of the turn lane. -/
def branch_4Trace : Trace := approach 6 3 true turnRight

/-- `branch_5` (violated): six lanes; the car enters from lane 2, four links left of the turn lane. -/
def branch_5Trace : Trace := approach 6 2 true turnRight

/-- `branch_6` (violated): six lanes; the car enters from lane 1, five links left of the turn lane. -/
def branch_6Trace : Trace := approach 6 1 true turnRight

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_1_o1"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_enters"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.NRS_484B_400_1_o1
