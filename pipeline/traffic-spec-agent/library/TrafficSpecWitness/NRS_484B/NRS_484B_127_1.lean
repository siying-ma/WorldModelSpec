/-
  Witnesses for NRS_484B_127_1.

  One straight carriageway in every scene: a highway region (region 1) 16 m broad, x ∈ [-500, 500],
  y ∈ [-8, 8], which every body of the scene stands on; `branch_12` carries a second highway region
  (region 2, y ∈ [20, 36]) alongside it, which the subject never stands on. The scenes carry no
  lane, because neither concept this rule calls reads one.

  The subject is track 1, a passenger car 4 m long and 1.8 m wide (half-extents 2 m, 0.9 m, 0.75 m);
  every other car is the same body, the bicycle of `branch_9` is 1.8 m long, and the truck of
  `branch_8` is a 4 m body too. Each scene is observed three times, a second apart, and every body
  advances by its own velocity between observations, so the geometry a narrative states is the
  geometry at the last observation of a scene that closes and at every observation of a scene that
  holds its spacing. Headings are due east unless stated; the two bodies of `branch_4` point east
  and travel west, their velocity written against their heading, and the bodies at rest in
  `branch_7` and `branch_8` keep their place.

  Every figure here is the witness's own and appears nowhere in the rule; the geometry is built to
  break or keep each bound of the run's reading by a clear margin (p.speed_resolution 0.2 m/s,
  p.body_offset_resolution 0.3 m, p.following_heading_cosine 0.966, p.following_reach 100 m,
  p.single_file_reach 1.8 m, p.headway_dry 2 s, p.headway_wet 3 s, p.headway_ice 5 s,
  p.closing_time 2 s, p.traffic_reach 50 m, p.traffic_gap_increment 1 m).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_127_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_127_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

/-- The observation index as a quantity: the observations are a second apart, so it is also the
    seconds elapsed since the first of them. -/
def step (k : Nat) : Q := Q.ofInt (Int.ofNat k)

/-- A passenger car's half-extents: a body 4 m long and 1.8 m wide. -/
def carBody : Q × Q × Q := (m 2, cm 90, cm 75)
/-- A bicycle's half-extents: a body 1.8 m long. -/
def bikeBody : Q × Q × Q := (cm 90, cm 30, cm 90)

-- ---------------------------------------------------------------------------------------------
-- The ground and the weather
-- ---------------------------------------------------------------------------------------------

/-- The carriageway the bodies stand on. -/
def way : Structure := Build.rect 1 .highway (m (-500)) (m (-8)) (m 500) (m 8)
/-- A second highway alongside it, which the subject never stands on. -/
def farWay : Structure := Build.rect 2 .highway (m (-500)) (m 20) (m 500) (m 36)

def dry : Env := { wetRoad := some false, iceOrSnow := some false }
def wet : Env := { wetRoad := some true, iceOrSnow := some false }
def icy : Env := { wetRoad := some true, iceOrSnow := some true }

-- ---------------------------------------------------------------------------------------------
-- The bodies
-- ---------------------------------------------------------------------------------------------

/-- A car at `x0` at the first observation, going due east at `speed`. -/
def eastCar (track : TrackId) (x0 y speed : Q) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (Q.add x0 (Q.mul speed (step k)), y) Build.east speed carBody

/-- A bicycle, likewise. -/
def eastBike (track : TrackId) (x0 y speed : Q) (k : Nat) : RoadUser :=
  Build.user track [.bicycle] (Q.add x0 (Q.mul speed (step k)), y) Build.east speed bikeBody

/-- A car standing still, pointing whichever way it came to rest facing. -/
def restingCar (track : TrackId) (x y : Q) (heading : Vec) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) heading Q.zero carBody

/-- A truck standing still, pointing whichever way it came to rest facing. -/
def restingTruck (track : TrackId) (x y : Q) (heading : Vec) : RoadUser :=
  Build.user track [.truck] (x, y) heading Q.zero carBody

