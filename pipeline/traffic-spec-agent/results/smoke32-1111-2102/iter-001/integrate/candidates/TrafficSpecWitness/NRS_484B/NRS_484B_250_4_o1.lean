/-
  Witnesses for NRS_484B_250_4_o1.

  Geometry (metres, +x east): ego's approach lane c (region 10) runs x ∈ [-80, 0], y ∈ [0, 4],
  direction east, its entrance end the intersection i (region 20, x ∈ [0, 20], y ∈ [-10, 14]).
  A stop line s (region 30, x ∈ [-2, -1.5]) and a crosswalk w (region 31, x ∈ [-4, -1]) mark c
  where a scene builds them, their lists complete. One signal head (device 40) governs c.
  Ego (track 1, a motor vehicle) drives east along y = 2 with half-extents 2 × 1 × 1 m, observed
  once a second; its occupancy is stated from its body (2 m either side of its reference point),
  so a body across two regions occupies both. The stopping zone is the reading's
  p.stop_point_tolerance (3 m): a halt is made with the body 1–2 m short of the place; an approach
  start lies 4–8 m short of it; at rest is speed 0, moving at least 1 m/s against the 0.1 m/s floor.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: ego ↦ 1

def laneC : Structure :=
  Build.lane 10 [(m (-80), m 0), (m 0, m 0), (m 0, m 4), (m (-80), m 4)] Build.east (enters := some 20)
def junction : Structure := Build.rect 20 .intersection (m 0) (m (-10)) (m 20) (m 14)
def stopLine : Structure :=
  { Build.rect 30 .stopLine (cm (-200)) (m 0) (cm (-150)) (m 4) with entranceOf := [10], entranceObserved := true }
def crosswalk : Structure :=
  { Build.rect 31 .crosswalk (m (-4)) (m 0) (m (-1)) (m 4) with
      entranceOf := [10], entranceObserved := true, marked := some true }

/-- The regions along ego's line of travel, as closed x-intervals. -/
def cSpan : RegionId × Q × Q := (10, m (-80), m 0)
def iSpan : RegionId × Q × Q := (20, m 0, m 20)
def sSpan : RegionId × Q × Q := (30, cm (-200), cm (-150))
def wSpan : RegionId × Q × Q := (31, m (-4), m (-1))

def deadSignal : Device :=
  { Build.signal 40 [10] [.dark] with uncovered := some true, inoperative := some true }
def greenSignal : Device :=
  { Build.signal 40 [10] [.circularGreen] with uncovered := some true, inoperative := some false }

/-- The regions ego's body (2 m either side of reference point x) overlaps. -/
def spans (x : Q) (rs : List (RegionId × Q × Q)) : List (TrackId × RegionId) :=
  rs.filterMap fun (r, a, b) =>
    if Q.le (Q.sub x (m 2)) b && Q.le a (Q.add x (m 2)) then some (1, r) else none

def egoAt (x v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, m 2) Build.east v (m 2, m 1, m 1)

/-- One observation a second; ego at the listed (x, speed). -/
def drive (structs : List Structure) (rs : List (RegionId × Q × Q)) (sig : Device)
    (path : List (Q × Q)) : Trace :=
  Build.trace path.length 0 (Units.seconds 1) fun k t =>
    let (x, v) := path.getD k (m 0, m 0)
    Build.scene t (some 1) [egoAt x v] structs [sig] (occupies := some (spans x rs))

def withStopLine : List Structure := [laneC, junction, stopLine]
def withStopLineSpans : List (RegionId × Q × Q) := [cSpan, iSpan, sSpan]

/-- Ego drives through at 10 m/s: at 4 s its body is 6 m short of the line, at 5 s it enters. -/
def throughPath : List (Q × Q) :=
  [(m (-50), mps 10), (m (-40), mps 10), (m (-30), mps 10), (m (-20), mps 10),
   (m (-10), mps 10), (m 0, mps 10), (m 10, mps 10)]

/-- `forbid` (violated): The single traffic signal head governing ego's approach lane c is installed, uncovered and inoperative; a stop line marks c. Ego approaches from beyond the stopping zone and enters the intersection without being at rest at any observation since the approach start. -/
def forbidTrace : Trace := drive withStopLine withStopLineSpans deadSignal throughPath

/-- `permit` (compliant): Same scene; ego comes to rest within p.stop_point_tolerance of the stop line, short of it, then enters.
    At 5–6 s ego is at rest with its body 2 m short of the line; it enters at 8 s. -/
