/-
  Witnesses for NRS_484B_217_2.

  The carriageway: a two-way highway (region 10) from x = -200 m to 400 m, y in [-4, 4] m; an
  eastbound lane 11 (y in [-3.5, 0]) and a westbound lane 12 (y in [0, 3.5]), both on highway 10; a
  centre line 13, a strip y in [-0.1, 0.1] on highway 10. The subject (track 1) is a motor vehicle
  4.6 m long and 1.8 m wide (half-extents 2.3, 0.9, 0.75 m). With the reading's tolerance of 0.3 m
  its body reaches past the centre line where the line's lateral offset is below 0.6 m.

  - forbid / idle / blind: three scenes 1 s apart; the subject at y = -1.75, -0.5, 1.1 (offset of
    the line 1.65, 0.4, -1.0 m), indicator off; forbid with solid yellow left markings, idle with
    broken white ones and no sign, blind with the markings masked.
  - permit: the subject at y = -1.0 (offset 0.9 m) throughout.
  - branch_1..4, 8, 10, 11 (the left-turn exception): 141 scenes 0.1 s apart then the last scene held
    for 11 s; the subject runs east at 10 m/s along y = -1.75 to x = 125 m (12.5 s), then turns
    left at 5 m/s (heading 16°, 23°, 37° while still in its lane, the course change), its body
    reaching past the line from 12.9 s (heading 53°), and enters the driveway entrance 20 (or, in
    branch_11, an intersection 20) on highway 10 at x 124..130 m, y 4..12 m. The subject's
    int.left_turn is declared true at region 20; asm.business_or_residence_district is true.
  - branch_5, 6, 7, 9 (the adjoining-highway exception): nine scenes 0.5 s apart; the zone is a
    no_passing zone sign governing both lanes (markings broken white); the subject drifts across the
    line at a heading of 16° (from 1.5 s) and turns into highway 30 (x 20..30 m, y 4..100 m) at 3 s.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_217_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_217_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (cm 230, cm 90, cm 75)
def mps (n : Int) : Q := Units.metresPerSecond n

def solidYellow : MarkingType × MarkingColour := (.solid, .yellow)
def brokenWhite : MarkingType × MarkingColour := (.broken, .white)
def solidWhite : MarkingType × MarkingColour := (.solid, .white)

def highwayH : Structure := Build.rect 10 .highway (m (-200)) (m (-4)) (m 400) (m 4)

def markedLane (id : RegionId) (y0 y1 : Q) (dir : Vec) (left : MarkingType × MarkingColour) : Structure :=
  let base := Build.lane id [(m (-200), y0), (m 400, y0), (m 400, y1), (m (-200), y1)] dir
  { base with
    ways := some [10]
    lane := base.lane.map fun l => { l with markingLeft := some left, markingRight := some solidWhite } }

def laneE (mk : MarkingType × MarkingColour) : Structure := markedLane 11 (cm (-350)) (m 0) Build.east mk
def laneW (mk : MarkingType × MarkingColour) : Structure := markedLane 12 (m 0) (cm 350) Build.west mk

def centreLine : Structure :=
  { Build.rect 13 .centreLine (m (-200)) (cm (-10)) (m 400) (cm 10) with ways := some [10] }

def target (kind : StructureKind) : Structure :=
  { Build.rect 20 kind (m 124) (m 4) (m 130) (m 12) with ways := some [10] }

def sideHighway : Structure := Build.rect 30 .highway (m 20) (m 4) (m 30) (m 100)

def simpleMap (mk : MarkingType × MarkingColour) : List Structure :=
  [highwayH, laneE mk, laneW mk, centreLine, target .drivewayOrAlleyEntrance]

def signalled (u : RoadUser) (ind : TurnIndicatorState) (hand : HandSignal) : RoadUser :=
  Build.withSignals u fun s => { s with turnIndicator := some ind, handSignal := some hand }

