/-
  Witnesses for NRS_484B_210_3.

  Geometry (the witness's own figures; none appears in the rule). A straight carriageway running
  east: lane 10 (left lane, y 0…4 m) and lane 11 (right lane, y −4…0 m); beside it, where a scene
  has one, shoulder 12 (y −7…−4 m) or a road-edge strip 13 (y −5…−4 m), each with its paved
  attribute set. Both bodies are 4 m long and 2 m wide, heading east.
  Track 2 (b, a motor vehicle) keeps lane 10 at y = 2 m, 10 m/s, x = 10k + 120 m. Track 1 (the
  subject, a motor vehicle) runs at 20 m/s, x = 20k m, at y = −2 m (on lane 11) or y = −4 m (body
  across lane 11 and the shoulder / edge strip, occupancy stated). Instants k = 0…15 at 1 s from
  t = 20 s; the first scene is repeated 12 s before and the last 3 s after, so every 10 s window
  (p.overtake_window) behind an instant of the main part is covered.
  b is ahead with a 6 m gap and aligned at k = 11, side by side (on the subject's left) at k = 12,
  behind with a 6 m gap at k = 13: the pass on b's right is recognized at k = 13 (t = 33 s); the act
  spans k = 12…13.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_210_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_210_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (m 2, m 1, m 1)

def subjectAt (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (20 * Int.ofNat k), y) Build.east (Units.metresPerSecond 20) body

def otherAt (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (10 * Int.ofNat k + 120), m 2) Build.east (Units.metresPerSecond 10) body

def laneL : Structure := Build.rect 10 .lane (m (-100)) (m 0) (m 600) (m 4)
def laneR : Structure := Build.rect 11 .lane (m (-100)) (m (-4)) (m 600) (m 0)
def shoulder (paved : Bool) : Structure :=
  { Build.rect 12 .shoulder (m (-100)) (m (-7)) (m 600) (m (-4)) with paved := some paved }
def edge (paved : Bool) : Structure :=
  { Build.rect 13 .roadEdge (m (-100)) (m (-5)) (m 600) (m (-4)) with paved := some paved }

/-- The pass (or, without b, the lone drive): the subject is across lane 11 and region `offRegion`
    at the instants `offAt` selects, on lane 11 otherwise. -/
def passTrace (structs : List Structure) (offAt : Nat → Bool) (offRegion : RegionId)
    (withB : Bool := true) : Trace :=
  Build.pad
    (Build.trace 16 20000 (Units.seconds 1) fun k t =>
      let off := offAt k
      let subj := subjectAt k (if off then m (-4) else m (-2))
      let occ : List (TrackId × RegionId) :=
        (if off then [(1, 11), (1, offRegion)] else [(1, 11)]) ++ (if withB then [(2, 10)] else [])
      Build.scene t (some 1) (if withB then [subj, otherAt k] else [subj]) structs [] (some occ))
    (Units.seconds 12) (Units.seconds 3) (Units.seconds 1)

def withShoulder (paved : Bool) : List Structure := [laneL, laneR, shoulder paved]
def withEdge (paved : Bool) : List Structure := [laneL, laneR, edge paved]

/-- `forbid` (violated): The subject passes b on b's right with its footprint overlapping an st.shoulder whose paved attribute is unset during the side-by-side phase. -/
def forbidTrace : Trace := passTrace (withShoulder false) (fun k => 10 ≤ k) 12

/-- `permit` (compliant): The subject passes b on b's right in the adjacent lane, its footprint overlapping no unpaved shoulder and no road edge with an unpaved surface beyond. -/
def permitTrace : Trace := passTrace (withShoulder false) (fun _ => false) 12

/-- `idle` (not_applicable): The subject drives along an unpaved shoulder with no road user ahead of it: no pass is recognized. -/
def idleTrace : Trace := passTrace (withShoulder false) (fun _ => true) 12 (withB := false)

/-- `blind` (unknown): The subject passes b on its right; rel.occupies is not observed, so whether it overlapped an unpaved shoulder is unknown. -/
def blindTrace : Trace := passTrace (withShoulder false) (fun k => 10 ≤ k) 12

/-- `occasion_s3` (violated): The subject's footprint overlaps an unpaved shoulder during the middle part of the pass only, the rest of the act on the roadway. -/
def occasion_s3Trace : Trace := passTrace (withShoulder false) (fun k => k == 12) 12

/-- `occasion_s3_outside` (compliant): The subject's footprint overlapped an unpaved shoulder only before the act began; it returned to the roadway, and then passed b on its right on the pavement. -/
def occasion_s3_outsideTrace : Trace := passTrace (withShoulder false) (fun k => 5 ≤ k && k ≤ 8) 12

/-- `branch_1` (violated): during the side-by-side phase the subject's body is across a road edge
    whose surface beyond is unpaved. -/
def branch_1Trace : Trace := passTrace (withEdge false) (fun k => k == 12) 13

/-- `branch_2` (compliant): the subject passes with its body across a paved shoulder: not off the
    paved portion. -/
def branch_2Trace : Trace := passTrace (withShoulder true) (fun k => 10 ≤ k) 12

/-- `branch_3` (compliant): the subject's body is across a road edge whose surface beyond is paved. -/
def branch_3Trace : Trace := passTrace (withEdge true) (fun k => k == 12) 13

def mainPart : Timestamp × Timestamp := (20000, 35000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_210_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some mainPart
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .compliant
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.NRS_484B_210_3
