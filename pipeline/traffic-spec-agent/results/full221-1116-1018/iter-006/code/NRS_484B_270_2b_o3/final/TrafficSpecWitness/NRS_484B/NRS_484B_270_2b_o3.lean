/-
  Witnesses for NRS_484B_270_2b_o3.

  Geometry (the witness's own figures; none appears in the rule). +x east, +y north.
  - One-lane road: lane 10 (y 0 … 4) carries eastbound traffic, one lane in its direction; lane
    11 (y 4 … 8) carries westbound traffic, one lane in its direction. `branch_2` replaces them by
    two eastbound lanes: 12 (left, y 4 … 8, ordinal 1) and 10 (right, y 0 … 4, ordinal 2), count 2.
  - Subject (track 1, motor vehicle, half-extents 2.5 × 1 m) drives at 10 m/s along y = 6, already
    moved out to the left of the rider, at x = 10·k at instant k (one observation a second).
    Its heading is east until it steers back right: heading (10, −1), about 5.7° clockwise of the
    lane's direction (sine about 0.0995, well above the course tolerance 0.035).
  - Overtaken road user (track 2) at 5 m/s east along y = 1 (a car in `idle`: y = 2), starting x0
    metres ahead of the subject, so its offset is x0 − 5·k. Rider half-extents 1 × 0.3 m.
      forbid / blind / branch_2: x0 = 18 — ahead at k 0 … 2, beside at k 3, 4; steer right at k 4.
      permit: x0 = 20 — ahead at k 0 … 3, beside at k 4, behind from k 5 (pass recognised at k 5);
        steer right at k 7, the rider 15 m behind: body gap about 12.1 m, above 5 m/s × 2 s = 10 m
        (dry) and below 5 m/s × 3 s = 15 m (wet), so the surface leaves decide it.
      branch_1: x0 = 20, an electric scooter; steer right at k 5, as the pass completes: body gap
        about 4.2 m, below 10 m.
  - Environment observed dry: no ice or snow, no wet road, no precipitation.
  - blind: the forbid trace; the manifest masks kin.heading.
  - Known plan defects (see task_result.md): `idle` and `branch_1` cannot reach their planned
    verdicts under the run's reading (a car is an unresolved class of the electric-bicycle and
    electric-scooter aggregates; an electric scooter is an unresolved class of its own aggregate),
    and `blind` with kin.heading masked leaves the selection unknown through rel.bearing,
    rel.same_direction and rel.longitudinal_overlap, which the gate counts as unmasked atoms.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_2b_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_2b_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def env0 : Env := { iceOrSnow := some false, wetRoad := some false, precipitation := some false }

def box (y0 y1 : Int) : List Vec := [(m (-200), m y0), (m 400, m y0), (m 400, m y1), (m (-200), m y1)]

/-- One-lane road: one eastbound lane, one westbound lane. -/
def oneLaneRoad : List Structure :=
  [ Build.lane 10 (box 0 4) Build.east none none (some 1) (some 1)
  , Build.lane 11 (box 4 8) Build.west none none (some 1) (some 1) ]

/-- Two eastbound lanes. -/
def twoLaneRoad : List Structure :=
  [ Build.lane 10 (box 0 4) Build.east (some 12) none (some 2) (some 2)
  , Build.lane 12 (box 4 8) Build.east none (some 10) (some 1) (some 2) ]

def carHalf : Q × Q × Q := (cm 250, m 1, m 1)
def riderHalf : Q × Q × Q := (m 1, cm 30, m 1)
def steerRight : Vec := (m 10, m (-1))

def subjectAt (k : Nat) (steer : Bool) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 6) (if steer then steerRight else Build.east)
    (Units.metresPerSecond 10) carHalf

/-- A pass: `n` instants a second apart; the overtaken user of class `cls` starts `x0` m ahead on
    `y0`; the subject steers right from instant `steerFrom`. -/
def passScene (cls : RoadUserClass) (half : Q × Q × Q) (y0 x0 : Int) (steerFrom : Nat)
    (structs : List Structure) (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1)
    [ subjectAt k (decide (steerFrom ≤ k))
    , Build.user 2 [cls] (m (x0 + 5 * (k : Int)), m y0) Build.east (Units.metresPerSecond 5) half ]
    structs [] (env := env0)

def passTrace (n : Nat) (cls : RoadUserClass) (half : Q × Q × Q) (y0 x0 : Int) (steerFrom : Nat)
    (structs : List Structure) : Trace :=
  Build.trace n 0 (Units.seconds 1) (passScene cls half y0 x0 steerFrom structs)

/-- `forbid` (violated): Road with one lane in the subject's direction; the subject car moves out left and overtakes a bicycle; while the bicycle is still beside it, the subject car steers back to the right, its heading turning right of the lane's direction beyond the course tolerance. -/
def forbidTrace : Trace := passTrace 5 .bicycle riderHalf 1 18 4 oneLaneRoad

/-- `permit` (compliant): Same pass; the subject car keeps its course until the bicycle is behind it at a gap above the bicycle's speed times the dry headway, then steers back right. -/
def permitTrace : Trace := passTrace 8 .bicycle riderHalf 1 20 7 oneLaneRoad

/-- `idle` (not_applicable): The subject car overtakes another car on a one-lane road and steers back; no bicycle, electric bicycle or electric scooter is in the scene. The duty binds the subject alone. -/
def idleTrace : Trace := passTrace 8 .motorVehicle carHalf 2 20 5 oneLaneRoad

/-- `blind` (unknown): As in forbid, but the source does not observe headings (the manifest masks
    kin.heading). -/
def blindTrace : Trace := passTrace 5 .bicycle riderHalf 1 18 4 oneLaneRoad

/-- `branch_1` (violated): The subject car completes the pass of an electric scooter and steers back right at once, the scooter behind it at a gap below its speed times the dry headway. -/
def branch_1Trace : Trace := passTrace 6 .electricScooter riderHalf 1 20 5 oneLaneRoad

/-- `branch_2` (not_applicable): The road has two lanes in the subject's direction; the subject passes a bicycle and steers back right while beside it. -/
def branch_2Trace : Trace := passTrace 5 .bicycle riderHalf 1 18 4 twoLaneRoad

def witness (name : String) (τ : Trace) (n : Nat) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_2b_o3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, ((n : Int) - 1) * 1000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace 5 .violated
  , witness "permit" permitTrace 8 .compliant
  , witness "idle" idleTrace 8 .notApplicable
  , witness "blind" blindTrace 5 (.unknown []) ["kin.heading"]
  , witness "branch_1" branch_1Trace 6 .violated
  , witness "branch_2" branch_2Trace 5 .notApplicable ]

end TrafficSpecWitness.NRS_484B_270_2b_o3
