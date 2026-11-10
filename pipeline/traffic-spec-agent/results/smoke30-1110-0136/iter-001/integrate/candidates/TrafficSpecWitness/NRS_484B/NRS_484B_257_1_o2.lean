/-
  Witnesses for NRS_484B_257_1_o2.

  Geometry (metres, +x east, +y north): intersection 10 is the square [-10, 10]², lying on
  highways 20 (A, north-south) and 21 (B, east-west). Lane 13 ([0, 6] × [-60, -16]) leads into
  lane 11 ([0, 6] × [-16, -10]), x's northbound approach to 10 on highway A; lane 12
  ([-100, -10] × [-6, 0]) is the eastbound approach to 10 on highway B. Bodies are 5 m × 2 m.

  x (track 1) travels north at x = 3: on lane 13 at y = -20 (k = 0), on lane 11 at y = -13
  (k = 1, halted or slowed there), across the entry at y = -9 (k = 2, on 11 and 10), inside 10
  (k = 3). Observations are 1 s apart; occupancy is stated per instant.

  y (track 2) travels east on lane 12:
  - through: at 10 m/s, x = -29 + 10k, y = -4, entering 10 at k = 2: from x's entry the centres'
    closest approach is about 1.3 m in 1.2 s.
  - far: at 10 m/s, x = -62.5 + 10k: at x's entry its body is 30 m from 10 (≤ 10 × 4 = 40 m) and
    the closest approach lies 4.3 s ahead, beyond the 3 s horizon.
  - fast: at 12 m/s, x = -48 + 12k, y = -2: at x's entry its body is 11.5 m from 10
    (≤ 12 × 4 = 48 m); closest approach about 1.9 m in 2.2 s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: x ↦ 1

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def intersection : Structure :=
  { Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10) with ways := some [20, 21] }
def approachX : Structure :=
  { Build.lane 11 (box 0 (-16) 6 (-10)) Build.north (enters := some 10) with ways := some [20] }
def approachY : Structure :=
  { Build.lane 12 (box (-100) (-6) (-10) 0) Build.east (enters := some 10) with ways := some [21] }
def upstream : Structure :=
  { Build.lane 13 (box 0 (-60) 6 (-16)) Build.north (leadsTo := some [11]) with ways := some [20] }
def highwayA : Structure := Build.rect 20 .highway (m (-12)) (m (-100)) (m 12) (m 100)
def highwayB : Structure := Build.rect 21 .highway (m (-100)) (m (-12)) (m 100) (m 12)

def world : List Structure := [intersection, approachX, approachY, upstream, highwayA, highwayB]

def body : Q × Q × Q := (cm 250, m 1, cm 80)
def xAt (yy v : Q) : RoadUser := Build.user 1 [.motorVehicle] (m 3, yy) Build.north v body
def yAt (xx yy v : Q) : RoadUser := Build.user 2 [.motorVehicle] (xx, yy) Build.east v body

/-- x's run: on lane 13, on lane 11 (halted when `halts`), across the entry, inside 10. -/
def xPhase (halts : Bool) (v : Int) : Nat → RoadUser × List RegionId
  | 0 => (xAt (m (-20)) (mps v), [13])
  | 1 => (xAt (m (-13)) (if halts then Q.zero else mps v), [11])
  | 2 => (xAt (m (-9)) (mps v), [11, 10])
  | _ => (xAt (m (-9 + v)) (mps v), [10])

def yThrough : Nat → List (RoadUser × List RegionId)
  | 0 => [(yAt (m (-29)) (m (-4)) (mps 10), [12])]
  | 1 => [(yAt (m (-19)) (m (-4)) (mps 10), [12])]
  | 2 => [(yAt (m (-9)) (m (-4)) (mps 10), [12, 10])]
  | _ => [(yAt (m 1) (m (-4)) (mps 10), [10])]

def yFar (k : Nat) : List (RoadUser × List RegionId) :=
  [(yAt (cm (-6250 + 1000 * (k : Int))) (m (-4)) (mps 10), [12])]

def yFast : Nat → List (RoadUser × List RegionId)
  | 0 => [(yAt (m (-48)) (m (-2)) (mps 12), [12])]
  | 1 => [(yAt (m (-36)) (m (-2)) (mps 12), [12])]
  | 2 => [(yAt (m (-24)) (m (-2)) (mps 12), [12])]
  | _ => [(yAt (m (-12)) (m (-2)) (mps 12), [12, 10])]

def noOne (_ : Nat) : List (RoadUser × List RegionId) := []

