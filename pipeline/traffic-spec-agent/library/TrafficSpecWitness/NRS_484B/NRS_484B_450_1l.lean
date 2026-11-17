/-
  Witnesses for NRS_484B_450_1l.

  Geometry (the witness's own figures, none in the rule): a highway region (1) spanning
  x 0…100 m, y −3…11 m; a road edge (2) along its south side, x 0…100 m, y −1…0 m, lying on the
  highway (`ways := [1]`); lane A (3) y 0…4 m next to the edge, lane B (4) y 4…8 m, both directed
  east (west in branch_4). Every vehicle has half-extents 2.5 m × 1 m × 0.8 m.
  The subject (track 1) stands in lane B at (50, 6); the other vehicle b (track 2) stands in lane A
  at (50, 1.2), so its body (y 0.2…2.2) is 0.2 m from the edge (bound 0.6 m), side by side with the
  subject (overlap 5 m), both b and the edge to the subject's right (−4.8 m and −6 m lateral).
  Three instants, 1 s apart (permit: 0.5 s apart while the subject drives past at 7 m/s).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_450_1l
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_450_1l

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def ext : Q × Q × Q := (cm 250, m 1, cm 80)

def highway : Structure := Build.rect 1 .highway (m 0) (m (-3)) (m 100) (m 11)
def roadEdge : Structure := { Build.rect 2 .roadEdge (m 0) (m (-1)) (m 100) (m 0) with ways := some [1] }
def laneA (dir : Vec) : Structure :=
  Build.lane 3 [(m 0, m 0), (m 100, m 0), (m 100, m 4), (m 0, m 4)] dir
def laneB (dir : Vec) : Structure :=
  Build.lane 4 [(m 0, m 4), (m 100, m 4), (m 100, m 8), (m 0, m 8)] dir

def structures (dir : Vec) : List Structure := [highway, roadEdge, laneA dir, laneB dir]

/-- The subject, at rest or moving, in lane B. -/
def subj (x : Q) (dir : Vec) (v : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, m 6) dir v ext
/-- The other vehicle b, in lane A. -/
def other (x y : Q) (dir : Vec) (v : Q) : RoadUser := Build.user 2 [.motorVehicle] (x, y) dir v ext

def scn (t : Timestamp) (users : List RoadUser) (devices : List Device) (dir : Vec := Build.east) : Scene :=
  Build.scene t (some 1) users (structures dir) devices

def staticTrace (users : List RoadUser) (devices : List Device) (dir : Vec := Build.east) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => scn t users devices dir

/-- The forbid pair: subject at rest beside b, b at rest 0.2 m from the edge. -/
def pair : List RoadUser := [subj (m 50) Build.east (m 0), other (m 50) (cm 120) Build.east (m 0)]

/-- `forbid` (violated): Another ru.aggregate vehicle b is at rest with its body 0.2 m from the right st.road_edge of the highway; the subject, a ru.aggregate vehicle, is at rest to b's left, side by side with it (rel.longitudinal_overlap positive, b's bearing to the subject's right, the edge to the subject's right); no road user is ahead of the subject in its lane, and no human direction or device is in the scene. -/
def forbidTrace : Trace := staticTrace pair []

/-- `permit` (compliant): As in forbid, but the subject moves past b at kin.speed 7 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    scn t [subj (cm (4650 + 350 * (k : Int))) Build.east (Units.metresPerSecond 7),
           other (m 50) (cm 120) Build.east (m 0)] []

/-- `idle` (not_applicable): No other road user is in the scene; the subject is at rest in the middle of its lane. -/
def idleTrace : Trace := staticTrace [subj (m 50) Build.east (m 0)] []

/-- `blind` (unknown): As in forbid, but the source maps the regions without their outlines (st.region_geometry absent), so whether b's body stands at the road edge is not observed. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): As in forbid, but b is moving at kin.speed 5 m/s. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    scn t [subj (m 50) Build.east (m 0),
           other (m (45 + 5 * (k : Int))) (cm 120) Build.east (Units.metresPerSecond 5)] []

