/-
  Witnesses for NRS_484B_257_1_o1.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - intersection X = region 10, the rectangle x ∈ [0, 20], y ∈ [-10, 14];
  - carrier c = lane 1, x ∈ [-100, 0], y ∈ [0, 4], direction east, entering X;
  - cross lane d = lane 2, x ∈ [10, 14], y ∈ [14, 100], direction south, entering X;
  - stop line 20 marking c, x ∈ [-5, -4.6]; crosswalk 30 marking c, x ∈ [-4, -1], y ∈ [-2, 6];
  - stop line 21 and crosswalk 31 marking d only (they never mark c: their entrance lists are
    observed), present in every scene so that "no mark of c" is decided over real candidates;
  - tier 1 scenes hold every mark; tier 2 scenes drop stop line 20 (the crosswalk is c's place);
    tier 3 scenes drop stop line 20 and crosswalk 30 (X's edge is c's place).
  The subject (track 1, a motor vehicle, half-length 2.5 m, half-width 1 m) drives east along
  y = 2, one observation a second; its body front is 2.5 m ahead of its reference point. With
  p.stop_point_tolerance = 2 m, a reference point at x = -8 (front -5.5) is in stop line 20's
  zone, x = -11 (front -8.5) is short of it (approach start); x = -7 (front -4.5) is in crosswalk
  30's zone, x = -12 short of it; x = -4 (front -1.5) is in X's zone, x = -7 short of it. Speeds
  are given in cm/s: 0 is a halt (p.halt_speed_tolerance 0.1 m/s), 300 is a rolling pass at or
  below p.yield_line_speed_max (4.2 m/s), 800 and above is well above it.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A speed in centimetres per second. -/
def cmps (n : Int) : Q := Units.micrometresPerSecond (n * 10000)

-- Binders ↦ tracks: subject ↦ 1

def intersectionX : Structure := Build.rect 10 .intersection (m 0) (m (-10)) (m 20) (m 14)
def carrierC : Structure :=
  Build.lane 1 [(m (-100), m 0), (m 0, m 0), (m 0, m 4), (m (-100), m 4)] Build.east (enters := some 10)
def carrierD : Structure :=
  Build.lane 2 [(m 10, m 14), (m 14, m 14), (m 14, m 100), (m 10, m 100)] Build.south (enters := some 10)
def stopLineC : Structure :=
  { Build.rect 20 .stopLine (m (-5)) (m 0) (cm (-460)) (m 4) with entranceOf := [1], entranceObserved := true }
def stopLineD : Structure :=
  { Build.rect 21 .stopLine (m 10) (m 19) (m 14) (cm 1940) with entranceOf := [2], entranceObserved := true }
def crosswalkC : Structure :=
  { Build.rect 30 .crosswalk (m (-4)) (m (-2)) (m (-1)) (m 6) with
      entranceOf := [1], entranceObserved := true, marked := some true }
def crosswalkD : Structure :=
  { Build.rect 31 .crosswalk (m 8) (m 15) (m 16) (m 18) with
      entranceOf := [2], entranceObserved := true, marked := some true }

/-- Tier 1: a stop line marks c (with a crosswalk beyond it). -/
def tier1 : List Structure := [intersectionX, carrierC, carrierD, stopLineC, crosswalkC, stopLineD, crosswalkD]
/-- Tier 2: no stop line marks c; a crosswalk does. -/
def tier2 : List Structure := [intersectionX, carrierC, carrierD, crosswalkC, stopLineD, crosswalkD]
/-- Tier 3: neither a stop line nor a crosswalk marks c. -/
def tier3 : List Structure := [intersectionX, carrierC, carrierD, stopLineD, crosswalkD]

def stopC : Device := Build.sign 100 .stopSign [1]
def stopX : Device := Build.sign 100 .stopSign [10]
def stopD : Device := Build.sign 102 .stopSign [2]
def yieldC : Device := Build.sign 101 .yieldSign [1]
def yieldX : Device := Build.sign 101 .yieldSign [10]
def officerOn (r : RegionId) : Device :=
  { Build.device 110 .humanDirection [r] with humanRole := some .policeOfficer, humanIndication := some .proceed }
def operatingSignalD : Device :=
  { Build.signal 120 [2] [.circularGreen] with uncovered := some true, inoperative := some false }
def darkSignalC : Device :=
  { Build.signal 121 [1] [.dark] with uncovered := some true, inoperative := some true }

/-- The subject at reference x (cm) on y = 2 m, heading east, at a speed (cm/s). -/
def subjectAt (xcm vcm : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm xcm, m 2) Build.east (cmps vcm) (cm 250, m 1, cm 80)

/-- A trace, one observation a second, of the subject at the listed (x cm, speed cm/s). -/
def drive (steps : List (Int × Int)) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    let (x, v) := steps.getD k (0, 0)
    Build.scene t (some 1) [subjectAt x v] structures devices

/-- Approach at speed, a rolling pass through stop line 20's zone at 3 m/s (x = -8), entry at x = 0.5. -/
def rollingSteps : List (Int × Int) :=
  [(-4200, 1000), (-3200, 1000), (-2300, 800), (-1600, 600), (-1100, 400), (-800, 300), (-300, 300), (50, 300)]

/-- Approach, halt at x = -8 (stop line 20 within 0.5 m ahead), creep, entry at x = 2. -/
def haltSteps : List (Int × Int) :=
  [(-4200, 1000), (-3200, 1000), (-2300, 800), (-1600, 600), (-1100, 400), (-800, 0), (-800, 0),
   (-600, 200), (-200, 400), (200, 400)]

/-- `forbid` (violated): A dev.stop_sign governs carrier c entering X; a st.stop_line marks c; no officer or operating signal. The subject passes the line and enters X with kin.speed well above p.halt_speed_tolerance, never halting since it was upstream of the line's stopping zone.
    An officer and an operating signal stand at the cross lane d only: neither governs c or X. -/
def forbidTrace : Trace := drive rollingSteps tier1 [stopC, officerOn 2, operatingSignalD]

/-- `permit` (compliant): Same scene; the subject halts on c with the line just ahead within p.stop_point_tolerance, then enters X. -/
def permitTrace : Trace := drive haltSteps tier1 [stopC]

/-- `idle` (not_applicable): No stop or yield sign governs c or X; the subject enters X without halting.
    A stop sign governs the cross lane d only. -/
def idleTrace : Trace := drive rollingSteps tier1 [stopD]

/-- `blind` (unknown): Stop sign governing c; kin.speed is absent, so whether the subject halted within the line's stopping zone is unknown. -/
def blindTrace : Trace := drive haltSteps tier1 [stopC]

/-- `history_boundary` (unknown): Stop sign governing c; the recording begins with the subject already within p.stop_point_tolerance of the stop line, moving slowly; no halt is recorded before its entry into X. -/
def history_boundaryTrace : Trace :=
  drive [(-750, 150), (-600, 200), (-300, 300), (100, 300)] tier1 [stopC]

/-- `branch_1` (compliant): Only a dev.yield_sign governs c; the subject passes the stop line's zone at kin.speed at or below p.yield_line_speed_max and enters X. -/
def branch_1Trace : Trace := drive rollingSteps tier1 [yieldC]

/-- `branch_2` (violated): Only a yield sign governs c; the subject passes through the place's stopping zone with kin.speed well above p.yield_line_speed_max at every observation and enters X. -/
def branch_2Trace : Trace :=
  drive [(-5000, 1200), (-3800, 1200), (-2600, 1200), (-1500, 1000), (-700, 800), (100, 800)] tier1 [yieldC]

/-- `branch_3` (not_applicable): A stop sign governs c, but a dev.human_direction of role police_officer governs c at the subject's entry; it enters X without halting. -/
def branch_3Trace : Trace := drive rollingSteps tier1 [stopC, officerOn 1]

/-- `branch_4` (compliant): no stop line marks c, crosswalk 30 does; a stop sign governs X; the
    subject halts with crosswalk 30 0.5 m ahead of its body, off it, then enters X. -/
def branch_4Trace : Trace :=
  drive [(-4200, 1000), (-3200, 1000), (-2300, 800), (-1600, 600), (-1200, 500), (-700, 0), (-700, 0),
         (-600, 100), (200, 400)] tier2 [stopX]

/-- `branch_5` (violated): no stop line marks c, crosswalk 30 does; a yield sign governs X; the
    subject passes the crosswalk's zone at 10 m/s and enters X. -/
def branch_5Trace : Trace :=
  drive [(-5000, 1200), (-3800, 1200), (-2600, 1200), (-1600, 1000), (-600, 1000), (400, 1000)] tier2 [yieldX]

/-- `branch_6` (compliant): neither a stop line nor a crosswalk marks c; a stop sign governs c;
    the subject halts with X's edge 1.5 m ahead of its body, then enters X. -/
def branch_6Trace : Trace :=
  drive [(-4200, 1000), (-3200, 1000), (-2300, 800), (-1600, 600), (-1200, 500), (-400, 0), (-400, 0),
         (-300, 100), (300, 400)] tier3 [stopC]

/-- `branch_7` (violated): neither mark of c; a stop sign governs X; the subject rolls through X's
    zone at 3 m/s without halting and enters X. -/
def branch_7Trace : Trace :=
  drive [(-4200, 1000), (-3200, 1000), (-2300, 800), (-1600, 600), (-1200, 500), (-700, 400), (-350, 300),
         (100, 300)] tier3 [stopX]

/-- `branch_8` (violated): a stop sign and a dark (inoperative) traffic signal govern c; a dark
    signal directs nothing, so the subject's rolling pass is a violation. -/
def branch_8Trace : Trace := drive rollingSteps tier1 [stopC, darkSignalC]

/-- `branch_9` (violated): stop sign on c; the subject halts at the line, enters X (that entry is
    complied with), backs out onto c without leaving the zone's reach, and re-enters X without a
    new halt: the earlier halt does not serve the second entry. -/
def branch_9Trace : Trace :=
  drive [(-4200, 1000), (-3200, 1000), (-2300, 800), (-1600, 600), (-1100, 400), (-800, 0), (50, 200),
         (-300, 200), (50, 300)] tier1 [stopC]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o1"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach start: the subject's last observation outside the stop line's stopping zone upstream on c lies before the recording")
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated ]

end TrafficSpecWitness.NRS_484B_257_1_o1
