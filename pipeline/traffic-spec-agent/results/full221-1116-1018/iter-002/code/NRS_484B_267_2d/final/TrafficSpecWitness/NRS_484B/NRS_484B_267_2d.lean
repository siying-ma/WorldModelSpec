/-
  Witnesses for NRS_484B_267_2d.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
  - Two eastbound lanes along the x axis: lane 101 (y ∈ [-2, 2]), the subject's, and lane 102
    (y ∈ [2, 6]), the approached vehicle's. Observations every second from t = 0.
  - The subject (track 1) is a car (half-extents 2.5 m × 1 m) at y = 0, heading east.
  - The approached vehicle (track 2) is an official vehicle of a regulatory agency (half-extents
    5 m × 1.25 m) at y = 4. The reading leaves every road-user class unresolved under
    DEF-NRS-484A-020::authorized_emergency_vehicle, so a fire engine's membership is unknown and
    can decide no verdict; the decided witnesses therefore use a regulatory-agency vehicle (the
    other alternative of s1), and a bicycle (decided outside both) in branch_3.
  - Base pass: the subject at x = 15k (15 m/s), the vehicle at x = 70 + 10k (10 m/s). The gap
    d = 70 − 5k: the vehicle is ahead clear (d = 10, k = 12), the bodies share length along the
    subject's heading at k = 13, 14, 15 (d = 5, 0, -5; half-lengths sum to 7.5 m), and the vehicle
    is behind clear at k = 16 (d = -10): the pass is recognized there, 4 s after the last aligned
    ahead observation, well within p.overtake_window = 10 s. The centre distance (≤ 75 m) is well
    within p.emergency_approach_reach = 150 m; every speed is 0 or ≥ 2 m/s against
    p.halt_speed_tolerance = 0.1 m/s; headings are equal (cosine 1) or opposed (cosine -1) against
    p.overtake_same_direction_cos = 0.9.
  - Each witness names the instants it speaks about (`window`), at least 11 s after the trace
    starts so that every 10 s look-back is covered.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_267_2d
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_267_2d

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

/-- The map: two eastbound lanes. -/
def laneA : RegionId := 101
def laneB : RegionId := 102
def laneC : RegionId := 103
def lanes : List Structure :=
  [ Build.rect laneA .lane (m (-100)) (m (-2)) (m 600) (m 2)
  , Build.rect laneB .lane (m (-100)) (m 2) (m 600) (m 6)
  , Build.rect laneC .lane (m (-100)) (m (-6)) (m 600) (m (-2)) ]

def redFlashingFront : List WarningLamp := [{ colour := .red, mode := .flashing, facing := .front }]

/-- The subject: a car in lane 101 heading east. -/
def subjectAt (x : Int) (speed : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m 0) Build.east (mps speed) (cm 250, m 1, cm 75)

/-- The approached vehicle: a regulatory agency's official vehicle in lane 102. -/
def agencyAt (x : Int) (heading : Vec) (speed : Int) (lamps : List WarningLamp)
    (hand : HandSignal := .noSignal) (turn : TurnIndicatorState := .off) : RoadUser :=
  let u := Build.user 2 [.officialVehicle, .motorVehicle] (m x, m 4) heading (mps speed) (m 5, cm 125, cm 150)
  Build.withSignals { u with officialKind := some .regulatoryAgency } fun s =>
    { s with warningLamps := some lamps, handSignal := some hand, turnIndicator := some turn }

/-- The vehicle is in the subject's line of sight (supplied: Core never computes it). -/
def seen : MeasuredRelation := Build.relation 1 2 (fun r => { r with visible := some true })

/-- A police officer directing traffic, waving traffic on, governing the subject's lane. -/
def officer : Device :=
  { Build.device 201 .humanDirection [laneA] (some (m 0, m (-4))) with
    humanRole := some .policeOfficer, humanIndication := some .proceed }

def sceneOf (t : Timestamp) (s e : RoadUser) (devices : List Device := []) : Scene :=
  Build.withRelations (Build.scene t (some 1) [s, e] lanes devices) [seen]

