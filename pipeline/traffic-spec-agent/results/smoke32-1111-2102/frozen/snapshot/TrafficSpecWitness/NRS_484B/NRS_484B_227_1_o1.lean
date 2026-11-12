/-
  Witnesses for NRS_484B_227_1_o1.

  A divided highway runs east–west: the highway region 1 spans y ∈ [-12, 12] (x ∈ [-200, 200]);
  roadway 2 (y ∈ [-10, -1]) is the right-hand roadway for eastbound traffic, roadway 3
  (y ∈ [1, 10]) the left-hand one; median 4 (y ∈ [-1, 1]) separates them. Roadways and median lie
  on highway 1. Ego (track 1) is a motor vehicle, 4 m × 2 m, at 15 m/s, observed at three
  instants one second apart at a fixed position.
  - forbid: ego eastbound at (0, 5) on roadway 3: the median's nearest edge (y = 1) lies 4 m to
    its right (offset -4 m).
  - permit: ego eastbound at (0, -5) on roadway 2: the median lies 4 m to its left (+4 m).
  - idle: one undivided roadway y ∈ [-10, 10] on the highway, no median.
  - blind: forbid's scene with rel.occupies absent.
  - branch_1: ego northbound at (0, 0), across roadway 2 and the median, whose opening is set.
  - branch_2: ego eastbound at (60, 5) on roadway 3 inside intersection 5 (x ∈ [50, 70]).
  - branch_3: branch_1 with the median closed (no opening): its offset is zero, a violation.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: ego ↦ 1

def ego (x y : Int) (heading : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) heading (Units.metresPerSecond 15) (m 2, m 1, m 1)

def highway : Structure := Build.rect 1 .highway (m (-200)) (m (-12)) (m 200) (m 12)
def roadwayRight : Structure :=
  { Build.rect 2 .roadway (m (-200)) (m (-10)) (m 200) (m (-1)) with ways := some [1] }
def roadwayLeft : Structure :=
  { Build.rect 3 .roadway (m (-200)) (m 1) (m 200) (m 10) with ways := some [1] }
def median (opening : Bool) : Structure :=
  { Build.rect 4 .medianOrDivider (m (-200)) (m (-1)) (m 200) (m 1) with
      ways := some [1], opening := some opening }
def intersection : Structure :=
  { Build.rect 5 .intersection (m 50) (m (-12)) (m 70) (m 12) with ways := some [1] }

def divided : List Structure := [highway, roadwayRight, roadwayLeft, median false]

/-- `forbid` (violated): Ego travels on the left-hand roadway of a divided highway: the median of the highway lies to ego's right (negative lateral offset). -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ego 0 5 Build.east ]
      divided
      [ ]

/-- `permit` (compliant): Ego travels on the right-hand roadway: the median lies to ego's left. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ego 0 (-5) Build.east ]
      divided
      [ ]

/-- `idle` (not_applicable): Ego travels on a two-way road whose highway carries no median or divider. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ego 0 (-5) Build.east ]
      [ highway
      , { Build.rect 2 .roadway (m (-200)) (m (-10)) (m 200) (m 10) with ways := some [1] } ]
      [ ]

/-- `blind` (unknown): Scene of forbid, but the source declares rel.occupies absent: which roadway ego is on cannot be read. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): Ego crosses the highway through a median opening; at the observation judged its footprint overlaps the median region with the opening attribute set. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ego 0 0 Build.north ]
      [ highway, roadwayRight, roadwayLeft, median true ]
      [ ]
      (occupies := some [(1, 1), (1, 2), (1, 4)])

/-- `branch_2` (not_applicable): ego on the left-hand roadway inside an intersection lying on the
    divided highway (d8). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ego 60 5 Build.east ]
      (divided ++ [intersection])
      [ ]

/-- `branch_3` (violated): ego across the right-hand roadway and a median with no opening: the
    median is not to its left (offset zero). -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ego 0 0 Build.north ]
      divided
      [ ]
      (occupies := some [(1, 1), (1, 2), (1, 4)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_227_1_o1
