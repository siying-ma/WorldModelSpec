/-
  Witnesses for NRS_484B_307_12b.

  Geometry (the witness's own figures, nowhere in the rule): an eastbound two-lane carriageway on
  a highway region 10 (x 0…400 m, y −2…10 m). Lane 1 (y 0…4 m) and lane 2 (y 4…8 m), both lying
  on highway 10. Overhead lane-control signals: device 21 over lane 1 at (90, 2), device 22 over
  lane 2 at (90, 6). The subject (track 1) is a motor vehicle, half-extent 2 m × 0.9 m × 0.75 m,
  heading east; instants 0, 1, 2 s. Occupancy follows the reference point. The halt tolerance
  of the reading (0.1 m/s) is kept by a sampled speed of 0 and broken by 5, 12 and 15 m/s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_12b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_12b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (m 2, cm 90, cm 75)

def highway : Structure := Build.rect 10 .highway (m 0) (m (-2)) (m 400) (m 10)
def lane1 : Structure := { Build.rect 1 .lane (m 0) (m 0) (m 400) (m 4) with ways := some [10] }
def lane2 : Structure := { Build.rect 2 .lane (m 0) (m 4) (m 400) (m 8) with ways := some [10] }
def structures : List Structure := [highway, lane1, lane2]

def lcs (id : DeviceId) (over : RegionId) (y : Int) (st : LaneControlState) : Device :=
  { Build.device id .laneControlSignal [over] (some (m 90, m y)) with laneControl := some st }

def car (x y : Int) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) Build.east speed body

/-- `forbid` (violated): A vehicle (ru.aggregate vehicle) moving at 15 m/s changes into a st.lane over which a dev.lane_control_signal 80 m ahead (dev.position ahead along kin.heading) displays red_x: rel.occupies of that lane rises. No other road user is in the scene. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (10 + 15 * k) (if k == 0 then 2 else 6) (Units.metresPerSecond 15) ]
      structures
      [ lcs 21 1 2 .greenDownArrow, lcs 22 2 6 .redX ]

/-- `permit` (compliant): The vehicle keeps to its own lane, whose signal displays green_down_arrow, while the signal over the adjacent lane displays red_x; it never occupies the red-X lane. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (10 + 15 * k) 2 (Units.metresPerSecond 15) ]
      structures
      [ lcs 21 1 2 .greenDownArrow, lcs 22 2 6 .redX ]

/-- `idle` (not_applicable): No lane-control signal in the scene displays red_x. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (10 + 15 * k) (if k == 0 then 2 else 6) (Units.metresPerSecond 15) ]
      structures
      [ lcs 21 1 2 .greenDownArrow, lcs 22 2 6 .greenDownArrow ]

/-- `blind` (unknown): The vehicle drives on a road whose lane-control signals are not observed by the source. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (10 + 15 * k) (if k == 0 then 2 else 6) (Units.metresPerSecond 15) ]
      structures
      [ lcs 21 1 2 .greenDownArrow, lcs 22 2 6 .redX ]

/-- `branch_1` (violated): The vehicle already occupies a lane when its overhead signal ahead turns to red_x and keeps driving in it at 12 m/s. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (10 + 12 * k) 6 (Units.metresPerSecond 12) ]
      structures
      [ lcs 21 1 2 .greenDownArrow, lcs 22 2 6 (if k == 0 then .greenDownArrow else .redX) ]

/-- `branch_2` (violated): the vehicle moves into the red-X lane and is sampled at rest at the
    observation its occupancy of that lane rises, staying at rest after: it enters the lane without
    driving in it at the sampled instants (the `enter` limb alone decides). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ if k == 0 then car 10 2 (Units.metresPerSecond 5) else car 14 6 (Units.metresPerSecond 0) ]
      structures
      [ lcs 21 1 2 .greenDownArrow, lcs 22 2 6 .redX ]

/-- `branch_3` (not_applicable): the vehicle drives in lane 2 already 60 m past the red-X signal
    over it: the head lies behind it, so the driver is not facing the signal. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (150 + 15 * k) 6 (Units.metresPerSecond 15) ]
      structures
      [ lcs 21 1 2 .greenDownArrow, lcs 22 2 6 .redX ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_12b"
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
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_12b
