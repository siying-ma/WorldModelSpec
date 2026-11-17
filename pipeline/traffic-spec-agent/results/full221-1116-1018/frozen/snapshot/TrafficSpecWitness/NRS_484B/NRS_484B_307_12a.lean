/-
  Witnesses for NRS_484B_307_12a.

  Geometry (the witness's own figures; none appears in the rule): a highway region 10 spans
  x ∈ [0, 300] m, y ∈ [-10, 10] m. Two eastbound lanes lie on it (`ways := [10]`): lane 11 at
  y ∈ [-4, 0] and lane 12 at y ∈ [0, 4]. Lane-control signal heads hang over them: device 21 over
  lane 11 at (100, -2), device 22 over lane 12 at (100, 2) (in some branches placed at x = 0,
  behind the vehicle). The subject (track 1, a motor vehicle, half-extent 2 m × 0.9 m × 0.75 m)
  heads east at 15 m/s, at x = 20, 35, 50 m over three instants 1 s apart (a head at x = 100 is
  50–80 m ahead, one at x = 0 is 20–50 m behind), in lane 11 (y = -2) or lane 12 (y = 2). Halt
  tolerance 0.1 m/s: 15 m/s is far above it, 0 m/s at it.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_12a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_12a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def hwy : Structure := Build.rect 10 .highway (m 0) (m (-10)) (m 300) (m 10)

/-- The two lanes, lying on the ways `ws`. -/
def laneA (ws : List RegionId) : Structure :=
  { Build.lane 11 [(m 0, m (-4)), (m 300, m (-4)), (m 300, m 0), (m 0, m 0)] Build.east (some 12) none
      with ways := some ws }
def laneB (ws : List RegionId) : Structure :=
  { Build.lane 12 [(m 0, m 0), (m 300, m 0), (m 300, m 4), (m 0, m 4)] Build.east none (some 11)
      with ways := some ws }

def roadOnHighway : List Structure := [hwy, laneA [10], laneB [10]]

/-- A lane-control signal head over one lane. -/
def lcs (id : DeviceId) (laneId : RegionId) (pos : Vec) (st : LaneControlState) : Device :=
  { Build.device id .laneControlSignal [laneId] (some pos) with laneControl := some st }

def aheadA (st : LaneControlState) : Device := lcs 21 11 (m 100, m (-2)) st
def aheadB (st : LaneControlState) : Device := lcs 22 12 (m 100, m 2) st
def behindA (st : LaneControlState) : Device := lcs 21 11 (m 0, m (-2)) st
def behindB (st : LaneControlState) : Device := lcs 22 12 (m 0, m 2) st

/-- The vehicle at instant `k`, in the lane at lateral position `y`, at speed `v`. -/
def vehicle (k : Nat) (y : Q) (v : Q) : RoadUser :=
  let x : Q := if v == Q.zero then m 20 else m (20 + 15 * (Int.ofNat k))
  Build.user 1 [.motorVehicle] (x, y) Build.east v (m 2, cm 90, cm 75)

def run (y : Q) (v : Q) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [vehicle k y v] structures devices

def inA : Q := m (-2)
def inB : Q := m 2
def cruise : Q := Units.metresPerSecond 15

/-- `forbid` (violated): A vehicle (ru.aggregate vehicle) drives at 15 m/s in a st.lane over which a dev.lane_control_signal 80 m ahead (dev.position ahead along kin.heading, dev.governs that lane) displays yellow_x, while the signal over the adjacent lane, also ahead, displays green_down_arrow. No other road user is in the scene. -/
def forbidTrace : Trace :=
  run inA cruise roadOnHighway [aheadA .yellowX, aheadB .greenDownArrow]

/-- `permit` (compliant): The same vehicle drives in the lane whose overhead lane-control signal ahead displays green_down_arrow. -/
def permitTrace : Trace :=
  run inB cruise roadOnHighway [aheadA .yellowX, aheadB .greenDownArrow]

/-- `idle` (not_applicable): The vehicle drives on a road over whose lanes no lane-control signal is placed (no dev.governs from any dev.lane_control_signal). -/
def idleTrace : Trace :=
  run inA cruise roadOnHighway []

/-- `blind` (unknown): The vehicle drives in a lane of a road whose lane-control signals are not observed by the source: whether a signal is over the lane and what it shows cannot be read. -/
def blindTrace : Trace :=
  run inA cruise roadOnHighway [aheadA .yellowX, aheadB .greenDownArrow]

/-- `branch_1` (not_applicable): Every lane-control signal over the lanes ahead of the vehicle displays red_x: the driver faces no green arrow. -/
def branch_1Trace : Trace :=
  run inA cruise roadOnHighway [aheadA .redX, aheadB .redX]

/-- `branch_2` (not_applicable): the head over the vehicle's lane is dark, the adjacent one shows
    the green arrow: the vehicle drives under no lit head. -/
def branch_2Trace : Trace :=
  run inA cruise roadOnHighway [aheadA .dark, aheadB .greenDownArrow]

/-- `branch_3` (not_applicable): the yellow-X head over the vehicle's lane is behind it (passed);
    the green arrow over the adjacent lane is ahead: no lit head over its lane faces it. -/
def branch_3Trace : Trace :=
  run inA cruise roadOnHighway [behindA .yellowX, aheadB .greenDownArrow]

/-- `branch_4` (not_applicable): the only green arrow is behind the vehicle; the yellow X over its
    lane is ahead: the driver faces no green arrow. -/
def branch_4Trace : Trace :=
  run inA cruise roadOnHighway [aheadA .yellowX, behindB .greenDownArrow]

/-- `branch_5` (not_applicable): as `forbid`, but the vehicle stands still in its lane (0 m/s):
    it is not driving in the lane. -/
def branch_5Trace : Trace :=
  run inA (Units.metresPerSecond 0) roadOnHighway [aheadA .yellowX, aheadB .greenDownArrow]

/-- `branch_6` (not_applicable): as `forbid`, but the lanes lie on no highway (a private way):
    the signals are not over the lanes of a highway. -/
def branch_6Trace : Trace :=
  run inA cruise [laneA [], laneB []] [aheadA .yellowX, aheadB .greenDownArrow]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_12a"
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
  , witness "blind" blindTrace (.unknown []) ["dev.lane_control_signal"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_12a