/-- `branch_2` (not_applicable): As in forbid, but b is at rest with its body 2.5 m from the road edge. -/
def branch_2Trace : Trace :=
  staticTrace [subj (m 50) Build.east (m 0), other (m 50) (cm 350) Build.east (m 0)] []

/-- `branch_3` (compliant): As in forbid, but a dev.traffic_signal showing circular_red governs the subject's lane. -/
def branch_3Trace : Trace := staticTrace pair [Build.signal 1 [4] [.circularRed]]

/-- `branch_4` (violated): As in forbid mirrored: both vehicles stand heading the other way, so b and the edge lie to the subject's left; the subject is still on b's highway side. -/
def branch_4Trace : Trace :=
  staticTrace [subj (m 50) Build.west (m 0), other (m 50) (cm 120) Build.west (m 0)] [] Build.west

/-- `branch_5` (compliant): As in forbid, with a motor vehicle at rest ahead of the subject in lane B, 2 m between bodies (queue exception). -/
def branch_5Trace : Trace :=
  staticTrace (pair ++ [Build.user 3 [.motorVehicle] (m 57, m 6) Build.east (m 0) ext]) []

/-- `branch_6` (violated): As in branch_5, but the vehicle ahead is 12 m away, beyond the queue gap. -/
def branch_6Trace : Trace :=
  staticTrace (pair ++ [Build.user 3 [.motorVehicle] (m 67, m 6) Build.east (m 0) ext]) []

/-- `branch_7` (compliant): As in forbid, with a stop sign governing lane B. -/
def branch_7Trace : Trace := staticTrace pair [Build.sign 1 .stopSign [4]]

/-- `branch_8` (compliant): As in forbid, with a yield sign governing lane B. -/
def branch_8Trace : Trace := staticTrace pair [Build.sign 1 .yieldSign [4]]

/-- `branch_9` (compliant): As in forbid, with a railway signal governing lane B, lights flashing, gate up. -/
def branch_9Trace : Trace :=
  staticTrace pair [{ Build.device 1 .railwaySignalOrGate [4] with railLights := some .flashing, gate := some .up }]

/-- `branch_10` (compliant): As in forbid, with a railway gate governing lane B, lights dark, gate down. -/
def branch_10Trace : Trace :=
  staticTrace pair [{ Build.device 1 .railwaySignalOrGate [4] with railLights := some .dark, gate := some .down }]

/-- `branch_11` (compliant): As in forbid, with a police officer directing lane B to stop. -/
def branch_11Trace : Trace :=
  staticTrace pair [{ Build.device 1 .humanDirection [4] with humanRole := some .policeOfficer, humanIndication := some .stop }]

/-- `branch_12` (violated): As in branch_11, but the person directing is a flagger. -/
def branch_12Trace : Trace :=
  staticTrace pair [{ Build.device 1 .humanDirection [4] with humanRole := some .flagger, humanIndication := some .stop }]

/-- `branch_13` (violated): As in branch_11, but the officer signals proceed. -/
def branch_13Trace : Trace :=
  staticTrace pair [{ Build.device 1 .humanDirection [4] with humanRole := some .policeOfficer, humanIndication := some .proceed }]

/-- `branch_14` (violated): As in branch_3, but the signal shows circular_green. -/
def branch_14Trace : Trace := staticTrace pair [Build.signal 1 [4] [.circularGreen]]

/-- `branch_15` (violated): As in branch_7, but the stop sign governs lane A only, not the subject's lane. -/
def branch_15Trace : Trace := staticTrace pair [Build.sign 1 .stopSign [3]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_450_1l"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .violated
  , witness "branch_13" branch_13Trace .violated
  , witness "branch_14" branch_14Trace .violated
  , witness "branch_15" branch_15Trace .violated ]

end TrafficSpecWitness.NRS_484B_450_1l
