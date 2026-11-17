/-
  Witnesses for NRS_484B_307_8e.

  Geometry (metres, +x east, +y north), the same in every scene:
    - highway h1 (region 10): the north–south public way, x ∈ [-15, 15] (sidewalks included);
    - highway h2 (region 11): the east–west public way (the intersecting street), y ∈ [-15, 15];
    - intersection i (region 1): x, y ∈ [-10, 10], lying on h1 and h2;
    - approach lane c (region 2): northbound, x ∈ [0, 10], y ∈ [-200, -10], on h1, entering i;
    - cross approach lane k (region 3): westbound, x ∈ [10, 200], y ∈ [0, 10], on h2, entering i;
    - the corner lot: the ground south-east of the corner (e.g. (25..40, -35..-20)), covered by no
      region — private property off every public way.
  Devices: head d1 (100) governs c; head d2 (101) governs k.
  Subject: track 1, a motor vehicle (member of both aggregates), half-extents 2 × 1 × 0.75 m.
  Occupancy is derived from the reference point; every scene carries the incorporated-city
  assumption. Scenes 2 s apart, except branch_1 (20 s apart, so that the 180 s parking window is
  covered and sampled well within half its length). Windows start at the second instant: the first
  one has no previous observation for the "came from off the way" test.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_8e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_8e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def structures : List Structure :=
  [ Build.rect 10 .highway (m (-15)) (m (-200)) (m 15) (m 200)
  , Build.rect 11 .highway (m (-200)) (m (-15)) (m 200) (m 15)
  , { Build.rect 1 .intersection (m (-10)) (m (-10)) (m 10) (m 10) with ways := some [10, 11] }
  , { Build.lane 2 (box 0 (-200) 10 (-10)) Build.north (enters := some 1) with ways := some [10] }
  , { Build.lane 3 (box 10 0 200 10) Build.west (enters := some 1) with ways := some [11] } ]

def devices (d1 d2 : List SignalIndication) : List Device :=
  [ Build.signal 100 [2] d1, Build.signal 101 [3] d2 ]

def subjectAt (x y : Int) (h : Vec) (v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) h v (m 2, m 1, cm 75)

def sceneOf (t : Timestamp) (u : RoadUser) (d1 d2 : List SignalIndication) : Scene :=
  Build.scene t (some 1) [u] structures (devices d1 d2)
    (assumptions := [("asm.within_incorporated_city", true)])

def red : List SignalIndication := [.circularRed]
def green : List SignalIndication := [.circularGreen]

/-- The cut through the corner lot: on c facing red, into the lot, out onto h2 east of i. -/
def cutThrough (k : Nat) : RoadUser :=
  match k with
  | 0 => subjectAt 5 (-50) Build.north (mps 5)
  | 1 => subjectAt 5 (-25) Build.north (mps 5)
  | 2 => subjectAt 25 (-30) Build.east (mps 5)
  | 3 => subjectAt 35 (-25) Build.north (mps 3)
  | 4 => subjectAt 35 (-5) Build.north (mps 5)
  | _ => subjectAt 55 (-5) Build.east (mps 5)

/-- `forbid` (violated): The subject (vehicle, traffic) occupies approach lane c entering intersection i; the head governing c displays circular_red alone; the head governing the cross street's approach lane k (on h2, entering i) displays circular_green. The subject turns right off c into a corner lot, its footprint overlapping no highway region for several observations while moving (never parked), and then comes to occupy h2 outside i. It never occupied i. The place is within an incorporated city. -/
def forbidTrace : Trace :=
  Build.trace 6 0 (Units.seconds 2) fun k t => sceneOf t (cutThrough k) red green

/-- `permit` (compliant): Same scene: the subject halts on c while its head displays circular_red alone, waits until circular_green, enters i and turns right onto h2 through i; at no observation does it come onto h2 from off the way. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 2) fun k t =>
    match k with
    | 0 => sceneOf t (subjectAt 5 (-50) Build.north (mps 5)) red green
    | 1 => sceneOf t (subjectAt 5 (-22) Build.north Q.zero) red green
    | 2 => sceneOf t (subjectAt 5 (-22) Build.north Q.zero) red green
    | 3 => sceneOf t (subjectAt 5 0 Build.north (mps 3)) green red
    | _ => sceneOf t (subjectAt 25 (-5) Build.east (mps 5)) green red

/-- `idle` (not_applicable): The head governing c displays circular_green throughout; the subject passes through i. It never occupied c facing a steady red alone. -/
def idleTrace : Trace :=
  Build.trace 4 0 (Units.seconds 2) fun k t =>
    match k with
    | 0 => sceneOf t (subjectAt 5 (-5) Build.north (mps 5)) green red
    | 1 => sceneOf t (subjectAt 5 5 Build.north (mps 5)) green red
    | 2 => sceneOf t (subjectAt 5 30 Build.north (mps 5)) green red
    | _ => sceneOf t (subjectAt 5 55 Build.north (mps 5)) green red

/-- `blind` (unknown): As in forbid, but the state of the head governing c is never observed (dev.traffic_signal absent); the subject cuts through the corner lot onto h2. -/
def blindTrace : Trace :=
  Build.trace 6 0 (Units.seconds 2) fun k t => sceneOf t (cutThrough k) red green

/-- `branch_1` (compliant): As in forbid, but the subject parks in the corner lot (at rest for longer than the parking duration) before leaving onto h2; while it waited on c facing the red it complied, and after parking the cut-through condition no longer holds. -/
def branch_1Trace : Trace :=
  Build.trace 16 0 (Units.seconds 20) fun k t =>
    let u :=
      if k == 0 then subjectAt 5 (-60) Build.north (mps 5)
      else if k == 1 then subjectAt 5 (-25) Build.north (mps 5)
      else if k == 2 then subjectAt 25 (-30) Build.east (mps 3)
      else if k ≤ 13 then subjectAt 30 (-30) Build.east Q.zero
      else if k == 14 then subjectAt 30 (-28) Build.north (mps 3)
      else subjectAt 35 (-5) Build.north (mps 5)
    sceneOf t u red green

/-- `branch_2` (not_applicable): As in forbid, but every head governing an approach of h2 into i displays circular_red throughout (an all-red interval): the intersecting street's traffic faces red. -/
def branch_2Trace : Trace :=
  Build.trace 6 0 (Units.seconds 2) fun k t => sceneOf t (cutThrough k) red red

/-- `branch_3` (violated): as forbid, but the red head (alone) governs the intersection i rather
    than the approach lane c; the subject faces it on c and cuts through the corner lot onto h2. -/
def branch_3Trace : Trace :=
  Build.trace 6 0 (Units.seconds 2) fun k t =>
    Build.scene t (some 1) [cutThrough k] structures
      [ Build.signal 100 [1] red, Build.signal 101 [3] green ]
      (assumptions := [("asm.within_incorporated_city", true)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_307_8e"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (2000, 10000))
  , witness "permit" permitTrace .compliant (window := some (2000, 8000))
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"] (window := some (2000, 10000))
  , witness "branch_1" branch_1Trace .compliant (window := some (20000, 300000))
  , witness "branch_2" branch_2Trace .notApplicable (window := some (2000, 10000))
  , witness "branch_3" branch_3Trace .violated (window := some (2000, 10000)) ]

end TrafficSpecWitness.NRS_484B_307_8e
