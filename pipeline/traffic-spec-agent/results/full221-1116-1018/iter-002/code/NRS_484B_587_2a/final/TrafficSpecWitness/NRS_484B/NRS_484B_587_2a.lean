/-
  Witnesses for NRS_484B_587_2a.

  Geometry (world frame, +x east): a straight controlled-access carriageway 400 m long, traffic
  eastbound. Region 10 is the highway (x 0..400, y -3..7) and region 11 the controlled-access
  region over the same area; region 12 is a mainline lane (y 0..4), region 13 the paved shoulder
  north of it (y 4..7, lying on highway 10), region 14 the median south of it (y -3..0). Device 20,
  where present, is a regulatory sign of code shoulder_use_permitted governing the shoulder.
  The surface street of `idle` is the same layout with no controlled-access region and no median.
  The subject (track 1) is 4 m × 2 m (bus: 12 m × 2.5 m) and sits wholly in one region; three
  instants 1 s apart. Speeds are 5..30 m/s, far above the 0.1 m/s halt tolerance. Every figure here
  is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_587_2a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_587_2a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)
def busExtent : Q × Q × Q := (m 6, cm 125, cm 150)

/-- y of the reference point: in the lane, on the shoulder, in the median. -/
def yLane : Q := m 2
def yShoulder : Q := cm 550
def yMedian : Q := cm (-150)

def highwayR : Structure := Build.rect 10 .highway (m 0) (m (-3)) (m 400) (m 7)
def controlledAccessR : Structure := Build.rect 11 .controlledAccess (m 0) (m (-3)) (m 400) (m 7)
def laneR : Structure := Build.rect 12 .lane (m 0) (m 0) (m 400) (m 4)
def shoulderR : Structure :=
  { Build.rect 13 .shoulder (m 0) (m 4) (m 400) (m 7) with paved := some true, ways := some [10] }
def medianR : Structure := Build.rect 14 .medianOrDivider (m 0) (m (-3)) (m 400) (m 0)

def freeway : List Structure := [highwayR, controlledAccessR, laneR, shoulderR, medianR]
def surfaceStreet : List Structure :=
  [ Build.rect 10 .highway (m 0) (m 0) (m 400) (m 7), laneR, shoulderR ]

/-- The shoulder-use sign, with the given legend conditions. -/
def shoulderSign (c : Conditions) : Device :=
  { Build.sign 20 .regulatorySign [13] with code := some .shoulderUsePermitted, conditions := some c }

/-- A road user with its lamps observed: no hazard lamps, no warning lamp (unless given). -/
def mover (classes : List RoadUserClass) (k : Nat) (y speed : Q) (ext : Q × Q × Q)
    (hazard : Bool := false) (lamps : List WarningLamp := []) : RoadUser :=
  Build.withSignals
    (Build.user 1 classes (Q.add (m 50) (Q.mul speed (Q.ofInt (Int.ofNat k))), y) Build.east speed ext)
    (fun s => { s with hazard := some hazard, warningLamps := some lamps })

def privateCar (k : Nat) (y speed : Q) (hazard : Bool := false) : RoadUser :=
  mover [.motorVehicle] k y speed carExtent hazard

/-- `forbid` (violated): The subject car, moving at 25 m/s on a controlled-access highway, drives along the paved shoulder to pass a queue; no hazard lamps, no shoulder-use sign. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ privateCar k yShoulder (Units.metresPerSecond 25) ]
      freeway
      [ ]

/-- `permit` (compliant): The subject car moves at 30 m/s in a mainline lane of the controlled-access highway; its footprint overlaps only that lane. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ privateCar k yLane (Units.metresPerSecond 30) ]
      freeway
      [ ]

/-- `idle` (not_applicable): The subject car drives on the shoulder of a surface street; it never overlaps a controlled-access region. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ privateCar k yShoulder (Units.metresPerSecond 12) ]
      surfaceStreet
      [ ]

/-- `blind` (unknown): The subject car is on the paved shoulder of a controlled-access highway; the source does not supply kin.speed, so whether it is driven there is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ privateCar k yShoulder (Units.metresPerSecond 20) ]
      freeway
      [ ]

/-- `branch_1` (compliant): A transit bus (bus aggregate member, ru.transit_bus) moves on a paved shoulder of the controlled-access highway governed by a shoulder_use_permitted sign whose conditions hold for it. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover [.bus, .transitBus, .motorVehicle] k yShoulder (Units.metresPerSecond 15) busExtent ]
      freeway
      [ shoulderSign { vehicleClass := some .transitBus } ]

/-- `branch_2` (not_applicable): The subject car with hazard lamps flashing moves slowly along the shoulder of the controlled-access highway. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ privateCar k yShoulder (Units.metresPerSecond 5) (hazard := true) ]
      freeway
      [ ]

/-- `branch_3` (violated): The subject car drives across the median of the controlled-access highway. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ privateCar k yMedian (Units.metresPerSecond 20) ]
      freeway
      [ ]

/-- `branch_4` (violated): A private car moves on a shoulder governed by a shoulder_use_permitted sign whose conditions admit only transit buses. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ privateCar k yShoulder (Units.metresPerSecond 20) ]
      freeway
      [ shoulderSign { vehicleClass := some .transitBus } ]

/-- `branch_5` (not_applicable): A police car showing a flashing blue warning lamp drives along the shoulder of the controlled-access highway; no shoulder-use sign. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ { mover [.emergencyVehicle, .motorVehicle] k yShoulder (Units.metresPerSecond 25) carExtent
            (lamps := [{ colour := .blue, mode := .flashing, facing := .front }])
          with emergencyKind := some .police } ]
      freeway
      [ ]

/-- `branch_6` (compliant): A traffic incident management vehicle drives on the paved shoulder of the controlled-access highway, governed by a shoulder_use_permitted sign with no restriction in its legend. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ { mover [.officialVehicle, .motorVehicle] k yShoulder (Units.metresPerSecond 15) carExtent
          with officialKind := some .incidentManagement } ]
      freeway
      [ shoulderSign {} ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_587_2a"
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
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .compliant ]

end TrafficSpecWitness.NRS_484B_587_2a
