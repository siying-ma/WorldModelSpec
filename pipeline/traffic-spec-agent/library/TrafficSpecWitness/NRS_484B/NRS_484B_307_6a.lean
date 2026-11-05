/-
  Witnesses for NRS_484B_307_6a.

  The carriageway. One straight approach runs east between x = −80 m and x = 0 m, four metres
  wide (`approachLane`, a lane whose entrance end is the junction); a second approach of the same
  shape lies beside it, three to seven metres north of the centre line (`adjacentLane`, built only
  where a scene needs it). The junction `junction` is the square between x = 0 m and x = 16 m,
  sixteen metres across; `way` is the highway region that carries both approaches and the junction
  (x from −80 m to 40 m, y from −10 m to 10 m). The signal head `headId` stands over the approach,
  governing the regions each scene names and displaying the indications each scene names.

  The bodies. One body per scene, track 1, four metres long and two wide, heading east; its speed
  is the figure the scene gives (a halted car has an observed velocity of zero). Occupancy is
  stated, not derived: a scene names the regions the body's footprint overlaps, so a body
  straddling the lane and the junction is written as such.

  The instants. Three observations a second apart (0 s, 1 s, 2 s) in every trace.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_6a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_6a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def carTrack : TrackId := 1
def laneId : RegionId := 10
def adjacentLaneId : RegionId := 11
def junctionId : RegionId := 20
def wayId : RegionId := 30
def headId : DeviceId := 1

/-- The approach the subject travels on: a lane whose entrance end is the junction. -/
def approachLane : Structure :=
  Build.lane laneId
    [(m (-80), m (-2)), (m 0, m (-2)), (m 0, m 2), (m (-80), m 2)] Build.east
    (enters := some junctionId)

/-- A second approach to the same junction, beside the first. -/
def adjacentLane : Structure :=
  Build.lane adjacentLaneId
    [(m (-80), m 3), (m 0, m 3), (m 0, m 7), (m (-80), m 7)] Build.east
    (enters := some junctionId)

def junction : Structure := Build.rect junctionId .intersection (m 0) (m (-8)) (m 16) (m 8)

def way : Structure := Build.rect wayId .highway (m (-80)) (m (-10)) (m 40) (m 10)

/-- A car at a place, with the speed the scene gives. -/
def car (x y speed : Int) : RoadUser :=
  Build.user carTrack [.motorVehicle] (m x, m y) Build.east (mps speed) (m 2, m 1, m 1)

/-- A person afoot at a place. -/
def walker (x y : Int) : RoadUser :=
  Build.user carTrack [.pedestrian] (m x, m y) Build.east (mps 1) (cm 30, cm 30, m 1)

/-- A scene: the body, the regions its footprint overlaps, the regions the head governs and the
    indications the head displays. -/
def sceneAt (t : Timestamp) (u : RoadUser) (occ governs : List RegionId)
    (states : List SignalIndication) (extra : List Structure := []) : Scene :=
  Build.scene t (some carTrack) [u] ([approachLane, junction, way] ++ extra)
    [Build.signal headId governs states]
    (some (occ.map fun r => (carTrack, r)))

/-- `forbid` (violated): A car occupies a lane of a highway that signal head H governs and whose entrance end is junction J; H displays circular_yellow alone and nothing else. Three seconds later H displays circular_red, and at that observation the car's footprint begins to overlap J. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (car (-30) 0 12) [laneId, wayId] [laneId, junctionId] [.circularYellow]
    | 1 => sceneAt t (car (-14) 0 12) [laneId, wayId] [laneId, junctionId] [.circularYellow]
    | _ => sceneAt t (car 6 0 12) [junctionId, wayId] [laneId, junctionId] [.circularRed]

/-- `permit` (compliant): The same car on the same lane sees H display circular_yellow alone, brakes and halts; H turns circular_red and the car's footprint never overlaps J while that indication is displayed. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (car (-30) 0 12) [laneId, wayId] [laneId] [.circularYellow]
    | 1 => sceneAt t (car (-12) 0 5) [laneId, wayId] [laneId] [.circularYellow]
    | _ => sceneAt t (car (-6) 0 0) [laneId, wayId] [laneId] [.circularRed]

/-- `idle` (not_applicable): H displays circular_green alone at every observation as the car approaches J on the lane H governs; no yellow indication is displayed at any observation, and the car enters J. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (car (-30) 0 12) [laneId, wayId] [laneId, junctionId] [.circularGreen]
    | 1 => sceneAt t (car (-14) 0 12) [laneId, wayId] [laneId, junctionId] [.circularGreen]
    | _ => sceneAt t (car 6 0 12) [junctionId, wayId] [laneId, junctionId] [.circularGreen]

/-- `blind` (unknown): H is observed displaying circular_yellow alone and then circular_red, and a car on an adjacent roadway enters J; the source declares dev.governs absent, so which regions H governs — and hence whether the car faces it — cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (car (-30) 5 12) [adjacentLaneId, wayId] [laneId, junctionId]
             [.circularYellow] [adjacentLane]
    | 1 => sceneAt t (car (-14) 5 12) [adjacentLaneId, wayId] [laneId, junctionId]
             [.circularRed] [adjacentLane]
    | _ => sceneAt t (car 6 5 12) [junctionId, wayId] [laneId, junctionId]
             [.circularRed] [adjacentLane]

/-- `branch_1` (compliant): The car's footprint already overlaps J when H turns circular_red, having begun to overlap it while H displayed circular_yellow alone; it clears the junction without any new entry. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (car (-20) 0 12) [laneId, wayId] [laneId, junctionId] [.circularYellow]
    | 1 => sceneAt t (car 6 0 12) [junctionId, wayId] [laneId, junctionId] [.circularYellow]
    | _ => sceneAt t (car 14 0 12) [junctionId, wayId] [laneId, junctionId] [.circularRed]

/-- `branch_2` (not_applicable): The road user facing H on the lane it governs is a person afoot — a member of traffic that DEF-NRS-484A-320 leaves out of the vehicle aggregate — who steps into J while H displays circular_red; no vehicle is in the scene. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (walker (-4) 0) [laneId, wayId] [laneId, junctionId] [.circularYellow]
    | 1 => sceneAt t (walker (-2) 0) [laneId, wayId] [laneId, junctionId] [.circularRed]
    | _ => sceneAt t (walker 2 0) [junctionId, wayId] [laneId, junctionId] [.circularRed]

/-- `branch_3` (violated): H governs the approach lane and not the junction itself; the car, still
    on that lane, puts its nose over the junction line while H displays circular_red, having been
    warned by the steady yellow alone two observations earlier. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneAt t (car (-30) 0 12) [laneId, wayId] [laneId] [.circularYellow]
    | 1 => sceneAt t (car (-14) 0 12) [laneId, wayId] [laneId] [.circularYellow]
    | _ => sceneAt t (car 2 0 12) [laneId, junctionId, wayId] [laneId] [.circularRed]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_6a"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_6a
