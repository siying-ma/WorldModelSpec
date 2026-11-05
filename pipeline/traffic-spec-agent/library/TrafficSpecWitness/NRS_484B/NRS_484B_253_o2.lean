/-
  Witnesses for NRS_484B_253_o2.

  The map (metres, +x east, +y north; every figure here is the witness's own and appears nowhere in
  the rule):

  - the junction (region 3, kind intersection) is the square [-6, 6] x [-6, 6], where a
    north-south street and an east-west street of two 6 m lanes each meet.
  - its approaches, as the source records them (`enters`): region 11, the northbound lane of the
    south leg (x in [0, 6], y in [-206, -6], designated direction north); region 12, the southbound
    lane of the north leg (x in [-6, 0], y in [6, 306], direction south); region 14, the eastbound
    lane of the west leg (x in [-206, -6], y in [-6, 0], direction east). Each carries the junction
    as its entrance end, so each is a carrier a vehicle approaches that junction through. The lane
    the turning car leaves by lies west of the junction and is not mapped: this source recorded the
    junction and the carriers that run into it.
  - the turning car is track 2, the subject track 1, and the third vehicle of `branch_1` and
    `branch_4` is track 3. Every car is 4 m long and 2 m wide (half-extents 2 m, 1 m, 0.75 m).
    Occupancy is declared observation by observation, as each footprint covers the regions.
  - every scene declares the way to lie within a business or residential district, the assumption
    NRS_484B_413_2 reads.

  The turning car's run (`turnerRun`, shared by every scenario but `idle`): nineteen observations
  north up region 11 at 6 m/s, 6 m apart, so that 108 m of path lie behind it when it reaches the
  junction at t = 18 s; at t = 19 s it is swinging left inside the junction, at (0.6, 1.8), its
  heading 53 degrees west of north and its yaw rate 53 deg/s, so that the signed heading change over
  the 10 s behind is 53 degrees — a change of course to the left by the reading's bounds. Its left
  lamp and its arm signal are off for the first two observations and given from t = 2 s on, so that
  102 m — over 330 feet — of signalled path lie behind the turn, more than the distance
  NRS_484B_413_2 requires, and the signalled run begins inside the recording. t = 19 s is the
  observation every witness is about.

  The subject keeps to region 12, the opposing approach, except in `branch_5`, where it comes up
  region 14 from the west — an approach to the same junction whose designated direction is not
  opposed to the turning car's.

  Why the `forbid` subject creeps: at the judged observation the turning car's yield must still
  stand, so the subject may not itself be an immediate hazard to it — its body must stand further
  from the junction than the ground its own speed covers in the arrival time. At 0.2 m/s that is
  1 m, and the subject's body stands 2 m short of the junction; under the two velocities observed
  the centres close to 4.19 m, below the 5 m minimum clearance, 1.29 s ahead, within the 3 s
  horizon.

  Every trace is 1 s apart and padded by 15 s of the first scene, so that the 10 s windows the rule
  looks back over — the act's course change, the yield, and the overlap with the approach carrier —
  are covered rather than truncated; nothing is looked ahead to, so nothing is padded after. Each
  witness names the instants it speaks about (`window`): t = 19 s, and for `idle` the whole run.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def degPerSec (n : Int) : Q := Units.degrees n
/-- The creeping subject's speed, 0.2 m/s. -/
def creep : Q := Units.ratio 1 5

-- Binders ↦ tracks: subject ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The map
-- ---------------------------------------------------------------------------------------------
def junction : Structure := Build.rect 3 .intersection (m (-6)) (m (-6)) (m 6) (m 6)

/-- The south leg's northbound lane, the turning car's approach. -/
def northboundApproach : Structure :=
  Build.lane 11 [(m 0, m (-206)), (m 6, m (-206)), (m 6, m (-6)), (m 0, m (-6))]
    Build.north (enters := some 3)

/-- The north leg's southbound lane, the opposing approach the subject keeps to. -/
def southboundApproach : Structure :=
  Build.lane 12 [(m (-6), m 6), (m 0, m 6), (m 0, m 306), (m (-6), m 306)]
    Build.south (enters := some 3)

/-- The west leg's eastbound lane: an approach to the same junction whose designated direction is
    not opposed to the turning car's. -/
