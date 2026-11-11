/-
  Witnesses for NRS_484B_600_1a.

  One eastbound lane (region 10) from x = −500 m to x = 500 m, its south edge at y = 0 and its width
  set per scene (3.7 m unless stated), carrying its sight distance and curvature. The subject,
  track 1, is a passenger car (half-extents 2.3 × 0.9 × 0.75 m, so 1.8 m wide) on the lane's centre
  line, advancing at its speed over three instants one second apart. Unless stated the road is dry
  (no ice, not wet, no precipitation), the visibility 1000 m, the sight distance 300 m and the lane
  straight (curvature 0).

  Against the reading (reaction 2.5 s; dry 4.5, wet 3.4, ice 1.5 m/s²; lateral 3 m/s²;
  margin 0.02 s; headway 1 s):
  - forbid: 15 m/s in fog, visibility 30 m; stopping distance 37.5 + 25 = 62.5 m > 30 m.
  - permit/blind: 10 m/s; stopping distance 25 + 11.1 = 36.1 m against 300 m and 1000 m; margin
    0.2 m against 3.7 − 1.8 = 1.9 m; nobody ahead.
  - idle: the car halted (0 m/s) by the lane's edge.
  - branch_1: ice, sight 60 m, 12 m/s; ice stopping distance 30 + 48 = 78 m > 60 m (dry: 46 m).
  - branch_2: curvature 1/20 per metre, 12 m/s; 144/20 = 7.2 m/s² > 3 m/s².
  - branch_3: a second car (track 2) 8 m of surface gap ahead in the lane, both at 12 m/s;
    headway 12 m > 8 m.
  - branch_4: a truck 2.6 m wide (half-extents 6 × 1.3 × 1.8 m) in a 3 m lane at 30 m/s; margin
    0.6 m > 0.4 m; stopping distance 75 + 100 = 175 m < 300 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- The lane: width, sight distance and curvature per scene. -/
def laneOf (width sight curvature : Q) : Structure :=
  let base := Build.lane 10 [(m (-500), Q.zero), (m 500, Q.zero), (m 500, width), (m (-500), width)] Build.east
  { base with sightDistance := some sight
              curvature := some curvature
              lane := base.lane.map fun li => { li with width := some width } }

def straightLane : Structure := laneOf (cm 370) (m 300) Q.zero

/-- Dry, clear weather with a given visibility. -/
def dryEnv (visibility : Q) : Env :=
  { precipitation := some false, wetRoad := some false, iceOrSnow := some false
    visibility := some visibility }

def carHalf : Q × Q × Q := (cm 230, cm 90, cm 75)

/-- The car on the lane's centre line, `v` m/s, at instant `k`. -/
def car (track : TrackId) (x0 v : Int) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (m (x0 + v * (k : Int)), cm 185) Build.east (Units.metresPerSecond v) carHalf

/-- `forbid` (violated): A passenger car moves on a dry straight lane in fog at a speed whose stopping distance exceeds the observed visibility distance; the sight distance is long and nothing is ahead in the lane. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 0 15 k ]
      [ straightLane ]
      []
      (env := dryEnv (m 30))

/-- `permit` (compliant): The car moves slowly on a dry straight lane of ample width with a long sight distance and visibility, alone in the scene: every bound holds. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 0 10 k ]
      [ straightLane ]
      []
      (env := dryEnv (m 1000))

/-- `idle` (not_applicable): The car stands halted at the curb throughout the trace. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (Q.zero, cm 100) Build.east (Units.metresPerSecond 0) carHalf ]
      [ straightLane ]
      []
      (env := dryEnv (m 1000))

/-- `blind` (unknown): As permit, but the source does not observe the visibility distance. -/
def blindTrace : Trace := permitTrace

/-- `branch_1` (violated): The car moves on an icy road (env.ice_or_snow) at a speed whose stopping distance under the ice deceleration exceeds the sight distance, though under the dry deceleration it would not. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 0 12 k ]
      [ laneOf (cm 370) (m 60) Q.zero ]
      []
      (env := { dryEnv (m 1000) with iceOrSnow := some true })

/-- `branch_2` (violated): The car takes a tight bend at a speed at which the square of the speed times the curvature exceeds the lateral-acceleration bound; sight and visibility are long. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 0 12 k ]
      [ laneOf (cm 370) (m 300) (Q.div (Units.perMetre 1) (Q.ofInt 20)) ]  -- a 20 m radius
      []
      (env := dryEnv (m 1000))

/-- `branch_3` (violated): The car follows another car ahead in the same lane at a surface gap shorter than the time headway at its speed. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 0 12 k
      , Build.user 2 [.motorVehicle] (Q.add (m (12 * (k : Int))) (cm 1260), cm 185) Build.east
          (Units.metresPerSecond 12) carHalf ]  -- 12.6 m between centres, 8 m between bodies
      [ straightLane ]
      []
      (env := dryEnv (m 1000))

/-- `branch_4` (violated): A wide truck moves in a narrow lane at a speed whose lateral margin exceeds the room the lane leaves beside it. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.truck] (m (30 * (k : Int)), cm 150) Build.east (Units.metresPerSecond 30)
          (m 6, cm 130, cm 180) ]
      [ laneOf (cm 300) (m 300) Q.zero ]
      []
      (env := dryEnv (m 1000))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["env.visibility"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a
