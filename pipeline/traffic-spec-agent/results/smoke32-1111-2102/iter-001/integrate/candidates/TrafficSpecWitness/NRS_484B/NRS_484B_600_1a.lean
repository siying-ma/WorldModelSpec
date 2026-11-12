/-
  Witnesses for NRS_484B_600_1a.

  The carriageway is one eastbound lane (region 10), from x = −200 m to x = 2000 m, of width w
  (4 m, or 2.5 m in branch_4) from y = 0 to y = w, carrying its width, sight distance and
  curvature. Ego (track 1) is a passenger car 4.5 m × 1.8 m on the lane's centre line, heading east
  at a constant speed v, at x = v·k for the instants k = 0, 1, 2 (one second apart). Other cars
  (tracks 2, 3) share the lane at a fixed offset from ego and ego's speed. Every weather and
  surface field is observed; in clear weather the visibility is 2000 m.

  Against the run's reading (reaction 2.5 s; decelerations 4.5 dry, 3.4 wet, 1.5 icy m/s²; side
  friction 2 m/s²; lane-width time 0.16 s):
    v = 15 m/s: dry stopping distance 62.5 m, width need 2.4 m, gap need 37.5 m.
    v = 20 m/s: dry 94.4 m, wet 108.8 m, icy 183.3 m, width need 3.2 m, gap need 50 m.
    v = 22 m/s: dry 108.8 m, width need 3.52 m.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: ego ↦ 1

/-- The lane: width `w`, sight distance `sight`, curvature `curv`. -/
def laneOf (w : Q) (sight : Q) (curv : Q) : Structure :=
  let l := Build.lane 10 [(m (-200), m 0), (m 2000, m 0), (m 2000, w), (m (-200), w)] Build.east
  { l with lane := l.lane.map (fun li => { li with width := some w })
           sightDistance := some sight
           curvature := some curv }

/-- A passenger car on the lane's centre line, `dx` ahead of ego, moving east with ego at `v`. -/
def car (track : TrackId) (classes : List RoadUserClass) (v : Q) (k : Nat) (dx : Q) (w : Q) : RoadUser :=
  Build.user track classes (Q.add (Q.mul v (Q.ofInt k)) dx, Q.half w) Build.east v (cm 225, cm 90, cm 75)

/-- Weather and surface, every field observed. -/
def weather (precip wet ice : Bool) (visibility : Q) : Env :=
  { precipitation := some precip, wetRoad := some wet, iceOrSnow := some ice, visibility := some visibility }

def clear : Env := weather false false false (m 2000)

/-- Ego alone, or with the cars `others` (track, offset), on one lane. -/
def drive (v : Q) (w sight curv : Q) (env : Env) (others : List (TrackId × Q) := [])
    (egoClasses : List RoadUserClass := [.motorVehicle]) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (car 1 egoClasses v k Q.zero w :: others.map fun (id, dx) => car id [.motorVehicle] v k dx w)
      [ laneOf w sight curv ]
      [ ]
      (env := env)

/-- `forbid` (violated): ego, a passenger car, drives at highway speed on a dry straight road in dense fog: its stopping distance far exceeds the visibility distance. -/
def forbidTrace : Trace :=
  drive (Units.metresPerSecond 22) (m 4) (m 400) Q.zero (weather false false false (m 30))

/-- `permit` (compliant): ego drives at a moderate speed on a dry, straight, wide road in clear weather with a long sight distance and no road user close ahead. A car 100 m ahead (gap 95.5 m) and a car close behind (gap 7.5 m), which is not ahead and so not bound. -/
def permitTrace : Trace :=
  drive (Units.metresPerSecond 15) (m 4) (m 300) Q.zero clear [(2, m 100), (3, m (-12))]

/-- `idle` (not_applicable): ego is a bicycle (ru.bicycle), a device moved by human power that the vehicle aggregate does not include. -/
def idleTrace : Trace :=
  drive (Units.metresPerSecond 5) (m 4) (m 300) Q.zero clear [] [.bicycle]

/-- `blind` (unknown): as in permit, but the source does not supply sight distances, so whether the stopping distance fits within the sight distance is unknown. -/
def blindTrace : Trace :=
  drive (Units.metresPerSecond 15) (m 4) (m 300) Q.zero clear [(2, m 100), (3, m (-12))]

/-- `branch_1` (violated): ego drives on an icy road at a speed whose dry stopping distance fits within the sight distance but whose icy stopping distance does not. 20 m/s, sight 140 m: dry 94.4 m, icy 183.3 m. -/
def branch_1Trace : Trace :=
  drive (Units.metresPerSecond 20) (m 4) (m 140) Q.zero (weather false false true (m 2000))

/-- `branch_2` (violated): ego takes a sharp bend at a speed whose lateral acceleration exceeds the side-friction limit, on a dry road with ample sight distance and no other road user. 20 m/s on a 50 m radius: 8 m/s². -/
def branch_2Trace : Trace :=
  drive (Units.metresPerSecond 20) (m 4) (m 300) (Units.ratio 1 50) clear

/-- `branch_3` (compliant): ego drives alone on the road at a moderate speed in clear weather: no road user is ahead and every bound holds. -/
def branch_3Trace : Trace :=
  drive (Units.metresPerSecond 15) (m 4) (m 300) Q.zero clear

/-- `branch_4` (violated): ego drives at 20 m/s on a straight dry lane 2.5 m wide in clear weather: the width needs 3.2 m. -/
def branch_4Trace : Trace :=
  drive (Units.metresPerSecond 20) (cm 250) (m 300) Q.zero clear

/-- `branch_5` (violated): ego drives at 20 m/s on a wet road, no rain falling, sight 101 m: dry 94.4 m fits, wet 108.8 m does not. -/
def branch_5Trace : Trace :=
  drive (Units.metresPerSecond 20) (m 4) (m 101) Q.zero (weather false true false (m 2000))

/-- `branch_6` (violated): as branch_5 in falling rain on a road not reported wet. -/
def branch_6Trace : Trace :=
  drive (Units.metresPerSecond 20) (m 4) (m 101) Q.zero (weather true false false (m 2000))

/-- `branch_7` (violated): ego follows a car at 20 m/s on a dry straight road in clear weather with a gap of 20.5 m, below the 50 m it travels in a reaction time. -/
def branch_7Trace : Trace :=
  drive (Units.metresPerSecond 20) (m 4) (m 300) Q.zero clear [(2, m 25)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a