def eastboundApproach : Structure :=
  Build.lane 14 [(m (-206), m (-6)), (m (-6), m (-6)), (m (-6), m 0), (m (-206), m 0)]
    Build.east (enters := some 3)

def crossroads : List Structure :=
  [junction, northboundApproach, southboundApproach, eastboundApproach]

-- ---------------------------------------------------------------------------------------------
-- Cars and scenes
-- ---------------------------------------------------------------------------------------------
/-- 53 degrees west of north, the turning car's heading at the judged observation. -/
def northWest : Vec := (Units.ratio (-4) 5, Units.ratio 3 5)

/-- A car of this witness, as the source observed it: position, heading, speed, yaw rate and the
    path length travelled since the recording began, with its turn lamp and its arm signal. -/
def car (track : TrackId) (pos heading : Vec) (speed yaw path : Q)
    (indicator : TurnIndicatorState) (hand : HandSignal) : RoadUser :=
  Build.withSignals
    (Build.withKin (Build.user track [.motorVehicle] pos heading speed (m 2, m 1, cm 75) (some path))
      fun k => { k with yawRate := some yaw })
    fun g => { g with turnIndicator := some indicator, handSignal := some hand,
                      brakeLamp := some false, hazard := some false }

/-- One observation of a car: position, heading, speed, yaw rate, path length, and the regions its
    footprint covers. -/
def carAt (track : TrackId) (indicator : TurnIndicatorState) (hand : HandSignal)
    (run : List (Vec × Vec × Q × Q × Q × List RegionId)) (k : Nat) : RoadUser × List RegionId :=
  let (p, h, sp, yw, pl, occ) :=
    run[k]?.getD ((m 0, m 0), Build.north, Q.zero, Q.zero, Q.zero, [])
  (car track p h sp yw pl indicator hand, occ)

/-- The source's declaration of the turning car's intention at the junction. -/
def turnerIntent : List DeclaredIntent :=
  [{ vehicle := 2, target := 3, values := [("int.left_turn", true)] }]

/-- `branch_6`: both turning cars declare the same intention at the junction. -/
def bothTurnersIntent : List DeclaredIntent :=
  [{ vehicle := 2, target := 3, values := [("int.left_turn", true)] },
   { vehicle := 4, target := 3, values := [("int.left_turn", true)] }]

/-- The way lies within a business or residential district. -/
def district : List (AsmId × Bool) := [("asm.way_within_business_or_residential_district", true)]

def sceneFrom (t : Timestamp) (parts : List (RoadUser × List RegionId))
    (intents : List DeclaredIntent) : Scene :=
  Build.scene t (some 1) (parts.map (·.1)) crossroads []
    (some (parts.flatMap fun (u, rs) => rs.map fun r => (u.track, r)))
    {} district intents

def padded (τ : Trace) : Trace := Build.pad τ (Units.seconds 15) Q.zero (Units.seconds 1)

def runOf (parts : Nat → List (RoadUser × List RegionId)) (intents : List DeclaredIntent) : Trace :=
  padded (Build.trace 20 0 (Units.seconds 1) fun k t => sceneFrom t (parts k) intents)