/-- The base pass, with the vehicle's lamps and the officer's presence per observation. -/
def basePass (lamps : Nat → List WarningLamp) (officerAt : Nat → Bool) : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    sceneOf t (subjectAt (15 * k) 15) (agencyAt (70 + 10 * k) Build.east 10 (lamps k))
      (if officerAt k then [officer] else [])

/-- `forbid` (violated): The agency vehicle moves ahead of the subject in the same direction with its
    red lamp flashing; the subject approaches it from behind within the reach, draws alongside
    (k = 13–15) and passes it, the vehicle coming to be behind it (k = 16). -/
def forbidTrace : Trace := basePass (fun _ => redFlashingFront) (fun _ => false)

/-- `permit` (compliant): Same scene, but the subject follows 30 m behind at the vehicle's speed,
    never sharing length with it along its heading. -/
def permitTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    sceneOf t (subjectAt (10 * k) 10) (agencyAt (30 + 10 * k) Build.east 10 redFlashingFront)

/-- `idle` (not_applicable): The subject passes a slower car, which shows no warning lamp and is
    no official vehicle; the duty does not arise. -/
def idleTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    let car := Build.withSignals
      (Build.user 2 [.motorVehicle] (m (70 + 10 * k), m 4) Build.east (mps 10) (cm 250, m 1, cm 75))
      fun s => { s with warningLamps := some [], handSignal := some .noSignal, turnIndicator := some .off }
    sceneOf t (subjectAt (15 * k) 15) car

/-- `blind` (unknown): As in forbid, but the source does not observe warning lamps. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): As in forbid, but the subject draws alongside the vehicle (k = 13, 14)
    and keeps level with it, moving at its speed, without completing the pass. -/
def branch_1Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    let s := if k ≤ 13 then subjectAt (15 * k) 15 else subjectAt (210 + 10 * (k - 14)) 10
    sceneOf t s (agencyAt (70 + 10 * k) Build.east 10 redFlashingFront)

/-- `branch_2` (not_applicable): The vehicle with its red lamp flashing moves in the opposite
    direction; the subject approaches it head-on and they come side by side as they meet (k = 12).
    The headings are opposed, so the condition fails. -/
def branch_2Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    sceneOf t (subjectAt (15 * k) 15) (agencyAt (300 - 10 * k) Build.west 10 redFlashingFront)

/-- `branch_3` (not_applicable): The subject passes a cyclist showing a flashing red lamp; a
    bicycle is neither an authorized emergency vehicle nor an official vehicle, so the duty does
    not arise. -/
def branch_3Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    let bike := Build.withSignals
      (Build.user 2 [.bicycle] (m (100 + 5 * k), m 4) Build.east (mps 5) (cm 90, cm 30, m 1))
      fun s => { s with warningLamps := some [{ colour := .red, mode := .flashing, facing := .rear }],
                        handSignal := some .noSignal, turnIndicator := some .off }
    sceneOf t (subjectAt (15 * k) 15) bike

/-- The vehicle moves (lamp off) until k = 5, then halts at x = 185 with its red lamp flashing,
    showing the given arm signal and turn indicator; the subject draws abreast of it at k = 12, within
    the window behind its last movement, and passes it at k = 13. -/
def preparingTrace (hand : HandSignal) (turn : TurnIndicatorState) : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    let e := if k ≤ 5 then agencyAt (135 + 10 * k) Build.east 10 []
             else agencyAt 185 Build.east 0 redFlashingFront hand turn
    sceneOf t (subjectAt (15 * k) 15) e

/-- `branch_4` (violated): The vehicle, having moved ahead of the subject, halts with its lamp
    flashing and visibly signals with its driver's arm that it is about to move (preparing to
    move); the subject drives abreast of it within the window behind its last movement. -/
def branch_4Trace : Trace := preparingTrace .left .off

/-- `branch_5` (violated): As branch_4, but the halted vehicle shows a lit turn indicator and no arm
    signal. -/
