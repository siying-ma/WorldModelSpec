/-
  Witnesses for NRS_484B_257_1_o1.

  One crossroads in every scene. The subject's way runs east-west (highway region 1, the breadth
  y ∈ [-6, 6]), the way it meets runs north-south (highway region 10); the junction is the
  rectangle x ∈ [0, 12], y ∈ [-6, 6] (region 3), which lies on both ways. Occupancy is the overlap
  of the body's footprint with a region, so the body is on its approach until its nose reaches
  x = 0 and within the junction from there on. The approach the
  subject comes in on is, as the scene requires, a lane (region 2, y ∈ [-3, 3], running into the
  junction and through it), a designated left-turn lane (region 7, y ∈ [-6, -3]) or the roadway
  (region 6, the whole carriageway); each lies on way 1. A stop line crosses the approach at
  x ∈ [-4, -3.8] (region 4; region 12 is the one across the turn lane, region 9 the opposing
  approach's beyond the junction, region 11 one a kilometre past it), and a near-side crosswalk at
  x ∈ [-3.2, -0.2] (region 5).

  The subject (track 1, a passenger car 4 m long and 1.8 m wide, heading east) is the only road
  user of every scene. It comes from 58 m west of the junction and is observed every 1.5 s, so the
  observations are 12 m of path apart at 8 m/s: the stretch of path the rule looks back over is
  covered at the instant the body enters the junction, and the gaps are short enough for the
  crossing look-back too. The view along the intersecting way is 80 m from every place.

  Every figure here is the witness's own and appears nowhere in the rule; the geometry is built to
  break or keep each bound of the run's reading by a clear margin (p.halt_speed_tolerance 0.2 m/s,
  p.yield_approach_speed 4 m/s, p.stop_place_tolerance 1.5 m, p.junction_approach_reach 10 m,
  p.intersection_edge_tolerance 2 m, p.intersection_view_distance 60 m,
  p.stop_approach_lookback 60 m, p.crossing_entry_lookback 25 m).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

/-- The spacing of the observations. -/
def dt : Q := Units.ratio 3 2

-- ---------------------------------------------------------------------------------------------
-- The ground
-- ---------------------------------------------------------------------------------------------

/-- The subject's way, east-west, between its boundary lines: the whole breadth of the public way
    the approach, the junction, the lines and the crossing lie on. -/
def wayEW : Structure := Build.rect 1 .highway (m (-200)) (m (-6)) (m 1100) (m 6)
/-- The way it meets, north-south. -/
def wayNS : Structure := Build.rect 10 .highway (m 0) (m (-200)) (m 12) (m 200)

/-- The junction, on both ways. -/
def inter : Structure :=
  { Build.rect 3 .intersection (m 0) (m (-6)) (m 12) (m 6) with ways := some [1, 10] }

/-- The approach lane, running into the junction and on through it. -/
def appLane : Structure :=
  { Build.lane 2 [(m (-200), m (-3)), (m 12, m (-3)), (m 12, m 3), (m (-200), m 3)]
      Build.east (enters := some 3) with ways := some [1] }

/-- The same lane, ending at the junction's edge: a body within the junction is on it no longer. -/
def appLaneShort : Structure :=
  { Build.lane 2 [(m (-200), m (-3)), (m 0, m (-3)), (m 0, m 3), (m (-200), m 3)]
      Build.east (enters := some 3) with ways := some [1] }

/-- The stop line across the approach, 3.8 m short of the junction. -/
def stopLineR : Structure :=
  { Build.rect 4 .stopLine (m (-4)) (m (-3)) (cm (-380)) (m 3) with ways := some [1] }

/-- The near-side crosswalk, between the line and the junction. -/
def crossWalkR : Structure :=
  { Build.rect 5 .crosswalk (cm (-320)) (m (-6)) (cm (-20)) (m 6) with
      ways := some [1], marked := some true }

/-- The carriageway, from well west of the junction through it and beyond. -/
def roadwayR : Structure :=
  { Build.rect 6 .roadway (m (-200)) (m (-6)) (m 200) (m 6) with ways := some [1] }

/-- A designated left-turn lane, south of the through lane, running into the junction. -/
def turnLaneR : Structure :=
  { Build.rect 7 .turnLane (m (-200)) (m (-6)) (m 12) (m (-3)) with
      lane := some { direction := some Build.east, entersIntersection := some 3 }
      ways := some [1] }

