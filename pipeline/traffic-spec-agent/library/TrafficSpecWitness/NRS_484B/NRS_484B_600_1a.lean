/-
  Witnesses for NRS_484B_600_1a.

  The geometry. One straight way running east, 4 km long about the origin:

    region 10  the highway H — the whole public way between its boundary lines, 20 m wide
               (y from −10 to 10);
    region 11  the roadway on its north half (y from 0 to 8), carrying the curvature of the bend;
    region 12  a travel lane on the roadway, its polygon as wide as the width it declares, laid
               from y = 0 northwards;
    region 13  a second lane north of it, used only by the straddling witness;
    region 14  a paved shoulder on the south half of H (y from −9 to −6), which lies on H
               (`ways := [10]`) and is neither lane nor roadway;
    region 20  a second highway, 25 m north of H, used only by the witness whose bystanders are on
               another way.

  The subject is track 1, a passenger car 4 m by 1.8 m carried at y = 1.8 m — inside the lane, the
  roadway and the highway — except on the shoulder witnesses, where it is carried at y = −7.5 m,
  inside H and the shoulder and inside no lane and no roadway. In `idle` the same place carries a
  bicycle, 1.8 m by 0.6 m. Each trace is three instants a second apart; the body advances by its
  own speed between them, its path length counted from the first instant. Bystanders are parked
  bodies of the traffic, each placed so that its centre distance to the subject stays inside or
  outside the interaction reach at every instant of the trace. Occupancy is read from the polygons
  except where a body straddles two regions or sits on the shoulder, where it is stated. No device
  is posted anywhere: this paragraph's standard reads no sign. The subject's view along the way is
  given per way (`sightAlongWay`), for H alone, which is the only way it ever occupies.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
/-- A horizontal curvature, as the reciprocal of the bend's radius in metres (1/m). -/
def bendOfRadius (r : Nat) : Q := Units.ratio 1 r
/-- A way that runs straight: no curvature at all. -/
def straight : Q := Q.zero
/-- A pedal or a brake applied through its whole travel. -/
def fullyApplied : Q := Units.ratio 1 1

-- Binders ↦ tracks: veh ↦ 1

/-- Half-extents: a passenger car, 4 m by 1.8 m by 1.5 m. -/
def carHalf : Q × Q × Q := (m 2, cm 90, cm 75)

/-- Half-extents: a bicycle, 1.8 m by 0.6 m by 1.2 m. -/
def bikeHalf : Q × Q × Q := (cm 90, cm 30, cm 60)

def wayWest : Q := m (-2000)
def wayEast : Q := m 2000

/-- The highway H: the whole way between its boundary lines, 20 m wide. -/
def highwayRegion : Structure := Build.rect 10 .highway wayWest (m (-10)) wayEast (m 10)

/-- A second highway, well north of H and never occupied by the subject. -/
def otherHighway : Structure := Build.rect 20 .highway wayWest (m 25) wayEast (m 45)

/-- The roadway on the north half of H, carrying the curvature of the bend at its point. -/
def roadwayOf (curv : Q) : Structure :=
  { Build.rect 11 .roadway wayWest Q.zero wayEast (m 8) with curvature := some curv }

/-- A travel lane from `y0` to `y1`, declaring the width `w` it is laid out to. -/
def laneOf (id : RegionId) (y0 y1 w : Q) : Structure :=
  { Build.region id .lane [ (wayWest, y0), (wayEast, y0), (wayEast, y1), (wayWest, y1) ] with
      lane := some { direction := some Build.east, width := some w } }

/-- The paved shoulder on the south half of H, which lies on H and is no lane and no roadway. -/
def shoulderRegion : Structure :=
  { Build.rect 14 .shoulder wayWest (m (-9)) wayEast (m (-6)) with
      paved := some true, ways := some [10] }

/-- A way with one lane of the given width, and the bend at the roadway's point. -/
def oneLaneWay (laneW curv : Q) : List Structure :=
  [ highwayRegion, roadwayOf curv, laneOf 12 Q.zero laneW laneW ]

