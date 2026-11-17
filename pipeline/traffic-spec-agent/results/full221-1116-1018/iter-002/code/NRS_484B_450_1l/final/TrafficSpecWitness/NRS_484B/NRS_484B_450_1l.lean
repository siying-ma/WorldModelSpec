/-
  Witnesses for NRS_484B_450_1l.

  The carriageway runs east. Highway region 1 spans y ∈ [−3, 12] m. The right-hand lane 10 spans
  y ∈ [0, 4], the left-hand lane 11 y ∈ [4, 8], both heading east. The right road edge (curb) 20
  is the strip y ∈ [−0.2, 0], lying on highway 1.

  Bodies are 5 m long and 2 m wide (half-extents 2.5 × 1 × 0.75 m).
  - b (track 2), a motor vehicle, stands at (0, 1.2) in lane 10: its body spans y ∈ [0.2, 2.2], so
    it is 0.2 m from the edge (reading: p.edge_standing_gap 0.6 m).
  - the subject (track 1), a motor vehicle, stands at (0, 5.5) in lane 11, body y ∈ [4.5, 6.5],
    side by side with b (longitudinal overlap 5 m); b lies 4.3 m to its right, the edge 5.5 m to
    its right, so the product of the two lateral components is positive.
  Speeds 0 m/s are at rest (reading: p.halt_speed_tolerance 0.1 m/s); 5 and 7 m/s are moving.
  The queue witness puts a third motor vehicle (track 3) at rest at (8, 5.5) in lane 11: 3 m of
  gap between the bodies (reading: p.queue_halt_gap 5 m).
  Three instants at 0, 1000 and 2000 ms; the rule reads no history.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_450_1l
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_450_1l

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (cm 250, m 1, cm 75)

def highway : Structure := Build.rect 1 .highway (m (-60)) (m (-3)) (m 60) (m 12)
def laneRight : Structure :=
  Build.lane 10 [(m (-60), m 0), (m 60, m 0), (m 60, m 4), (m (-60), m 4)] Build.east
    (left := some 11) (right := none)
def laneLeft : Structure :=
  Build.lane 11 [(m (-60), m 4), (m 60, m 4), (m 60, m 8), (m (-60), m 8)] Build.east
    (left := none) (right := some 10)
def roadEdge : Structure :=
  { Build.rect 20 .roadEdge (m (-60)) (cm (-20)) (m 60) (m 0) with ways := some [1] }

def structures : List Structure := [highway, laneRight, laneLeft, roadEdge]

/-- The subject at (x, y) heading east at a speed. -/
def subjectAt (x y : Q) (v : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, y) Build.east v body
/-- b, the other vehicle, at (x, y) heading east at a speed. -/
def otherAt (x y : Q) (v : Q) : RoadUser := Build.user 2 [.motorVehicle] (x, y) Build.east v body

def subjectHalted : RoadUser := subjectAt (m 0) (cm 550) (m 0)
def bAtCurb : RoadUser := otherAt (m 0) (cm 120) (m 0)

/-- A three-instant trace of the same users and devices. -/
def still (users : List RoadUser) (devices : List Device := []) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures devices

/-- `forbid` (violated): Another ru.aggregate vehicle b is at rest with its body 0.2 m from the right st.road_edge of the highway; the subject, a ru.aggregate vehicle, is at rest to b's left, side by side with it (rel.longitudinal_overlap positive, b's bearing to the subject's right, the edge to the subject's right); no road user is ahead of the subject in its lane, and no human direction or device is in the scene. -/
def forbidTrace : Trace := still [subjectHalted, bAtCurb]

/-- `permit` (compliant): As in forbid, but the subject moves past b at kin.speed 7 m/s.
    The subject is at x = −3, 4, 11 m: side by side with b at the first two instants, past it at
    the third. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (m (7 * (k : Int) - 3)) (cm 550) (Units.metresPerSecond 7), bAtCurb ]
      structures []

/-- `idle` (not_applicable): No other road user is in the scene; the subject is at rest in the middle of its lane. -/
def idleTrace : Trace := still [subjectAt (m 0) (m 6) (m 0)]

/-- `blind` (unknown): As in forbid, but the source does not supply the bearing between the two vehicles. -/
def blindTrace : Trace := still [subjectHalted, bAtCurb]

/-- `branch_1` (not_applicable): As in forbid, but b is moving at kin.speed 5 m/s. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectHalted, otherAt (m (5 * (k : Int))) (cm 120) (Units.metresPerSecond 5) ]
      structures []

/-- `branch_2` (not_applicable): As in forbid, but b is at rest with its body 2.5 m from the road edge.
    b at y = 3.5 (body y ∈ [2.5, 4.5]); the subject at y = 7 (body y ∈ [6, 8]) to keep clear of it. -/
def branch_2Trace : Trace := still [subjectAt (m 0) (m 7) (m 0), otherAt (m 0) (cm 350) (m 0)]

/-- `branch_3` (compliant): As in forbid, but a dev.traffic_signal showing circular_red governs the subject's lane. -/
def branch_3Trace : Trace :=
  still [subjectHalted, bAtCurb] [Build.signal 50 [11] [.circularRed]]

/-- `branch_4` (compliant): As in forbid, but a stop sign governs the subject's lane. -/
def branch_4Trace : Trace :=
  still [subjectHalted, bAtCurb] [Build.sign 50 .stopSign [11]]

/-- `branch_5` (compliant): As in forbid, but a yield sign governs the subject's lane. -/
def branch_5Trace : Trace :=
  still [subjectHalted, bAtCurb] [Build.sign 50 .yieldSign [11]]

/-- `branch_6` (compliant): As in forbid, but a level-crossing signal with its lights flashing (gate up) governs the subject's lane. -/
def branch_6Trace : Trace :=
  still [subjectHalted, bAtCurb]
    [{ Build.device 50 .railwaySignalOrGate [11] with railLights := some .flashing, gate := some .up }]

/-- `branch_7` (compliant): As in forbid, but a level-crossing gate that is down (lights dark) governs the subject's lane. -/
def branch_7Trace : Trace :=
  still [subjectHalted, bAtCurb]
    [{ Build.device 50 .railwaySignalOrGate [11] with railLights := some .dark, gate := some .down }]

/-- `branch_8` (compliant): As in forbid, but a police officer directing the subject's lane to stop. -/
def branch_8Trace : Trace :=
  still [subjectHalted, bAtCurb]
    [{ Build.device 50 .humanDirection [11] with
        humanRole := some .policeOfficer, humanIndication := some .stop }]

/-- `branch_9` (compliant): As in forbid, but a motor vehicle stands 3 m ahead of the subject in its lane. -/
def branch_9Trace : Trace :=
  still [subjectHalted, bAtCurb, Build.user 3 [.motorVehicle] (m 8, cm 550) Build.east (m 0) body]

/-- `branch_10` (violated): forbid mirrored: both vehicles stand heading west, so b and the edge
    lie to the subject's left (positive lateral components); the subject is still on b's highway side. -/
def branch_10Trace : Trace :=
  still [ Build.user 1 [.motorVehicle] (m 0, cm 550) Build.west (m 0) body
        , Build.user 2 [.motorVehicle] (m 0, cm 120) Build.west (m 0) body ]

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
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .violated ]

end TrafficSpecWitness.NRS_484B_450_1l
