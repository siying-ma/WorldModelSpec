/-
  Witnesses for NRS_484B_507_1.

  Geometry (the witness's own figures, nowhere in the rule):
  - lane 10: x ∈ [-300, 300], y ∈ [0, 4], eastbound; lane 11 beside it, y ∈ [4, 8];
  - curb zone 20 of kind freight_loading: x ∈ [0, 20], y ∈ [0, 2.5], overlapping lane 10;
  - the subject (track 1) approaches at 5 m/s at (-60, 1.25) before instant `k0`, stands at rest at
    (12, 1.25) inside the zone from `k0` to `k1`, and has left east, moving at (80, 1.25), after;
  - a goods truck (track 2, half-length 4 m) halted at (-7, 1.25): its body ends 3 m short of the
    zone (reach 10 m), outside it; a car (track 3) halted ahead in lane 10 at (19.5, 1.25): 3 m body
    gap to the subject (queue gap 5 m).
  Instants every 10 s from 0 (every 20 s in branch_12). Every trace starts with the subject moving,
  so each standing window behind a halted instant holds a moving observation or is covered.
  Halts: brief = 30–60 s (< 60 s standing duration), long = 100–150 s (> 60 s, < 1800 s); branch_12
  stands 1960 s (> 1800 s).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_507_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_507_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneA : Structure :=
  Build.lane 10 [(m (-300), m 0), (m 300, m 0), (m 300, m 4), (m (-300), m 4)] Build.east
def laneB : Structure :=
  Build.lane 11 [(m (-300), m 4), (m 300, m 4), (m 300, m 8), (m (-300), m 8)] Build.east
def freightZone : Structure :=
  { Build.rect 20 .curbZone (m 0) (m 0) (m 20) (cm 250) with curbKind := some .freightLoading }

def carExt : Q × Q × Q := (cm 225, cm 90, cm 75)
def truckExt : Q × Q × Q := (m 4, cm 125, cm 175)

/-- The subject's place: approaching before `k0`, in the zone until `k1`, gone after. -/
def phasePos (k0 k1 k : Nat) : Vec :=
  if k < k0 then (m (-60), cm 125) else if k < k1 then (m 12, cm 125) else (m 80, cm 125)
def phaseSpeed (k0 k1 k : Nat) : Q :=
  if k < k0 then Units.metresPerSecond 5 else if k < k1 then Q.zero else Units.metresPerSecond 5

def subjectAt (classes : List RoadUserClass) (ext : Q × Q × Q) (k0 k1 : Nat)
    (doors : Nat → Option (List DoorSide)) (k : Nat) : RoadUser :=
  Build.withSignals (Build.user 1 classes (phasePos k0 k1 k) Build.east (phaseSpeed k0 k1 k) ext)
    fun s => { s with doorsOpen := doors k }

def closed : Nat → Option (List DoorSide) := fun _ => some []
def openAt (ks : List Nat) : Nat → Option (List DoorSide) :=
  fun k => some (if ks.contains k then [.curb] else [])
def unobserved : Nat → Option (List DoorSide) := fun _ => none

def car := subjectAt [.motorVehicle] carExt
def truckSubject := subjectAt [.truck] truckExt

/-- A goods truck halted 3 m short of the zone, outside it. -/
def waitingTruck : RoadUser := Build.user 2 [.truck] (m (-7), cm 125) Build.east Q.zero truckExt
/-- The same truck once gone, moving far west of the zone. -/
def goneTruck : RoadUser :=
  Build.user 2 [.truck] (m (-200), cm 125) Build.east (Units.metresPerSecond 5) truckExt
/-- A car halted ahead of the subject in lane 10, 3 m body gap. -/
def queuedCar : RoadUser := Build.user 3 [.motorVehicle] (cm 1950, cm 125) Build.east Q.zero carExt
/-- That car once the queue has cleared, moving far ahead. -/
def clearedCar : RoadUser :=
  Build.user 3 [.motorVehicle] (m 200, cm 125) Build.east (Units.metresPerSecond 5) carExt

def street : List Structure := [laneA, freightZone]

/-- A long halt (100 s) of a passenger car in the zone, doors closed, with the given devices. -/
def longClosedHalt (devices : List Device) (others : List RoadUser := []) (structures : List Structure := street)
    (env : Env := {}) : Trace :=
  Build.trace 14 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1) (car 2 12 closed k :: others) structures devices (env := env)

/-- `forbid` (violated): A passenger car halts inside a freight_loading curb zone that no sign governs, for longer than the standing duration, doors closed; no road user ahead and no stop control governs its lane. -/
def forbidTrace : Trace := longClosedHalt []

/-- `permit` (compliant): A truck halts in the zone with its curb-side door open and moves off before the commercial loading duration has elapsed. (150 s halt; door open from 80 s to 110 s.) -/
def permitTrace : Trace :=
  Build.trace 20 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1) [truckSubject 2 17 (openAt [8, 9, 10, 11]) k] street []

/-- `idle` (not_applicable): A passenger car halts at a curb where there is no curb zone. -/
def idleTrace : Trace := longClosedHalt [] (structures := [laneA])