/-- The same way, with a second lane north of the first: the straddling witness's two lanes. -/
def twoLaneWay : List Structure :=
  [ highwayRegion, roadwayOf straight, laneOf 12 Q.zero (cm 360) (cm 360),
    laneOf 13 (cm 360) (m 6) (cm 240) ]

/-- The way with its paved shoulder: a lane and a roadway are there, off to the subject's north. -/
def shoulderWay : List Structure :=
  [ highwayRegion, roadwayOf straight, laneOf 12 Q.zero (m 4) (m 4), shoulderRegion ]

/-- The subject on the shoulder: it overlaps H and the shoulder and no lane and no roadway. -/
def shoulderOccupancy : List (TrackId × RegionId) := [(1, 10), (1, 14)]

/-- The straddling subject: it overlaps H, the roadway and both lanes. -/
def straddleOccupancy : List (TrackId × RegionId) := [(1, 10), (1, 11), (1, 12), (1, 13)]

/-- The observed conditions of the scene. -/
def conditionsOf (dark precip wet ice : Bool) (vis : Q) : Env :=
  { darkness := some dark, precipitation := some precip, wetRoad := some wet,
    iceOrSnow := some ice, visibility := some vis }

/-- A dry, clear, snow-free day, with the air seeing `vis`. -/
def clearDay (vis : Q) : Env := conditionsOf false false false false vis

/-- How far the body has run from the first instant, at its own speed, a second apart. -/
def along (k : Nat) (v : Q) : Q := Q.mul (Q.ofInt (Int.ofNat k)) v

/-- The subject at the `k`-th instant: a body of `classes` at lateral place `y`, running east at
    `v`, which can see `sight` along the highway H. -/
def subjectAt (classes : List RoadUserClass) (half : Q × Q × Q) (y v sight : Q) (k : Nat) : RoadUser :=
  { Build.user 1 classes (along k v, y) Build.east v half (pathLength := some (along k v)) with
      sightAlongWay := some [(10, sight)] }

/-- The subject as a passenger car in the lane. -/
def carOn (v sight : Q) (k : Nat) : RoadUser := subjectAt [.motorVehicle] carHalf (cm 180) v sight k

/-- The subject as a passenger car on the shoulder. -/
def carOnShoulder (v sight : Q) (k : Nat) : RoadUser :=
  subjectAt [.motorVehicle] carHalf (cm (-750)) v sight k

/-- The subject as a bicycle in the lane. -/
def bikeOn (v sight : Q) (k : Nat) : RoadUser := subjectAt [.bicycle] bikeHalf (cm 180) v sight k

/-- The subject standing still in the lane, its service brake fully applied and its engine
    running. -/
def haltedCar (sight : Q) (k : Nat) : RoadUser :=
  Build.withKin (subjectAt [.motorVehicle] carHalf (cm 180) Q.zero sight k) fun kn =>
    { kn with serviceBrake := some fullyApplied, engineRunning := some true }

/-- A parked body of the traffic at a place of the scene. -/
def bystander (track : TrackId) (x y : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) Build.east Q.zero carHalf (pathLength := some Q.zero)

/-- A scene of this way: the subject, the bystanders, the regions, the stated occupancy and the
    observed conditions. No device is posted. -/
def sceneOf (mk : Nat → RoadUser) (structs : List Structure)
    (occ : Option (List (TrackId × RegionId))) (e : Env) (others : List RoadUser)
    (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1) (mk k :: others) structs [ ] occ e

/-- Three instants, a second apart. -/
def threeInstants (f : Nat → Timestamp → Scene) : Trace := Build.trace 3 0 (Units.seconds 1) f

/-- `forbid` (violated): A passenger car, a class the reading includes in DEF-NRS-484A-320::vehicle, travels at kin.speed 25 m/s on a two-lane highway H it occupies (rel.occupies) in a lane L of st.lane_width 2.8 m. env.ice_or_snow and env.precipitation hold, env.darkness holds, env.visibility is 40 m and st.sight_along_way 60 m. The ice and precipitation reductions, the darkness reduction and the narrow-lane scaling put the condition bound at its floor, far below 25 m/s, and the distance needed to stop from 25 m/s exceeds the 40 m that can be seen: violated. -/
def forbidTrace : Trace :=
  threeInstants (sceneOf (carOn (mps 25) (m 60)) (oneLaneWay (cm 280) straight) none
    (conditionsOf true true false true (m 40)) [ ])

