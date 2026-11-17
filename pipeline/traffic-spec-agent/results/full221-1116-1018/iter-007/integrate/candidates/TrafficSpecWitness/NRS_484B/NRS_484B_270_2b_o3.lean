/-
  Witnesses for NRS_484B_270_2b_o3.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
  - A two-lane two-way road along x, from x = -100 m to x = 300 m. Lane 10 (y 0..4 m) carries
    traffic east and is the only lane in that direction (count 1); lane 11 (y 4..8 m) carries
    traffic west (count 1). `branch_2` instead has two eastbound lanes, 21 (y 4..8, ordinal 1) and
    20 (y 0..4, ordinal 2), each with count 2.
  - The subject car (track 1, motor vehicle, 5 m × 2 m) runs at y = 5.5 m (in lane 11, having moved
    out left) at 10 m/s, x = 10·k m at instant k (one second apart). "Steering back right" is its
    heading turned to (0.99, -0.14), about 8° right of east (sine 0.14, against the 0.035 tolerance).
  - The bicycle (track 2, 2 m × 0.6 m) rides east at y = 1.5 m in lane 10 at 5 m/s,
    x = 20 + 5·k m. It is ahead of the car with the projections apart at k = 0..3, side by side at
    k = 4, behind at k ≥ 5 (pass recognized at k = 5). Body gaps after the pass, about:
    k = 5: 3.4 m (car turned) / 1.5 m longitudinal; k = 7: 11.8 m; k = 8: 16.7 m; k = 10: 26.6 m.
    At the bicycle's 5 m/s the required gaps are 10 m (dry, 2 s), 15 m (wet, 3 s), 30 m (ice, 6 s).
  - Surfaces are observed dry unless a branch says otherwise.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_2b_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_2b_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The car's heading when it steers back right: about 8° clockwise of east. -/
def rightTurned : Vec := (Units.ratio 99 100, Units.ratio (-14) 100)

def strip (y0 y1 : Int) : List Vec := [(m (-100), m y0), (m 300, m y0), (m 300, m y1), (m (-100), m y1)]

/-- One lane east (lane 10), one lane west (lane 11). -/
def oneLaneRoad : List Structure :=
  [ Build.lane 10 (strip 0 4) Build.east (ordinal := some 1) (count := some 1)
  , Build.lane 11 (strip 4 8) Build.west (ordinal := some 1) (count := some 1) ]

/-- Two lanes east: lane 21 (left, y 4..8) and lane 20 (right, y 0..4). -/
def twoLaneRoad : List Structure :=
  [ Build.lane 20 (strip 0 4) Build.east (left := some 21) (ordinal := some 2) (count := some 2)
  , Build.lane 21 (strip 4 8) Build.east (right := some 20) (ordinal := some 1) (count := some 2) ]

def dry : Env := { precipitation := some false, wetRoad := some false, iceOrSnow := some false }
def wet : Env := { dry with wetRoad := some true }
def raining : Env := { dry with precipitation := some true }
def icy : Env := { dry with iceOrSnow := some true }

def car (k : Nat) (turned : Bool) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (10 * (k : Int)), cm 550)
    (if turned then rightTurned else Build.east) (Units.metresPerSecond 10) (cm 250, m 1, cm 75)

def bike (k : Nat) : RoadUser :=
  Build.user 2 [.bicycle] (m (20 + 5 * (k : Int)), cm 150) Build.east (Units.metresPerSecond 5) (m 1, cm 30, m 1)

/-- The pass: n instants one second apart, the car turned right at instant `turnAt`. -/
def passTrace (n turnAt : Nat) (road : List Structure) (env : Env) : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k (k == turnAt), bike k] road [] (env := env)

/-- `forbid` (violated): Road with one lane in the subject's direction; the subject car moves out left and overtakes a bicycle; while the bicycle is still beside it, the subject car steers back to the right, its heading turning right of the lane's direction beyond the course tolerance. -/
def forbidTrace : Trace := passTrace 5 4 oneLaneRoad dry

/-- `permit` (compliant): Same pass; the subject car keeps its course until the bicycle is behind it at a gap above the bicycle's speed times the dry headway, then steers back right. -/
def permitTrace : Trace := passTrace 9 8 oneLaneRoad dry

/-- `idle` (not_applicable): The subject car drives alone on a road with one lane in its direction and steers to the right; no other road user is in the scene, so no bicycle, electric bicycle or electric scooter is being overtaken. The duty binds the subject alone. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k (k == 2)] oneLaneRoad [] (env := dry)

/-- `blind` (unknown): As in forbid, but the source does not observe the lanes' designated direction of travel, so whether the subject's heading turned right of the rider's lane is unknown while the rider, still beside it, is decided not clear. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): The subject car completes the pass of a bicycle on a road with one lane in its direction and steers back right at once, as the pass is recognized, the bicycle behind it at a gap below its speed times the dry headway. -/
def branch_1Trace : Trace := passTrace 6 5 oneLaneRoad dry

/-- `branch_2` (not_applicable): The road has two lanes in the subject's direction; the subject passes a bicycle and steers back right while beside it. -/
def branch_2Trace : Trace := passTrace 5 4 twoLaneRoad dry

/-- `branch_3` (violated): wet road; the car steers back right with the bicycle behind at about
    11.8 m, clear of the dry headway (10 m) but not the wet one (15 m). -/
def branch_3Trace : Trace := passTrace 8 7 oneLaneRoad wet

/-- `branch_4` (violated): rain falling on an otherwise unwet reading; as branch_3. -/
def branch_4Trace : Trace := passTrace 8 7 oneLaneRoad raining

/-- `branch_5` (violated): icy road; the car steers back right with the bicycle behind at about
    26.6 m, clear of the wet headway (15 m) but not the ice one (30 m). -/
def branch_5Trace : Trace := passTrace 11 10 oneLaneRoad icy

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_2b_o3"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_270_2b_o3
