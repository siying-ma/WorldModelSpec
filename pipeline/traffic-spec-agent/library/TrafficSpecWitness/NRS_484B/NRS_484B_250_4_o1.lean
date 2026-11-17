/-
  Witnesses for NRS_484B_250_4_o1.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - intersection X = region 1, the rectangle x ∈ [0, 20], y ∈ [-10, 10];
  - carrier c = lane 2, x ∈ [-60, 0], y ∈ [0, 4], direction east, entering X;
  - stop line 3 marking c: x ∈ [-10, -9.7], y ∈ [0, 4];
  - crosswalk 4 marking c: x ∈ [-4, 0], y ∈ [-10, 10];
  - for the "no mark for c" scenes, an opposite approach lane 5 (x ∈ [20, 80], y ∈ [-4, 0],
    direction west, entering X) with its own stop line 6 and crosswalk 7, whose entrance lists
    are observed and name lane 5 only;
  - signal 1, uncovered, governing lane 2 (or X in branch_4), dark and inoperative (circular
    green and operative in idle).
  The subject (track 1) is a motor vehicle, half-length 2 m, half-width 1 m, centred on y = 2,
  heading east; its body spans [x − 2, x + 2]. Observations are 1 s apart; occupancy is stated
  per observation from the body's span. Reading values: halt speed tolerance 0.1 m/s, stop-point
  tolerance 2 m; a halt is speed 0, a creep 1 m/s, a run 6–10 m/s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def junction : Structure := Build.rect 1 .intersection (m 0) (m (-10)) (m 20) (m 10)
def laneC : Structure :=
  Build.lane 2 [(m (-60), m 0), (m 0, m 0), (m 0, m 4), (m (-60), m 4)] Build.east (enters := some 1)
def lineC : Structure :=
  { Build.rect 3 .stopLine (cm (-1000)) (m 0) (cm (-970)) (m 4) with
    entranceOf := [2], entranceObserved := true }
def walkC : Structure :=
  { Build.rect 4 .crosswalk (m (-4)) (m (-10)) (m 0) (m 10) with
    marked := some true, entranceOf := [2], entranceObserved := true }
def laneOther : Structure :=
  Build.lane 5 [(m 20, m (-4)), (m 80, m (-4)), (m 80, m 0), (m 20, m 0)] Build.west (enters := some 1)
def lineOther : Structure :=
  { Build.rect 6 .stopLine (m 30) (m (-4)) (cm 3030) (m 0) with
    entranceOf := [5], entranceObserved := true }
def walkOther : Structure :=
  { Build.rect 7 .crosswalk (m 20) (m (-10)) (m 24) (m 10) with
    marked := some true, entranceOf := [5], entranceObserved := true }

def lineOnly : List Structure := [junction, laneC, lineC]
def lineAndWalk : List Structure := [junction, laneC, lineC, walkC]
def walkOnly : List Structure := [junction, laneC, walkC]
def noMarkForC : List Structure := [junction, laneC, laneOther, lineOther, walkOther]

def darkSignal (governs : List RegionId) : Device :=
  { Build.signal 1 governs [.dark] with uncovered := some true, inoperative := some true }
def greenSignal : Device :=
  { Build.signal 1 [2] [.circularGreen] with uncovered := some true, inoperative := some false }

def car (x v : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, m 2) Build.east v (m 2, m 1, m 1)

/-- One observation per second: the subject's position x, its speed, and the regions its body overlaps. -/
def drive (structs : List Structure) (devs : List Device) (steps : List (Q × Q × List RegionId)) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    match steps[k]? with
    | some (x, v, rs) =>
      Build.scene t (some 1) [car x v] structs devs (occupies := some (rs.map fun r => ((1 : TrackId), r)))
    | none => Build.scene t (some 1) [] structs devs

/-- Runs from well upstream across the stop line into X at 10 m/s, never halting. -/
def runThroughLine : List (Q × Q × List RegionId) :=
  [ (m (-40), mps 10, [2]), (m (-30), mps 10, [2]), (m (-20), mps 10, [2]),
    (m (-10), mps 10, [2, 3]), (m 1, mps 10, [2, 1]) ]

/-- Halts 0.5 m short of the stop line (line 2.5 m ahead of the reference point), creeps onto it,
    crosses and enters X. -/
def haltAtLine : List (Q × Q × List RegionId) :=
  [ (m (-40), mps 10, [2]), (m (-25), mps 10, [2]), (cm (-1250), mps 0, [2]),
    (cm (-1150), mps 1, [2, 3]), (m (-5), mps 6, [2]), (m 1, mps 6, [2, 1]) ]

/-- `forbid` (violated): A dev.traffic_signal governs carrier c, which enters X; at the subject's entry into X it is dev.inoperative. A st.stop_line marks c's entrance; the subject crosses it and enters X at a kin.speed well above p.halt_speed_tolerance, never halting since it was upstream of the line's stopping zone. -/
def forbidTrace : Trace := drive lineOnly [darkSignal [2]] runThroughLine

