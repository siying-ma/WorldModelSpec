/-
  Witnesses for LVMC_11_30_070_B.

  Geometry (world frame, +x east, +y north; figures are the witness's own):
    - roadway 1: x ∈ [-50, 50] m, y ∈ [0, 8] m; in the two-way scenes it carries no direction of its
      own, its lanes do: lane 2 (y ∈ [0, 4], eastbound) and lane 3 (y ∈ [4, 8], westbound).
    - sidewalk 4: y ∈ [8, 11] m along the roadway.
    - crosswalk 5: x ∈ [18, 22] m across the roadway (marked in `permit`, unmarked in `branch_1`,
      where intersection 6, x ∈ [10, 30] m, is also built).
    - the pedestrian (track 1, half-extent 0.25 × 0.25 × 0.85 m) at x = 20 m walks north at 1.4 m/s
      from y = 0.5 m (0.5, 1.9, 3.3 m at t = 0, 1, 2 s): at right angles to its lane's direction
      (|cos| = 0, far below 0.94; 1.4 m/s far above 0.1 m/s).
    - branch_3: a roadway carrying a direction itself (east) and no lane: the roadway limb of s2.
    - branch_4: the pedestrian walks east along the eastbound lane at y = 2 m (|cos| = 1 > 0.94):
      no crossing.
  No look-back operator: no window is needed.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_070_B
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_070_B

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def roadway : Structure := Build.rect 1 .roadway (m (-50)) (m 0) (m 50) (m 8)
def roadwayDirected : Structure :=
  { roadway with lane := some { direction := some Build.east } }
def laneEast : Structure := Build.lane 2 (box (m (-50)) (m 0) (m 50) (m 4)) Build.east
def laneWest : Structure := Build.lane 3 (box (m (-50)) (m 4) (m 50) (m 8)) Build.west
def sidewalk : Structure := Build.rect 4 .sidewalk (m (-50)) (m 8) (m 50) (m 11)
def crosswalk (marked : Bool) : Structure :=
  { Build.rect 5 .crosswalk (m 18) (m 0) (m 22) (m 8) with marked := some marked }
def intersection : Structure := Build.rect 6 .intersection (m 10) (m (-3)) (m 30) (m 11)

def ext : Q × Q × Q := (cm 25, cm 25, cm 85)

/-- The pedestrian crossing northward at x = 20 m. -/
def crosser (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (m 20, cm (50 + 140 * (k : Int))) Build.north (cm 140) ext

def bd (v : Bool) : List (AsmId × Bool) := [("asm.business_district", v)]

/-- `forbid` (violated): A pedestrian (ru.pedestrian) moves at 1.4 m/s across a lane at right angles to the lane's st.lane_direction, footprint on the roadway and on no st.crosswalk, at a place declared asm.business_district true. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ crosser k ]
      [ roadway, laneEast, laneWest, sidewalk ]
      [ ]
      (assumptions := bd true)

/-- `permit` (compliant): The same pedestrian crosses the same roadway with its footprint inside a st.crosswalk with marked true at every observation of the crossing, in a business district. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ crosser k ]
      [ roadway, laneEast, laneWest, sidewalk, crosswalk true ]
      [ ]
      (assumptions := bd true)

/-- `idle` (not_applicable): A pedestrian walks on a st.sidewalk and occupies no roadway, in a business district. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (cm (140 * (k : Int)), cm 950) Build.east (cm 140) ext ]
      [ roadway, laneEast, laneWest, sidewalk ]
      [ ]
      (assumptions := bd true)

/-- `blind` (unknown): A pedestrian is on the roadway outside any crosswalk in a business district; the source does not observe kin.velocity, so whether it moves across the lane is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ crosser k ]
      [ roadway, laneEast, laneWest, sidewalk ]
      [ ]
      (assumptions := bd true)

/-- `branch_1` (compliant): The pedestrian crosses within an unmarked crosswalk (st.crosswalk with marked false) at an intersection, in a business district. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ crosser k ]
      [ roadway, laneEast, laneWest, sidewalk, intersection, crosswalk false ]
      [ ]
      (assumptions := bd true)

/-- `branch_2` (not_applicable): The pedestrian crosses mid-block outside any crosswalk at a place declared asm.business_district false. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ crosser k ]
      [ roadway, laneEast, laneWest, sidewalk ]
      [ ]
      (assumptions := bd false)

/-- `branch_3` (violated): the pedestrian crosses, outside any crosswalk in a business district, a
    roadway that carries a designated direction itself and has no lane built: the roadway limb of s2. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ crosser k ]
      [ roadwayDirected, sidewalk ]
      [ ]
      (assumptions := bd true)

/-- `branch_4` (compliant): the pedestrian walks east along the eastbound lane of a roadway directed
    east, outside any crosswalk in a business district: moving along is no crossing. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (cm (2000 + 140 * (k : Int)), m 2) Build.east (cm 140) ext ]
      [ roadwayDirected, laneEast, sidewalk ]
      [ ]
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
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.LVMC_11_30_070_B
