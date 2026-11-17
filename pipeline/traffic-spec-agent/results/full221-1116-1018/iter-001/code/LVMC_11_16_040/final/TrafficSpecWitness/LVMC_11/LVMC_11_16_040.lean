/-
  Witnesses for LVMC_11_16_040.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - way 10: a north–south highway, x ∈ [-15, 15], y ∈ [-120, 120];
    way 11: an east–west highway, x ∈ [-120, 120], y ∈ [-5, 25];
  - region 20: the intersection, x ∈ [-10, 10], y ∈ [0, 20], lying on ways 10 and 11, with its
    sight distance per scenario (300 m: never short; 10 m in branch_5);
  - lane 30: the subject's northbound approach, x ∈ [0, 10], y ∈ [-120, 0], entering 20;
    lane 31: the westbound cross approach, x ∈ [10, 120], y ∈ [0, 10], entering 20.
  - subject (track 1, motor vehicle, half-extents 2.5 × 1 × 0.75 m) drives north along x = 5,
    5 m of path between consecutive observations: y = -62 + 5k for k = 0 … 16, path length 5k.
    It is in lane 30 for k ≤ 12 (y = -2 at k = 12, the last observation before entry) and in the
    intersection for k = 13 … 16 (y = 3 … 18). The 100 ft (30.48 m) path window behind k = 12
    reaches back to k = 6, preceded by observations, sampled every 5 m: covered and adequate.
  - fast runs: one observation per 0.5 s at 10 m/s (22.4 mph); slow runs: one per 1 s at 5 m/s
    (11.2 mph). Both against 15 mph = 6.7056 m/s. The window names the in-intersection instants.
  - sight along the ways (per way, from the subject): restricted = 20 m along way 11 (25 m in
    branch_1), 200 m along way 10; clear = 200 m along both.
  - another vehicle (track 2), stationary on way 11 at (35, 15) (body 22.5 m from the
    intersection) or at (100, 15) (87.5 m), with its visibility from the subject measured.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_16_040
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_16_040

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (cm 250, m 1, cm 75)

def fastSpeed : Q := Units.metresPerSecond 10
def slowSpeed : Q := Units.metresPerSecond 5
def fastDt : Q := Units.milliseconds 500
def slowDt : Q := Units.seconds 1
def fastWindow : Option (Timestamp × Timestamp) := some (6500, 8000)
def slowWindow : Option (Timestamp × Timestamp) := some (13000, 16000)

def restricted : Option (List (RegionId × Q)) := some [(11, m 20), (10, m 200)]
def clearSight : Option (List (RegionId × Q)) := some [(11, m 200), (10, m 200)]

def subjectAt (speed : Q) (sight : Option (List (RegionId × Q))) (k : Nat) : RoadUser :=
  { Build.user 1 [.motorVehicle] (m 5, m (-62 + 5 * (k : Int))) Build.north speed body
      (some (m (5 * (k : Int)))) with sightAlongWay := sight }

def structures (sd : Q) : List Structure :=
  [ Build.rect 10 .highway (m (-15)) (m (-120)) (m 15) (m 120)
  , Build.rect 11 .highway (m (-120)) (m (-5)) (m 120) (m 25)
  , { Build.rect 20 .intersection (m (-10)) (m 0) (m 10) (m 20) with
        ways := some [10, 11], sightDistance := some sd }
  , Build.lane 30 [(m 0, m (-120)), (m 10, m (-120)), (m 10, m 0), (m 0, m 0)] Build.north
      (enters := some 20)
  , Build.lane 31 [(m 10, m 0), (m 120, m 0), (m 120, m 10), (m 10, m 10)] Build.west
      (enters := some 20) ]

