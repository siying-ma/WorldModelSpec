/-
  Witnesses for NRS_484B_600_1a.

  The geometry, once for all the scenes below. A straight public way runs east: region 10, a
  rectangle 1000 m long and 20 m wide (`wayRegion`), of kind `highway`. Upon it lies one lane,
  region 20, the southern 10 m of the same rectangle (`laneRegion`), which carries the two figures
  the rule reads of a lane — the width the source reports at that place and the sight distance
  along the road there. The subject is track 1, a body 4 m long and 2 m wide, at (100 m, 5 m),
  heading east, inside both polygons, so `Build.scene` derives that it occupies the way and the
  lane. Other road users are placed on the same way east of it, or off the way at y = 60 m.
  Every scene is repeated at three instants one second apart; no formula of the rule looks back,
  so no padding and no window is needed.

  Every figure here is the witness's own and appears nowhere in the rule. Against the run's
  reading — dry 25, wet 20, ice 11, night 20 m/s, reference lane width 3.6 m, width-penalty time
  0.2 s, sight-clearance time 4 s, traffic reach 50 m, traffic decrement 1.5 m/s — the margins are:
  a long view is 400 m of sight distance (a bound of 100 m/s) and 600 m of visibility (150 m/s),
  so that in every scene but `branch_4` and `branch_5` the view and weather bounds are far above
  the speed and the scene turns on the bound it is about.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def kmh (n : Int) : Q := Units.kmh n

-- Binders ↦ tracks: v ↦ 1

/-- Half-length, half-width, half-height of a vehicle body. -/
def body : Q × Q × Q := (m 2, m 1, m 1)
/-- The same of a person on foot. -/
def personBody : Q × Q × Q := (cm 30, cm 30, m 2)

/-- The public way: region 10, 1000 m by 20 m. -/
def wayRegion : Structure := Build.rect 10 .highway (m 0) (m 0) (m 1000) (m 20)

/-- The lane upon it: region 20, the southern half of the way, with the width the source reports
    and the sight distance along the road at that place. -/
def laneRegion (width sight : Q) : Structure :=
  { Build.rect 20 .lane (m 0) (m 0) (m 1000) (m 10) with
      lane := some { direction := some Build.east, width := some width },
      sightDistance := some sight }

