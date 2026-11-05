/-
  Witnesses for NRS_484B_113_2.

  The world every scene below is built in: a city junction whose roadways meet in the square
  region 10 (`junction`, kind intersection) from (-6, -6) to (6, 6) metres. Region 11 is a marked
  crosswalk: on its east approach, (6, -6) to (12, 6) (`crossing`), or on its west approach,
  (-12, -6) to (-6, 6) (`westCrossing`), whichever the scene needs. Every body heads east
  (+x) and rides on the line y = 0; a body that backs has its velocity set opposite its heading,
  so its heading and its travel disagree, which is what drv.motion.rearward_motion reads.
  Occupancy is the builders' own, from the polygons: a body occupies the region its reference
  point lies in. Each trace is three observations one second apart, so a body backing at 1.5 m/s
  moves 1.5 m between them.

  Rates of turn: the adapter holds a scene's yaw rate over the interval before it, so a body that
  turns must show the heading it turned to. A body turning in these traces therefore turns at the
  first observation, whose interval lies outside the trace, and holds its course after; every other
  body has yaw rate zero, further below the tolerance than the narratives' 0.1–0.2 deg/s and
  decided alike.

  Every figure here is the witness's own and appears nowhere in the rule; the reading's values the
  scenes are built against are p.reverse_speed_tolerance = 0.3 m/s, p.yaw_rate_tolerance = 1 deg/s
  and p.corner_reach = 10 m, and every scene breaks or keeps each by a clear margin.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_113_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_113_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- Centimetres per second. -/
def cmps (n : Int) : Q := Units.micrometresPerSecond (n * 10000)
/-- Degrees per second. -/
def degps (n : Int) : Q := Units.degrees n
/-- Thousandths of a degree per second. -/
def mdegps (n : Int) : Q := Units.millidegrees n

/-- The value for the k-th observation of a three-scene trace. -/
def pick (k : Nat) (a b c : Q) : Q := if k = 0 then a else if k = 1 then b else c

/-- The yaw rate of a body turning at 7 deg/s at the first observation of the trace and holding a
    straight course afterwards. A rate of turn at a scene is the rate over the interval before it,
    and the interval before the first observation is outside the trace, so this is the one turn a
    three-scene trace of exact rational headings can carry: a later one would demand a heading
    rotated by 7°, which no rational vector gives exactly. -/
def turnOnce (k : Nat) : Q := if k = 0 then degps 7 else Q.zero

/-- A body holding a straight course: its heading does not change, so its rate of turn is zero,
    a clear margin below the 1 deg/s tolerance. -/
def straight : Q := Q.zero

def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)
def vanExtent : Q × Q × Q := (cm 250, m 1, cm 130)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 60)

/-- A body on y = 0 heading east whose velocity runs opposite its heading: it backs at `spd`. -/
def backing (track : TrackId) (cls : List RoadUserClass) (x spd yaw : Q)
    (half : Q × Q × Q) : RoadUser :=
  Build.withKin (Build.user track cls (x, Q.zero) Build.east spd half) fun k =>
    { k with velocity := some (Build.scale Build.east (Q.neg spd)), yawRate := some yaw }

/-- A body on y = 0 heading east and travelling east at `spd`. -/
def rolling (track : TrackId) (cls : List RoadUserClass) (x spd yaw : Q)
    (half : Q × Q × Q) : RoadUser :=
  Build.withKin (Build.user track cls (x, Q.zero) Build.east spd half) fun k =>
    { k with yawRate := some yaw }

/-- The same body, of which the source does not observe the velocity. -/
def velocityUnobserved (u : RoadUser) : RoadUser :=
  Build.withKin u fun k => { k with velocity := none }

/-- The junction region: the square where the two roadways meet. -/
def junction : Structure := Build.rect 10 .intersection (m (-6)) (m (-6)) (m 6) (m 6)
/-- The marked crosswalk across the junction's east approach. -/
def crossing : Structure :=
  { Build.rect 11 .crosswalk (m 6) (m (-6)) (m 12) (m 6) with marked := some true }
/-- The marked crosswalk across the junction's west approach. -/
def westCrossing : Structure :=
  { Build.rect 11 .crosswalk (m (-12)) (m (-6)) (m (-6)) (m 6) with marked := some true }

