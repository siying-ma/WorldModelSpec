/-
  Witnesses for NRS_484B_600_1a.

  The carriageway is one and the same in every scene: a highway region 2000 m long (x from 0 to
  2000 m, y from -2 to 12 m) carrying two eastbound lanes that lie on it (`ways`), the right-hand
  lane (region 2) against the kerb and the left-hand lane (region 3) beside it. Both lanes carry a
  declared width; `narrowLanes` is the same pair with the subject's lane cut to 2.6 m.

  The subject is track 1, a motor vehicle 4 m long and 1.8 m wide, in the right-hand lane heading
  east; its position advances by its speed over the trace, so it is inside the lane polygon (and so
  on the highway) at every instant. Other road users are tracks 2, 3 and 4, running at the
  subject's speed at fixed offsets so that the traffic about it is the same at every instant.

  Every trace is 7 scenes 10 s apart, 0 s to 60 s; nothing in the rule looks back, so no scenario
  names a window.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

def hwId : RegionId := 1
def laneA : RegionId := 2
def laneB : RegionId := 3

/-- The public way: one carriageway, 2000 m long. -/
def highway : Structure := Build.rect hwId .highway (m 0) (m (-2)) (m 2000) (m 12)

/-- A lane of that highway, between `y0` and `y1`, `w` wide, lying on it. -/
def laneOf (id : RegionId) (y0 y1 w : Q) (left right : Option RegionId) : Structure :=
  let s := Build.lane id [(m 0, y0), (m 2000, y0), (m 2000, y1), (m 0, y1)] Build.east left right
  { s with ways := some [hwId],
           lane := s.lane.map (fun li => { li with width := some w }) }

/-- The ordinary carriageway: both lanes 3.6 m wide. -/
def wideLanes : List Structure :=
  [ highway
  , laneOf laneA (m 0) (cm 360) (cm 360) (some laneB) none
  , laneOf laneB (cm 360) (cm 720) (cm 360) none (some laneA) ]

/-- The same carriageway with the subject's lane cut to 2.6 m. -/
def narrowLanes : List Structure :=
  [ highway
  , laneOf laneA (m 0) (cm 260) (cm 260) (some laneB) none
  , laneOf laneB (cm 260) (cm 620) (cm 360) none (some laneA) ]

/-- Rain falling on a wet surface, 60 m of visibility, daylight. -/
def wetRain : Env :=
  { darkness := some false, precipitation := some true, wetRoad := some true,
    iceOrSnow := some false, visibility := some (m 60) }

/-- A dry surface in daylight, with the visible distance given. -/
def dryDay (vis : Q) : Env :=
  { darkness := some false, precipitation := some false, wetRoad := some false,
    iceOrSnow := some false, visibility := some vis }

/-- An icy, snow-covered surface in daylight, 400 m of visibility. -/
def icyDay : Env :=
  { darkness := some false, precipitation := some false, wetRoad := some true,
    iceOrSnow := some true, visibility := some (m 400) }

/-- Half-length, half-width, half-height of an ordinary car. -/
def halfExtent : Q × Q × Q := (m 2, cm 90, cm 75)

def vehicleAt (track : TrackId) (x y speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) Build.east speed halfExtent

/-- Where a body that started at `x0` and runs at `speed` stands at the `k`-th instant. -/
def along (x0 speed : Q) (k : Nat) : Q := Q.add x0 (Q.mul speed (Q.ofInt (Int.ofNat (10 * k))))

def dt : Q := Units.seconds 10
def nScenes : Nat := 7

/-- The subject alone on the carriageway, at `speed`, under the environment given. -/
def soloTrace (speed : Q) (y : Q) (structures : List Structure) (env : Env) : Trace :=
  Build.trace nScenes 0 dt fun k t =>
    Build.scene t (some 1)
      [ vehicleAt 1 (along (m 100) speed k) y speed ]
      structures [] none env

/-- The subject at `speed` with three other vehicles held at fixed offsets about it: one 20 m
    behind in its own lane, one 25 m ahead in the left-hand lane, one 40 m behind in that lane —
    every one of them within p.traffic_reach of the subject. -/
