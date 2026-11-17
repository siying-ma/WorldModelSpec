/-
  Witnesses for LVMC_11_30_050.

  Geometry (the witness's own figures; none appears in the rule): a straight east–west roadway
  (region 10) spanning x ∈ [-50, 50] m, y ∈ [0, 10] m; two lanes, lane 11 for y ∈ [0, 5] and lane 12
  for y ∈ [5, 10]; a sidewalk (region 20) for y ∈ [10, 13]. The pedestrian (track 1, half-extents
  0.3 × 0.3 × 0.9 m) stands at (0, 2.5) in lane 11, walking at 1.4 m/s.

  Headings are exact unit vectors: the diagonal heading (3/5, 4/5) is 36.9° off the perpendicular
  (|cos| with the lane direction 0.6, between the right-angle bound and the crossing bound by a clear
  margin each); the near-square heading (21/221, 220/221) is 5.5° off it (|cos| ≈ 0.095).

  forbid/permit: one-way roadway with both lanes eastbound, the roadway itself carrying direction east.
  branch_1: as forbid, with a marked crosswalk (region 30, x ∈ [-2, 2]) across the roadway.
  branch_2: an unlaned one-way roadway carrying direction east, crossed diagonally (roadway carrier).
  branch_3: a laned two-way roadway (lanes east / west, roadway carrying no direction), crossed
            diagonally (lane carrier decides).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_050
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_050

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (cm 30, cm 30, cm 90)
def walk : Q := Units.ratio 7 5   -- 1.4 m/s

/-- 36.9° off the perpendicular to an east–west carrier. -/
def diagonal : Vec := (Units.ratio 3 5, Units.ratio 4 5)
/-- 5.5° off the perpendicular to an east–west carrier. -/
def square : Vec := (Units.ratio 21 221, Units.ratio 220 221)

def inLane : Vec := (m 0, cm 250)

def roadwayWith (dir : Option Vec) : Structure :=
  { Build.rect 10 .roadway (m (-50)) (m 0) (m 50) (m 10) with lane := some { direction := dir } }

def lane11 : Structure :=
  Build.lane 11 [(m (-50), m 0), (m 50, m 0), (m 50, m 5), (m (-50), m 5)] Build.east
def lane12 (dir : Vec) : Structure :=
  Build.lane 12 [(m (-50), m 5), (m 50, m 5), (m 50, m 10), (m (-50), m 10)] dir
def sidewalk : Structure := Build.rect 20 .sidewalk (m (-50)) (m 10) (m 50) (m 13)
def crosswalk : Structure :=
  { Build.rect 30 .crosswalk (m (-2)) (m 0) (m 2) (m 10) with marked := some true }

def oneWayLaned : List Structure := [roadwayWith (some Build.east), lane11, lane12 Build.east, sidewalk]

def ped (pos : Vec) (h : Vec) : RoadUser := Build.user 1 [.pedestrian] pos h walk body

/-- `forbid` (violated): A pedestrian crosses a laned roadway mid-block, away from any crosswalk, walking at 1.4 m/s at 40 degrees off perpendicular to the lane direction. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ ped inLane diagonal ] oneWayLaned [ ]

/-- `permit` (compliant): A pedestrian crosses the same roadway mid-block walking at 1.4 m/s at 5 degrees off perpendicular to the lane direction. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ ped inLane square ] oneWayLaned [ ]

/-- `idle` (not_applicable): A pedestrian walks along the sidewalk and never occupies the roadway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ ped (m 0, cm 1150) Build.east ] oneWayLaned [ ]

/-- `blind` (unknown): A pedestrian occupies the roadway mid-block, but its velocity is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ ped inLane diagonal ] oneWayLaned [ ]

/-- `branch_1` (not_applicable): A pedestrian crosses diagonally at 40 degrees off perpendicular inside a marked crosswalk. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ ped inLane diagonal ] (oneWayLaned ++ [crosswalk]) [ ]

/-- `branch_2` (violated): A pedestrian crosses an unlaned one-way roadway diagonally, mid-block. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ ped inLane diagonal ] [roadwayWith (some Build.east), sidewalk] [ ]

/-- `branch_3` (violated): A pedestrian crosses a laned two-way roadway (no roadway direction) diagonally, mid-block. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ ped inLane diagonal ]
      [roadwayWith none, lane11, lane12 Build.west, sidewalk] [ ]

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
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.LVMC_11_30_050
