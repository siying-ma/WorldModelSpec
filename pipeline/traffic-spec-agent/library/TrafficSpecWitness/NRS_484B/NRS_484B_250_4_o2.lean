/-
  Witnesses for NRS_484B_250_4_o2.

  The geometry, once for all the scenes below. A crossroads: region 100, the square from
  (−6 m, −6 m) to (6 m, 6 m), of kind `intersection` (`junction`). The southern approach is
  region 200, a lane 6 m wide running north from (−6 m, −60 m) to (0 m, −6 m) (`approachLane`),
  which runs into region 100. A transverse stop line, region 300, lies across that lane
  (`nearStopLine`, from y = −10 m to y = −8 m; `farStopLine`, twenty metres further back, for the
  scene that turns on the stop line alone). One device, head 1, is a traffic signal with its
  vehicular faces uncovered: `deadHead` shows no valid indication (`inoperative`), `liveHead` is
  back in operation and shows a circular green. It governs the approach lane, except in the scene
  that puts it on the intersection region itself.

  The subject is track 1, a motor vehicle 4 m long and 2 m wide, at x = −3 m, heading north. Every
  trace is sixteen instants one second apart, from t = 0. The subject stands still on the stop line
  for the first twelve of them and then goes forward: `slowSubject` at three metres a second,
  entering the junction at the thirteenth instant (t = 13 s); `fastSubject` at ten, entering at the
  twelfth; `farSubject` from the far stop line at ten, entering at the fourteenth. The twelve
  standing instants cover the ten-second look-back window at every instant judged, so no window is
  truncated. Each scenario names the instants it speaks about in its `window`: the instants from
  the entry on, since the rule looks back past the entry and the applicability before it is
  decided only on the entry's own account.

  Other road users are track 2, a motor vehicle of the same body, with its longitudinal
  acceleration observed so that the give-way limb is decided either way.

  Every figure here is the witness's own and appears nowhere in the rule. Against the run's
  reading — cautious speed 7 m/s, halt tolerance 0.2 m/s, junction reach 10 m, look-back window
  10 s, yield horizon 4 s, yield clearance 6 m, obstruction reach 8 m, single-file reach 1.8 m,
  give-way deceleration 1.5 m/s² — the margins are: a cautious scene runs at 3 m/s and an
  uncautious one at 10 m/s; a halt at the near stop line stands 1 m from the junction and one at
  the far stop line 21 m from it; a conflicting pair passes 3.6 m apart at its closest approach and
  a clear pair 8 m; a body in another's way stands 7 m ahead of it squarely in its line, and a body
  out of its way stands 8 m behind it or 3 m off its line.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def mps2 (n : Int) : Q := Units.metresPerSecondSq n

-- Binders ↦ tracks: v ↦ 1

/-- Half-length, half-width, half-height of a vehicle body. -/
def carBody : Q × Q × Q := (m 2, m 1, m 1)

/-- The intersection region: the square where the two roadways meet. -/
def junction : Structure := Build.rect 100 .intersection (m (-6)) (m (-6)) (m 6) (m 6)

/-- The southern approach lane, with the intersection it runs into (none where the source does not
    report it). -/
def approachLane (enters : Option RegionId) : Structure :=
  Build.lane 200 [(m (-6), m (-60)), (m 0, m (-60)), (m 0, m (-6)), (m (-6), m (-6))]
    Build.north (enters := enters)

/-- A transverse stop line across that lane. -/
def stopLineBetween (y0 y1 : Int) : Structure := Build.rect 300 .stopLine (m (-6)) (m y0) (m 0) (m y1)

/-- The clearly marked stop line at the junction's entrance. -/
def nearStopLine : Structure := stopLineBetween (-10) (-8)
/-- A stop line twenty metres back from the entrance. -/
def farStopLine : Structure := stopLineBetween (-30) (-28)

/-- The uncovered vehicular head, showing no valid indication. -/
def deadHead (governs : List RegionId) : Device :=
  { Build.signal 1 governs [.dark] with uncovered := some true, inoperative := some true }

