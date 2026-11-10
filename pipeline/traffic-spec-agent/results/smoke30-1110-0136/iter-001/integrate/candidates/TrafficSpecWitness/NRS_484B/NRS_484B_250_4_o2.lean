/-
  Witnesses for NRS_484B_250_4_o2.

  The intersection i (region 10) is the square (-10,-10)–(10,10). x (track 1) approaches from the
  west on lane c (11, (-50,-8)–(-10,0), eastward, entering i) along y = -4; the crossing approach
  cy (12, (0,-50)–(8,-10), northward, entering i) is y's in branch_1. Marks, by variant:
    stop line on c (13, x ∈ [-12.5,-12]); stop line on cy (14, y ∈ [-15.5,-15]);
    crosswalk on c (15, x ∈ [-14,-10]); crosswalk on cy (16, y ∈ [-14,-10]);
    highways h1 (20, (-60,-10)–(60,10), the east–west way, c lies on it) and h2 (21,
    (-10,-60)–(10,60), the north–south way); i lies on both.
  Bodies are 4.5 m × 1.8 m. Instants are 1 s apart, k = 0 … 6. x starts outside c (k0, x = -56),
  runs onto c (k1), halts with its front 0.75 m short of the governing mark at k2–k3 (centre at
  -15.5 for the stop line, -17 for the crosswalk, -13 for the intersection edge: 0.75 m < 2 m,
  upstream), moves on at 3 m/s (k4 at -11), enters i at k5 (-9) and is at -6 at k6.
  y (track 2), in forbid, comes south along x = -2 at 5 m/s and is first within i at k6 at (-2,7):
  closest approach to x in 1.97 s at 2.2 m (< 4 m within 3 s). In permit y leaves i southward along
  x = 4, ahead of x: closest approach 9.6 m. In branch_1 y halts on cy at k1 (centre (4,-13)),
  before x halts at k2, and starts north at 4 m/s at k4 still outside i while x enters at k4:
  closest approach 2.5 m in 2.6 s.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: x ↦ 1

def car (id : TrackId) (p : Vec) (h : Vec) (v : Q) : RoadUser :=
  Build.user id [.motorVehicle] p h v (cm 225, cm 90, cm 75)

-- Regions
def iPlain : Structure := Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def cPlain : Structure :=
  Build.lane 11 [(m (-50), m (-8)), (m (-10), m (-8)), (m (-10), m 0), (m (-50), m 0)] Build.east
    (enters := some 10)
def cyLane : Structure :=
  Build.lane 12 [(m 0, m (-50)), (m 8, m (-50)), (m 8, m (-10)), (m 0, m (-10))] Build.north
    (enters := some 10)
def stopLineC : Structure :=
  { Build.rect 13 .stopLine (cm (-1250)) (m (-8)) (m (-12)) (m 0) with entranceOf := [11], entranceObserved := true }
def stopLineCy : Structure :=
  { Build.rect 14 .stopLine (m 0) (cm (-1550)) (m 8) (m (-15)) with entranceOf := [12], entranceObserved := true }
def crosswalkC : Structure :=
  { Build.rect 15 .crosswalk (m (-14)) (m (-8)) (m (-10)) (m 0) with entranceOf := [11], entranceObserved := true }
def crosswalkCy : Structure :=
  { Build.rect 16 .crosswalk (m 0) (m (-14)) (m 8) (m (-10)) with entranceOf := [12], entranceObserved := true }
def iWays : Structure := { iPlain with ways := some [20, 21] }
def cWays : Structure := { cPlain with ways := some [20] }
def h1 : Structure := Build.rect 20 .highway (m (-60)) (m (-10)) (m 60) (m 10)
def h2 : Structure := Build.rect 21 .highway (m (-10)) (m (-60)) (m 10) (m 60)

def stopLineMap : List Structure := [iPlain, cPlain, cyLane, stopLineC]
def crosswalkMap : List Structure := [iPlain, cPlain, cyLane, crosswalkC, stopLineCy]
def edgeMap : List Structure := [iWays, cWays, cyLane, stopLineCy, crosswalkCy, h1, h2]

-- Devices
def darkHead (id : DeviceId) (gov : List RegionId) : Device :=
  { Build.signal id gov [.dark] with uncovered := some true, inoperative := some true }
def greenHead (id : DeviceId) (gov : List RegionId) : Device :=
  { Build.signal id gov [.circularGreen] with uncovered := some true, inoperative := some false }
def coveredHead (id : DeviceId) (gov : List RegionId) : Device :=
  { Build.signal id gov [.circularRed] with uncovered := some false, inoperative := some false }

/-- x's approach: outside c, onto c, halted with its centre at `haltX` (k2, k3), on, into i. -/
def xHalting (haltX : Q) (k : Nat) : RoadUser :=
  match k with
  | 0 => car 1 (m (-56), m (-4)) Build.east (mps 8)
  | 1 => car 1 (m (-40), m (-4)) Build.east (mps 8)
  | 2 | 3 => car 1 (haltX, m (-4)) Build.east Q.zero
  | 4 => car 1 (m (-11), m (-4)) Build.east (mps 3)
  | 5 => car 1 (m (-9), m (-4)) Build.east (mps 3)
  | _ => car 1 (m (-6), m (-4)) Build.east (mps 3)

