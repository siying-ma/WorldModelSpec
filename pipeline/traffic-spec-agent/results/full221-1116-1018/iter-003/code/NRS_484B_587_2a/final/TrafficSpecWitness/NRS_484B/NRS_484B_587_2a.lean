/-
  Witnesses for NRS_484B_587_2a.

  Geometry (every figure is the witness's own and appears nowhere in the rule): an eastbound
  carriageway along +x, x from -100 m to 400 m.
    region 1  highway            y -10 … 10
    region 2  controlled_access  y -10 … 10 (absent in `idle`, which is a surface street; there a
              controlled-access region lies far away, y 100 … 120)
    region 3  lane               y   0 … 4   (the mainline lane)
    region 5  shoulder           y  -3 … 0   (paved, lying on highway 1)
    region 6  median_or_divider  y   8 … 10
    y 4 … 8 is unmarked pavement (a gore area): neither lane, shoulder nor median.
  Device 1, where present, is a regulatory sign of code shoulder_use_permitted governing shoulder 5.
  Three instants, one second apart; the subject (track 1) advances at its speed along +x.
  A car is 5 m × 2 m; a bus 12 m × 2.5 m. On the shoulder the reference point is at y = -1.5, in
  the lane at y = 2, on the median at y = 9, in the gore at y = 6. Speeds are 5–30 m/s, far above
  the halt tolerance (0.1 m/s). Hazard lamps are observed off unless the scene turns them on.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_587_2a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_587_2a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

def carExtent : Q × Q × Q := (cm 250, m 1, cm 75)
def busExtent : Q × Q × Q := (m 6, cm 125, cm 150)

def hwy : Structure := Build.rect 1 .highway (m (-100)) (m (-10)) (m 400) (m 10)
def ca : Structure := Build.rect 2 .controlledAccess (m (-100)) (m (-10)) (m 400) (m 10)
def mainLane : Structure :=
  Build.lane 3 [(m (-100), m 0), (m 400, m 0), (m 400, m 4), (m (-100), m 4)] Build.east
def shoulder : Structure :=
  { Build.rect 5 .shoulder (m (-100)) (m (-3)) (m 400) (m 0) with paved := some true, ways := some [1] }
def median : Structure := Build.rect 6 .medianOrDivider (m (-100)) (m 8) (m 400) (m 10)

def freeway : List Structure := [hwy, ca, mainLane, shoulder, median]

/-- A shoulder_use_permitted sign over the shoulder with the given legend conditions. -/
def shoulderSign (conds : Conditions) : Device :=
  { Build.sign 1 .regulatorySign [5] with code := some .shoulderUsePermitted, conditions := some conds }

/-- The subject at instant `k`, at lateral offset `y`, moving east at `v` m/s, hazard lamps off. -/
def mover (classes : List RoadUserClass) (ext : Q × Q × Q) (y : Q) (v : Int) (k : Nat) : RoadUser :=
  Build.withSignals
    (Build.user 1 classes (m (v * Int.ofNat k), y) Build.east (Units.metresPerSecond v) ext)
    (fun s => { s with hazard := some false })

def shoulderY : Q := cm (-150)
def laneY : Q := m 2

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): The subject car, moving at 25 m/s on a controlled-access highway, drives along the paved shoulder to pass a queue; no hazard lamps, no shoulder-use sign. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover [.motorVehicle] carExtent shoulderY 25 k ]
      freeway
      [ ]

/-- `permit` (compliant): The subject car moves at 30 m/s in a mainline lane of the controlled-access highway; its footprint overlaps only that lane. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover [.motorVehicle] carExtent laneY 30 k ]
      freeway
      [ ]

/-- `idle` (not_applicable): The subject car drives on the shoulder of a surface street; it never overlaps a controlled-access region. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover [.motorVehicle] carExtent shoulderY 15 k ]
      [ hwy, mainLane, shoulder,
        Build.rect 2 .controlledAccess (m (-100)) (m 100) (m 400) (m 120) ]
      [ ]

/-- `blind` (unknown): The subject car is on the paved shoulder of a controlled-access highway; the source does not supply kin.speed, so whether it is driven there is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (mover [.motorVehicle] carExtent shoulderY 20 k) (fun kn => { kn with speed := none }) ]
      freeway
      [ ]

/-- `branch_1` (compliant): A transit bus (ru.transit_bus) moves on a paved shoulder of the controlled-access highway, lying on the highway it occupies, governed by a shoulder_use_permitted sign whose conditions admit transit buses. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover [.bus, .transitBus] busExtent shoulderY 15 k ]
      freeway
      [ shoulderSign { vehicleClass := some .transitBus } ]

/-- `branch_2` (not_applicable): The subject car with hazard lamps flashing moves slowly along the shoulder of the controlled-access highway. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withSignals (mover [.motorVehicle] carExtent shoulderY 5 k)
          (fun s => { s with hazard := some true }) ]
      freeway
      [ ]

/-- `branch_3` (violated): The subject car drives across the median of the controlled-access highway. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover [.motorVehicle] carExtent (m 9) 15 k ]
      freeway
      [ ]

/-- `branch_4` (violated): A private car moves on a shoulder governed by a shoulder_use_permitted sign whose conditions admit only transit buses. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover [.motorVehicle] carExtent shoulderY 20 k ]
      freeway
      [ shoulderSign { vehicleClass := some .transitBus } ]

/-- `branch_5` (compliant): A traffic incident management vehicle (ru.official_vehicle, kind incident_management) drives on the paved shoulder of the controlled-access highway, governed by a shoulder_use_permitted sign with no restriction in its legend. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ { mover [.motorVehicle, .officialVehicle] carExtent shoulderY 15 k with
            officialKind := some .incidentManagement } ]
      freeway
      [ shoulderSign {} ]

/-- `branch_6` (not_applicable): A police car (ru.emergency_vehicle) with its red warning lamp
    flashing drives along the shoulder of the controlled-access highway. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withSignals
          ({ mover [.motorVehicle, .emergencyVehicle] carExtent shoulderY 25 k with
              emergencyKind := some .police })
          (fun s => { s with warningLamps := some [⟨.red, .flashing, .front⟩] }) ]
      freeway
      [ ]

/-- `branch_7` (violated): The subject car drives on the unmarked gore pavement of the
    controlled-access highway, overlapping no lane, shoulder or median. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mover [.motorVehicle] carExtent (m 6) 20 k ]
      freeway
      [ ]

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
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .violated ]

end TrafficSpecWitness.NRS_484B_587_2a
