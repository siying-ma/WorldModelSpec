/-
  Witnesses for LVMC_11_30_030.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - An eastbound two-lane road on the x axis: right lane 10 (y −4…0) and left lane 11 (y 0…4) from
    x = −60 to 30, a crosswalk 20 at x 30…34 across both lanes (y −4…4), sidewalks 30/31 along both
    edges (|y| 4…7). Mid-block map (`midBlock`): the crosswalk is marked and lanes 12/13 continue at
    x 34…80. Intersection map (`atIntersection`): the crosswalk is unmarked, an intersection 40 lies
    at x 34…50, and lanes 12/13 continue at x 50…80.
  - Cars are 4 m × 2 m (half-extents 2 m, 1 m); the pedestrian 0.6 m × 0.6 m. Track 1 is the
    subject, track 2 the other car b, track 3 the pedestrian.
  - b halted "at" the crosswalk stands at x = 27 in the right lane: its front at 29, 1 m before the
    crosswalk (within the 2 m stop-point tolerance), the crosswalk ahead along lane 10's direction.
  - Observations every 1 s from t = 20 s; each trace is padded with 12 s of its first scene before,
    so the 10 s overtake window behind each judged instant is covered; `window` names the
    instants built from the narrative.
  - A pass: b is ahead of the subject with headings aligned and a gap between the projections, then
    alongside (projections overlapping), then behind (subject's rear past b's front).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_030
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_030

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def tStart : Timestamp := 20000

/-- A position in centimetres. -/
def at_ (x y : Int) : Vec := (cm x, cm y)
/-- A heading slightly left of east (cosine to east about 0.97), for moving out to the left lane. -/
def nne : Vec := (m 4, m 1)

def car (id : TrackId) (p : Vec) (h : Vec) (v : Q) : RoadUser :=
  Build.user id [.motorVehicle] p h v (m 2, m 1, cm 75)
def walker (p : Vec) (h : Vec) (v : Q) : RoadUser :=
  Build.user 3 [.pedestrian] p h v (cm 30, cm 30, cm 90)

def rectR (id : RegionId) (k : StructureKind) (x0 y0 x1 y1 : Int) : Structure :=
  Build.rect id k (m x0) (m y0) (m x1) (m y1)
def laneR (id : RegionId) (x0 y0 x1 y1 : Int) (left right : Option RegionId) : Structure :=
  Build.lane id [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)] Build.east left right

/-- Marked crosswalk, mid-block. -/
def midBlock : List Structure :=
  [ laneR 10 (-60) (-4) 30 0 (some 11) none
  , laneR 11 (-60) 0 30 4 none (some 10)
  , { rectR 20 .crosswalk 30 (-4) 34 4 with marked := some true }
  , laneR 12 34 (-4) 80 0 (some 13) none
  , laneR 13 34 0 80 4 none (some 12)
  , rectR 30 .sidewalk (-60) (-7) 80 (-4)
  , rectR 31 .sidewalk (-60) 4 80 7 ]

/-- Unmarked crosswalk at an intersection. -/
def atIntersection : List Structure :=
  [ laneR 10 (-60) (-4) 30 0 (some 11) none
  , laneR 11 (-60) 0 30 4 none (some 10)
  , { rectR 20 .crosswalk 30 (-4) 34 4 with marked := some false }
  , rectR 40 .intersection 34 (-4) 50 4
  , laneR 12 50 (-4) 80 0 (some 13) none
  , laneR 13 50 0 80 4 none (some 12)
  , rectR 30 .sidewalk (-60) (-7) 80 (-4)
  , rectR 31 .sidewalk (-60) 4 80 7 ]

/-- A trace of `n` scenes, 1 s apart from `tStart`, padded with 12 s of its first scene. -/
def build (n : Nat) (structs : List Structure) (f : Nat → List RoadUser) : Trace :=
  Build.pad
    (Build.trace n tStart (Units.seconds 1) fun k t => Build.scene t (some 1) (f k) structs [])
    (Units.seconds 12) Q.zero (Units.seconds 1)

/-- The built (unpadded) instants of an `n`-scene trace. -/
def span (n : Nat) : Option (Timestamp × Timestamp) :=
  some (tStart, tStart + 1000 * ((n : Int) - 1))

/-- b halted 1 m before the crosswalk in the right lane. -/
def bHalted : RoadUser := car 2 (at_ 2700 (-200)) Build.east Q.zero

/-- A pedestrian walking north on the crosswalk at 0.5 m/s, from y = −3.5 m. -/
def pedOnCrosswalk (k : Nat) : RoadUser :=
  walker (at_ 3200 (-350 + 50 * (k : Int))) Build.north (cm 50)

/-- The subject coming up behind b in the right lane, moving out to the left lane and passing:
    b ahead with a gap and headings aligned up to k = 3, alongside at k = 4, 5, behind at k = 6. -/