/-- A car sliding broadside eastward: its body points due north and its velocity runs due east. -/
def crabbingCar (track : TrackId) (x0 speed : Q) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user track [.motorVehicle]
      (Q.add x0 (Q.mul speed (step k)), Q.zero) Build.north speed carBody)
    (fun kin => { kin with velocity := some (Build.scale Build.east speed) })

/-- A car reversing westward: its body points due east and its velocity runs due west. -/
def westReverser (track : TrackId) (x0 speed : Q) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user track [.motorVehicle]
      (Q.sub x0 (Q.mul speed (step k)), Q.zero) Build.east speed carBody)
    (fun kin => { kin with velocity := some (Build.scale Build.west speed) })

-- ---------------------------------------------------------------------------------------------
-- The instants
-- ---------------------------------------------------------------------------------------------

def sceneOf (env : Env) (structures : List Structure) (users : Nat → List RoadUser)
    (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1) (users k) structures [] (env := env)

/-- Three observations a second apart, the bodies moving as their velocities say. -/
def traceOf (env : Env) (structures : List Structure) (users : Nat → List RoadUser) : Trace :=
  Build.trace 3 0 (Units.seconds 1) (sceneOf env structures users)

/-- The one carriageway. -/
def ground : List Structure := [way]

-- Binders ↦ tracks: v ↦ 1

/-- `forbid` (violated): On a dry roadway in daylight, the subject car goes due east at 20 m/s and a second car goes due east at 20 m/s in the same line, its reference point 15 m east of the subject's, both bodies 4 m long and pointing east, so about 11 m of clear space lies between the two bodies along the course. The space the dry headway owes at 20 m/s, with no closing speed and only the leader counted in the traffic within the reach, is about 40 m; the 11 m left falls far short of it. -/
def forbidTrace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 20) k
    , eastCar 2 (m 15) Q.zero (mps 20) k ]

/-- `permit` (compliant): A dry roadway, both cars going due east at 10 m/s in one line, the leader's reference point 45 m east of the subject's, each body 4 m long, and no other road user in the scene. The subject does follow the leader - the offset is within the reach and the two reference points are in one line - and at 10 m/s the dry headway, with no closing speed and the leader counted in the traffic, owes little over 20 m, which the 41 m of clear space exceeds. -/
def permitTrace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 10) k
    , eastCar 2 (m 45) Q.zero (mps 10) k ]

/-- `idle` (not_applicable): The subject car goes due east at 20 m/s on a dry roadway and no other road user is present in the scene at all. It follows nobody, so the words - a driver who follows another vehicle - do not reach it and the duty does not engage. This is the scene with no second party, and the rule decides it without one. -/
def idleTrace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 20) k ]

/-- `blind` (unknown): The same dry roadway and the same two cars going east in one line 15 m apart, on a source that reports positions, headings, velocities and speeds but declares the bodies' extent absent. How far each body reaches beyond its reference point is unobserved, so the clear space between the two bodies cannot be computed and the rule reports unknown. -/
def blindTrace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 20) k
    , eastCar 2 (m 15) Q.zero (mps 20) k ]

/-- `branch_1` (violated): The surface is wet. The subject goes due east at 20 m/s with the leader's reference point 45 m ahead of its own in the same line, both bodies 4 m long, and no other traffic within the reach. The wet headway owes more space than the dry one and the 41 m left falls short of it, where the same space on a dry surface would have met the bound. -/
def branch_1Trace : Trace :=
  traceOf wet ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 20) k
    , eastCar 2 (m 45) Q.zero (mps 20) k ]

/-- `branch_2` (violated): A closing follower on a dry roadway. The subject goes due east at 25 m/s behind a car going at 15 m/s in its line, the two reference points 59 m apart and the bodies 4 m long, with no other road user within the reach. The headway the subject's own speed owes is met by the 55 m of clear space; with the allowance for the 10 m/s by which the subject's speed exceeds the leader's, the space owed is not. -/
def branch_2Trace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 25) k
    , eastCar 2 (m 59) Q.zero (mps 15) k ]

