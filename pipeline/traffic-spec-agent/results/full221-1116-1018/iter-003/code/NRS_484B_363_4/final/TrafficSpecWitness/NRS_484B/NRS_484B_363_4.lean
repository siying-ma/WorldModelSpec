/-
  Witnesses for NRS_484B_363_4.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - an eastbound carriageway: right lane y ∈ [-4, 0] (region 10), left lane y ∈ [0, 4] (region 11),
    x ∈ [-20, 300]; in the `occasion_s3` witnesses the lanes are cut at x = 115 or x = 95 into a
    western part (10, 11) and an eastern part (12, 13); `branch_7` adds a third lane y ∈ [4, 8] (14).
  - every body is 4 m long and 2 m wide (half-extents 2, 1, 1).
  - scenes every second from t = 0; the subject (track 1) drives the left lane at 10 m/s,
    x = 10k. The other car (track 2) drives the right lane at 8 m/s, x = 26 + 8k: it is ahead with a
    gap up to k = 10 (gap 2 m at k = 10), alongside for k = 11 … 15 and behind with a gap at
    k = 16, where the pass is recognized. Its under-way stretch in the rule is k = 11 … 16. Every
    witness is judged at t = 16 s; its 10 s window behind, [6, 16], is covered by the trace.
  - zone sign 100 (school crossing, or school in the occasion_s3 witnesses) governs the lanes, with
    a legend window 07:00–16:00 every day; the recording's clock reads 08:00 unless stated.
    Beacon 200, where present, governs both lanes.
  - assumptions declared in every scene: school in session, not outside the operation margin,
    pupils in class, unless stated.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_363_4
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_363_4

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- A car with a 4 m × 2 m body. -/
def car (track : TrackId) (x y : Int) (heading : Vec) (speed : Int) : RoadUser :=
  Build.user track [.motorVehicle] (m x, m y) heading (Units.metresPerSecond speed) (m 2, m 1, m 1)

/-- The subject in the left lane at 10 m/s. -/
def subjectCar (k : Nat) : RoadUser := car 1 (10 * (k : Int)) 2 Build.east 10

/-- The other car in the right lane at 8 m/s: passed at k = 16. -/
def passedCar (k : Nat) : RoadUser := car 2 (26 + 8 * (k : Int)) (-2) Build.east 8

/-- The other car moving until k = 13 and at rest at x = 150 from k = 14: passed at k = 16. -/
def stoppingCar (k : Nat) : RoadUser :=
  if k ≤ 13 then car 2 (38 + 8 * (k : Int)) (-2) Build.east 8 else car 2 150 (-2) Build.east 0

/-- The other car angled out of the kerb (heading north-east, not aligned) up to k = 9, then
    heading east: passed at k = 16. -/
def emergingCar (k : Nat) : RoadUser :=
  if k ≤ 9 then car 2 (26 + 8 * (k : Int)) (-2) (m 1, m 1) 8 else passedCar k

/-- A third car in the outer left lane at 8 m/s, x = 36 + 8k: ahead with a gap up to k = 15,
    alongside from k = 16, passed at k = 21. -/
def thirdCar (k : Nat) : RoadUser := car 3 (36 + 8 * (k : Int)) 6 Build.east 8

def laneRect (id : RegionId) (x0 y0 x1 y1 : Int) : Structure :=
  Build.lane id [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)] Build.east

def lanesFull : List Structure :=
  [laneRect 10 (-20) (-4) 300 0, laneRect 11 (-20) 0 300 4]

def lanesSplit (x : Int) : List Structure :=
  [laneRect 10 (-20) (-4) x 0, laneRect 11 (-20) 0 x 4, laneRect 12 x (-4) 300 0, laneRect 13 x 0 300 4]

def lanesThree : List Structure := lanesFull ++ [laneRect 14 (-20) 4 300 8]

/-- The sign's legend: 07:00–16:00, every day. -/
def schoolHours : Conditions := { windows := [{ startMinute := 420, endMinute := 960 }] }

def crossingSign : Device := Build.zoneSign 100 [10, 11] .schoolCrossing false (some schoolHours)
def schoolSign : Device := Build.zoneSign 100 [10, 11] .school false (some schoolHours)
def speedZoneSign : Device := Build.zoneSign 100 [10, 11] .speedZone false (some {})