def subjectPassing (k : Nat) : RoadUser :=
  match k with
  | 0 => car 1 (at_ 500 (-200)) Build.east (m 5)
  | 1 => car 1 (at_ 1000 (-200)) Build.east (m 5)
  | 2 => car 1 (at_ 1500 (-100)) nne (m 5)
  | 3 => car 1 (at_ 2000 100) nne (m 5)
  | k => car 1 (at_ (2500 + 500 * ((k : Int) - 4)) 200) Build.east (m 5)

/-- `forbid` (violated): Car b halts 1 m before a marked crosswalk in the right lane while a pedestrian walks on the crosswalk; the subject car, coming up behind b in the same direction, moves to the left lane and passes b within 6 s while b is still halted and the pedestrian still on the crosswalk. -/
def forbidTrace : Trace :=
  build 9 midBlock fun k => [subjectPassing k, bHalted, pedOnCrosswalk k]

/-- `permit` (compliant): Car b halts before a marked crosswalk with a pedestrian on it; the subject car, behind b in the same direction, halts behind b and does not pass it. -/
def permitTrace : Trace :=
  build 9 midBlock fun k =>
    let subj := match k with
      | 0 => car 1 (at_ 500 (-200)) Build.east (m 5)
      | 1 => car 1 (at_ 1000 (-200)) Build.east (m 5)
      | 2 => car 1 (at_ 1500 (-200)) Build.east (m 4)
      | 3 => car 1 (at_ 1800 (-200)) Build.east (m 2)
      | _ => car 1 (at_ 1900 (-200)) Build.east Q.zero
    [subj, bHalted, pedOnCrosswalk k]

/-- `idle` (not_applicable): The subject car drives along a street; no vehicle is halted at any crosswalk, and no other vehicle is in the scene. -/
def idleTrace : Trace :=
  build 9 midBlock fun k =>
    [car 1 (at_ (-5000 + 1000 * (k : Int)) 200) Build.east (m 10)]

/-- `blind` (unknown): Car b stands before a marked crosswalk with a pedestrian on it while the subject passes it, but the speed of b is not observed, so whether b is stopped is unknown. -/
def blindTrace : Trace :=
  build 9 midBlock fun k => [subjectPassing k, bHalted, pedOnCrosswalk k]

/-- `occasion_d1` (violated): Car b is halted at an unmarked crosswalk at an intersection with a pedestrian on it during the first 3 s of the subject's pass; the pedestrian then reaches the far curb and b remains halted while the subject completes the pass 2 s later.
    The subject drives the left lane at 2.5 m/s from x = 15: b ahead with a gap at k = 3 (the act
    begins), alongside at k = 4…6, behind at k = 7. The pedestrian (1.5 m/s north from y = −3) is on
    the crosswalk up to k = 4 and on the far sidewalk from k = 5. -/
def occasion_d1Trace : Trace :=
  build 9 atIntersection fun k =>
    [ car 1 (at_ (1500 + 250 * (k : Int)) 200) Build.east (cm 250)
    , bHalted
    , walker (at_ 3200 (-300 + 150 * (k : Int))) Build.north (cm 150) ]

/-- `occasion_d1_outside` (compliant): Car b halts at a marked crosswalk with a pedestrian on it while the subject waits behind; the pedestrian clears the crosswalk and b moves off before the subject begins to move out; the subject passes b, which is then moving, 8 s later, with no pedestrian on the crosswalk during the pass.
    b halted at k = 0…2, then 1 m/s east; the pedestrian (2.5 m/s north from y = 1) is on the
    crosswalk at k = 0, 1 only; the subject halted 3 m behind b to k = 3, moves out at k = 4 (b ahead
    with headings aligned: the act begins), alongside at k = 5…7, b behind at k = 8. -/
def occasion_d1_outsideTrace : Trace :=
  build 10 midBlock fun k =>
    let b := if k ≤ 2 then bHalted
      else car 2 (at_ (2700 + 100 * ((k : Int) - 2)) (-200)) Build.east (m 1)
    let subj := match k with
      | 0 | 1 | 2 | 3 => car 1 (at_ 2000 (-200)) Build.east Q.zero
      | 4 => car 1 (at_ 2300 (-100)) nne (m 4)
      | 5 => car 1 (at_ 2700 100) nne (m 4)
      | k => car 1 (at_ (3000 + 400 * ((k : Int) - 6)) 200) Build.east (m 4)
    [subj, b, walker (at_ 3200 (100 + 250 * (k : Int))) Build.north (cm 250)]

/-- The subject passing in the left lane at 5 m/s from x = 5 (b ahead with a gap at k ≤ 2 when b
    stands at x ≥ 23). -/
def subjectLeftLane (x0 : Int) (k : Nat) : RoadUser :=
  car 1 (at_ (x0 + 500 * (k : Int)) 200) Build.east (m 5)

