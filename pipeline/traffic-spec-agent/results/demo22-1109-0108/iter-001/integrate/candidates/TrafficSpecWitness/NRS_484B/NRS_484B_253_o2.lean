/-
  Witnesses for NRS_484B_253_o2.

  THE GEOMETRY. One junction, a five-metre square at the origin (region 10), where a north-south
  street meets an east-west street. Region 20 is the northbound approach (x from 0 to 2.5 m, south
  of the junction), its designated direction north, its entrance end that junction; region 21 is
  the southbound approach (x from -2.5 to 0 m, north of the junction), its direction south, its
  entrance end the same junction. The source records those two approaches and the junction, and
  no further carrier: the westbound way the van's turn leads into is outside what it reports.

  THE BODIES. Track 1 is the subject, a car 4 m by 1.8 m coming south down region 21 (in one
  witness a bicycle instead). Track 2 is the van, 4.8 m by 2 m, which comes north up region 20 at
  4 m/s, stands from t = 3950 ms with its reference point at (1.3, -1.8) m — in the junction
  mouth, its footprint overlapping both its approach carrier and the junction throughout — and
  from t = 4000 ms swings to the left at 30 deg/s: one and a half degrees between consecutive
  scenes, written as an exact rational rotation of its heading, so that heading and yaw rate say
  the same thing at every scene. The heading change accumulated since that onset passes
  forty-five degrees at t = 5500 ms, where its left turn is recognized, and reaches ninety
  degrees by the end. Track 3, where a witness has one, is a car that came south down region 21
  and stopped in the junction, across the van's turn.

  Every body here either stands or runs straight at a constant speed, its position advancing by
  the speed of the scene over the interval before it, so that no scene asserts a motion its own
  figures deny.

  THE INSTANTS. Every trace is 141 scenes at 50 ms, t = 0 to 7000 ms — the sampling period of the
  run's acquisition profile, so the concept's integration is never short of a sample, and long
  enough that every three-second window behind a judged instant is covered. Each witness names
  the instants it speaks about, t = 6000 to 7000 ms: the second and a half after the turn is
  recognized. Before the yaw onset the turn concept is unknown, as its contract says: no onset is
  observed yet.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def degps (n : Int) : Q := Units.degrees n
/-- A point of the world frame, in centimetres: every coordinate below is exact. -/
def pt (x y : Int) : Vec := (cm x, cm y)

/-- The rotation to the left by one step of the van's turn: the one and a half degrees its yaw
    rate of 30 deg/s makes over the 50 ms before a scene, as an exact rational rotation. -/
def stepCos : Q := Units.ratio 9996573 10000000
def stepSin : Q := Units.ratio 261769 10000000

/-- Keep a coordinate to a tenth of a micrometre, so the sixty steps of the turn stay small
    exact rationals; the angle between consecutive headings is unaffected at this resolution. -/
def trim (q : Q) : Q := Units.ratio ((q.num * 10000000) / Int.ofNat q.den) 10000000

def rotLeft (v : Vec) : Vec :=
  (trim (Q.sub (Q.mul v.1 stepCos) (Q.mul v.2 stepSin)),
   trim (Q.add (Q.mul v.1 stepSin) (Q.mul v.2 stepCos)))

/-- `n` steps of that rotation. -/
def rotN : Nat → Vec → Vec
  | 0, v => v
  | n + 1, v => rotLeft (rotN n v)

-- Binders ↦ tracks: v ↦ 1

/-- The junction: a five-metre square where the two streets meet. -/
def junction : Structure := Build.rect 10 .intersection (cm (-250)) (cm (-250)) (cm 250) (cm 250)

/-- The northbound approach: the carrier by which the van reaches the junction. -/
def northboundApproach : Structure :=
  Build.lane 20 [pt 0 (-10000), pt 250 (-10000), pt 250 (-250), pt 0 (-250)]
    Build.north (enters := some 10)