/-- The same head back in operation, showing a circular green. -/
def liveHead (governs : List RegionId) : Device :=
  { Build.signal 1 governs [.circularGreen] with uncovered := some true, inoperative := some false }

/-- The subject on the southern approach, at `y` and at `speed`. -/
def subjectAt (y speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (-3), y) Build.north speed carBody

/-- Another motor vehicle, with its longitudinal acceleration observed. -/
def otherAt (track : TrackId) (pos : Vec) (heading : Vec) (speed accel : Q) : RoadUser :=
  Build.withKin (Build.user track [.motorVehicle] pos heading speed carBody)
    fun kin => { kin with accelLongitudinal := some accel }

/-- The ordinary approach: at rest on the near stop line, then north at three metres a second,
    within the junction from the thirteenth instant on. -/
def slowSubject (k : Nat) : RoadUser :=
  if k ≤ 11 then subjectAt (m (-9)) Q.zero
  else if k = 12 then subjectAt (m (-7)) (mps 3)
  else if k = 13 then subjectAt (m (-4)) (mps 3)
  else if k = 14 then subjectAt (m (-1)) (mps 3)
  else subjectAt (m 2) (mps 3)

/-- The same halt, then north at ten metres a second: within the junction at the twelfth and
    thirteenth instants. -/
def fastSubject (k : Nat) : RoadUser :=
  if k ≤ 11 then subjectAt (m (-9)) Q.zero
  else if k = 12 then subjectAt (m (-5)) (mps 10)
  else if k = 13 then subjectAt (m 5) (mps 10)
  else subjectAt (m 15) (mps 10)

/-- A halt at the far stop line, then north at ten metres a second: within the junction at the
    fourteenth instant. -/
def farSubject (k : Nat) : RoadUser :=
  if k ≤ 11 then subjectAt (m (-29)) Q.zero
  else if k = 12 then subjectAt (m (-19)) (mps 10)
  else if k = 13 then subjectAt (m (-9)) (mps 10)
  else if k = 14 then subjectAt (m 1) (mps 10)
  else subjectAt (m 11) (mps 10)

/-- A scene of this crossroads. -/
def sceneOf (users : List RoadUser) (structures : List Structure) (devices : List Device)
    (t : Timestamp) : Scene :=
  Build.scene t (some 1) users structures devices

/-- Sixteen instants one second apart. -/
def traceOf (f : Nat → Timestamp → Scene) : Trace := Build.trace 16 0 (Units.seconds 1) f

/-- The ordinary furniture: the junction, the approach lane running into it, the near stop line,
    and the inoperative head on that lane. -/
def ordinaryGround : List Structure := [junction, approachLane (some 100), nearStopLine]
def ordinaryDevices : List Device := [deadHead [200]]

/-- Track 2 crossing from the west at three metres a second: level with the subject's body at the
    thirteenth instant, and drawing away from it after. -/
def crossingWest (k : Nat) : RoadUser :=
  otherAt 2 (m (-2 + 3 * (Int.ofNat k - 13)), m (-4)) Build.east (mps 3) Q.zero

/-- `forbid` (violated): An uncovered signal head governing the approach lane is inoperative. The subject halts at the marked stop line, then enters the intersection while the head is still inoperative. Another motor vehicle is already within the intersection, crossing from the left; the subject drives on and its body touches the other's. The rule reports violated. -/
def forbidTrace : Trace :=
  traceOf fun k t => sceneOf [slowSubject k, crossingWest k] ordinaryGround ordinaryDevices t

/-- `permit` (compliant): The same inoperative uncovered head and the same halt at the marked stop line; the subject then enters the empty intersection at a speed below the cautious speed and no other road user is anywhere in the scene. The duty binds the subject alone and is decided with no other party present: the rule reports compliant. -/
def permitTrace : Trace :=
  traceOf fun k t => sceneOf [slowSubject k] ordinaryGround ordinaryDevices t

