/-
  Witnesses for NRS_484B_600_1a.

  Geometry: one eastbound lane (region 10) from x = −100 m to x = 700 m, centred on y = 0, 4 m wide
  (3 m in branch_4), with its width, curvature and sight distance set on the lane. Track 1 is x, a
  car 4.5 m × 1.8 m (a truck 2.5 m wide in branch_4), driving east along y = 0 and advancing by its
  speed each second; three instants, 1 s apart. The weather and surface are set on every scene:
  dry and clear (visibility 2000 m) unless the narrative says otherwise.

  Against the reading (reaction 2.5 s; dry 3.4, wet 2.5, ice 1.0 m/s²; headway 1 s; lane margin
  0.0175 s; motion tolerance 0.2 m/s):
    forbid    25 m/s, dry, fog 30 m: SD ≈ 154 m ≫ 30 m.
    permit    15 m/s, dry, straight, sight 300 m: SD ≈ 71 m; margin 0.53 ≤ 2.2 m.
    idle      0 m/s.
    blind     permit's scene with kin.speed masked.
    branch_1  20 m/s, y (track 2) 13 m ahead centre to centre: gap 8.5 m < 20 m.
    branch_2  15 m/s, curvature 0.01 /m, ice: 2.25 > 1.0 m/s² (SD 150 m < sight 300 m).
    branch_3  the same bend and speed, dry: 2.25 ≤ 3.4 m/s², SD ≈ 71 m.
    branch_4  20 m/s, truck 2.5 m wide in a 3 m lane: 0.70 m > 0.5 m.
    branch_5  20 m/s, wet road, no precipitation, sight 120 m: SD wet 130 m > 120 m (dry ≈ 109 m).
    branch_6  20 m/s, precipitation falling, road not reported wet, sight 120 m: SD 130 m > 120 m.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- The eastbound lane, of half-width `hw`, with its width, curvature and sight distance. -/
def laneOf (hw : Q) (sight : Q) (curv : Q) : Structure :=
  let s := Build.lane 10 [(m (-100), Q.neg hw), (m 700, Q.neg hw), (m 700, hw), (m (-100), hw)] Build.east
  { s with
    lane := s.lane.map (fun li => { li with width := some (Q.add hw hw) })
    sightDistance := some sight
    curvature := some curv }

/-- Surface and weather: dry and clear unless overridden. -/
def clear : Env :=
  { precipitation := some false, wetRoad := some false, iceOrSnow := some false
    visibility := some (m 2000) }

/-- A car of 4.5 m × 1.8 m heading east along y = 0. -/
def car (track : TrackId) (x0 : Int) (v : Int) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (m (x0 + v * (k : Int)), Q.zero) Build.east
    (Units.metresPerSecond v) (cm 225, cm 90, cm 75)

/-- A scene of x alone in the lane. -/
def alone (u : RoadUser) (ln : Structure) (env : Env) (t : Timestamp) : Scene :=
  Build.scene t (some 1) [u] [ln] [] (env := env)

/-- `forbid` (violated): x, alone in the scene, drives on a dry road in dense fog at a speed whose stopping distance far exceeds the visibility distance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    alone (car 1 0 25 k) (laneOf (m 2) (m 300) Q.zero) { clear with visibility := some (m 30) } t

/-- `permit` (compliant): x, alone in the scene, drives at a moderate speed on a dry, straight road with wide lanes in clear weather and a long sight distance; its stopping distance lies within the sight and visibility distances and the lane-keeping margin holds. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    alone (car 1 0 15 k) (laneOf (m 2) (m 300) Q.zero) clear t

/-- `idle` (not_applicable): x stands halted throughout the trace. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    alone (car 1 0 0 k) (laneOf (m 2) (m 300) Q.zero) clear t

/-- `blind` (unknown): The source declares kin.speed absent: whether x moves, and how fast, is unknown. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.speed"]) permitTrace

/-- `branch_1` (violated): Clear, dry, straight road; x follows y, a car in the same lane, at a gap shorter than its speed times the minimum time headway. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 0 20 k, car 2 13 20 k ]
      [ laneOf (m 2) (m 300) Q.zero ]
      []
      (env := clear)

/-- `branch_2` (violated): x drives through a bend on an icy road at a speed whose lateral acceleration exceeds the ice deceleration, though it would lie within the dry one. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    alone (car 1 0 15 k) (laneOf (m 2) (m 300) (Units.ratio 1 100)) { clear with iceOrSnow := some true } t

/-- `branch_3` (compliant): The same bend and speed as branch_2 on a dry road in clear weather, every other bound met. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    alone (car 1 0 15 k) (laneOf (m 2) (m 300) (Units.ratio 1 100)) clear t

/-- `branch_4` (violated): A wide vehicle x travels in a narrow lane at a speed whose required lateral margin exceeds half of the lane width less its width; every other bound is met. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    alone
      (Build.user 1 [.truck] (m (20 * (k : Int)), Q.zero) Build.east (Units.metresPerSecond 20) (m 5, cm 125, cm 200))
      (laneOf (cm 150) (m 300) Q.zero) clear t

/-- `branch_5` (violated): on a wet road, with no precipitation falling, x's stopping distance at the
    wet deceleration exceeds the sight distance, though at the dry one it would lie within it. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    alone (car 1 0 20 k) (laneOf (m 2) (m 120) Q.zero) { clear with wetRoad := some true } t

/-- `branch_6` (violated): rain falling on a road not reported wet selects the wet deceleration, and
    x's stopping distance at it exceeds the sight distance. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    alone (car 1 0 20 k) (laneOf (m 2) (m 120) Q.zero) { clear with precipitation := some true } t

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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1a
