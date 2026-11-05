/-
  Witnesses for NRS_484B_250_1.

  One scene is built for every witness: a four-way junction of two public ways. The junction
  (region 1) is the 20 m square from (−10, −10) to (10, 10) and lies on both ways. The east–west
  highway is region 10 (the strip |y| ≤ 10 from x = −120 to x = 120) and the north–south highway
  region 11 (the strip |x| ≤ 10 from y = −120 to y = 120). Three approach carriers run into the
  junction: the eastbound lane (region 2, x ∈ [−120, −10], y ∈ [−6, 0], direction east, on way
  10), the northbound lane (region 3, x ∈ [0, 6], y ∈ [−120, −10], direction north, on way 11)
  and the westbound lane (region 4, x ∈ [10, 120], y ∈ [0, 6], direction west, on way 10).

  Track 1 is the subject, a motor vehicle 5 m long and 1.8 m wide, driving east along y = −3 at
  6 m/s: at t = 11 s its body lies from x = −18.5 m to x = −13.5 m, wholly in the eastbound lane,
  and one second later it reaches x = −10 m, where its footprint begins to overlap the junction.
  Track 2 is a van that comes north through the junction at 2 m/s, its footprint overlapping the
  junction from t = 9 s. Track 3, where a witness needs it, is a second vehicle on the westbound
  carrier, whose designated direction is opposed to the subject's.

  Every trace is 17 observations one second apart, t = 0 … 16 000 ms, and every witness is judged
  at t = 11 s alone (`window`): there the subject is still approaching the junction, the ten
  seconds of history a manoeuvre window needs are recorded, and the three seconds ahead in which
  the entry is read are recorded too. Occupancy is stated scene by scene, since a body spans two
  regions as it crosses from a carrier into the junction.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A length in decimetres, for the arc of a turning vehicle. -/
def dm (n : Int) : Q := Units.centimetres (10 * n)
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def junctionId : RegionId := 1
def eastId : RegionId := 2
def northId : RegionId := 3
def westId : RegionId := 4
def wideId : RegionId := 5
def ewWayId : RegionId := 10
def nsWayId : RegionId := 11

/-- Half-length, half-width, half-height of a passenger car or van (m). -/
def carBody : Q × Q × Q := (cm 250, cm 90, cm 75)

/-- A directed approach carrier: a rectangle with a designated direction, an entrance end at the
    junction, and the public way it lies on. -/
def carrier (id : RegionId) (x0 y0 x1 y1 : Int) (dir : Vec) (way : RegionId) : Structure :=
  { Build.lane id [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)] dir
      (enters := some junctionId) with ways := some [way] }

/-- The same, written as a roadway rather than a lane. -/
def roadwayCarrier (id : RegionId) (x0 y0 x1 y1 : Int) (dir : Vec) (way : RegionId) : Structure :=
  { carrier id x0 y0 x1 y1 dir way with kind := .roadway }

def junction : Structure :=
  { Build.rect junctionId .intersection (m (-10)) (m (-10)) (m 10) (m 10) with
    ways := some [ewWayId, nsWayId] }

def eastLane : Structure := carrier eastId (-120) (-6) (-10) 0 Build.east ewWayId
def northLane : Structure := carrier northId 0 (-120) 6 (-10) Build.north nsWayId
def westLane : Structure := carrier westId 10 0 120 6 Build.west ewWayId
def ewHighway : Structure := Build.rect ewWayId .highway (m (-120)) (m (-10)) (m 120) (m 10)
def nsHighway : Structure := Build.rect nsWayId .highway (m (-10)) (m (-120)) (m 10) (m 120)

def baseStructures : List Structure :=
  [junction, eastLane, northLane, westLane, ewHighway, nsHighway]

/-- A road user with its place, heading, speed and rate of turn. -/
def vehicle (track : TrackId) (classes : List RoadUserClass) (pos : Vec) (hdg : Vec) (speed : Q)
    (yaw : Q := Q.zero) : RoadUser :=
  Build.withKin (Build.user track classes pos hdg speed carBody)
    (fun k => { k with yawRate := some yaw })

