/-
  Witnesses for NRS_484B_363_4.

  The carriageway: four eastbound lanes along x, the right lane y ∈ [0, 4], the left lane
  y ∈ [4, 8]; lanes 10 (right) and 11 (left) run from x = -50 to `zoneEnd`, lanes 12 (right) and
  13 (left) from `zoneEnd` to x = 400. Zone sign 100 governs all four lanes, or only 10 and 11
  where the scenario places the zone's end. Its legend: weekdays 07:00–16:00. Beacon 101, where
  present, governs all four lanes.

  The bodies: half-length 2 m, half-width 1 m. The subject (track 1) drives in the left lane
  (y = 6), b (track 2) in the right lane (y = 2), both heading east.

  The instants: one scene a second, t = 0 … 19 s. Up to t = 11 s both are at rest, the subject at
  x = 0 and b at x = 25 (the trace's history: no pass can be under way while the subject is at
  rest). From t = 12 s the subject moves at 10 m/s (x = 10, 20, …) and b at 5 m/s (x = 30, 35, …):
  b is ahead with a clear gap at t = 12 … 15 s (gaps 16, 11, 6, 1 m), alongside at t = 16 s, and
  behind with a 1 m gap at t = 17 s, where the pass is recognized. Judged instants: t = 12 … 19 s,
  so every 10 s window behind is covered.

  Civil time: Tuesday 2026-11-17, 08:00 where the sign's conditions hold, 18:00 where they do not.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_363_4
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_363_4

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- What varies between the scenarios. `beacon k` is `(inoperative, flashing)` of beacon 101. -/
structure Cfg where
  zoneKind : ZoneKind := .schoolCrossing
  zoneIsEnd : Bool := false
  zoneEnd : Int := 300
  zoneOnSignedLanesOnly : Bool := false
  withOther : Bool := true
  otherAtRest : Bool := false
  beacon : Option (Nat → Bool × Bool) := none
  condsHold : Nat → Bool := fun _ => true
  pupils : Bool := true

def body : Q × Q × Q := (m 2, m 1, m 1)

def subjectX (k : Nat) : Int := if k ≤ 11 then 0 else 10 * ((k : Int) - 11)
def subjectSpeed (k : Nat) : Q := if k ≤ 11 then Q.zero else Units.metresPerSecond 10

def otherX (c : Cfg) (k : Nat) : Int :=
  if c.otherAtRest then 50 else if k ≤ 11 then 25 else 25 + 5 * ((k : Int) - 11)
def otherSpeed (c : Cfg) (k : Nat) : Q :=
  if c.otherAtRest || k ≤ 11 then Q.zero else Units.metresPerSecond 5

def users (c : Cfg) (k : Nat) : List RoadUser :=
  [Build.user 1 [.motorVehicle] (m (subjectX k), m 6) Build.east (subjectSpeed k) body]
  ++ (if c.withOther then
        [Build.user 2 [.motorVehicle] (m (otherX c k), m 2) Build.east (otherSpeed c k) body]
      else [])

def laneBox (id : RegionId) (x0 x1 y0 y1 : Int) : Structure :=
  Build.lane id [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)] Build.east

def structures (c : Cfg) : List Structure :=
  [ laneBox 10 (-50) c.zoneEnd 0 4, laneBox 11 (-50) c.zoneEnd 4 8
  , laneBox 12 c.zoneEnd 400 0 4, laneBox 13 c.zoneEnd 400 4 8 ]

def legend : Conditions :=
  { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 420, endMinute := 960 }] }

def devices (c : Cfg) (k : Nat) : List Device :=
  let govs : List RegionId := if c.zoneOnSignedLanesOnly then [10, 11] else [10, 11, 12, 13]
  [Build.zoneSign 100 govs c.zoneKind c.zoneIsEnd (some legend)]
  ++ (match c.beacon with
      | none => []
      | some f =>
        let (inop, fl) := f k
        [{ Build.device 101 .speedLimitBeacon [10, 11, 12, 13] with
            inoperative := some inop, flashing := some fl }])

def civil (c : Cfg) (k : Nat) : CivilTime :=
  { year := 2026, month := 11, day := 17, weekday := 1
    minuteOfDay := if c.condsHold k then 480 else 1080 }

def asms (c : Cfg) : List (AsmId × Bool) :=
  [ ("asm.school_in_session_day", true)
  , ("asm.school_outside_operation_margin", false)
  , ("asm.pupils_in_class", c.pupils) ]

def traceOf (c : Cfg) : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (users c k) (structures c) (devices c k)
      (env := { civilTime := some (civil c k) }) (assumptions := asms c)

/-- `forbid` (violated): The subject vehicle, on a lane governed by a dev.zone_sign of kind school_crossing (not an end sign, conditions holding), comes up behind another moving vehicle with aligned headings and comes to have it behind (rel.bearing longitudinal negative, no overlap); asm.school_in_session_day true, asm.school_outside_operation_margin false; no beacon governs the lane. -/
def forbidTrace : Trace := traceOf {}

/-- `permit` (compliant): Same zone and declarations as forbid; the subject is the only vehicle in the scene and travels through the zone: no pass is recognized. -/
def permitTrace : Trace := traceOf { withOther := false }

