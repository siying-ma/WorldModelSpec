/-
  Witnesses for NRS_484B_603_1_o1.

  The carriageway runs east along y = 0 inside a highway (region 30, y from −40 to 40 m): a roadway
  (10, y from −2 to 6 m) carrying two eastbound lanes, lane 11 (y −2…2, the subject's) and lane 12
  (y 2…6), each 3.5 m wide unless stated and lying on the highway. On the approach scenes the
  roadway and lanes end at x = 300 m where intersection 20 (x 300…320) begins, and lane 11 enters
  it. On the open scenes the roadway runs on to x = 1200 m and there is no intersection.

  The subject (track 1) is a car (half-extents 2.25 × 0.90 × 0.75 m) driving east from x = 0 at a
  steady speed; its path length is its x. Dry weather: no precipitation, dry, no ice, visibility
  1000 m unless stated. Stopping distance D = v·1.5 + v²/(2a) with the run's reading.

  Short scenes: three instants 0.5 s apart. Long scenes ("long"): fourteen instants 1 s apart,
  judged over 0…2 s only (`window`), so the 150 m curve window ahead is covered at every judged
  instant and the curve condition is decided.

    forbid   20 m/s on the approach, sight 40 m: D = 30 + 33.3 = 63.3 m > 40 m.
    permit   10 m/s on the approach, sight 40 m: D = 15 + 8.3 = 23.3 m < 40 m.
    blind    as forbid, the sight distance masked.
    idle     long, 15 m/s on the open road, curvature 0, lane 3.5 m, sight 200 m (below the 1000 m
             visibility); a crest 1000 m ahead, debris 600 m ahead on lane 12, cones governing lane
             12 only, a pedestrian standing on the verge 50 m behind (y = 8 m, off the roadway).
    branch_1 long, 20 m/s on a roadway without mapped lanes, curvature 1/100 m: v²κ = 4 > 3 m/s²;
             sight 1000 m. The bend is the only condition.
    branch_2 13 m/s on the approach, icy, sight 60 m: D = 19.5 + 84.5 = 104 m > 60 m (dry 33.6 m).
    branch_3 15 m/s on the open road, sight 200 m; a pedestrian (track 2) at x = 22.55 m, y = −1 m
             walking north at 1 m/s: closest approach ≈ 0.5 m after ≈ 1.5 s, surface gap 20 m,
             D = 41.25 m > 20 m.
    branch_4 crossing: the car is inside a large intersection (x −20…40) and on no roadway, 20 m/s,
             fog with visibility 40 m: D = 63.3 m > 40 m. Being in the intersection is the only
             condition decided true.
    branch_5 long, divided highway: the subject's roadway 10 is straight (sight 200 m) with wide
             lanes; the other carriageway, roadway 13 (y 10…18), bends (1/100 m), has sight 300 m
             and a pedestrian standing on it 50 m behind; visibility 250 m. Nothing holds for the
             subject's own place: not applicable.
    branch_6 long, 20 m/s in a 2.8 m lane on the highway, straight, sight 40 m: D = 63.3 m > 40 m;
             the narrow lane is the only condition.
    branch_7 long, 20 m/s on the open road towards a crest at x 115…125 m (reference point x = 120),
             sight 40 m: D = 63.3 m > 40 m; the crest ahead is the only condition.
    branch_8 long, 15 m/s, sight 200 m; a bicycle (track 3) 20 m ahead (surface gap) riding east at
             3 m/s: centres meet within ≈ 1.7 s, D = 41.25 m > 20 m; the conflict is the only
             condition (a bicycle is traffic, not a pedestrian).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_603_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_603_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- Seconds since the trace start at instant `k` of a trace sampled every `stepMs` ms. -/
def secondsAt (k : Nat) (stepMs : Int) : Q := Units.milliseconds ((k : Int) * stepMs)

/-- The subject: a car at `x` on y = 0, heading east at `v`; its path length is `x`. -/
def car (x v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, Q.zero) Build.east v (cm 225, cm 90, cm 75) (some x)

def dryEnv : Env :=
  { precipitation := some false, wetRoad := some false, iceOrSnow := some false
    visibility := some (m 1000) }

def icyEnv : Env := { dryEnv with iceOrSnow := some true }

def highway : Structure := Build.rect 30 .highway (m (-200)) (m (-40)) (m 1200) (m 40)

def roadwayAt (id : RegionId) (y0 y1 x1 κ sd : Q) : Structure :=
  { Build.rect id .roadway (m (-100)) y0 x1 y1 with
    curvature := some κ, sightDistance := some sd, ways := some [30] }

def roadway (x1 κ sd : Q) : Structure := roadwayAt 10 (m (-2)) (m 6) x1 κ sd

def laneOf (id : RegionId) (y0 y1 x1 w : Q) (enters : Option RegionId) : Structure :=
  let l := Build.lane id [(m (-100), y0), (x1, y0), (x1, y1), (m (-100), y1)] Build.east (enters := enters)
  { l with ways := some [30], lane := l.lane.map fun li => { li with width := some w } }

def intersection : Structure :=
  { Build.rect 20 .intersection (m 300) (m (-10)) (m 320) (m 10) with ways := some [30] }

/-- The approach to intersection 20: lane 11 enters it. -/
def approachStructures (sd : Q) : List Structure :=
  [ roadway (m 300) Q.zero sd, laneOf 11 (m (-2)) (m 2) (m 300) (cm 350) (some 20),
    laneOf 12 (m 2) (m 6) (m 300) (cm 350) none, intersection, highway ]

/-- The open road: no intersection; lanes of width `w`. -/
def openStructuresW (κ sd w : Q) : List Structure :=
  [ roadway (m 1200) κ sd, laneOf 11 (m (-2)) (m 2) (m 1200) w none,
    laneOf 12 (m 2) (m 6) (m 1200) w none, highway ]

def openStructures (κ sd : Q) : List Structure := openStructuresW κ sd (cm 350)

/-- The car approaching the intersection at `v`, three instants 0.5 s apart. -/
def approachTrace (v sd : Q) (env : Env) : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1) [car (Q.mul v (secondsAt k 500)) v] (approachStructures sd) [] (env := env)

