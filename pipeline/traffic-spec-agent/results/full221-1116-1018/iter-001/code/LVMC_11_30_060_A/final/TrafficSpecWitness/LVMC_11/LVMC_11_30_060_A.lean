/-
  Witnesses for LVMC_11_30_060_A.

  Geometry (the witness's own figures, nowhere in the rule):
  - Roadway 10: x 0..100 m, y 0..7 m, carrying no direction of its own (two-way). Lane 11
    (y 0..3.5, direction east) and lane 12 (y 3.5..7, direction west). In `branch_2` the roadway
    carries no lanes and a designated direction (east) of its own.
  - Crosswalk 13 (marked): x 48..52 m across the roadway, used in `idle` only.
  - Pedestrian, track 1: at x = 50 m, walking north at 1.4 m/s (perpendicular to every carrier
    direction: |cos| = 0 against the 0.94 bound), half-extents 0.3 × 0.3 × 0.9 m.
  - Car, track 2: a motor vehicle at 12 m/s, half-extents 2.9 × 1.05 × 0.75 m.
  - Scenes 1 s apart.
  In `forbid`, the car starts at (26, 3) heading east while the pedestrian is at (50, 1): the centres'
  closest approach comes in about 2 s (within the 3 s horizon) at about 0.8 m (below 3 m), and the
  pedestrian keeps walking at 1.4 m/s (above 0.1 m/s).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_060_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_060_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def walkSpeed : Q := Units.micrometresPerSecond 1400000
def carSpeed : Q := Units.metresPerSecond 12

def roadway : Structure := Build.rect 10 .roadway (m 0) (m 0) (m 100) (m 7)
def laneEast : Structure :=
  Build.lane 11 [(m 0, m 0), (m 100, m 0), (m 100, cm 350), (m 0, cm 350)] Build.east
def laneWest : Structure :=
  Build.lane 12 [(m 0, cm 350), (m 100, cm 350), (m 100, m 7), (m 0, m 7)] Build.west
def crosswalk : Structure :=
  { Build.rect 13 .crosswalk (m 48) (m 0) (m 52) (m 7) with marked := some true }
def directedRoadway : Structure :=
  { roadway with lane := some { direction := some Build.east } }
def laned : List Structure := [roadway, laneEast, laneWest]

/-- The pedestrian at (50, y), walking north at `speed`. -/
def ped (y : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.pedestrian] (m 50, y) Build.north speed (cm 30, cm 30, cm 90)

/-- A car at (x, y) with heading `h` at 12 m/s. -/
def car (x y : Q) (h : Vec) : RoadUser :=
  Build.user 2 [.motorVehicle] (x, y) h carSpeed (cm 290, cm 105, cm 75)

/-- Pedestrian's y at scene k when walking from y = 1 m at 1.4 m/s. -/
def pedY (k : Nat) : Q := cm (100 + 140 * (k : Int))

/-- Car heading east from x = x0 at 12 m/s. -/
def carX (x0 : Int) (k : Nat) : Q := m (x0 + 12 * (k : Int))

/-- `forbid` (violated): A pedestrian crosses a laned roadway mid-block at 1.4 m/s; a car on that roadway at 12 m/s would come within 1 m of the pedestrian's centre in 2 s, and the pedestrian keeps walking. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (pedY k) walkSpeed, car (carX 26 k) (m 3) Build.east ]
      laned
      [ ]

/-- `permit` (compliant): A pedestrian crosses the roadway mid-block at 1.4 m/s; no vehicle is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (pedY k) walkSpeed ]
      laned
      [ ]

/-- `idle` (not_applicable): A pedestrian crosses the roadway within a marked crosswalk while a car approaches. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (pedY k) walkSpeed, car (carX 26 k) (m 3) Build.east ]
      (laned ++ [crosswalk])
      [ ]

/-- `blind` (unknown): A pedestrian occupies the roadway mid-block while a car approaches, but the pedestrian's velocity is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (pedY k) walkSpeed, car (carX 10 k) (m 3) Build.east ]
      laned
      [ ]

/-- `branch_1` (compliant): A pedestrian crossing mid-block halts in the lane while a car on the roadway passes 4 m ahead of it, then walks on once the car has gone; no conflict is projected while the pedestrian moves. -/
def branch_1Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (if k < 3 then ped (m 1) Q.zero else ped (pedY (k - 3)) walkSpeed)
      , car (m (74 - 12 * (k : Int))) (m 5) Build.west ]
      laned
      [ ]

/-- `branch_2` (violated): the forbid encounter on an unlaned roadway that carries its own designated
    direction: the pedestrian moves across the roadway itself, and keeps walking into the conflict. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (pedY k) walkSpeed, car (carX 26 k) (m 3) Build.east ]
      [ directedRoadway ]
      [ ]

/-- `branch_3` (violated): the rear of a car clips the crossing pedestrian as it passes; the centres
    already recede (no conflict projected), but the bodies touch. -/
def branch_3Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (pedY k) walkSpeed, car (carX 52 k) (cm 150) Build.east ]
      laned
      [ ]

/-- A pedestrians_prohibited regulatory sign governing the roadway. -/
def prohibition : Device :=
  { Build.sign 20 .regulatorySign [10] with
      code := some .pedestriansProhibited
      conditions := some {} }

/-- `branch_4` (not_applicable): the forbid encounter where a pedestrians_prohibited sign governs the
    roadway crossed: the section has no application there (f8). -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (pedY k) walkSpeed, car (carX 26 k) (m 3) Build.east ]
      laned
      [ prohibition ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_30_060_A"
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_30_060_A
