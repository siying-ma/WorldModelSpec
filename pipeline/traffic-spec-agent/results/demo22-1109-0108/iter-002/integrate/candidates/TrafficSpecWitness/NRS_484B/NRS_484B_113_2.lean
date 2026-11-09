/-
  Witnesses for NRS_484B_113_2.

  THE GEOMETRY. Two streets, each a highway region thirty metres between its boundary lines:
  region 1 runs east-west (y from -15 to 15 m), region 2 north-south (x from -15 to 15 m). They
  meet at region 10, the junction at the origin, a thirty-metre square whose `ways` are those two
  highways. Region 20 is a marked crossing laid across the east-west street just east of that
  junction (x from 15 to 19 m); region 21 a marked crossing at mid-block, forty metres east of
  the junction, away from any junction at all. Where a witness needs a second junction (the
  `permit` scene speaks of a stretch between two of them), region 3 is a further north-south
  highway (x from 85 to 115 m) and region 11 the junction it makes with region 1.

  THE BODIES. Track 1 is the subject in every witness: a car 4 m by 1.8 m, or — in `branch_1` —
  a van 4.8 m by 2 m, or — in `idle` — a pedal cycle 1.8 m by 0.6 m, which the aggregate of
  DEF-NRS-484A-320 leaves out. A reversing body is built with its velocity set against its
  heading, so that the component of the velocity along the direction the body points is the
  negative of its speed: 1.5 m/s for the car, 1 m/s for the van, 0.5 m/s for the cycle, each well
  clear of the tolerance below which a rearward reading is noise. Its reference point advances by
  the speed of the scene over the interval before it, so no scene asserts a motion its own figures
  deny, and the occupancy stated for each scene is the one its footprint has: the car's rear face
  is two metres behind its reference point, the van's 2.4 m, and a region is listed exactly from
  the scene at which that face crosses the region's boundary.

  In `branch_2` and `branch_4` the car backs around the corner inside the junction: it reverses
  due west until t = 4000 ms and then yaws to the left at 10 degrees per second to the end of the
  trace, its heading rotating half a degree between consecutive scenes — the exact rational
  rotation its yaw rate makes over the 50 ms before a scene, so that heading and yaw rate say the
  same thing at every scene — and its reference point running along the arc of radius 8.6 m that
  that yaw rate and that speed describe. Over the three seconds behind any judged instant its
  heading change is at least twenty degrees, far above the resolution; in `branch_5` the same car
  reverses straight through the junction with its yaw rate zero throughout, so it is not turning.

  THE INSTANTS. Every trace is 141 scenes at 50 ms, t = 0 to 7000 ms, the sampling period of the
  run's acquisition profile, so that the three-second window behind every judged instant is
  covered rather than truncated. Each witness names the instants it speaks about, t = 6000 to
  7000 ms: the second in which the car crosses into the junction (`forbid`), stands on the
  crossing (`branch_1`), or is well into its corner (`branch_2`).

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_113_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_113_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A point of the world frame, in millimetres: every coordinate below is exact. -/
def ptmm (x y : Int) : Vec := (Units.millimetres x, Units.millimetres y)

def carSpeed : Q := Units.micrometresPerSecond 1500000
def vanSpeed : Q := Units.metresPerSecond 1
def cycleSpeed : Q := Units.micrometresPerSecond 500000
def leftYaw : Q := Units.degrees 10

def carHalf : Q × Q × Q := (m 2, cm 90, cm 75)
def vanHalf : Q × Q × Q := (cm 240, m 1, cm 95)
def cycleHalf : Q × Q × Q := (cm 90, cm 30, cm 90)

-- Binders ↦ tracks: v ↦ 1

/-- The rotation to the left by one step of the corner: the half degree a yaw rate of 10 deg/s
    makes over the 50 ms before a scene, as an exact rational rotation. -/
def stepCos : Q := Units.ratio 9999619 10000000
def stepSin : Q := Units.ratio 87265 10000000

/-- Keep a coordinate to a tenth of a micrometre, so the steps of the corner stay small exact
    rationals; the angle between consecutive headings is unaffected at this resolution. -/
def trim (q : Q) : Q := Units.ratio ((q.num * 10000000) / Int.ofNat q.den) 10000000

def rotLeft (v : Vec) : Vec :=
  (trim (Q.sub (Q.mul v.1 stepCos) (Q.mul v.2 stepSin)),
   trim (Q.add (Q.mul v.1 stepSin) (Q.mul v.2 stepCos)))

/-- `n` steps of that rotation. -/
def rotN : Nat → Vec → Vec
  | 0, v => v
  | n + 1, v => rotLeft (rotN n v)

/-- The east-west street, thirty metres between its boundary lines. -/
def eastWestStreet : Structure := Build.rect 1 .highway (m (-200)) (m (-15)) (m 200) (m 15)

/-- The north-south street it meets at the origin. -/
def northSouthStreet : Structure := Build.rect 2 .highway (m (-15)) (m (-200)) (m 15) (m 200)

/-- The junction of those two ways. -/
def junction : Structure :=
  { Build.rect 10 .intersection (m (-15)) (m (-15)) (m 15) (m 15) with ways := some [1, 2] }

