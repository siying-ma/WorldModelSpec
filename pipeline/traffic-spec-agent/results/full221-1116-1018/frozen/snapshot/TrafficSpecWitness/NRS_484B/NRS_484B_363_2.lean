/-
  Witnesses for NRS_484B_363_2.

  Geometry: an eastbound lane 10 (x 0–300 m, y 0–4 m) and, where a scene needs a second region,
  a parallel lane 11 (y 4–8 m). The subject, track 1, a motor vehicle (half extents 2 m × 1 m ×
  0.75 m), runs along y = 2 from x = 50 m, three observations 1 s apart. Speeding scenes run at
  15 m/s (≈ 33.6 mph, well above 25 mph = 11.176 m/s); the permit scene at 8 m/s (≈ 17.9 mph).
  The school crossing zone sign (device 20) governs lane 10 with a legend window Monday–Friday
  07:00–16:00; the civil time is Monday 07:30 (inside the window), or 18:00 where the window must
  fail. Beacons are devices 30/31. Every scene declares the three assumptions.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_363_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_363_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def fast : Q := Units.metresPerSecond 15
def slow : Q := Units.metresPerSecond 8

def laneA : Structure :=
  Build.lane 10 [(m 0, m 0), (m 300, m 0), (m 300, m 4), (m 0, m 4)] Build.east
def laneB : Structure :=
  Build.lane 11 [(m 0, m 4), (m 300, m 4), (m 300, m 8), (m 0, m 8)] Build.east

def schoolHours : Conditions :=
  { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 420, endMinute := 960 }] }

def crossingSign (governs : List RegionId) (isEnd : Bool := false) : Device :=
  Build.zoneSign 20 governs .schoolCrossing isEnd (some schoolHours)

def schoolSign (governs : List RegionId) : Device :=
  Build.zoneSign 21 governs .school false (some schoolHours)

def beacon (id : DeviceId) (governs : List RegionId) (flashing inoperative : Bool) : Device :=
  { Build.device id .speedLimitBeacon governs with
      flashing := some flashing, inoperative := some inoperative }

def civil (minute : Nat) : Env :=
  { civilTime := some { year := 2026, month := 11, day := 16, weekday := 0, minuteOfDay := minute } }

def asms (inSession outsideMargin inClass : Bool) : List (AsmId × Bool) :=
  [ ("asm.school_in_session_day", inSession)
  , ("asm.school_outside_operation_margin", outsideMargin)
  , ("asm.pupils_in_class", inClass) ]

def subjectAt (k : Nat) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (Q.add (m 50) (Q.mul speed (m k)), m 2) Build.east speed (m 2, m 1, cm 75)

/-- A three-observation trace of the subject on lane 10 with the given devices and declarations. -/
def mk (speed : Q) (structures : List Structure) (devices : List Device)
    (minute : Nat := 450) (decl : List (AsmId × Bool) := asms true false true) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt k speed] structures devices (env := civil minute) (assumptions := decl)

/-- `forbid` (violated): A motor vehicle's footprint overlaps a lane governed by a dev.zone_sign of kind school_crossing (not an end sign) whose conditions hold now; asm.school_in_session_day true, asm.school_outside_operation_margin false; no dev.speed_limit_beacon governs the lane; kin.speed is well above the stated 25 miles per hour. -/
def forbidTrace : Trace := mk fast [laneA] [crossingSign [10]]

/-- `permit` (compliant): Same zone and declarations as forbid; kin.speed is below the stated 25 miles per hour at every observation. -/
def permitTrace : Trace := mk slow [laneA] [crossingSign [10]]

/-- `idle` (not_applicable): The motor vehicle travels above the stated figure on a lane that no dev.zone_sign of kind school_crossing governs
    (lane 10 carries a school-kind sign only; the school crossing sign governs lane 11, which the subject does not occupy). -/
def idleTrace : Trace := mk fast [laneA, laneB] [schoolSign [10], crossingSign [11]]

/-- `blind` (unknown): Same zone and declarations as forbid, but the source declares kin.speed absent. -/
def blindTrace : Trace := mk fast [laneA] [crossingSign [10]]

/-- `branch_1` (not_applicable): A dev.speed_limit_beacon that is not inoperative governs the zone's lane; asm.pupils_in_class true; the beacon is not flashing; the motor vehicle exceeds the stated figure: exception (c) holds. -/
def branch_1Trace : Trace := mk fast [laneA] [crossingSign [10], beacon 30 [10] false false]

/-- `branch_2` (violated): Same as branch_1 but the beacon is flashing: exceptions (c) and (d) fail; the motor vehicle exceeds the stated figure. -/
def branch_2Trace : Trace := mk fast [laneA] [crossingSign [10], beacon 30 [10] true false]

/-- `branch_3` (not_applicable): No beacon governs the zone's lane; prim.conditions_hold is false for the school crossing zone sign; the motor vehicle exceeds the stated figure: exception (d) holds (18:00, outside the legend's window). -/
def branch_3Trace : Trace := mk fast [laneA] [crossingSign [10]] (minute := 1080)

/-- `branch_4` (not_applicable): asm.school_outside_operation_margin true; the motor vehicle exceeds the stated figure in the zone: exception (b) holds. -/
def branch_4Trace : Trace := mk fast [laneA] [crossingSign [10]] (decl := asms true true true)

/-- `branch_5` (not_applicable): school not in session that day; speeding in the zone: exception (a) holds. -/
def branch_5Trace : Trace := mk fast [laneA] [crossingSign [10]] (decl := asms false false true)

/-- `branch_6` (violated): operational beacon not flashing, but pupils not in class: (c) fails, and (d) fails for the beacon. -/
def branch_6Trace : Trace :=
  mk fast [laneA] [crossingSign [10], beacon 30 [10] false false] (decl := asms true false false)

/-- `branch_7` (violated): the only beacon is inoperative, the sign's conditions hold: (c) and (d) fail. -/
def branch_7Trace : Trace := mk fast [laneA] [crossingSign [10], beacon 30 [10] false true]

/-- `branch_8` (not_applicable): the school crossing sign governing the lane is an end sign. -/
def branch_8Trace : Trace := mk fast [laneA] [crossingSign [10] (isEnd := true)]

/-- `branch_9` (not_applicable): a flashing beacon governs only the other lane; the zone's operational beacon is dark: (c) holds. -/
def branch_9Trace : Trace :=
  mk fast [laneA, laneB] [crossingSign [10], beacon 30 [10] false false, beacon 31 [11] true false]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_363_2"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_363_2
