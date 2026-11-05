/-
  Witnesses for NRS_484B_223_1b.

  The map (the same in every scene of a trace, as a map must be): a highway region 400 m each way of
  the origin and 20 m wide, and on it the lanes of its carriageway, each 4 m wide and 800 m long,
  each carrying its designated direction, its place among the lanes of that direction, and the
  marking on each of its sides.

  Two-lane traces (forbid, permit, blind, branch_1, branch_2, branch_3): two lanes running east,
  region 11 the left (north) one, y from 4 m to 8 m, first of two from the left, its left side a solid
  edge line and its right side the broken lane line; region 12 the right (south) one, y from 0 m to
  4 m, second of two, its left side that broken line and its right side a solid edge line.
  The idle trace: one lane each way, region 11 running west and region 12 running east, each the only
  lane of its direction.

  The bodies: passenger cars, 4.4 m by 1.8 m (half-extents 2.20 m, 0.90 m, 0.75 m), heading east.
  The subject is track 1, travelling east at 10 m/s, at x = 10 m per second of the trace. It rides in
  the right lane (y = 2 m, its body from 1.1 m to 2.9 m, wholly inside it) at the first two
  observations and in the left lane (y = 6 m, body from 5.1 m to 6.9 m, wholly inside it) at the last
  two: so the observation at t = 12 s is the one at which its body leaves the right lane and enters
  the left one, and at that observation the right lane lies 2 m to its right — the departure is to the
  left, across the broken line.

  The instants: four observations one second apart from t = 10 s to t = 13 s, the window each witness
  speaks about, with the first scene repeated for three seconds before and the last for one second
  after, so that the event the duty reads has an observation behind it at t = 10 s.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_1b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_1b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The regions of the map. -/
def wayId : RegionId := 10
def leftLaneId : RegionId := 11
def rightLaneId : RegionId := 12

def highway : Structure := Build.rect wayId .highway (m (-400)) (m (-10)) (m 400) (m 10)

/-- A lane of the carriageway: its strip, its designated direction, its neighbour of that direction,
    its place among them and the marking on each side. -/
def laneStrip (id : RegionId) (y0 y1 : Q) (dir : Vec) (left right : Option RegionId)
    (ord cnt : Nat) (mLeft mRight : MarkingType) : Structure :=
  let st := Build.lane id [(m (-400), y0), (m 400, y0), (m 400, y1), (m (-400), y1)] dir
              (left := left) (right := right) (ordinal := some ord) (count := some cnt)
  { st with
    ways := some [wayId]
    lane := st.lane.map (fun li =>
      { li with markingLeft := some (mLeft, MarkingColour.white),
                markingRight := some (mRight, MarkingColour.white) }) }

/-- The left (north) lane of two running east. -/
def leftLane : Structure :=
  laneStrip leftLaneId (m 4) (m 8) Build.east none (some rightLaneId) 1 2
    MarkingType.solid MarkingType.broken
/-- The right (south) lane of two running east. -/
def rightLane : Structure :=
  laneStrip rightLaneId (m 0) (m 4) Build.east (some leftLaneId) none 2 2
    MarkingType.broken MarkingType.solid

/-- The one westbound lane of the single-lane highway. -/
def oncomingLane : Structure :=
  laneStrip leftLaneId (m 4) (m 8) Build.west none none 1 1
    MarkingType.solid MarkingType.broken
/-- The one eastbound lane of the single-lane highway. -/
def soleLane : Structure :=
  laneStrip rightLaneId (m 0) (m 4) Build.east none none 1 1
    MarkingType.broken MarkingType.solid

def carExtent : Q × Q × Q := (cm 220, cm 90, cm 75)

/-- The subject's position at the k-th observation: east at 10 m/s, in the right lane for the first
    two observations and in the left lane for the last two. -/
def subjectAt (k : Nat) : Vec := (m (10 * Int.ofNat k), if k < 2 then m 2 else m 6)

/-- The subject, with the signals it shows. -/
def subject (k : Nat) (ind : TurnIndicatorState) (hand : HandSignal) : RoadUser :=
  Build.withSignals
    (Build.user 1 [RoadUserClass.motorVehicle] (subjectAt k) Build.east (Units.metresPerSecond 10) carExtent)
    fun s => { s with turnIndicator := some ind, handSignal := some hand }