-- ---------------------------------------------------------------------------------------------
-- The subject: east along the eastbound lane at 6 m/s, entering the junction at t = 12 s.
-- ---------------------------------------------------------------------------------------------
def subjectAt (k : Nat) (classes : List RoadUserClass := [.motorVehicle]) : RoadUser :=
  vehicle 1 classes (m (6 * (k : Int) - 82), m (-3)) Build.east (mps 6)

def subjectOcc (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 11 then [(1, eastId)]
  else if k = 12 then [(1, eastId), (1, junctionId)]
  else if k ≤ 15 then [(1, junctionId)]
  else []

-- ---------------------------------------------------------------------------------------------
-- The van from the crossing highway: north at 2 m/s, in the junction from t = 9 s.
-- ---------------------------------------------------------------------------------------------
def vanAt (k : Nat) (classes : List RoadUserClass := [.motorVehicle]) : RoadUser :=
  vehicle 2 classes (m 3, m (2 * (k : Int) - 30)) Build.north (mps 2)

def vanOcc (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 8 then [(2, northId)]
  else if k ≤ 11 then [(2, northId), (2, junctionId)]
  else [(2, junctionId)]

/-- The van of `branch_3`, which is away north at 12 m/s from t = 11 s. -/
def fastVanAt (k : Nat) : RoadUser :=
  if k ≤ 10 then vanAt k
  else vehicle 2 [.motorVehicle] (m 3, m (12 * (k : Int) - 140)) Build.north (mps 12)

def fastVanOcc (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 8 then [(2, northId)]
  else if k ≤ 11 then [(2, northId), (2, junctionId)]
  else if k = 12 then [(2, junctionId)]
  else []

/-- The van of `branch_16`, which enters the junction at t = 11 s at 6 m/s and is well clear of
    the subject's path by the time the subject reaches it. -/
def briskVanAt (k : Nat) : RoadUser :=
  vehicle 2 [.motorVehicle] (m 3, m (6 * (k : Int) - 78)) Build.north (mps 6)

def briskVanOcc (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 10 then [(2, northId)]
  else if k = 11 then [(2, northId), (2, junctionId)]
  else if k ≤ 15 then [(2, junctionId)]
  else []

/-- The van of `branch_1`: it entered the junction from the same east–west highway the subject's
    lane lies on, ahead of the subject, and comes west at 2 m/s. -/
def westVanAt (k : Nat) : RoadUser :=
  vehicle 2 [.motorVehicle] (m (30 - 2 * (k : Int)), m 1) Build.west (mps 2)

def westVanOcc (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 8 then [(2, westId)]
  else if k ≤ 11 then [(2, westId), (2, junctionId)]
  else [(2, junctionId)]

/-- A second vehicle approaching the junction through the westbound carrier, whose designated
    direction is opposed to the subject's: west at 2 m/s, never reaching the junction. -/
def opposedAt (k : Nat) : RoadUser :=
  vehicle 3 [.motorVehicle] (m (60 - 2 * (k : Int)), m 3) Build.west (mps 2)

def opposedOcc (k : Nat) : List (TrackId × RegionId) := [(3, westId)]

-- ---------------------------------------------------------------------------------------------
-- A left turn under way: an arc of radius 9.5 m at 1 m/s and 6 °/s, so that the heading swings
-- 6° to the left each second and the course change over any ten seconds of it is 60°. The arc is
-- given as the distance run along the initial heading and the offset to its left (decimetres),
-- with the heading at each second as a direction vector (hundredths).
-- ---------------------------------------------------------------------------------------------
def arcAlong : List Int := [0, 10, 20, 30, 39, 48, 56, 64, 71, 77, 83, 87, 91, 93, 95, 95, 95]
def arcLeft : List Int := [0, 1, 2, 5, 8, 13, 18, 25, 32, 39, 48, 57, 66, 76, 86, 95, 105]
def arcHeading : List (Int × Int) :=
  [(100, 0), (99, 10), (98, 21), (95, 31), (91, 41), (87, 50), (81, 59), (74, 67), (67, 74),
   (59, 81), (50, 87), (41, 91), (31, 95), (21, 98), (10, 99), (0, 100), (-10, 99)]

def alongAt (k : Nat) : Int := (arcAlong[k]?).getD 95
def leftAt (k : Nat) : Int := (arcLeft[k]?).getD 105
def headAt (k : Nat) : Int × Int := (arcHeading[k]?).getD (-10, 99)
def yawOfTurn : Q := Units.degrees 6

/-- The vehicle of `branch_4`: westbound on the wide westbound approach (region 5), turning left
    (to the south) throughout, its place following the arc and its heading the turn its rate of
    turn makes over each second. -/
def turnerAt (k : Nat) : RoadUser :=
  vehicle 3 [.motorVehicle] (dm (400 - alongAt k), dm (40 - leftAt k))
    (Q.ofInt (- (headAt k).1), Q.ofInt (- (headAt k).2)) (mps 1) yawOfTurn

def turnerOcc (_k : Nat) : List (TrackId × RegionId) := [(3, wideId)]

/-- The wide westbound approach the turning vehicle of `branch_4` runs on: a roadway recorded as
    a directed approach segment of the east–west highway. -/
def wideWest : Structure := roadwayCarrier wideId 12 (-14) 120 6 Build.west ewWayId

/-- The wide eastbound approach the subject of `branch_10` runs on while it turns to the left. -/
def wideEast : Structure := roadwayCarrier eastId (-120) (-10) (-10) 8 Build.east ewWayId

/-- The subject of `branch_10`: eastbound on the wide eastbound approach, turning left at 6 °/s
    and 1 m/s, never reaching the junction. -/
def turningSubjectAt (k : Nat) : RoadUser :=
  vehicle 1 [.motorVehicle] (dm (-400 + alongAt k), dm (-40 + leftAt k))
    (Q.ofInt (headAt k).1, Q.ofInt (headAt k).2) (mps 1) yawOfTurn

def turningSubjectOcc (_k : Nat) : List (TrackId × RegionId) := [(1, eastId)]

-- ---------------------------------------------------------------------------------------------
-- The traces
-- ---------------------------------------------------------------------------------------------
/-- Seventeen observations a second apart, from the scene at each. -/
def run (f : Nat → Timestamp → Scene) : Trace := Build.trace 17 0 (Units.seconds 1) f

def plainScene (users : Nat → List RoadUser) (occ : Nat → List (TrackId × RegionId))
    (sts : List Structure := baseStructures) (devs : List Device := [])
    (ints : Nat → List DeclaredIntent := fun _ => []) : Trace :=
  run fun k t => Build.scene t (some 1) (users k) sts devs (occupies := some (occ k))
    (intents := ints k)

/-- `forbid` (violated): The subject approaches an uncontrolled four-way junction along a lane of the east–west highway; no device governs the junction or that lane. A van entered the junction two seconds earlier from a lane of the north–south highway and its footprint still overlaps the junction. The subject's footprint begins to overlap the junction while the two velocities bring their centres within 2 m inside 2 s. -/
def forbidTrace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k]) (fun k => subjectOcc k ++ vanOcc k)

/-- `permit` (compliant): The subject approaches the same uncontrolled junction and enters it; no other road user of any kind is in the scene, so no vehicle occupies the junction. -/
def permitTrace : Trace :=
  plainScene (fun k => [subjectAt k]) subjectOcc

/-- `idle` (not_applicable): The subject approaches a junction that a signal head governs — dev.governs names the junction region — and a van that entered from the crossing highway occupies it. -/
def idleTrace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k]) (fun k => subjectOcc k ++ vanOcc k)
    baseStructures [Build.signal 1 [junctionId] [.circularGreen]]

/-- `blind` (unknown): A van occupies a junction region and the subject is on a roadway beside it, closing fast; the source declares st.lane_enters absent, so neither which junction the subject's carrier enters nor the highway the van entered from can be read. -/
def blindTrace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k]) (fun k => subjectOcc k ++ vanOcc k)
    [junction, roadwayCarrier eastId (-120) (-6) (-10) 0 Build.east ewWayId, northLane, westLane,
     ewHighway, nsHighway]

