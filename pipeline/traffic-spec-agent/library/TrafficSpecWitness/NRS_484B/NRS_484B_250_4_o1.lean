/-
  Witnesses for NRS_484B_250_4_o1.

  The world every scene below is built from (+x east, +y north; the subject travels north).

  Regions:
    10  intersection, the square (-6, -6) … (6, 6);
    11  the northbound approach lane, (-4, -60) … (0, -6), direction north, entrance end 10;
    12  a stop line across that lane, (-4, -7.2) … (0, -6.8), recorded as marking 11;
    14  a crosswalk on the near side, (-6, -9.5) … (6, -6.5), recorded as marking 11;
    13  the intersecting highway, (-60, -6) … (60, 6).
  The stop-line scenes hold 10, 11, 12; the crosswalk scenes 10, 11, 14; the sight scenes 10, 11,
  13 (no mark at all, so the third place of the words governs).

  The subject is track 1, a motor vehicle 5 m long and 1.8 m wide (half-extents 2.5 × 0.9 × 0.75),
  centred on the lane at x = -2, so its body spans y ∈ [y - 2.5, y + 2.5]. Each observation states
  the regions its footprint overlaps, since a reference point lies in one polygon only.

  Device 1 is the signal head governing region 10: dark, uncovered and inoperative, except in the
  `idle` scene where it shows a steady circular green and is not inoperative.

  Figures that matter against the run's reading (p.stop_point_tolerance = 1.5 m,
  p.motion_speed_tolerance = 0.3 m/s, p.intersection_view_sight_distance = 120 m):
    body-to-stop-line distance 20 m and more while upstream (outside the line's zone by a clear
    margin), 0.3 m at the halt (inside it by a clear margin); 0.9 m where a scene starts inside the
    zone; halt speeds are exactly 0 and rolling speeds 2 m/s and more; sight distances are 40–60 m
    where the view is short and 150 m where it is open.

  The first observation of every scene in which the duty is decided has the subject off the
  recorded approach segment: the run of observations outside the governing place's stopping zone
  then begins inside the recording, which is what the search back needs in order to decide.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def ms (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

/-- The junction the approach runs into. -/
def junction : Structure := Build.rect 10 .intersection (m (-6)) (m (-6)) (m 6) (m 6)
/-- The northbound approach lane, its entrance end the junction. -/
def approach : Structure :=
  Build.lane 11 [(m (-4), m (-60)), (m 0, m (-60)), (m 0, m (-6)), (m (-4), m (-6))]
    Build.north (enters := some 10)
/-- A stop line the source records as marking the approach's entrance. -/
def stopLine : Structure :=
  { Build.rect 12 .stopLine (m (-4)) (cm (-720)) (m 0) (cm (-680)) with
      entranceOf := [11], entranceObserved := true }
/-- A marked crosswalk the source records as marking the approach's entrance. -/
def crossing : Structure :=
  { Build.rect 14 .crosswalk (m (-6)) (cm (-950)) (m 6) (cm (-650)) with
      entranceOf := [11], entranceObserved := true, marked := some true }
/-- The intersecting highway, the way whose approaching traffic the driver must be able to see. -/
def crossWay : Structure := Build.rect 13 .highway (m (-60)) (m (-6)) (m 60) (m 6)

def stopLineWorld : List Structure := [junction, approach, stopLine]
def crosswalkWorld : List Structure := [junction, approach, crossing]
def sightWorld : List Structure := [junction, approach, crossWay]

/-- A signal head governing the junction: installed, faces uncovered, showing no valid indication. -/
def deadSignal : Device :=
  { Build.signal 1 [10] [.dark] with uncovered := some true, inoperative := some true }
/-- The same head working: a steady circular green, not inoperative. -/
def workingSignal : Device :=
  { Build.signal 1 [10] [.circularGreen] with uncovered := some true, inoperative := some false }

/-- The subject at an observation: its position on the lane, its speed, and the sight distances the
    source reports for it along each way. -/
def car (y v : Q) (sight : List (RegionId × Q)) : RoadUser :=
  { Build.user 1 [.motorVehicle] (m (-2), y) Build.north v (cm 250, cm 90, cm 75) with
      sightAlongWay := some sight }

/-- One observation: the subject's y, its speed, the regions its footprint overlaps, the sight
    distances reported for it. -/
def step (y v : Q) (occ : List RegionId) : Q × Q × List RegionId × List (RegionId × Q) :=
  (y, v, occ, [])
def stepSeeing (y v : Q) (occ : List RegionId) (sight : Q)
    : Q × Q × List RegionId × List (RegionId × Q) :=
  (y, v, occ, [(13, sight)])

def sceneOf (regions : List Structure) (devs : List Device)
    (s : Q × Q × List RegionId × List (RegionId × Q)) (t : Timestamp) : Scene :=
  Build.scene t (some 1) [car s.1 s.2.1 s.2.2.2] regions devs
    (some (s.2.2.1.map fun r => ((1 : TrackId), r)))

/-- A trace at one observation a second from a list of observations. -/
def traceOf (regions : List Structure) (devs : List Device)
    (steps : List (Q × Q × List RegionId × List (RegionId × Q))) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    sceneOf regions devs (steps[k]?.getD (Q.zero, Q.zero, [], [])) t

/-- `forbid` (violated): A four-way junction is governed by a signal head that is installed, its
    vehicular faces uncovered, and inoperative — showing no valid indication. The subject approaches
    along a lane whose entrance end is that junction and which a stop line is recorded as marking;
    from well upstream, outside the line's stopping zone, it rolls on at 7 m/s without its speed
    ever reaching the halt tolerance, crosses the line and enters the junction. No other road user
    is in the scene. -/
def forbidTrace : Trace :=
  traceOf stopLineWorld [deadSignal]
    [ step (m (-63)) (ms 7) []            -- just short of the recorded approach segment
    , step (m (-56)) (ms 7) [11]          -- on the approach, 46 m from the line: outside its zone
    , step (m (-49)) (ms 7) [11]
    , step (m (-42)) (ms 7) [11]
    , step (m (-35)) (ms 7) [11]
    , step (m (-28)) (ms 7) [11]
    , step (m (-21)) (ms 7) [11]
    , step (m (-14)) (ms 7) [11]          -- 4.3 m from the line: still outside its zone
    , step (m (-7)) (ms 7) [11, 10, 12]   -- body over the line and into the junction: the entry
    , step (m 0) (ms 7) [10] ]

/-- `permit` (compliant): The same junction and inoperative signal. The subject approaches from
    outside the stop line's stopping zone, halts with its body short of the line and within the
    stop-point tolerance of it, stands for two observations, then moves off and enters the junction.
    It is the only road user in the scene, and the duty is still decided. -/
def permitTrace : Trace :=
  traceOf stopLineWorld [deadSignal]
    [ step (m (-63)) (ms 10) []
    , step (m (-53)) (ms 10) [11]         -- outside the line's zone
    , step (m (-43)) (ms 10) [11]
    , step (m (-33)) (ms 10) [11]
    , step (m (-23)) (ms 8) [11]
    , step (m (-16)) (ms 5) [11]
    , step (cm (-1250)) (ms 2) [11]       -- 2.8 m from the line: last observation outside the zone
    , step (m (-10)) Q.zero [11]          -- halted, nose 0.3 m short of the line
    , step (m (-10)) Q.zero [11]          -- still standing
    , step (m (-8)) (ms 3) [11, 10, 12]   -- the entry
    , step (m (-4)) (ms 5) [11, 10] ]

/-- `idle` (not_applicable): The same junction and layout, but the signal head governing it is
    working: it displays a steady circular green to the subject's approach and is not inoperative.
    The subject enters the junction at 10 m/s without halting. -/
def idleTrace : Trace :=
  traceOf stopLineWorld [workingSignal]
    [ step (m (-37)) (ms 10) [11]
    , step (m (-27)) (ms 10) [11]
    , step (m (-17)) (ms 10) [11]
    , step (m (-7)) (ms 10) [11, 10, 12]  -- the entry, under a working signal
    , step (m 3) (ms 10) [10] ]

/-- `blind` (unknown): The inoperative signal, the stop line and the subject's entry are as in the
    forbid scenario, but the source maps its regions without their outlines: st.region_geometry is
    absent, so every distance from the subject's body to the stop line, and with it whether any halt
    lay at the place, is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `history_boundary` (unknown): The recording begins with the subject already a short way short of
    the stop line, inside that line's stopping zone upstream, under the inoperative signal; it rolls
    forward at 2 m/s, never halting, and enters the junction. No observation shows it outside the
    zone, there is no previous entry into this junction, and no recorded halt decides the verdict. -/
def history_boundaryTrace : Trace :=
  traceOf stopLineWorld [deadSignal]
    [ step (cm (-1060)) (ms 2) [11]         -- 0.9 m from the line: already inside its zone
    , step (cm (-860)) (ms 2) [11, 12]
    , step (cm (-660)) (ms 2) [11, 10, 12]  -- the entry
    , step (cm (-460)) (ms 2) [11, 10, 12]
    , step (cm (-260)) (ms 2) [10] ]

/-- `branch_1` (compliant): no stop line marks the approach, but a crosswalk does; the subject comes
    from outside the crossing's stopping zone, halts with its body short of the crossing and not on
    it, stands, then enters the junction. -/
def branch_1Trace : Trace :=
  traceOf crosswalkWorld [deadSignal]
    [ step (m (-63)) (ms 10) []
    , step (m (-53)) (ms 10) [11]         -- 41 m from the crossing: outside its zone
    , step (m (-40)) (ms 10) [11]
    , step (m (-28)) (ms 8) [11]
    , step (m (-18)) (ms 5) [11]          -- 6 m from the crossing: last observation outside the zone
    , step (cm (-1250)) Q.zero [11]       -- halted, nose 0.5 m short of the crossing
    , step (cm (-1250)) Q.zero [11]
    , step (m (-8)) (ms 3) [11, 10, 14]   -- the entry
    , step (cm (-380)) (ms 5) [11, 10] ]

/-- `branch_2` (violated): the same crosswalk layout, and the subject rolls through at 10 m/s from
    outside the crossing's zone into the junction without ever halting. -/
def branch_2Trace : Trace :=
  traceOf crosswalkWorld [deadSignal]
    [ step (m (-63)) (ms 10) []
    , step (m (-53)) (ms 10) [11]
    , step (m (-43)) (ms 10) [11]
    , step (m (-33)) (ms 10) [11]
    , step (m (-23)) (ms 10) [11]         -- 11 m from the crossing: last observation outside the zone
    , step (m (-13)) (ms 10) [11]
    , step (m (-8)) (ms 10) [11, 10, 14]  -- the entry
    , step (cm (-380)) (ms 10) [11, 10] ]

/-- `branch_3` (compliant): neither a stop line nor a crosswalk marks the approach, so the third
    place governs: the subject halts short of the junction at a point where the sight along the
    intersecting highway is 150 m, then enters. -/
def branch_3Trace : Trace :=
  traceOf sightWorld [deadSignal]
    [ stepSeeing (m (-63)) (ms 10) [] (m 40)
    , stepSeeing (m (-53)) (ms 10) [11] (m 40)     -- on the approach, the view still short
    , stepSeeing (m (-40)) (ms 10) [11] (m 40)
    , stepSeeing (m (-25)) (ms 8) [11] (m 60)      -- last observation upstream of the view
    , stepSeeing (m (-14)) (ms 4) [11] (m 150)     -- the view is open, but still rolling
    , stepSeeing (m (-11)) Q.zero [11] (m 150)     -- halted short of the junction, with the view
    , stepSeeing (m (-11)) Q.zero [11] (m 150)
    , stepSeeing (m (-7)) (ms 3) [11, 10, 13] (m 150)  -- the entry
    , stepSeeing (m (-3)) (ms 5) [10, 13] (m 150) ]

/-- `branch_4` (violated): the same layout with no mark, and the subject's only halt is 30 m back,
    where the sight along the intersecting highway is 40 m; it then rolls on through the point at
    which the view opens and enters the junction without halting there. -/
def branch_4Trace : Trace :=
  traceOf sightWorld [deadSignal]
    [ stepSeeing (m (-63)) (ms 10) [] (m 40)
    , stepSeeing (m (-53)) (ms 10) [11] (m 40)
    , stepSeeing (m (-40)) (ms 10) [11] (m 40)
    , stepSeeing (m (-30)) Q.zero [11] (m 40)      -- halted where no view of the way exists
    , stepSeeing (m (-20)) (ms 8) [11] (m 50)      -- last observation upstream of the view
    , stepSeeing (m (-11)) (ms 5) [11] (m 150)     -- the view is open, and it does not halt
    , stepSeeing (m (-7)) (ms 5) [11, 10, 13] (m 150)  -- the entry
    , stepSeeing (m (-3)) (ms 5) [10, 13] (m 150) ]

/-- `branch_5` (violated): the stop-line layout, with the subject's approach bounded by its previous
    visit to the junction rather than by an observation outside the line's zone: it enters the
    junction, backs out onto the approach without ever getting farther from the line than the
    stop-point tolerance, and enters again without halting. -/
def branch_5Trace : Trace :=
  traceOf stopLineWorld [deadSignal]
    [ step (cm (-1060)) (ms 2) [11]           -- 0.9 m from the line: inside its zone
    , step (cm (-760)) (ms 3) [11, 10, 12]    -- the first entry
    , step (cm (-560)) (ms 3) [11, 10, 12]    -- in the junction, no longer entering it
    , step (cm (-760)) (ms 2) [11, 10, 12]    -- backing out
    , step (cm (-1060)) (ms 2) [11]           -- on the approach again, still inside the line's zone
    , step (cm (-760)) (ms 3) [11, 10, 12]    -- the second entry, with no halt since the visit
    , step (cm (-460)) (ms 3) [11, 10, 12] ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach upstream of the stop line that marks this carrier's entrance: the trace holds no observation at which the subject lay outside that mark's stopping zone before the entry, and no earlier entry of the subject into this intersection.")
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_4_o1
