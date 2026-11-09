/-
  Witnesses for NRS_484B_250_4_o1.

  The geometry (one layout, shared by every scenario; every figure here is the witness's own and
  appears nowhere in the rule). The world frame has +x east. A two-lane street runs east-west and
  meets a crossing street at a four-way junction:

    region 1  the junction            x ∈ [0, 12],    y ∈ [-6, 6]      (on ways 10 and 11)
    region 2  the eastbound approach  x ∈ [-80, 0],   y ∈ [-3, 0]      lane, direction east,
                                                                        entrance end: region 1,
                                                                        on way 10
    region 3  a stop line             x ∈ [-7, -6.5], y ∈ [-3, 0]
    region 4  a marked crosswalk      x ∈ [-6, -3],   y ∈ [-3, 0]
    region 10 the east-west highway   x ∈ [-80, 12],  y ∈ [-6, 6]
    region 11 the crossing highway    x ∈ [0, 12],    y ∈ [-60, 60]
    device 5  a signal head governing the junction

  Track 1 is a car 5 m long and 2 m wide (half-extents 2.5 m, 1 m, 1 m) on the lane centre
  (y = -1.5 m), heading east, so its footprint spans [x - 2.5, x + 2.5] × [-2.5, -0.5]: it overlaps
  the junction from x = -2.5 m on, and the lane until x = 2.5 m. Occupancy is written as the
  footprint's overlap with each boundary, as closed sets, which is what Core derives from the
  geometry.

  The sight along the crossing way (11) is the figure each scenario names per observation; the
  sight along the car's own way (10) is 300 m throughout, so a scenario shows that the way read is
  the crossing one. Scenes are one second apart.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

/-- The car: its position along the lane centre, its speed, and the sight along the crossing way. -/
def car (px : Q) (speed : Q) (sight : Q) : RoadUser :=
  { Build.user 1 [.motorVehicle] (px, cm (-150)) Build.east speed (cm 250, m 1, m 1) with
      sightAlongWay := some [(11, sight), (10, m 300)] }

def junction : Structure :=
  { Build.rect 1 .intersection (m 0) (m (-6)) (m 12) (m 6) with ways := some [10, 11] }

def approach : Structure :=
  { Build.lane 2 [(m (-80), m (-3)), (m 0, m (-3)), (m 0, m 0), (m (-80), m 0)] Build.east
      (enters := some 1) with ways := some [10] }

/-- A stop line recorded as marking the approach's entrance. -/
def stopLine : Structure :=
  { Build.rect 3 .stopLine (m (-7)) (m (-3)) (cm (-650)) (m 0) with
      entranceOf := [2], entranceObserved := true, ways := some [10] }

/-- A stop line whose entrances are observed and do not include the approach. -/
def foreignStopLine : Structure :=
  { Build.rect 3 .stopLine (m (-7)) (m (-3)) (cm (-650)) (m 0) with
      entranceObserved := true, ways := some [10] }

/-- A marked crosswalk recorded as marking the approach's entrance. -/
def crosswalk : Structure :=
  { Build.rect 4 .crosswalk (m (-6)) (m (-3)) (m (-3)) (m 0) with
      marked := some true, entranceOf := [2], entranceObserved := true, ways := some [10] }

/-- A marked crosswalk whose entrances are observed and do not include the approach. -/
def foreignCrosswalk : Structure :=
  { Build.rect 4 .crosswalk (m (-6)) (m (-3)) (m (-3)) (m 0) with
      marked := some true, entranceObserved := true, ways := some [10] }

def ownWay : Structure := Build.rect 10 .highway (m (-80)) (m (-6)) (m 12) (m 6)
def crossWay : Structure := Build.rect 11 .highway (m 0) (m (-60)) (m 12) (m 60)

/-- Installed, faces uncovered, showing no valid indication. -/
def deadSignal : Device :=
  { Build.signal 5 [1] [SignalIndication.dark] with uncovered := some true, inoperative := some true }

/-- Installed, faces uncovered, showing a steady circular red: not inoperative. -/
def redSignal : Device :=
  { Build.signal 5 [1] [SignalIndication.circularRed] with
      uncovered := some true, inoperative := some false }

/-- Installed and uncovered; whether it shows a valid indication is not reported. -/
def mutedSignal : Device :=
  { Build.signal 5 [1] [SignalIndication.dark] with uncovered := some true }

/-- The occupancy the geometry gives: the pair (track, region) exactly where the car's footprint
    and the region's boundary overlap as closed sets. -/