/-- `idle` (not_applicable): The subject halts at the marked stop line while the uncovered head is inoperative, but the head returns to operation and shows a circular green while the subject still stands outside the intersection; the subject then enters under that operating green. The head was operative at the entry, so the subsection does not govern and the rule does not apply. -/
def idleTrace : Trace :=
  traceOf fun k t =>
    sceneOf [slowSubject k] ordinaryGround [if k ≤ 9 then deadHead [200] else liveHead [200]] t

/-- `blind` (unknown): The forbidding scene exactly, except that the source's capability manifest declares dev.inoperative absent, so whether the governing head showed no valid indication at the entry cannot be read and the rule reports unknown. -/
def blindTrace : Trace := forbidTrace

/-- Track 2 from the east: at rest at its own entrance until the tenth instant, then west at four
    metres a second into the junction. -/
def stoppedThenWest (k : Nat) : RoadUser :=
  if k ≤ 9 then otherAt 2 (m 27, m 2) Build.west Q.zero Q.zero
  else otherAt 2 (m (27 - 4 * (Int.ofNat k - 9)), m 2) Build.west (mps 4) Q.zero

/-- `branch_1` (violated): The same inoperative uncovered head and the same halt at the stop line. The intersection is empty when the subject enters, but another motor vehicle had completed a stop at its own entrance a few seconds earlier and is now moving into the junction from the right; the subject crosses in front of it and their centres pass within the yield clearance at their closest approach within the horizon. This exercises the previously-completed-a-stop limb of span c9 and the closest-approach limb of span c8: the rule reports violated. -/
def branch_1Trace : Trace :=
  traceOf fun k t => sceneOf [slowSubject k, stoppedThenWest k] ordinaryGround ordinaryDevices t

/-- Track 2 standing still west of the junction, pointing east, with the subject's body coming
    across its nose. -/
def haltedInLine : RoadUser := otherAt 2 (m (-10), m (-1)) Build.east Q.zero Q.zero

/-- `branch_2` (violated): The same inoperative uncovered head and the same halt at the marked stop line. A motor vehicle is already travelling east through the junction's western entrance when the subject pulls out across its path; that vehicle brakes and is brought to a halt short of the subject's flank. Their bodies never touch, and their centres stay clear of the yield clearance at their closest approach. The halted vehicle is at rest and the subject's reference point stands seven metres ahead of it along the direction it points, squarely in its line: the subject has taken the precedence. This exercises the give-way limb of span c8, which the contact and closest-approach limbs leave untouched: the rule reports violated. -/
def branch_2Trace : Trace :=
  traceOf fun k t => sceneOf [slowSubject k, haltedInLine] ordinaryGround ordinaryDevices t

/-- Track 2 standing still within the junction, pointing east across the subject's path, with the
    subject crossing well behind it. -/
def haltedAcross : RoadUser := otherAt 2 (m 5, m 3) Build.east Q.zero Q.zero

/-- `branch_3` (compliant): The same inoperative uncovered head and the same halt at the marked stop line. Another motor vehicle stands at rest within the intersection, pointing away across the subject's path, and the subject crosses well behind it: their bodies never touch, their centre distance at the closest approach stands far beyond the yield clearance, and the subject's reference point lies behind that vehicle along the direction it points, so it stands in nobody's way. This exercises the negative side of the give-way limb of span c8: the rule reports compliant. -/
def branch_3Trace : Trace :=
  traceOf fun k t => sceneOf [slowSubject k, haltedAcross] ordinaryGround ordinaryDevices t

/-- `branch_4` (violated): The same inoperative uncovered head and the same halt at the marked stop line, and again no other road user in the scene; but the subject enters the empty junction at ten metres a second, well above the cautious speed. This exercises the proceeding-cautiously limb of span c7: the rule reports violated. -/
def branch_4Trace : Trace :=
  traceOf fun k t => sceneOf [fastSubject k] ordinaryGround ordinaryDevices t

/-- Track 2 west of the junction: at rest at its own entrance until the tenth instant, then
    creeping east and braking hard as the subject crosses its nose. -/