-- ---------------------------------------------------------------------------------------------
-- The runs
-- ---------------------------------------------------------------------------------------------
/-- The turning car: north up region 11 at 6 m/s, into the junction, and swinging left. -/
def turnerRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  [ ((m 3, m (-111)), Build.north, mps 6, Q.zero, m 0, [11])
  , ((m 3, m (-105)), Build.north, mps 6, Q.zero, m 6, [11])
  , ((m 3, m (-99)), Build.north, mps 6, Q.zero, m 12, [11])
  , ((m 3, m (-93)), Build.north, mps 6, Q.zero, m 18, [11])
  , ((m 3, m (-87)), Build.north, mps 6, Q.zero, m 24, [11])
  , ((m 3, m (-81)), Build.north, mps 6, Q.zero, m 30, [11])
  , ((m 3, m (-75)), Build.north, mps 6, Q.zero, m 36, [11])
  , ((m 3, m (-69)), Build.north, mps 6, Q.zero, m 42, [11])
  , ((m 3, m (-63)), Build.north, mps 6, Q.zero, m 48, [11])
  , ((m 3, m (-57)), Build.north, mps 6, Q.zero, m 54, [11])
  , ((m 3, m (-51)), Build.north, mps 6, Q.zero, m 60, [11])
  , ((m 3, m (-45)), Build.north, mps 6, Q.zero, m 66, [11])
  , ((m 3, m (-39)), Build.north, mps 6, Q.zero, m 72, [11])
  , ((m 3, m (-33)), Build.north, mps 6, Q.zero, m 78, [11])
  , ((m 3, m (-27)), Build.north, mps 6, Q.zero, m 84, [11])
  , ((m 3, m (-21)), Build.north, mps 6, Q.zero, m 90, [11])
  , ((m 3, m (-15)), Build.north, mps 6, Q.zero, m 96, [11])
  , ((m 3, m (-9)), Build.north, mps 6, Q.zero, m 102, [11])
  , ((m 3, m (-3)), Build.north, mps 6, Q.zero, m 108, [3])
  , ((cm 60, cm 180), northWest, mps 6, degPerSec 53, m 114, [3]) ]

/-- A turning car at an observation: its left lamp and arm signal are given from the third
    observation on, so that the signalled run begins inside the recording. -/
def signallingAt (track : TrackId) (run : List (Vec × Vec × Q × Q × Q × List RegionId))
    (signalling : Bool) (k : Nat) : RoadUser × List RegionId :=
  if signalling && k ≥ 2 then carAt track .left .left run k
  else carAt track .off .noSignal run k

def turnerAt (signalling : Bool) (k : Nat) : RoadUser × List RegionId :=
  signallingAt 2 turnerRun signalling k

/-- `branch_6`'s leading turner (track 2): the same path one step ahead of `turnerRun`, so that at
    the judged observation it is heading west across the junction, its signed heading change over
    the window behind a quarter turn to the left. -/
def leadTurnerRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  [ ((m 3, m (-105)), Build.north, mps 6, Q.zero, m 0, [11])
  , ((m 3, m (-99)), Build.north, mps 6, Q.zero, m 6, [11])
  , ((m 3, m (-93)), Build.north, mps 6, Q.zero, m 12, [11])
  , ((m 3, m (-87)), Build.north, mps 6, Q.zero, m 18, [11])
  , ((m 3, m (-81)), Build.north, mps 6, Q.zero, m 24, [11])
  , ((m 3, m (-75)), Build.north, mps 6, Q.zero, m 30, [11])
  , ((m 3, m (-69)), Build.north, mps 6, Q.zero, m 36, [11])
  , ((m 3, m (-63)), Build.north, mps 6, Q.zero, m 42, [11])
  , ((m 3, m (-57)), Build.north, mps 6, Q.zero, m 48, [11])
  , ((m 3, m (-51)), Build.north, mps 6, Q.zero, m 54, [11])
  , ((m 3, m (-45)), Build.north, mps 6, Q.zero, m 60, [11])
  , ((m 3, m (-39)), Build.north, mps 6, Q.zero, m 66, [11])
  , ((m 3, m (-33)), Build.north, mps 6, Q.zero, m 72, [11])
  , ((m 3, m (-27)), Build.north, mps 6, Q.zero, m 78, [11])
  , ((m 3, m (-21)), Build.north, mps 6, Q.zero, m 84, [11])
  , ((m 3, m (-15)), Build.north, mps 6, Q.zero, m 90, [11])
  , ((m 3, m (-9)), Build.north, mps 6, Q.zero, m 96, [11])
  , ((m 3, m (-3)), Build.north, mps 6, Q.zero, m 102, [3])
  , ((cm 60, cm 180), northWest, mps 6, degPerSec 53, m 108, [3])
  , ((cm (-480), m 4), Build.west, mps 6, degPerSec 37, m 114, [3]) ]

/-- `branch_6`'s third vehicle (track 3): down the opposing approach at 14 m/s, 16 m short of the
    junction at the judged observation. It is an immediate hazard to both turning cars; the car
    behind swings into predicted conflict with it, the leading car does not. -/
def hazardAheadRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  [ ((m (-3), m 290), Build.south, mps 14, Q.zero, m 0, [12])
  , ((m (-3), m 276), Build.south, mps 14, Q.zero, m 14, [12])
  , ((m (-3), m 262), Build.south, mps 14, Q.zero, m 28, [12])
  , ((m (-3), m 248), Build.south, mps 14, Q.zero, m 42, [12])
  , ((m (-3), m 234), Build.south, mps 14, Q.zero, m 56, [12])
  , ((m (-3), m 220), Build.south, mps 14, Q.zero, m 70, [12])
  , ((m (-3), m 206), Build.south, mps 14, Q.zero, m 84, [12])
  , ((m (-3), m 192), Build.south, mps 14, Q.zero, m 98, [12])
  , ((m (-3), m 178), Build.south, mps 14, Q.zero, m 112, [12])
  , ((m (-3), m 164), Build.south, mps 14, Q.zero, m 126, [12])
  , ((m (-3), m 150), Build.south, mps 14, Q.zero, m 140, [12])
  , ((m (-3), m 136), Build.south, mps 14, Q.zero, m 154, [12])
  , ((m (-3), m 122), Build.south, mps 14, Q.zero, m 168, [12])
  , ((m (-3), m 108), Build.south, mps 14, Q.zero, m 182, [12])
  , ((m (-3), m 94), Build.south, mps 14, Q.zero, m 196, [12])
  , ((m (-3), m 80), Build.south, mps 14, Q.zero, m 210, [12])
  , ((m (-3), m 66), Build.south, mps 14, Q.zero, m 224, [12])
  , ((m (-3), m 52), Build.south, mps 14, Q.zero, m 238, [12])
  , ((m (-3), m 38), Build.south, mps 14, Q.zero, m 252, [12])
  , ((m (-3), m 24), Build.south, mps 14, Q.zero, m 266, [12]) ]

/-- `forbid`'s and `branch_2`'s subject: a creep down region 12 at 0.2 m/s, its body standing 2 m
    short of the junction at the judged observation — twice the metre its own speed covers in the
    arrival time. -/
def creepingSubjectRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  [ ((m (-3), cm 1380), Build.south, creep, Q.zero, cm 0, [12])
  , ((m (-3), cm 1360), Build.south, creep, Q.zero, cm 20, [12])
  , ((m (-3), cm 1340), Build.south, creep, Q.zero, cm 40, [12])
  , ((m (-3), cm 1320), Build.south, creep, Q.zero, cm 60, [12])
  , ((m (-3), cm 1300), Build.south, creep, Q.zero, cm 80, [12])
  , ((m (-3), cm 1280), Build.south, creep, Q.zero, cm 100, [12])
  , ((m (-3), cm 1260), Build.south, creep, Q.zero, cm 120, [12])
  , ((m (-3), cm 1240), Build.south, creep, Q.zero, cm 140, [12])
  , ((m (-3), cm 1220), Build.south, creep, Q.zero, cm 160, [12])
  , ((m (-3), cm 1200), Build.south, creep, Q.zero, cm 180, [12])
  , ((m (-3), cm 1180), Build.south, creep, Q.zero, cm 200, [12])
  , ((m (-3), cm 1160), Build.south, creep, Q.zero, cm 220, [12])
  , ((m (-3), cm 1140), Build.south, creep, Q.zero, cm 240, [12])
  , ((m (-3), cm 1120), Build.south, creep, Q.zero, cm 260, [12])
  , ((m (-3), cm 1100), Build.south, creep, Q.zero, cm 280, [12])
  , ((m (-3), cm 1080), Build.south, creep, Q.zero, cm 300, [12])
  , ((m (-3), cm 1060), Build.south, creep, Q.zero, cm 320, [12])
  , ((m (-3), cm 1040), Build.south, creep, Q.zero, cm 340, [12])
  , ((m (-3), cm 1020), Build.south, creep, Q.zero, cm 360, [12])
  , ((m (-3), cm 1000), Build.south, creep, Q.zero, cm 380, [12]) ]

/-- `permit`'s subject: at a halt on region 12, 32 m short of the junction, letting the turn be
    completed. -/
def haltedSubjectRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  List.replicate 20 ((m (-3), m 40), Build.south, Q.zero, Q.zero, Q.zero, [12])