def branch_5Trace : Trace := preparingTrace .noSignal .left

/-- `branch_6` (compliant): The vehicle moves at 2 m/s; the subject passes it, pausing alongside
    for one observation (k = 14, at rest). A police officer directing traffic governs the
    subject's lane at every observation of the pass at which the subject moves (k = 13, 15, 16 on),
    not at the pause: the pass is excepted throughout it, and a subject at rest alongside does not
    drive abreast. -/
def branch_6Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    let s := if k ≤ 13 then subjectAt (15 * k) 15
             else if k == 14 then subjectAt 195 0
             else subjectAt (195 + 15 * (k - 14)) 15
    sceneOf t s (agencyAt (174 + 2 * k) Build.east 2 redFlashingFront)
      (if k == 13 || k ≥ 15 then [officer] else [])

/-- `branch_7` (compliant): The agency vehicle, lamp flashing, overtakes the subject from behind
    (vehicle at x = 15k − 60, 15 m/s; subject at x = 10k, 10 m/s): side by side at k = 11–13, its
    centre ahead of the subject's at k = 13 only. At k = 13 a police officer directing traffic governs
    the subject's lane and waves it on, so the subject's moving alongside there is excused; the
    overtaking alternative is engaged (the officer did not govern throughout), but the subject
    never overtakes the vehicle. -/
def branch_7Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    sceneOf t (subjectAt (10 * k) 10) (agencyAt (15 * k - 60) Build.east 15 redFlashingFront)
      (if k == 13 then [officer] else [])

/-- `branch_8` (compliant): The subject follows the agency vehicle 30 m behind at its speed, as in
    permit, and passes a cyclist showing a flashing red lamp in lane 103 (side by side at k = 14); a
    bicycle is no authorized emergency vehicle, so drawing abreast of it breaches nothing. -/
def branch_8Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    let bike := Build.withSignals
      (Build.user 3 [.bicycle] (m (70 + 5 * k), m (-4)) Build.east (mps 5) (cm 90, cm 30, m 1))
      fun s => { s with warningLamps := some [{ colour := .red, mode := .flashing, facing := .rear }],
                        handSignal := some .noSignal, turnIndicator := some .off }
    Build.withRelations
      (Build.scene t (some 1)
        [subjectAt (10 * k) 10, agencyAt (30 + 10 * k) Build.east 10 redFlashingFront, bike] lanes [])
      [seen, Build.relation 1 3 (fun r => { r with visible := some true })]

/-- `occasion_s1` (violated): The subject approaches the moving vehicle from behind within the
    reach at the onset of the pass; once alongside past its centre (k = 14 on), the vehicle is no
    longer ahead, so the approach holds for part of the pass only; the pass is completed. -/
def occasion_s1Trace : Trace := basePass (fun _ => redFlashingFront) (fun _ => false)

/-- `occasion_s1_outside` (not_applicable): The subject approached the vehicle (k ≤ 4) while it
    stood with its lamp flashing and its driver's arm signalling (preparing to move), then
    halted 20 m behind it; while the subject stands at rest the vehicle, lamps flashing, backs past
    it (k = 17–22), so that relative to the subject it goes from ahead to behind. The subject was
    not moving at any observation of the act, so the approach held only before it began. -/
def occasion_s1_outsideTrace : Trace :=
  Build.trace 25 0 (Units.seconds 1) fun k t =>
    let s := if k ≤ 4 then subjectAt (10 * k) 10 else subjectAt 50 0
    let e := if k ≤ 16 then agencyAt 70 Build.east 0 redFlashingFront .left .off
             else Build.withKin (agencyAt (70 - 5 * (k - 16)) Build.east 5 redFlashingFront)
                    fun kin => { kin with velocity := some (Q.neg (mps 5), Q.zero) }
    sceneOf t s e

/-- `occasion_s3` (violated): The vehicle's red lamp flashes at the onset of the subject's pass and
    is switched off midway (from k = 14); the pass is completed. -/
def occasion_s3Trace : Trace :=
  basePass (fun k => if k ≤ 13 then redFlashingFront else []) (fun _ => false)

