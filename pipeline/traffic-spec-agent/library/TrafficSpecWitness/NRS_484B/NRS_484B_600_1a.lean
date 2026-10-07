/-
  Witnesses for NRS_484B_600_1a.

  The carriageway. Every scene is laid out on one straight, level stretch running east: a roadway
  region (id 11) 12 m wide about the line y = 0, from x = 0 to x = 1000, carrying the curvature of
  the place; inside it one lane (id 10) of the width the scene declares, centred on the same line
  and carrying it as `st.lane_width`. The subject (track 1) stands at x = 100 m, y = 0, heading
  east, so it occupies both regions; a second body, where the scene has one, is a little further
  east in the same lane. Each witness is three instants a second apart; nothing in the rule looks
  back, so the three are the same scene at three times.

  The margins. The subject's half-length is 2 m and a truck's 5 m, so the longitudinal surface gap
  between two bodies 10 m apart centre to centre is 3 m. At 20 m/s the car needs 73.8 m to halt on
  a wet surface once its 0.75 s response is allowed for, and 94.4 m to halt after the 2.5 s design
  reaction time; at 30 m/s the latter is 175 m. The free-flow bound of a 2 m lane is about 27.2 m/s
  and of a 4 m lane about 32.1 m/s. A curve of radius 100 m exhausts the comfortable side friction
  at about 15.1 m/s. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

private def m (n : Int) : Q := Units.metres n
private def cm (n : Int) : Q := Units.centimetres n
private def mps (n : Int) : Q := Units.metresPerSecond n

/-- Half-length, half-width, half-height. -/
private def carExtent : Q × Q × Q := (m 2, m 1, m 1)
private def truckExtent : Q × Q × Q := (m 5, m 1, m 2)
private def bicycleExtent : Q × Q × Q := (m 1, cm 30, m 1)

/-- The lane of the stretch, of the declared width, centred on y = 0. -/
private def laneOf (w : Q) : Structure :=
  { Build.rect 10 .lane (m 0) (Q.neg (Q.half w)) (m 1000) (Q.half w) with
      lane := some { direction := some Build.east, width := some w } }

/-- The roadway of the stretch, carrying the curvature at the subject's place (1/m; zero straight). -/
private def roadwayOf (curvature : Q) : Structure :=
  { Build.rect 11 .roadway (m 0) (m (-6)) (m 1000) (m 6) with curvature := some curvature }

private def weather (wet rain ice : Bool) (visibility : Q) : Env :=
  { precipitation := some rain
    wetRoad := some wet
    iceOrSnow := some ice
    visibility := some visibility }

private def theCar (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 100, m 0) Build.east speed carExtent

/-- `forbid` (violated): The subject is a car proceeding along a straight, undivided roadway while rain falls and the surface is wet. A truck stands halted in the subject's own lane ahead of it, and the longitudinal gap between the two bodies is far shorter than the distance the car would need to come to a halt from its present speed at the deceleration a wet surface allows, once its response to the truck is allowed for; the halted truck itself needs no distance to stop. The lane is of the nominal width, the roadway is straight and the air is clear, so no other bound is near. The traffic bound is passed: the rate of speed is greater than is reasonable, having due regard for the traffic and for the surface. -/
private def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ theCar (mps 20)
      , Build.user 2 [.truck] (m 110, m 0) Build.east (mps 0) truckExtent ]
      [ laneOf (cm 366), roadwayOf Q.zero ]
      []
      (env := weather true true false (m 500))

/-- `permit` (compliant): The subject is the same car on the same straight roadway, alone: no other road user is anywhere in the scene, so the rule's quantification over the traffic ahead has nothing to range over and the subject's duty is still decided. The surface is dry, no precipitation falls, the air is clear and the visibility distance far exceeds the distance the car needs to halt from its speed, the lane it occupies is wider than the nominal width, and the roadway at its place is straight. Its speed passes none of the four bounds. -/
private def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ theCar (mps 20) ]
      [ laneOf (m 4), roadwayOf Q.zero ]
      []
      (env := weather false false false (m 500))

/-- `idle` (not_applicable): The subject is a bicycle, ridden briskly along the roadway with a delivery van halted close ahead in its lane - a gap far shorter than the distance the rider would need to stop. A bicycle is moved by human power, which the definition of 'vehicle' excepts, so the reading's 'vehicle' aggregate does not count the subject and the duty does not reach it, however close the van stands. -/
private def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m 100, m 0) Build.east (mps 6) bicycleExtent
      , Build.user 2 [.motorVehicle] (m 108, m 0) Build.east (mps 0) carExtent ]
      [ laneOf (cm 366), roadwayOf Q.zero ]
      []
      (env := weather false false false (m 500))

/-- `blind` (unknown): The scene of 'permit' exactly - dry, straight, empty, a wide lane - except that the source's capability manifest declares the visibility distance absent, so env.visibility is not observed. The traffic, width and curvature bounds are all met, but whether the car can halt within what can be seen through the air cannot be decided, so the rule reports unknown rather than compliant. -/
private def blindTrace : Trace := permitTrace

/-- `branch_1` (violated): A car takes a tight bend on a dry roadway with nobody else about, the air clear and the lane wide. The square of its speed, allowing for the speed tolerance, exceeds the comfortable lateral acceleration multiplied by the radius of the curve at its place. The curvature bound is passed and nothing else is near its bound. -/
private def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ theCar (mps 20) ]
      [ laneOf (m 4), roadwayOf (Units.ratio 1 100) ]
      []
      (env := weather false false false (m 500))

/-- `branch_2` (violated): A car proceeds at open-road speed along a lane far narrower than the nominal width, on a dry, straight and empty stretch in clear air. Its speed exceeds, by more than the speed tolerance, the base free-flow speed reduced by the lane's width deficit. The width bound is passed and no other bound is. -/
private def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ theCar (mps 30) ]
      [ laneOf (m 2), roadwayOf Q.zero ]
      []
      (env := weather false false false (m 1000))

/-- `branch_3` (violated): A car proceeds through thick fog along a dry, straight, empty road in a wide lane. The visibility distance is far shorter than the distance the car would need to halt from its present speed after the design brake-reaction time. The weather bound is passed and no other bound is. -/
private def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ theCar (mps 20) ]
      [ laneOf (m 4), roadwayOf Q.zero ]
      []
      (env := weather false false false (m 30))

private def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_600_1a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("veh", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["env.visibility"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a
