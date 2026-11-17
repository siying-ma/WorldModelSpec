/-
  Witnesses for NRS_484B_503.

  Geometry (the witness's own figures, nowhere in the rule): an eastbound lane 10 (x −200…200 m,
  y 0…4 m, the curb at y = 0) and a second eastbound lane 11 (y 4…8 m). A passenger_loading curb
  zone 20 covers x 15…45 m, y 0…3 m. The subject (track 1, a motor vehicle, 5.0 × 1.8 m) halts at
  (30, 1.5), inside lane 10 and zone 20. Observations every 5 s.

  - Long halt (forbid, branch_1…branch_9 except branch_2's other car): halted from t = 0 to 80 s;
    the witnesses speak about t = 65…80 s, where the 60 s parked window behind is covered and the
    halt has lasted longer than p.standing_min_duration (60 s) by 5…20 s.
  - Stop-and-go (permit, blind): moving at 2 m/s for 70 s (outside the zone up to x = 10 m), halted
    at x = 30 from t = 70 to 85 s (15 s, well under 60 s), curb door open at t = 75 and 80 s, then
    moving off at 2 m/s.
  - Zone signs: hours Monday–Friday 08:00–18:00; the observation's civil time is a Tuesday at
    21:00 (out of hours) or 10:00 (in hours).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_503
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_503

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneA : Structure := Build.lane 10 [(m (-200), m 0), (m 200, m 0), (m 200, m 4), (m (-200), m 4)] Build.east
def laneB : Structure := Build.lane 11 [(m (-200), m 4), (m 200, m 4), (m 200, m 8), (m (-200), m 8)] Build.east
def zone : Structure := { Build.rect 20 .curbZone (m 15) (m 0) (m 45) (m 3) with curbKind := some .passengerLoading }

def car (track : TrackId) (x : Int) (speed : Q) (doors : List DoorSide) : RoadUser :=
  Build.withSignals (Build.user track [.motorVehicle] (m x, cm 150) Build.east speed (cm 250, cm 90, cm 75))
    fun s => { s with doorsOpen := some doors }

def weekdayHours : Conditions :=
  { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 480, endMinute := 1080 }] }

def tuesdayAt (minute : Nat) : Env :=
  { civilTime := some { year := 2026, month := 11, day := 17, weekday := 1, minuteOfDay := minute } }

/-- A halt at (30, 1.5) from t = 0 to 80 s, doors closed, with the given devices, other users,
    structures and environment. -/
def longHalt (devs : Nat → List Device) (others : List RoadUser := [])
    (structures : List Structure := [laneA, laneB, zone]) (env : Env := {}) : Trace :=
  Build.trace 17 0 (Units.seconds 5) fun k t =>
    Build.scene t (some 1) (car 1 30 Q.zero [] :: others) structures (devs k) (env := env)

/-- Moving at 2 m/s, halted at x = 30 for t = 70…85 s, curb door open at t = 75 and 80 s, then
    moving off. -/
def stopAndGo : Trace :=
  Build.trace 21 0 (Units.seconds 5) fun k t =>
    let ki : Int := k
    let x : Int := if k < 14 then 30 - 10 * (14 - ki) else if k ≤ 17 then 30 else 30 + 10 * (ki - 17)
    let v : Q := if 14 ≤ k ∧ k ≤ 17 then Q.zero else Units.metresPerSecond 2
    let doors : List DoorSide := if k = 15 ∨ k = 16 then [.curb] else []
    Build.scene t (some 1) [car 1 x v doors] [laneA, laneB, zone] []

def longWindow : Option (Timestamp × Timestamp) := some (65000, 80000)

/-- `forbid` (violated): A car halts inside a passenger_loading curb zone that no sign governs, for longer than the standing duration, no door open; no road user ahead and no stop control governs its lane. -/
def forbidTrace : Trace := longHalt fun _ => []

/-- `permit` (compliant): A car halts in the zone, opens its curb-side door, and moves off before the standing duration has elapsed. -/
def permitTrace : Trace := stopAndGo