/-- `occasion_s3_outside` (not_applicable): The vehicle's lamp flashed while the subject approached
    (k ≤ 1) and was switched off long before the pass began, outside the window behind its
    recognition; it stays off throughout the pass. -/
def occasion_s3_outsideTrace : Trace :=
  basePass (fun k => if k ≤ 1 then redFlashingFront else []) (fun _ => false)

/-- `occasion_s7` (violated): The vehicle moves in the subject's direction at the onset of the pass
    and halts midway (at rest from k = 14); the subject completes the pass. -/
def occasion_s7Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    let e := if k ≤ 13 then agencyAt (70 + 10 * k) Build.east 10 redFlashingFront
             else agencyAt 200 Build.east 0 redFlashingFront
    sceneOf t (subjectAt (15 * k) 15) e

/-- `occasion_s7_outside` (not_applicable): The vehicle moved in the subject's direction long
    before (k ≤ 1), then halted on the roadway with its lamp flashing and visibly signalled with its
    driver's arm; it stays at rest throughout the subject's pass (k = 13, 14), which falls outside
    the window behind its last movement. -/
def occasion_s7_outsideTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    let e := if k == 0 then agencyAt 190 Build.east 10 redFlashingFront
             else if k == 1 then agencyAt 200 Build.east 10 redFlashingFront
             else agencyAt 200 Build.east 0 redFlashingFront .left .off
    sceneOf t (subjectAt (15 * k) 15) e

/-- `occasion_s6` (violated): A police officer directing traffic governs the subject's lane while the
    subject is alongside the vehicle (k = 13–15) only; the subject completes the pass (k = 16) where
    no officer governs. -/
def occasion_s6Trace : Trace :=
  basePass (fun _ => redFlashingFront) (fun k => 13 ≤ k && k ≤ 15)

/-- `occasion_s6_outside` (not_applicable): A police officer directing traffic governs the lane the
    subject occupies at every observation of the pass (from k = 13), and did not before it began;
    the officer waves the subject past. -/
def occasion_s6_outsideTrace : Trace :=
  basePass (fun _ => redFlashingFront) (fun k => 13 ≤ k)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (window : Option (Timestamp × Timestamp)) (absent : List String := [])
    (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_267_2d"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (some (11000, 19000))
  , witness "permit" permitTrace .compliant (some (11000, 19000))
  , witness "idle" idleTrace .notApplicable (some (11000, 19000))
  , witness "blind" blindTrace (.unknown []) (some (11000, 19000)) ["sig.warning_lamp"]
  , witness "branch_1" branch_1Trace .violated (some (11000, 19000))
  , witness "branch_2" branch_2Trace .notApplicable (some (11000, 19000))
  , witness "branch_3" branch_3Trace .notApplicable (some (11000, 19000))
  , witness "branch_4" branch_4Trace .violated (some (11000, 15000))
  , witness "branch_5" branch_5Trace .violated (some (11000, 15000))
  , witness "branch_6" branch_6Trace .compliant (some (13000, 19000))
  , witness "branch_7" branch_7Trace .compliant (some (11000, 19000))
  , witness "branch_8" branch_8Trace .compliant (some (11000, 19000))
  , witness "occasion_s1" occasion_s1Trace .violated (some (11000, 19000))
  , witness "occasion_s1_outside" occasion_s1_outsideTrace .notApplicable (some (16000, 24000))
  , witness "occasion_s3" occasion_s3Trace .violated (some (11000, 19000))
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .notApplicable (some (13000, 19000))
  , witness "occasion_s7" occasion_s7Trace .violated (some (11000, 19000))
  , witness "occasion_s7_outside" occasion_s7_outsideTrace .notApplicable (some (13000, 19000))
  , witness "occasion_s6" occasion_s6Trace .violated (some (11000, 19000))
  , witness "occasion_s6_outside" occasion_s6_outsideTrace .notApplicable (some (13000, 19000)) ]

end TrafficSpecWitness.NRS_484B_267_2d