/-- A long view: the sight distance of an open straight road. -/
def longSight : Q := m 400
/-- Clear air. -/
def clearAir : Q := m 600
/-- A lane of the reference width (3.6 m in the run's reading). -/
def referenceWidth : Q := cm 360

/-- The weather and the light, every field of them observed. -/
def air (dark wet ice precip : Bool) (visibility : Q) : Env :=
  { darkness := some dark, wetRoad := some wet, iceOrSnow := some ice,
    precipitation := some precip, visibility := some visibility }

/-- Daylight, a dry surface, no precipitation, clear air. -/
def dryAir : Env := air false false false false clearAir

/-- The subject: a motor vehicle at (100 m, 5 m), heading east at `speed`. -/
def subjectAt (speed : Q) : RoadUser := Build.user 1 [.motorVehicle] (m 100, m 5) Build.east speed body

/-- Another road user standing on the way at `x`. -/
def standingAt (track : TrackId) (classes : List TrafficSpec.RoadUserClass) (x y : Q)
    (halfExtent : Q × Q × Q) : RoadUser :=
  Build.user track classes (x, y) Build.east Q.zero halfExtent

/-- Three instants one second apart of one unchanging scene. -/
def still (users : List RoadUser) (structures : List Structure) (env : Env) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures [] (env := env)

/-- `forbid` (violated): A single road user is in the scene: a motor vehicle, a class the definition of 'vehicle' includes. Its footprint overlaps a public way and a lane of that way whose width equals the reference lane width. The roadway carries no ice and no snow and is not wet, no precipitation falls, the natural light is sufficient, the visibility distance is long and the sight distance at its place is likewise long. No other road user is present, so the traffic about it is of no road users at all and the density allowance takes nothing from the bound. Its speed is far above the dry-surface free-flow speed and so above the least of the four bounds, none of which is at its floor. The rule reports violated. This is also the scenario in which no road user other than the binder is in the scene, and the duty is still decided. -/
def forbidTrace : Trace :=
  still [subjectAt (mps 40)] [wayRegion, laneRegion referenceWidth longSight] dryAir

/-- `permit` (compliant): The same single motor vehicle on the same public way and in the same lane, with the same dry surface, sufficient light, long visibility distance and long sight distance, and again no other road user in the scene. Its speed is well below the dry-surface free-flow speed and below the night, visibility and sight bounds as well. The rule reports compliant. -/
def permitTrace : Trace :=
  still [subjectAt (mps 10)] [wayRegion, laneRegion referenceWidth longSight] dryAir

/-- `idle` (not_applicable): The only road user in the scene is a motor vehicle, a class the definition of 'vehicle' includes, standing still with its engine running on a narrow icy strip of private ground: its footprint overlaps a lane region one metre wide whose surface carries ice, and it overlaps no public way at all - the scene holds no st.highway region its footprint lies in. There is therefore no highway whose traffic, surface, width, weather and other conditions the rate could be weighed against, the engagement condition of s5 fails, and the rule does not engage. The rule reports not_applicable. (This is the shape of the situation an earlier rule condemned: standing still where the composed bound had gone negative.) -/
def idleTrace : Trace :=
  still [Build.withKin (subjectAt Q.zero) fun k =>
          { k with engineRunning := some true, serviceBrake := some (Units.ratio 1 1) }]
    [laneRegion (m 1) (m 100)]
    (air false false true false clearAir)

/-- `blind` (unknown): A motor vehicle alone on a public way, in a lane of the reference width, with sufficient light, a long visibility distance and a long sight distance, and no other road user in the scene. The source does not observe whether the road surface is wet: env.wet_road is unobserved on this trace, while env.ice_or_snow is observed false and env.precipitation observed false. The vehicle's speed lies above the wet-surface free-flow speed and below the dry-surface one, and both selections give a bound well above the floor, so the surface bound decides the comparison one way if the surface is wet and the other way if it is dry, and the two selections do not agree. The rule reports unknown. -/
def blindTrace : Trace :=
  still [subjectAt (kmh 81)] [wayRegion, laneRegion referenceWidth longSight]
    { darkness := some false, wetRoad := none, iceOrSnow := some false,
      precipitation := some false, visibility := some clearAir }

/-- `branch_1` (violated): A motor vehicle alone on a dry public way, in a lane of the reference width, with a long visibility distance and a long sight distance, but the natural light is insufficient, so env.darkness holds. Its speed is below the dry-surface free-flow speed and above the night allowance. The night bound is the least of the four, and the rule reports violated. -/
def branch_1Trace : Trace :=
  still [subjectAt (kmh 81)] [wayRegion, laneRegion referenceWidth longSight]
    (air true false false false clearAir)

/-- `branch_2` (violated): A motor vehicle on a dry public way in a lane of the reference width, in sufficient light with a long visibility distance and a long sight distance, but four other road users - three motor vehicles and a pedestrian, all of them classes the traffic aggregate includes - overlap the same public way and stand within the traffic reach of it. Its speed is below the dry-surface free-flow speed but above that speed reduced by the decrement for each of those four, which is still well above the floor. The rule reports violated. -/
def branch_2Trace : Trace :=
  still
    [ subjectAt (kmh 81)
    , standingAt 2 [.motorVehicle] (m 110) (m 5) body
    , standingAt 3 [.motorVehicle] (m 120) (m 5) body
    , standingAt 4 [.motorVehicle] (m 130) (m 5) body
    , standingAt 5 [.pedestrian] (m 140) (m 5) personBody ]
    [wayRegion, laneRegion referenceWidth longSight] dryAir

/-- `branch_3` (violated): A motor vehicle alone on a dry public way in sufficient light, with a long visibility distance and a long sight distance, but the lane its footprint overlaps is narrower than the reference lane width. Its speed is below the dry-surface free-flow speed and above that speed less the cost of the missing width, which remains a positive rate. The rule reports violated. -/
def branch_3Trace : Trace :=
  still [subjectAt (mps 23)] [wayRegion, laneRegion (m 3) longSight] dryAir

/-- `branch_4` (violated): A motor vehicle alone on a dry public way in a lane of the reference width, in sufficient light, with a long sight distance at its place, but the air is thick with fog and the visibility distance is short. Its speed is below the dry-surface free-flow speed and above the visibility distance divided by the sight-clearance time. The rule reports violated. -/
def branch_4Trace : Trace :=
  still [subjectAt (kmh 72)] [wayRegion, laneRegion referenceWidth longSight]
    (air false false false false (m 60))

/-- `branch_5` (violated): A motor vehicle alone on a dry public way in a lane of the reference width, in sufficient light and clear air, but the sight distance at its place on the road is short, the road rising to a crest ahead of it. Its speed is below the dry-surface free-flow speed and above the sight distance divided by the sight-clearance time. The rule reports violated. -/
def branch_5Trace : Trace :=
  still [subjectAt (kmh 72)] [wayRegion, laneRegion referenceWidth (m 40)] dryAir

/-- `branch_6` (violated): A motor vehicle alone on a public way, in a lane of the reference width, in sufficient light with a long visibility distance and a long sight distance, on a roadway covered with snow and ice, so env.ice_or_snow holds. Its speed is below the wet-surface free-flow speed and above the icy one. The rule reports violated. -/
def branch_6Trace : Trace :=
  still [subjectAt (mps 15)] [wayRegion, laneRegion referenceWidth longSight]
    (air false false true false clearAir)

/-- `branch_7` (violated): A motor vehicle alone on a public way, in a lane of the reference width, in sufficient light with a long visibility distance and a long sight distance; rain is falling, so env.precipitation holds, although the source reports the surface as not yet wet and free of ice and snow. Its speed is below the dry-surface free-flow speed and above the wet-surface one. The rule reports violated. -/
def branch_7Trace : Trace :=
  still [subjectAt (kmh 81)] [wayRegion, laneRegion referenceWidth longSight]
    (air false false false true clearAir)

/-- `branch_8` (compliant): A motorcycle, a class the vehicle aggregate includes, stands still upon a public way: its footprint overlaps that way and a lane of it one metre wide, far narrower than the reference lane width, the surface carries ice and snow, the light is sufficient, the air clear and the sight distance at its place moderate. Its engine is running and its service brake is fully applied; its measured speed is nought. The width the lane lacks, costed at the width-penalty time, exceeds the icy free-flow speed, so the surface, traffic and width bound stands at its floor of none - and a rate of none is not greater than a rate of none. The night bound does not bind, and both the visibility and the sight bounds are far above nought. The rule reports compliant: no accumulation of adverse circumstances condemns a vehicle that is not moving. -/
def branch_8Trace : Trace :=
  still [Build.withKin (Build.user 1 [.motorcycle] (m 100, m 5) Build.east Q.zero body) fun k =>
          { k with engineRunning := some true, serviceBrake := some (Units.ratio 1 1) }]
    [wayRegion, laneRegion (m 1) (m 200)]
    (air false false true false clearAir)

/-- `branch_9` (violated): The same public way, the same one-metre icy lane, the same sufficient light, clear air and moderate sight distance, but the motorcycle is creeping forward at a few metres a second rather than standing. The surface, traffic and width bound is again at its floor of none, and its rate of speed is above it. The rule reports violated, so the floor permits only a vehicle that is not moving and does not excuse one that is. -/
def branch_9Trace : Trace :=
  still [Build.withKin (Build.user 1 [.motorcycle] (m 100, m 5) Build.east (mps 2) body) fun k =>
          { k with engineRunning := some true }]
    [wayRegion, laneRegion (m 1) (m 200)]
    (air false false true false clearAir)

/-- `branch_10` (compliant): A motor vehicle in a lane of the reference width on a dry public way in sufficient light with a long view, and two other road users that are not the traffic about it: one motor vehicle on the same way but far ahead, beyond the traffic reach, and one motor vehicle off the way, whose footprint overlaps no public way the vehicle overlaps. Neither counts, the density allowance takes nothing, and its speed stays below the dry-surface free-flow speed and below the other three bounds. The rule reports compliant. -/
def branch_10Trace : Trace :=
  still
    [ subjectAt (kmh 72)
    , standingAt 2 [.motorVehicle] (m 200) (m 5) body
    , standingAt 3 [.motorVehicle] (m 100) (m 60) body ]
    [wayRegion, laneRegion referenceWidth longSight] dryAir

/-- `branch_11` (violated): A motor vehicle alone on a public way in sufficient light with a long visibility distance; the surface is reported wet with standing water, although no rain or snow is falling and there is no ice, so env.wet_road alone selects the wet-surface free-flow speed. Its lane is of the reference width and the sight distance at its place is long. Its speed is above the wet-surface free-flow speed and below the dry one. The rule reports violated. -/
def branch_11Trace : Trace :=
  still [subjectAt (kmh 81)] [wayRegion, laneRegion referenceWidth longSight]
    (air false true false false clearAir)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_600_1a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["env.wet_road"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a