def permitTrace : Trace :=
  drive withStopLine withStopLineSpans deadSignal
    [(m (-50), mps 10), (m (-40), mps 10), (m (-30), mps 10), (m (-20), mps 8), (m (-12), mps 5),
     (m (-6), mps 0), (m (-6), mps 0), (m (-4), mps 2), (m (-1), mps 3), (m 6, mps 5)]

/-- `idle` (not_applicable): The signal governing c shows circular_green when ego enters; it is not inoperative. -/
def idleTrace : Trace := drive withStopLine withStopLineSpans greenSignal throughPath

/-- `blind` (unknown): Scene of forbid, but the source declares dev.inoperative absent: whether the signal is inoperative at the entry cannot be read. -/
def blindTrace : Trace := drive withStopLine withStopLineSpans deadSignal throughPath

/-- `history_boundary` (unknown): Signal inoperative; a stop line marks c. The recording begins with ego already within the stopping zone of the line moving slowly; ego enters without being at rest at any recorded observation. The approach start lies before the recording and no previous entry is recorded.
    Ego starts with its body 2 m short of the line at 1 m/s and enters at 4 s. -/
def history_boundaryTrace : Trace :=
  drive withStopLine withStopLineSpans deadSignal
    [(m (-6), mps 1), (m (-5), mps 1), (m (-4), mps 1), (m (-3), mps 1), (m (-2), mps 1),
     (m (-1), mps 1), (m 0, mps 1), (m 1, mps 1)]

/-- `branch_1` (violated): No stop line marks c (list complete); a crosswalk marks c. Ego comes to rest with its footprint overlapping the crosswalk, then enters; it was at rest nowhere short of the crosswalk.
    At 4 s ego's body is 4 m short of the crosswalk; at 5–6 s it rests over it; it enters at 7 s. -/
def branch_1Trace : Trace :=
  drive [laneC, junction, crosswalk] [cSpan, iSpan, wSpan] deadSignal
    [(m (-50), mps 10), (m (-40), mps 10), (m (-30), mps 10), (m (-20), mps 8), (m (-10), mps 5),
     (m (-4), mps 0), (m (-4), mps 0), (m 1, mps 3), (m 8, mps 5)]

/-- `branch_2` (compliant): Neither a stop line nor a crosswalk marks c (lists complete). Ego comes to rest outside the intersection within p.stop_point_tolerance of its edge, then enters.
    At 5–6 s ego rests with its body 2 m short of the intersection; it enters at 7 s. -/
def branch_2Trace : Trace :=
  drive [laneC, junction] [cSpan, iSpan] deadSignal
    [(m (-50), mps 10), (m (-40), mps 10), (m (-30), mps 10), (m (-20), mps 8), (m (-10), mps 5),
     (m (-4), mps 0), (m (-4), mps 0), (m (-1), mps 3), (m 6, mps 5)]

/-- `branch_3` (violated): neither a stop line nor a crosswalk marks c; ego drives into the
    intersection at 10 m/s from 8 m short of its edge without coming to rest. -/
def branch_3Trace : Trace := drive [laneC, junction] [cSpan, iSpan] deadSignal throughPath

/-- `branch_4` (compliant): no stop line marks c, a crosswalk does; ego rests with its body 1 m
    short of the crosswalk at 5–6 s, then enters at 7 s. -/
def branch_4Trace : Trace :=
  drive [laneC, junction, crosswalk] [cSpan, iSpan, wSpan] deadSignal
    [(m (-50), mps 10), (m (-40), mps 10), (m (-30), mps 10), (m (-20), mps 8), (m (-12), mps 5),
     (m (-7), mps 0), (m (-7), mps 0), (m (-2), mps 3), (m 6, mps 5)]

/-- `branch_5` (violated): the inoperative head governs the intersection itself, not lane c; a stop
    line marks c; ego drives through at 10 m/s without coming to rest. -/
def junctionSignal : Device :=
  { Build.signal 40 [20] [.dark] with uncovered := some true, inoperative := some true }
def branch_5Trace : Trace := drive withStopLine withStopLineSpans junctionSignal throughPath

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o1"
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
  , witness "blind" blindTrace (.unknown []) ["dev.inoperative"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach start: the observation at which ego, on c, was last outside the stop line's stopping zone upstream, which precedes the recording")
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_4_o1