def other (x : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (m x, m 15) Build.west Q.zero body (some Q.zero)

def seen (v : Bool) : MeasuredRelation := Build.relation 1 2 (fun r => { r with visible := some v })

/-- The approach and traversal, with the scenario's speed, sight, sight distance, other users,
    devices and measured relations. -/
def run (dt speed : Q) (sight : Option (List (RegionId × Q))) (sd : Q)
    (others : List RoadUser) (devs : List Device) (rels : List MeasuredRelation) : Trace :=
  Build.trace 17 0 dt fun k t =>
    Build.withRelations
      (Build.scene t (some 1) (subjectAt speed sight k :: others) (structures sd) devs) rels

/-- `forbid` (violated): Uncontrolled intersection, hedges limit sight along the cross street to 20 m during the last 100 ft of the subject's approach; it traverses j above fifteen mph. -/
def forbidTrace : Trace := run fastDt fastSpeed restricted (m 300) [] [] []

/-- `permit` (compliant): Same, traversing j at or below fifteen mph. -/
def permitTrace : Trace := run slowDt slowSpeed restricted (m 300) [] [] []

/-- `idle` (not_applicable): Same restricted view, but a traffic signal (circular_green) governs the subject's approach lane. -/
def idleTrace : Trace :=
  run fastDt fastSpeed restricted (m 300) [] [Build.signal 40 [30] [.circularGreen]] []

/-- `blind` (unknown): Uncontrolled intersection; the source does not supply sight along the ways, and the subject traverses above fifteen mph. -/
def blindTrace : Trace := run fastDt fastSpeed none (m 300) [] [] []

/-- `branch_1` (compliant): Uncontrolled intersection, no other road user in the scene; a wall limits sight along one cross way below one hundred feet during the last 100 ft of the approach; the subject traverses at or below fifteen mph. The traffic quantifier is empty and the verdict is still decided by the sight along the way. -/
def branch_1Trace : Trace :=
  run slowDt slowSpeed (some [(11, m 25), (10, m 200)]) (m 300) [] [] []

/-- `branch_2` (violated): clear sight along both ways, but a vehicle on the cross way 22.5 m from j is not visible during the approach (d7); fast. -/
def branch_2Trace : Trace := run fastDt fastSpeed clearSight (m 300) [other 35] [] [seen false]

/-- `branch_3` (not_applicable): as branch_2, the vehicle visible: the view is clear. -/
def branch_3Trace : Trace := run fastDt fastSpeed clearSight (m 300) [other 35] [] [seen true]

/-- `branch_4` (not_applicable): as branch_2, the hidden vehicle 87.5 m from j, beyond one hundred feet. -/
def branch_4Trace : Trace := run fastDt fastSpeed clearSight (m 300) [other 100] [] [seen false]

/-- `branch_5` (violated): clear sight along the ways, no other user, but the intersection's sight distance (10 m) is below the subject's distance to it early in the window (d6); fast. -/
def branch_5Trace : Trace := run fastDt fastSpeed clearSight (m 10) [] [] []

/-- `branch_6` (not_applicable): restricted view; a stop sign governs the cross approach (through street, traffic-controlled); fast. -/
def branch_6Trace : Trace :=
  run fastDt fastSpeed restricted (m 300) [] [Build.sign 41 .stopSign [31]] []

/-- `branch_7` (not_applicable): restricted view; a yield sign governs the subject's approach; fast. -/
def branch_7Trace : Trace :=
  run fastDt fastSpeed restricted (m 300) [] [Build.sign 42 .yieldSign [30]] []

/-- `branch_8` (not_applicable): restricted view; a traffic signal (circular_green) governs the intersection itself; fast. -/
def branch_8Trace : Trace :=
  run fastDt fastSpeed restricted (m 300) [] [Build.signal 43 [20] [.circularGreen]] []

/-- `branch_9` (violated): restricted view; the signal on the subject's approach is dark, so the intersection is not traffic-controlled; fast. -/
def branch_9Trace : Trace :=
  run fastDt fastSpeed restricted (m 300) [] [Build.signal 44 [30] [.dark]] []

/-- `branch_10` (not_applicable): restricted view; a flashing-red signal governs the cross approach; fast. -/
def branch_10Trace : Trace :=
  run fastDt fastSpeed restricted (m 300) [] [Build.signal 45 [31] [.flashingRed]] []

/-- `branch_11` (not_applicable): clear sight along both ways, no other user, sight distance ample: the view is clear; fast. -/
def branch_11Trace : Trace := run fastDt fastSpeed clearSight (m 300) [] [] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := fastWindow) : Scenario :=
  { name := name
    rule := "LVMC_11_16_040"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant (window := slowWindow)
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.sight_along_way"]
  , witness "branch_1" branch_1Trace .compliant (window := slowWindow)
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .notApplicable
  , witness "branch_11" branch_11Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_16_040
