/-
  Witnesses for NRS_484B_257_2_o1.

  Geometry (the witness's own figures; none appears in the rule). World frame +x east, +y north.
  - Lane c (region 10): x ∈ [-80, 0] m, y ∈ [0, 4] m, direction east, entering intersection X.
  - Intersection X (region 20): x ∈ [0, 20] m, y ∈ [-10, 14] m.
  - Stop line L (region 30): x ∈ [-3, -2.5] m across c, marking c's entrance (list observed).
  - Crosswalk W (region 40, branch_6 only): x ∈ [-4, -1] m across c, marking c's entrance.
  - Subject (track 1): a motor vehicle, half-extents 2 × 1 × 1 m, heading east along y = 2 m;
    its footprint spans [x − 2, x + 2] m along c. Occupancy is stated from that footprint.
  - Devices: stop sign 100, yield sign 101, traffic signal 102, police officer 103; each scene
    lists which govern c or X.
  Instants are 1 s apart from t = 0. With the reading's tolerance 2 m, a halt with the body 1 m
  short of the mark is in the stopping zone; an observation 5 m or more short of it is the
  approach start. Halt speed 0 (≤ 0.1 m/s); slowed speed 3 m/s (≤ 4.2 m/s); fast 10 m/s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_2_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_2_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def cId : RegionId := 10
def xId : RegionId := 20
def lineId : RegionId := 30
def walkId : RegionId := 40

def laneC : Structure :=
  Build.lane cId [(m (-80), m 0), (m 0, m 0), (m 0, m 4), (m (-80), m 4)] Build.east (enters := some xId)
def interX : Structure := Build.rect xId .intersection (m 0) (m (-10)) (m 20) (m 14)
def stopLine : Structure :=
  { Build.rect lineId .stopLine (cm (-300)) (m 0) (cm (-250)) (m 4) with
      entranceOf := [cId], entranceObserved := true }
def crosswalk : Structure :=
  { Build.rect walkId .crosswalk (m (-4)) (m 0) (m (-1)) (m 4) with
      entranceOf := [cId], entranceObserved := true, marked := some true }

def otherLaneId : RegionId := 11
def otherInterId : RegionId := 21

/-- branch_9 only: a westbound carrier c' on c's footprint, entering intersection Y west of it. -/
def laneOther : Structure :=
  Build.lane otherLaneId [(m (-80), m 0), (m 0, m 0), (m 0, m 4), (m (-80), m 4)] Build.west (enters := some otherInterId)
def interY : Structure := Build.rect otherInterId .intersection (m (-100)) (m (-10)) (m (-80)) (m 14)

def withLine : List Structure := [laneC, interX, stopLine]
def bare : List Structure := [laneC, interX]
def withWalk : List Structure := [laneC, interX, crosswalk]
def withOther : List Structure := [laneC, interX, laneOther, interY]

def stopSign (gov : List RegionId) : Device := Build.sign 100 .stopSign gov
def yieldSign (gov : List RegionId) : Device := Build.sign 101 .yieldSign gov
def operatingSignal (gov : List RegionId) (shows : SignalIndication) : Device :=
  { Build.signal 102 gov [shows] with uncovered := some true, inoperative := some false }
def darkSignal (gov : List RegionId) : Device :=
  { Build.signal 102 gov [.dark] with uncovered := some true, inoperative := some true }
def officer (gov : List RegionId) : Device :=
  { Build.device 103 .humanDirection gov with
      humanRole := some .policeOfficer, humanIndication := some .proceed }

/-- One observation: the reference point's x (cm) and the speed. -/
structure Step where
  x : Int
  v : Q

/-- Occupancy from the footprint [x − 2 m, x + 2 m] along c. -/
def occupancy (structs : List Structure) (x : Int) : List (TrackId × RegionId) :=
  let lo := x - 200
  let hi := x + 200
  let has (r : RegionId) : Bool := structs.any (·.id == r)
  (if lo < 0 then [(1, cId)] else []) ++
  (if has otherLaneId && lo < 0 then [(1, otherLaneId)] else []) ++
  (if hi > 0 then [(1, xId)] else []) ++
  (if has lineId && hi > -300 && lo < -250 then [(1, lineId)] else []) ++
  (if has walkId && hi > -400 && lo < -100 then [(1, walkId)] else [])

def subjectAt (st : Step) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm st.x, m 2) Build.east st.v (m 2, m 1, m 1)

def run (steps : List Step) (structs : List Structure) (devs : List Device) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    let st := steps.getD k ⟨0, Q.zero⟩
    Build.scene t (some 1) [subjectAt st] structs devs (occupies := some (occupancy structs st.x))

def v (n : Int) : Q := Units.metresPerSecond n

/-- Fast throughout: 30, 20, 10 m short of X (approach start), then on the stop line, then in X. -/
def fastSteps : List Step :=
  [⟨-3000, v 10⟩, ⟨-2000, v 10⟩, ⟨-1000, v 10⟩, ⟨-300, v 10⟩, ⟨400, v 10⟩, ⟨1000, v 10⟩]

