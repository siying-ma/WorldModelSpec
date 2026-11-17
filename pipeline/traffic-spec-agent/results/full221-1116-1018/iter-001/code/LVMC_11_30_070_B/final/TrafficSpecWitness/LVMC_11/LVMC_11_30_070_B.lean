/-
  Witnesses for LVMC_11_30_070_B.

  Geometry (the witness's own figures, none of them in the rule):
  - roadway 10: x ∈ [-50, 50] m, y ∈ [0, 7] m, two-way, no designated direction of its own;
    lane 11 eastbound (y ∈ [0, 3.5]), lane 12 westbound (y ∈ [3.5, 7]);
    sidewalk 13: y ∈ [-3, 0].
  - crosswalk 14: x ∈ [-2, 2] across the whole roadway (permit: marked; branch_1: unmarked, at an
    intersection 15); in forbid / blind / branch_2 the crosswalk lies at x ∈ [30, 34], away from
    the pedestrian.
  - pedestrian 1 (half-extent 0.25 × 0.25 × 0.9 m) walks north at 1.4 m/s from (0, 1.0) through
    (0, 2.4) to (0, 3.8), instants 0, 1, 2 s: at right angles to both lanes' directions
    (cosine 0 against the reading's 0.94, speed 1.4 against the 0.1 m/s tolerance).
  - idle: the pedestrian walks east along the sidewalk at (−2 … 0.8, −1.5), on no roadway.
  - branch_3: an unlaned one-way roadway carrying the eastbound direction itself; the pedestrian
    crosses it outside any crosswalk → violated (exercises the roadway-carrier disjunct).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_070_B
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_070_B

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def walkSpeed : Q := Q.mk' 7 5   -- 1.4 m/s
def pedExtent : Q × Q × Q := (cm 25, cm 25, cm 90)

/-- The pedestrian crossing northwards at instant k. -/
def crosser (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (m 0, cm (100 + 140 * (k : Int))) Build.north walkSpeed pedExtent

def roadway : Structure := Build.rect 10 .roadway (m (-50)) (m 0) (m 50) (m 7)
def laneEast : Structure :=
  Build.lane 11 [(m (-50), m 0), (m 50, m 0), (m 50, cm 350), (m (-50), cm 350)] Build.east
def laneWest : Structure :=
  Build.lane 12 [(m (-50), cm 350), (m 50, cm 350), (m 50, m 7), (m (-50), m 7)] Build.west
def sidewalk : Structure := Build.rect 13 .sidewalk (m (-50)) (m (-3)) (m 50) (m 0)
def crosswalkHere (marked : Bool) : Structure :=
  { Build.rect 14 .crosswalk (m (-2)) (m 0) (m 2) (m 7) with marked := some marked }
def crosswalkAway : Structure :=
  { Build.rect 14 .crosswalk (m 30) (m 0) (m 34) (m 7) with marked := some true }
def intersection : Structure := Build.rect 15 .intersection (m (-2)) (m 0) (m 2) (m 7)

def street : List Structure := [roadway, laneEast, laneWest, sidewalk]

def bd (v : Bool) : List (AsmId × Bool) := [("asm.business_district", v)]

/-- `forbid` (violated): A pedestrian (ru.pedestrian) moves at 1.4 m/s across a lane at right angles to the lane's st.lane_direction, footprint on the roadway and on no st.crosswalk, at a place declared asm.business_district true. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [crosser k] (street ++ [crosswalkAway]) []
      (assumptions := bd true)

/-- `permit` (compliant): The same pedestrian crosses the same roadway with its footprint inside a st.crosswalk with marked true at every observation of the crossing, in a business district. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [crosser k] (street ++ [crosswalkHere true]) []
      (assumptions := bd true)

/-- `idle` (not_applicable): A pedestrian walks on a st.sidewalk and occupies no roadway, in a business district. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [Build.user 1 [.pedestrian] (cm (-200 + 140 * (k : Int)), cm (-150)) Build.east walkSpeed pedExtent]
      (street ++ [crosswalkHere true]) []
      (assumptions := bd true)

/-- `blind` (unknown): A pedestrian is on the roadway outside any crosswalk in a business district; the source does not observe kin.velocity, so whether it moves across the lane is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [crosser k] (street ++ [crosswalkAway]) []
      (assumptions := bd true)

/-- `branch_1` (compliant): The pedestrian crosses within an unmarked crosswalk (st.crosswalk with marked false) at an intersection, in a business district. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [crosser k] (street ++ [intersection, crosswalkHere false]) []
      (assumptions := bd true)

/-- `branch_2` (not_applicable): The pedestrian crosses mid-block outside any crosswalk at a place declared asm.business_district false. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [crosser k] (street ++ [crosswalkAway]) []
      (assumptions := bd false)

/-- `branch_3` (violated): an unlaned one-way roadway carries the eastbound direction itself; the
    pedestrian crosses it outside any crosswalk in a business district. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [crosser k]
      [ { roadway with lane := some { direction := some Build.east } }, sidewalk, crosswalkAway ] []
      (assumptions := bd true)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_30_070_B"
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
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.LVMC_11_30_070_B