/-- `idle` (not_applicable): The subject passes another moving vehicle on a street no dev.zone_sign of kind school or school_crossing governs (the lanes' zone sign is a speed zone sign). -/
def idleTrace : Trace := traceOf { zoneKind := .speedZone }

/-- `blind` (unknown): Same as forbid, but the source declares rel.bearing absent, so the pass is not decided. -/
def blindTrace : Trace := traceOf {}
-- Core computes rel.bearing from kin.position and kin.heading (Atoms.rel_bearing), and the mask of
-- rel.bearing drops only a measured value; the pass concept reads those same kinematics. On this
-- trace, as on any whose kinematics are observed, the mask therefore decides nothing: see
-- task_result.md.

/-- `branch_1` (not_applicable): Same as forbid, but the other vehicle is at rest (kin.speed at or below the halt tolerance) at every observation while the pass is under way: it is not a vehicle traveling. -/
def branch_1Trace : Trace := traceOf { otherAtRest := true }

/-- `branch_2` (not_applicable): No beacon governs the zone's lane; prim.conditions_hold is false for the zone sign throughout the pass: exception (d) holds. -/
def branch_2Trace : Trace := traceOf { condsHold := fun _ => false }

/-- `branch_3` (not_applicable): An operational beacon governs the zone's lane and is not flashing; asm.pupils_in_class true throughout the pass: exception (c) holds. -/
def branch_3Trace : Trace :=
  traceOf { zoneKind := .school, beacon := some fun _ => (false, false) }

/-- `branch_4` (violated): An operational beacon governs the zone's lane and is not flashing, but the pupils are not in class (asm.pupils_in_class false) and the sign's conditions hold: neither (c) nor (d) holds. -/
def branch_4Trace : Trace :=
  traceOf { beacon := some fun _ => (false, false), pupils := false }

/-- `occasion_s3` (violated): The pass begins while the subject's footprint overlaps a lane the school zone sign governs (up to x = 45, left at t = 16 s) and is recognized after the subject has left the zone; no exception holds. -/
def occasion_s3Trace : Trace :=
  traceOf { zoneKind := .school, zoneEnd := 45, zoneOnSignedLanesOnly := true }

/-- `occasion_s3_outside` (not_applicable): The subject occupies the zone's lane (up to x = 5) only while at rest, before the pass begins, leaves the zone, and the whole pass takes place on regions no zone sign governs. -/
def occasion_s3_outsideTrace : Trace :=
  traceOf { zoneKind := .school, zoneEnd := 5, zoneOnSignedLanesOnly := true }

/-- `occasion_s7` (violated): A beacon governing the lane, not flashing, with asm.pupils_in_class true, is operational at the first observations of the pass (to t = 14 s) and inoperative at the later ones, while the zone sign's conditions hold: neither (c) nor (d) holds throughout. -/
def occasion_s7Trace : Trace :=
  traceOf { beacon := some fun k => (decide (k ≥ 15), false) }

/-- `occasion_s7_outside` (not_applicable): The beacon is inoperative before the pass begins (to t = 11 s) and operational, not flashing, at every observation while it is under way, with asm.pupils_in_class true: exception (c) holds throughout. -/
def occasion_s7_outsideTrace : Trace :=
  traceOf { beacon := some fun k => (decide (k ≤ 11), false) }

/-- `occasion_s9` (violated): An operational beacon governs the lane with asm.pupils_in_class true; it is not flashing at the first observations of the pass (to t = 14 s) and flashing at the later ones; no other exception holds. -/
def occasion_s9Trace : Trace :=
  traceOf { beacon := some fun k => (false, decide (k ≥ 15)) }

/-- `occasion_s9_outside` (not_applicable): The operational beacon is flashing before the pass begins (to t = 11 s) and not flashing at every observation while it is under way, with asm.pupils_in_class true: exception (c) holds throughout. -/
def occasion_s9_outsideTrace : Trace :=
  traceOf { beacon := some fun k => (false, decide (k ≤ 11)) }

/-- `occasion_s10` (violated): The beacon governing the lane is inoperative at the first observations of the pass (to t = 14 s) and operational and flashing at the later ones; the zone sign's conditions do not hold throughout: neither (c) nor (d) holds throughout. -/
def occasion_s10Trace : Trace :=
  traceOf { beacon := some fun k => (decide (k ≤ 14), decide (k ≥ 15)), condsHold := fun _ => false }

/-- `occasion_s10_outside` (not_applicable): The beacon governing the lane is operational before the pass begins (to t = 11 s) and inoperative at every observation while it is under way; prim.conditions_hold is false for the zone sign throughout: exception (d) holds throughout. -/
def occasion_s10_outsideTrace : Trace :=
  traceOf { beacon := some fun k => (decide (k ≥ 12), decide (k ≤ 11)), condsHold := fun _ => false }

/-- `occasion_s11` (violated): No beacon governs the lane; prim.conditions_hold for the zone sign is false at the first observations of the pass (to t = 14 s) and true at the later ones. -/
def occasion_s11Trace : Trace :=
  traceOf { condsHold := fun k => decide (k ≥ 15) }

/-- `occasion_s11_outside` (not_applicable): No beacon governs the lane; prim.conditions_hold is true before the pass begins (to t = 11 s) and false at every observation while it is under way: exception (d) holds throughout. -/
def occasion_s11_outsideTrace : Trace :=
  traceOf { condsHold := fun k => decide (k ≤ 11) }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_363_4"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (12000, 19000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .notApplicable
  , witness "occasion_s7" occasion_s7Trace .violated
  , witness "occasion_s7_outside" occasion_s7_outsideTrace .notApplicable
  , witness "occasion_s9" occasion_s9Trace .violated
  , witness "occasion_s9_outside" occasion_s9_outsideTrace .notApplicable
  , witness "occasion_s10" occasion_s10Trace .violated
  , witness "occasion_s10_outside" occasion_s10_outsideTrace .notApplicable
  , witness "occasion_s11" occasion_s11Trace .violated
  , witness "occasion_s11_outside" occasion_s11_outsideTrace .notApplicable ]

end TrafficSpecWitness.NRS_484B_363_4
