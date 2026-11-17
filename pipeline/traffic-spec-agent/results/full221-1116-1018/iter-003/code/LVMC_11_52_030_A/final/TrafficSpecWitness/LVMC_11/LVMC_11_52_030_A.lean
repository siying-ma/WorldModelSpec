/-
  Witnesses for LVMC_11_52_030_A.

  Geometry (every figure is the witness's own): one eastbound lane 10, x 0…100 m, y 0…4 m; a curb
  zone 20 along its north edge, x 20…60 m, y 3…4 m, of the kind and colour each scene names. A car
  (half-extents 2.5 m × 1 m) or a bus (6 m × 1.25 m) runs along y = 3 m, so its body overlaps the
  lane and, between x 20 and 60, the zone. A vehicle "pulls in": at the first instant it moves at
  3 m/s at x = 10 m, its body clear of the zone; from the second instant it is at rest at x = 40 m,
  inside the zone. Speeds at rest are zero (tolerance 0.1 m/s). A mail drop box (obstruction 30) is
  a 1 m square either 0.5 m north of the halted car's body (within the 3 m reach) or 27.5 m away.
  Devices govern lane 10 (a travel region the subject occupies).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_030_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_030_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneL : Structure := Build.lane 10 [(m 0, m 0), (m 100, m 0), (m 100, m 4), (m 0, m 4)] Build.east

def zone (kind : CurbZoneKind) (colour : CurbColour) : Structure :=
  { Build.rect 20 .curbZone (m 20) (m 3) (m 60) (m 4) with curbKind := some kind, curbColour := some colour }

/-- A mail drop box: a 1 m square north of the curb, its west edge at `x0`. -/
def dropBox (x0 : Int) : Structure :=
  { Build.rect 30 .obstruction (m x0) (cm 450) (m (x0 + 1)) (cm 550) with obstructionKind := some .mailDropBox }

def carDims : Q × Q × Q := (cm 250, cm 100, cm 75)
def busDims : Q × Q × Q := (m 6, cm 125, m 2)

/-- A road user that approaches clear of the zone at instant 0 and is at rest in it afterwards. -/
def pullIn (track : TrackId) (classes : List RoadUserClass) (dims : Q × Q × Q) (k : Nat) : RoadUser :=
  if k == 0 then Build.user track classes (m 10, m 3) Build.east (Units.metresPerSecond 3) dims
  else Build.user track classes (m 40, m 3) Build.east Q.zero dims

/-- As `pullIn`, then at instant `leaveAt` and after it drives on, clear of the zone at x = 70 m. -/
def pullInAndLeave (track : TrackId) (classes : List RoadUserClass) (dims : Q × Q × Q) (leaveAt k : Nat) : RoadUser :=
  if k ≥ leaveAt then Build.user track classes (m 70, m 3) Build.east (Units.metresPerSecond 3) dims
  else pullIn track classes dims k

/-- `forbid` (violated): A curb zone z (st.curb_zone, colour red, kind no_stopping) along a street. The subject, a passenger car (ru.motor_vehicle), pulls into z and stands there at rest for several minutes; no other road user is in the scene and no device governs its region. -/
def forbidTrace : Trace :=
  Build.trace 5 0 (Units.seconds 60) fun k t =>
    Build.scene t (some 1)
      [ pullIn 1 [.motorVehicle] carDims k ]
      [ laneL, zone .noStopping .red ]
      [ ]

/-- `permit` (compliant): The same car drives along z at a steady speed, its footprint overlapping z, and leaves it without halting. -/
def permitTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (10 + 10 * (k : Int)), m 3) Build.east (Units.metresPerSecond 10) carDims ]
      [ laneL, zone .noStopping .red ]
      [ ]

/-- `idle` (not_applicable): The same car halts for several minutes in a curb zone whose colour is none. -/
def idleTrace : Trace :=
  Build.trace 5 0 (Units.seconds 60) fun k t =>
    Build.scene t (some 1)
      [ pullIn 1 [.motorVehicle] carDims k ]
      [ laneL, zone .noStopping .none ]
      [ ]

/-- `blind` (unknown): As in forbid, but the source supplies no speed for the subject (kin.speed absent): whether it halts is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): A tour bus (ru.tour_bus_or_limousine) halts for ten minutes in a red zone of kind no_stopping, no other road user present and no device governing its region: the zone is not of kind tour_bus_loading, so exception (2) does not hold whatever the bus's aggregate membership, and the halt is a prohibited stop. -/
def branch_1Trace : Trace :=
  Build.trace 11 0 (Units.seconds 60) fun k t =>
    Build.scene t (some 1)
      [ pullIn 1 [.tourBusOrLimousine] busDims k ]
      [ laneL, zone .noStopping .red ]
      [ ]