/-- The stop line across that turn lane. -/
def turnLine : Structure :=
  { Build.rect 12 .stopLine (m (-4)) (m (-6)) (cm (-380)) (m (-3)) with ways := some [1] }

/-- The opposing approach's lane, east of the junction and reaching a little into it. -/
def oppLane : Structure :=
  { Build.lane 8 [(m 8, m (-3)), (m 200, m (-3)), (m 200, m 3), (m 8, m 3)]
      Build.west (enters := some 3) with ways := some [1] }

/-- The opposing approach's stop line, beyond the junction. -/
def oppLine : Structure :=
  { Build.rect 9 .stopLine (cm 1220) (m (-3)) (cm 1240) (m 3) with ways := some [1] }

/-- A stop line of another junction, a kilometre along the same way. -/
def farLine : Structure :=
  { Build.rect 11 .stopLine (m 1000) (m (-3)) (cm 100020) (m 3) with ways := some [1] }

/-- The carriageway beyond the junction, which the subject is never upon. -/
def oppRoadway : Structure :=
  { Build.rect 13 .roadway (m 12) (m (-6)) (m 200) (m 6) with ways := some [1] }

def ground : List Structure := [wayEW, wayNS, inter]

-- ---------------------------------------------------------------------------------------------
-- The devices
-- ---------------------------------------------------------------------------------------------

def stopSign (rs : List RegionId) : Device := Build.sign 1 .stopSign rs
def yieldSign (rs : List RegionId) : Device := Build.sign 2 .yieldSign rs
/-- A signal head displaying a circular green, uncovered and working. -/
def greenHead (rs : List RegionId) : Device :=
  { Build.signal 3 rs [.circularGreen] with uncovered := some true, inoperative := some false }
/-- A head installed and uncovered but showing no valid indication. -/
def darkHead (rs : List RegionId) : Device :=
  { Build.signal 3 rs [.dark] with uncovered := some true, inoperative := some true }
/-- A person directing traffic, of the role police officer. -/
def officer (rs : List RegionId) : Device :=
  { Build.device 4 .humanDirection rs with
      humanRole := some .policeOfficer, humanIndication := some .proceed }

-- ---------------------------------------------------------------------------------------------
-- The bodies and the instants
-- ---------------------------------------------------------------------------------------------

/-- The subject at a place on the ground: position, speed and the path it has travelled, with the
    view the place affords along each way. -/
def car (x y speed path : Q) : RoadUser :=
  { Build.user 1 [.motorVehicle] (x, y) Build.east speed (m 2, cm 90, cm 75) (some path) with
      sightAlongWay := some [(1, m 300), (10, m 80)] }

def sceneAt (steps : List (Q × Q × Q)) (y : Q) (ss : List Structure) (ds : List Device)
    (k : Nat) (t : Timestamp) : Scene :=
  let s := steps[k]?.getD (Q.zero, Q.zero, Q.zero)
  Build.scene t (some 1) [car s.1 y s.2.1 s.2.2] ss ds

/-- A trace from the subject's motion (x, speed, path at each observation). -/
def traceOf (steps : List (Q × Q × Q)) (ss : List Structure) (ds : List Device)
    (y : Q := Q.zero) : Trace :=
  Build.trace steps.length 0 dt (sceneAt steps y ss ds)

/-- Four observations closing on the junction at 8 m/s, 12 m of path apart. -/
def approach8 : List (Q × Q × Q) :=
  [ (m (-58), mps 8, m 0)
  , (m (-46), mps 8, m 12)
  , (m (-34), mps 8, m 24)
  , (m (-22), mps 8, m 36) ]

/-- Straight through the junction at 8 m/s, never halting. -/
def run8 : List (Q × Q × Q) :=
  approach8 ++ [ (m (-10), mps 8, m 48), (m 2, mps 8, m 60) ]