/-- `branch_3` (violated): The subject has closed the last of its space onto the car it follows. On a dry roadway both bodies point and go due east, the subject at 20 m/s and the leader at 10 m/s, the leader's reference point 4 m ahead of the subject's with 4 m long bodies, so the two bodies touch and the clear space along the course is nothing. The following relation still holds, the leader's reference point standing ahead within the subject's line, and the headway convention owes far more than nothing, so the duty is breached at the moment the following culminates. (The subject closes from 24 m to the contact over the three observations.) -/
def branch_3Trace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 20) k
    , eastCar 2 (m 24) Q.zero (mps 10) k ]

/-- `branch_4` (violated): Two cars reverse slowly westward along a dry roadway, both bodies pointing due east, each at 2 m/s and each 4 m long. The other car's reference point is 6 m due west of the subject's, so along the subject's course - which runs west - that car stands 6 m ahead and about 2 m of clear space lies between the bodies. It is the car the subject travels behind in the direction of travel, and at 2 m/s the dry headway owes more than the 2 m left. -/
def branch_4Trace : Trace :=
  traceOf dry ground fun k =>
    [ westReverser 1 (m 0) (mps 2) k
    , westReverser 2 (m (-6)) (mps 2) k ]

/-- `branch_5` (violated): Dense traffic on a dry roadway. The subject goes due east at 20 m/s with the leader's reference point 47 m ahead of its own in its line, bodies 4 m long, and five other cars go 3.5 m to either hand, all within the reach about the subject on the same highway. Those five are offset too far across the subject's course to be in its line, so none of them is followed; the dry headway alone would be met by the 43 m of clear space, but with the increment the thickened traffic adds, the space owed exceeds the space left. -/
def branch_5Trace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 20) k
    , eastCar 2 (m 47) Q.zero (mps 20) k
    , eastCar 3 (m 10) (cm 350) (mps 20) k
    , eastCar 4 (m 25) (cm 350) (mps 20) k
    , eastCar 5 (m 40) (cm (-350)) (mps 20) k
    , eastCar 6 (m (-10)) (cm 350) (mps 20) k
    , eastCar 7 (m 20) (cm (-350)) (mps 20) k ]

/-- `branch_6` (compliant): A dry roadway, the subject going due east at 10 m/s with the leader's reference point 44 m ahead of its own in its line, bodies 4 m long, and a third car abreast of the subject 3.5 m to its left at 10 m/s. The abreast car is not followed - its reference point stands neither ahead of the subject's along its course nor within its line - but it is counted in the traffic upon the highway, and even with that increment the space owed at 10 m/s is well under the 40 m left. -/
def branch_6Trace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 10) k
    , eastCar 2 (m 44) Q.zero (mps 10) k
    , eastCar 3 (m 0) (cm 350) (mps 10) k ]

/-- `branch_7` (violated): A dry roadway, the subject going due east at 20 m/s with a car standing still 20 m ahead of it in its line, that car's body pointing due east, along the subject's course. Its velocity fixes no direction of travel, but the body it presents lies along the course, so it is a vehicle the subject travels behind; with the whole of the subject's 20 m/s counted as closing speed the convention owes far more than the 16 m of clear space left. Were a halted vehicle never reckoned as followed, this scene would be left unengaged. (The subject closes on the halted car from 60 m to the 20 m the narrative states.) -/
def branch_7Trace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m (-40)) Q.zero (mps 20) k
    , restingCar 2 (m 20) Q.zero Build.east ]

/-- `branch_8` (compliant): A dry roadway, the subject going due east at 10 m/s, a car it follows 45 m ahead in its line at 10 m/s, and a truck standing still 10 m ahead in the same line with its body pointing due north, athwart the subject's course - a vehicle that crossed the way and came to rest across it. All bodies are 4 m long. The truck is at rest and the body it presents lies across the course, so it is no vehicle the subject follows, though it is counted in the traffic upon the highway; against the car it does follow, the 41 m of clear space exceeds the little over 20 m the dry headway and the two increments owe. Were the truck reckoned as followed, the 6 m of space to it would fall far short and the scene would be a violation. (The subject comes up on the halted truck from 30 m to the 10 m the narrative states.) -/
def branch_8Trace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m (-20)) Q.zero (mps 10) k
    , eastCar 2 (m 25) Q.zero (mps 10) k
    , restingTruck 3 (m 10) Q.zero Build.north ]