/-- `permit` (compliant): Same scene; the subject halts (kin.speed at or below p.halt_speed_tolerance) on c with the stop line just ahead within p.stop_point_tolerance, then enters X. -/
def permitTrace : Trace := drive lineOnly [darkSignal [2]] haltAtLine

/-- `idle` (not_applicable): The signal governing c shows circular_green at the subject's entry into X: not inoperative. -/
def idleTrace : Trace := drive lineOnly [greenSignal] runThroughLine

/-- `blind` (unknown): A traffic signal governs c; dev.inoperative is absent on the source, so whether the signal is inoperative at the entry is unknown. -/
def blindTrace : Trace := drive lineOnly [darkSignal [2]] haltAtLine

/-- `history_boundary` (unknown): Inoperative signal governing c; the recording begins with the subject already within p.stop_point_tolerance of the stop line, moving slowly; no halt is recorded before it enters X. -/
def history_boundaryTrace : Trace :=
  drive lineOnly [darkSignal [2]]
    [ (cm (-1220), mps 1, [2]), (m (-9), mps 2, [2, 3]), (m (-4), mps 3, [2]), (m 1, mps 3, [2, 1]) ]

/-- `branch_1` (compliant): No stop line and no crosswalk mark c (entrance lists observed, excluding c); the subject halts with its footprint outside X and its body within p.stop_point_tolerance of X, then enters. -/
def branch_1Trace : Trace :=
  drive noMarkForC [darkSignal [2]]
    [ (m (-40), mps 10, [2]), (m (-25), mps 10, [2]), (m (-3), mps 0, [2]), (m 1, mps 4, [2, 1]) ]

/-- `branch_2` (violated): A stop line marks c; the subject passes it without halting and halts only at the crosswalk beyond it, then enters X: the halt is not at the governing place. -/
def branch_2Trace : Trace :=
  drive lineAndWalk [darkSignal [2]]
    [ (m (-40), mps 10, [2]), (m (-25), mps 10, [2]), (m (-11), mps 6, [2, 3]),
      (cm (-650), mps 0, [2]), (m 1, mps 4, [2, 4, 1]) ]

/-- `branch_3` (violated): stop line; the subject halts at it and enters X (compliant entry),
    backs out onto c past the line and re-enters X without halting again: the previous entry
    ends the search for the second one. -/
def branch_3Trace : Trace :=
  drive lineOnly [darkSignal [2]]
    [ (m (-25), mps 10, [2]), (cm (-1250), mps 0, [2]), (m 1, mps 3, [2, 1]),
      (m 3, mps 1, [1]), (m (-5), mps 2, [2]), (m 1, mps 2, [2, 1]) ]

/-- `branch_4` (violated): the inoperative signal governs X itself (not c); stop line; no halt. -/
def branch_4Trace : Trace := drive lineOnly [darkSignal [1]] runThroughLine

/-- `branch_5` (compliant): only a crosswalk marks c; the subject halts with its body 0.5 m short
    of it, creeps onto it and enters X. -/
def branch_5Trace : Trace :=
  drive walkOnly [darkSignal [2]]
    [ (m (-40), mps 10, [2]), (m (-25), mps 10, [2]), (cm (-650), mps 0, [2]),
      (cm (-550), mps 1, [2, 4]), (m 1, mps 3, [2, 4, 1]) ]

/-- `branch_6` (violated): only a crosswalk marks c; the subject halts with its body on the
    crosswalk, then enters X. -/
def branch_6Trace : Trace :=
  drive walkOnly [darkSignal [2]]
    [ (m (-40), mps 10, [2]), (m (-25), mps 10, [2]), (m (-5), mps 0, [2, 4]), (m 1, mps 2, [2, 4, 1]) ]

/-- `branch_7` (violated): no mark for c; the subject enters X without halting. -/
def branch_7Trace : Trace :=
  drive noMarkForC [darkSignal [2]]
    [ (m (-40), mps 10, [2]), (m (-25), mps 10, [2]), (m (-10), mps 10, [2]),
      (m (-3), mps 8, [2]), (m 1, mps 8, [2, 1]) ]

/-- `branch_8` (violated): stop line; the subject halts 8 m short of it, outside its stopping
    zone, then crosses it and enters X without halting again. -/
def branch_8Trace : Trace :=
  drive lineOnly [darkSignal [2]]
    [ (m (-40), mps 10, [2]), (m (-20), mps 0, [2]), (m (-11), mps 6, [2, 3]),
      (m (-5), mps 6, [2]), (m 1, mps 6, [2, 1]) ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o1"
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
  , witness "blind" blindTrace (.unknown []) ["dev.inoperative"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach start: the subject's last observation outside the stop line's stopping zone upstream on c lies before the recording")
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_4_o1