/-- The subject in the three-scene traces at lateral position `y k`, moving east at 10 m/s. -/
def straightSubject (y : Nat → Q) (k : Nat) : RoadUser :=
  signalled (Build.user 1 [.motorVehicle] (m (10 * Int.ofNat k), y k) Build.east (mps 10) body
    (some (m (11 * Int.ofNat k)))) .off .noSignal

def overtakeY (k : Nat) : Q :=
  match k with
  | 0 => cm (-175)
  | 1 => cm (-50)
  | _ => cm 110

def noLeftTurn : List DeclaredIntent := [{ vehicle := 1, target := 20, values := [("int.left_turn", false)] }]

/-- `forbid` (violated): The subject vehicle occupies a lane whose left st.lane_marking is solid yellow; it moves left until prim.region_lateral_offset of the centre line is -1.0 m to overtake a slower vehicle; int.left_turn is declared false at every region and it stays on the same highway. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ straightSubject overtakeY k
      , Build.user 2 [.motorVehicle] (m (15 + 5 * Int.ofNat k), cm (-175)) Build.east (mps 5) body ]
      (simpleMap solidYellow)
      []
      (intents := noLeftTurn)

/-- `permit` (compliant): The subject occupies the same no-passing lane (left marking solid yellow) and keeps the centre line 0.9 m to its left with a body width of 1.8 m plus margin: the offset stays above half its width minus the tolerance. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ straightSubject (fun _ => cm (-100)) k ]
      (simpleMap solidYellow)
      []
      (intents := noLeftTurn)

/-- `idle` (not_applicable): The subject's lane has a broken white left marking and no no_passing dev.zone_sign governs any region it occupies; it crosses the centre line to overtake. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ straightSubject overtakeY k ]
      (simpleMap brokenWhite)
      []
      (intents := noLeftTurn)

/-- `blind` (unknown): The source does not observe st.lane_marking and no zone sign is in the scene; the subject's body reaches past the centre line. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ straightSubject overtakeY k ]
      (simpleMap solidYellow)
      []
      (intents := noLeftTurn)

-- ---------------------------------------------------------------------------------------------
-- The left turn into region 20 (0.1 s apart): position, heading, speed, path length, yaw rate.
-- ---------------------------------------------------------------------------------------------
def turnPose (k : Nat) : Vec × Vec × Q × Q × Q :=
  if k ≤ 125 then
    ((m (Int.ofNat k), cm (-175)), Build.east, mps 10, m (Int.ofNat k), Units.degrees 0)
  else
    match k - 125 with
    | 1 => ((cm 12548, cm (-161)), (Units.ratio 24 25, Units.ratio 7 25), mps 5, cm 12550, Units.degrees 163)
    | 2 => ((cm 12594, cm (-142)), (Units.ratio 12 13, Units.ratio 5 13), mps 5, cm 12600, Units.degrees 64)
    | 3 => ((cm 12634, cm (-112)), (Units.ratio 4 5, Units.ratio 3 5), mps 5, cm 12650, Units.degrees 142)
    | 4 => ((cm 12664, cm (-72)), (Units.ratio 3 5, Units.ratio 4 5), mps 5, cm 12700, Units.degrees 163)
    | 5 => ((cm 12683, cm (-26)), (Units.ratio 5 13, Units.ratio 12 13), mps 5, cm 12750, Units.degrees 142)
    | j => ((cm 12683, cm (-26 + 50 * (Int.ofNat j - 5))), Build.north, mps 5,
            cm (12500 + 50 * Int.ofNat j), if j == 6 then Units.degrees 226 else Units.degrees 0)

def leftTurnAt20 : List DeclaredIntent := [{ vehicle := 1, target := 20, values := [("int.left_turn", true)] }]

