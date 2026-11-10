/-
  Witnesses for NRS_484B_250_4_o1.

  Geometry (metres, +x east, +y north). The approach lane c (region 10) runs east from x = -100 to
  x = 0 between y = 0 and y = 4, enters intersection i (region 20, x 0..20, y -6..10), and lies on
  highway 50; i lies on highways 50 and 60, so 60 is the through highway of c's approach. Stop line
  s (region 30) is the strip x -2..-1.5 across c; crosswalk w (region 40) is the strip x -4..-1,
  y -6..10. Each marks c (associations observed). Highway 50 is the east-west way (x -100..40,
  y -8..12), highway 60 the north-south one (x -2..22, y -60..60). Where no mark is recorded for
  c (`branch_2`, `branch_6`), the opposite approach d (region 11, x 20..100, y 6..10, westbound)
  carries crosswalk 41 (x 21..24), which marks d only. Signal head 1 is uncovered and governs i (in
  `branch_3`, c only); it is dark and inoperative, except in `idle`, where it shows circular green.

  x (track 1) is a car 4 m long and 2 m wide, centred on y = 2, heading east; one observation a
  second. Occupancy is stated from the footprint (a body across c and i occupies both). Each
  witness speaks about the entry observation, at which x's front first overlaps i.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: x ↦ 1

/-- Approach lane c, entering i, on highway 50. -/
def laneC : Structure :=
  { Build.lane 10 [(m (-100), m 0), (m 0, m 0), (m 0, m 4), (m (-100), m 4)] Build.east (enters := some 20)
    with ways := some [50] }

/-- Intersection i, on both highways. -/
def interI : Structure :=
  { Build.rect 20 .intersection (m 0) (m (-6)) (m 20) (m 10) with ways := some [50, 60] }

/-- Stop line s, marking c. -/
def stopS : Structure :=
  { Build.rect 30 .stopLine (m (-2)) (m 0) (cm (-150)) (m 4) with entranceOf := [10], entranceObserved := true }

/-- Crosswalk w, marking c. -/
def crossW : Structure :=
  { Build.rect 40 .crosswalk (m (-4)) (m (-6)) (m (-1)) (m 10) with entranceOf := [10], entranceObserved := true }

/-- The way c lies on, and the crossing (through) highway. -/
def wayA : Structure := Build.rect 50 .highway (m (-100)) (m (-8)) (m 40) (m 12)
def wayB : Structure := Build.rect 60 .highway (m (-2)) (m (-60)) (m 22) (m 60)

/-- The opposite approach d, entering i from the east, and the crosswalk that marks it only. -/
def laneD : Structure :=
  { Build.lane 11 [(m 20, m 6), (m 100, m 6), (m 100, m 10), (m 20, m 10)] Build.west (enters := some 20)
    with ways := some [50] }
def crossE : Structure :=
  { Build.rect 41 .crosswalk (m 21) (m (-6)) (m 24) (m 10) with entranceOf := [11], entranceObserved := true }

/-- The inoperative head governing `gov`. -/
def darkHead (gov : List RegionId) : Device :=
  { Build.signal 1 gov [.dark] with uncovered := some true, inoperative := some true }

/-- The operating head governing i. -/
def greenHead : Device :=
  { Build.signal 1 [20] [.circularGreen] with uncovered := some true, inoperative := some false }

/-- Lane e (region 12), overlapping the last 10 m of c but recorded as an approach to another
    intersection (region 21, far to the north), and that intersection. -/
def laneE : Structure :=
  Build.lane 12 [(m (-10), m 0), (m 0, m 0), (m 0, m 4), (m (-10), m 4)] Build.east (enters := some 21)
def interN : Structure := Build.rect 21 .intersection (m 0) (m 100) (m 20) (m 120)

/-- An operating head governing lanes e and d, neither of them x's approach into i. -/
def greenOtherHead : Device :=
  { Build.signal 2 [12, 11] [.circularGreen] with uncovered := some true, inoperative := some false }

