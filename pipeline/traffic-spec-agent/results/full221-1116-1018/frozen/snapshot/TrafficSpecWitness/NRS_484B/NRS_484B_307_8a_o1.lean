/-
  Witnesses for NRS_484B_307_8a_o1.

  Geometry (the witness's own figures, nowhere in the rule):
    lane c (10): x ∈ [-80, 0], y ∈ [0, 4], direction east, entering intersection i (20);
    intersection i (20): x ∈ [0, 24], y ∈ [-12, 16];
    stop line L (30): x ∈ [-7.5, -7], y ∈ [0, 4]; crosswalk X (40): x ∈ [-5, -2], y ∈ [0, 4];
    where a mark does not mark c it carries an observed, empty list of entrances
    (stop line 31 and crosswalk 41 lie beyond the intersection);
    signal head s (50) governs c.
  The car (track 1, a motor vehicle) drives east along y = 2, half-length 2 m, half-width 1 m, so
  its body spans [x - 2, x + 2]. Observations every second; occupancy is stated per scene (a body
  across two regions). With p.stop_point_tolerance = 2 m and p.halt_speed_tolerance = 0.1 m/s a
  body 1 m short of a place at speed 0 is a halt in the zone, a body 4 m or more short of it is
  outside the zone (an approach start), and every moving speed is ≥ 1 m/s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_8a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_8a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def cId : RegionId := 10
def iId : RegionId := 20
def lId : RegionId := 30
def xId : RegionId := 40

def laneC : Structure :=
  Build.lane cId [(m (-80), m 0), (m 0, m 0), (m 0, m 4), (m (-80), m 4)] Build.east (enters := some iId)
def isect : Structure := Build.rect iId .intersection (m 0) (m (-12)) (m 24) (m 16)
def stopLine (id : RegionId) (x0 x1 : Q) (entrances : List RegionId) : Structure :=
  { Build.rect id .stopLine x0 (m 0) x1 (m 4) with entranceOf := entrances, entranceObserved := true }
def crosswalk (id : RegionId) (x0 x1 : Q) (entrances : List RegionId) : Structure :=
  { Build.rect id .crosswalk x0 (m 0) x1 (m 4) with
      entranceOf := entrances, entranceObserved := true, marked := some true }

/-- Stop line and crosswalk both marking c. -/
def markedApproach : List Structure :=
  [laneC, isect, stopLine lId (cm (-750)) (m (-7)) [cId], crosswalk xId (m (-5)) (m (-2)) [cId]]
/-- No stop line or crosswalk marks c: the ones present list their entrances, which exclude c. -/
def unmarkedApproach : List Structure :=
  [laneC, isect, stopLine 31 (m 30) (cm 3050) [], crosswalk 41 (m 25) (m 28) []]
/-- A crosswalk marks c; the only stop line marks no carrier. -/
def crosswalkApproach : List Structure :=
  [laneC, isect, stopLine 31 (m 30) (cm 3050) [], crosswalk xId (m (-5)) (m (-2)) [cId]]

def head (shows : List SignalIndication) : Device := Build.signal 50 [cId] shows
def red : List Device := [head [.circularRed]]

def car (x v : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, m 2) Build.east v (m 2, m 1, m 1)

/-- One observation per second: the car's reference x, its speed, the regions its body overlaps. -/
def drive (structures : List Structure) (devices : List Device) (pts : List (Q × Q × List RegionId)) : Trace :=
  Build.trace pts.length 0 (Units.seconds 1) fun k t =>
    let (x, v, regs) := pts.getD k (Q.zero, Q.zero, [])
    Build.scene t (some 1) [car x v] structures devices (occupies := some (regs.map fun r => (1, r)))

/-- 12 m/s throughout: 36 m, 24 m and 12 m of body-to-line gap, then 1.5 m short at speed, then in i. -/
def runThrough : List (Q × Q × List RegionId) :=
  [ (m (-59), mps 12, [cId]), (m (-47), mps 12, [cId]), (m (-35), mps 12, [cId]),
    (m (-23), mps 12, [cId]), (m (-11), mps 12, [cId]), (m 1, mps 12, [cId, iId]) ]

/-- `forbid` (violated): A car occupies lane c, recorded as entering i and governed by head s displaying circular_red alone; a stop line marks c's entrance. The car passes the line at 12 m/s, its speed never at or below the halt tolerance, and its footprint comes to overlap i while s still displays circular_red alone; the search from the entry reaches the approach start (the car 40 m short of the line) without a halt. -/
def forbidTrace : Trace := drive markedApproach red runThrough

/-- `permit` (compliant): Same approach; the car halts with its body 1 m short of the stop line, footprint off the line and the crosswalk, waits, and then enters i for a right turn while s still displays circular_red alone: the halt lies within the approach. -/
def permitTrace : Trace :=
  drive markedApproach red
    [ (m (-40), mps 10, [cId]), (m (-25), mps 8, [cId]), (m (-14), mps 4, [cId]),
      (cm (-1050), mps 0, [cId]), (cm (-1050), mps 0, [cId]),
      (m (-6), mps 4, [cId, lId, xId]), (m 1, mps 6, [cId, iId]) ]

/-- `idle` (not_applicable): The car enters i while s displays circular_green alone. -/
def idleTrace : Trace := drive markedApproach [head [.circularGreen]] runThrough

/-- `blind` (unknown): As forbid, but the source supplies no speed for the car at any observation of the approach: whether it halted is unknown. -/
def blindTrace : Trace := drive markedApproach red runThrough

/-- `history_boundary` (unknown): The recording begins with the car already on c with its body 1.5 m short of the stop line, moving at 1 m/s; it enters i under circular_red alone without halting in the recording. The approach start and any earlier entry lie before the recording, so neither end of the search is reached. -/
def history_boundaryTrace : Trace :=
  drive markedApproach red
    [ (m (-11), mps 1, [cId]), (m (-9), mps 3, [cId, lId]),
      (cm (-450), mps 5, [cId, xId]), (m 1, mps 6, [cId, iId]) ]

/-- `branch_1` (compliant): No stop line or crosswalk marks c's entrance (every line's and crosswalk's list of entrances is observed and excludes c); the car halts with its body 1 m short of the edge of i and then enters i under circular_red alone: the place is the intersection's edge. -/
def branch_1Trace : Trace :=
  drive unmarkedApproach red
    [ (m (-30), mps 10, [cId]), (m (-15), mps 6, [cId]), (m (-3), mps 0, [cId]),
      (m (-3), mps 0, [cId]), (m 1, mps 4, [cId, iId]) ]

/-- `branch_2` (compliant): only a crosswalk marks c; the car halts with its body 1 m short of it,
    crosses it and enters i under circular_red alone: the place is the crosswalk. -/
def branch_2Trace : Trace :=
  drive crosswalkApproach red
    [ (m (-35), mps 10, [cId]), (m (-20), mps 6, [cId]), (m (-8), mps 0, [cId]),
      (m (-8), mps 0, [cId]), (m (-3), mps 3, [cId, xId]), (m 1, mps 5, [cId, iId]) ]

/-- `branch_3` (violated): only a crosswalk marks c; the car halts with its body 4 m short of it,
    outside the stopping zone, then rolls over the crosswalk into i without halting again. -/
def branch_3Trace : Trace :=
  drive crosswalkApproach red
    [ (m (-35), mps 10, [cId]), (m (-20), mps 6, [cId]), (m (-11), mps 0, [cId]),
      (m (-11), mps 0, [cId]), (m (-6), mps 5, [cId, xId]), (m 1, mps 6, [cId, iId]) ]

/-- `branch_4` (violated): only a crosswalk marks c; the car halts with its reference point short
    of the crosswalk but its nose on it (footprint overlapping the crosswalk marking c), then enters
    i under circular_red alone: a halt on the crosswalk is no halt before it. -/
def branch_4Trace : Trace :=
  drive crosswalkApproach red
    [ (m (-35), mps 10, [cId]), (m (-20), mps 6, [cId]), (m (-12), mps 3, [cId]),
      (m (-6), mps 0, [cId, xId]), (m (-6), mps 0, [cId, xId]), (m 1, mps 5, [cId, iId]) ]

/-- `branch_5` (violated): no mark on c; the car halts 1 m short of i, enters i, backs out onto c
    and re-enters i under circular_red alone without halting again: the search from the second
    entry ends at the first entry, before the earlier halt. -/
def branch_5Trace : Trace :=
  drive unmarkedApproach red
    [ (m (-12), mps 6, [cId]), (m (-3), mps 0, [cId]), (m 1, mps 4, [cId, iId]),
      (m (-3), mps 1, [cId]), (m 1, mps 4, [cId, iId]) ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_8a_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, Int.ofNat (1000 * (τ.length - 1)))
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the car's approach on c before it came within the stop-point tolerance of the stop line")
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_8a_o1