def inCity : List (AsmId × Bool) := [("asm.way_within_city_limits", true)]
def outsideCity : List (AsmId × Bool) := [("asm.way_within_city_limits", false)]

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): A passenger car on a city street reverses at 1.5 m/s — its velocity opposed to its heading — and its footprint overlaps a marked crosswalk at the junction; the trace declares asm.way_within_city_limits. No other road user is in the scene. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing 1 [.motorVehicle] (pick k (cm 1100) (cm 950) (cm 800)) (cmps 150) straight
          carExtent ]
      [ junction, crossing ]
      []
      (assumptions := inCity)

/-- `permit` (compliant): The same car reverses at 1.0 m/s along a parking aisle 60 m from the nearest junction, its yaw rate 0.1 deg/s, its footprint overlapping no crosswalk and no intersection and no junction region within the reach. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing 1 [.motorVehicle] (pick k (m 70) (m 69) (m 68)) (cmps 100) straight carExtent ]
      [ junction, crossing ]
      []
      (assumptions := inCity)

/-- `idle` (not_applicable): A pedal bicycle — a device moved by human power, which DEF-NRS-484A-320 leaves out of the vehicle aggregate — is pushed backwards over a marked crosswalk at a city junction; no vehicle is in the scene. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing 1 [.bicycle] (pick k (cm 1100) (cm 1050) (cm 1000)) (cmps 50) straight
          bikeExtent ]
      [ junction, crossing ]
      []
      (assumptions := inCity)

/-- `blind` (unknown): A car's footprint overlaps a marked crosswalk at a city junction and its wheels are turned; the source declares kin.velocity absent, so whether it is travelling rearward cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ velocityUnobserved (backing 1 [.motorVehicle] (m 9) (cmps 100) (turnOnce k) carExtent) ]
      [ junction, crossing ]
      []
      (assumptions := inCity)

/-- `branch_1` (violated): A delivery van on a city street reverses at 1.2 m/s with a yaw rate of 7 deg/s while its body is 3 m from the junction region it is backing round; its footprint touches no crosswalk and never overlaps the junction. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing 1 [.truck] (pick k (cm 1390) (cm 1270) (cm 1150)) (cmps 120) (turnOnce k)
          vanExtent ]
      [ junction, westCrossing ]
      []
      (assumptions := inCity)

/-- `branch_2` (violated): A car reverses at 0.8 m/s and at this observation its footprint begins to overlap the junction region, having not overlapped it at the previous observation; no crosswalk is marked there. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing 1 [.motorVehicle] (pick k (cm 700) (cm 620) (cm 540)) (cmps 80) straight
          carExtent ]
      [ junction, westCrossing ]
      []
      (assumptions := inCity)

/-- `branch_3` (compliant): the same car drives forward over the marked crosswalk at the city
    junction: it is at one of the three places, but it does not back, so it complies. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rolling 1 [.motorVehicle] (pick k (m 8) (cm 950) (m 11)) (cmps 150) straight
          carExtent ]
      [ junction, crossing ]
      []
      (assumptions := inCity)

/-- `branch_4` (compliant): a car halted inside the junction region then backs across it at
    0.8 m/s without turning: it is in the intersection but enters it at no observation of the
    trace, and it touches no crosswalk, so it complies. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing 1 [.motorVehicle] (pick k (m 2) (cm 120) (cm 40))
          (if k = 0 then cmps 0 else cmps 80) straight carExtent ]
      [ junction, crossing ]
      []
      (assumptions := inCity)

/-- `branch_5` (compliant): the `branch_1` van, backing and turning 3 m from the junction, on a
    highway the trace declares to be outside the limits of any incorporated city: no street
    corner, so it complies. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing 1 [.truck] (pick k (cm 1390) (cm 1270) (cm 1150)) (cmps 120) (turnOnce k)
          vanExtent ]
      [ junction, westCrossing ]
      []
      (assumptions := outsideCity)

/-- `branch_6` (compliant): a car on a city street backs at 1.0 m/s while turning at 7 deg/s, but
    its body stays 22 m from the junction region, well beyond the corner's reach, so it complies. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ backing 1 [.motorVehicle] (pick k (m 32) (m 31) (m 30)) (cmps 100) (turnOnce k)
          carExtent ]
      [ junction, crossing ]
      []
      (assumptions := inCity)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_113_2"
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant ]

end TrafficSpecWitness.NRS_484B_113_2