/-- A long scene: fourteen instants 1 s apart; `others` gives the other road users at time `s`. -/
def longTrace (v : Q) (structs : List Structure) (devices : List Device)
    (others : Q → List RoadUser) (env : Env) : Trace :=
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    let s := secondsAt k 1000
    Build.scene t (some 1) (car (Q.mul v s) v :: others s) structs devices (env := env)

/-- The judged instants of a long scene. -/
def early : Option (Timestamp × Timestamp) := some (0, 2000)

/-- `forbid` (violated): A car occupies a lane that enters an intersection on a dry, straight roadway with no precipitation; the sight distance at its place is 40 m and the visibility is long; it travels at 20 m/s, so its stopping distance at the dry deceleration exceeds 40 m. -/
def forbidTrace : Trace := approachTrace (Units.metresPerSecond 20) (m 40) dryEnv

/-- `permit` (compliant): The same approach at 10 m/s: the stopping distance at the dry deceleration is below the 40 m sight distance and the visibility; no road user is in conflict. -/
def permitTrace : Trace := approachTrace (Units.metresPerSecond 10) (m 40) dryEnv

/-- `idle` (not_applicable): A car travels on a dry, straight, wide-laned roadway between intersections, no crest ahead within reach, no pedestrian on the roadway, no road user in conflict, no obstruction or temporary traffic control, visibility longer than the sight distance. -/
def idleTrace : Trace :=
  let crest : Structure := { Build.rect 60 .crest (m 995) (m (-20)) (m 1005) (m 20) with position := some (m 1000, Q.zero) }
  let debris : Structure := { Build.rect 40 .obstruction (m 600) (m 4) (m 601) (m 5) with obstructionKind := some .debris }
  let cones : Device := Build.device 50 .temporaryTrafficControl [12]
  let walker : RoadUser := Build.user 2 [.pedestrian] (m (-50), m 8) Build.north Q.zero (cm 30, cm 30, cm 90)
  longTrace (Units.metresPerSecond 15) (openStructures Q.zero (m 200) ++ [crest, debris]) [cones]
    (fun _ => [walker]) dryEnv

/-- `blind` (unknown): As in forbid, but the source does not observe the sight distance at the car's place; the curvature is zero and no road user is in conflict, so the verdict turns on the unobserved sight distance. -/
def blindTrace : Trace := approachTrace (Units.metresPerSecond 20) (m 40) dryEnv

/-- `branch_1` (violated): A car on a roadway with curvature 0.01 1/m (a 100 m radius) at 20 m/s on a dry road with long sight distance: v squared times curvature exceeds the curve lateral-acceleration bound. -/
def branch_1Trace : Trace :=
  let κ := Q.div (Units.perMetre 1) (m 100)
  longTrace (Units.metresPerSecond 20) [roadway (m 1200) κ (m 1000), highway] [] (fun _ => []) dryEnv