def stoppedThenBraking (k : Nat) : RoadUser :=
  if k ≤ 9 then otherAt 2 (m (-14), m (-4)) Build.east Q.zero Q.zero
  else otherAt 2 (m (-14 + (Int.ofNat k - 9)), m (-4)) Build.east (mps 1) (Q.neg (mps2 2))

/-- `branch_5` (violated): The same inoperative uncovered head and the same halt at the marked stop line. Another motor vehicle, which had completed a stop at its own entrance, is creeping east towards the junction when the subject pulls out seven metres ahead of it, squarely in its line; it is not at rest, but it is braking at two metres a second squared, beyond the give-way deceleration. Their bodies never touch and their centres stay clear of the yield clearance. This exercises the deceleration side of the give-way limb of span c8: the rule reports violated. -/
def branch_5Trace : Trace :=
  traceOf fun k t => sceneOf [slowSubject k, stoppedThenBraking k] ordinaryGround ordinaryDevices t

/-- `branch_6` (violated): The same inoperative uncovered head, but the only stop line of this scene lies twenty metres back from the junction's entrance, far beyond the junction reach. The subject halts upon it, so the halt counts as made for this junction by its stop line alone, and then enters at ten metres a second. This exercises the stop-line limb of span c5: the rule reports violated. -/
def branch_6Trace : Trace :=
  traceOf fun k t =>
    sceneOf [farSubject k] [junction, approachLane (some 100), farStopLine] ordinaryDevices t

/-- `branch_7` (violated): The same inoperative uncovered head, and no stop line anywhere in the scene. The subject halts on the approach with its body a metre from the junction region, within the junction reach, so the halt counts as made for this junction by its place alone, and then enters at ten metres a second. This exercises the junction-reach limb of span c5: the rule reports violated. -/
def branch_7Trace : Trace :=
  traceOf fun k t => sceneOf [fastSubject k] [junction, approachLane (some 100)] ordinaryDevices t

/-- `branch_8` (violated): The same halt at the marked stop line, but the source reports the uncovered inoperative head as governing the intersection region itself and reports no intersection for the approach lane to run into. The head governs the junction directly, so the subsection governs, and the subject enters at ten metres a second. This exercises the region limb of "controlled by" in span c2: the rule reports violated. -/
def branch_8Trace : Trace :=
  traceOf fun k t =>
    sceneOf [fastSubject k] [junction, approachLane none, nearStopLine] [deadHead [100]] t

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := window }

/-- The instants from the ordinary entry (t = 13 s) to the end of the trace. -/
def afterSlowEntry : Option (Timestamp × Timestamp) := some (13000, 15000)
/-- The instants the subject spends within the junction after the fast entry (t = 12 s). -/
def afterFastEntry : Option (Timestamp × Timestamp) := some (12000, 13000)
/-- The instant of the far-halt entry (t = 14 s). -/
def afterFarEntry : Option (Timestamp × Timestamp) := some (14000, 14000)

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated [] afterSlowEntry
  , witness "permit" permitTrace .compliant [] afterSlowEntry
  , witness "idle" idleTrace .notApplicable [] afterSlowEntry
  , witness "blind" blindTrace (.unknown []) ["dev.inoperative"] afterSlowEntry
  , witness "branch_1" branch_1Trace .violated [] afterSlowEntry
  , witness "branch_2" branch_2Trace .violated [] afterSlowEntry
  , witness "branch_3" branch_3Trace .compliant [] afterSlowEntry
  , witness "branch_4" branch_4Trace .violated [] afterFastEntry
  , witness "branch_5" branch_5Trace .violated [] afterSlowEntry
  , witness "branch_6" branch_6Trace .violated [] afterFarEntry
  , witness "branch_7" branch_7Trace .violated [] afterFastEntry
  , witness "branch_8" branch_8Trace .violated [] afterFastEntry ]

end TrafficSpecWitness.NRS_484B_250_4_o2
