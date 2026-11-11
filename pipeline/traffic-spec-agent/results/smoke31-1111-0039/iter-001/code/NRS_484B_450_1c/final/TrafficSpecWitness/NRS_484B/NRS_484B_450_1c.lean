/-
  Witnesses for NRS_484B_450_1c.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
  - intersection 1: the square x ∈ [0, 20] m, y ∈ [-10, 10] m;
  - lane 2: the eastbound approach x ∈ [-100, 0] m, y ∈ [0, 4] m, direction east, entering 1;
  - x (track 1): a motor vehicle heading east, half-extents 2.25 × 0.9 × 0.75 m; halted is speed 0,
    moving is 10 m/s (the speed resolution is 0.2 m/s);
  - three scenes one second apart; occupancy is stated per scene.
  The rule reads one observation at a time, so no window is named.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_450_1c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_450_1c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- Intersection 1 and its eastbound approach lane 2. -/
def structures : List Structure :=
  [ Build.rect 1 .intersection (m 0) (m (-10)) (m 20) (m 10)
  , Build.lane 2 [(m (-100), m 0), (m 0, m 0), (m 0, m 4), (m (-100), m 4)] Build.east (enters := some 1) ]

/-- x halted at a point, heading east. -/
def haltedX (x y : Int) : RoadUser := Build.user 1 [.motorVehicle] (m x, m y) Build.east (m 0) carExtent

/-- A scene of three instants with x halted at (10, 2), inside intersection 1. -/
def haltedInside (others : List RoadUser) (occ : List (TrackId × RegionId)) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) (haltedX 10 2 :: others) structures devices (occupies := some ((1, 1) :: occ))

/-- `forbid` (violated): x (ru.motor_vehicle) halts inside intersection i with nothing ahead of it, no emergency vehicle in the scene and no device or officer directing a stop. -/
def forbidTrace : Trace := haltedInside [] [] []

/-- `permit` (compliant): x crosses i without halting; no other road user is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (4 + 6 * (k : Int)), m 2) Build.east (Units.metresPerSecond 10) carExtent ]
      structures [] (occupies := some [(1, 1)])

/-- `idle` (not_applicable): x halts in a lane away from any intersection. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ haltedX (-50) 2 ] structures [] (occupies := some [(1, 2)])

/-- `blind` (unknown): x halts at the edge of i, but the source does not observe whether its footprint overlaps i. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ haltedX (-1) 2 ] structures [] (occupies := some [(1, 1), (1, 2)])

/-- `branch_1` (compliant): x halts inside i behind a halted car ahead of it at a surface gap below p.stopping_conflict_gap. -/
def branch_1Trace : Trace :=
  -- the car ahead: centre 6.5 m ahead, so its body is 2 m from x's
  haltedInside
    [ Build.user 2 [.motorVehicle] (cm 1650, m 2) Build.east (m 0) carExtent ] [(2, 1)] []

/-- `branch_2` (compliant): x halts inside i while a dev.human_direction of role police_officer with indication stop governs i. -/
def branch_2Trace : Trace :=
  haltedInside [] []
    [ { Build.device 1 .humanDirection [1] with
        humanRole := some .policeOfficer, humanIndication := some .stop } ]

/-- An emergency vehicle 30 m behind x in the approach lane, with the given signals. -/
def emergencyBehind (f : Signals → Signals) : RoadUser :=
  Build.withSignals
    (Build.user 2 [.emergencyVehicle] (m (-20), m 2) Build.east (Units.metresPerSecond 8) carExtent) f

/-- `branch_3` (compliant): x halts inside i while an emergency vehicle behind it flashes a red warning lamp, its siren silent. -/
def branch_3Trace : Trace :=
  haltedInside
    [ emergencyBehind fun s => { s with
        warningLamps := some [{ colour := .red, mode := .flashing, facing := .front }], siren := some false } ]
    [(2, 2)] []

/-- `branch_4` (compliant): x halts inside i while an emergency vehicle behind it sounds its siren, no lamp lit. -/
def branch_4Trace : Trace :=
  haltedInside
    [ emergencyBehind fun s => { s with warningLamps := some [], siren := some true } ]
    [(2, 2)] []

/-- `branch_5` (compliant): x halts inside i while a traffic signal governing i shows circular red. -/
def branch_5Trace : Trace :=
  haltedInside [] [] [ Build.signal 1 [1] [.circularRed] ]

/-- `branch_6` (compliant): x halts across the entrance of i, its rear still in approach lane 2, which a stop sign governs. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [ haltedX 2 2 ] structures [ Build.sign 1 .stopSign [2] ]
      (occupies := some [(1, 1), (1, 2)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_450_1c"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant ]

end TrafficSpecWitness.NRS_484B_450_1c
