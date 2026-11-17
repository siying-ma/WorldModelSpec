/-
  Witnesses for LVMC_11_30_050.

  Geometry (metres, +x east, +y north): a roadway (region 10) from x = -50 to 50, y = 0 to 10;
  two lanes, 11 (y 0..5) and 12 (y 5..10); a sidewalk (20) along its north curb, y 10..13; a
  marked crosswalk (30) across the roadway at x 20..24. The curbs run east–west.
  * two-way roadway: lane 11 runs east, lane 12 west; the roadway itself carries no direction.
  * one-way roadway: both lanes and the roadway carry the direction east.
  * unlaned one-way roadway: the roadway alone, direction east, no lanes.
  The pedestrian (track 1, class pedestrian, half-extent 0.3 × 0.3 × 0.9 m) walks at 1.4 m/s:
  * diagonal heading (3/5, 4/5): |cos| with east 0.6, about 37° off perpendicular;
  * square heading (21/221, 220/221): |cos| with east about 0.095, about 5.5° off perpendicular.
  Three instants one second apart. Every figure is the witness's own and appears nowhere in the
  rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_050
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_050

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def walkSpeed : Q := Units.micrometresPerSecond 1400000
def halfBody : Q × Q × Q := (cm 30, cm 30, cm 90)
def diagonal : Vec := (Units.ratio 3 5, Units.ratio 4 5)
def square : Vec := (Units.ratio 21 221, Units.ratio 220 221)

def roadwayUndirected : Structure := Build.rect 10 .roadway (m (-50)) (m 0) (m 50) (m 10)
def roadwayEast : Structure :=
  { roadwayUndirected with lane := some { direction := some Build.east } }
def lane11 : Structure := Build.lane 11 [(m (-50), m 0), (m 50, m 0), (m 50, m 5), (m (-50), m 5)] Build.east
def lane12East : Structure := Build.lane 12 [(m (-50), m 5), (m 50, m 5), (m 50, m 10), (m (-50), m 10)] Build.east
def lane12West : Structure := Build.lane 12 [(m (-50), m 5), (m 50, m 5), (m 50, m 10), (m (-50), m 10)] Build.west
def sidewalk : Structure := Build.rect 20 .sidewalk (m (-50)) (m 10) (m 50) (m 13)
def crosswalk : Structure :=
  { Build.rect 30 .crosswalk (m 20) (m 0) (m 24) (m 10) with marked := some true }

def twoWay : List Structure := [roadwayUndirected, lane11, lane12West, sidewalk]
def oneWay : List Structure := [roadwayEast, lane11, lane12East, sidewalk]

def ped (pos : Vec) (heading : Vec) : RoadUser :=
  Build.user 1 [.pedestrian] pos heading walkSpeed halfBody

/-- `forbid` (violated): A pedestrian crosses a laned roadway mid-block, away from any crosswalk, walking at 1.4 m/s at 40 degrees off perpendicular to the lane direction. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (cm (84 * (k : Int)), cm (100 + 112 * (k : Int))) diagonal ]
      twoWay
      [ ]

/-- `permit` (compliant): A pedestrian crosses the same roadway mid-block walking at 1.4 m/s at 5 degrees off perpendicular to the lane direction. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (cm (13 * (k : Int)), cm (100 + 139 * (k : Int))) square ]
      oneWay
      [ ]

/-- `idle` (not_applicable): A pedestrian walks along the sidewalk and never occupies the roadway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (cm (140 * (k : Int)), cm 1150) Build.east ]
      oneWay
      [ ]

/-- `blind` (unknown): A pedestrian occupies the roadway mid-block, but its velocity is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (cm (84 * (k : Int)), cm (100 + 112 * (k : Int))) diagonal ]
      oneWay
      [ ]

/-- `branch_1` (not_applicable): A pedestrian crosses diagonally at 40 degrees off perpendicular inside a marked crosswalk. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (cm (2200 + 84 * (k : Int)), cm (100 + 112 * (k : Int))) diagonal ]
      (oneWay ++ [crosswalk])
      [ ]

/-- `branch_2` (violated): A pedestrian crosses an unlaned one-way roadway mid-block diagonally,
    so the roadway itself is the carrier crossed. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (cm (84 * (k : Int)), cm (100 + 112 * (k : Int))) diagonal ]
      [roadwayEast, sidewalk]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_30_050"
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.LVMC_11_30_050