/-- A second, operating head governing the approach lane c only. -/
def greenLaneHead : Device :=
  { Build.signal 2 [10] [.circularGreen] with uncovered := some true, inoperative := some false }

/-- x with its centre at `cx` (y = 2), heading east at `v`. -/
def car (cx v : Q) (sight : Option (List (RegionId × Q)) := none) : RoadUser :=
  { Build.user 1 [.motorVehicle] (cx, m 2) Build.east v (m 2, m 1, cm 75) with sightAlongWay := sight }

/-- A scene whose occupancy is x's footprint overlap with each region outline. -/
def sceneAt (t : Timestamp) (u : RoadUser) (structures : List Structure) (devices : List Device) : Scene :=
  let s0 := Build.scene t (some 1) [u] structures devices
  let occ : List (TrackId × RegionId) :=
    match footprint s0 1 with
    | none => []
    | some fp => structures.filterMap fun st =>
      match st.boundary with
      | some poly => if Geom.polygonsOverlap fp poly then some (1, st.id) else none
      | none => none
  Build.scene t (some 1) [u] structures devices (occupies := some occ)

/-- One observation a second through the (centre x, speed) list. -/
def drive (pts : List (Q × Q)) (structures : List Structure) (devices : List Device)
    (sight : Option (List (RegionId × Q)) := none) : Trace :=
  Build.trace pts.length 0 (Units.seconds 1) fun k t =>
    let (cx, v) := pts.getD k (Q.zero, Q.zero)
    sceneAt t (car cx v sight) structures devices

/-- Never halting: 10 m/s from 40 m out, 3 m/s at s, front into i at t = 6 s. -/
def rollingPts : List (Q × Q) :=
  [(m (-40), mps 10), (m (-30), mps 10), (m (-20), mps 10), (m (-12), mps 6), (m (-7), mps 4),
   (m (-4), mps 3), (m (-1), mps 3), (m 2, mps 3)]

/-- `forbid` (violated): A dev.traffic_signal head, uncovered, governs intersection i and is dev.inoperative. x (a passenger car) occupies lane c with st.lane_enters c i; stop line s has st.entrance_of s c. x approaches from 60 m upstream at 10 m/s, slows to 3 m/s near s and enters i without kin.speed ever falling to the speed tolerance. -/
def forbidTrace : Trace :=
  drive rollingPts [laneC, interI, stopS, wayA, wayB] [darkHead [20]]

/-- `permit` (compliant): Same scene; x halts (kin.speed 0) with its front 0.5 m short of s, on c, then enters i. -/
def permitTrace : Trace :=
  drive [(m (-40), mps 10), (m (-30), mps 10), (m (-20), mps 8), (m (-12), mps 5), (m (-7), mps 2),
         (cm (-450), mps 0), (cm (-450), mps 0), (m (-1), mps 3)]
    [laneC, interI, stopS, wayA, wayB] [darkHead [20]]

/-- `idle` (not_applicable): The signal head governing i is operating (state circular_green, not dev.inoperative) when x enters i without halting. -/
def idleTrace : Trace :=
  drive rollingPts [laneC, interI, stopS, wayA, wayB] [greenHead]

/-- `blind` (unknown): As forbid, but the source does not observe dev.inoperative, so whether the signal was inoperative at the entry is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): No stop line is recorded for c (association observed, empty); crosswalk w has st.entrance_of w c. x halts with its footprint overlapping w and then enters i. -/
def branch_1Trace : Trace :=
  drive [(m (-40), mps 10), (m (-30), mps 10), (m (-20), mps 8), (m (-12), mps 5), (m (-9), mps 2),
         (cm (-450), mps 0), (cm (-450), mps 0), (m (-1), mps 3)]
    [laneC, interI, crossW, wayA, wayB] [darkHead [20]]