/-- `idle` (not_applicable): A car halts at a curb where there is no curb zone. -/
def idleTrace : Trace := longHalt (fun _ => []) (structures := [laneA, laneB])

/-- `blind` (unknown): A car halts in the zone briefly, shorter than the standing duration, and the source does not observe its doors. -/
def blindTrace : Trace := stopAndGo

/-- `branch_1` (not_applicable): A car halts in the zone while a parking_restricted zone sign governing its lane posts hours that do not include the observation's time of day. -/
def branch_1Trace : Trace :=
  longHalt (fun _ => [Build.zoneSign 40 [10] .parkingRestricted false (some weekdayHours)]) (env := tuesdayAt 1260)

/-- `branch_2` (compliant): A car halts in the zone behind another car ahead in the same lane, within the queue gap, doors closed. -/
def branch_2Trace : Trace := longHalt (fun _ => []) (others := [car 2 37 Q.zero []])

/-- `branch_3` (compliant): a long halt in the zone on a lane a stop sign governs. -/
def branch_3Trace : Trace := longHalt fun _ => [Build.sign 30 .stopSign [10]]

/-- `branch_4` (compliant): a long halt in the zone on a lane a yield sign governs. -/
def branch_4Trace : Trace := longHalt fun _ => [Build.sign 31 .yieldSign [10]]

/-- `branch_5` (compliant): a long halt in the zone on a lane whose traffic signal shows circular red. -/
def branch_5Trace : Trace := longHalt fun _ => [Build.signal 32 [10] [.circularRed]]

/-- `branch_6` (compliant): a long halt on a lane governed by a railway signal and gate: lights
    flashing with the gate up (t = 65, 70 s), then lights dark with the gate down (t = 75, 80 s). -/
def branch_6Trace : Trace :=
  longHalt fun k =>
    [ if k < 15 then { Build.device 33 .railwaySignalOrGate [10] with railLights := some .flashing, gate := some .up }
      else { Build.device 33 .railwaySignalOrGate [10] with railLights := some .dark, gate := some .down } ]

/-- `branch_7` (compliant): a long halt on a lane where a police officer indicates stop. -/
def branch_7Trace : Trace :=
  longHalt fun _ =>
    [{ Build.device 34 .humanDirection [10] with humanRole := some .policeOfficer, humanIndication := some .stop }]

/-- `branch_8` (violated): a long halt in the zone, doors closed, while a parking_restricted zone
    sign governing its lane posts hours that include the observation's time of day. -/
def branch_8Trace : Trace :=
  longHalt (fun _ => [Build.zoneSign 40 [10] .parkingRestricted false (some weekdayHours)]) (env := tuesdayAt 600)

/-- `branch_9` (violated): a long halt in the zone, doors closed, out of posted hours, where the
    sign governing its lane is a school zone sign and the parking_restricted sign governs only the
    neighbouring lane the car does not occupy: the zone's regulations stay effective. -/
def branch_9Trace : Trace :=
  longHalt (fun _ =>
      [ Build.zoneSign 41 [10] .school false (some weekdayHours)
      , Build.zoneSign 42 [11] .parkingRestricted false (some weekdayHours) ])
    (env := tuesdayAt 1260)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_503"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := longWindow)
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable (window := longWindow)
  , witness "blind" blindTrace (.unknown []) ["sig.door_open"]
  , witness "branch_1" branch_1Trace .notApplicable (window := longWindow)
  , witness "branch_2" branch_2Trace .compliant (window := longWindow)
  , witness "branch_3" branch_3Trace .compliant (window := longWindow)
  , witness "branch_4" branch_4Trace .compliant (window := longWindow)
  , witness "branch_5" branch_5Trace .compliant (window := longWindow)
  , witness "branch_6" branch_6Trace .compliant (window := longWindow)
  , witness "branch_7" branch_7Trace .compliant (window := longWindow)
  , witness "branch_8" branch_8Trace .violated (window := longWindow)
  , witness "branch_9" branch_9Trace .violated (window := longWindow) ]

end TrafficSpecWitness.NRS_484B_503
