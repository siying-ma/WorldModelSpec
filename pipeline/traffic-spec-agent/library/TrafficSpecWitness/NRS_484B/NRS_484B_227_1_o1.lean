/-
  Witnesses for NRS_484B_227_1_o1.

  Geometry (every figure is the witness's own and appears nowhere in the rule): an east–west
  highway (region 1) spans x ∈ [-100, 100] m, y ∈ [-20, 20] m. On the divided highway, a raised
  median (region 4) spans y ∈ [-2, 2]; the north roadway (region 2, y ∈ [2, 10]) carries westbound
  traffic, the south roadway (region 3, y ∈ [-10, -2]) eastbound traffic, as right-hand traffic
  makes it. A side street (highway 5, roadway 6) leaves northwards from y = 20. The car (track 1)
  is 4 m × 2 m. Three instants, one second apart.

  Against the reading (speed floor 0.2 m/s, opposed cosine 0.5): `forbid` moves at 10 m/s along
  the westbound roadway eastwards (cosine −1, well past −0.5); `permit` moves eastwards on the
  eastbound roadway (cosine +1); `branch_1` crosses the westbound roadway northwards at 2 m/s
  (cosine 0, inside the tolerance); `branch_2` crosses the median opening at 1 m/s, on no roadway.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

def car (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading speed carExtent

/-- The highway, region 1. -/
def highway : Structure := Build.rect 1 .highway (m (-100)) (m (-20)) (m 100) (m 20)

/-- A roadway lying on highway 1, with a designated direction. -/
def roadway (id : RegionId) (y0 y1 : Q) (dir : Option Vec) : Structure :=
  { Build.rect id .roadway (m (-100)) y0 (m 100) y1 with
      lane := some { direction := dir }, ways := some [1] }

def northRoadway : Structure := roadway 2 (m 2) (m 10) (some Build.west)
def southRoadway : Structure := roadway 3 (m (-10)) (m (-2)) (some Build.east)

/-- The raised median, region 4, with an opening. -/
def median : Structure :=
  { Build.rect 4 .medianOrDivider (m (-100)) (m (-2)) (m 100) (m 2) with
      ways := some [1], opening := some true }

def dividedHighway : List Structure := [highway, northRoadway, southRoadway, median]

/-- The side street to the north: highway 5 and its roadway 6. -/
def sideStreet : List Structure :=
  [ Build.rect 5 .highway (m (-5)) (m 20) (m 5) (m 80)
  , { Build.rect 6 .roadway (m (-5)) (m 20) (m 5) (m 80) with
        lane := some {}, ways := some [5] } ]

/-- `forbid` (violated): On a highway divided by a raised median, a car drives along the roadway whose designated direction is opposite to its travel. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (-20 + 10 * k), m 6) Build.east (Units.metresPerSecond 10) ]
      dividedHighway
      [ ]

/-- `permit` (compliant): On the same divided highway, a car drives along the roadway in its designated direction. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (-20 + 10 * k), m (-6)) Build.east (Units.metresPerSecond 10) ]
      dividedHighway
      [ ]

/-- `idle` (not_applicable): A car drives on an undivided two-way highway: no median or dividing section lies on the way. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (-20 + 10 * k), m (-4)) Build.east (Units.metresPerSecond 10) ]
      [ highway, roadway 2 (m (-10)) (m 10) none ]
      [ ]

/-- `blind` (unknown): A car drives along one roadway of a divided highway; the source declares st.lane_direction absent, so whether it travels against the roadway's direction is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (-20 + 10 * k), m (-6)) Build.east (Units.metresPerSecond 10) ]
      dividedHighway
      [ ]

/-- `branch_1` (compliant): A car that has turned left through a median opening crosses the opposite roadway at a right angle to its designated direction to reach a side street. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 0, m (4 + 2 * k)) Build.north (Units.metresPerSecond 2) ]
      (dividedHighway ++ sideStreet)
      [ ]

-- `branch_2` (compliant): a car crossing the median through its opening is upon the divided
-- highway but on none of its roadways, so it travels against no roadway's direction.
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 0, m (-1 + k)) Build.north (Units.metresPerSecond 1) ]
      dividedHighway
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_227_1_o1