/-- The southbound approach: the carrier the subject occupies, its direction the opposed one. -/
def southboundApproach : Structure :=
  Build.lane 21 [pt (-250) 250, pt 0 250, pt 0 10000, pt (-250) 10000]
    Build.south (enters := some 10)

def roads : List Structure := [junction, northboundApproach, southboundApproach]

/-- A clear, dry afternoon. -/
def weather : Env :=
  { darkness := some false, precipitation := some false, wetRoad := some false,
    iceOrSnow := some false, visibility := some (m 300) }

/-- What the source declares about the van's plan at the junction. -/
def vanIntent (v : Bool) : DeclaredIntent :=
  { vehicle := 2, target := 10,
    values := [("int.turn_left", v), ("int.left_turn", v), ("int.turn_to_the_left", v)] }

/-- The subject car: 4 m by 1.8 m, running straight south, no signal of its own. -/
def car (ycm : Int) (xcm : Int) (speed : Q) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 1 [.motorVehicle] (pt xcm ycm) Build.south speed (m 2, cm 90, cm 75))
      (fun s => { s with turnIndicator := some .off, handSignal := some .noSignal }))
    (fun k => { k with yawRate := some Q.zero })

/-- The subject in the witness where it is a bicycle, which the aggregate does not include. -/
def cycle (ycm : Int) (xcm : Int) (speed : Q) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 1 [.bicycle] (pt xcm ycm) Build.south speed (cm 90, cm 30, cm 90))
      (fun s => { s with turnIndicator := some .off, handSignal := some .noSignal }))
    (fun k => { k with yawRate := some Q.zero })

/-- The van's reference point: north up the approach at 4 m/s, then standing in the junction
    mouth from t = 3950 ms. -/
def vanPos (k : Nat) : Vec :=
  if k ≤ 79 then pt 130 (-1760 + 20 * (k : Int)) else pt 130 (-180)

def vanSpeed (k : Nat) : Q := if k ≤ 79 then mps 4 else Q.zero

/-- The van's heading: north until it stands, then one and a half degrees further to the left at
    every scene from t = 4000 ms, the rotation its yaw rate makes over the interval before it. -/
def vanHeading (k : Nat) : Vec := if k ≤ 79 then Build.north else rotN (k - 79) Build.north

/-- The van's yaw rate: the onset of the turn at t = 4000 ms, held to the end of the trace. -/
def vanYaw (k : Nat) : Q := if k ≤ 79 then Q.zero else degps 30

/-- The van, with the indication it shows. -/
def vanAt (k : Nat) (ind : TurnIndicatorState) (hand : HandSignal) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 2 [.motorVehicle] (vanPos k) (vanHeading k) (vanSpeed k) (cm 240, m 1, cm 95))
      (fun s => { s with turnIndicator := some ind, handSignal := some hand }))
    (fun kk => { kk with yawRate := some (vanYaw k) })

/-- The van's stated occupancy: its approach carrier throughout, and the junction from the moment
    its nose crosses the junction mouth. -/
def vanOcc (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 43 then [(2, 20)] else [(2, 20), (2, 10)]

/-- A southbound car's stated occupancy, from the height of its reference point (centimetres):
    its approach carrier while its rear is north of the junction mouth, the junction while its
    nose is south of it. -/
def southboundOcc (track : TrackId) (ycm : Int) : List (TrackId × RegionId) :=
  (if ycm ≥ 50 then [(track, 21)] else []) ++
  (if ycm ≤ 450 then (if ycm ≥ -450 then [(track, 10)] else []) else [])

/-- The vehicle that rolled up to the junction mouth and stands there, its nose settling three
    degrees to the left: an onset of turning is observed, and the heading change accumulated
    since it stays far below the turn angle, so it makes no left turn. -/
def twitchVehicle (k : Nat) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 2 [.motorVehicle] (vanPos k)
        (if k ≤ 79 then Build.north else rotN (min (k - 79) 2) Build.north) (vanSpeed k)
        (cm 240, m 1, cm 95))
      (fun s => { s with turnIndicator := some .off, handSignal := some .noSignal }))
    (fun kk => { kk with yawRate := some (if k ≤ 79 then Q.zero else if k ≤ 81 then degps 30 else Q.zero) })

