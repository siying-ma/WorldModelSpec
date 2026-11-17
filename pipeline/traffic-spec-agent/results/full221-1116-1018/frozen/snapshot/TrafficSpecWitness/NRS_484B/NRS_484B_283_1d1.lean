/-
  Witnesses for NRS_484B_283_1d1.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - roadway 100: x ∈ [-80, 20] m, y ∈ [-6, 6] m (east–west); in `branch_2` a lane 101 with the
    same rectangle replaces it; both carry an eastward travel direction (read by the composed
    rules). Sidewalk 102 south of it: x ∈ [-80, 20], y ∈ [-10, -6]. A marked crosswalk 103 across
    the roadway at x ∈ [-2, 2], y ∈ [-6, 6], where the pedestrian crosses (so the exceptions for
    pedestrians crossing elsewhere do not engage).
  - pedestrian head 10 at (0, 10), governing the roadway (or the lane), state walk unless stated.
  - pedestrian 2 walks north at 1 m/s along x = 0: y = -9.5 + k at instant k (k = 0 … 7, 1 s
    apart), on the sidewalk for k ≤ 3 and on the roadway from k = 4 (y = -5.5) to k = 7
    (y = -2.5); the head lies dead ahead (cosine 1), 12.5 m to 19.5 m away (reading: 0.87, 40 m).
    The walk from the sidewalk gives the composed rules the history of the pedestrian's entry.
  - subject 1, a motor vehicle, heading east at 8 m/s along y = -2.8, at x = -65.6 + 8k, so at
    k = 7 it is at (-9.6, -2.8): under constant velocities the centres' closest approach is at
    about 1.18 s (horizon 3 s) at about 1.5 m (clearance 3 m). At rest (`permit`) it stays at
    (-9.6, -2.8).
  - the witnesses speak about the instants on the roadway, 4 s to 7 s (`window`).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_283_1d1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_283_1d1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def eastward : LaneInfo := { direction := some Build.east }
def roadway : Structure :=
  { Build.rect 100 .roadway (m (-80)) (m (-6)) (m 20) (m 6) with lane := some eastward }
def laneOnly : Structure :=
  { Build.rect 101 .lane (m (-80)) (m (-6)) (m 20) (m 6) with lane := some eastward }
def sidewalk : Structure := Build.rect 102 .sidewalk (m (-80)) (m (-10)) (m 20) (m (-6))
def crosswalk : Structure :=
  { Build.rect 103 .crosswalk (m (-2)) (m (-6)) (m 2) (m 6) with marked := some true }

def head (governs : List RegionId) (st : Option PedSignalState) : Device :=
  { Build.device 10 .pedestrianSignal governs (some (m 0, m 10)) with pedState := st }

def pedestrian (k : Nat) : RoadUser :=
  Build.user 2 [.pedestrian] (m 0, cm (-950 + 100 * (k : Int))) Build.north
    (Units.metresPerSecond 1) (cm 30, cm 30, cm 90)

def movingVehicle (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm (-6560 + 800 * (k : Int)), cm (-280)) Build.east
    (Units.metresPerSecond 8) (cm 240, cm 90, cm 75)

def stoppedVehicle (_k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm (-960), cm (-280)) Build.east
    (Units.metresPerSecond 0) (cm 240, cm 90, cm 75)

def sceneTrace (users : Nat → List RoadUser) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (users k) structures devices

def withPed (veh : Nat → RoadUser) (k : Nat) : List RoadUser := [veh k, pedestrian k]

/-- `forbid` (violated): A pedestrian on the roadway faces a pedestrian head 12 m ahead that governs that roadway and shows walk; the subject turns toward the crossing at 8 m/s with a predicted closest approach of 0.8 m in 1.2 s. -/
def forbidTrace : Trace :=
  sceneTrace (withPed movingVehicle) [roadway, sidewalk, crosswalk] [head [100] (some .walk)]

/-- `permit` (compliant): Same scene with the subject at rest before the crossing. -/
def permitTrace : Trace :=
  sceneTrace (withPed stoppedVehicle) [roadway, sidewalk, crosswalk] [head [100] (some .walk)]

/-- `idle` (not_applicable): The faced head shows dont_walk_steady. -/
def idleTrace : Trace :=
  sceneTrace (withPed movingVehicle) [roadway, sidewalk, crosswalk] [head [100] (some .dontWalkSteady)]

/-- `blind` (unknown): Same as forbid, but the head's state is not observed. -/
def blindTrace : Trace :=
  sceneTrace (withPed movingVehicle) [roadway, sidewalk, crosswalk] [head [100] (some .walk)]

/-- `branch_1` (not_applicable): The head shows walk but no pedestrian is in the scene: decided for the subject alone as not engaged. -/
def branch_1Trace : Trace :=
  sceneTrace (fun k => [movingVehicle k]) [roadway, sidewalk, crosswalk] [head [100] (some .walk)]

/-- `branch_2` (violated): as forbid, but the pedestrian walks into a lane the head governs (no roadway region): the lane limb of c0/c2. -/
def branch_2Trace : Trace :=
  sceneTrace (withPed movingVehicle) [laneOnly, sidewalk, crosswalk] [head [101] (some .walk)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_283_1d1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (4000, 7000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.pedestrian_signal"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_283_1d1