/-- `branch_2` (violated): A tour bus (ru.tour_bus_or_limousine) stays at rest in a red zone of kind tour_bus_loading for forty minutes: from thirty minutes after it came to rest the exception no longer holds. -/
def branch_2Trace : Trace :=
  Build.trace 10 0 (Units.minutes 5) fun k t =>
    Build.scene t (some 1)
      [ pullIn 1 [.tourBusOrLimousine] busDims k ]
      [ laneL, zone .tourBusLoading .red ]
      [ ]

/-- `branch_3` (not_applicable): An armored car (ru.official_vehicle kind armored_car) halts in the red zone of forbid for fifteen minutes. -/
def branch_3Trace : Trace :=
  Build.trace 4 0 (Units.minutes 5) fun k t =>
    Build.scene t (some 1)
      [ { pullIn 1 [.officialVehicle] carDims k with officialKind := some .armoredCar } ]
      [ laneL, zone .noStopping .red ]
      [ ]

/-- `branch_4` (not_applicable): A passenger car halts in a red zone with its body beside a mail drop box (st.obstruction kind mail_drop_box) for half a minute and drives on. -/
def branch_4Trace : Trace :=
  Build.trace 5 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1)
      [ pullInAndLeave 1 [.motorVehicle] carDims 4 k ]
      [ laneL, zone .noStopping .red, dropBox 39 ]
      [ ]

/-- `branch_5` (compliant): A passenger car in a red zone halts behind another vehicle halted ahead of it in the same lane, the gap between their bodies within a queue spacing: the halt is one the definition of stopping excludes, so the duty is met. -/
def branch_5Trace : Trace :=
  Build.trace 4 0 (Units.seconds 60) fun k t =>
    Build.scene t (some 1)
      [ pullIn 1 [.motorVehicle] carDims k
      , Build.user 2 [.motorVehicle] (m 46, m 3) Build.east Q.zero carDims ]
      [ laneL, zone .noStopping .red ]
      [ ]

/-- `branch_6` (not_applicable): an ambulance (ru.emergency_vehicle) halts in the red zone of forbid
    for fifteen minutes: exception (4). -/
def branch_6Trace : Trace :=
  Build.trace 4 0 (Units.minutes 5) fun k t =>
    Build.scene t (some 1)
      [ { pullIn 1 [.emergencyVehicle] carDims k with emergencyKind := some .ambulance } ]
      [ laneL, zone .noStopping .red ]
      [ ]

/-- `branch_7` (violated): a car halts beside the drop box for ninety seconds: from beyond the
    expeditious-deposit bound exception (5) no longer holds. -/
def branch_7Trace : Trace :=
  Build.trace 5 0 (Units.seconds 30) fun k t =>
    Build.scene t (some 1)
      [ pullIn 1 [.motorVehicle] carDims k ]
      [ laneL, zone .noStopping .red, dropBox 39 ]
      [ ]

/-- `branch_8` (violated): a car halts for half a minute in the red zone, the drop box far beyond
    reach of its body: exception (5) does not hold. -/
def branch_8Trace : Trace :=
  Build.trace 5 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1)
      [ pullInAndLeave 1 [.motorVehicle] carDims 4 k ]
      [ laneL, zone .noStopping .red, dropBox 70 ]
      [ ]

/-- `branch_9` (compliant): a car halts in the red zone at a police officer's stop direction governing
    its lane. -/
def branch_9Trace : Trace :=
  Build.trace 4 0 (Units.seconds 60) fun k t =>
    Build.scene t (some 1)
      [ pullIn 1 [.motorVehicle] carDims k ]
      [ laneL, zone .noStopping .red ]
      [ { Build.device 52 .humanDirection [10] with humanRole := some .policeOfficer, humanIndication := some .stop } ]

/-- `branch_10` (compliant): a car halts in the red zone at a circular red signal governing its lane. -/
def branch_10Trace : Trace :=
  Build.trace 4 0 (Units.seconds 60) fun k t =>
    Build.scene t (some 1)
      [ pullIn 1 [.motorVehicle] carDims k ]
      [ laneL, zone .noStopping .red ]
      [ Build.signal 50 [10] [.circularRed] ]

/-- `branch_11` (compliant): a car halts in the red zone at a stop sign governing its lane. -/
def branch_11Trace : Trace :=
  Build.trace 4 0 (Units.seconds 60) fun k t =>
    Build.scene t (some 1)
      [ pullIn 1 [.motorVehicle] carDims k ]
      [ laneL, zone .noStopping .red ]
      [ Build.sign 51 .stopSign [10] ]

/-- `branch_12` (violated): a transit bus stays at rest in a red zone of kind bus_stop for forty
    minutes: from thirty minutes after it came to rest exception (3) no longer holds. -/
def branch_12Trace : Trace :=
  Build.trace 10 0 (Units.minutes 5) fun k t =>
    Build.scene t (some 1)
      [ pullIn 1 [.bus, .transitBus] busDims k ]
      [ laneL, zone .busStop .red ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_52_030_A"
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
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .violated ]

end TrafficSpecWitness.LVMC_11_52_030_A