/-- A further north-south street, and the junction it makes with the east-west one. -/
def farStreet : Structure := Build.rect 3 .highway (m 85) (m (-200)) (m 115) (m 200)

def farJunction : Structure :=
  { Build.rect 11 .intersection (m 85) (m (-15)) (m 115) (m 15) with ways := some [1, 3] }

/-- The marked crossing at the junction, on the east-west street. -/
def junctionCrosswalk : Structure :=
  { Build.rect 20 .crosswalk (m 15) (m (-15)) (m 19) (m 15) with
      marked := some true, ways := some [1] }

/-- The marked crossing at mid-block, away from any junction. -/
def midBlockCrosswalk : Structure :=
  { Build.rect 21 .crosswalk (m 40) (m (-15)) (m 44) (m 15) with
      marked := some true, ways := some [1] }

/-- A clear, dry afternoon. -/
def weather : Env :=
  { darkness := some false, precipitation := some false, wetRoad := some false,
    iceOrSnow := some false, visibility := some (m 300) }

/-- A body travelling rearward: its velocity is set against its heading at `speed`, so the
    component of the velocity along the direction it points is `-speed`. -/
def reversingUser (track : TrackId) (classes : List RoadUserClass) (pos heading : Vec)
    (speed : Q) (halfExtent : Q × Q × Q) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user track classes pos heading speed halfExtent)
    (fun k => { k with velocity := some (Build.scale heading (Q.neg speed)),
                       yawRate := some yaw })

/-- A body travelling forward: `Build.user` already sets its velocity along its heading. -/
def forwardUser (track : TrackId) (classes : List RoadUserClass) (pos heading : Vec)
    (speed : Q) (halfExtent : Q × Q × Q) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user track classes pos heading speed halfExtent)
    (fun k => { k with yawRate := some yaw })

/-- 141 scenes at the acquisition profile's 50 ms, t = 0 to 7000 ms. -/
def traceOf (f : Nat → Timestamp → Scene) : Trace := Build.trace 141 0 (Units.milliseconds 50) f

/-- A scene of a witness: the bodies, the roads, the stated occupancy and the city-limits
    declaration the map carries. -/
def sceneOf (t : Timestamp) (users : List RoadUser) (roads : List Structure)
    (occ : List (TrackId × RegionId)) (inCity : Bool) : Scene :=
  Build.scene t (some 1) users roads [] (some occ) weather
    [("asm.inside_city_limits", inCity)]

/-- The car approaching the junction from the east, heading east and reversing westward: its
    reference point is at 17 m when its rear face reaches the junction's east boundary, which it
    does at t = 6500 ms. -/
def backingCarXmm (k : Nat) : Int := 26700 - 75 * (k : Int)

/-- Its stated occupancy: the east-west street throughout, and the junction with the north-south
    street from the scene at which its rear face crosses x = 15 m. -/
def backingCarOcc (k : Nat) : List (TrackId × RegionId) :=
  [(1, 1)] ++ (if backingCarXmm k - 2000 ≤ 15000 then [(1, 2), (1, 10)] else [])

/-- `forbid` (violated): A car stops just short of a four-way junction, selects reverse and then — having overshot — reverses the other way: at one observation its velocity has a rearward component of 1.5 m/s along its heading and its footprint first overlaps the junction region. It has backed into an intersection. -/
def forbidTrace : Trace :=
  traceOf fun k t =>
    sceneOf t
      [reversingUser 1 [.motorVehicle] (ptmm (backingCarXmm k) (-5000)) Build.east
        carSpeed carHalf Q.zero]
      [eastWestStreet, northSouthStreet, junction] (backingCarOcc k) true

/-- The car leaving the parking bay at mid-block: it reverses 10.5 m westward along the stretch
    between the two junctions, from 75 m to 64.5 m east of the first. -/
def midBlockCarXmm (k : Nat) : Int := 75000 - 75 * (k : Int)

/-- `permit` (compliant): The same car reverses 10 m along a straight stretch of roadway midway between two junctions to leave a parking bay. Through the whole reverse its footprint overlaps no intersection and no crosswalk, and it occupies no region where two highways meet, so no limb of the prohibition is met. -/
def permitTrace : Trace :=
  traceOf fun k t =>
    sceneOf t
      [reversingUser 1 [.motorVehicle] (ptmm (midBlockCarXmm k) (-5000)) Build.east
        carSpeed carHalf Q.zero]
      [eastWestStreet, northSouthStreet, junction, farStreet, farJunction, junctionCrosswalk]
      [(1, 1)] true

/-- The cycle wheeled backwards off the crossing into the junction. -/
def cycleXmm (k : Nat) : Int := 16000 - 25 * (k : Int)

def cycleOcc (k : Nat) : List (TrackId × RegionId) :=
  [(1, 1)]
    ++ (if cycleXmm k - 900 ≤ 15000 then [(1, 2), (1, 10)] else [])
    ++ (if cycleXmm k + 900 ≥ 15000 then [(1, 20)] else [])

