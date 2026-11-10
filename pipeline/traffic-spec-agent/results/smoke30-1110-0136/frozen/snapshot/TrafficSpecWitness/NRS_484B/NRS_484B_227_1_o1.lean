/-
  Witnesses for NRS_484B_227_1_o1.

  The divided highway (region 10) runs east–west over x ∈ [0, 200] m, y ∈ [-12, 12] m. A median
  (11) lies on it over y ∈ [-1, 1]; the right-hand roadway for eastbound traffic (12) is
  y ∈ [-11, -1], designated east; the left-hand roadway (13) is y ∈ [1, 11], designated west.
  Every carrier lists the highway as its way. The car (track 1) is 4 m × 2 m and moves at 15 m/s,
  sampled at 0, 1, 2 s. Headings are exactly opposed (cosine -1) or exactly perpendicular or
  along (cosine 0 or above), far from the reading's tolerance either way.

  - forbid: the car heads east on the westbound roadway at y = 5.
  - permit: the car heads east on the eastbound roadway at y = -5.
  - idle: an undivided highway (20) with one roadway (21) and two lanes (22 east, 23 west), no
    median; the car heads east in the westbound lane at y = 3.
  - blind: forbid with kin.heading masked.
  - branch_1: the median is broken by an intersection (16) over x ∈ [90, 110]; the car turns left
    there, from east through north-east to north, crossing the westbound roadway at x = 100, y = 5.
  - branch_2: as forbid, but the westbound roadway carries no direction and its two lanes (14,
    15) carry it; the car heads east in lane 14 at y = 4.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)
def carSpeed : Q := Units.metresPerSecond 15

def car (x y : Int) (heading : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) heading carSpeed carExtent

/-- A structure lying on the highway `w`. -/
def onWay (w : RegionId) (s : Structure) : Structure := { s with ways := some [w] }

/-- A carrier with a designated direction. -/
def directed (d : Vec) (s : Structure) : Structure := { s with lane := some { direction := some d } }

def dividedHighway : Structure := Build.rect 10 .highway (m 0) (m (-12)) (m 200) (m 12)
def median : Structure :=
  { onWay 10 (Build.rect 11 .medianOrDivider (m 0) (m (-1)) (m 200) (m 1)) with opening := some false }
def eastbound : Structure := directed Build.east (onWay 10 (Build.rect 12 .roadway (m 0) (m (-11)) (m 200) (m (-1))))
def westbound : Structure := directed Build.west (onWay 10 (Build.rect 13 .roadway (m 0) (m 1) (m 200) (m 11)))

def dividedScene : List Structure := [dividedHighway, median, eastbound, westbound]

/-- `forbid` (violated): On a highway with a median, a car moves along the left-hand roadway, its kin.heading opposed to that roadway's st.lane_direction (wrong-way driving). -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (100 + 15 * (k : Int)) 5 Build.east ]
      dividedScene
      [ ]

/-- `permit` (compliant): The same car moves along the right-hand roadway, its heading along the designated direction. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (100 + 15 * (k : Int)) (-5) Build.east ]
      dividedScene
      [ ]

/-- `idle` (not_applicable): On an undivided two-way highway (no st.median_or_divider on it) a car moves in the opposing lane while passing. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (100 + 15 * (k : Int)) 3 Build.east ]
      [ Build.rect 20 .highway (m 0) (m (-8)) (m 200) (m 8)
      , onWay 20 (Build.rect 21 .roadway (m 0) (m (-7)) (m 200) (m 7))
      , directed Build.east (onWay 20 (Build.rect 22 .lane (m 0) (m (-7)) (m 200) (m 0)))
      , directed Build.west (onWay 20 (Build.rect 23 .lane (m 0) (m 0) (m 200) (m 7))) ]
      [ ]

/-- `blind` (unknown): As forbid, with kin.heading declared absent. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): A car turning left at an intersection of the divided highway crosses the left-hand roadway across its direction; its heading is never opposed to that roadway's direction. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let pose : Int × Int × Vec :=
      match k with
      | 0 => (95, -5, Build.east)
      | 1 => (99, -3, (Q.ofInt 1, Q.ofInt 1))
      | _ => (100, 5, Build.north)
    Build.scene t (some 1)
      [ car pose.1 pose.2.1 pose.2.2 ]
      [ dividedHighway
      , { onWay 10 (Build.rect 11 .medianOrDivider (m 0) (m (-1)) (m 90) (m 1)) with opening := some false }
      , { onWay 10 (Build.rect 17 .medianOrDivider (m 110) (m (-1)) (m 200) (m 1)) with opening := some false }
      , onWay 10 (Build.rect 16 .intersection (m 90) (m (-12)) (m 110) (m 12))
      , eastbound, westbound ]
      [ ]

/-- `branch_2` (violated): As forbid, but the left-hand roadway carries no direction and its lanes do; the car heads against its lane's direction. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (100 + 15 * (k : Int)) 4 Build.east ]
      [ dividedHighway, median, eastbound
      , onWay 10 (Build.rect 13 .roadway (m 0) (m 1) (m 200) (m 11))
      , directed Build.west (onWay 10 (Build.rect 14 .lane (m 0) (m 1) (m 200) (m 6)))
      , directed Build.west (onWay 10 (Build.rect 15 .lane (m 0) (m 6) (m 200) (m 11))) ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o1"
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
  , witness "blind" blindTrace (.unknown []) ["kin.heading"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_227_1_o1