/-- A car that came south down the approach at 4 m/s and stopped in the junction, where the van's
    turn crosses it; its nose settles three degrees to the left, so that whether it makes a left
    turn of its own is decided and not unknown. -/
def crossedVehicle (k : Nat) : RoadUser :=
  Build.withKin
    (Build.withSignals
      (Build.user 3 [.motorVehicle] (pt (-100) (if k ≤ 70 then 1500 - 20 * (k : Int) else 100))
        (if k ≤ 79 then Build.south else rotN (min (k - 79) 2) Build.south)
        (if k ≤ 70 then mps 4 else Q.zero) (m 2, cm 90, cm 75))
      (fun s => { s with turnIndicator := some .off, handSignal := some .noSignal }))
    (fun kk => { kk with yawRate := some (if k ≤ 79 then Q.zero else if k ≤ 81 then degps 30 else Q.zero) })

def crossedY (k : Nat) : Int := if k ≤ 70 then 1500 - 20 * (k : Int) else 100

/-- A scene of a witness: the bodies, the roads, the stated occupancy and the declarations. -/
def sceneOf (t : Timestamp) (users : List RoadUser) (occ : List (TrackId × RegionId))
    (intents : List DeclaredIntent) : Scene :=
  Build.scene t (some 1) users roads [] (some occ) weather [] intents

/-- 141 scenes at the acquisition profile's 50 ms, t = 0 to 7000 ms. -/
def traceOf (f : Nat → Timestamp → Scene) : Trace := Build.trace 141 0 (Units.milliseconds 50) f

/-- The subject braking well short of the junction: 4 m/s, then one metre per second. -/
def clearCarY (k : Nat) : Int :=
  let i : Int := k
  if k ≤ 90 then 3400 - 20 * i else 1600 - 5 * (i - 90)
def clearCarSpeed (k : Nat) : Q := if k ≤ 90 then mps 4 else mps 1

/-- `forbid` (violated): A van within a junction has yielded to the opposing stream, shows its left indicator through the two seconds before its turn is recognized, and turns left. The subject car occupies the opposing approach lane entering the same junction and drives on into the van's path, the two bodies touching. -/
def forbidTrace : Trace :=
  traceOf fun k t =>
    let y : Int := 3590 - 25 * (k : Int)
    sceneOf t [car y (-100) (mps 5), vanAt k .left .noSignal]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

/-- `permit` (compliant): The same junction and the same signalled, yielded left turn by the van. The subject car brakes on its approach and stays more than ten metres clear of the van throughout, no closest approach within the horizon coming near the clearance bound. -/
def permitTrace : Trace :=
  traceOf fun k t =>
    sceneOf t [car (clearCarY k) (-120) (clearCarSpeed k), vanAt k .left .noSignal]
      (southboundOcc 1 (clearCarY k) ++ vanOcc k) [vanIntent false]

/-- `idle` (not_applicable): The subject car occupies the opposing approach lane of a junction in which no vehicle is making a left turn at all: no road user raises the duty, so the rule is not engaged. -/
def idleTrace : Trace :=
  traceOf fun k t =>
    sceneOf t [car (clearCarY k) (-120) (clearCarSpeed k), twitchVehicle k]
      (southboundOcc 1 (clearCarY k) ++ vanOcc k) [vanIntent false]

/-- `blind` (unknown): A van makes a signalled left turn in the junction the subject approaches, but the source does not report whether the van's footprint overlaps the junction region, so whether the turn is the one made in that intersection is unknown. -/
def blindTrace : Trace := permitTrace

/-- `branch_1` (not_applicable): The van turns left in the junction and has yielded to the opposing stream, but its indicator stays off and it gives no arm signal in the window behind the recognition of the turn: the weaker fact -- a turn made without the signal the words require -- leaves the other drivers' duty unraised, and the rule is not engaged. -/
def branch_1Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [car (clearCarY k) (-120) (clearCarSpeed k), vanAt k .off .noSignal]
      (southboundOcc 1 (clearCarY k) ++ vanOcc k) [vanIntent false]