def occupancyOf (u : RoadUser) (sts : List Structure) : List (TrackId × RegionId) :=
  let s : Scene := { t := 0, users := [u], structures := sts }
  match footprint s u.track with
  | none => []
  | some fp => sts.filterMap fun st =>
      match st.boundary with
      | some poly => if Geom.polygonsOverlap fp poly then some (u.track, st.id) else none
      | none => none

def sceneAt (t : Timestamp) (u : RoadUser) (sts : List Structure) (dvs : List Device) : Scene :=
  Build.scene t (some 1) [u] sts dvs (some (occupancyOf u sts))

/-- The map with a stop line marking the approach. -/
def lineMap : List Structure := [junction, approach, stopLine, ownWay, crossWay]
/-- The map with a crosswalk, and no stop line at all. -/
def crossingMap : List Structure := [junction, approach, crosswalk, ownWay, crossWay]
/-- The map whose stop line and crosswalk are observed to mark some other carrier. -/
def unmarkedMap : List Structure := [junction, approach, foreignStopLine, foreignCrosswalk, ownWay, crossWay]
/-- The bare map: no stop line, no crosswalk. -/
def bareMap : List Structure := [junction, approach, ownWay, crossWay]

/-- `forbid` (violated): A car approaches a four-way junction whose signal heads are installed, uncovered and dark with no valid indication. A stop line is recorded as marking the lane the car occupies, the lane's entrance end is that junction, and the car crosses the line and enters the junction without its speed ever falling to the standstill tolerance anywhere on the approach from the line's upstream zone onward. No other road user is in the scene. -/
def forbidTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let u := match k with
      | 0 => car (m (-20)) (mps 8) (m 40)       -- upstream of the line by 10.5 m: the start of the approach
      | 1 => car (m (-12)) (mps 8) (m 60)       -- still 2.5 m short of the line
      | 2 => car (cm (-390)) (mps 8) (m 120)    -- past the line, still short of the junction
      | 3 => car (m 2) (mps 8) (m 150)          -- the footprint comes to overlap the junction
      | _ => car (m 10) (mps 8) (m 150)
    sceneAt t u lineMap [deadSignal]

/-- `permit` (compliant): The same junction and the same inoperative signal. The car halts with its speed at zero while its body is within the stop-point tolerance of the stop line marking its lane and short of the line, then moves off and enters the junction. The scene contains no other road user, and the verdict is still decided. -/
def permitTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    let u := match k with
      | 0 => car (m (-20)) (mps 8) (m 40)       -- the start of the approach
      | 1 => car (m (-11)) (mps 4) (m 60)       -- body 1.5 m short of the line
      | 2 => car (m (-10)) (mps 0) (m 60)       -- halted, body 0.5 m short of the line
      | 3 => car (cm (-390)) (mps 4) (m 120)    -- moving off, past the line
      | 4 => car (m 2) (mps 4) (m 150)          -- entry
      | _ => car (m 10) (mps 8) (m 150)
    sceneAt t u lineMap [deadSignal]

/-- `idle` (not_applicable): The same junction, but the signal governing it shows a steady circular red and is not inoperative. The car enters the junction without halting: the trigger does not hold, so the rule is not engaged. -/
def idleTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let u := match k with
      | 0 => car (m (-20)) (mps 8) (m 40)
      | 1 => car (m (-12)) (mps 8) (m 60)
      | 2 => car (cm (-390)) (mps 8) (m 120)
      | 3 => car (m 2) (mps 8) (m 150)
      | _ => car (m 10) (mps 8) (m 150)
    sceneAt t u lineMap [redSignal]

/-- `blind` (unknown): The car enters the junction without halting, the signal is installed and uncovered, but the source does not report whether the head is showing a valid indication, so whether it was inoperative at the entry is unknown and the rule reports unknown. -/
def blindTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let u := match k with
      | 0 => car (m (-20)) (mps 8) (m 40)
      | 1 => car (m (-12)) (mps 8) (m 60)
      | 2 => car (cm (-390)) (mps 8) (m 120)
      | 3 => car (m 2) (mps 8) (m 150)
      | _ => car (m 10) (mps 8) (m 150)
    sceneAt t u lineMap [mutedSignal]

