/-
  Witnesses for NRS_484B_450_1o.

  Geometry: one eastbound lane (region 10), x from −10 m to 1100 m, y from 0 to 4 m. The subject
  (track 1) is a motor vehicle 5 m long and 2 m wide, its reference point on y = 2 m. A curb zone
  (region 20), where present, is the strip y 0–1 m along the lane's right edge; the subject's
  footprint (y 1–3 m) touches it, and its occupancy of both regions is stated.
  The prohibiting sign is device 100, governing the lane; an excusing device, where present, is
  device 101, governing the lane too.
  Long halts are sampled every 10 s (at most half the 60 s standing window), short halts every 1 s.
  Under the run's reading (halt tolerance 0.1 m/s, standing 60 s, parking 180 s, queue gap 5 m): the
  forbid halt lasts 300 s (> 180 s), the permit halt 20 s (< 180 s), the standing halt 120 s
  (> 60 s), the curb no_parking halt 400 s; a moving subject runs at 5 m/s; the vehicle ahead in
  branch_4 stands with its body 2 m from the subject's (< 5 m).
  Witnesses whose rule looks back over a window name the instants whose window the trace covers.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_450_1o
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_450_1o

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneL : Structure :=
  Build.lane 10 [(m (-10), m 0), (m 1100, m 0), (m 1100, m 4), (m (-10), m 4)] Build.east

def curbZone (k : CurbZoneKind) : Structure :=
  { Build.rect 20 .curbZone (m (-10)) (m 0) (m 1100) (m 1) with curbKind := some k }

def car (track : TrackId) (x : Q) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, m 2) Build.east speed (cm 250, m 1, cm 75)

def regSign (code : SignCode) : Device :=
  { Build.sign 100 .regulatorySign [10] with code := some code, conditions := some {} }

/-- The subject at rest at x = 5 m throughout, every `dt` seconds. -/
def restTrace (n : Nat) (dt : Q) (structs : List Structure) (devs : List Device)
    (occ : Option (List (TrackId × RegionId)) := none) (env : Env := {}) : Trace :=
  Build.trace n 0 dt fun _k t =>
    Build.scene t (some 1) [car 1 (m 5) Q.zero] structs devs occ env

/-- The subject moving at 5 m/s at the first instant, then at rest at x = 5 m for 2 s. -/
def haltTrace (structs : List Structure) (devs : List Device) (others : List RoadUser := [])
    (occ : Option (List (TrackId × RegionId)) := none) : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let u := if k == 0 then car 1 (m 0) (Units.metresPerSecond 5) else car 1 (m 5) Q.zero
    Build.scene t (some 1) (u :: others) structs devs occ

/-- `forbid` (violated): A dev.regulatory_sign of code no_parking with empty conditions governs the lane the subject, a ru.aggregate vehicle, occupies; the subject has been at rest (kin.speed zero) for 300 s; no other road user, no human direction and no other device is in the scene. -/
def forbidTrace : Trace :=
  restTrace 31 (Units.seconds 10) [laneL] [regSign .noParking]

/-- `permit` (compliant): As in forbid, but the subject has been at rest for 20 s after moving, a halt shorter than parking. -/
def permitTrace : Trace :=
  Build.trace 24 0 (Units.seconds 10) fun k t =>
    let u := if k ≤ 20 then car 1 (m (50 * k)) (Units.metresPerSecond 5) else car 1 (m 1000) Q.zero
    Build.scene t (some 1) [u] [laneL] [regSign .noParking]

/-- `idle` (not_applicable): The subject is at rest in a lane that no prohibiting sign governs and overlaps no curb zone. -/
def idleTrace : Trace :=
  restTrace 3 (Units.seconds 1) [laneL] []

/-- `blind` (unknown): As in forbid, but the source does not observe the subject's speed. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.speed"]) forbidTrace

