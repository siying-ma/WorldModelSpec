/-
  Witnesses for NRS_484B_223_4a.

  A highway (region 100) runs north, x ∈ [-10, 20] m, y ∈ [-60, 80] m; its northbound lanes are
  4 m wide from x = 0, numbered from the left, each lying on the highway and entering the
  intersection 200 (y ∈ [50, 70] m). In the two-lane layout lane 101 (x ∈ [0, 4]) is a through
  lane and lane 102 (x ∈ [4, 8]) the single right turn lane; in the three-lane layout (branch_2)
  lanes 102 and 103 (x ∈ [8, 12]) are both right turn lanes. Car 1 (half-extents 2 × 1 × 1 m)
  drives north at 5 m/s from y = -20 m, three instants one second apart, its reference point at
  the centre of the lane it is in (x = 6 for 102, x = 2 for 101, x = 10 for 103). Its declared
  intention int.turn_right is given for intersection 200. Every figure here is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_4a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_4a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def highwayId : RegionId := 100
def intersectionId : RegionId := 200

/-- An axis-aligned polygon. -/
def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def highway : Structure := Build.rect highwayId .highway (m (-10)) (m (-60)) (m 20) (m 80)
def intersection : Structure :=
  { Build.rect intersectionId .intersection (m (-10)) (m 50) (m 20) (m 70) with ways := some [highwayId] }

/-- A northbound lane on the highway, entering the intersection: `k`-th from the left of `n`. -/
def laneAt (id : RegionId) (k n : Nat) (left right : Option RegionId) : Structure :=
  { Build.lane id (box (4 * (Int.ofNat k - 1)) (-50) (4 * Int.ofNat k) 50) Build.north left right
      (some k) (some n) none (some intersectionId) with ways := some [highwayId] }

def rightTurn (st : Structure) : Structure := { st with kind := .turnLane, turnSide := some .right }

/-- Two lanes: a through lane 101 and the single right turn lane 102. -/
def twoLaneWithTurn : List Structure :=
  [ highway, intersection
  , laneAt 101 1 2 none (some 102)
  , rightTurn (laneAt 102 2 2 (some 101) none) ]

/-- Two through lanes, no turn lane. -/
def twoThroughLanes : List Structure :=
  [ highway, intersection
  , laneAt 101 1 2 none (some 102)
  , laneAt 102 2 2 (some 101) none ]

/-- Three lanes: a through lane 101 and two adjacent right turn lanes 102 and 103. -/
def twoTurnLanes : List Structure :=
  [ highway, intersection
  , laneAt 101 1 3 none (some 102)
  , rightTurn (laneAt 102 2 3 (some 101) (some 103))
  , rightTurn (laneAt 103 3 3 (some 102) none) ]

/-- Two lanes: a left turn lane 101 and, beside it, the single right turn lane 102. -/
def leftThenRightTurn : List Structure :=
  [ highway, intersection
  , { laneAt 101 1 2 none (some 102) with kind := .turnLane, turnSide := some .left }
  , rightTurn (laneAt 102 2 2 (some 101) none) ]

/-- Car 1 driving north at 5 m/s with its reference point at `x`. -/
def car (x : Int) (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m (-20 + 5 * Int.ofNat k)) Build.north (Units.metresPerSecond 5)
    (m 2, m 1, m 1) (some (m (5 * Int.ofNat k)))

def turnRight (v : Bool) : List DeclaredIntent :=
  [ { vehicle := 1, target := intersectionId, values := [("int.turn_right", v)] } ]

def run (x : Int) (structures : List Structure) (intents : List DeclaredIntent) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car x k] structures [] (intents := intents)

/-- `forbid` (violated): A car's footprint overlaps the single right turn lane of a highway; the source declares int.turn_right false for it at the intersection the lane enters (its plan goes straight on). -/
def forbidTrace : Trace := run 6 twoLaneWithTurn (turnRight false)

/-- `permit` (compliant): As forbid, with int.turn_right declared true at that intersection. -/
def permitTrace : Trace := run 6 twoLaneWithTurn (turnRight true)

/-- `idle` (not_applicable): A car drives on a highway with no turn lane on it. -/
def idleTrace : Trace := run 6 twoThroughLanes (turnRight false)

/-- `blind` (unknown): A car drives beside and possibly within the right turn lane; rel.occupies is declared absent. -/
def blindTrace : Trace := run 5 twoLaneWithTurn (turnRight false)

/-- `branch_1` (compliant): A car drives in the through lane beside the single right turn lane; no intention is declared for it. -/
def branch_1Trace : Trace := run 2 twoLaneWithTurn []

/-- `branch_2` (not_applicable): The highway has two adjacent right turn lanes (no single right turn lane); a car in the rightmost one has int.turn_right declared false. -/
def branch_2Trace : Trace := run 10 twoTurnLanes (turnRight false)

/-- `branch_3` (violated): The right turn lane's left neighbour is a left turn lane, so it is still the single right turn lane; a car in it has int.turn_right declared false. -/
def branch_3Trace : Trace := run 6 leftThenRightTurn (turnRight false)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_223_4a"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_223_4a