/-- One scene of the left turn; the left indicator is on from observation `onFrom` (never where none). -/
def turnScene (onFrom : Option Nat) (kind : StructureKind) (others : Nat → List RoadUser)
    (k : Nat) (t : Timestamp) : Scene :=
  let (pos, hd, sp, path, yaw) := turnPose k
  let ind : TurnIndicatorState :=
    match onFrom with
    | some k0 => if k0 ≤ k then .left else .off
    | none => .off
  let subj := signalled (Build.withKin (Build.user 1 [.motorVehicle] pos hd sp body (some path))
    fun kn => { kn with yawRate := some yaw }) ind .noSignal
  Build.scene t (some 1) (subj :: others k)
    [highwayH, laneE solidYellow, laneW solidYellow, centreLine, target kind]
    []
    (assumptions := [("asm.business_or_residence_district", true)])
    (intents := leftTurnAt20)

def turnTrace (onFrom : Option Nat) (kind : StructureKind) (others : Nat → List RoadUser) : Trace :=
  Build.pad (Build.trace 141 0 (Units.milliseconds 100) (turnScene onFrom kind others))
    Q.zero (Units.seconds 11) (Units.milliseconds 500)

def nobody : Nat → List RoadUser := fun _ => []

/-- `branch_1` (compliant): In the no-passing zone (asm.business_or_residence_district declared true at every observation) the subject's int.left_turn is declared true at a driveway_or_alley_entrance on the zone's highway; while still in its own lane its heading turns off the lane's direction to the left (NRS_484B_413_2 engages there, within the turn window before the crossing), its left indicator having been on for the last 120 m before that course change, so NRS_484B_413_2 is complied with; it then crosses the centre line; no other road user is in the scene. -/
def branch_1Trace : Trace := turnTrace (some 0) .drivewayOrAlleyEntrance nobody

/-- `branch_2` (violated): As branch_1 but sig.turn_indicator is off and sig.hand_signal no_signal at the observation before the crossing. -/
def branch_2Trace : Trace := turnTrace none .drivewayOrAlleyEntrance nobody

/-- An oncoming vehicle heading straight at the subject: at 12.9 s its closest approach is 2 s ahead
    at a centre distance of 1 m. -/
def oncomingCar (k : Nat) : List RoadUser :=
  [Build.user 2 [.motorVehicle]
    (cm (13944 - 30 * (Int.ofNat k - 129)), cm (1468 - 40 * (Int.ofNat k - 129)))
    (Units.ratio (-3) 5, Units.ratio (-4) 5) (mps 5) body]

/-- `branch_3` (violated): As branch_1 but an oncoming vehicle (rel.oncoming) has a closest approach to the subject in 2 s at a centre distance of 1 m. -/
def branch_3Trace : Trace := turnTrace (some 0) .drivewayOrAlleyEntrance oncomingCar