/-- `branch_2` (compliant): Neither a stop line nor a crosswalk marks c (associations observed). x halts outside i, 1 m from its edge, where st.sight_along_way to the crossing highway is 120 m, then enters. -/
def branch_2Trace : Trace :=
  drive [(m (-40), mps 10), (m (-30), mps 10), (m (-20), mps 8), (m (-12), mps 5), (m (-6), mps 2),
         (m (-3), mps 0), (m (-3), mps 0), (m 1, mps 3)]
    [laneC, interI, laneD, crossE, wayA, wayB] [darkHead [20]] (sight := some [(60, m 120)])

/-- `branch_3` (violated): the inoperative head governs only the approach lane c, not i itself;
    x rolls into i as in forbid without halting. -/
def branch_3Trace : Trace :=
  drive rollingPts [laneC, interI, stopS, wayA, wayB] [darkHead [10]]

/-- `branch_4` (not_applicable): the head governing i is inoperative, but a second head governing
    x's approach lane c shows circular green; x rolls in without halting. -/
def branch_4Trace : Trace :=
  drive rollingPts [laneC, interI, stopS, wayA, wayB] [darkHead [20], greenLaneHead]

/-- `branch_5` (compliant): no stop line; crosswalk w marks c. x halts with its front 0.5 m short
    of w, off it, then enters i. -/
def branch_5Trace : Trace :=
  drive [(m (-40), mps 10), (m (-30), mps 10), (m (-20), mps 8), (m (-13), mps 5), (m (-10), mps 2),
         (cm (-650), mps 0), (cm (-650), mps 0), (m (-1), mps 3)]
    [laneC, interI, crossW, wayA, wayB] [darkHead [20]]

/-- `branch_6` (violated): neither a stop line nor a crosswalk marks c; the view along highway 60 is
    120 m, but x rolls into i without halting. -/
def branch_6Trace : Trace :=
  drive rollingPts [laneC, interI, laneD, crossE, wayA, wayB] [darkHead [20]] (sight := some [(60, m 120)])

/-- `branch_7` (violated): as forbid, with a second head operating that governs lane e (which x
    occupies before the entry, but which enters another intersection) and the opposite approach d
    (which x never occupies): neither is x's approach into i, so the dark head decides and x,
    rolling in without halting, violates. -/
def branch_7Trace : Trace :=
  drive rollingPts [laneC, laneE, laneD, interI, interN, stopS, wayA, wayB] [darkHead [20], greenOtherHead]

/-- `history_boundary` (unknown): The recording begins with x already on c within the stopping zone of s, rolling at 1 m/s; no halt is recorded before x enters the inoperative-signal intersection, and no approach start is visible. -/
def history_boundaryTrace : Trace :=
  drive [(cm (-450), mps 1), (cm (-350), mps 1), (cm (-250), mps 1), (cm (-150), mps 1)]
    [laneC, interI, stopS, wayA, wayB] [darkHead [20]]

def witness (name : String) (τ : Trace) (expected : Verdict) (at_ : Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (at_, at_)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 6000
  , witness "permit" permitTrace .compliant 7000
  , witness "idle" idleTrace .notApplicable 6000
  , witness "blind" blindTrace (.unknown []) 6000 ["dev.inoperative"]
  , witness "branch_1" branch_1Trace .violated 7000
  , witness "branch_2" branch_2Trace .compliant 7000
  , witness "branch_3" branch_3Trace .violated 6000
  , witness "branch_4" branch_4Trace .notApplicable 6000
  , witness "branch_5" branch_5Trace .compliant 7000
  , witness "branch_6" branch_6Trace .violated 6000
  , witness "branch_7" branch_7Trace .violated 6000
  , witness "history_boundary" history_boundaryTrace (.unknown []) 3000 (boundary := "the approach start of x on c (its last observation outside the stopping zone of s), before the recording begins") ]

end TrafficSpecWitness.NRS_484B_250_4_o1