def trafficTrace (speed : Q) : Trace :=
  Build.trace nScenes 0 dt fun k t =>
    let x := along (m 100) speed k
    Build.scene t (some 1)
      [ vehicleAt 1 x (cm 180) speed
      , vehicleAt 2 (Q.sub x (m 20)) (cm 180) speed
      , vehicleAt 3 (Q.add x (m 25)) (cm 540) speed
      , vehicleAt 4 (Q.sub x (m 40)) (cm 540) speed ]
      wideLanes [] none (dryDay (m 400))

/-- `forbid` (violated): Rain is falling and the road surface is wet; the visibility distance is 60 m; the subject runs at 30 m/s along a two-lane highway, the lane it occupies 3.6 m wide, and no other road user is in the scene. 30 m/s is above the wet-surface baseline and above the sight bound, 60 m divided by p.sight_clearance_time. The trace runs 60 s and nothing in the rule is windowed. The rule quantifies over the other road users of the traffic and the scene has none; the verdict is decided all the same. -/
def forbidTrace : Trace := soloTrace (mps 30) (cm 180) wideLanes wetRain

/-- `permit` (compliant): The same rain, the same wet surface, the same 60 m of visibility and the same 3.6 m lane, with the subject at 10 m/s and no other road user within p.traffic_reach: the speed is under every one of the four bounds the operationalization sets. The trace runs 60 s and nothing is windowed. -/
def permitTrace : Trace := soloTrace (mps 10) (cm 180) wideLanes wetRain

/-- `idle` (not_applicable): A dry highway in daylight, visibility 400 m. The subject stands parked at the kerb for the whole 60 s trace, its speed zero at every observation and so below p.speed_resolution: it is not a vehicle in motion upon the way, so the rule is not engaged. -/
def idleTrace : Trace := soloTrace Q.zero (cm 40) wideLanes (dryDay (m 400))

/-- `blind` (unknown): A dry highway in daylight with a clear surface, the subject's lane 3.6 m wide, no other road user within p.traffic_reach, and the subject at 20 m/s — under the surface-and-light bound, under the lane-width bound and under the traffic bound. The source's manifest declares env.visibility absent, so the sight bound cannot be computed and whether the speed is greater than is reasonable cannot be decided. The rule reports unknown rather than compliance. -/
def blindTrace : Trace := soloTrace (mps 20) (cm 180) wideLanes (dryDay (m 400))

/-- `branch_1` (violated): an icy, snow-covered surface in daylight with 400 m of visibility and a
    3.6 m lane, the subject at 15 m/s: only the surface-and-light bound, p.speed_ice, is broken. -/
def branch1Trace : Trace := soloTrace (mps 15) (cm 180) wideLanes icyDay

/-- `branch_2` (violated): a dry surface in daylight, a 3.6 m lane, no traffic, the subject at
    20 m/s, but only 60 m of visibility: only the stopping-sight-distance bound is broken. -/
def branch2Trace : Trace := soloTrace (mps 20) (cm 180) wideLanes (dryDay (m 60))

/-- `branch_3` (violated): a dry surface in daylight, 400 m of visibility, no traffic, the subject
    at 22 m/s in a lane cut to 2.6 m: only the lane-width bound is broken. -/
def branch3Trace : Trace := soloTrace (mps 22) (cm 130) narrowLanes (dryDay (m 400))

/-- `branch_4` (violated): a dry surface in daylight, 400 m of visibility, a 3.6 m lane, the
    subject at 22 m/s with three other vehicles of the traffic within p.traffic_reach on lanes of
    its own highway: only the traffic-density bound is broken. -/
def branch4Trace : Trace := trafficTrace (mps 22)

/-- `branch_5` (compliant): the same three vehicles about the subject, with the subject at
    18 m/s — under the traffic-density bound the three of them set, and under the other three. -/
def branch5Trace : Trace := trafficTrace (mps 18)

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
  , witness "blind" blindTrace (.unknown []) ["env.visibility"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .violated
  , witness "branch_3" branch3Trace .violated
  , witness "branch_4" branch4Trace .violated
  , witness "branch_5" branch5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_600_1a
