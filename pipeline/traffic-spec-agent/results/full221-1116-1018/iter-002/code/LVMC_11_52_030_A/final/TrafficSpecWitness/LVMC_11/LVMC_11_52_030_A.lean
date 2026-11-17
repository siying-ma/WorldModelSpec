/-
  Witnesses for LVMC_11_52_030_A.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - lane 10: x 0 … 200 m, y 0 … 4 m, direction east; the curb is its south edge (y = 0).
  - curb zone 20: x 40 … 80 m, y 0 … 2.5 m along that curb; colour and kind per scene.
  - the subject (track 1) drives east at y = 1.5 m, a car of half-extent 2.25 × 0.9 m (a bus
    6 × 1.25 m). A halting witness has two approach observations 1 s apart (x = 56, 58 m at
    2 m/s), then the subject at rest at x = 60 m (inside lane 10 and zone 20) from t = 2 s,
    sampled at the witness's own step.
  - mail drop box 30: an obstruction, x 59.7 … 60.3 m, y −1.5 … −0.9 m, 1.5 m from the halted
    car's body (reach 3 m in the reading).
  - queue: track 2, a car at rest at x = 67 m in lane 10, 2.5 m of body gap ahead of the subject
    (queue gap 5 m in the reading).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_030_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_030_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExt : Q × Q × Q := (cm 225, cm 90, cm 75)
def busExt : Q × Q × Q := (m 6, cm 125, cm 160)

def lane10 : Structure :=
  Build.lane 10 [(m 0, m 0), (m 200, m 0), (m 200, m 4), (m 0, m 4)] Build.east

def zone (kind : CurbZoneKind) (colour : CurbColour) : Structure :=
  { Build.rect 20 .curbZone (m 40) (m 0) (m 80) (cm 250) with
    curbKind := some kind, curbColour := some colour }

def redZone : Structure := zone .noStopping .red

def mailBox : Structure :=
  { Build.rect 30 .obstruction (cm 5970) (cm (-150)) (cm 6030) (cm (-90)) with
    obstructionKind := some .mailDropBox }

/-- A passenger car at `x` with speed `v`. -/
def car (x v : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, cm 150) Build.east v carExt

/-- A tour bus at `x` with speed `v`. -/
def tourBus (x v : Q) : RoadUser := Build.user 1 [.tourBusOrLimousine] (x, cm 150) Build.east v busExt

/-- An armored car at `x` with speed `v`. -/
def armored (x v : Q) : RoadUser :=
  { Build.user 1 [.officialVehicle] (x, cm 150) Build.east v carExt with officialKind := some .armoredCar }

/-- A fire engine at `x` with speed `v`. -/
def fireEngine (x v : Q) : RoadUser :=
  { Build.user 1 [.emergencyVehicle] (x, cm 150) Build.east v busExt with emergencyKind := some .fire }

/-- The subject approaches (x = 56, 58 m at 2 m/s, t = 0, 1 s), then rests at x = 60 m for `n`
    observations `step` seconds apart from t = 2 s. -/
def haltTrace (mk : Q → Q → RoadUser) (structs : List Structure) (devs : List Device)
    (others : List RoadUser) (n : Nat) (step : Int) : Trace :=
  Build.trace 2 0 (Units.seconds 1) (fun k t =>
      Build.scene t (some 1) (mk (Q.add (m 56) (m (2 * Int.ofNat k))) (Units.metresPerSecond 2) :: others)
        structs devs)
  ++ Build.trace n 2000 (Units.seconds step) (fun _k t =>
      Build.scene t (some 1) (mk (m 60) Q.zero :: others) structs devs)

/-- `forbid` (violated): A curb zone z (st.curb_zone, colour red, kind no_stopping) along a street. The subject, a passenger car (ru.motor_vehicle), pulls into z and stands there at rest for several minutes; no other road user is in the scene and no device governs its region. -/
def forbidTrace : Trace := haltTrace car [lane10, redZone] [] [] 6 60

