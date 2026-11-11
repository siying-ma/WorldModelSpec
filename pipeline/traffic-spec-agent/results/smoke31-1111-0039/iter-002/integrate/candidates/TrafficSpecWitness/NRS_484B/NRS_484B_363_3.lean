/-
  Witnesses for NRS_484B_363_3.

  The map: lane 1 (z's lane) is the rectangle x ∈ [0, 60], y ∈ [0, 8]; lane 2 lies beside it,
  x ∈ [0, 60], y ∈ [−8, 0]; lane 3 continues beyond z's stretch, x ∈ [60, 120], y ∈ [0, 8]; a
  sidewalk (4) runs along the north edge, y ∈ [8, 12]. Zone sign 10 (school, not an end sign)
  governs lane 1; speed limit beacon 11 governs the lane each scene names.

  The instants: 30 scenes one second apart (t = 0 … 29 s). x (track 1, a motor vehicle, 4 m × 2 m)
  yaws at 90 deg/s at k = 23, 24 and runs straight otherwise (heading east, north at 23, west from
  24), so its heading change over the 20 s window behind reaches 180° at k = 24 (90° at k = 23,
  outside the 30° tolerance): the U-turn is recognized at k = 24 and the act's observations are
  k = 23, 24. "The first part of the act" is k = 23, "the rest" k = 24, "before the act" k ≤ 22.
  The judged instants are 22 … 29 s, where every window behind is covered by the trace.

  The child (track 2, 0.4 m × 0.4 m) stands near at (30, 10), 1.8 m from lane 1 (reach 5 m), or
  far at (30, 40), 31.8 m from it. Zone sign 10's legend is unconditional (`some {}`), or, where a
  scene reads it, 07:00–08:00 on weekdays; the civil date is Monday 2026-11-09.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_363_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_363_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def laneA : Structure := Build.rect 1 .lane (m 0) (m 0) (m 60) (m 8)
def laneB : Structure := Build.rect 2 .lane (m 0) (m (-8)) (m 60) (m 0)
def laneC : Structure := Build.rect 3 .lane (m 60) (m 0) (m 120) (m 8)
def sidewalk : Structure := Build.rect 4 .sidewalk (m 0) (m 8) (m 120) (m 12)
def structures : List Structure := [laneA, laneB, laneC, sidewalk]

def onA : Vec := (m 30, m 4)
def onB : Vec := (m 30, m (-4))
def onC : Vec := (m 90, m 4)
def nearChild : Vec := (m 30, m 10)
def farChild : Vec := (m 30, m 40)

/-- x's yaw rate: 90 deg/s at k = 23, 24, a half turn in two seconds (the rate at a scene is held
    over the interval before it, so the heading is east to k = 22, north at 23, west from 24). -/
def yaw (k : Nat) : Q := if 23 ≤ k ∧ k ≤ 24 then Units.degrees 90 else Q.zero

def heading (k : Nat) : Vec := if k ≤ 22 then Build.east else if k = 23 then Build.north else Build.west

def vehicle (k : Nat) (pos : Vec) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos (heading k) (Units.metresPerSecond 3) (m 2, m 1, m 1))
    (fun kn => { kn with yawRate := some (yaw k) })

def child (pos : Vec) : RoadUser :=
  Build.user 2 [.pedestrian, .child] pos Build.north Q.zero (cm 20, cm 20, cm 60)

/-- Zone sign 10 with an unconditional legend. -/
def zone : Device := Build.zoneSign 10 [1] .school false (some {})

/-- Zone sign 10 whose legend reads 07:00–08:00 on weekdays. -/
def zoneTimed : Device :=
  Build.zoneSign 10 [1] .school false
    (some { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 420, endMinute := 480 }] })

def beacon (governs : List RegionId) (flashing : Bool) : Device :=
  { Build.device 11 .speedLimitBeacon governs with flashing := some flashing }

def asms (notInSession outsideMargin pupilsInClass : Bool) : List (AsmId × Bool) :=
  [ ("asm.school_not_in_session_day", notInSession)
  , ("asm.outside_school_operation_margin", outsideMargin)
  , ("asm.pupils_in_class", pupilsInClass) ]

