/-
  Witnesses for NRS_484B_510.

  Geometry (the witness's own figures; none appears in the rule):
    - lane 10: an eastbound kerbside lane, x ∈ [-100, 100], y ∈ [-3, 0];
    - region 20: a curb zone over the lane, x ∈ [0, 20], y ∈ [-3, 0], of kind restricted_parking
      (passenger_loading in `idle`);
    - device 30: a parking_restricted zone sign governing lane 10, legend: Monday–Friday
      08:00–18:00, taxicabs only; every scene is Monday 10:00;
    - track 1, the subject: a car (half-extents 2.25 × 0.9 × 0.75 m) heading east, halted at
      (10, -1.5) inside the zone; where it arrives, it is at (8, -1.5) at 2 m/s one second before;
    - track 2: a taxicab halted at (-6, -1.5), body 3.75 m from the zone (reach 10 m), or a car
      halted 2 m ahead of the subject's front (queue gap 5 m);
    - device 40: a stop sign, yield sign, red signal, railway signal or gate, or police officer
      governing lane 10.
  The standing duration is 60 s: `forbid` halts for 70 s; the brief halts last 3 s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_510
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_510

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def monday10 : Env :=
  { civilTime := some { year := 2026, month := 11, day := 16, weekday := 0, minuteOfDay := 600 } }

def lane0 : Structure :=
  Build.lane 10 [(m (-100), m (-3)), (m 100, m (-3)), (m 100, m 0), (m (-100), m 0)] Build.east

def zone (k : CurbZoneKind) : Structure :=
  { Build.rect 20 .curbZone (m 0) (m (-3)) (m 20) (m 0) with curbKind := some k }

def taxiOnly : Conditions :=
  { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 480, endMinute := 1080 }]
    vehicleClass := some .taxicab }

def zoneSignDev : Device := Build.zoneSign 30 [10] .parkingRestricted false (some taxiOnly)

/-- A vehicle in the kerbside lane at x, heading east, with its doors as given. -/
def car (track : TrackId) (classes : List RoadUserClass) (x : Q) (v : Q)
    (doors : Option (List DoorSide)) : RoadUser :=
  Build.withSignals (Build.user track classes (x, cm (-150)) Build.east v (cm 225, cm 90, cm 75))
    (fun s => { s with doorsOpen := doors })

def street (t : Timestamp) (users : List RoadUser) (devices : List Device)
    (k : CurbZoneKind := .restrictedParking) : Scene :=
  Build.scene t (some 1) users [lane0, zone k] (zoneSignDev :: devices) (env := monday10)

def passengerCar : List RoadUserClass := [.motorVehicle]
def taxi : List RoadUserClass := [.taxicab, .motorVehicle]

/-- The subject halted in the zone. -/
def haltedSubject (classes : List RoadUserClass) (doors : Option (List DoorSide)) : RoadUser :=
  car 1 classes (m 10) Q.zero doors

/-- A brief stop: arriving at k = 0, halted at k = 1..3, leaving at k = 4. -/
def briefSubject (k : Nat) (doors : Option (List DoorSide)) : RoadUser :=
  if k == 0 then car 1 passengerCar (m 8) (Units.metresPerSecond 2) doors
  else if k ≥ 4 then car 1 passengerCar (m 12) (Units.metresPerSecond 2) doors
  else car 1 passengerCar (m 10) Q.zero doors

/-- A passenger car halted 70 s in the zone, doors closed, not a taxicab. -/
def forbidTrace : Trace :=
  Build.trace 8 0 (Units.seconds 10) fun _k t =>
    street t [haltedSubject passengerCar (some [])] []

/-- A taxicab, meeting the sign's class condition inside its posted hours, parks in the zone. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    street t [haltedSubject taxi (some [])] []

/-- A passenger car halts in a passenger_loading curb zone: no restricted_parking zone. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    street t [haltedSubject passengerCar (some [])] [] (k := .passengerLoading)

/-- A passenger car halts 3 s in the zone; its doors are not observed. -/
def blindTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    street t [briefSubject k none] []

/-- A passenger car halts 3 s; a door is open at the middle observation of the halt, closed at its
    first and last; no other road user. -/
def branch_1Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    street t [briefSubject k (if k == 2 then some [.curb] else some [])] []

/-- A passenger car halts with a door open while a taxicab stands halted 3.75 m outside the zone. -/
def branch_2Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    street t
      [ (if k == 0 then car 1 passengerCar (m 8) (Units.metresPerSecond 2) (some [])
         else haltedSubject passengerCar (some [.curb]))
      , car 2 taxi (m (-6)) Q.zero (some []) ] []

/-- branch_3 (compliant): halted, doors closed, behind a car halted 2 m ahead in the same lane. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    street t [haltedSubject passengerCar (some []), car 2 passengerCar (cm 1650) Q.zero (some [])] []

/-- Halted, doors closed, with device `d` governing the lane. -/
def deviceTrace (d : Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    street t [haltedSubject passengerCar (some [])] [d]

/-- branch_4 (compliant): a stop sign governs the lane. -/
def branch_4Trace : Trace := deviceTrace (Build.sign 40 .stopSign [10])
/-- branch_5 (compliant): a yield sign governs the lane. -/
def branch_5Trace : Trace := deviceTrace (Build.sign 40 .yieldSign [10])
/-- branch_6 (compliant): a signal showing circular red governs the lane. -/
def branch_6Trace : Trace := deviceTrace (Build.signal 40 [10] [.circularRed])
/-- branch_7 (compliant): a railway signal with lights flashing, gate up. -/
def branch_7Trace : Trace :=
  deviceTrace { Build.device 40 .railwaySignalOrGate [10] with railLights := some .flashing, gate := some .up }
/-- branch_8 (compliant): a railway gate down, lights dark. -/
def branch_8Trace : Trace :=
  deviceTrace { Build.device 40 .railwaySignalOrGate [10] with railLights := some .dark, gate := some .down }
/-- branch_9 (compliant): a police officer indicating stop. -/
def branch_9Trace : Trace :=
  deviceTrace { Build.device 40 .humanDirection [10] with
    humanRole := some .policeOfficer, humanIndication := some .stop }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_510"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (60000, 70000))
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.door_open"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant ]

end TrafficSpecWitness.NRS_484B_510
