/-
  Witnesses for NRS_484B_307_9b_o2.

  Geometry (decimetres in the frames, +x east, +y north): approach lane c (10) x 0..4 m, y −30..0 m,
  northbound, entering intersection i (20) x −6..10 m, y 0..10 m; exit lanes e (30) north of i,
  f (40) east of i (y 4..8 m) and g (50) west of i (y 4..8 m). Signal head s (100) governs c (or,
  in branch_2 and branch_5, i only). x has half-length 1 m, half-width 0.5 m; occupancy is stated from its
  footprint (closed overlap). One scene every 50 ms; moving at 20 m/s (1 m per scene), halted at 0.
  x is at y = −4.5 m while halted (footprint clear of i); its entry into i is at y = −0.5 m
  (index 13), its leaving of i at y = 11.5 m (index 25) going straight. In the turning branches it
  turns 90° inside i (yaw rate ±600 °/s over three scenes) and leaves east or west.
  Display schedule: one rise of circular_red + green_arrow at index 5 (forbid, history_boundary,
  ... ), or three rises at indices 3, 5 and 7 during the halt at indices 2..9 (permit and branches);
  circular_red alone otherwise. Every figure here is the witness's own and appears nowhere in the
  rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def dm (n : Int) : Q := Units.centimetres (n * 10)

-- Binders ↦ tracks: x ↦ 1

def cId : RegionId := 10
def iId : RegionId := 20
def eId : RegionId := 30
def fId : RegionId := 40
def gId : RegionId := 50
def sId : DeviceId := 100

/-- Region boxes, decimetres: id, x0, y0, x1, y1. -/
def boxes : List (RegionId × Int × Int × Int × Int) :=
  [(cId, 0, -300, 40, 0), (iId, -60, 0, 100, 100), (eId, 0, 100, 40, 400),
   (fId, 100, 40, 400, 80), (gId, -400, 40, -60, 80)]

def corners (x0 y0 x1 y1 : Int) : List Vec :=
  [(dm x0, dm y0), (dm x1, dm y0), (dm x1, dm y1), (dm x0, dm y1)]

def structures : List Structure :=
  [ Build.lane cId (corners 0 (-300) 40 0) Build.north (enters := some iId)
  , Build.rect iId .intersection (dm (-60)) (dm 0) (dm 100) (dm 100)
  , Build.lane eId (corners 0 100 40 400) Build.north
  , Build.lane fId (corners 100 40 400 80) Build.east
  , Build.lane gId (corners (-400) 40 (-60) 80) Build.west ]

/-- One observation of x: position (dm), heading, speed, yaw rate. -/
structure Frame where
  px : Int
  py : Int
  hd : Vec
  spd : Q
  yaw : Q := Q.zero

/-- Half-extents (dm) of the box bounding x's footprint: exact for an axis-aligned heading, a
    bound for a diagonal one (used only deep inside i). -/
def halfBox (h : Vec) : Int × Int :=
  if Q.isZero h.1 then (5, 10) else if Q.isZero h.2 then (10, 5) else (12, 12)

def occOf (f : Frame) : List RegionId :=
  let (hx, hy) := halfBox f.hd
  boxes.filterMap fun (r, x0, y0, x1, y1) =>
    if f.px - hx ≤ x1 ∧ x0 ≤ f.px + hx ∧ f.py - hy ≤ y1 ∧ y0 ≤ f.py + hy then some r else none

def fast : Q := Units.metresPerSecond 20
def turnYaw : Q := Units.degrees 600

def northAt (py : Int) (spd : Q) : Frame := { px := 20, py := py, hd := Build.north, spd := spd }

def approach : List Frame := [northAt (-65) fast, northAt (-55) fast]
def halt (n : Nat) : List Frame := List.replicate n (northAt (-45) Q.zero)
/-- From the halt line to beyond i, straight: entry at −5 dm, leaving at 115 dm. -/
def through : List Frame := (List.range 17).map fun j => northAt (-35 + 10 * Int.ofNat j) fast
def intoI : List Frame := (List.range 9).map fun j => northAt (-35 + 10 * Int.ofNat j) fast

def rightTurn : List Frame :=
  intoI ++
  [ { px := 30, py := 55, hd := (Units.ratio 3 5, Units.ratio 4 5), spd := fast, yaw := Q.neg turnYaw }
  , { px := 40, py := 60, hd := (Units.ratio 4 5, Units.ratio 3 5), spd := fast, yaw := Q.neg turnYaw }
  , { px := 50, py := 60, hd := Build.east, spd := fast, yaw := Q.neg turnYaw } ] ++
  (List.range 8).map fun j => { px := 60 + 10 * Int.ofNat j, py := 60, hd := Build.east, spd := fast }

def leftTurn : List Frame :=
  intoI ++
  [ { px := 10, py := 55, hd := (Units.ratio (-3) 5, Units.ratio 4 5), spd := fast, yaw := turnYaw }
  , { px := 0, py := 60, hd := (Units.ratio (-4) 5, Units.ratio 3 5), spd := fast, yaw := turnYaw }
  , { px := -10, py := 60, hd := Build.west, spd := fast, yaw := turnYaw } ] ++
  (List.range 8).map fun j => { px := -20 - 10 * Int.ofNat j, py := 60, hd := Build.west, spd := fast }