/-- `idle` (not_applicable): A pedal cycle propelled by human power, which the vehicle definition leaves out, is wheeled backwards over a marked crossing at a junction. No vehicle is bound and the rule does not engage. -/
def idleTrace : Trace :=
  traceOf fun k t =>
    sceneOf t
      [reversingUser 1 [.bicycle] (ptmm (cycleXmm k) (-5000)) Build.east
        cycleSpeed cycleHalf Q.zero]
      [eastWestStreet, northSouthStreet, junction, junctionCrosswalk] (cycleOcc k) true

/-- `blind` (unknown): The forbid scene with the source declaring road-user velocity absent: the junction, the footprint overlap and its rise are recorded, but whether the car's motion was rearward along its heading cannot be read, so the prohibition is unknown rather than satisfied. -/
def blindTrace : Trace := forbidTrace

/-- The van backing out of the loading bay: its reference point is at 46.4 m when its rear face
    reaches the crossing's east boundary. -/
def vanXmm (k : Nat) : Int := 51300 - 50 * (k : Int)

def vanOcc (k : Nat) : List (TrackId × RegionId) :=
  [(1, 1)] ++ (if vanXmm k - 2400 ≤ 44000 then [(1, 21)] else [])

/-- `branch_1` (violated): A van reverses out of a loading bay and its footprint comes to overlap a marked crossing laid across the roadway away from any junction, its rearward speed 1 m/s. It has backed on or over a crosswalk. -/
def branch_1Trace : Trace :=
  traceOf fun k t =>
    sceneOf t
      [reversingUser 1 [.motorVehicle] (ptmm (vanXmm k) (-5000)) Build.east
        vanSpeed vanHalf Q.zero]
      [eastWestStreet, midBlockCrosswalk] (vanOcc k) true

/-- The scene at which the car's yaw rate rises, t = 4000 ms. -/
def turnStart : Nat := 80

/-- Its heading: due east until the corner begins, then half a degree further to the left at
    every scene. -/
def cornerHeading (k : Nat) : Vec :=
  if k ≤ turnStart then Build.east else rotN (k - turnStart) Build.east

/-- Its reference point: straight west down the junction until the corner begins, then along the
    arc of radius 8.6 m its yaw rate and its speed describe, centred at (6, -13.6) m. -/
def cornerPos (k : Nat) : Vec :=
  if k ≤ turnStart then ptmm (12000 - 75 * (k : Int)) (-5000)
  else
    let u := rotN (k - turnStart) Build.north
    (Q.add (Units.millimetres 6000) (Q.mul u.1 (Units.millimetres 8600)),
     Q.add (Units.millimetres (-13600)) (Q.mul u.2 (Units.millimetres 8600)))

def cornerYaw (k : Nat) : Q := if k ≤ turnStart then Q.zero else leftYaw

/-- The car is within the junction, and so within both ways that meet there, at every scene of
    the corner traces: it had already backed in before the recording began. -/
def cornerOcc : List (TrackId × RegionId) := [(1, 1), (1, 2), (1, 10)]

/-- The corner trace, with the city-limits declaration the map carries. -/
def cornerTrace (inCity : Bool) : Trace :=
  traceOf fun k t =>
    sceneOf t
      [reversingUser 1 [.motorVehicle] (cornerPos k) (cornerHeading k)
        carSpeed carHalf (cornerYaw k)]
      [eastWestStreet, northSouthStreet, junction] cornerOcc inCity

/-- `branch_2` (violated): A car reverses through the corner of a junction of two highways inside a city, the trace declaring the city-limits assumption true: while its footprint overlaps the junction its heading change over the window behind exceeds the resolution, so it is turning, and its motion is rearward throughout. -/
def branch_2Trace : Trace := cornerTrace true

/-- `branch_3` (compliant): The forbid geometry with the car driving forward into the junction
    instead of backing into it: its velocity runs along its heading, so it is not travelling
    rearward and no limb of the prohibition can bite. -/
def branch_3Trace : Trace :=
  traceOf fun k t =>
    sceneOf t
      [forwardUser 1 [.motorVehicle] (ptmm (backingCarXmm k) 5000) Build.west
        carSpeed carHalf Q.zero]
      [eastWestStreet, northSouthStreet, junction] (backingCarOcc k) true

/-- `branch_4` (compliant): The same reversing corner, the map declaring the junction outside the
    territorial limits of any city: the street-corner limb is not met, and the car neither backs
    into the junction (it was within it before the recording) nor overlaps a crossing. -/
def branch_4Trace : Trace := cornerTrace false

/-- `branch_5` (compliant): A car reverses straight through the same junction of two highways
    inside a city, its yaw rate zero throughout: its heading change over the window behind is
    nothing, so it is not turning and backs around no corner. -/
def branch_5Trace : Trace :=
  traceOf fun k t =>
    sceneOf t
      [reversingUser 1 [.motorVehicle] (ptmm (12000 - 75 * (k : Int)) (-5000)) Build.east
        carSpeed carHalf Q.zero]
      [eastWestStreet, northSouthStreet, junction] cornerOcc true

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (6000, 7000)) : Scenario :=
  { name := name
    rule := "NRS_484B_113_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := window
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
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_113_2
