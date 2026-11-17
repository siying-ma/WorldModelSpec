/-
  Witnesses for NRS_484B_310_1.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - approach lane `c` = 10: x ∈ [-60, 0], y ∈ [0, 4], direction east, entering intersection 20;
  - intersection `i` = 20: x ∈ [0, 16], y ∈ [-8, 12];
  - stop line 30 on lane 10: x ∈ [-3, -2.5], recorded as marking lane 10 (list observed);
  - crosswalk 40 on lane 10: x ∈ [-4, -1], recorded as marking lane 10 (list observed);
  - a second eastbound lane 11 (y ∈ [4, 8], entering 20) with its own stop line 31 marking only
    lane 11: the "if none" scenes, whose observed entrance lists show no mark for lane 10;
  - signal head 50 governing lane 10 (lane 11 too in the "if none" scenes), or the intersection.
  The car (track 1, motor vehicle) drives east along y = 2, half-length 2 m, half-width 1 m;
  instants 1 s apart. Occupancy is stated per scene from the footprint (x ± 2).
  Reading: halt speed tolerance 0.1 m/s (halts are at 0, motion at ≥ 1 m/s); stop-point tolerance
  2 m (halts are 0.5–1 m short of the mark; approach starts are ≥ 6 m short).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_310_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_310_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def laneC : Structure :=
  Build.lane 10 [(m (-60), m 0), (m 0, m 0), (m 0, m 4), (m (-60), m 4)] Build.east (enters := some 20)
def laneOther : Structure :=
  Build.lane 11 [(m (-60), m 4), (m 0, m 4), (m 0, m 8), (m (-60), m 8)] Build.east (enters := some 20)
def inter : Structure := Build.rect 20 .intersection (m 0) (m (-8)) (m 16) (m 12)
def stopLine : Structure :=
  { Build.rect 30 .stopLine (m (-3)) (m 0) (cm (-250)) (m 4) with entranceOf := [10], entranceObserved := true }
def stopLineOther : Structure :=
  { Build.rect 31 .stopLine (m (-3)) (m 4) (cm (-250)) (m 8) with entranceOf := [11], entranceObserved := true }
def crosswalk : Structure :=
  { Build.rect 40 .crosswalk (m (-4)) (m 0) (m (-1)) (m 4) with
      entranceOf := [10], entranceObserved := true, marked := some true }

def withStopLine : List Structure := [laneC, inter, stopLine]
def withCrosswalk : List Structure := [laneC, inter, crosswalk]
def withoutMark : List Structure := [laneC, laneOther, inter, stopLineOther]

def car (x v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, m 2) Build.east v (m 2, m 1, m 1)

/-- A trace from per-instant (x, speed, regions occupied), 1 s apart. -/
def run (steps : List (Q × Q × List RegionId)) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    let st := steps.getD k (Q.zero, Q.zero, [])
    Build.scene t (some 1) [car st.1 st.2.1] structures devices
      (occupies := some (st.2.2.map fun r => ((1 : TrackId), r)))

def redOnLane : List Device := [Build.signal 50 [10] [.flashingRed]]

/-- Stop line scenes, no halt: starts 15 m short of the line, crosses it at 8 m/s, enters at k = 3. -/
def noHaltStopLine : List (Q × Q × List RegionId) :=
  [ (m (-20), mps 8, [10]), (m (-12), mps 8, [10]), (m (-4), mps 8, [10, 30]), (m 4, mps 8, [20]) ]

/-- `forbid` (violated): A car occupies approach lane c entering i; a stop line is recorded as marking c; the head governing c displays flashing_red. The car approaches from beyond the stopping zone and enters i without a halt (speed stays above the tolerance). -/
def forbidTrace : Trace := run noHaltStopLine withStopLine redOnLane

/-- `permit` (compliant): As in forbid, but the car halts with its body within the tolerance short of the stop line, not overlapping it, then enters i. -/
def permitTrace : Trace :=
  run [ (m (-20), mps 8, [10]), (m (-12), mps 5, [10]), (cm (-550), mps 0, [10]), (cm (-550), mps 0, [10])
      , (m 1, mps 4, [10, 20]) ] withStopLine redOnLane

/-- `idle` (not_applicable): The head governing c displays circular_green when the car enters i. -/
def idleTrace : Trace := run noHaltStopLine withStopLine [Build.signal 50 [10] [.circularGreen]]

/-- `blind` (unknown): As in forbid, but the head's state is not observed at the entry (dev.traffic_signal absent). -/
def blindTrace : Trace := run noHaltStopLine withStopLine redOnLane

/-- `history_boundary` (unknown): The recording begins with the car already within the stop line's stopping zone on c, rolling slowly under a flashing red; it enters i. No halt is recorded and no earlier entry into i is recorded. -/
def history_boundaryTrace : Trace :=
  run [ (m (-6), mps 1, [10]), (m (-5), mps 1, [10, 30]), (m (-4), mps 1, [10, 30]), (m (-3), mps 1, [10, 30])
      , (m (-1), mps 1, [10, 20, 30]) ] withStopLine redOnLane

/-- `branch_1` (compliant): The source's entrance lists show no stop line and no crosswalk marking c; the car halts with its body within the tolerance of i's edge, not overlapping i, then enters under flashing red. -/
def branch_1Trace : Trace :=
  run [ (m (-20), mps 8, [10]), (m (-12), mps 5, [10]), (m (-3), mps 0, [10]), (m (-3), mps 0, [10])
      , (m 1, mps 4, [10, 20]) ] withoutMark [Build.signal 50 [10, 11] [.flashingRed]]

/-- `branch_2` (compliant): a crosswalk (no stop line) marks c; the car halts 1 m short of it, then enters. -/
def branch_2Trace : Trace :=
  run [ (m (-20), mps 8, [10]), (m (-13), mps 5, [10]), (m (-7), mps 0, [10]), (m (-7), mps 0, [10])
      , (m 0, mps 4, [10, 20, 40]) ] withCrosswalk redOnLane

/-- `branch_3` (violated): a crosswalk (no stop line) marks c; the car approaches from 14 m short of it and enters without a halt. -/
def branch_3Trace : Trace :=
  run [ (m (-20), mps 8, [10]), (m (-12), mps 8, [10]), (m (-4), mps 8, [10, 40]), (m 4, mps 8, [20]) ]
    withCrosswalk redOnLane

/-- `branch_4` (violated): no mark for c (observed lists); the car approaches from 18 m short of i and enters without a halt. -/
def branch_4Trace : Trace :=
  run [ (m (-20), mps 8, [10]), (m (-12), mps 8, [10]), (m (-4), mps 8, [10]), (m 4, mps 8, [20]) ]
    withoutMark [Build.signal 50 [10, 11] [.flashingRed]]

/-- `branch_5` (violated): as in forbid, but the flashing red head governs the intersection itself, not c. -/
def branch_5Trace : Trace := run noHaltStopLine withStopLine [Build.signal 50 [20] [.flashingRed]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_310_1"
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
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the car's approach to the stop line on c before the recording began, where a halt may have been made")
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_310_1
