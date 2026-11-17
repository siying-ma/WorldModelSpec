/-
  Witnesses for NRS_484B_450_1m.

  Geometry (all figures the witness's own): an eastbound lane 10 (x −50…150, y 0…4) and the lane
  11 beside it (y 4…8), both crossing a bridge 20 (an elevated structure, x 0…100, y −2…10). The
  subject, track 1, a motor vehicle of 4 m × 2 m, stands at (50, 2) in lane 10, at speed 0 (the
  tolerance is 0.1 m/s) or 15 m/s. A second motor vehicle, track 2, stands ahead in lane 10 at
  (56, 2): its rear is 2 m from the subject's front (the queue gap is 5 m), or at (66, 2), 12 m.
  Devices govern lane 10 (or lane 11 where the subject is not). The tunnel scene uses a tunnel 21
  (an elevated structure) in place of the bridge; the idle scene a roadway 30 with no structure
  under the subject, the bridge lying 250 m away. Three instants at 1 s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_450_1m
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_450_1m

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (m 2, m 1, cm 75)

def lane10 : Structure := Build.lane 10 [(m (-50), m 0), (m 150, m 0), (m 150, m 4), (m (-50), m 4)] Build.east
def lane11 : Structure := Build.lane 11 [(m (-50), m 4), (m 150, m 4), (m 150, m 8), (m (-50), m 8)] Build.east
def bridge : Structure := Build.rect 20 .elevatedStructure (m 0) (m (-2)) (m 100) (m 10)
def tunnel : Structure := Build.rect 21 .elevatedStructure (m 0) (m (-2)) (m 100) (m 10)

/-- The subject at rest (or moving) at `x` in lane 10. -/
def subjectAt (x : Int) (speed : Q) : RoadUser := Build.user 1 [.motorVehicle] (m x, m 2) Build.east speed body
def halted : RoadUser := subjectAt 50 Q.zero
def leader (x : Int) : RoadUser := Build.user 2 [.motorVehicle] (m x, m 2) Build.east Q.zero body

/-- A bridge scene, three instants, with the given users and devices. -/
def bridgeTrace (users : List RoadUser) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users [lane10, lane11, bridge] devices

/-- `forbid` (violated): The subject, a ru.aggregate vehicle, is at rest (kin.speed zero) with its footprint overlapping a st.elevated_structure (a bridge); no other road user, no human direction and no device is in the scene. -/
def forbidTrace : Trace := bridgeTrace [halted] []

/-- `permit` (compliant): As in forbid, but the subject crosses the bridge at kin.speed 15 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [subjectAt (30 + 15 * (k : Int)) (Units.metresPerSecond 15)] [lane10, lane11, bridge] []

/-- `idle` (not_applicable): The subject is at rest on a roadway that overlaps no elevated structure. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [halted]
      [ Build.rect 30 .roadway (m (-50)) (m 0) (m 150) (m 8)
      , Build.rect 20 .elevatedStructure (m 300) (m (-2)) (m 400) (m 10) ]
      []

/-- `blind` (unknown): As in forbid, but the source does not observe footprint occupancy of regions. -/
def blindTrace : Trace := bridgeTrace [halted] []

/-- `branch_1` (compliant): As in forbid, but another vehicle stands ahead of the subject in the same lane on the bridge (rel.ahead_behind_in_lane) with its body 2 m from the subject's (rel.surface_gap). -/
def branch_1Trace : Trace := bridgeTrace [halted, leader 56] []

/-- `branch_2` (violated): The subject is at rest inside a tunnel carrying the roadway (st.elevated_structure), alone in the scene. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [halted] [lane10, lane11, tunnel] []

/-- `branch_3` (violated): the vehicle ahead in the lane is 12 m away, beyond the queue gap. -/
def branch_3Trace : Trace := bridgeTrace [halted, leader 66] []

/-- `branch_4` (compliant): a stop sign governs the lane the subject stands in. -/
def branch_4Trace : Trace := bridgeTrace [halted] [Build.sign 40 .stopSign [10]]

/-- `branch_5` (violated): the stop sign governs the other lane only. -/
def branch_5Trace : Trace := bridgeTrace [halted] [Build.sign 40 .stopSign [11]]

/-- `branch_6` (compliant): a yield sign governs the subject's lane. -/
def branch_6Trace : Trace := bridgeTrace [halted] [Build.sign 41 .yieldSign [10]]

/-- `branch_7` (compliant): a traffic signal governing the subject's lane shows circular red. -/
def branch_7Trace : Trace := bridgeTrace [halted] [Build.signal 42 [10] [.circularRed]]

/-- `branch_8` (violated): the signal governing the subject's lane shows circular green. -/
def branch_8Trace : Trace := bridgeTrace [halted] [Build.signal 42 [10] [.circularGreen]]

def rail (lights : RailLights) (gate : GateState) : Device :=
  { Build.device 43 .railwaySignalOrGate [10] with railLights := some lights, gate := some gate }

/-- `branch_9` (compliant): a level-crossing signal governing the lane flashes, its gate up. -/
def branch_9Trace : Trace := bridgeTrace [halted] [rail .flashing .up]

/-- `branch_10` (compliant): the level-crossing lights are dark and the gate is down. -/
def branch_10Trace : Trace := bridgeTrace [halted] [rail .dark .down]

/-- `branch_11` (violated): the level-crossing lights are dark and the gate is up. -/
def branch_11Trace : Trace := bridgeTrace [halted] [rail .dark .up]

def officer (role : HumanRole) (ind : HumanIndication) : Device :=
  { Build.device 44 .humanDirection [10] with humanRole := some role, humanIndication := some ind }

/-- `branch_12` (compliant): a police officer directs the subject's lane to stop. -/
def branch_12Trace : Trace := bridgeTrace [halted] [officer .policeOfficer .stop]

/-- `branch_13` (violated): the police officer directs the lane to proceed. -/
def branch_13Trace : Trace := bridgeTrace [halted] [officer .policeOfficer .proceed]

/-- `branch_14` (violated): a flagger, not a police officer, directs the lane to stop. -/
def branch_14Trace : Trace := bridgeTrace [halted] [officer .flagger .stop]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_450_1m"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .violated
  , witness "branch_14" branch_14Trace .violated ]

end TrafficSpecWitness.NRS_484B_450_1m
