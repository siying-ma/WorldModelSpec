/-
  Witnesses for NRS_484B_600_1a.

  The geometry is the same straight way in every scene: one highway region 600 m long and 20 m wide
  (region 1), and inside it one eastbound lane (region 2) whose polygon is the declared width about
  the centre line, whose `LaneInfo.width` is the width the source maps there and whose
  `sightDistance` is the view the road affords at that place. The subject is track 1 at the origin,
  heading east; other road users stand on the same way ahead of it, so that each is within the
  highway region the subject occupies and at a centre distance the scene states by its position.
  Every scene is repeated at three instants one second apart; the rule looks back nowhere, so no
  scenario names a window.

  Every figure here is the witness's own and appears nowhere in the rule: the speeds and widths are
  chosen to break or keep each bound the reading's values set by a clear margin (the reading has
  p.speed_dry 25 m/s, p.speed_wet 20, p.speed_ice 11, p.speed_dark 20, p.speed_resolution 0.2 m/s,
  p.reference_lane_width 3.6 m, p.width_penalty_time 0.2 s, p.traffic_reach 50 m,
  p.traffic_speed_decrement 1.5 m/s, p.sight_clearance_time 4 s).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

/-- The whole way between its boundary lines. -/
def highway : Structure := Build.rect 1 .highway (m (-300)) (m (-10)) (m 300) (m 10)

/-- The one eastbound lane of that way: its polygon is `width` wide about the centre line, the
    source maps `width` to it and `sight` is the distance that can be seen along the road there. -/
def laneAt (width sight : Q) : Structure :=
  let half := Q.div width (Q.ofInt 2)
  { Build.rect 2 .lane (m (-300)) (Q.neg half) (m 300) half with
      lane := some { direction := some Build.east, width := some width }
      sightDistance := some sight }

/-- A passenger car at a place on the way, heading east. -/
def carAt (track : TrackId) (pos : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos Build.east speed (m 2, cm 90, cm 75)

/-- A passenger car on the centre line of the lane, heading east. -/
def car (track : TrackId) (x : Q) (speed : Q) : RoadUser := carAt track (x, Q.zero) speed

/-- A pedal bicycle, a device moved by human power: no class the reading includes under
    DEF-NRS-484A-320::vehicle, and one it includes under DEF-NRS-484A-285::traffic. -/
def bike (track : TrackId) (x : Q) (speed : Q) : RoadUser :=
  Build.user track [.bicycle] (x, Q.zero) Build.east speed (m 1, cm 30, cm 90)

/-- A person on foot upon the way. -/
def walker (track : TrackId) (x : Q) : RoadUser :=
  Build.user track [.pedestrian] (x, Q.zero) Build.east (mps 1) (cm 30, cm 30, cm 90)

def envOf (dark precip wet ice : Bool) (vis : Q) : Env :=
  { darkness := some dark, precipitation := some precip, wetRoad := some wet,
    iceOrSnow := some ice, visibility := some vis }

/-- Daylight, a dry surface, clear air. -/
def dryDay : Env := envOf false false false false (m 500)

def sceneOf (t : Timestamp) (users : List RoadUser) (width sight : Q) (e : Env) : Scene :=
  Build.scene t (some 1) users [highway, laneAt width sight] [] none e

-- Binders ↦ tracks: v ↦ 1

/-- `forbid` (violated): One track only, a passenger car whose class the reading includes under DEF-NRS-484A-320::vehicle; no other road user is in the scene, so the traffic count about it is zero and the duty is decided on the subject alone. Its footprint overlaps a lane that lies within a highway region it also overlaps; st.lane_width at its place is at p.reference_lane_width, so no width deficit is owed. env.wet_road, env.ice_or_snow, env.precipitation and env.darkness are all observed false; env.visibility and st.sight_distance are both long, far above the bounds p.sight_clearance_time makes of them. kin.speed is far above p.speed_dry, hence above the least bound. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 40)] (cm 360) (m 500) dryDay

/-- `permit` (compliant): The same car on the same lane at reference width, alone in the scene, in daylight; env.wet_road is observed true and env.ice_or_snow false, so the baseline is p.speed_wet. env.visibility and st.sight_distance are long. kin.speed is well below p.speed_wet, and below every other bound, so the rate of speed is within the reasonable-and-proper bound. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 12)] (cm 360) (m 500)
      (envOf false false true false (m 500))

/-- `idle` (not_applicable): The only track is a pedal bicycle, a device moved by human power and so a class the reading excludes from DEF-NRS-484A-320::vehicle. It runs at a kin.speed above p.speed_dry on a lane whose st.lane_width is well below p.reference_lane_width, in darkness. The subject's aggregate membership is false, so the rule is not engaged. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [bike 1 (m 0) (mps 30)] (m 2) (m 500)
      (envOf true false false false (m 500))