/-- `branch_1` (compliant): As in forbid, except that the van occupying the junction entered it from the same east–west highway the subject's lane lies on, ahead of the subject; the subject enters the junction with the same closing geometry. -/
def branch_1Trace : Trace :=
  plainScene (fun k => [subjectAt k, westVanAt k]) (fun k => subjectOcc k ++ westVanOcc k)

/-- `branch_2` (not_applicable): The subject and another vehicle approach the uncontrolled junction through carriers whose designated directions are opposed, and the source declares int.left_turn for the subject at that junction; a third vehicle occupies the junction having entered from the crossing highway. -/
def branch_2Trace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k, opposedAt k])
    (fun k => subjectOcc k ++ vanOcc k ++ opposedOcc k) baseStructures []
    (fun _ => [{ vehicle := 1, target := junctionId, values := [("int.left_turn", true)] }])

/-- `branch_3` (compliant): As in forbid, except that the van that entered from the crossing highway is leaving at 12 m/s on a diverging path: under the velocities observed, the centres never come within the clearance inside the horizon. The subject enters the junction. -/
def branch_3Trace : Trace :=
  plainScene (fun k => [subjectAt k, fastVanAt k]) (fun k => subjectOcc k ++ fastVanOcc k)

/-- `branch_4` (not_applicable): The ground of s9 rather than s8: the subject approaches the uncontrolled junction and another vehicle approaches it through a carrier whose designated direction is opposed to the subject's, no left turn is declared for either, and that other vehicle is making a left turn — through the whole window behind each judged observation its heading swings steadily to the left, each scene's heading being the previous scene's heading advanced by the turn its yaw rate makes over the interval, its position following the curving path at a speed above the motion tolerance, so that the heading change over p.turn_window lies between p.turn_min_course_change and p.turn_max_course_change. The vehicle still occupies the opposed approach carrier throughout. A van that entered from the crossing highway occupies the junction, so the duty would otherwise be owed. -/
def branch_4Trace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k, turnerAt k])
    (fun k => subjectOcc k ++ vanOcc k ++ turnerOcc k) (baseStructures ++ [wideWest])