def civil (minute : Nat) : Env :=
  { civilTime := some { year := 2026, month := 11, day := 9, weekday := 0, minuteOfDay := minute } }

/-- A U-turn scene sequence: where x is, where the child is, the devices, the declarations and the
    minute of the day, each by the scene index. -/
def uTurnTrace (pos : Nat → Vec) (childAt : Nat → Option Vec) (devs : Nat → List Device)
    (decl : Nat → List (AsmId × Bool)) (minute : Nat → Nat := fun _ => 450) : Trace :=
  Build.trace 30 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (match childAt k with
       | some p => [vehicle k (pos k), child p]
       | none => [vehicle k (pos k)])
      structures (devs k) (env := civil (minute k)) (assumptions := decl k)

def alwaysA : Nat → Vec := fun _ => onA
def childNear : Nat → Option Vec := fun _ => some nearChild
def zoneFlashing : Nat → List Device := fun _ => [zone, beacon [1] true]
def noException : Nat → List (AsmId × Bool) := fun _ => asms false false false

/-- `forbid` (violated): x (ru.motor_vehicle) makes a U-turn on a lane governed by a school zone sign z; a ru.child stands within p.child_presence_reach of z's lane at every observation, asm.school_not_in_session_day and asm.outside_school_operation_margin are declared false, and a speed limit beacon governing the lane is flashing. -/
def forbidTrace : Trace := uTurnTrace alwaysA childNear zoneFlashing noException

/-- `permit` (compliant): x makes a U-turn on z's lane while no ru.child lies within p.child_presence_reach of any region z governs at any observation of the act. -/
def permitTrace : Trace := uTurnTrace alwaysA (fun _ => some farChild) zoneFlashing noException

/-- `idle` (not_applicable): x makes a U-turn on a street no school zone or school crossing zone sign governs. -/
def idleTrace : Trace := uTurnTrace alwaysA childNear (fun _ => [beacon [1] true]) noException

/-- `blind` (unknown): x drives along z's lane with children on the sidewalk and turns about, but its yaw rate is missing, so whether a U-turn was made is unknown. -/
def blindTrace : Trace := uTurnTrace alwaysA childNear zoneFlashing noException

/-- `occasion_d3` (violated): Baseline as in forbid (children present, school in session, inside the operation margin, beacon flashing): x begins its U-turn on z's lane and completes it on a lane beyond the stretch z governs; it occupied z's lane for part of the act only. -/
def occasion_d3Trace : Trace :=
  uTurnTrace (fun k => if k ≤ 23 then onA else onC) childNear zoneFlashing noException

/-- `occasion_d3_outside` (not_applicable): x drove along z's lane, left the governed stretch, and only afterwards, on a lane no zone sign governs, makes its U-turn: it was in the zone before the act began only. -/
def occasion_d3_outsideTrace : Trace :=
  uTurnTrace (fun k => if k ≤ 15 then onA else onC) childNear zoneFlashing noException

/-- `occasion_d5` (violated): U-turn on z's lane; no ru.child is within p.child_presence_reach at the first observations of the act, then a child walks up beside the lane before the act is recognized; the other alternatives fail throughout. -/
def occasion_d5Trace : Trace :=
  uTurnTrace alwaysA (fun k => some (if k ≤ 23 then farChild else nearChild)) zoneFlashing noException

/-- `occasion_d5_outside` (compliant): Children stood beside z's lane before the act began and left; at every observation of the U-turn none lies within p.child_presence_reach; the other alternatives fail. -/
def occasion_d5_outsideTrace : Trace :=
  uTurnTrace alwaysA (fun k => some (if k ≤ 22 then nearChild else farChild)) zoneFlashing noException

/-- `occasion_d8` (violated): A beacon governs the region x occupies at the start of the U-turn only; x ends the turn on a region no beacon governs; asm.pupils_in_class holds and the beacon is not flashing; z's conditions hold; children present, school in session, inside the margin: neither (d) nor (e) covers the whole act. -/
def occasion_d8Trace : Trace :=
  uTurnTrace (fun k => if k ≤ 23 then onB else onA) childNear (fun _ => [zone, beacon [2] false])
    (fun _ => asms false false true)

