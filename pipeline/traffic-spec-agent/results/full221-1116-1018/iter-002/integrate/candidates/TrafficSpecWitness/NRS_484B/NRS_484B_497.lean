/-
  Witnesses for NRS_484B_497.

  Geometry (all figures the witness's own): a highway (10) x ∈ [0, 1000] m, y ∈ [-3, 10] m; on it a
  roadway (20) y ∈ [0, 7] — one-way eastbound in every witness but `idle`, where it is a two-way
  roadway — with two lanes, 21 (y ∈ [0, 3.5]) and 22 (y ∈ [3.5, 7]); road edges 30 (south curb,
  y ∈ [-0.5, 0]) and 31 (north curb, y ∈ [7, 7.5]). Heading east, the north curb is on the left of
  the roadway's direction. The car (track 1, a motor vehicle, 4 m × 2 m) stands at (500, 5.5):
  1.5 m right of the north curb's near side (offset +1.5) and 5.5 m from the south curb (offset
  −5.5), so the north curb is nearest by a 4 m margin; in `permit` it stands at (500, 1.5), the
  south curb nearest (−1.5 against +5.5).

  Time: scenes every 10 s from 0 s; the standing duration p.standing_min_duration is 60 s, so each
  witness judges only the instants from 70 s on, whose 60 s look-back lies inside the trace. At rest
  the speed is 0 (tolerance 0.1 m/s); moving, 5 m/s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_497
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_497

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def highway : Structure := Build.rect 10 .highway (m 0) (m (-3)) (m 1000) (m 10)

/-- The one-way roadway, eastbound. -/
def oneWay : Structure :=
  { Build.rect 20 .oneWayRoadway (m 0) (m 0) (m 1000) (m 7) with
      lane := some { direction := some Build.east }, ways := some [10] }

/-- The two-way roadway of `idle`: no designated single direction. -/
def twoWay : Structure :=
  { Build.rect 20 .roadway (m 0) (m 0) (m 1000) (m 7) with ways := some [10] }

def laneS (dir : Vec) : Structure :=
  { Build.lane 21 (box (m 0) (m 0) (m 1000) (cm 350)) dir with ways := some [10] }
def laneN (dir : Vec) : Structure :=
  { Build.lane 22 (box (m 0) (cm 350) (m 1000) (m 7)) dir with ways := some [10] }

def edgeS : Structure := { Build.rect 30 .roadEdge (m 0) (cm (-50)) (m 1000) (m 0) with ways := some [10] }
def edgeN : Structure := { Build.rect 31 .roadEdge (m 0) (m 7) (m 1000) (cm 750) with ways := some [10] }

def oneWayStructures : List Structure :=
  [highway, oneWay, laneS Build.east, laneN Build.east, edgeS, edgeN]

def car (x y : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) Build.east speed (m 2, m 1, cm 75)

def atRest : Q := Units.metresPerSecond 0
def moving : Q := Units.metresPerSecond 5

/-- `forbid` (violated): A car is at rest, for longer than the standing duration, against the left curb of a one-way roadway of two lanes, heading along the roadway's direction; the nearest road edge lies to its left; it overlaps no parking bay and no angle-parking or parking-restricted sign governs the roadway. -/
def forbidTrace : Trace :=
  Build.trace 10 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [car (m 500) (cm 550) atRest] oneWayStructures []

/-- `permit` (compliant): The same car is at rest for as long against the right curb of the same one-way roadway: the nearest road edge lies to the right of the roadway's direction. -/
def permitTrace : Trace :=
  Build.trace 10 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [car (m 500) (cm 150) atRest] oneWayStructures []

/-- `idle` (not_applicable): The car is at rest against a left curb of a two-way roadway (st.roadway that is not one-way): no one-way roadway is occupied. -/
def idleTrace : Trace :=
  Build.trace 10 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [car (m 500) (cm 550) atRest]
      [highway, twoWay, laneS Build.east, laneN Build.west, edgeS, edgeN] []

/-- `blind` (unknown): As in forbid, but the source does not observe the roadway's designated direction, so which edge lies on the left-hand side is unknown. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["st.lane_direction"]) forbidTrace

/-- `branch_1` (compliant): The car is at rest at the left curb of the one-way roadway inside a marked parking bay. -/
def branch_1Trace : Trace :=
  Build.trace 10 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [car (m 500) (cm 550) atRest]
      (oneWayStructures ++
        [{ Build.rect 40 .parkingSpace (m 490) (m 4) (m 510) (m 7) with ways := some [10] }]) []

/-- `branch_2` (compliant): The car halts at the left curb only for a moment shorter than the standing duration and moves off: it is not standing. Moving until 70 s, at rest at 80–100 s, moving again from 110 s. -/
def branch_2Trace : Trace :=
  Build.trace 16 0 (Units.seconds 10) fun k t =>
    let x : Q :=
      if k ≤ 8 then m (50 + 50 * (k : Int))
      else if k ≤ 10 then m 450
      else m (450 + 50 * ((k : Int) - 10))
    let v : Q := if 8 ≤ k ∧ k ≤ 10 then atRest else moving
    Build.scene t (some 1) [car x (cm 550) v] oneWayStructures []

/-- `branch_3` (compliant): As in forbid, but an angle-parking regulatory sign with an unrestricted legend governs the one-way roadway. -/
def branch_3Trace : Trace :=
  Build.trace 10 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [car (m 500) (cm 550) atRest] oneWayStructures
      [{ Build.sign 50 .regulatorySign [20] with code := some .angleParking, conditions := some {} }]

/-- `branch_4` (compliant): As in forbid, but a parking-restricted zone sign with an unrestricted legend governs the one-way roadway. -/
def branch_4Trace : Trace :=
  Build.trace 10 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [car (m 500) (cm 550) atRest] oneWayStructures
      [Build.zoneSign 51 [20] .parkingRestricted false (some {})]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (70000, 90000)) : Scenario :=
  { name := name
    rule := "NRS_484B_497"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant (window := some (70000, 150000))
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_484B_497