/-- `branch_5` (not_applicable): as in forbid, except that a stop sign governs the subject's
    approach lane: the junction is controlled by an official traffic-control device. -/
def branch_5Trace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k]) (fun k => subjectOcc k ++ vanOcc k)
    baseStructures [Build.sign 1 .stopSign [eastId]]

/-- `branch_6` (not_applicable): as in forbid, except that a yield sign governs the junction. -/
def branch_6Trace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k]) (fun k => subjectOcc k ++ vanOcc k)
    baseStructures [Build.sign 1 .yieldSign [junctionId]]

/-- `branch_7` (not_applicable): as in forbid, except that a regulatory sign whose legend states
    no restriction of hours or class governs the subject's approach lane. -/
def branch_7Trace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k]) (fun k => subjectOcc k ++ vanOcc k)
    baseStructures
    [{ Build.sign 1 .regulatorySign [eastId] with code := some .noLeftTurn, conditions := some {} }]

/-- `branch_8` (not_applicable): as in forbid, except that an overhead lane-control signal
    governs the subject's approach lane. -/
def branch_8Trace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k]) (fun k => subjectOcc k ++ vanOcc k)
    baseStructures
    [{ Build.device 1 .laneControlSignal [eastId] with laneControl := some .greenDownArrow }]

/-- `branch_9` (not_applicable): as in branch_2, except that the declared left turn is the other
    vehicle's: the exception reads either of the two. -/