def beacon (inoperative flashing : Bool) : Device :=
  { Build.device 200 .speedLimitBeacon [10, 11] with
    inoperative := some inoperative, flashing := some flashing }

def asms (inSession outsideMargin pupils : Bool) : List (AsmId × Bool) :=
  [("asm.school_in_session_day", inSession), ("asm.school_outside_operation_margin", outsideMargin),
   ("asm.pupils_in_class", pupils)]

def clock (minute : Nat) : Env :=
  { civilTime := some { year := 2026, month := 3, day := 10, weekday := 1, minuteOfDay := minute } }

def mkScene (t : Timestamp) (users : List RoadUser) (structs : List Structure) (devs : List Device)
    (minute : Nat := 480) (as : List (AsmId × Bool) := asms true false true) : Scene :=
  Build.scene t (some 1) users structs devs (env := clock minute) (assumptions := as)

def run (n : Nat) (f : Nat → Timestamp → Scene) : Trace := Build.trace n 0 (Units.seconds 1) f

/-- `forbid` (violated): The subject vehicle, on a lane governed by a dev.zone_sign of kind school_crossing (not an end sign, conditions holding), comes up behind another moving vehicle with aligned headings and comes to have it behind (rel.bearing longitudinal negative, no overlap); asm.school_in_session_day true, asm.school_outside_operation_margin false; no beacon governs the lane. -/
def forbidTrace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign]

/-- `permit` (compliant): Same zone and declarations as forbid; the subject is the only vehicle in the scene and travels through the zone: no pass is recognized. -/
def permitTrace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k] lanesFull [crossingSign]

/-- `idle` (not_applicable): The subject passes another moving vehicle on a street no dev.zone_sign of kind school or school_crossing governs (a speed zone sign governs it). -/
def idleTrace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [speedZoneSign]

/-- `blind` (unknown): Same as forbid, but the source declares kin.position absent: the pass concept, which reads the positions of both road users, the bearing and longitudinal overlap computed from them, and the subject's footprint occupancy are unobserved, so whether a pass of a travelling vehicle is made in the zone is not decided. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): Same as forbid, but the other vehicle is at rest (kin.speed at or below the halt tolerance) at every observation while the pass is under way (it stops at k = 14, before it is drawn alongside): it is not a vehicle traveling. -/
def branch_1Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, stoppingCar k] lanesFull [crossingSign]

/-- `branch_2` (not_applicable): No beacon governs the zone's lane; prim.conditions_hold is false for the zone sign throughout the pass (the clock reads 16:40): exception (d) holds. -/
def branch_2Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign] (minute := 1000)

/-- `branch_3` (not_applicable): An operational beacon governs the zone's lane and is not flashing; asm.pupils_in_class true throughout the pass: exception (c) holds. -/
def branch_3Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign, beacon false false]

/-- `occasion_s3` (violated): The pass begins while the subject's footprint overlaps a lane the school zone sign governs (the zone ends at x = 115; the subject is in it up to k = 11) and is recognized after the subject has left the zone; no exception holds. -/
def occasion_s3Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] (lanesSplit 115) [schoolSign]

/-- `occasion_s3_outside` (not_applicable): The subject occupies the zone's lane only before the pass begins (the zone ends at x = 95; the subject leaves it after k = 9, while the other vehicle is still angled out of the kerb, not ahead with aligned headings), and the whole pass takes place on regions no zone sign governs. -/
def occasion_s3_outsideTrace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, emergingCar k] (lanesSplit 95) [schoolSign]

/-- `occasion_s7` (violated): A beacon governing the lane, not flashing, with asm.pupils_in_class true, is operational at the first observations of the pass (k ≤ 12) and inoperative at the later ones, while the zone sign's conditions hold: neither (c) nor (d) holds throughout. -/
def occasion_s7Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign, beacon (decide (k ≥ 13)) false]

/-- `occasion_s7_outside` (not_applicable): The beacon is inoperative before the pass begins (k ≤ 9) and operational, not flashing, at every observation while it is under way, with asm.pupils_in_class true: exception (c) holds throughout. -/
def occasion_s7_outsideTrace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign, beacon (decide (k ≤ 9)) false]