/-- `branch_1`'s and `branch_4`'s subject: at a halt far up region 12, where it is no hazard to the
    turning car and stands in no other vehicle's way. -/
def farSubjectRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  List.replicate 20 ((m (-3), m 300), Build.south, Q.zero, Q.zero, Q.zero, [12])

/-- `branch_3`'s subject: down region 12 at 2 m/s, its body 14 m short of the junction at the judged
    observation, where the predicted closest approach stays above the minimum clearance. -/
def approachingSubjectRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  [ ((m (-3), m 60), Build.south, mps 2, Q.zero, m 0, [12])
  , ((m (-3), m 58), Build.south, mps 2, Q.zero, m 2, [12])
  , ((m (-3), m 56), Build.south, mps 2, Q.zero, m 4, [12])
  , ((m (-3), m 54), Build.south, mps 2, Q.zero, m 6, [12])
  , ((m (-3), m 52), Build.south, mps 2, Q.zero, m 8, [12])
  , ((m (-3), m 50), Build.south, mps 2, Q.zero, m 10, [12])
  , ((m (-3), m 48), Build.south, mps 2, Q.zero, m 12, [12])
  , ((m (-3), m 46), Build.south, mps 2, Q.zero, m 14, [12])
  , ((m (-3), m 44), Build.south, mps 2, Q.zero, m 16, [12])
  , ((m (-3), m 42), Build.south, mps 2, Q.zero, m 18, [12])
  , ((m (-3), m 40), Build.south, mps 2, Q.zero, m 20, [12])
  , ((m (-3), m 38), Build.south, mps 2, Q.zero, m 22, [12])
  , ((m (-3), m 36), Build.south, mps 2, Q.zero, m 24, [12])
  , ((m (-3), m 34), Build.south, mps 2, Q.zero, m 26, [12])
  , ((m (-3), m 32), Build.south, mps 2, Q.zero, m 28, [12])
  , ((m (-3), m 30), Build.south, mps 2, Q.zero, m 30, [12])
  , ((m (-3), m 28), Build.south, mps 2, Q.zero, m 32, [12])
  , ((m (-3), m 26), Build.south, mps 2, Q.zero, m 34, [12])
  , ((m (-3), m 24), Build.south, mps 2, Q.zero, m 36, [12])
  , ((m (-3), m 22), Build.south, mps 2, Q.zero, m 38, [12]) ]

/-- `idle`'s subject: down region 12 at 6 m/s, alone in the scene. -/
def loneSubjectRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  [ ((m (-3), m 136), Build.south, mps 6, Q.zero, m 0, [12])
  , ((m (-3), m 130), Build.south, mps 6, Q.zero, m 6, [12])
  , ((m (-3), m 124), Build.south, mps 6, Q.zero, m 12, [12])
  , ((m (-3), m 118), Build.south, mps 6, Q.zero, m 18, [12])
  , ((m (-3), m 112), Build.south, mps 6, Q.zero, m 24, [12])
  , ((m (-3), m 106), Build.south, mps 6, Q.zero, m 30, [12])
  , ((m (-3), m 100), Build.south, mps 6, Q.zero, m 36, [12])
  , ((m (-3), m 94), Build.south, mps 6, Q.zero, m 42, [12])
  , ((m (-3), m 88), Build.south, mps 6, Q.zero, m 48, [12])
  , ((m (-3), m 82), Build.south, mps 6, Q.zero, m 54, [12])
  , ((m (-3), m 76), Build.south, mps 6, Q.zero, m 60, [12])
  , ((m (-3), m 70), Build.south, mps 6, Q.zero, m 66, [12])
  , ((m (-3), m 64), Build.south, mps 6, Q.zero, m 72, [12])
  , ((m (-3), m 58), Build.south, mps 6, Q.zero, m 78, [12])
  , ((m (-3), m 52), Build.south, mps 6, Q.zero, m 84, [12])
  , ((m (-3), m 46), Build.south, mps 6, Q.zero, m 90, [12])
  , ((m (-3), m 40), Build.south, mps 6, Q.zero, m 96, [12])
  , ((m (-3), m 34), Build.south, mps 6, Q.zero, m 102, [12])
  , ((m (-3), m 28), Build.south, mps 6, Q.zero, m 108, [12])
  , ((m (-3), m 22), Build.south, mps 6, Q.zero, m 114, [12]) ]