def frame (devs : List Device) (t : Timestamp) (x : RoadUser × List RegionId)
    (others : List (RoadUser × List RegionId)) : Scene :=
  Build.scene t (some 1) (x.1 :: others.map (·.1)) world devs
    (occupies := some ((x.2.map fun r => (x.1.track, r)) ++
      others.flatMap fun (u, rs) => rs.map fun r => (u.track, r)))

def crossing (n : Nat) (devs : List Device) (halts : Bool) (v : Int)
    (others : Nat → List (RoadUser × List RegionId)) : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t => frame devs t (xPhase halts v k) (others k)

def stopX : Device := Build.sign 30 .stopSign [11]
def stopAtIntersection : Device := Build.sign 30 .stopSign [10]
def stopY : Device := Build.sign 31 .stopSign [12]
def yieldX : Device := Build.sign 32 .yieldSign [11]
def yieldAtIntersection : Device := Build.sign 32 .yieldSign [10]
def police : Device :=
  { Build.device 40 .humanDirection [10] with humanRole := some .policeOfficer, humanIndication := some .proceed }
def greenSignal : Device :=
  { Build.signal 41 [11] [.circularGreen] with inoperative := some false, uncovered := some true }

/-- `forbid` (violated): A dev.stop_sign governs c on highway A. x halts at the stop line, then moves into i while y, which entered i from highway B, crosses x's path; predicted closest approach 1 m in 1.3 s. -/
def forbidTrace : Trace := crossing 4 [stopX] true 3 yThrough

/-- `permit` (compliant): x halts at the stop line and moves into i while y on highway B, 30 m from i at 10 m/s, is predicted to pass 12 m from x. -/
def permitTrace : Trace := crossing 3 [stopX] true 3 yFar

/-- `idle` (not_applicable): No stop or yield sign governs c or i; x crosses i while y crosses.
    (The only stop sign governs y's approach, lane 12.) -/
def idleTrace : Trace := crossing 4 [stopY] true 3 yThrough

/-- `blind` (unknown): As forbid, but st.on_way is not observed, so whether y came from the through highway is unknown.
    (Judged at x's entry, with y on lane 12 still outside i at 12 m/s, closest approach about
    0.3 m in 2.3 s: inside i, the intersection itself is a travel region whose `st_lane_enters`
    is unrecorded, which would add its own unknown to the masked one.) -/
def blindTrace : Trace := crossing 3 [stopX] true 3 yFast

/-- `branch_1` (not_applicable): As forbid, but x never halted (and a stop sign, not a yield sign, governs): the condition 'after having stopped' does not hold. -/
def branch_1Trace : Trace := crossing 4 [stopX] false 3 yThrough

/-- `branch_2` (violated): Only a dev.yield_sign governs c; x slows to 4 m/s on c and moves into i while y on highway B, outside i, is 25 m from i at 12 m/s; predicted closest approach 2 m in 2 s.
    (A stop sign governs y's approach only; judged at x's entry, while y is still outside i.) -/
def branch_2Trace : Trace := crossing 3 [yieldX, stopY] false 4 yFast

/-- `branch_3` (not_applicable): A stop sign governs c; x halts, then crosses i with no other road user in the scene. -/
def branch_3Trace : Trace := crossing 4 [stopX] true 3 noOne

/-- `branch_4` (not_applicable): As forbid, but a police officer directs traffic at i: the exception of s1. -/
def branch_4Trace : Trace := crossing 4 [stopX, police] true 3 yThrough

/-- `branch_5` (not_applicable): As forbid, but an operative traffic signal showing green governs c: the exception of s2. -/
def branch_5Trace : Trace := crossing 4 [stopX, greenSignal] true 3 yThrough

/-- `branch_6` (violated): As forbid, but the stop sign governs the intersection i rather than c. -/
def branch_6Trace : Trace := crossing 4 [stopAtIntersection] true 3 yThrough

/-- `branch_7` (violated): As branch_2, but the yield sign governs the intersection i rather than c. -/
def branch_7Trace : Trace := crossing 4 [yieldAtIntersection, stopY] false 4 yFast

/-- `branch_8` (not_applicable): As forbid, but a police officer's direction governs x's approach lane c. -/
def branch_8Trace : Trace :=
  crossing 4 [stopX, { police with governs := [11] }] true 3 yThrough

/-- `branch_9` (not_applicable): As forbid, but an operative traffic signal showing green governs the intersection i. -/
def branch_9Trace : Trace :=
  crossing 4 [stopX, { greenSignal with governs := [10] }] true 3 yThrough

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.on_way"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_257_1_o2