/-- `occasion_s9` (violated): An operational beacon governs the lane with asm.pupils_in_class true; it is not flashing at the first observations of the pass (k ≤ 12) and flashing at the later ones; no other exception holds. -/
def occasion_s9Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign, beacon false (decide (k ≥ 13))]

/-- `occasion_s9_outside` (not_applicable): The operational beacon is flashing before the pass begins (k ≤ 9) and not flashing at every observation while it is under way, with asm.pupils_in_class true: exception (c) holds throughout. -/
def occasion_s9_outsideTrace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign, beacon false (decide (k ≤ 9))]

/-- `occasion_s10` (violated): The beacon governing the lane is inoperative at the first observations of the pass (k ≤ 12) and operational and flashing at the later ones; the zone sign's conditions do not hold throughout (16:40): neither (c) nor (d) holds throughout. -/
def occasion_s10Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull
    [crossingSign, beacon (decide (k ≤ 12)) (decide (k ≥ 13))] (minute := 1000)

/-- `occasion_s10_outside` (not_applicable): The beacon governing the lane is operational before the pass begins (k ≤ 9) and inoperative at every observation while it is under way; prim.conditions_hold is false for the zone sign throughout (16:40): exception (d) holds throughout. -/
def occasion_s10_outsideTrace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull
    [crossingSign, beacon (decide (k ≥ 10)) false] (minute := 1000)

/-- `occasion_s11` (violated): No beacon governs the lane; prim.conditions_hold for the zone sign is false at the first observations of the pass (06:59, k ≤ 12) and true at the later ones (07:00). -/
def occasion_s11Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign]
    (minute := if k ≤ 12 then 419 else 420)

/-- `occasion_s11_outside` (not_applicable): No beacon governs the lane; prim.conditions_hold is true before the pass begins (15:59, k ≤ 9) and false at every observation while it is under way (16:00): exception (d) holds throughout. -/
def occasion_s11_outsideTrace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign]
    (minute := if k ≤ 9 then 959 else 960)

/-- `branch_4` (not_applicable): asm.school_in_session_day is declared true before the pass begins (k ≤ 9) and false at every observation while it is under way: exception (a) holds throughout. -/
def branch_4Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign]
    (as := asms (decide (k ≤ 9)) false true)

/-- `branch_5` (not_applicable): asm.school_outside_operation_margin is declared false before the pass begins (k ≤ 9) and true at every observation while it is under way: exception (b) holds throughout. -/
def branch_5Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign]
    (as := asms true (decide (k ≥ 10)) true)

/-- `branch_6` (violated): An operational beacon governs the lane and is not flashing, but asm.pupils_in_class is false throughout the pass; the zone sign's conditions hold: neither (c) nor (d) holds. -/
def branch_6Trace : Trace :=
  run 17 fun k t => mkScene t [subjectCar k, passedCar k] lanesFull [crossingSign, beacon false false]
    (as := asms true false false)

/-- `branch_7` (compliant): The subject draws alongside a travelling vehicle in the outer lane (passed only at k = 21, after the judged observation) while it passes, at k = 16, a vehicle that stopped before it was drawn alongside: the duty applies, and the pass of the vehicle at rest does not violate it. -/
def branch_7Trace : Trace :=
  run 22 fun k t => mkScene t [subjectCar k, stoppingCar k, thirdCar k] lanesThree [crossingSign]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_363_4"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (16000, 16000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.position"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .notApplicable
  , witness "occasion_s7" occasion_s7Trace .violated
  , witness "occasion_s7_outside" occasion_s7_outsideTrace .notApplicable
  , witness "occasion_s9" occasion_s9Trace .violated
  , witness "occasion_s9_outside" occasion_s9_outsideTrace .notApplicable
  , witness "occasion_s10" occasion_s10Trace .violated
  , witness "occasion_s10_outside" occasion_s10_outsideTrace .notApplicable
  , witness "occasion_s11" occasion_s11Trace .violated
  , witness "occasion_s11_outside" occasion_s11_outsideTrace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant ]

end TrafficSpecWitness.NRS_484B_363_4