/-- To rest at the stop line (the body's front 0.5 m short of it, 4.5 m short of the junction),
    standing for one observation, then into the junction. -/
def haltAtLine : List (Q × Q × Q) :=
  approach8 ++ [ (cm (-650), mps 0, cm 5150), (cm (-650), mps 0, cm 5150), (m 2, mps 8, m 60) ]

/-- Past the stop line at 2 m/s without coming to rest, then into the junction. -/
def slowAtLine : List (Q × Q × Q) :=
  approach8 ++ [ (cm (-650), mps 2, cm 5150), (m 2, mps 8, m 60) ]

/-- To rest at the stop line, and no further: the body never reaches the junction. -/
def haltShortOfJunction : List (Q × Q × Q) :=
  approach8 ++ [ (cm (-650), mps 0, cm 5150), (cm (-650), mps 0, cm 5150) ]

/-- To rest with the body a metre from the junction, then into it. -/
def haltNearEdge : List (Q × Q × Q) :=
  approach8 ++ [ (m (-10), mps 8, m 48), (m (-3), mps 0, m 55), (m (-3), mps 0, m 55)
               , (m 4, mps 8, m 62) ]

/-- To rest upon the stop line (ground distance nil, the junction three metres off), then into it. -/
def haltOnLine : List (Q × Q × Q) :=
  approach8 ++ [ (m (-10), mps 8, m 48), (m (-5), mps 0, m 53), (m (-5), mps 0, m 53)
               , (m 4, mps 8, m 62) ]

/-- Through the line at 8 m/s and to rest only within the junction, the front at the opposing
    line, then out. -/
def haltInJunction : List (Q × Q × Q) :=
  approach8 ++ [ (m (-10), mps 8, m 48), (m 10, mps 0, m 68), (m 10, mps 0, m 68)
               , (m 16, mps 8, m 74) ]

/-- To rest half a metre short of the near-side crosswalk, then across it and into the junction. -/
def haltAtCrossing : List (Q × Q × Q) :=
  [ (m (-56), mps 8, m 0)
  , (m (-44), mps 8, m 12)
  , (m (-32), mps 8, m 24)
  , (m (-20), mps 8, m 36)
  , (m (-10), mps 8, m 46)
  , (cm (-570), mps 0, cm 5030)
  , (cm (-570), mps 0, cm 5030)
  , (m 4, mps 8, m 60) ]

/-- Straight through at 6 m/s, 9 m of path apart, to a place within the junction at which the body
    has left the approach behind it altogether. -/
def run6 : List (Q × Q × Q) :=
  [ (m (-60), mps 6, m 0)
  , (m (-51), mps 6, m 9)
  , (m (-42), mps 6, m 18)
  , (m (-33), mps 6, m 27)
  , (m (-24), mps 6, m 36)
  , (m (-15), mps 6, m 45)
  , (m (-6), mps 6, m 54)
  , (m 3, mps 6, m 63) ]

/-- Straight through at 5 m/s, 7.5 m of path apart. -/
def run5 : List (Q × Q × Q) :=
  [ (m (-58), mps 5, m 0)
  , (cm (-5050), mps 5, cm 750)
  , (m (-43), mps 5, m 15)
  , (cm (-3550), mps 5, cm 2250)
  , (m (-28), mps 5, m 30)
  , (cm (-2050), mps 5, cm 3750)
  , (m (-13), mps 5, m 45)
  , (cm (-550), mps 5, cm 5250)
  , (m 2, mps 5, m 60) ]

-- Binders ↦ tracks: v ↦ 1

/-- `forbid` (violated): A stop sign governs the lane the subject occupies, which runs into an intersection; a stop line crosses that approach a few metres before the junction, its boundary carried; no officer and no signal head governs that lane, the junction or any region the subject is upon. The subject runs at 8 m/s throughout and its speed never falls within the halt tolerance anywhere in the stretch of path behind, then its footprint comes to overlap the intersection. No stop was made at the line. -/
def forbidTrace : Trace :=
  traceOf run8 (ground ++ [appLane, stopLineR]) [stopSign [2]]

/-- `permit` (compliant): The same stop-signed approach and stop line, with no other road user in the scene. The subject's speed falls to zero while its footprint overlaps no intersection region, with the ground distance from its body to the stop line within the placement tolerance and to the intersection region within the entrance reach; it stands there for an observation and then enters. The required halt is found at the line of this junction, before entering it. -/
def permitTrace : Trace :=
  traceOf haltAtLine (ground ++ [appLane, stopLineR]) [stopSign [2]]

/-- `idle` (not_applicable): The same stop-signed approach and stop line, but a signal head displays a circular green, is not inoperative, and governs the roadway the subject's footprint overlaps throughout - neither the approach lane nor the intersection region. The subject passes the line at 8 m/s without halting. The head controls the traffic of the region the subject is upon, which dev.governs admits as readily as a lane, so traffic is being controlled by a traffic-control signal and the duty does not apply. -/
def idleTrace : Trace :=
  traceOf run8 (ground ++ [appLane, stopLineR, roadwayR]) [stopSign [2], greenHead [6]]

/-- `blind` (unknown): The permit approach - the subject comes to rest once on its approach and then enters the intersection - on a source that maps regions and occupancy but declares region geometry absent, so no boundary and no ground distance is carried. Whether the halt was made at the stop line of this junction, at the near edge of its crosswalk or at the point nearest the intersection cannot be decided, and neither can whether this junction carries a line or a crossing at all, so the rule reports unknown. -/
def blindTrace : Trace :=
  traceOf haltAtLine (ground ++ [appLane, stopLineR]) [stopSign [2]]

/-- `branch_1` (compliant): A yield sign, not a stop sign, governs the intersection region the subject's approach lane runs into, and that approach carries a stop line of this junction. The subject passes that line at 2 m/s, at or below the yield-approach speed and still overlapping no intersection region, without coming to rest, and then enters. The yield the sign requires at the place is performed, the sign governing the junction answering the words as one governing the travel region would. -/
def branch_1Trace : Trace :=
  traceOf slowAtLine (ground ++ [appLane, stopLineR]) [yieldSign [3]]

/-- `branch_2` (violated): A stop sign governs the approach and this junction carries neither a stop line nor a crosswalk the subject's body comes within the entrance reach of. The subject runs at 8 m/s throughout, never halting at any place within the nearest-point tolerance of the intersection region from which the view along the intersecting way reaches the intersection view distance, and enters the junction. -/
def branch_2Trace : Trace :=
  traceOf run8 (ground ++ [appLane]) [stopSign [2]]

/-- `branch_3` (violated): The same stop-signed approach and stop line, with an uncovered signal head that governs the approach lane but is inoperative and shows 'dark' at every observation. The subject runs through at 5 m/s and crosses the line without halting. A head showing no valid indication directs no traffic, so the exception does not lift the duty the sign imposes, and the halt is missing. -/
def branch_3Trace : Trace :=
  traceOf run5 (ground ++ [appLane, stopLineR]) [stopSign [2], darkHead [2]]

/-- `branch_4` (violated): Two stop lines lie on the way: the subject's own, set back from the junction on its approach, and the opposing approach's, beyond the junction. The subject passes its own line at 8 m/s, enters the intersection, and only there comes to rest with its front overlapping the opposing line, its footprint overlapping the intersection region and the opposing approach lane throughout the halt. No conduct was performed at a place before entering the junction, so the words are not satisfied. -/
def branch_4Trace : Trace :=
  traceOf haltInJunction (ground ++ [appLane, stopLineR, oppLane, oppLine]) [stopSign [2]]

/-- `branch_5` (violated): The same stop-signed approach and stop line, the subject crossing the line at 6 m/s without halting and judged at an observation at which its footprint lies wholly within the intersection and no longer overlaps the approach lane it came in on; that lane is found in the stretch of path behind, so the duty is still judged of it, and no halt is found anywhere in that stretch. -/
def branch_5Trace : Trace :=
  traceOf run6 (ground ++ [appLaneShort, stopLineR]) [stopSign [2]]

/-- `branch_6` (compliant): A stop sign governs the approach; this junction carries no stop line but a near-side crosswalk on the subject's approach way, and the same way carries one stop line a kilometre beyond the junction, which the subject's body never comes within the entrance reach of. The subject comes to rest half a metre short of the crossing, within the entrance reach of the intersection, having nowhere overlapped that crossing within the crossing look-back of path behind, and then crosses and enters. The distant line is no line of this junction, so the crosswalk limb governs and the halt at the crossing's edge satisfies it. -/
def branch_6Trace : Trace :=
  traceOf haltAtCrossing (ground ++ [appLane, crossWalkR, farLine]) [stopSign [2]]

/-- `branch_7` (compliant): A stop sign governs the approach and this junction carries neither a stop line nor a crosswalk the subject's body comes within the entrance reach of. The subject comes to rest with its body a metre from the intersection region, within the nearest-point tolerance and overlapping no intersection region, where the view along the intersecting way reaches the intersection view distance, and then enters. -/
def branch_7Trace : Trace :=
  traceOf haltNearEdge (ground ++ [appLane]) [stopSign [2]]

/-- `branch_8` (compliant): A stop sign governs the designated left-turn lane through which the subject reaches the junction, a turn lane that runs into the intersection region and lies on the same way as it; the way carries a stop line at that entrance. The subject halts in the turn lane with the ground distance from its body to the line nil and to the intersection region three metres, overlapping no region of kind lane and no intersection region, and then enters. The turn lane carries the signs and the way as an ordinary lane would, so the duty is engaged and the halt is at the line the words name. -/
def branch_8Trace : Trace :=
  traceOf haltOnLine (ground ++ [turnLaneR, turnLine]) [stopSign [7]] (cm (-450))

/-- `branch_9` (violated): No sign governs any lane of the junction and none governs the intersection region: a stop sign is erected over the roadway by which the subject comes to the junction, and dev.governs holds of that roadway alone. That roadway lies on the same way as the intersection region, and the subject's footprint overlaps it at every observation and comes to overlap the intersection region. The subject runs at 8 m/s throughout, its speed never within the halt tolerance anywhere in the stretch of path behind, and crosses the stop line of this junction without halting. The sign faces the traffic of the roadway, which the subject is one of, so the duty is engaged and the halt is missing. -/
def branch_9Trace : Trace :=
  traceOf run8 (ground ++ [roadwayR, stopLineR]) [stopSign [6]]

/-- `branch_10` (compliant): The same roadway-governing stop sign - the only sign of the scene, governing neither a lane nor the junction - and the stop line of this junction. The subject comes to rest with the ground distance from its body to that line within the placement tolerance and to the intersection region within the entrance reach, its footprint overlapping no intersection region and overlapping that signed roadway, and then enters. The duty the roadway-borne sign imposes is performed at the line.
    The witness speaks about the instant at which the body is within the junction: the roadway runs
    through the junction rather than into it, so until the body overlaps the junction the scene
    says nothing about whether that roadway is an approach to it, and the rule reports unknown. -/
def branch_10Trace : Trace :=
  traceOf haltAtLine (ground ++ [roadwayR, stopLineR]) [stopSign [6]]

/-- `branch_11` (violated): A stop sign governs the subject's approach lane and a stop line crosses it. A person directing traffic, of the role police officer, governs the opposing roadway beyond the junction, which the subject's footprint never overlaps, and governs neither the intersection region nor any region the subject is upon. The subject crosses the line at 8 m/s without halting and enters. The traffic the officer controls is not the subject's, so the exception does not lift the duty and the halt is missing. -/
def branch_11Trace : Trace :=
  traceOf run8 (ground ++ [appLane, stopLineR, oppRoadway]) [stopSign [2], officer [13]]

/-- `branch_12` (compliant): A yield sign governs the approach lane itself, and no sign governs the
    junction. The subject passes the stop line of this junction at 2 m/s, at or below the
    yield-approach speed and overlapping no intersection region, and then enters. A yield sign over
    the travel region answers the words as one over the junction does. -/
def branch_12Trace : Trace :=
  traceOf slowAtLine (ground ++ [appLane, stopLineR]) [yieldSign [2]]

/-- `branch_13` (compliant): The stop-signed approach and its stop line; the subject comes to rest
    at the line and stands there to the end of the trace, its footprint overlapping no intersection
    region at any observation. The duty is engaged throughout - the signs face its traffic on an
    approach that runs into the junction - and nothing is required of a vehicle that has not
    reached the junction. -/
def branch_13Trace : Trace :=
  traceOf haltShortOfJunction (ground ++ [appLane, stopLineR]) [stopSign [2]]

/-- `branch_14` (not_applicable): The stop-signed approach and its stop line, with a person
    directing traffic, of the role police officer, standing in the junction and governing the
    intersection region itself - neither the approach lane nor any other region the subject is
    upon. The subject runs through at 8 m/s without halting. The officer controls the traffic of
    the junction the signs face, so the duty does not apply, and it is the role that decides: a
    person directing traffic in any other role would leave the duty in force. -/
def branch_14Trace : Trace :=
  traceOf run8 (ground ++ [appLane, stopLineR]) [stopSign [2], officer [3]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .compliant [] (some (9000, 9000))
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .compliant
  , witness "branch_14" branch_14Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_257_1_o1