/-- `permit` (compliant): The same car travels at kin.speed 20 m/s on highway H in a lane of st.lane_width 3.6 m, the only lane and the only roadway its footprint overlaps. env.wet_road, env.ice_or_snow, env.precipitation and env.darkness are all observed false, env.visibility is 2000 m, st.sight_along_way 400 m, st.curvature at its point 0.0005 1/m, and two other road users of DEF-NRS-484A-285::traffic lie on H within the interaction reach of it. The condition bound stays above 20 m/s, the stopping distance at 20 m/s fits well inside both the air's visibility and the view along H, and the lateral acceleration on the gentle bend stays below the comfortable bound: compliant. -/
def permitTrace : Trace :=
  threeInstants (sceneOf (carOn (mps 20) (m 400)) (oneLaneWay (cm 360) (bendOfRadius 2000)) none
    (clearDay (m 2000)) [ bystander 2 (m 50) (cm 180), bystander 3 (m (-50)) (cm 180) ])

/-- `idle` (not_applicable): The subject is a bicycle, a device moved by human power, which the words of NRS 484A.320 exclude and the reading classes as excluded from DEF-NRS-484A-320::vehicle. It coasts downhill at kin.speed 14 m/s in a 2.6 m lane with env.visibility 30 m. ru.aggregate is false for the subject, so the prohibition does not engage: not_applicable. -/
def idleTrace : Trace :=
  threeInstants (sceneOf (bikeOn (mps 14) (m 30)) (oneLaneWay (cm 260) straight) none
    (clearDay (m 30)) [ ])

/-- `blind` (unknown): A passenger car travels at kin.speed 20 m/s on a dry, straight, standard-width lane of highway H in daylight, with env.wet_road, env.ice_or_snow, env.precipitation and env.darkness all observed false and st.sight_along_way 500 m, but the source's capability manifest declares env.visibility absent. The condition bound and the curve bound are decided and met, yet the air's clarity cannot be read, so the stopping-distance conjunct is unknown and the rule reports unknown. -/
def blindTrace : Trace :=
  threeInstants (sceneOf (carOn (mps 20) (m 500)) (oneLaneWay (cm 360) straight) none
    (clearDay (m 2000)) [ ])

/-- `branch_1` (violated): The subject is the only road user in the scene: no road user of DEF-NRS-484A-285::traffic is anywhere on the highway. It travels at kin.speed 45 m/s on a dry, straight lane of st.lane_width 3.6 m in daylight, env.visibility 2000 m and st.sight_along_way 1500 m. The traffic term is nil and no condition reduces the bound, yet 45 m/s exceeds the base bound: violated, so the duty is shown to bind the subject with no other party in the scene. -/
def branch_1Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 45) (m 1500)) (oneLaneWay (cm 360) straight) none
    (clearDay (m 2000)) [ ])

/-- `branch_11` (compliant): A passenger car moves at kin.speed 1 m/s along a paved shoulder that lies on highway H (st.shoulder, st.on_way), occupying H and the shoulder and no st.lane and no st.roadway at all. It is the only road user; env.darkness, env.precipitation, env.wet_road and env.ice_or_snow are all observed false, env.visibility is 1000 m and st.sight_along_way along H 1000 m. With no lane under it the width factor is the standard width, so the condition bound is the base bound; the stopping distance at 1 m/s is a few metres against 1000 m seen; with no roadway under it no curvature is read. Compliant: occupying neither a lane nor a roadway neither condemns the subject nor withholds the judgement. -/
def branch_11Trace : Trace :=
  threeInstants (sceneOf (carOnShoulder (mps 1) (m 1000)) shoulderWay (some shoulderOccupancy)
    (clearDay (m 1000)) [ ])

