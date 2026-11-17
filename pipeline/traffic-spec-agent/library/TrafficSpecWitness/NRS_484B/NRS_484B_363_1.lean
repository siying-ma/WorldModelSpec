/-
  Witnesses for NRS_484B_363_1.

  Geometry: lane 100 is the rectangle (0,-2)–(200,2), traffic eastbound; lane 200 is another
  street, (0,20)–(200,24). The subject (track 1) is a motor vehicle, half-extent 2 m × 0.9 m ×
  0.75 m, driving east along y = 0 from x = 50, three observations 1 s apart. Fast is 30 mph
  (twice the stated figure), slow is 8 mph.
  Devices: zone sign 10 (kind school, not an end sign) whose legend reads Monday–Friday
  07:00–17:00; speed limit beacon 20 where a scene has one. Civil time is Wednesday 2026-11-18,
  08:00 (inside the posted window) or 20:00 (outside it). Every figure here is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_363_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_363_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def fast : Q := Units.mph 30
def slow : Q := Units.mph 8

def lane1 : Structure := Build.rect 100 .lane (m 0) (m (-2)) (m 200) (m 2)
def lane2 : Structure := Build.rect 200 .lane (m 0) (m 20) (m 200) (m 24)

def car (k : Nat) (v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (50 + 13 * (k : Int)), m 0) Build.east v (m 2, cm 90, cm 75)

def schoolHours : Conditions :=
  { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 420, endMinute := 1020 }] }

def zone (governs : List RegionId) (kind : ZoneKind := .school) (isEnd : Bool := false) : Device :=
  Build.zoneSign 10 governs kind isEnd (some schoolHours)

def beacon (flashing inoperative : Bool) : Device :=
  { Build.device 20 .speedLimitBeacon [100] with flashing := some flashing, inoperative := some inoperative }

def morning : Env := { civilTime := some { year := 2026, month := 11, day := 18, weekday := 2, minuteOfDay := 480 } }
def evening : Env := { civilTime := some { year := 2026, month := 11, day := 18, weekday := 2, minuteOfDay := 1200 } }

def asms (inSession outside pupils : Bool) : List (AsmId × Bool) :=
  [("asm.school_in_session_day", inSession), ("asm.school_outside_operation_margin", outside),
   ("asm.pupils_in_class", pupils)]

/-- A three-observation scene sequence on lane 100. -/
def run (v : Q) (devices : List Device) (env : Env) (as : List (AsmId × Bool)) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k v] [lane1, lane2] devices (env := env) (assumptions := as)

/-- `forbid` (violated): A motor vehicle's footprint overlaps a lane governed by a dev.zone_sign of kind school (not an end sign) whose conditions hold now; asm.school_in_session_day true, asm.school_outside_operation_margin false; no dev.speed_limit_beacon governs the lane; kin.speed is well above the stated 15 miles per hour. -/
def forbidTrace : Trace := run fast [zone [100]] morning (asms true false true)

/-- `permit` (compliant): Same zone and declarations as forbid; kin.speed is below the stated 15 miles per hour at every observation. -/
def permitTrace : Trace := run slow [zone [100]] morning (asms true false true)

/-- `idle` (not_applicable): The motor vehicle travels well above the stated figure on a lane that no dev.zone_sign of kind school governs; the only zone sign nearby governs another street. -/
def idleTrace : Trace := run fast [zone [200]] morning (asms true false true)

/-- `blind` (unknown): Same zone and declarations as forbid, but the source declares kin.speed absent. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.speed"]) (run fast [zone [100]] morning (asms true false true))

/-- `branch_1` (not_applicable): A dev.speed_limit_beacon that is not inoperative governs the zone's lane; asm.pupils_in_class true; the beacon's flashing attribute is false; asm.school_in_session_day true and asm.school_outside_operation_margin false; the motor vehicle exceeds the stated figure: exception (c) holds. -/
def branch_1Trace : Trace := run fast [zone [100], beacon false false] morning (asms true false true)

/-- `branch_2` (violated): Same as branch_1 but the beacon is flashing: exception (c) fails, exception (d) fails because an operational beacon designates the zone; the motor vehicle exceeds the stated figure.
    The time lies outside the sign's posted window, so only the operational beacon defeats (d). -/
def branch_2Trace : Trace := run fast [zone [100], beacon true false] evening (asms true false true)

/-- `branch_3` (not_applicable): No beacon governs the zone's lane; prim.conditions_hold is false for the school zone sign (the time lies outside its posted window); the motor vehicle exceeds the stated figure: exception (d) holds. -/
def branch_3Trace : Trace := run fast [zone [100]] evening (asms true false true)

/-- `branch_4` (not_applicable): asm.school_in_session_day false (a day school is not in session); the motor vehicle exceeds the stated figure in the zone: exception (a) holds. -/
def branch_4Trace : Trace := run fast [zone [100]] morning (asms false false true)

/-- `branch_5` (not_applicable): as forbid, but asm.school_outside_operation_margin true: exception (b) holds. -/
def branch_5Trace : Trace := run fast [zone [100]] morning (asms true true true)

/-- `branch_6` (violated): as branch_1 (operational beacon, not flashing) but asm.pupils_in_class false: exception (c) fails, (d) fails. -/
def branch_6Trace : Trace := run fast [zone [100], beacon false false] morning (asms true false false)

/-- `branch_7` (not_applicable): as branch_2 but the beacon is inoperative (and dark): no operational beacon designates the zone, the time lies outside the posted window: exception (d) holds. -/
def branch_7Trace : Trace := run fast [zone [100], beacon false true] evening (asms true false true)

/-- `branch_8` (violated): an inoperative beacon governs the lane, the time lies inside the posted window, pupils in class: (c) fails for want of an operational beacon, (d) fails because the sign's conditions hold. -/
def branch_8Trace : Trace := run fast [zone [100], beacon false true] morning (asms true false true)

/-- `branch_9` (not_applicable): as forbid, but the zone sign governing the lane is an end sign. -/
def branch_9Trace : Trace := run fast [zone [100] .school true] morning (asms true false true)

/-- `branch_10` (not_applicable): as forbid, but the zone sign governing the lane is of kind speed_zone. -/
def branch_10Trace : Trace := run fast [zone [100] .speedZone false] morning (asms true false true)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_363_1"
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
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_363_1