def branch_9Trace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k, opposedAt k])
    (fun k => subjectOcc k ++ vanOcc k ++ opposedOcc k) baseStructures []
    (fun _ => [{ vehicle := 3, target := junctionId, values := [("int.left_turn", true)] }])

/-- `branch_10` (not_applicable): the subject itself is making the left turn, on a wide eastbound
    approach, while another vehicle approaches the junction through the opposed carrier; a van
    that entered from the crossing highway occupies the junction. -/
def branch_10Trace : Trace :=
  plainScene (fun k => [turningSubjectAt k, vanAt k, opposedAt k])
    (fun k => turningSubjectOcc k ++ vanOcc k ++ opposedOcc k)
    [junction, wideEast, northLane, westLane, ewHighway, nsHighway]

/-- `branch_11` (compliant): the van that entered from the crossing highway is on a closing
    course, but the subject creeps at 1 m/s and its footprint does not reach the junction at any
    observation of the window ahead: it makes no entry while the conflict is predicted. -/
def branch_11Trace : Trace :=
  plainScene
    (fun k => [vehicle 1 [.motorVehicle] (m ((k : Int) - 30), m (-3)) Build.east (mps 1), vanAt k])
    (fun k => [(1, eastId)] ++ vanOcc k)

/-- `branch_12` (compliant): what occupies the junction, having come from the crossing highway on
    a closing course, is a bicycle, which the admitted aggregate DEF-NRS-484A-320::vehicle leaves
    out: no vehicle is owed precedence. -/
def branch_12Trace : Trace :=
  plainScene (fun k => [subjectAt k, vanAt k [.bicycle]]) (fun k => subjectOcc k ++ vanOcc k)

/-- `branch_13` (not_applicable): the subject is no longer approaching the junction — its own
    footprint overlaps it — while the van from the crossing highway occupies it. -/
def branch_13Trace : Trace :=
  plainScene
    (fun k => [vehicle 1 [.motorVehicle] (m (6 * (k : Int) - 70), m (-3)) Build.east (mps 6), vanAt k])
    (fun k =>
      (if k ≤ 9 then [(1, eastId)]
       else if k = 10 then [(1, eastId), (1, junctionId)]
       else if k ≤ 13 then [(1, junctionId)]
       else []) ++ vanOcc k)

/-- `branch_14` (not_applicable): the same approach and the same van, with a bicycle as the
    subject: the admitted aggregate leaves it out and the section is not engaged. -/
def branch_14Trace : Trace :=
  plainScene (fun k => [subjectAt k [.bicycle], vanAt k]) (fun k => subjectOcc k ++ vanOcc k)

/-- `branch_15` (not_applicable): the subject stands still short of the junction — its velocity
    is the zero vector — while the van from the crossing highway occupies it. -/
def branch_15Trace : Trace :=
  plainScene
    (fun k => [vehicle 1 [.motorVehicle] (m (-16), m (-3)) Build.east (mps 0), vanAt k])
    (fun k => [(1, eastId)] ++ vanOcc k)

/-- `branch_16` (compliant): the van entered the junction from the crossing highway and the two
    centres do approach within the horizon, but it is away north at 6 m/s and the centre distance
    at the closest approach stays above the clearance. The subject enters the junction. -/
def branch_16Trace : Trace :=
  plainScene (fun k => [subjectAt k, briskVanAt k]) (fun k => subjectOcc k ++ briskVanOcc k)

/-- The instant every witness speaks about: the subject still approaches the junction there, and
    the window ahead in which its entry is read is recorded. -/
def judged : Timestamp × Timestamp := (11000, 11000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_enters"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .notApplicable
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .notApplicable
  , witness "branch_14" branch_14Trace .notApplicable
  , witness "branch_15" branch_15Trace .notApplicable
  , witness "branch_16" branch_16Trace .compliant ]

end TrafficSpecWitness.NRS_484B_250_1