/-- `branch_12` (compliant): A passenger car stands still on a straight lane of st.lane_width 2.4 m with kin.speed 0 m/s, its service brake fully applied and its engine running; env.darkness, env.precipitation, env.wet_road and env.ice_or_snow all hold, env.visibility is 1000 m and st.sight_along_way 1000 m, st.curvature 0 1/m, and it is the only road user. The narrow-lane scaling and the summed wet, ice and darkness reductions would bring the raw condition bound below nothing, but the bound is read as at least p.reasonable_speed_floor, which a halt does not exceed; the stopping distance from rest is nil and the lateral acceleration nil. Compliant: a halt is no rate of speed greater than reasonable or proper, however adverse the conditions. -/
def branch_12Trace : Trace :=
  threeInstants (sceneOf (haltedCar (m 1000)) (oneLaneWay (cm 240) straight) none
    (conditionsOf true true true true (m 1000)) [ ])

/-- `branch_13` (violated): The same paved shoulder of branch_11, and the same dry, clear, empty daylight scene with env.visibility 2000 m and st.sight_along_way 1500 m, but the car runs along the shoulder at kin.speed 40 m/s, occupying no st.lane and no st.roadway. The width factor is the standard width and no condition reduces the bound, yet 40 m/s exceeds the base bound: violated. Together with branch_11 this shows the bound still binds off the lane and the roadway, rather than being vacuous there. -/
def branch_13Trace : Trace :=
  threeInstants (sceneOf (carOnShoulder (mps 40) (m 1500)) shoulderWay (some shoulderOccupancy)
    (clearDay (m 2000)) [ ])

/-- `branch_14` (violated): A passenger car travels at kin.speed 22 m/s on a dry, straight, clear daylight highway H, env.visibility 2000 m and st.sight_along_way 1000 m, its footprint straddling two lanes it occupies: one of st.lane_width 3.6 m and one of st.lane_width 2.4 m. The bound at the standard-width lane would admit 22 m/s, but the bound at the 2.4 m lane does not, and every lane the subject occupies bounds its speed: violated, which pins the reading that the narrowest lane under the subject governs. -/
def branch_14Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 22) (m 1000)) twoLaneWay (some straddleOccupancy)
    (clearDay (m 2000)) [ ])

/-- `branch_15` (compliant): The car travels at kin.speed 25 m/s on a dry, clear, straight lane laid out 5 m wide — wider than the standard lane width — with env.visibility 2000 m and st.sight_along_way 1000 m, alone on the way. The width ratio is capped at one, so the generous lane does not raise the bound above the base speed, and 25 m/s is inside it: compliant. This is the scene in which the cap on the width ratio is the branch taken. -/
def branch_15Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 25) (m 1000)) (oneLaneWay (m 5) straight) none
    (clearDay (m 2000)) [ ])

/-- `branch_16` (violated): The car travels at kin.speed 25 m/s on a standard-width straight lane in daylight, alone on the way, with env.visibility 2000 m and st.sight_along_way 1000 m, but env.wet_road holds while env.precipitation, env.ice_or_snow and env.darkness are all observed false. The wet-pavement reduction alone brings the bound below 25 m/s: violated, so the wet surface is shown to move the bound on its own. -/
def branch_16Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 25) (m 1000)) (oneLaneWay (cm 360) straight) none
    (conditionsOf false false true false (m 2000)) [ ])

/-- `branch_17` (compliant): The car travels at kin.speed 29 m/s on a dry, clear, straight standard-width lane of H, env.visibility 2000 m and st.sight_along_way 1000 m, with one other road user of the traffic 400 m away along H — outside the interaction reach at every instant. The traffic term is nil, so the bound is the base bound and 29 m/s is inside it: compliant. A road user beyond the reach is shown not to lower the bound, and the subject is shown not to count itself among the traffic. -/
def branch_17Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 29) (m 1000)) (oneLaneWay (cm 360) straight) none
    (clearDay (m 2000)) [ bystander 2 (m 400) (cm 180) ])

/-- `branch_18` (compliant): The same car at kin.speed 29 m/s on H, with two road users of the traffic standing within 100 m of it but on region 20, a second highway the subject's footprint does not overlap. The traffic the bound reads is the traffic on a way the subject is on, so the term is nil and 29 m/s is inside the base bound: compliant. -/
def branch_18Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 29) (m 1000)) (oneLaneWay (cm 360) straight ++ [otherHighway])
    none (clearDay (m 2000)) [ bystander 2 Q.zero (m 35), bystander 3 (m 60) (m 35) ])

