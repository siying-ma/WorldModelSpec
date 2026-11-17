/-
  Witnesses for NRS_484B_490.

  Geometry (witness-only figures): two eastbound lanes side by side, lane 10 (y 0..4 m) and
  lane 11 (y 4..8 m), each x 0..2000 m. The subject (track 1) drives along y = 2 m in lane 10
  (half-extent 2.5 × 1 × 0.75 m), so it occupies lane 10 only. Device 100 is a zone sign.
  Observations every 10 s from t = 0 (well within half of the 180 s parking window).

  forbid: moves at 5 m/s for k = 0, 1, then stands (speed 0) at x = 200 m from t = 20 s to
    t = 240 s; the instants judged are t = 200..240 s, where the 180 s window behind is all at rest
    (halt of 180..220 s ≥ 180 s by a 20 s margin at the end of the window). Sign: narrow_highway,
    governs lane 10, conditions `some {}` (unconditional).
  permit: drives at 5 m/s, stands 20 s (t = 200..220 s) at x = 1100 m, drives on; instants judged
    t = 200..290 s, every 180 s window behind holds a moving sample.
  idle: as forbid, but the narrow_highway sign governs lane 11, which the subject does not occupy.
  blind: as forbid, but the sign's governed regions are unobserved (dev.governs masked).
  branch_1 (not_applicable): as forbid, but the zone sign is of kind parking_restricted.
  branch_2 (not_applicable): as forbid, but the narrow_highway sign's legend restricts it to
    Monday–Friday 07:00–09:00 and the civil time is Saturday 12:00, so its conditions do not hold.
  branch_3 (not_applicable): as forbid, but the subject is a pedestrian, no member of the vehicle
    aggregate.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_490
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_490

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def lanes : List Structure :=
  [ Build.rect 10 .lane (m 0) (m 0) (m 2000) (m 4)
  , Build.rect 11 .lane (m 0) (m 4) (m 2000) (m 8) ]

def body : Q × Q × Q := (cm 250, cm 100, cm 75)

/-- The subject at x, eastbound, at the given speed. -/
def subjectAt (classes : List RoadUserClass) (x : Q) (v : Q) : RoadUser :=
  Build.user 1 classes (x, m 2) Build.east v body

/-- Arrives at x = 200 m at t = 20 s and stands there. -/
def standingAt (classes : List RoadUserClass) (k : Nat) : RoadUser :=
  if k < 2 then subjectAt classes (m (100 + 50 * (Int.ofNat k))) (Units.metresPerSecond 5)
  else subjectAt classes (m 200) Q.zero

def standingTrace (classes : List RoadUserClass) (sign : Device) (env : Env := {}) : Trace :=
  Build.trace 25 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1) [standingAt classes k] lanes [sign] (env := env)

def narrowSign (governs : List RegionId) : Device :=
  Build.zoneSign 100 governs .narrowHighway false (some {})

/-- `forbid` (violated): A vehicle that drove into a lane governed by a narrow_highway zone sign with an empty conditions set has stood there (kin.speed 0) for 200 s. -/
def forbidTrace : Trace := standingTrace [.motorVehicle] (narrowSign [10])

/-- `permit` (compliant): The same vehicle halts 20 s in the governed lane and drives on. -/
def permitTrace : Trace :=
  Build.trace 30 0 (Units.seconds 10) fun k t =>
    let u :=
      if k < 20 then subjectAt [.motorVehicle] (m (100 + 50 * (Int.ofNat k))) (Units.metresPerSecond 5)
      else if k ≤ 22 then subjectAt [.motorVehicle] (m 1100) Q.zero
      else subjectAt [.motorVehicle] (m (1100 + 50 * (Int.ofNat k - 22))) (Units.metresPerSecond 5)
    Build.scene t (some 1) [u] lanes [narrowSign [10]]

/-- `idle` (not_applicable): The vehicle stands 200 s in a lane no narrow_highway zone sign governs. -/
def idleTrace : Trace := standingTrace [.motorVehicle] (narrowSign [11])

/-- `blind` (unknown): As in forbid, but the source does not observe which regions the devices govern. -/
def blindTrace : Trace :=
  standingTrace [.motorVehicle] { narrowSign [] with governsObserved := false }

/-- `branch_1` (not_applicable): the zone sign governing the lane is of kind parking_restricted. -/
def branch1Trace : Trace :=
  standingTrace [.motorVehicle] (Build.zoneSign 100 [10] .parkingRestricted false (some {}))

/-- `branch_2` (not_applicable): the narrow_highway sign applies Mon–Fri 07:00–09:00; it is Saturday noon. -/
def branch2Trace : Trace :=
  standingTrace [.motorVehicle]
    (Build.zoneSign 100 [10] .narrowHighway false
      (some { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 420, endMinute := 540 }] }))
    { civilTime := some { year := 2026, month := 11, day := 14, weekday := 5, minuteOfDay := 720 } }

/-- `branch_3` (not_applicable): the road user standing in the governed lane is a pedestrian. -/
def branch3Trace : Trace := standingTrace [.pedestrian] (narrowSign [10])

/-- The instants judged on a standing trace: from 180 s of halt onwards. -/
def standingWindow : Option (Timestamp × Timestamp) := some (200000, 240000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := standingWindow) : Scenario :=
  { name := name
    rule := "NRS_484B_490"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant (window := some (200000, 290000))
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch1Trace .notApplicable
  , witness "branch_2" branch2Trace .notApplicable
  , witness "branch_3" branch3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_490