/-- `branch_9` (compliant): A dry roadway, the subject going due east at 10 m/s, a bicycle 15 m ahead of it in its line at 10 m/s, and a car 45 m ahead in the same line at 10 m/s. A bicycle is no member of the admitted aggregate the text's "vehicle" is read as, so it is not another vehicle followed, though it is counted in the traffic upon the highway; against the car, the 41 m of clear space exceeds the little over 20 m owed. Were the bicycle reckoned another vehicle, its 11 m of clear space would fall far short and the scene would be a violation. -/
def branch_9Trace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 10) k
    , eastBike 2 (m 15) Q.zero (mps 10) k
    , eastCar 3 (m 45) Q.zero (mps 10) k ]

/-- `branch_10` (violated): Ice or snow on a wet surface. The subject goes due east at 10 m/s with the leader's reference point 40 m ahead of its own in its line, bodies 4 m long, and no other traffic. The icy headway owes over 50 m against the 36 m of clear space left; the wet headway of the same scene would have owed about 31 m and the dry about 21 m, both of which that space meets, so it is the icy surface that decides. -/
def branch_10Trace : Trace :=
  traceOf icy ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 10) k
    , eastCar 2 (m 40) Q.zero (mps 10) k ]

/-- `branch_11` (compliant): A dry roadway, the subject going due east at 10 m/s with the leader's reference point 27 m ahead of its own in its line, bodies 4 m long, and three other cars on the same highway going east with it, two of them 80 m and 95 m ahead or behind to one hand and one 80 m behind, every one of them outside the reach about the subject. None of the three is counted in the traffic, so the space owed is a little over 20 m against the 23 m of clear space left; were a road user outside the reach counted, the space owed would exceed what is left and the scene would be a violation. -/
def branch_11Trace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 10) k
    , eastCar 2 (m 27) Q.zero (mps 10) k
    , eastCar 3 (m 80) (cm 350) (mps 10) k
    , eastCar 4 (m (-80)) (cm 350) (mps 10) k
    , eastCar 5 (m 95) (cm (-350)) (mps 10) k ]

/-- `branch_12` (compliant): A dry roadway with a second highway alongside it, 28 m to the north, which the subject's footprint never overlaps. The subject goes due east at 10 m/s with the leader's reference point 27 m ahead of its own in its line, bodies 4 m long, and three cars go east on that other highway, each within the reach about the subject but on no highway region the subject stands on. None of the three is counted in the traffic upon the subject's highway, so the space owed is a little over 20 m against the 23 m of clear space left; were a road user of another highway counted, the space owed would exceed what is left and the scene would be a violation. -/
def branch_12Trace : Trace :=
  traceOf dry [way, farWay] fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 10) k
    , eastCar 2 (m 27) Q.zero (mps 10) k
    , eastCar 3 (m 0) (m 28) (mps 10) k
    , eastCar 4 (m 10) (m 28) (mps 10) k
    , eastCar 5 (m (-10)) (m 28) (mps 10) k ]

/-- `branch_13` (violated): A dry roadway, the subject going due east at 20 m/s with a car 15 m ahead of it in its line that travels due east at 20 m/s with its body pointing due north - a car sliding broadside along the way. That car's own velocity fixes its direction of travel, so the way its body points is never read: it is a vehicle the subject travels behind, and the 11 m of clear space falls far short of the some 40 m the dry headway owes. Were the way a moving body points read as the at-rest limb reads the way a halted body lies, this scene would be left unengaged. -/
def branch_13Trace : Trace :=
  traceOf dry ground fun k =>
    [ eastCar 1 (m 0) Q.zero (mps 20) k
    , crabbingCar 2 (m 15) (mps 20) k ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_127_1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.extent"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .violated ]

end TrafficSpecWitness.NRS_484B_127_1