/-- `branch_19` (violated): The same car at kin.speed 29 m/s on the same dry, clear, straight way, but one road user of the traffic stands on H 50 m from it, inside the interaction reach at every instant. The single speed-flow reduction brings the bound just below 29 m/s: violated, so the traffic term is shown to bind by how many road users are within reach. -/
def branch_19Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 29) (m 1000)) (oneLaneWay (cm 360) straight) none
    (clearDay (m 2000)) [ bystander 2 (m 50) (cm 180) ])

/-- `branch_20` (violated): The car travels at kin.speed 25 m/s on a dry, clear, straight standard-width lane, alone on the way, with env.visibility 2000 m — the air seeing far — but st.sight_along_way along H only 100 m, the way bending out of view. The distance needed to stop from 25 m/s exceeds the 100 m that can be seen along the way: violated, so the view along the way is shown to bind even where the air is clear. -/
def branch_20Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 25) (m 100)) (oneLaneWay (cm 360) straight) none
    (clearDay (m 2000)) [ ])

/-- `branch_21` (violated): The car travels at kin.speed 20 m/s on a dry, clear standard-width lane with env.visibility 2000 m and st.sight_along_way 1000 m, alone on the way, but the roadway under it bends at st.curvature 0.01 1/m, a 100 m radius. The condition bound and the sight bound are both met, yet the lateral acceleration 20 m/s develops on that bend exceeds the comfortable bound: violated, so the bend is shown to bind on its own. -/
def branch_21Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 20) (m 1000)) (oneLaneWay (cm 360) (bendOfRadius 100)) none
    (clearDay (m 2000)) [ ])

/-- `branch_22` (violated): The car travels at kin.speed 20 m/s on a dry, clear, straight standard-width lane, alone on the way, with env.visibility 2000 m and st.sight_along_way 1000 m, but env.ice_or_snow holds while env.wet_road, env.precipitation and env.darkness are all observed false. The winter-surface reduction alone brings the bound below 20 m/s: violated. -/
def branch_22Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 20) (m 1000)) (oneLaneWay (cm 360) straight) none
    (conditionsOf false false false true (m 2000)) [ ])

/-- `branch_23` (violated): The car travels at kin.speed 25 m/s on a dry, straight standard-width lane, alone on the way, with env.visibility 2000 m and st.sight_along_way 1000 m, but env.darkness holds while env.wet_road, env.precipitation and env.ice_or_snow are all observed false. The night-driving reduction alone brings the bound below 25 m/s: violated. -/
def branch_23Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 25) (m 1000)) (oneLaneWay (cm 360) straight) none
    (conditionsOf true false false false (m 2000)) [ ])

/-- `branch_24` (violated): The car travels at kin.speed 25 m/s on a straight standard-width lane in daylight on a dry surface, alone on the way, with env.visibility 2000 m and st.sight_along_way 1000 m, but env.precipitation holds: rain is falling on a surface not yet observed wet. The wet-pavement reduction is taken for the falling rain alone and brings the bound below 25 m/s: violated. -/
def branch_24Trace : Trace :=
  threeInstants (sceneOf (carOn (mps 25) (m 1000)) (oneLaneWay (cm 360) straight) none
    (conditionsOf false true false false (m 2000)) [ ])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("veh", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["env.visibility"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .violated
  , witness "branch_14" branch_14Trace .violated
  , witness "branch_15" branch_15Trace .compliant
  , witness "branch_16" branch_16Trace .violated
  , witness "branch_17" branch_17Trace .compliant
  , witness "branch_18" branch_18Trace .compliant
  , witness "branch_19" branch_19Trace .violated
  , witness "branch_20" branch_20Trace .violated
  , witness "branch_21" branch_21Trace .violated
  , witness "branch_22" branch_22Trace .violated
  , witness "branch_23" branch_23Trace .violated
  , witness "branch_24" branch_24Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a
