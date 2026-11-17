/-
  Witnesses for NRS_484B_477_1b.

  Geometry (the witness's own figures, nowhere in the rule): an alley runs east–west along x from
  −50 m to 50 m; its left (north) and right (south) road edges are 20 cm wide strips just beyond
  its sides. The subject (track 1, a motor vehicle) stands at the origin heading east, half-extents
  2.5 m × 1.0 m, so its body spans y ∈ [−1, 1].
    standard layout: alley y ∈ [−1.3, 3.0]: left edge 2.0 m, right edge 0.3 m from the body;
    left-open layout: alley y ∈ [−1.3, 5.0]: left edge 4.0 m (> 10 ft = 3.048 m), right 0.3 m;
    right-open layout: alley y ∈ [−5.0, 1.3]: right edge 4.0 m, left edge 0.3 m.
  Another vehicle (track 2) is at rest, heading east, same size, where a scene needs one.
  A lane (region 13) covering the alley is built where a queue or a device needs one.
  Each trace has three instants one second apart; no operator of the rule looks back.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_477_1b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_477_1b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The subject at the origin heading east at the given speed. -/
def subjectAt (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m 0) Build.east speed (cm 250, m 1, cm 75)

/-- Another vehicle at rest heading east at (x, y). -/
def otherAt (x y : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (x, y) Build.east Q.zero (cm 250, m 1, cm 75)

/-- The alley between `yLo` and `yHi`, with its two road edges beyond its sides when `edges`. -/
def layout (yLo yHi : Q) (edges : Bool := true) : List Structure :=
  [Build.rect 10 .alley (m (-50)) yLo (m 50) yHi] ++
    (if edges then
      [ Build.rect 11 .roadEdge (m (-50)) yHi (m 50) (Q.add yHi (cm 20))
      , Build.rect 12 .roadEdge (m (-50)) (Q.sub yLo (cm 20)) (m 50) yLo ]
     else [])

def standard : List Structure := layout (cm (-130)) (cm 300)
def leftOpen : List Structure := layout (cm (-130)) (cm 500)
def rightOpen : List Structure := layout (cm (-500)) (cm 130)

/-- A lane covering the standard alley, direction east. -/
def laneStd : Structure :=
  Build.lane 13 [(m (-50), cm (-130)), (m 50, cm (-130)), (m 50, cm 300), (m (-50), cm 300)] Build.east

def asms (business : Bool) : List (AsmId × Bool) :=
  [("asm.business_district", business), ("asm.local_alley_ordinance", false)]

def mk (users : List RoadUser) (structures : List Structure) (devices : List Device)
    (business : Bool := false) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures devices (assumptions := asms business)

/-- `forbid` (violated): A vehicle at rest 20 s in an alley (asm.business_district false, asm.local_alley_ordinance false); the left road edge lies 2.0 m and the right 0.3 m from its body; nothing else beside it, nobody ahead, no device. -/
def forbidTrace : Trace := mk [subjectAt Q.zero] standard []

/-- `permit` (compliant): The same vehicle, edges as in forbid, moves through the alley at 2 m/s without halting. -/
def permitTrace : Trace := mk [subjectAt (Units.metresPerSecond 2)] standard []

/-- `idle` (not_applicable): The same halt in an alley where asm.business_district is true. -/
def idleTrace : Trace := mk [subjectAt Q.zero] standard [] (business := true)

/-- `blind` (unknown): As in forbid, but region outlines are absent, so the distances to the edges are unknown. -/
def blindTrace : Trace := mk [subjectAt Q.zero] standard []

/-- `branch_3` (not_applicable): The vehicle is at rest with the right edge 0.3 m and the left edge 4.0 m from its body, nothing alongside: 10 feet are left free on its left. -/
def branch_3Trace : Trace := mk [subjectAt Q.zero] leftOpen []

/-- `branch_1` (violated): The left edge lies 4.0 m from the subject's body, but another vehicle at rest alongside on its left has a lateral gap of 1.5 m; the right edge lies 0.3 m away. -/
def branch_1Trace : Trace := mk [subjectAt Q.zero, otherAt (m 0) (cm 350)] leftOpen []

/-- `branch_2` (compliant): The subject halts 2 m behind another vehicle ahead of it in its lane, edges as in forbid: a queue halt. -/
def branch_2Trace : Trace := mk [subjectAt Q.zero, otherAt (m 7) (m 0)] (standard ++ [laneStd]) []

/-- `branch_4` (violated): left edge 4.0 m away, but an obstruction on the left lies 1.0 m from the body; right edge 0.3 m. -/
def branch_4Trace : Trace :=
  mk [subjectAt Q.zero] (leftOpen ++ [Build.rect 14 .obstruction (m (-1)) (m 2) (m 1) (cm 250)]) []

/-- `branch_5` (violated): an alley whose road edges are mapped nowhere: no side has an edge, so no side is free. -/
def branch_5Trace : Trace := mk [subjectAt Q.zero] (layout (cm (-130)) (cm 300) (edges := false)) []

/-- `branch_6` (violated): right edge 4.0 m away, but an obstruction on the right lies 1.0 m from the body; left edge 0.3 m. -/
def branch_6Trace : Trace :=
  mk [subjectAt Q.zero] (rightOpen ++ [Build.rect 14 .obstruction (m (-1)) (cm (-250)) (m 1) (m (-2))]) []

/-- `branch_7` (violated): right edge 4.0 m away, but another vehicle at rest alongside on the right has a lateral gap of 1.5 m; left edge 0.3 m. -/
def branch_7Trace : Trace := mk [subjectAt Q.zero, otherAt (m 0) (cm (-350))] rightOpen []

/-- `branch_13` (not_applicable): at rest with the left edge 0.3 m and the right edge 4.0 m from its body, nothing alongside: 10 feet are left free on its right. -/
def branch_13Trace : Trace := mk [subjectAt Q.zero] rightOpen []

/-- A halt as in forbid, in a lane governed by the given device. -/
def governedTrace (kind : DeviceKind) : Trace :=
  mk [subjectAt Q.zero] (standard ++ [laneStd]) [Build.device 20 kind [13]]

/-- `branch_8` (compliant): the halt is in a lane governed by a traffic signal. -/
def branch_8Trace : Trace := governedTrace .trafficSignal
/-- `branch_9` (compliant): the halt is in a lane governed by a stop sign. -/
def branch_9Trace : Trace := governedTrace .stopSign
/-- `branch_10` (compliant): the halt is in a lane governed by a yield sign. -/
def branch_10Trace : Trace := governedTrace .yieldSign
/-- `branch_11` (compliant): the halt is in a lane governed by a railway signal or gate. -/
def branch_11Trace : Trace := governedTrace .railwaySignalOrGate
/-- `branch_12` (compliant): the halt is in a lane governed by a person directing traffic. -/
def branch_12Trace : Trace := governedTrace .humanDirection

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_477_1b"
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
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_477_1b