/-- Halts with the body 1 m short of the stop line, then crosses it and enters X. -/
def haltSteps : List Step :=
  [⟨-2000, v 6⟩, ⟨-1200, v 4⟩, ⟨-600, v 0⟩, ⟨-400, v 2⟩, ⟨100, v 3⟩, ⟨800, v 5⟩]

/-- `forbid` (violated): A dev.stop_sign governs carrier c entering X; a st.stop_line marks c; no officer or operating signal. The subject passes the line and enters X with kin.speed well above p.halt_speed_tolerance, never halting since it was upstream of the line's stopping zone. -/
def forbidTrace : Trace := run fastSteps withLine [stopSign [cId]]

/-- `permit` (compliant): Same scene; the subject halts on c with the line just ahead within p.stop_point_tolerance, then enters X. -/
def permitTrace : Trace := run haltSteps withLine [stopSign [cId]]

/-- `idle` (not_applicable): No stop or yield sign governs c or X; the subject enters X without halting. -/
def idleTrace : Trace := run fastSteps withLine []

/-- `blind` (unknown): Stop sign governing c; kin.speed is absent, so whether the subject halted is unknown. -/
def blindTrace : Trace := run haltSteps withLine [stopSign [cId]]

/-- `history_boundary` (unknown): Stop sign governing c; the recording begins with the subject already within p.stop_point_tolerance of the stop line, moving slowly; no halt is recorded before its entry into X. -/
def history_boundaryTrace : Trace :=
  run [⟨-600, v 1⟩, ⟨-400, v 1⟩, ⟨100, v 2⟩, ⟨800, v 2⟩] withLine [stopSign [cId]]

/-- `branch_1` (compliant): Only a dev.yield_sign governs c; no stop line or crosswalk marks c; the subject reaches X's edge at kin.speed at or below p.yield_line_speed_max and enters. -/
def branch_1Trace : Trace :=
  run [⟨-2000, v 8⟩, ⟨-1000, v 6⟩, ⟨-300, v 3⟩, ⟨300, v 3⟩, ⟨900, v 4⟩] bare [yieldSign [cId]]

/-- `branch_2` (not_applicable): A stop sign governs c, but an operating dev.traffic_signal (circular_red) also governs c at the subject's entry. -/
def branch_2Trace : Trace := run fastSteps withLine [stopSign [cId], operatingSignal [cId] .circularRed]

/-- `branch_3` (not_applicable): a stop sign governs c, and a police officer directing traffic governs c. -/
def branch_3Trace : Trace := run fastSteps withLine [stopSign [cId], officer [cId]]

/-- `branch_4` (violated): a stop sign governs X; a traffic signal governing c is inoperative (dark), so the exception does not hold; the subject never halts. -/
def branch_4Trace : Trace := run fastSteps withLine [stopSign [xId], darkSignal [cId]]

/-- `branch_5` (violated): only a yield sign, governing X; no mark on c; the subject reaches X's edge at 10 m/s, above p.yield_line_speed_max. -/
def branch_5Trace : Trace := run fastSteps bare [yieldSign [xId]]

/-- `branch_6` (compliant): a stop sign governs c; no stop line, a crosswalk marks c; the subject halts with the crosswalk 1 m ahead, not overlapping it, then crosses and enters X. -/
def branch_6Trace : Trace :=
  run [⟨-2000, v 8⟩, ⟨-1200, v 5⟩, ⟨-700, v 0⟩, ⟨-200, v 3⟩, ⟨300, v 3⟩, ⟨900, v 4⟩] withWalk [stopSign [cId]]

/-- `branch_7` (not_applicable): a stop sign governs c, and an operating traffic signal (circular_green) governs X. -/
def branch_7Trace : Trace := run fastSteps withLine [stopSign [cId], operatingSignal [xId] .circularGreen]

/-- `branch_8` (not_applicable): a stop sign governs c, and a police officer directing traffic governs X. -/
def branch_8Trace : Trace := run fastSteps withLine [stopSign [cId], officer [xId]]

/-- `branch_9` (compliant): a yield sign governs c; a stop sign governs only c', a westbound carrier on c's footprint that enters another intersection Y; no mark on c; the subject reaches X's edge at 3 m/s and enters X. The stop sign at Y's entrance owes no halt at X. -/
def branch_9Trace : Trace :=
  run [⟨-2000, v 8⟩, ⟨-1000, v 6⟩, ⟨-300, v 3⟩, ⟨300, v 3⟩, ⟨900, v 4⟩] withOther
    [yieldSign [cId], stopSign [otherLaneId]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_2_o1"
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
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach start: the subject's last observation outside the stop line's stopping zone upstream on c lies before the recording")
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .compliant ]

end TrafficSpecWitness.NRS_484B_257_2_o1
