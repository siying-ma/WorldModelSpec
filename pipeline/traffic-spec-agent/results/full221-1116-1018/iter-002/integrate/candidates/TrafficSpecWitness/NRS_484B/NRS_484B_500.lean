/-
  Witnesses for NRS_484B_500.

  Geometry: two eastbound lanes, lane 10 (x 0…100 m, y 0…4 m) and lane 11 (x 0…100 m, y 4…8 m).
  The subject (track 1) is a motor vehicle, half-extent 2 m × 1 m × 1 m, centred on y = 2 m in
  lane 10. A halted subject stands at x = 50 m with speed 0 (tolerance 0.1 m/s); a moving one drives
  at 10 m/s from x = 20 m. Three observations, 1 s apart. Devices: a hazardous_place zone sign that
  begins a zone with an unconditional legend (100), a no_stopping regulatory sign (101), a stop
  sign (102), a yield sign (103), a traffic signal (104), a railway signal/gate (105), a police
  officer (106). A second car (track 2, same size, halted) stands ahead in lane 10: at x = 56 m the
  body gap is 2 m (within the 5 m queue gap), at x = 64 m it is 10 m (beyond it).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_500
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_500

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (m 2, m 1, m 1)

def lane10 : Structure := Build.lane 10 [(m 0, m 0), (m 100, m 0), (m 100, m 4), (m 0, m 4)] Build.east
def lane11 : Structure := Build.lane 11 [(m 0, m 4), (m 100, m 4), (m 100, m 8), (m 0, m 8)] Build.east
def lanes : List Structure := [lane10, lane11]

def haltedCar : RoadUser := Build.user 1 [.motorVehicle] (m 50, m 2) Build.east (Units.metresPerSecond 0) body
def movingCar (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (20 + 10 * (Int.ofNat k)), m 2) Build.east (Units.metresPerSecond 10) body
def carAhead (x : Int) : RoadUser := Build.user 2 [.motorVehicle] (m x, m 2) Build.east (Units.metresPerSecond 0) body

def zoneOn (rs : List RegionId) : Device := Build.zoneSign 100 rs .hazardousPlace false (some {})
def hazardZone : Device := zoneOn [10]
def noStopping (code : SignCode) (rs : List RegionId) : Device :=
  { Build.sign 101 .regulatorySign rs with code := some code, conditions := some {} }
def stopSign (rs : List RegionId) : Device := Build.sign 102 .stopSign rs
def yieldSign : Device := Build.sign 103 .yieldSign [10]
def redSignal (shows : List SignalIndication) : Device := Build.signal 104 [10] shows
def railway (l : RailLights) (g : GateState) : Device :=
  { Build.device 105 .railwaySignalOrGate [10] with railLights := some l, gate := some g }
def officer : Device :=
  { Build.device 106 .humanDirection [10] with humanRole := some .policeOfficer, humanIndication := some .stop }

/-- Three observations of a fixed scene. -/
def still (users : List RoadUser) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => Build.scene t (some 1) users lanes devices

/-- `forbid` (violated): A car halts in a lane governed by a hazardous_place zone sign whose legend is unconditional; no road user is ahead of it in the lane and no stop sign, signal or officer governs the lane. -/
def forbidTrace : Trace := still [haltedCar] [hazardZone]

/-- `permit` (compliant): The car drives through the same lane without halting. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [movingCar k] lanes [hazardZone]

/-- `idle` (not_applicable): The car halts in a lane that no hazardous_place zone sign and no no-stopping sign governs. -/
def idleTrace : Trace := still [haltedCar] [zoneOn [11], noStopping .noStopping [11]]

/-- `blind` (unknown): The car is in the governed lane with no road user ahead, but the source does not observe its speed, so whether it is halted is unknown. -/
def blindTrace : Trace := still [haltedCar] [hazardZone]

/-- `branch_1` (compliant): The car halts in the governed lane behind another car ahead in the same lane, its gap within the queue gap. -/
def branch_1Trace : Trace := still [haltedCar, carAhead 56] [hazardZone]

/-- `branch_2` (compliant): The car halts in a lane governed by a no-stopping sign where a traffic signal governing the lane displays circular_red. -/
def branch_2Trace : Trace := still [haltedCar] [noStopping .noStopping [10], redSignal [.circularRed]]

/-- `branch_3` (compliant): halted in the hazard zone where a stop sign governs the lane. -/
def branch_3Trace : Trace := still [haltedCar] [hazardZone, stopSign [10]]

/-- `branch_4` (compliant): halted in the hazard zone where a yield sign governs the lane. -/
def branch_4Trace : Trace := still [haltedCar] [hazardZone, yieldSign]

/-- `branch_5` (compliant): halted where a railway signal governing the lane flashes, its gate up. -/
def branch_5Trace : Trace := still [haltedCar] [hazardZone, railway .flashing .up]

/-- `branch_6` (compliant): halted where a railway gate governing the lane is down, its lights dark. -/
def branch_6Trace : Trace := still [haltedCar] [hazardZone, railway .dark .down]

/-- `branch_7` (compliant): halted where a police officer directing the lane indicates stop. -/
def branch_7Trace : Trace := still [haltedCar] [hazardZone, officer]

/-- `branch_8` (not_applicable): halted in a lane governed by a hazardous_place sign that ends the zone. -/
def branch_8Trace : Trace := still [haltedCar] [Build.zoneSign 100 [10] .hazardousPlace true (some {})]

/-- `branch_9` (not_applicable): halted under a hazardous_place sign whose legend restricts it to trucks; the car is no truck. -/
def branch_9Trace : Trace :=
  still [haltedCar] [Build.zoneSign 100 [10] .hazardousPlace false (some { vehicleClass := some .truck })]

/-- `branch_10` (violated): halted in the hazard zone behind a car ahead in the lane, but 10 m away, beyond the queue gap. -/
def branch_10Trace : Trace := still [haltedCar, carAhead 64] [hazardZone]

/-- `branch_11` (violated): halted under a no-stopping sign where the governing signal shows circular_green. -/
def branch_11Trace : Trace := still [haltedCar] [noStopping .noStopping [10], redSignal [.circularGreen]]

/-- `branch_12` (violated): halted in the hazard zone; a railway signal governs the lane, lights dark and gate up. -/
def branch_12Trace : Trace := still [haltedCar] [hazardZone, railway .dark .up]

/-- `branch_13` (not_applicable): halted in a lane governed by a school zone sign. -/
def branch_13Trace : Trace := still [haltedCar] [Build.zoneSign 100 [10] .school false (some {})]

/-- `branch_14` (not_applicable): halted in a lane governed by a no_parking sign (not no_stopping). -/
def branch_14Trace : Trace := still [haltedCar] [noStopping .noParking [10]]

/-- `branch_15` (violated): halted in the hazard zone; a stop sign governs only the adjacent lane. -/
def branch_15Trace : Trace := still [haltedCar] [hazardZone, stopSign [11]]

/-- `branch_16` (violated): halted in the hazard zone; another car is beside it in the adjacent lane, not ahead in its lane. -/
def branch_16Trace : Trace :=
  still [haltedCar, Build.user 2 [.motorVehicle] (m 56, m 6) Build.east (Units.metresPerSecond 0) body] [hazardZone]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_500"
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
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .violated
  , witness "branch_13" branch_13Trace .notApplicable
  , witness "branch_14" branch_14Trace .notApplicable
  , witness "branch_15" branch_15Trace .violated
  , witness "branch_16" branch_16Trace .violated ]

end TrafficSpecWitness.NRS_484B_500