/-- `branch_5`'s subject: up region 14 from the west at 5 m/s — an approach to the same junction
    whose designated direction is not opposed to the turning car's. -/
def westLegSubjectRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  [ ((m (-110), m (-3)), Build.east, mps 5, Q.zero, m 0, [14])
  , ((m (-105), m (-3)), Build.east, mps 5, Q.zero, m 5, [14])
  , ((m (-100), m (-3)), Build.east, mps 5, Q.zero, m 10, [14])
  , ((m (-95), m (-3)), Build.east, mps 5, Q.zero, m 15, [14])
  , ((m (-90), m (-3)), Build.east, mps 5, Q.zero, m 20, [14])
  , ((m (-85), m (-3)), Build.east, mps 5, Q.zero, m 25, [14])
  , ((m (-80), m (-3)), Build.east, mps 5, Q.zero, m 30, [14])
  , ((m (-75), m (-3)), Build.east, mps 5, Q.zero, m 35, [14])
  , ((m (-70), m (-3)), Build.east, mps 5, Q.zero, m 40, [14])
  , ((m (-65), m (-3)), Build.east, mps 5, Q.zero, m 45, [14])
  , ((m (-60), m (-3)), Build.east, mps 5, Q.zero, m 50, [14])
  , ((m (-55), m (-3)), Build.east, mps 5, Q.zero, m 55, [14])
  , ((m (-50), m (-3)), Build.east, mps 5, Q.zero, m 60, [14])
  , ((m (-45), m (-3)), Build.east, mps 5, Q.zero, m 65, [14])
  , ((m (-40), m (-3)), Build.east, mps 5, Q.zero, m 70, [14])
  , ((m (-35), m (-3)), Build.east, mps 5, Q.zero, m 75, [14])
  , ((m (-30), m (-3)), Build.east, mps 5, Q.zero, m 80, [14])
  , ((m (-25), m (-3)), Build.east, mps 5, Q.zero, m 85, [14])
  , ((m (-20), m (-3)), Build.east, mps 5, Q.zero, m 90, [14])
  , ((m (-15), m (-3)), Build.east, mps 5, Q.zero, m 95, [14]) ]

/-- `branch_1`'s third vehicle: down the opposing approach at 14 m/s, its body 12 m short of the
    junction at the judged observation — far nearer than the 70 m its speed covers in the arrival
    time — and in predicted conflict with the turning car as it swings across. -/
def hazardOnApproachRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  [ ((m (-3), m 286), Build.south, mps 14, Q.zero, m 0, [12])
  , ((m (-3), m 272), Build.south, mps 14, Q.zero, m 14, [12])
  , ((m (-3), m 258), Build.south, mps 14, Q.zero, m 28, [12])
  , ((m (-3), m 244), Build.south, mps 14, Q.zero, m 42, [12])
  , ((m (-3), m 230), Build.south, mps 14, Q.zero, m 56, [12])
  , ((m (-3), m 216), Build.south, mps 14, Q.zero, m 70, [12])
  , ((m (-3), m 202), Build.south, mps 14, Q.zero, m 84, [12])
  , ((m (-3), m 188), Build.south, mps 14, Q.zero, m 98, [12])
  , ((m (-3), m 174), Build.south, mps 14, Q.zero, m 112, [12])
  , ((m (-3), m 160), Build.south, mps 14, Q.zero, m 126, [12])
  , ((m (-3), m 146), Build.south, mps 14, Q.zero, m 140, [12])
  , ((m (-3), m 132), Build.south, mps 14, Q.zero, m 154, [12])
  , ((m (-3), m 118), Build.south, mps 14, Q.zero, m 168, [12])
  , ((m (-3), m 104), Build.south, mps 14, Q.zero, m 182, [12])
  , ((m (-3), m 90), Build.south, mps 14, Q.zero, m 196, [12])
  , ((m (-3), m 76), Build.south, mps 14, Q.zero, m 210, [12])
  , ((m (-3), m 62), Build.south, mps 14, Q.zero, m 224, [12])
  , ((m (-3), m 48), Build.south, mps 14, Q.zero, m 238, [12])
  , ((m (-3), m 34), Build.south, mps 14, Q.zero, m 252, [12])
  , ((m (-3), m 20), Build.south, mps 14, Q.zero, m 266, [12]) ]