/-- `blind` (unknown): A car alone in the scene, in daylight (env.darkness false) with env.ice_or_snow and env.precipitation observed false, on a lane at p.reference_lane_width, with env.visibility and st.sight_distance both long. The source declares env.wet_road absent, so whether the baseline is p.speed_dry or p.speed_wet is unknown; kin.speed lies between p.speed_wet and p.speed_dry, so the comparison is decided neither way and the rule reports unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 22)] (cm 360) (m 500)
      (envOf false false true false (m 500))

/-- `branch_1` (violated): Daylight, dry surface, lane at reference width, long visibility and long sight distance; kin.speed sits just below p.speed_dry. Several other tracks - two cars and a person on foot, all classes the reading includes under DEF-NRS-484A-285::traffic - overlap the same highway region the subject overlaps and each lies within p.traffic_reach of it by rel.centre_distance, so the bound falls by p.traffic_speed_decrement for each of them and the subject's speed exceeds it. The traffic factor alone decides the verdict. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 24), car 2 (m 10) (mps 24), car 3 (m 20) (mps 24), walker 4 (m 30)]
      (cm 360) (m 500) dryDay

/-- `branch_2` (violated): Daylight, dry surface, no other road user in the scene, long visibility and long sight distance; kin.speed sits just below p.speed_dry. The lane the subject's footprint overlaps has st.lane_width well below p.reference_lane_width, and the deficit divided by p.width_penalty_time brings the bound below the subject's speed. The width factor alone decides the verdict. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 24)] (m 2) (m 500) dryDay

/-- `branch_3` (violated): Daylight, dry surface, lane at reference width, no other road user, env.visibility long; but st.sight_distance at the subject's place is short - a place on the road from which little of it can be seen - and kin.speed, though below p.speed_dry, exceeds st.sight_distance divided by p.sight_clearance_time. The catch-all factor, read through the view the road affords, decides the verdict. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 24)] (cm 360) (m 60) dryDay

/-- `branch_4` (violated): env.ice_or_snow observed true and env.darkness observed true; lane at reference width, no other road user, long visibility and long sight distance. kin.speed is above p.speed_ice and above p.speed_dark, so both the surface baseline and the night cap are exceeded. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 24)] (cm 360) (m 500)
      (envOf true false false true (m 500))

/-- `branch_5` (violated): Daylight, dry surface, lane at reference width, no other road user, st.sight_distance long; but env.visibility is short, a fog or dust that shortens the distance that can be seen, and kin.speed exceeds env.visibility divided by p.sight_clearance_time while remaining below p.speed_dry. The weather factor, read by the degree to which it holds, decides the verdict. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 24)] (cm 360) (m 500)
      (envOf false false false false (m 80))

/-- `branch_6` (not_applicable): the same car on the same lane in the same clear daylight, standing
    still at the kerbside halt: kin.speed is zero and does not stand clear of p.speed_resolution,
    so the vehicle is not being driven or operated and the duty is not engaged. The motion leaf of
    the applicability decides the verdict. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) Q.zero] (cm 360) (m 500) dryDay

/-- `branch_7` (violated): daylight, lane at reference width, no other road user, long visibility
    and long sight distance, env.wet_road and env.ice_or_snow observed false; but
    env.precipitation is observed true, so the baseline is p.speed_wet, and kin.speed lies between
    p.speed_wet and p.speed_dry. The falling rain alone decides the verdict. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 22)] (cm 360) (m 500)
      (envOf false true false false (m 500))

/-- `branch_8` (compliant): daylight, dry surface, lane at reference width, long visibility and
    long sight distance; one other car of the traffic lies 30 m ahead within p.traffic_reach, so
    the bound is p.speed_dry less one p.traffic_speed_decrement, and kin.speed is just below it.
    The scene is the one in which counting the subject itself among the traffic about it would
    lower the bound below its speed, so it holds the traffic count to the other road users. -/
def branch_8Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 23), car 2 (m 30) (mps 23)] (cm 360) (m 500) dryDay

/-- `branch_9` (violated): night (env.darkness observed true) on a dry surface, no other road user,
    long visibility and long sight distance; kin.speed is exactly at p.speed_dark and below
    p.speed_dry, so neither bare baseline is exceeded. The lane the subject occupies is narrower
    than p.reference_lane_width by a width whose allowance keeps the day bound but breaks the night
    one: the night cap less the width allowance alone decides the verdict. -/
def branch_9Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [car 1 (m 0) (mps 20)] (m 3) (m 500)
      (envOf true false false false (m 500))

/-- `branch_10` (violated): night again, dry surface, long visibility, no other road user; but the
    car stands on the way outside the one lane - on the shoulder breadth of the highway region, so
    its footprint overlaps no lane and no width allowance or sight-distance cap is owed. kin.speed
    is between p.speed_dark and p.speed_dry, so the night cap on the baseline alone decides the
    verdict. -/
def branch_10Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf t [carAt 1 (m 0, m 5) (mps 22)] (cm 360) (m 500)
      (envOf true false false false (m 500))

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
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a