/-- `branch_1` (violated): A dev.regulatory_sign of code no_stopping with empty conditions governs the subject's lane; the subject halts for 2 s. -/
def branch_1Trace : Trace :=
  haltTrace [laneL] [regSign .noStopping]

/-- `branch_2` (violated): The subject's footprint overlaps a st.curb_zone of kind no_parking and it has been at rest for 400 s. -/
def branch_2Trace : Trace :=
  restTrace 41 (Units.seconds 10) [laneL, curbZone .noParking] [] (some [(1, 10), (1, 20)])

/-- `branch_3` (not_applicable): As in forbid, but the sign's conditions state a time window that env.civil_time at the observation lies outside, so prim.conditions_hold is false. -/
def branch_3Trace : Trace :=
  let sign : Device :=
    { regSign .noParking with
      conditions := some { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 420, endMinute := 600 }] } }
  restTrace 31 (Units.seconds 10) [laneL] [sign] none
    { civilTime := some { year := 2026, month := 11, day := 16, weekday := 0, minuteOfDay := 1200 } }

/-- `branch_4` (compliant): As in branch_1, but another vehicle stands ahead of the subject in the same lane (rel.ahead_behind_in_lane) with its body 2 m from the subject's (rel.surface_gap). -/
def branch_4Trace : Trace :=
  haltTrace [laneL] [regSign .noStopping] [car 2 (m 12) Q.zero]

/-- `branch_5` (violated): a no_standing sign governs the subject's lane; the subject has been at rest 120 s. -/
def branch_5Trace : Trace :=
  restTrace 13 (Units.seconds 10) [laneL] [regSign .noStanding]

/-- `branch_6` (violated): the subject's footprint overlaps a no_stopping curb zone; it halts for 2 s. -/
def branch_6Trace : Trace :=
  haltTrace [laneL, curbZone .noStopping] [] [] (some [(1, 10), (1, 20)])

/-- `branch_7` (compliant): as branch_1, but a stop sign governs the subject's lane. -/
def branch_7Trace : Trace :=
  haltTrace [laneL] [regSign .noStopping, Build.sign 101 .stopSign [10]]

/-- `branch_8` (compliant): as branch_1, but a yield sign governs the subject's lane. -/
def branch_8Trace : Trace :=
  haltTrace [laneL] [regSign .noStopping, Build.sign 101 .yieldSign [10]]

/-- `branch_9` (compliant): as branch_1, but a traffic signal showing circular red governs the subject's lane. -/
def branch_9Trace : Trace :=
  haltTrace [laneL] [regSign .noStopping, Build.signal 101 [10] [.circularRed]]

/-- `branch_10` (compliant): as branch_1, but a level-crossing signal with its lights flashing (gate up) governs the subject's lane. -/
def branch_10Trace : Trace :=
  haltTrace [laneL]
    [regSign .noStopping,
     { Build.device 101 .railwaySignalOrGate [10] with railLights := some .flashing, gate := some .up }]

/-- `branch_11` (compliant): as branch_1, but a level-crossing gate is down (lights dark) on the subject's lane. -/
def branch_11Trace : Trace :=
  haltTrace [laneL]
    [regSign .noStopping,
     { Build.device 101 .railwaySignalOrGate [10] with railLights := some .dark, gate := some .down }]

/-- `branch_12` (compliant): as branch_1, but a police officer directs the subject's lane to stop. -/
def branch_12Trace : Trace :=
  haltTrace [laneL]
    [regSign .noStopping,
     { Build.device 101 .humanDirection [10] with humanRole := some .policeOfficer, humanIndication := some .stop }]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_450_1o"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (180000, 300000))
  , witness "permit" permitTrace .compliant (window := some (180000, 230000))
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] (window := some (180000, 300000))
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated (window := some (180000, 400000))
  , witness "branch_3" branch_3Trace .notApplicable (window := some (180000, 300000))
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated (window := some (60000, 120000))
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .compliant ]

end TrafficSpecWitness.NRS_484B_450_1o