/-- `branch_4`'s third vehicle: down the opposing approach at 3 m/s and within the junction itself
    from t = 17 s on, where the turning car swings into predicted conflict with it. -/
def hazardWithinJunctionRun : List (Vec × Vec × Q × Q × Q × List RegionId) :=
  [ ((m (-3), m 57), Build.south, mps 3, Q.zero, m 0, [12])
  , ((m (-3), m 54), Build.south, mps 3, Q.zero, m 3, [12])
  , ((m (-3), m 51), Build.south, mps 3, Q.zero, m 6, [12])
  , ((m (-3), m 48), Build.south, mps 3, Q.zero, m 9, [12])
  , ((m (-3), m 45), Build.south, mps 3, Q.zero, m 12, [12])
  , ((m (-3), m 42), Build.south, mps 3, Q.zero, m 15, [12])
  , ((m (-3), m 39), Build.south, mps 3, Q.zero, m 18, [12])
  , ((m (-3), m 36), Build.south, mps 3, Q.zero, m 21, [12])
  , ((m (-3), m 33), Build.south, mps 3, Q.zero, m 24, [12])
  , ((m (-3), m 30), Build.south, mps 3, Q.zero, m 27, [12])
  , ((m (-3), m 27), Build.south, mps 3, Q.zero, m 30, [12])
  , ((m (-3), m 24), Build.south, mps 3, Q.zero, m 33, [12])
  , ((m (-3), m 21), Build.south, mps 3, Q.zero, m 36, [12])
  , ((m (-3), m 18), Build.south, mps 3, Q.zero, m 39, [12])
  , ((m (-3), m 15), Build.south, mps 3, Q.zero, m 42, [12])
  , ((m (-3), m 12), Build.south, mps 3, Q.zero, m 45, [12])
  , ((m (-3), m 9), Build.south, mps 3, Q.zero, m 48, [12])
  , ((m (-3), m 6), Build.south, mps 3, Q.zero, m 51, [3, 12])
  , ((m (-3), m 3), Build.south, mps 3, Q.zero, m 54, [3])
  , ((m (-3), m 0), Build.south, mps 3, Q.zero, m 57, [3]) ]

-- ---------------------------------------------------------------------------------------------
-- The traces
-- ---------------------------------------------------------------------------------------------
/-- `forbid` (violated): A car within the crossroads is turning left, its signed heading change over the window behind to the left; through that window no vehicle was within the junction, and none was on the opposing approach closer to it than the ground it covers in the arrival time, and the turning car signalled left continuously over the distance NRS_484B_413_2 requires. The subject approaches on the opposing segment, whose designated direction is the reverse of the turner's approach, at a creep and standing further from the junction than the ground its own speed covers in the arrival time - so the subject is itself no immediate hazard to the turner and the turner's yield stands - while the turning car swings across the junction at speed: under the two velocities observed the centres approach within the conflict horizon to below the minimum clearance. -/
def forbidTrace : Trace :=
  runOf (fun k => [turnerAt true k, carAt 1 .off .noSignal creepingSubjectRun k]) turnerIntent

/-- `permit` (compliant): The same turning car, the same yield and the same signal, but the subject stands at a halt on its approach and lets the turn be completed: under the velocities observed the centres do not approach within the conflict horizon at all. -/
def permitTrace : Trace :=
  runOf (fun k => [turnerAt true k, carAt 1 .off .noSignal haltedSubjectRun k]) turnerIntent

/-- `idle` (not_applicable): The subject approaches the crossroads on its own, with no other road user in the scene, so no vehicle is making a left turn within the junction and the duty does not arise; the verdict is decided with the subject alone. -/
def idleTrace : Trace :=
  runOf (fun k => [carAt 1 .off .noSignal loneSubjectRun k]) []

/-- `blind` (unknown): the `forbid` scene, but the source declares no footprint overlap for any
    region and records no entrance relation: neither the turner's place in the junction nor either
    vehicle's approach carrier can be decided, and the rule reports unknown for those two atoms. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): The same turning car, but through the window behind a third car was on the opposing approach nearer to the junction than the ground its speed covers in the arrival time, and the turner swung across it with a predicted centre closest approach below the minimum clearance: the turner has not so yielded, so the duty this clause lays on other vehicles does not arise. -/