/-- `branch_2` (not_applicable): The van signals left and turns, but it did not comply with its own duty to yield under the first node of this section: it turned across an oncoming vehicle that was within the junction. Having not so yielded, it raises no duty on the other drivers. -/
def branch_2Trace : Trace :=
  traceOf fun k t =>
    sceneOf t [car (clearCarY k) (-120) (clearCarSpeed k), vanAt k .left .noSignal,
               crossedVehicle k]
      (southboundOcc 1 (clearCarY k) ++ vanOcc k ++ southboundOcc 3 (crossedY k))
      [vanIntent true]

/-- `branch_3` (compliant): The van gives no indicator but signals the turn with its arm, and
    turns. The subject car has stopped on its approach well short of the junction: standing, it
    grants precedence. -/
def branch_3Trace : Trace :=
  traceOf fun k t =>
    let y : Int := if k ≤ 100 then 2600 - 20 * (k : Int) else 600
    sceneOf t [car y (-120) (if k ≤ 100 then mps 4 else Q.zero), vanAt k .off .left]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

/-- `branch_4` (violated): The same signalled turn. The subject car holds 8 m/s down the middle of
    its approach, twenty metres short of the van: the bodies are far apart, but the closest
    approach their velocities predict within the horizon is under two metres. -/
def branch_4Trace : Trace :=
  traceOf fun k t =>
    let y : Int := 6800 - 40 * (k : Int)
    sceneOf t [car y (-30) (mps 8), vanAt k .left .noSignal]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

/-- `branch_5` (violated): The same signalled turn. The subject car creeps on until it is less
    than half a metre from the standing van's nose without touching it: their centres do not
    approach within the horizon, and the gap between the nearest points of the two bodies is
    below the clearance. -/
def branch_5Trace : Trace :=
  traceOf fun k t =>
    let i : Int := k
    let y : Int := if k ≤ 119 then 1400 - 10 * i else 210 - 2 * (i - 119)
    sceneOf t [car y (-180) (if k ≤ 119 then mps 2 else Units.micrometresPerSecond 400000),
               vanAt k .left .noSignal]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

/-- `branch_6` (compliant): The same signalled turn. The subject car comes down the far side of
    its approach at 4 m/s: the centres do approach within the horizon, and the closest approach
    stays above the clearance, as does the gap between the bodies. -/
def branch_6Trace : Trace :=
  traceOf fun k t =>
    let y : Int := 3350 - 20 * (k : Int)
    sceneOf t [car y (-200) (mps 4), vanAt k .left .noSignal]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

/-- `branch_7` (not_applicable): The road user on the opposing approach is a bicycle, which the
    aggregate of DEF-NRS-484A-320 does not include: the subject of this duty is a vehicle, so the
    rule is not engaged. -/
def branch_7Trace : Trace :=
  traceOf fun k t =>
    let y : Int := 2000 - 10 * (k : Int)
    sceneOf t [cycle y (-120) (mps 2), vanAt k .left .noSignal]
      ([(1, 21)] ++ vanOcc k) [vanIntent false]

/-- `branch_8` (violated): The van gives no indicator and signals the turn with its arm alone, and
    turns. The subject car holds 8 m/s down the middle of its approach: the closest approach their
    velocities predict within the horizon is under two metres, so it does not grant precedence to
    the vehicle whose arm signal raised the duty. -/
def branch_8Trace : Trace :=
  traceOf fun k t =>
    let y : Int := 6800 - 40 * (k : Int)
    sceneOf t [car y (-30) (mps 8), vanAt k .off .left]
      (southboundOcc 1 y ++ vanOcc k) [vanIntent false]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (6000, 7000)) : Scenario :=
  { name := name
    rule := "NRS_484B_253_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .violated ]

end TrafficSpecWitness.NRS_484B_253_o2
