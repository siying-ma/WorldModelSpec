/-
  Witnesses for NRS_484B_450_1g.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
    - lane 10: x ∈ [−60, 12], y ∈ [0, 4], direction east, entering intersection 13;
    - intersection 13: x ∈ [12, 30], y ∈ [−10, 14];
    - road edge 11 (right): strip y ∈ [−1, 0]; road edge 12 (left): strip y ∈ [4, 5], x ∈ [−60, 12];
    - subject (track 1): a motor vehicle, half-extents 2.5 × 1 × 0.75 m (length 5 m), at (0, 2)
      heading east, its front at x = 2.5;
    - traffic signal 20: head at (8.5, −2): 6 m ahead of the subject's front, 2 m beyond the right
      edge. Reference-to-head distance √(8.5² + 4²) ≈ 9.39 m against the bound 30 ft + 2.5 m ≈
      11.64 m; head lateral −4 m against the right edge's −2 m.
  Three instants, one second apart; the rule reads no history.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_450_1g
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_450_1g

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def car : Q × Q × Q := (cm 250, m 1, cm 75)

def laneR : Structure :=
  Build.lane 10 [(m (-60), m 0), (m 12, m 0), (m 12, m 4), (m (-60), m 4)] Build.east (enters := some 13)
def junction : Structure := Build.rect 13 .intersection (m 12) (m (-10)) (m 30) (m 14)
def rightEdge : Structure := Build.rect 11 .roadEdge (m (-60)) (m (-1)) (m 12) (m 0)
def leftEdge : Structure := Build.rect 12 .roadEdge (m (-60)) (m 4) (m 12) (m 5)
def structures : List Structure := [laneR, junction, rightEdge, leftEdge]

/-- The subject at rest at (x, 2). -/
def subjectAt (x : Q) (speed : Q := Q.zero) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, m 2) Build.east speed car

/-- The signal head at a position, governing `gov`, showing `shows`. -/
def signalAt (pos : Vec) (gov : List RegionId := [10]) (shows : List SignalIndication := [.circularGreen]) : Device :=
  { Build.signal 20 gov shows with position := some pos }

def roadsideHead : Vec := (cm 850, m (-2))

def staticTrace (users : List RoadUser) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures devices

/-- `forbid` (violated): The subject, a ru.aggregate vehicle, is at rest (kin.speed zero) in a lane it occupies that a dev.traffic_signal governs; the head (dev.position) stands 6 m ahead of the subject's front along the lane's direction and 2 m beyond the right st.road_edge; the signal shows circular_green; no other road user, no human direction and no other device is in the scene. -/
def forbidTrace : Trace := staticTrace [subjectAt (m 0)] [signalAt roadsideHead]

/-- `permit` (compliant): As in forbid, but the subject moves through at kin.speed 10 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [subjectAt (m (10 * Int.ofNat k)) (Units.metresPerSecond 10)]
      structures
      [signalAt roadsideHead]

/-- `idle` (not_applicable): As in forbid, but the subject is at rest with its front 40 m before the signal head. -/
def idleTrace : Trace := staticTrace [subjectAt (cm (-3400))] [signalAt roadsideHead]

/-- `blind` (unknown): As in forbid, but the source does not observe the signal head's position. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): As in forbid, but the signal shows circular_red: the halt is in compliance with law and the device's direction. -/
def branch_1Trace : Trace := staticTrace [subjectAt (m 0)] [signalAt roadsideHead [10] [.circularRed]]

/-- `branch_2` (compliant): As in forbid, but another vehicle stands ahead of the subject in the same lane (rel.ahead_behind_in_lane) with its body 2 m from the subject's (rel.surface_gap). -/
def branch_2Trace : Trace :=
  staticTrace [subjectAt (m 0), Build.user 2 [.motorVehicle] (m 7, m 2) Build.east Q.zero car]
    [signalAt roadsideHead]

/-- `branch_3` (not_applicable): As in forbid, but the signal head is mounted over the subject's lane, laterally inside the roadway edges on both sides. -/
def branch_3Trace : Trace := staticTrace [subjectAt (m 0)] [signalAt (cm 850, m 1)]

/-- `branch_4` (compliant): As in forbid, but a dev.human_direction of role police_officer with indication stop governs the subject's lane. -/
def branch_4Trace : Trace :=
  staticTrace [subjectAt (m 0)]
    [ signalAt roadsideHead
    , { Build.device 30 .humanDirection [10] (some (m 6, m 3)) with
          humanRole := some .policeOfficer, humanIndication := some .stop } ]

/-- `branch_5` (compliant): As in forbid, but a stop sign governs the subject's lane. -/
def branch_5Trace : Trace :=
  staticTrace [subjectAt (m 0)] [signalAt roadsideHead, Build.sign 31 .stopSign [10]]

/-- `branch_6` (compliant): As in forbid, but a yield sign governs the subject's lane. -/
def branch_6Trace : Trace :=
  staticTrace [subjectAt (m 0)] [signalAt roadsideHead, Build.sign 32 .yieldSign [10]]

/-- `branch_7` (compliant): As in forbid, but a level-crossing signal with lights flashing (gate up) governs the subject's lane. -/
def branch_7Trace : Trace :=
  staticTrace [subjectAt (m 0)]
    [ signalAt roadsideHead
    , { Build.device 33 .railwaySignalOrGate [10] with railLights := some .flashing, gate := some .up } ]

/-- `branch_8` (compliant): As in forbid, but a level-crossing gate is down (lights dark) on the subject's lane. -/
def branch_8Trace : Trace :=
  staticTrace [subjectAt (m 0)]
    [ signalAt roadsideHead
    , { Build.device 34 .railwaySignalOrGate [10] with railLights := some .dark, gate := some .down } ]

/-- `branch_9` (violated): As in forbid, but the signal governs the intersection the subject's lane enters, not the lane. -/
def branch_9Trace : Trace := staticTrace [subjectAt (m 0)] [signalAt roadsideHead [13]]

/-- `branch_10` (violated): As in forbid, but the head stands 2 m beyond the left road edge. -/
def branch_10Trace : Trace := staticTrace [subjectAt (m 0)] [signalAt (cm 850, m 6)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_450_1g"
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
  , witness "blind" blindTrace (.unknown []) ["dev.position"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .violated ]

end TrafficSpecWitness.NRS_484B_450_1g