def branch_1Trace : Trace :=
  runOf (fun k => [turnerAt true k, carAt 1 .off .noSignal farSubjectRun k,
                   carAt 3 .off .noSignal hazardOnApproachRun k]) turnerIntent

/-- `branch_2` (not_applicable): The same turning car, which yielded, but it gave no signal at all, by lamp or by arm, over the distance NRS_484B_413_2 requires, so that node is not complied with for it and the duty this clause lays on other vehicles does not arise. -/
def branch_2Trace : Trace :=
  runOf (fun k => [turnerAt false k, carAt 1 .off .noSignal creepingSubjectRun k]) turnerIntent

/-- `branch_3` (compliant): The same yielding, signalling turner within the junction, but the subject is further up its approach, so that under the velocities observed the two centres do approach within the conflict horizon yet their distance at the closest approach stays above the minimum clearance: the subject has granted precedence. This visits the compliant side of the clearance comparison, which the permit scenario (no approach within the horizon at all) does not reach. -/
def branch_3Trace : Trace :=
  runOf (fun k => [turnerAt true k, carAt 1 .off .noSignal approachingSubjectRun k]) turnerIntent

/-- `branch_4` (not_applicable): the same turning, signalling car, but a third vehicle was within
    the junction itself, and the turner swung into predicted conflict with it: the turner has not so
    yielded, by the limb of the yield that needs no direction, and the duty does not arise. -/
def branch_4Trace : Trace :=
  runOf (fun k => [turnerAt true k, carAt 1 .off .noSignal farSubjectRun k,
                   carAt 3 .off .noSignal hazardWithinJunctionRun k]) turnerIntent

/-- `branch_5` (not_applicable): the same yielding, signalling turner within the junction, but the
    subject approaches the same junction up the west leg, on a carrier whose designated direction is
    not opposed to the turner's approach: this clause lays no duty on it. -/
def branch_5Trace : Trace :=
  runOf (fun k => [turnerAt true k, carAt 1 .off .noSignal westLegSubjectRun k]) turnerIntent

/-- `branch_6` (compliant): two cars turn left in convoy within the junction, both signalling. The
    leading one (track 2) yielded: neither the third car coming down the opposing approach nor the
    car behind it is in predicted conflict with it, and the subject, creeping up the opposing
    approach, is not either - so the duty towards it is owed and granted. The car behind (track 4)
    swung across the third car with a predicted centre closest approach below the minimum clearance:
    it has not so yielded, so no duty is owed towards it, although under the velocities observed the
    subject's centre and its own do approach within the conflict horizon to below the clearance.
    This is where the yield the obligation re-states does its work: were that third car no immediate
    hazard, or the conflict with it no conflict, the duty towards the car behind would arise too and
    the subject would stand in breach of it. -/
def branch_6Trace : Trace :=
  runOf (fun k => [signallingAt 2 leadTurnerRun true k,
                   carAt 1 .off .noSignal creepingSubjectRun k,
                   carAt 3 .off .noSignal hazardAheadRun k,
                   signallingAt 4 turnerRun true k]) bothTurnersIntent

def witness (name : String) (τ : Trace) (expected : Verdict) (fromMs toMs : Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (fromMs, toMs)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 19000 19000
  , witness "permit" permitTrace .compliant 19000 19000
  , witness "idle" idleTrace .notApplicable 0 19000
  , witness "blind" blindTrace (.unknown []) 19000 19000 ["rel.occupies", "st.lane_enters"]
  , witness "branch_1" branch_1Trace .notApplicable 19000 19000
  , witness "branch_2" branch_2Trace .notApplicable 19000 19000
  , witness "branch_3" branch_3Trace .compliant 19000 19000
  , witness "branch_4" branch_4Trace .notApplicable 19000 19000
  , witness "branch_5" branch_5Trace .notApplicable 19000 19000
  , witness "branch_6" branch_6Trace .compliant 19000 19000 ]

end TrafficSpecWitness.NRS_484B_253_o2