/-- `branch_4` (violated): As branch_1 (asm.business_or_residence_district declared true, the heading turning left off the subject's lane direction while it still occupies that lane, before the crossing) but the left indicator came on only 10 m before that course change and stays on through the crossing, so NRS_484B_413_2 is violated at the course change although a signal was given at the observation before the crossing. -/
def branch_4Trace : Trace := turnTrace (some 115) .drivewayOrAlleyEntrance nobody

-- ---------------------------------------------------------------------------------------------
-- The crossing to an adjoining highway (0.5 s apart): position, heading, path length.
-- ---------------------------------------------------------------------------------------------
def d16 : Vec := (Units.ratio 24 25, Units.ratio 7 25)

def driftPose (k : Nat) : Vec × Vec × Q :=
  match k with
  | 0 => ((m 0, cm (-175)), Build.east, m 0)
  | 1 => ((m 5, cm (-175)), Build.east, m 5)
  | 2 => ((m 10, cm (-175)), d16, m 10)
  | 3 => ((cm 1480, cm (-35)), d16, m 15)
  | 4 => ((cm 1960, cm 105), d16, m 20)
  | 5 => ((m 23, m 3), (Units.ratio 3 5, Units.ratio 4 5), cm 2420)
  | j => ((m 25, cm (600 + 500 * (Int.ofNat j - 6))), Build.north, cm (2800 + 500 * (Int.ofNat j - 6)))

def driftScene (ind : TurnIndicatorState) (hand : HandSignal) (others : Nat → List RoadUser)
    (k : Nat) (t : Timestamp) : Scene :=
  let (pos, hd, path) := driftPose k
  let subj := signalled (Build.user 1 [.motorVehicle] pos hd (mps 10) body (some path)) ind hand
  Build.scene t (some 1) (subj :: others k)
    [highwayH, laneE brokenWhite, laneW brokenWhite, centreLine, sideHighway]
    [Build.zoneSign 50 [11, 12] .noPassing false (some {})]

def driftTrace (ind : TurnIndicatorState) (hand : HandSignal) (others : Nat → List RoadUser) : Trace :=
  Build.trace 9 0 (Units.milliseconds 500) (driftScene ind hand others)

/-- `branch_5` (compliant): In the zone the subject signals left, crosses the centre line and within the turn window occupies another highway and no longer the zone's highway; no oncoming or following road user has a conflicting closest approach. -/
def branch_5Trace : Trace := driftTrace .left .noSignal nobody

/-- `branch_6` (violated): as branch_5, but an oncoming vehicle in the westbound lane has a closest
    approach to the subject within 1 s at a centre distance below 1 m while it crosses. -/
def branch_6Trace : Trace :=
  driftTrace .left .noSignal fun k =>
    [Build.user 2 [.motorVehicle] (m (49 - 5 * Int.ofNat k), cm 175) Build.west (mps 10) body]

/-- `branch_7` (violated): as branch_5, but a following vehicle at 20 m/s behind the subject on its
    course closes on it (closest approach in 0.8 s at a centre distance of zero) while it crosses. -/
def branch_7Trace : Trace :=
  driftTrace .left .noSignal fun k =>
    if k ≤ 2 then
      [Build.user 3 [.motorVehicle] (cm (712 - 1000 * (3 - Int.ofNat k)), cm (-259)) Build.east (mps 20) body]
    else
      [Build.user 3 [.motorVehicle] (cm (712 + 960 * (Int.ofNat k - 3)), cm (-259 + 280 * (Int.ofNat k - 3)))
        d16 (mps 20) body]

/-- `branch_8` (violated): as branch_1, but a pedestrian walking west along the edge of the highway
    (neither oncoming nor following) has a closest approach to the subject about 1 s ahead at under
    0.5 m while it crosses: the crossing is not safe. -/
def branch_8Trace : Trace :=
  turnTrace (some 0) .drivewayOrAlleyEntrance fun k =>
    [Build.user 4 [.pedestrian] (cm (13114 - 15 * (Int.ofNat k - 129)), cm 380) Build.west
      (Units.micrometresPerSecond 1500000) (cm 30, cm 30, cm 90)]

/-- `branch_9` (compliant): as branch_5, but the indicator is off and the driver's hand signal means
    left. -/
def branch_9Trace : Trace := driftTrace .off .left nobody

/-- `branch_10` (violated): as branch_1, but at the first observation of the crossing another vehicle
    moving with the subject's velocity, 1.5 m to its left, is in contact with its body (no closest
    approach, since they do not close): the crossing is not safe. -/
def branch_10Trace : Trace :=
  turnTrace (some 0) .drivewayOrAlleyEntrance fun k =>
    if k == 129 then
      [Build.user 5 [.motorVehicle] (cm 12574, cm 58) (Units.ratio 3 5, Units.ratio 4 5) (mps 5) body]
    else []

/-- `branch_11` (compliant): as branch_1, but the declared left turn is at an intersection on the
    zone's highway. -/
def branch_11Trace : Trace := turnTrace (some 0) .intersection nobody

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_217_2"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_marking"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .compliant ]

end TrafficSpecWitness.NRS_484B_217_2
