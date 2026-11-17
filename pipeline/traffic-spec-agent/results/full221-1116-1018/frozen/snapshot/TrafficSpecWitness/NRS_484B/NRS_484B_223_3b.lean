/-
  Witnesses for NRS_484B_223_3b.

  Geometry (metres, +x east, +y north), sampled every 1 s from t = 0:
    region 10: centre turn lane, x 0 … 200, y −2 … 2;
    region 11: an approach lane (kind lane) feeding it, x −40 … 0, y −2 … 2;
    region 13: a through lane, x −40 … 200, y −6 … −2;
    region 12: a driveway entrance north of the centre turn lane, y 3 … 40.
  The subject (track 1, a motor vehicle) drives east, enters the centre turn lane at t = 2 s,
  runs in it, then turns left (yaw rate 17 deg/s for 5 s, 85 deg, heading rotated 17° per
  step) into the driveway and stops turning (yaw rate 0), when the left turn is recognised.
    forbid: 10 m/s; in the lane from x = 5 (path 20 m) to x ≈ 99.8 (path 116 m, t = 12 s): 96 m,
            above 200 ft = 60.96 m; turn recognised at t = 17 s; driveway x 100 … 116.
    permit: 8 m/s; in the lane from x = 4 (path 16 m) to x ≈ 40.8 (path 54 m, t = 7 s): 38 m;
            turn recognised at t = 12 s; driveway x 40 … 56.
    idle:   10 m/s straight east in the through lane, yaw rate 0 throughout.
    blind:  the forbid trace with kin.yaw_rate unobserved.
  Each witness judges the instants from t = 10 s (the turn window of the reading is 10 s), so no
  window it reads is truncated at the trace's start. Every figure is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_3b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_3b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def ctl : Structure := Build.rect 10 .centreTurnLane (m 0) (m (-2)) (m 200) (m 2)
def approach : Structure := Build.rect 11 .lane (m (-40)) (m (-2)) (m 0) (m 2)
def through : Structure := Build.rect 13 .lane (m (-40)) (m (-6)) (m 200) (m (-2))
def driveway (x0 : Int) : Structure := Build.rect 12 .drivewayOrAlleyEntrance (m x0) (m 3) (m (x0 + 16)) (m 40)

/-- The heading after `n` steps of 17° to the left from east (unit vector to three decimals). -/
def hdg : Nat → Vec
  | 0 => Build.east
  | 1 => (Units.ratio 956 1000, Units.ratio 292 1000)
  | 2 => (Units.ratio 829 1000, Units.ratio 559 1000)
  | 3 => (Units.ratio 629 1000, Units.ratio 777 1000)
  | 4 => (Units.ratio 375 1000, Units.ratio 927 1000)
  | _ => (Units.ratio 87 1000, Units.ratio 996 1000)

/-- The subject at a position (cm), heading, speed (m/s), cumulative path length (m) and yaw rate (deg/s). -/
def subjectAt (x y : Int) (hd : Vec) (speed : Int) (path : Int) (yaw : Int) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (cm x, cm y) hd (Units.metresPerSecond speed) (cm 240, cm 90, cm 75)
      (some (m path)))
    (fun kn => { kn with yawRate := some (Units.degrees yaw) })

def sceneWith (t : Timestamp) (u : RoadUser) (drivewayX0 : Int) : Scene :=
  Build.scene t (some 1) [u] [ctl, approach, through, driveway drivewayX0] []

/-- A left turn that starts at (x0, 0) cm heading east with path p0 m: five steps of about 5 m
    (path 6 m each) turning 17° (yaw rate 17 deg/s), then straight at 85° and 4 m/s with yaw
    rate 0. -/
def turning (x0 p0 : Int) (j : Nat) : RoadUser :=
  let dx : List Int := [478, 415, 315, 188, 44]
  let dy : List Int := [146, 280, 389, 464, 498]
  if j ≤ 5 then
    let sx := (dx.take j).foldl (· + ·) 0
    let sy := (dy.take j).foldl (· + ·) 0
    subjectAt (x0 + sx) sy (hdg j) 5 (p0 + 6 * (j : Int)) 17
  else
    let e : Int := (j : Int) - 5
    subjectAt (x0 + 1440 + 35 * e) (1777 + 398 * e) (hdg 5) 4 (p0 + 30 + 4 * e) 0

/-- Forbid motion: 10 m/s east, in the lane from k = 2 (path 20 m) to k = 12 (path 115 m),
    turning at k = 12 … 16, recognised at k = 17. -/
def forbidSubject (k : Nat) : RoadUser :=
  let i : Int := k
  if k ≤ 11 then subjectAt (-1500 + 1000 * i) 0 Build.east 10 (10 * i) 0
  else turning 9500 110 (k - 11)

/-- `forbid` (violated): The subject enters the st.centre_turn_lane, travels 90 m in it continuously, and turns left by 85 degrees out of it into a driveway_or_alley_entrance. -/
def forbidTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t => sceneWith t (forbidSubject k) 100

/-- Permit motion: 8 m/s east, in the lane from k = 2 (path 16 m) to k = 7 (path 53 m),
    turning at k = 7 … 11, recognised at k = 12. -/
def permitSubject (k : Nat) : RoadUser :=
  let i : Int := k
  if k ≤ 6 then subjectAt (-1200 + 800 * i) 0 Build.east 8 (8 * i) 0
  else turning 3600 48 (k - 6)

/-- `permit` (compliant): The subject travels 40 m in the centre turn lane and then turns left out of it. -/
def permitTrace : Trace :=
  Build.trace 15 0 (Units.seconds 1) fun k t => sceneWith t (permitSubject k) 40

/-- `idle` (not_applicable): The subject drives straight in a through lane and makes no left turn. -/
def idleTrace : Trace :=
  Build.trace 15 0 (Units.seconds 1) fun k t =>
    let i : Int := k
    sceneWith t (subjectAt (-3000 + 1000 * i) (-400) Build.east 10 (10 * i) 0) 100

/-- `blind` (unknown): The subject travels 90 m in the centre turn lane and leaves it, but kin.yaw_rate is not observed, so whether it turned left is unknown. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.yaw_rate"]) forbidTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_223_3b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (10000, 19000))
  , witness "permit" permitTrace .compliant (window := some (10000, 14000))
  , witness "idle" idleTrace .notApplicable (window := some (10000, 14000))
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (window := some (10000, 19000)) ]

end TrafficSpecWitness.NRS_484B_223_3b