/-- x never halting: above the speed tolerance throughout. -/
def xRolling (k : Nat) : RoadUser :=
  match k with
  | 0 => car 1 (m (-56), m (-4)) Build.east (mps 8)
  | 1 => car 1 (m (-40), m (-4)) Build.east (mps 8)
  | 2 => car 1 (m (-30), m (-4)) Build.east (mps 6)
  | 3 => car 1 (m (-20), m (-4)) Build.east (mps 6)
  | 4 => car 1 (m (-11), m (-4)) Build.east (mps 3)
  | 5 => car 1 (m (-9), m (-4)) Build.east (mps 3)
  | _ => car 1 (m (-6), m (-4)) Build.east (mps 3)

/-- y crossing x's path southward along x = -2, first within i at k6. -/
def yCrossing (k : Nat) : RoadUser :=
  car 2 (m (-2), m (37 - 5 * (k : Int))) Build.south (mps 5)

/-- y leaving i southward along x = 4, ahead of x. -/
def yLeaving (k : Nat) : RoadUser :=
  car 2 (m 4, m (24 - 5 * (k : Int))) Build.south (mps 5)

def sceneTrace (xs : Nat → RoadUser) (ys : Option (Nat → RoadUser)) (structures : List Structure)
    (devices : List Device) : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (match ys with
       | some y => [xs k, y k]
       | none => [xs k])
      structures devices

/-- `forbid` (violated): Intersection i's only signal head is uncovered and dev.inoperative. x halts at the stop line of its approach lane c, then moves into i at 4 m/s while vehicle y, within i on the crossing way, crosses x's path; prim.closest_approach_distance is 1 m at 1.2 s. -/
def forbidTrace : Trace :=
  sceneTrace (xHalting (cm (-1550))) (some yCrossing) stopLineMap [darkHead 30 [10]]

/-- `permit` (compliant): Same, but x moves into i only while y, still within i, is leaving on the far side: predicted closest approach 9 m. -/
def permitTrace : Trace :=
  sceneTrace (xHalting (cm (-1550))) (some yLeaving) stopLineMap [darkHead 30 [10]]

/-- `idle` (not_applicable): The signal governing i shows circular_green (not inoperative) when x enters; x moves through i next to y. -/
def idleTrace : Trace :=
  sceneTrace (xHalting (cm (-1550))) (some yCrossing) stopLineMap [greenHead 30 [10]]

/-- `blind` (unknown): As forbid, but dev.inoperative is not observed, so the condition at the entry is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): y halted on its approach cy before x halted at its stop line; as x moves into i, y starts into i and their predicted closest approach is 0.8 m within 1.5 s.
    Here x runs on c from the first instant, halts at k2–k3 and enters i at k4; y halts on cy at
    k1–k3 and starts at k4, still outside i; the only head governs c and cy, not i. -/
def branch_1Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let x := match k with
      | 0 => car 1 (m (-45), m (-4)) Build.east (mps 8)
      | 1 => car 1 (m (-30), m (-4)) Build.east (mps 8)
      | 2 | 3 => car 1 (cm (-1550), m (-4)) Build.east Q.zero
      | _ => car 1 (m (-8), m (-4)) Build.east (mps 4)
    let y := match k with
      | 0 => car 2 (m 4, m (-30)) Build.north (mps 8)
      | 1 | 2 | 3 => car 2 (m 4, m (-13)) Build.north Q.zero
      | _ => car 2 (m 4, cm (-1250)) Build.north (mps 4)
    Build.scene t (some 1) [x, y] stopLineMap [darkHead 30 [11, 12]]

/-- `branch_2` (not_applicable): x halts at its stop line, then moves through i with no other road user in the scene. -/
def branch_2Trace : Trace :=
  sceneTrace (xHalting (cm (-1550))) none stopLineMap [darkHead 30 [10]]

/-- `branch_3` (not_applicable): As forbid, but x never halted on c before entering (kin.speed stays above the tolerance): the condition 'after making such a stop' does not hold. -/
def branch_3Trace : Trace :=
  sceneTrace xRolling (some yCrossing) stopLineMap [darkHead 30 [10]]

/-- `branch_4` (violated): no stop line marks c (one marks cy); x halts before the crosswalk marking c, then crosses into i into y's path as in forbid. -/
def branch_4Trace : Trace :=
  sceneTrace (xHalting (m (-17))) (some yCrossing) crosswalkMap [darkHead 30 [10]]

/-- `branch_5` (violated): neither a stop line nor a crosswalk marks c (both mark cy); x halts outside i at c's entrance end, seeing 100 m along h2 (the crossing way) and 30 m along h1 (its own), then crosses into y's path as in forbid. -/
def branch_5Trace : Trace :=
  sceneTrace (fun k => { xHalting (m (-13)) k with sightAlongWay := some [(20, m 30), (21, m 100)] })
    (some yCrossing) edgeMap [darkHead 30 [10]]

/-- `branch_6` (violated): as forbid, with a covered, working head also governing i and an uncovered green head governing only cy: neither is one that must be inoperative. -/
def branch_6Trace : Trace :=
  sceneTrace (xHalting (cm (-1550))) (some yCrossing) stopLineMap
    [darkHead 30 [10], coveredHead 31 [10], greenHead 32 [12]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o2"
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
  , witness "blind" blindTrace (.unknown []) ["dev.inoperative"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_4_o2