/-- A car in the left lane at `x`, travelling east at `speed`. -/
def otherCar (x : Int) (speed : Int) : RoadUser :=
  Build.user 2 [RoadUserClass.motorVehicle] (m x, m 6) Build.east (Units.metresPerSecond speed) carExtent

/-- A scene of the two-lane highway. -/
def twoLaneScene (t : Timestamp) (users : List RoadUser) : Scene :=
  Build.scene t (some 1) users [highway, leftLane, rightLane] []

/-- A scene of the single-lane-each-way highway. -/
def oneLaneScene (t : Timestamp) (users : List RoadUser) : Scene :=
  Build.scene t (some 1) users [highway, oncomingLane, soleLane] []

/-- Four observations a second apart from t = 10 s, the first repeated for three seconds before and
    the last for one second after. -/
def episode (f : Nat → Timestamp → Scene) : Trace :=
  Build.pad (Build.trace 4 10000 (Units.seconds 1) f) (Units.seconds 3) (Units.seconds 1) (Units.seconds 1)

/-- `forbid` (violated): The subject, a car in the right of two marked lanes running east on a highway, moves across the broken line into the left lane; at the observation at which its footprint leaves the right lane its turn indicator is off and it gives no arm signal. No other road user is in the scene. -/
def forbidTrace : Trace :=
  episode fun k t => twoLaneScene t [subject k TurnIndicatorState.off HandSignal.noSignal]

/-- `permit` (compliant): The same two-lane highway. The subject shows its left indicator and moves from the right lane into the left lane, which lies to its left; at the observation of the departure the only other road user, a car far back in the left lane, is not predicted to approach within the conflict horizon. -/
def permitTrace : Trace :=
  episode fun k t =>
    twoLaneScene t
      [ subject k TurnIndicatorState.left HandSignal.noSignal
      , otherCar (-100 + 8 * Int.ofNat k) 8 ]

/-- `idle` (not_applicable): The subject travels on a highway whose roadway carries a single lane in its direction of travel, with one lane in the opposite direction; it moves out of its lane without signalling. The trigger's two-or-more-lanes condition fails and the duty is not engaged. -/
def idleTrace : Trace :=
  episode fun k t => oneLaneScene t [subject k TurnIndicatorState.off HandSignal.noSignal]

/-- `blind` (unknown): The subject moves from the right lane into the left lane of the two-lane highway, but the source observes no signals: sig.turn_indicator and sig.hand_signal are absent, so whether the appropriate signal was given is unknown. -/
def blindTrace : Trace :=
  episode fun k t => twoLaneScene t [subject k TurnIndicatorState.left HandSignal.noSignal]

/-- `branch_1` (violated): The subject shows its left indicator and moves from the right lane into the left lane while a car closes from behind in the left lane at a much higher speed: under the velocities observed the two centres approach within the conflict horizon and the centre distance at the closest approach falls below the minimum clearance. -/
def branch_1Trace : Trace :=
  episode fun k t =>
    twoLaneScene t
      [ subject k TurnIndicatorState.left HandSignal.noSignal
      , otherCar (-70 + 30 * Int.ofNat k) 30 ]

/-- `branch_2` (compliant): The subject is the only road user in the scene on the two-lane highway: it shows its left indicator and moves from the right lane into the left lane, and the duty is decided for the subject alone. -/
def branch_2Trace : Trace :=
  episode fun k t => twoLaneScene t [subject k TurnIndicatorState.left HandSignal.noSignal]

/-- `branch_3` (violated): the subject shows its left indicator and moves into the left lane, where a
    halted car stands whose body its own body touches: the centres are not predicted to approach
    (the subject is drawing away from it), but the gap to a road user already in the lane entered is
    zero, which is contact, so the movement was not one that could be made with safety. -/
def branch_3Trace : Trace :=
  episode fun k t =>
    twoLaneScene t
      [ subject k TurnIndicatorState.left HandSignal.noSignal
      , Build.user 2 [RoadUserClass.motorVehicle] (cm 1560, m 6) Build.east (Units.metresPerSecond 0) carExtent ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_223_1b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (10000, 13000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator", "sig.hand_signal"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_223_1b