def red : List SignalIndication := [.circularRed]
def redArrow (d : ArrowDir) : List SignalIndication := [.circularRed, .greenArrow d]

/-- One rise of the display, at index 5. -/
def oneRise (d : ArrowDir) (k : Nat) : Option (List SignalIndication) :=
  some (if k ≥ 5 then redArrow d else red)

/-- Three rises of the display, at indices 3, 5 and 7. -/
def threeRises (d : ArrowDir) (k : Nat) : Option (List SignalIndication) :=
  some (if k = 3 ∨ k = 5 ∨ k ≥ 7 then redArrow d else red)

def sceneOf (cls : List RoadUserClass) (govern : List RegionId) (shows : Option (List SignalIndication))
    (f : Frame) (t : Timestamp) : Scene :=
  let u := Build.withKin (Build.user 1 cls (dm f.px, dm f.py) f.hd f.spd (m 1, cm 50, cm 50))
    fun k => { k with yawRate := some f.yaw }
  Build.scene t (some 1) [u] structures [{ Build.signal sId govern [] with indications := shows }]
    (occupies := some ((occOf f).map fun r => (1, r)))

def mkTrace (cls : List RoadUserClass) (govern : List RegionId) (frames : List Frame)
    (sig : Nat → Option (List SignalIndication)) : Trace :=
  Build.trace frames.length 0 (Units.milliseconds 50) fun k t =>
    sceneOf cls govern (sig k) (frames.getD k (northAt 0 Q.zero)) t

/-- `forbid` (violated): x (ru.motorcycle), recorded from upstream, halts on c; s governing c rises to circular_red with green_arrow(left) once during the wait; x then enters i under that display and leaves straight through: the rises counted do not exceed two. -/
def forbidTrace : Trace :=
  mkTrace [.motorcycle] [cId] (approach ++ halt 8 ++ through) (oneRise .left)

/-- `permit` (compliant): x (ru.bicycle), recorded from upstream, halts on c and stays halted while s's circular_red with green_arrow(left) display rises three times, never showing circular_green or green_arrow(straight); x then enters under the display and leaves straight through. -/
def permitTrace : Trace :=
  mkTrace [.bicycle] [cId] (approach ++ halt 8 ++ through) (threeRises .left)

/-- `idle` (not_applicable): x is a ru.pedestrian, a class decided outside all five aggregates; it waits on c and then goes straight through i under circular_red with green_arrow(left). -/
def idleTrace : Trace :=
  mkTrace [.pedestrian] [cId] (approach ++ halt 8 ++ through) (threeRises .left)

/-- `blind` (unknown): x, recorded from upstream, halts on c, waits and then goes straight through, but the source does not observe s's state during the wait or at the entry. -/
def blindTrace : Trace :=
  mkTrace [.bicycle] [cId] (approach ++ halt 8 ++ through) (fun _ => none)

/-- `branch_1` (violated): x halts on c through three rises of circular_red with green_arrow(left), but during the wait s also displays circular_green for c, which x lets pass; x later enters straight through under the red with the arrow: the signal did change, so the condition fails. -/
def branch_1Trace : Trace :=
  mkTrace [.motorcycle] [cId] (approach ++ halt 8 ++ through)
    (fun k => if k = 4 then some [.circularGreen] else threeRises .left k)

/-- `history_boundary` (unknown): x's recording begins with x already halted on c; a single rise of circular_red with green_arrow(left) is recorded before x enters i straight through, and the start of the wait is not recorded. -/
def history_boundaryTrace : Trace :=
  mkTrace [.motorcycle] [cId] (halt 10 ++ through) (oneRise .left)

/-- `branch_2` (compliant): s governs the intersection i only, not c; x waits on c through three
    rises of circular_red with green_arrow(left) and goes straight through. -/
def branch_2Trace : Trace :=
  mkTrace [.bicycle] [iId] (approach ++ halt 8 ++ through) (threeRises .left)

/-- `branch_3` (violated): under circular_red with green_arrow(left), x waits through one rise only
    and turns right, opposite the arrow. -/
def branch_3Trace : Trace :=
  mkTrace [.moped] [cId] (approach ++ halt 8 ++ rightTurn) (oneRise .left)

/-- `branch_4` (violated): under circular_red with green_arrow(right), x waits through one rise
    only and turns left, opposite the arrow. -/
def branch_4Trace : Trace :=
  mkTrace [.bicycle] [cId] (approach ++ halt 8 ++ leftTurn) (oneRise .right)

/-- `branch_5` (violated): s governs the intersection i only; x waits on c through one rise of
    circular_red with green_arrow(left) and goes straight through. -/
def branch_5Trace : Trace :=
  mkTrace [.motorcycle] [iId] (approach ++ halt 8 ++ through) (oneRise .left)

/-- The instants a witness speaks about: every scene after the first (the first has no scene
    before it, so no entry or leaving is decided there). -/
def spoken (τ : Trace) : Option (Timestamp × Timestamp) :=
  match τ[1]?, τ.getLast? with
  | some a, some b => some (a.t, b.t)
  | _, _ => none

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := spoken τ
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch_1Trace .violated
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the start of x's halt on c, which lies before the recording")
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_9b_o2
