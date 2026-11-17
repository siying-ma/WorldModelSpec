/-
  Witnesses for NRS_484B_600_1a.

  Geometry (the witness's own figures, none of them in the rule): one eastbound lane (region 10)
  from x = -100 m to x = 500 m, y from -2 m to 2 m, lane width 4 m. The subject (track 1, a motor
  vehicle, half-extent 2.5 × 1 × 1 m, so 2 m wide) stands at the origin heading east. Three
  instants one second apart; the scene is held still (the rule reads one instant at a time).
  The environment is decided in every scene: daylight, no precipitation, visibility 1000 m.

  Against the run's reading (tr 1.5 s, dry 6, wet 4, ice 1 m/s², curve 3 m/s², heading error 0.03,
  tmin 1 s, low beam 50 m):
    permit   v 20 m/s dry: S = 30 + 33.3 = 63.3 m within sight 300 m; drift 2·0.6 = 1.2 ≤ 4 − 2.
    forbid   v 20 m/s dry, sight 40 m: S = 63.3 m > 40 m.
    blind    as forbid, sight distance unobserved; every other bound holds.
    idle     v 0.
    branch_1 ice, v 10 m/s, sight 40 m: dry S = 23.3 m would fit, ice S = 15 + 50 = 65 m does not.
    branch_2 dry, v 20 m/s, sight 300 m, curvature 1/50 m⁻¹: v²κ = 8 > 3 m/s².
    branch_3 dry, v 20 m/s, sight 300 m, a motor vehicle (track 2) 30 m ahead at 0.5 m/s:
             surface gap 25 m + 0.02 m credited < S = 63.3 m.
    branch_4 as permit, but dark: S = 63.3 m > low-beam reach 50 m.
    branch_5 as permit, but fog: visibility 40 m < S = 63.3 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The lane, with its width, sight distance and curvature as given. -/
def theLane (sight : Option Q) (curv : Q) : Structure :=
  let l := Build.lane 10 [(m (-100), m (-2)), (m 500, m (-2)), (m 500, m 2), (m (-100), m 2)] Build.east
  { l with
    lane := l.lane.map (fun li => { li with width := some (m 4) })
    sightDistance := sight
    curvature := some curv }

def subjectAt (v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m 0) Build.east v (cm 250, m 1, m 1)

def env (ice : Bool) : Env :=
  { darkness := some false
    precipitation := some false
    wetRoad := some false
    iceOrSnow := some ice
    visibility := some (m 1000) }

def oneScene (users : List RoadUser) (lane : Structure) (e : Env) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users [lane] [] (env := e)

/-- `forbid` (violated): blind crest, sight 40 m, v 20 m/s on dry road. -/
def forbidTrace : Trace :=
  oneScene [subjectAt (Units.metresPerSecond 20)] (theLane (some (m 40)) Q.zero) (env false)

/-- `permit` (compliant): sight 300 m, visibility 1000 m, v 20 m/s on a straight dry lane. -/
def permitTrace : Trace :=
  oneScene [subjectAt (Units.metresPerSecond 20)] (theLane (some (m 300)) Q.zero) (env false)

/-- `idle` (not_applicable): the subject stands still. -/
def idleTrace : Trace :=
  oneScene [subjectAt Q.zero] (theLane (some (m 300)) Q.zero) (env false)

/-- `blind` (unknown): as forbid, with the sight distance masked by the manifest. -/
def blindTrace : Trace :=
  oneScene [subjectAt (Units.metresPerSecond 20)] (theLane (some (m 40)) Q.zero) (env false)

/-- `branch_1` (violated): icy road, v 10 m/s, sight 40 m (fits dry, not ice). -/
def branch_1Trace : Trace :=
  oneScene [subjectAt (Units.metresPerSecond 10)] (theLane (some (m 40)) Q.zero) (env true)

/-- `branch_2` (violated): dry, ample sight, on a bend of curvature 1/50 m⁻¹ at 20 m/s. -/
def branch_2Trace : Trace :=
  oneScene [subjectAt (Units.metresPerSecond 20)] (theLane (some (m 300)) (Units.ratio 1 50)) (env false)

/-- `branch_3` (violated): a nearly stopped vehicle 30 m ahead in the lane at 0.5 m/s. -/
def branch_3Trace : Trace :=
  oneScene
    [ subjectAt (Units.metresPerSecond 20)
    , Build.user 2 [.motorVehicle] (m 30, m 0) Build.east (cm 50) (cm 250, m 1, m 1) ]
    (theLane (some (m 300)) Q.zero) (env false)

/-- `branch_4` (violated): dry, sight 300 m, clear air, but dark: S = 63.3 m beyond the 50 m low beam. -/
def branch_4Trace : Trace :=
  oneScene [subjectAt (Units.metresPerSecond 20)] (theLane (some (m 300)) Q.zero)
    { env false with darkness := some true }

/-- `branch_5` (violated): dry daylight, sight 300 m, but fog: visibility 40 m < S = 63.3 m. -/
def branch_5Trace : Trace :=
  oneScene [subjectAt (Units.metresPerSecond 20)] (theLane (some (m 300)) Q.zero)
    { env false with visibility := some (m 40) }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1a"
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
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a