/-- `permit` (compliant): The same car drives along z at a steady speed, its footprint overlapping z, and leaves it without halting. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (Q.add (m 42) (m (10 * Int.ofNat k))) (Units.metresPerSecond 10) ]
      [ lane10, redZone ]
      [ ]

/-- `idle` (not_applicable): The same car halts for several minutes in a curb zone whose colour is none. -/
def idleTrace : Trace := haltTrace car [lane10, zone .passengerLoading .none] [] [] 6 60

/-- `blind` (unknown): As in forbid, but the source supplies no speed for the subject (kin.speed absent): whether it halts is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): A tour bus (classified under DEF-LVMC-11-02-150::tour_bus) halts in a red zone of kind tour_bus_loading for ten minutes. -/
def branch_1Trace : Trace := haltTrace tourBus [lane10, zone .tourBusLoading .red] [] [] 3 300

/-- `branch_2` (violated): The same tour bus stays at rest in that zone for forty minutes: from thirty minutes after it came to rest the exception no longer holds. -/
def branch_2Trace : Trace := haltTrace tourBus [lane10, zone .tourBusLoading .red] [] [] 9 300

/-- `branch_3` (not_applicable): An armored car (ru.official_vehicle kind armored_car) halts in the red zone of forbid for fifteen minutes. -/
def branch_3Trace : Trace := haltTrace armored [lane10, redZone] [] [] 4 300

/-- `branch_4` (not_applicable): A passenger car halts in a red zone with its body beside a mail drop box (st.obstruction kind mail_drop_box) for half a minute and drives on. -/
def branch_4Trace : Trace :=
  haltTrace car [lane10, redZone, mailBox] [] [] 4 10
  ++ Build.trace 1 42000 (Units.seconds 1) (fun _k t =>
      Build.scene t (some 1) [ car (m 62) (Units.metresPerSecond 2) ] [lane10, redZone, mailBox] [])

/-- `branch_5` (not_applicable): A passenger car in a red zone halts behind another vehicle halted ahead of it in the same lane, the gap between their bodies within a queue spacing. -/
def branch_5Trace : Trace :=
  haltTrace car [lane10, redZone] []
    [ Build.user 2 [.motorVehicle] (m 67, cm 150) Build.east Q.zero carExt ] 4 10

/-- `branch_6` (not_applicable): a fire engine (ru.emergency_vehicle) halts in the red zone for fifteen minutes. -/
def branch_6Trace : Trace := haltTrace fireEngine [lane10, redZone] [] [] 4 300

/-- `branch_7` (compliant): the car halts in the red zone at a police officer's stop direction governing its lane. -/
def branch_7Trace : Trace :=
  haltTrace car [lane10, redZone]
    [ { Build.device 40 .humanDirection [10] with
        humanRole := some .policeOfficer, humanIndication := some .stop } ] [] 4 10

/-- `branch_8` (compliant): the car halts in the red zone at a traffic signal showing circular red over its lane. -/
def branch_8Trace : Trace :=
  haltTrace car [lane10, redZone] [ Build.signal 41 [10] [.circularRed] ] [] 4 10

/-- `branch_9` (compliant): the car halts in the red zone at a stop sign governing its lane. -/
def branch_9Trace : Trace :=
  haltTrace car [lane10, redZone] [ Build.sign 42 .stopSign [10] ] [] 4 10

/-- `branch_10` (violated): the car stays at rest beside the mail drop box for four minutes, past an expeditious deposit. -/
def branch_10Trace : Trace := haltTrace car [lane10, redZone, mailBox] [] [] 5 60

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "LVMC_11_52_030_A"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .notApplicable (window := some (2000, 602000))
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable (window := some (2000, 32000))
  , witness "branch_5" branch_5Trace .notApplicable (window := some (2000, 32000))
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .violated ]

end TrafficSpecWitness.LVMC_11_52_030_A
