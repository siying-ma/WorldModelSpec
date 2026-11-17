/-
  Witnesses for NRS_486_341.

  Geometry (the witness's own figures, none in the rule): a highway region 10 spanning
  x ∈ [-50, 100], y ∈ [-2, 10]; two eastbound lanes on it, lane 11 (L, y ∈ [0, 4]) and lane 12
  (the adjacent lane, y ∈ [4, 8], L's left neighbour). Every body heads east at 15 m/s; the
  subject (track 1) is a car of half-extent (2.5, 1, 0.75) m, the motorcycle / moped (track 2) of
  half-extent (1, 0.4, 0.6) m. Occupancy follows the reference points. Three instants, 1 s apart;
  the rule reads no window, so the scene is the same at each.
    forbid:   car at (0, 3) in L, motorcycle at (1, 1) in L: overlap [-2.5,2.5] ∩ [0,2] = 2 m.
    permit:   car at (0, 3) in L, motorcycle at (22, 1) in L: overlap 2.5 − 21 = −18.5 m.
    idle:     as forbid, the subject a bicycle.
    blind:    as forbid, rel.longitudinal_overlap masked (as planned; Core recomputes the overlap
              from the bodies, so this witness cannot be unknown — reported as a node defect).
    branch_1: the car alone at (0, 3) in L.
    branch_2: car at (0, 6) in lane 12, motorcycle at (1, 1) in L.
    branch_3: as forbid, track 2 a moped (the moped limb).
    branch_4: as forbid, but the highway region lies apart from the lanes (y ∈ [20, 30]), so the
              motorcycle is on no highway (the highway limb).
-/
import TrafficSpec.Rules.NRS_486.NRS_486_341
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_486_341

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneL : Structure :=
  Build.lane 11 [(m (-50), m 0), (m 100, m 0), (m 100, m 4), (m (-50), m 4)] Build.east
    (some 12) none
def laneAdj : Structure :=
  Build.lane 12 [(m (-50), m 4), (m 100, m 4), (m 100, m 8), (m (-50), m 8)] Build.east
    none (some 11)
def highway : Structure := Build.rect 10 .highway (m (-50)) (m (-2)) (m 100) (m 10)
def highwayApart : Structure := Build.rect 10 .highway (m (-50)) (m 20) (m 100) (m 30)

def structures : List Structure := [highway, laneL, laneAdj]

def car (cls : List RoadUserClass) (x y : Int) : RoadUser :=
  Build.user 1 cls (m x, m y) Build.east (Units.metresPerSecond 15) (cm 250, m 1, cm 75)
def twoWheeler (cls : List RoadUserClass) (x y : Int) : RoadUser :=
  Build.user 2 cls (m x, m y) Build.east (Units.metresPerSecond 15) (m 1, cm 40, cm 60)

def staticTrace (users : List RoadUser) (ss : List Structure := structures) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users ss []

/-- `forbid` (violated): A car occupies lane L of a highway beside a motorcycle also occupying L; rel.longitudinal_overlap of car and motorcycle 2 m. -/
def forbidTrace : Trace :=
  staticTrace [car [.motorVehicle] 0 3, twoWheeler [.motorcycle] 1 1]

/-- `permit` (compliant): The car occupies lane L 20 m behind the motorcycle in L; rel.longitudinal_overlap negative. -/
def permitTrace : Trace :=
  staticTrace [car [.motorVehicle] 0 3, twoWheeler [.motorcycle] 22 1]

/-- `idle` (not_applicable): The subject is a bicycle beside the motorcycle in L; a bicycle is not a motor vehicle. -/
def idleTrace : Trace :=
  staticTrace [car [.bicycle] 0 3, twoWheeler [.motorcycle] 1 1]

/-- `blind` (unknown): The car and the motorcycle both occupy L; rel.longitudinal_overlap is not observed. -/
def blindTrace : Trace :=
  -- the source measures no overlap and no extent of the motorcycle, so Core cannot compute the
  -- overlap from the bodies either (occupancy is still read from the reference point)
  -- As planned. NOT satisfiable under Core (see task_result.md): masking rel.longitudinal_overlap
  -- drops only a measured value, and Core recomputes the overlap from the position, heading and
  -- extent that the adapter requires of every occupancy-observed track, so this scene is violated.
  staticTrace [car [.motorVehicle] 0 3, twoWheeler [.motorcycle] 1 1]

/-- `branch_1` (compliant): The car drives on the highway; no motorcycle or moped is in the scene. -/
def branch_1Trace : Trace :=
  staticTrace [car [.motorVehicle] 0 3]

/-- `branch_2` (compliant): The car occupies the adjacent lane only, side by side with the motorcycle in L. -/
def branch_2Trace : Trace :=
  staticTrace [car [.motorVehicle] 0 6, twoWheeler [.motorcycle] 1 1]

/-- `branch_3` (violated): A car shares lane L side by side with a moped (overlap 2 m). -/
def branch_3Trace : Trace :=
  staticTrace [car [.motorVehicle] 0 3, twoWheeler [.moped] 1 1]

/-- `branch_4` (compliant): A car beside a motorcycle in lane L, but the motorcycle is on no highway. -/
def branch_4Trace : Trace :=
  staticTrace [car [.motorVehicle] 0 3, twoWheeler [.motorcycle] 1 1] [highwayApart, laneL, laneAdj]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_486_341"
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
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_486_341