/-- `branch_2` (violated): A car approaches an intersection at 13 m/s on an icy road with a 60 m sight distance: its stopping distance at the ice deceleration exceeds 60 m, though at the dry deceleration it would not. -/
def branch_2Trace : Trace := approachTrace (Units.metresPerSecond 13) (m 60) icyEnv

/-- `branch_3` (violated): A car on a dry straight road at 15 m/s with long sight distance; a pedestrian ahead walks so that its centre comes within the conflict clearance of the car's within the conflict horizon, and the surface gap is 20 m, shorter than the car's stopping distance. -/
def branch_3Trace : Trace :=
  let v := Units.metresPerSecond 15
  let w := Units.metresPerSecond 1
  Build.trace 2 0 (Units.milliseconds 500) fun k t =>
    let s := secondsAt k 500
    Build.scene t (some 1)
      [ car (Q.mul v s) v
      , Build.user 2 [.pedestrian] (cm 2255, Q.add (m (-1)) (Q.mul w s)) Build.north w (cm 30, cm 30, cm 90) ]
      (openStructures Q.zero (m 200)) [] (env := dryEnv)

/-- `branch_4` (violated): crossing — the car is inside an intersection and on no roadway, at 20 m/s
    in fog with 40 m visibility; its stopping distance exceeds the visibility. -/
def branch_4Trace : Trace :=
  let v := Units.metresPerSecond 20
  let bigIntersection : Structure :=
    { Build.rect 20 .intersection (m (-20)) (m (-10)) (m 40) (m 10) with ways := some [30] }
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1) [car (Q.mul v (secondsAt k 500)) v] [bigIntersection, highway] []
      (env := { dryEnv with visibility := some (m 40) })

/-- `branch_5` (not_applicable): divided highway — the other carriageway bends, offers a longer
    sight distance than the visibility and has a pedestrian on it; the subject's own roadway is
    straight, dry, wide-laned and clear. -/
def branch_5Trace : Trace :=
  let κ := Q.div (Units.perMetre 1) (m 100)
  let walker : RoadUser := Build.user 2 [.pedestrian] (m (-50), m 14) Build.north Q.zero (cm 30, cm 30, cm 90)
  longTrace (Units.metresPerSecond 15)
    (openStructures Q.zero (m 200) ++ [roadwayAt 13 (m 10) (m 18) (m 1200) κ (m 300)]) []
    (fun _ => [walker]) { dryEnv with visibility := some (m 250) }

/-- `branch_6` (violated): a straight highway with 2.8 m lanes at 20 m/s and a 40 m sight distance;
    the narrow lane is the only condition and the stopping distance exceeds the sight. -/
def branch_6Trace : Trace :=
  longTrace (Units.metresPerSecond 20) (openStructuresW Q.zero (m 40) (cm 280)) [] (fun _ => []) dryEnv

/-- `branch_7` (violated): a crest 115 m ahead at 20 m/s, sight distance 40 m; the crest is the only
    condition and the stopping distance exceeds the sight. -/
def branch_7Trace : Trace :=
  let crest : Structure := { Build.rect 60 .crest (m 115) (m (-2)) (m 125) (m 6) with position := some (m 120, Q.zero) }
  longTrace (Units.metresPerSecond 20) (openStructures Q.zero (m 40) ++ [crest]) [] (fun _ => []) dryEnv

/-- `branch_8` (violated): a bicycle 20 m ahead riding at 3 m/s while the car does 15 m/s; the
    conflict is the only condition and the stopping distance exceeds the surface gap. -/
def branch_8Trace : Trace :=
  let vb := Units.metresPerSecond 3
  longTrace (Units.metresPerSecond 15) (openStructures Q.zero (m 200)) []
    (fun s => [Build.user 3 [.bicycle] (Q.add (cm 2315) (Q.mul vb s), Q.zero) Build.east vb (cm 90, cm 30, cm 80)])
    dryEnv

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_603_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable (window := early)
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"]
  , witness "branch_1" branch_1Trace .violated (window := early)
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable (window := early)
  , witness "branch_6" branch_6Trace .violated (window := early)
  , witness "branch_7" branch_7Trace .violated (window := early)
  , witness "branch_8" branch_8Trace .violated (window := early) ]

end TrafficSpecWitness.NRS_484B_603_1_o1