/-- `branch_1` (not_applicable): b halts 5 m short of the crosswalk (outside the stop-point
    tolerance) with a pedestrian on the crosswalk; the subject passes it: b is not at the crosswalk. -/
def branch1Trace : Trace :=
  build 8 midBlock fun k =>
    [subjectLeftLane 500 k, car 2 (at_ 2300 (-200)) Build.east Q.zero, pedOnCrosswalk k]

/-- `branch_2` (not_applicable): b halts 1 m beyond the crosswalk, in lane 12, with a pedestrian on
    the crosswalk behind it; the subject passes it: the crosswalk lies behind b, so b is not stopped at it. -/
def branch2Trace : Trace :=
  build 8 midBlock fun k =>
    [subjectLeftLane 1500 k, car 2 (at_ 3700 (-200)) Build.east Q.zero, pedOnCrosswalk k]

/-- `branch_3` (not_applicable): b halts 1 m before the crosswalk while a pedestrian waits on the
    curb (sidewalk), not on the crosswalk; the subject passes b. -/
def branch3Trace : Trace :=
  build 9 midBlock fun k =>
    [subjectPassing k, bHalted, walker (at_ 3200 (-500)) Build.north Q.zero]

/-- `branch_4` (not_applicable): b creeps towards the crosswalk at 0.5 m/s (never at rest) while a
    pedestrian is on the crosswalk; the subject passes it: b is not stopped. -/
def branch4Trace : Trace :=
  build 9 midBlock fun k =>
    [ subjectLeftLane 500 k
    , car 2 (at_ (2400 + 50 * (k : Int)) (-200)) Build.east (cm 50)
    , pedOnCrosswalk k ]

/-- `branch_5` (compliant): b halts at the crosswalk with a pedestrian on it while the subject
    creeps up behind it at 0.5 m/s, b still ahead with headings aligned (before the act begins); the
    pedestrian clears, b moves off, and only then does the subject move out and pass b, which is
    moving: the trigger held during the approach only, not during the pass. -/
def branch5Trace : Trace :=
  build 10 midBlock fun k =>
    let b := if k ≤ 2 then bHalted
      else car 2 (at_ (2700 + 100 * ((k : Int) - 2)) (-200)) Build.east (m 1)
    let subj := match k with
      | 0 | 1 | 2 | 3 => car 1 (at_ (1850 + 50 * (k : Int)) (-200)) Build.east (cm 50)
      | 4 => car 1 (at_ 2300 (-100)) nne (m 4)
      | 5 => car 1 (at_ 2700 100) nne (m 4)
      | k => car 1 (at_ (3000 + 400 * ((k : Int) - 6)) 200) Build.east (m 4)
    [subj, b, walker (at_ 3200 (100 + 250 * (k : Int))) Build.north (cm 250)]

/-- `branch_6` (compliant): two cars queue in the right lane before the crosswalk with a pedestrian
    on it: car 4 halted 1 m before the crosswalk, b halted behind it 6 m short of the crosswalk; the
    subject passes b in the left lane and halts alongside car 4 without passing it: b is not at the
    crosswalk, and car 4, which is, is not passed. -/
def branch6Trace : Trace :=
  build 9 midBlock fun k =>
    let subj := match k with
      | 0 => car 1 (at_ 200 200) Build.east (m 5)
      | 1 => car 1 (at_ 700 200) Build.east (m 5)
      | 2 => car 1 (at_ 1200 200) Build.east (m 5)
      | 3 => car 1 (at_ 1600 200) Build.east (m 4)
      | 4 => car 1 (at_ 2000 200) Build.east (m 4)
      | 5 => car 1 (at_ 2300 200) Build.east (m 3)
      | _ => car 1 (at_ 2600 200) Build.east Q.zero
    [ subj
    , car 2 (at_ 2100 (-200)) Build.east Q.zero
    , car 4 (at_ 2700 (-200)) Build.east Q.zero
    , pedOnCrosswalk k ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "LVMC_11_30_030"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := span 9)
  , witness "permit" permitTrace .compliant (window := span 9)
  , witness "idle" idleTrace .notApplicable (window := span 9)
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] (window := span 9)
  , witness "occasion_d1" occasion_d1Trace .violated (window := span 9)
  , witness "occasion_d1_outside" occasion_d1_outsideTrace .compliant (window := span 10)
  , witness "branch_1" branch1Trace .notApplicable (window := span 8)
  , witness "branch_2" branch2Trace .notApplicable (window := span 8)
  , witness "branch_3" branch3Trace .notApplicable (window := span 9)
  , witness "branch_4" branch4Trace .notApplicable (window := span 9)
  , witness "branch_5" branch5Trace .compliant (window := span 10)
  , witness "branch_6" branch6Trace .compliant (window := span 9) ]

end TrafficSpecWitness.LVMC_11_30_030
