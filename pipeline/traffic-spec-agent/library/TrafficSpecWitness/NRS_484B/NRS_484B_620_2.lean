/-
  Witnesses for NRS_484B_620_2.

  Geometry (the witness's own figures, nowhere in the rule): a highway region 1, the rectangle
  x ∈ [0, 200] m, y ∈ [-10, 10] m; on it two eastbound lanes, lane 2 (y ∈ [0, 4] m) and lane 3
  (y ∈ [-4, 0] m), each with `ways := [1]`. The subject, track 1, is a motor vehicle at
  (50 m, 2 m) in lane 2 (or at (50 m, -2 m) in lane 3), heading east, half-extent 2 × 1 × 1 m.
  Device 10 is a speed_zone zone sign (not an end sign), device 11 a speed limit sign of kind
  zone at 20 m/s, both governing lane 2 unless stated. Three instants, 1 s apart; nothing looks
  back, so no window is named. The place is outside any incorporated city unless stated.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_620_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_620_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

def asmCity : AsmId := "asm.within_incorporated_city"

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 1 .highway (m 0) (m (-10)) (m 200) (m 10)

def laneOn (id : RegionId) (y0 y1 : Int) (ways : List RegionId) : Structure :=
  { Build.rect id .lane (m 0) (m y0) (m 200) (m y1) with
      ways := some ways
      lane := some { direction := some Build.east } }

def lane2 : Structure := laneOn 2 0 4 [1]
def lane3 : Structure := laneOn 3 (-4) 0 [1]

def car (classes : List RoadUserClass) (y : Int) (speed : Q) : RoadUser :=
  Build.user 1 classes (m 50, m y) Build.east speed (m 2, m 1, m 1)

def speedZoneSign (governs : List RegionId) : Device := Build.zoneSign 10 governs .speedZone false
def zoneLimit20 (governs : List RegionId) : Device := Build.speedLimit 11 governs (mps 20) .zone

/-- A three-instant trace of one scene. -/
def sceneTrace (u : RoadUser) (structures : List Structure) (devices : List Device)
    (inCity : Bool := false) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [u] structures devices (assumptions := [(asmCity, inCity)])

/-- `forbid` (violated): A car outside any incorporated city (asm.within_incorporated_city false) occupies a lane on a highway governed by a speed_zone zone sign and a zone speed limit sign of 20 m/s; its speed is 25 m/s. -/
def forbidTrace : Trace :=
  sceneTrace (car [.motorVehicle] 2 (mps 25)) [highway, lane2, lane3]
    [speedZoneSign [2], zoneLimit20 [2]]

/-- `permit` (compliant): The same scene with the car at 18 m/s. -/
def permitTrace : Trace :=
  sceneTrace (car [.motorVehicle] 2 (mps 18)) [highway, lane2, lane3]
    [speedZoneSign [2], zoneLimit20 [2]]

/-- `idle` (not_applicable): A car outside any city on a highway lane that no speed_zone zone sign governs; only a general maximum speed sign is present. -/
def idleTrace : Trace :=
  sceneTrace (car [.motorVehicle] 2 (mps 25)) [highway, lane2, lane3]
    [Build.speedLimit 12 [2] (mps 20) .maximum]

/-- `blind` (unknown): As in forbid, but the source does not supply the car's speed. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): As in forbid, but the reading declares the place within an incorporated city (asm.within_incorporated_city true): it is no road. -/
def branch_1Trace : Trace :=
  sceneTrace (car [.motorVehicle] 2 (mps 25)) [highway, lane2, lane3]
    [speedZoneSign [2], zoneLimit20 [2]] (inCity := true)

/-- `branch_2` (not_applicable): As in forbid, but the speed_zone sign marks the zone's end. -/
def branch_2Trace : Trace :=
  sceneTrace (car [.motorVehicle] 2 (mps 25)) [highway, lane2, lane3]
    [Build.zoneSign 10 [2] .speedZone true, zoneLimit20 [2]]

/-- `branch_3` (not_applicable): As in forbid, but the lane lies on no highway (a lane of no public way). -/
def branch_3Trace : Trace :=
  sceneTrace (car [.motorVehicle] 2 (mps 25)) [highway, laneOn 2 0 4 [], laneOn 3 (-4) 0 []]
    [speedZoneSign [2], zoneLimit20 [2]]

/-- `branch_4` (not_applicable): As in forbid, but the only speed limit sign is a minimum sign. -/
def branch_4Trace : Trace :=
  sceneTrace (car [.motorVehicle] 2 (mps 25)) [highway, lane2, lane3]
    [speedZoneSign [2], Build.speedLimit 11 [2] (mps 20) .minimum]

/-- `branch_5` (not_applicable): As in forbid, but the zone sign is a school zone sign, not a speed zone. -/
def branch_5Trace : Trace :=
  sceneTrace (car [.motorVehicle] 2 (mps 25)) [highway, lane2, lane3]
    [Build.zoneSign 10 [2] .school false, zoneLimit20 [2]]

/-- `branch_6` (not_applicable): The car at 25 m/s is in lane 3; the speed-zone signs govern lane 2 only. -/
def branch_6Trace : Trace :=
  sceneTrace (car [.motorVehicle] (-2) (mps 25)) [highway, lane2, lane3]
    [speedZoneSign [2], zoneLimit20 [2]]

/-- `branch_7` (not_applicable): As in forbid, but the road user is a bicycle, no motor vehicle. -/
def branch_7Trace : Trace :=
  sceneTrace (car [.bicycle] 2 (mps 25)) [highway, lane2, lane3]
    [speedZoneSign [2], zoneLimit20 [2]]

/-- `branch_8` (violated): A speed zone with a maximum sign of 30 m/s and a zone sign of 20 m/s; the car at 25 m/s exceeds the zone value. -/
def branch_8Trace : Trace :=
  sceneTrace (car [.motorVehicle] 2 (mps 25)) [highway, lane2, lane3]
    [speedZoneSign [2], Build.speedLimit 12 [2] (mps 30) .maximum, zoneLimit20 [2]]

/-- `branch_9` (violated): A speed zone whose only speed limit sign is a maximum sign of 20 m/s; the car at 25 m/s exceeds it. -/
def branch_9Trace : Trace :=
  sceneTrace (car [.motorVehicle] 2 (mps 25)) [highway, lane2, lane3]
    [speedZoneSign [2], Build.speedLimit 12 [2] (mps 20) .maximum]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_620_2"
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
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated ]

end TrafficSpecWitness.NRS_484B_620_2
