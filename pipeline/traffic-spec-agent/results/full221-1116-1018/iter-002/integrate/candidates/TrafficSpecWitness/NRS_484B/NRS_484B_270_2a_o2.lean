/-
  Witnesses for NRS_484B_270_2a_o2.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - A straight carriageway heading east. With two lanes in that direction: lane 1 (right,
    ordinal 2 of 2, left neighbour lane 2) is y ∈ [0, 3.5] m, lane 2 (left, ordinal 1 of 2, no left
    neighbour) is y ∈ [3.5, 7] m. With one lane: lane 1 alone (ordinal 1 of 1), y ∈ [0, 3.5] m.
    Both run x ∈ [-100, 400] m.
  - Subject (track 1), a car, half-extents 2.5 m × 1 m, at 10 m/s east, x = 10·k m at t = k s; in
    the right lane at y = 2.2 m (body y ∈ [1.2, 3.2]), in the left lane at y = 5.25 m.
  - Rider (track 2), a bicycle (idle: a moped), half-extents 1 m × 0.3 m, at 5 m/s east,
    x = 75 + 5·k m, y = 0.8 m in the right lane (y = 4.3 m in the left lane in branch_3).
    Relative position 75 − 5·k: ahead with no shared length up to k = 14 (5 m), side by side at
    k = 15 (overlap 3.5 m), behind from k = 16, at which the pass is recognized; the pass's start
    is k = 14. The window behind (10 s) at k = 16 reaches back to k = 6, inside the trace.
  - Other car (track 3), 10 m/s east in the left lane, beside the subject (branch_1, gap 1.05 m,
    under 10 m/s × 2 s = 20 m) or 30 m ahead (body gap about 25 m: above 20, below 10 × 3 = 30)
    or 50 m ahead (about 45 m: above 30, below 10 × 6 = 60).
  - 20 observations, one per second; each witness judges t ∈ [10, 19] s, where every window
    behind is covered.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_2a_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_2a_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def dry : Env := { iceOrSnow := some false, wetRoad := some false, precipitation := some false }
def wet : Env := { dry with wetRoad := some true }
def rain : Env := { dry with precipitation := some true }
def icy : Env := { dry with iceOrSnow := some true }

def laneRight : Structure :=
  Build.lane 1 [(m (-100), m 0), (m 400, m 0), (m 400, cm 350), (m (-100), cm 350)] Build.east
    (some 2) none (some 2) (some 2)
def laneLeft : Structure :=
  Build.lane 2 [(m (-100), cm 350), (m 400, cm 350), (m 400, m 7), (m (-100), m 7)] Build.east
    none (some 1) (some 1) (some 2)
def laneSingle : Structure :=
  Build.lane 1 [(m (-100), m 0), (m 400, m 0), (m 400, cm 350), (m (-100), cm 350)] Build.east
    none none (some 1) (some 1)

def carExtent : Q × Q × Q := (cm 250, m 1, cm 80)
def riderExtent : Q × Q × Q := (m 1, cm 30, cm 80)

/-- One observation: k seconds in. -/
def sceneAt (k : Nat) (t : Timestamp)
    (riderClasses : List RoadUserClass := [.bicycle]) (riderSpeed : Int := 5)
    (riderY : Q := cm 80) (subjectY : Nat → Q := fun _ => cm 220)
    (twoLanes : Bool := true) (other : Option Int := none) (ttc : Bool := false)
    (env : Env := dry) : Scene :=
  let ki : Int := Int.ofNat k
  let subject := Build.user 1 [.motorVehicle] (m (10 * ki), subjectY k) Build.east
    (Units.metresPerSecond 10) carExtent
  let rider := Build.user 2 riderClasses (m (75 + riderSpeed * ki), riderY) Build.east
    (Units.metresPerSecond riderSpeed) riderExtent
  let others := match other with
    | some dx => [Build.user 3 [.motorVehicle] (m (10 * ki + dx), cm 525) Build.east
        (Units.metresPerSecond 10) carExtent]
    | none => []
  let lanes := if twoLanes then [laneRight, laneLeft] else [laneSingle]
  let devices := if ttc then [Build.device 10 .temporaryTrafficControl [2] (some (m 100, cm 525))] else []
  Build.scene t (some 1) ([subject, rider] ++ others) lanes devices (env := env)