/-- `branch_1` (compliant): A junction with the same inoperative signal where the lane's stop lines and crosswalks are observed and none marks the car's lane. The car halts, with its speed at zero, on its lane at the point nearest the junction at which the sight along the crossing way reaches the view distance, then enters: the third place in the words' order governs and the duty is met. -/
def branch_1Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let u := match k with
      | 0 => car (m (-20)) (mps 8) (m 40)       -- the way is visible 40 m: short of the view point
      | 1 => car (m (-10)) (mps 4) (m 60)       -- 60 m: still short of it
      | 2 => car (cm (-390)) (mps 0) (m 120)    -- halted where the way is visible 120 m
      | 3 => car (m 2) (mps 4) (m 150)          -- entry
      | _ => car (m 10) (mps 8) (m 150)
    sceneAt t u unmarkedMap [deadSignal]

/-- `branch_2` (violated): The same junction and inoperative signal, with no stop line but a marked crosswalk recorded as marking the car's lane. The car slows to a crawl above the standstill tolerance before the crosswalk and rolls into the junction: the second place in the words' order governs and no halt is found on the approach. -/
def branch_2Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let u := match k with
      | 0 => car (m (-20)) (mps 8) (m 40)       -- the start of the approach, 11.5 m short of the crossing
      | 1 => car (m (-12)) (mps 3) (m 60)       -- 3.5 m short of the crossing
      | 2 => car (m (-8)) (mps 1) (m 120)       -- crawling, body over the crossing
      | 3 => car (m 2) (mps 3) (m 150)          -- entry
      | _ => car (m 10) (mps 8) (m 150)
    sceneAt t u crossingMap [deadSignal]

/-- `branch_3` (violated): no stop line and no crosswalk at all, so the view point governs; the car
    passes the point from which the crossing way is visible to the view distance without halting. -/
def branch_3Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let u := match k with
      | 0 => car (m (-20)) (mps 8) (m 40)
      | 1 => car (m (-10)) (mps 8) (m 60)
      | 2 => car (cm (-390)) (mps 8) (m 120)    -- the view point, taken at speed
      | 3 => car (m 2) (mps 8) (m 150)          -- entry
      | _ => car (m 10) (mps 8) (m 150)
    sceneAt t u bareMap [deadSignal]

/-- `branch_4` (compliant): the crosswalk marking the lane governs, and the car halts short of it
    within the stop-point tolerance before entering. -/
def branch_4Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    let u := match k with
      | 0 => car (m (-20)) (mps 8) (m 40)       -- the start of the approach
      | 1 => car (m (-10)) (mps 2) (m 60)       -- body 1.5 m short of the crossing
      | 2 => car (cm (-920)) (mps 0) (m 60)     -- halted, body 0.7 m short of the crossing
      | 3 => car (cm (-390)) (mps 3) (m 120)    -- moving off, body over the crossing
      | 4 => car (m 2) (mps 3) (m 150)          -- entry
      | _ => car (m 10) (mps 8) (m 150)
    sceneAt t u crossingMap [deadSignal]

/-- `branch_5` (violated): the recording begins inside the line's stopping zone; the car enters the
    junction, reverses out of it without ever halting and without reaching the line's upstream
    zone, then enters again. The search back from the second entry ends at its own earlier presence
    in the junction, so the duty is violated there. -/
def branch_5Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let u := match k with
      | 0 => car (cm (-350)) (mps 5) (m 120)    -- between the line and the junction
      | 1 => car (m 2) (mps 5) (m 150)          -- the first entry
      | 2 => car (m (-3)) (mps 3) (m 120)       -- backed out of the junction, still past the line
      | 3 => car (m 2) (mps 3) (m 150)          -- the second entry
      | _ => car (m 10) (mps 5) (m 150)
    sceneAt t u lineMap [deadSignal]

/-- `history_boundary` (unknown): The recording begins with the car already between the stop line and the junction, inside the line's stopping zone, and the car then enters the junction while the signal is inoperative. No halt is recorded, and the recording contains neither the start of the approach upstream of the line nor a previous entry of the car into that junction, so no recorded act and no visible end of the search decides the verdict. -/
def history_boundaryTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let u := match k with
      | 0 => car (m (-6)) (mps 5) (m 120)       -- body over the line, inside its stopping zone
      | 1 => car (cm (-350)) (mps 5) (m 120)    -- 0.5 m past the line
      | 2 => car (m 2) (mps 5) (m 150)          -- entry
      | _ => car (m 10) (mps 5) (m 150)
    sceneAt t u lineMap [deadSignal]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.inoperative"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the stretch of the approach upstream of the stop line's stopping zone, at which the car entered that zone, lies before the first observation of the recording") ]

end TrafficSpecWitness.NRS_484B_250_4_o1