/-- `occasion_d8_outside` (compliant): No beacon governs the region x occupied before the act; a non-flashing beacon governs every region x occupies during the U-turn and asm.pupils_in_class holds throughout it; children present. -/
def occasion_d8_outsideTrace : Trace :=
  uTurnTrace (fun k => if k ≤ 22 then onC else onA) childNear (fun _ => [zone, beacon [1] false])
    (fun _ => asms false false true)

/-- `occasion_d10` (violated): A beacon governs z's lane and asm.pupils_in_class holds throughout; the beacon is not flashing for the first part of the U-turn and flashing for the rest; children present. -/
def occasion_d10Trace : Trace :=
  uTurnTrace alwaysA childNear (fun k => [zone, beacon [1] (decide (24 ≤ k))])
    (fun _ => asms false false true)

/-- `occasion_d10_outside` (compliant): A beacon governs z's lane and asm.pupils_in_class holds throughout; the beacon was flashing before the act and is not flashing at any observation of the U-turn; children present. -/
def occasion_d10_outsideTrace : Trace :=
  uTurnTrace alwaysA childNear (fun k => [zone, beacon [1] (decide (k ≤ 22))])
    (fun _ => asms false false true)

/-- `occasion_d12` (violated): No beacon governs the region x occupies at the start of the U-turn, a flashing beacon governs the region it ends on; z's conditions do not hold throughout; children present, school in session, inside the margin. -/
def occasion_d12Trace : Trace :=
  uTurnTrace (fun k => if k ≤ 23 then onA else onC) childNear (fun _ => [zoneTimed, beacon [3] true])
    noException (fun _ => 600)

/-- `occasion_d12_outside` (compliant): A beacon governed the region x occupied before the act; no beacon governs any region x occupies or z governs during the U-turn; z's conditions do not hold throughout; children present. -/
def occasion_d12_outsideTrace : Trace :=
  uTurnTrace (fun k => if k ≤ 22 then onC else onA) childNear (fun _ => [zoneTimed, beacon [3] true])
    noException (fun _ => 600)

/-- `occasion_d13` (violated): No beacon; env.civil_time leaves z's posted window during the U-turn, so z's conditions do not hold for the first part of the act and hold for the rest; children present, school in session, inside the margin. -/
def occasion_d13Trace : Trace :=
  uTurnTrace alwaysA childNear (fun _ => [zoneTimed]) noException (fun k => if k ≤ 23 then 419 else 420)

/-- `occasion_d13_outside` (compliant): No beacon; z's conditions held before the act and do not hold at any observation of the U-turn; children present. -/
def occasion_d13_outsideTrace : Trace :=
  uTurnTrace alwaysA childNear (fun _ => [zoneTimed]) noException (fun k => if k ≤ 22 then 479 else 480)

/-- `branch_1` (compliant): x makes a U-turn on z's lane with children present while asm.school_not_in_session_day is declared true at every observation of the act. -/
def branch_1Trace : Trace :=
  uTurnTrace alwaysA childNear zoneFlashing (fun _ => asms true false false)

/-- `branch_2` (compliant): as forbid, but asm.outside_school_operation_margin is declared true at every observation of the act (exception (c)). -/
def branch_2Trace : Trace :=
  uTurnTrace alwaysA childNear zoneFlashing (fun _ => asms false true false)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_363_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (22000, 29000)   -- the instants whose look-back windows the trace covers
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "occasion_d3" occasion_d3Trace .violated
  , witness "occasion_d3_outside" occasion_d3_outsideTrace .notApplicable
  , witness "occasion_d5" occasion_d5Trace .violated
  , witness "occasion_d5_outside" occasion_d5_outsideTrace .compliant
  , witness "occasion_d8" occasion_d8Trace .violated
  , witness "occasion_d8_outside" occasion_d8_outsideTrace .compliant
  , witness "occasion_d10" occasion_d10Trace .violated
  , witness "occasion_d10_outside" occasion_d10_outsideTrace .compliant
  , witness "occasion_d12" occasion_d12Trace .violated
  , witness "occasion_d12_outside" occasion_d12_outsideTrace .compliant
  , witness "occasion_d13" occasion_d13Trace .violated
  , witness "occasion_d13_outside" occasion_d13_outsideTrace .compliant
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_363_3