def run (f : Nat → Timestamp → Scene) : Trace := Build.trace 20 0 (Units.seconds 1) f

/-- `forbid` (violated): Dry road with two lanes in one direction; a bicycle rides in the right lane; the left lane is open and empty. The subject car overtakes the bicycle staying in the right lane, side by side with it. -/
def forbidTrace : Trace := run fun k t => sceneAt k t

/-- `permit` (compliant): Same scene; the subject car moves wholly into the left lane before drawing alongside and stays there until the bicycle is behind it. -/
def permitTrace : Trace :=
  run fun k t => sceneAt k t (subjectY := fun k => if k < 9 then cm 220 else cm 525)

/-- `idle` (not_applicable): The subject car overtakes another car on a two-lane carriageway; no bicycle, electric bicycle or electric scooter is in the scene. The duty binds the subject alone.
    The overtaken vehicle is a moped: a car's membership of the electric-bicycle and
    electric-scooter aggregates is unresolved in the run's reading, a moped's is decided false. -/
def idleTrace : Trace := run fun k t => sceneAt k t (riderClasses := [.moped])

/-- `blind` (unknown): As in forbid, but the source does not observe lane adjacency, so neither the lane count nor the left neighbour is known. -/
def blindTrace : Trace := run fun k t => sceneAt k t

/-- `branch_1` (compliant): As in forbid, but at the pass's start a car occupies the left lane beside the subject, nearer than the subject's speed times the dry headway: the lane is not reasonably safe and the subject passes in the right lane. -/
def branch_1Trace : Trace := run fun k t => sceneAt k t (other := some 0)

/-- `branch_2` (not_applicable): The road has a single lane in the subject's direction; the subject passes a bicycle. -/
def branch_2Trace : Trace := run fun k t => sceneAt k t (twoLanes := false)

/-- `branch_3` (compliant): two lanes, the bicycle rides in the left lane, which has no lane to its
    left; the subject passes it in that lane. -/
def branch_3Trace : Trace :=
  run fun k t => sceneAt k t (riderY := cm 430) (subjectY := fun _ => cm 590)

/-- `branch_4` (compliant): as forbid, but temporary traffic control governs the left lane. -/
def branch_4Trace : Trace := run fun k t => sceneAt k t (ttc := true)

/-- `branch_5` (compliant): as forbid on a wet road; a car 30 m ahead in the left lane is beyond
    the dry headway but within the wet one. -/
def branch_5Trace : Trace := run fun k t => sceneAt k t (other := some 30) (env := wet)

/-- `branch_6` (compliant): as branch_5, the road dry but rain falling. -/
def branch_6Trace : Trace := run fun k t => sceneAt k t (other := some 30) (env := rain)

/-- `branch_7` (compliant): as forbid on ice; a car 50 m ahead in the left lane is beyond the wet
    headway but within the icy one. -/
def branch_7Trace : Trace := run fun k t => sceneAt k t (other := some 50) (env := icy)

/-- `branch_8` (violated): dry road, a car 30 m ahead in the left lane beyond the dry headway: the
    lane is safe and the subject stays in the right lane alongside the bicycle. -/
def branch_8Trace : Trace := run fun k t => sceneAt k t (other := some 30)

/-- `branch_9` (not_applicable): the bicycle stands still in the right lane; the subject passes it. -/
def branch_9Trace : Trace := run fun k t => sceneAt k t (riderSpeed := 0)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_2a_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (10000, 19000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_270_2a_o2