/-- `blind` (unknown): A passenger car halts in the zone briefly, shorter than the standing duration, and the source does not observe its doors. -/
def blindTrace : Trace :=
  Build.trace 8 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1) [car 2 5 unobserved k] street []

/-- `branch_1` (violated): A passenger car halts briefly in the zone with a door open while a truck stands halted just outside the zone, within the waiting reach of it. -/
def branch_1Trace : Trace :=
  Build.trace 8 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1) [car 2 5 (openAt [2, 3, 4]) k, waitingTruck] street []

/-- `branch_2` (compliant): A passenger car halts briefly in the zone with a door open; no other road user is in the scene. (Door open at the middle observation only.) -/
def branch_2Trace : Trace :=
  Build.trace 8 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1) [car 2 6 (openAt [4]) k] street []

/-- `branch_3` (compliant): a long halt, doors closed, 3 m behind a car halted ahead in the lane. -/
def branch_3Trace : Trace := longClosedHalt [] [queuedCar]

/-- `branch_4` (compliant): a long halt, doors closed, in a lane a stop sign governs. -/
def branch_4Trace : Trace := longClosedHalt [Build.sign 50 .stopSign [10]]

/-- `branch_5` (compliant): a long halt, doors closed, in a lane a yield sign governs. -/
def branch_5Trace : Trace := longClosedHalt [Build.sign 50 .yieldSign [10]]

/-- `branch_6` (compliant): a long halt, doors closed, at a signal showing circular red. -/
def branch_6Trace : Trace := longClosedHalt [Build.signal 50 [10] [.circularRed]]

/-- `branch_7` (compliant): a long halt at a railway signal flashing, gate up. -/
def branch_7Trace : Trace :=
  longClosedHalt [{ Build.device 50 .railwaySignalOrGate [10] with railLights := some .flashing, gate := some .up }]

/-- `branch_8` (compliant): a long halt at a railway gate down, lights dark. -/
def branch_8Trace : Trace :=
  longClosedHalt [{ Build.device 50 .railwaySignalOrGate [10] with railLights := some .dark, gate := some .down }]

/-- `branch_9` (compliant): a long halt at a police officer's stop indication. -/
def branch_9Trace : Trace :=
  longClosedHalt [{ Build.device 50 .humanDirection [10] with humanRole := some .policeOfficer, humanIndication := some .stop }]

def weekdayDaytime : Conditions := { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 420, endMinute := 1080 }] }
def weekend : Conditions := { windows := [{ weekdays := [5, 6], startMinute := 0, endMinute := 1440 }] }
/-- Wednesday 10:00. -/
def wednesdayMorning : Env := { civilTime := some { year := 2026, month := 11, day := 18, weekday := 2, minuteOfDay := 600 } }
/-- Sunday 20:00. -/
def sundayEvening : Env := { civilTime := some { year := 2026, month := 11, day := 22, weekday := 6, minuteOfDay := 1200 } }

/-- `branch_10` (not_applicable): a long halt, doors closed, in a zone whose parking_restricted sign (weekdays 7:00–18:00) governs the lane, on Sunday evening: the zone's hours are not in effect. -/
def branch_10Trace : Trace :=
  longClosedHalt [Build.zoneSign 60 [10] .parkingRestricted false (some weekdayDaytime)] (env := sundayEvening)

/-- `branch_11` (compliant): a commercial motor vehicle (no truck) halts 150 s with a door open mid-halt. -/
def branch_11Trace : Trace :=
  Build.trace 20 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1) [subjectAt [.commercialMotorVehicle] truckExt 2 17 (openAt [8, 9, 10, 11]) k] street []

/-- `branch_12` (violated): a truck stands 1960 s in the zone with its door open: past the commercial loading limit. -/
def branch_12Trace : Trace :=
  Build.trace 103 0 (Units.seconds 20) fun k t =>
    Build.scene t (some 1) [truckSubject 2 100 (fun k => some (if k < 2 then [] else if k < 100 then [.curb] else [])) k] street []

/-- `branch_13` (violated): a passenger car halts behind a queued car while a truck waits outside the zone; the queue clears and the truck leaves, then the car opens a door briefly: the stop interfered with the waiting truck. -/
def branch_13Trace : Trace :=
  Build.trace 10 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1)
      [car 2 8 (openAt [5]) k, if k < 4 then waitingTruck else goneTruck, if k < 4 then queuedCar else clearedCar]
      street []

/-- `branch_14` (violated): a long halt, doors closed, on Wednesday morning, with a parking_restricted sign whose hours hold governing the lane, a school zone sign out of its hours governing the lane, and a parking_restricted sign out of its hours governing the next lane. -/
def branch_14Trace : Trace :=
  longClosedHalt
    [ Build.zoneSign 60 [10] .parkingRestricted false (some weekdayDaytime)
    , Build.zoneSign 61 [10] .school false (some weekend)
    , Build.zoneSign 62 [11] .parkingRestricted false (some weekend) ]
    (structures := [laneA, laneB, freightZone]) (env := wednesdayMorning)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_507_1"
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
  , witness "blind" blindTrace (.unknown []) ["sig.door_open"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .notApplicable
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .violated
  , witness "branch_13" branch_13Trace .violated
  , witness "branch_14" branch_14Trace .violated ]

end TrafficSpecWitness.NRS_484B_507_1
