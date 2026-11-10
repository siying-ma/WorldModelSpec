/-
  Witnesses for NRS_484B_257_1_o1.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
    lane c (10): x ∈ [-100, 0], y ∈ [0, 4], direction east, enters intersection i (20), on way 40.
    intersection i (20): x ∈ [0, 20], y ∈ [-8, 12], on ways 40 and 41.
    stop line s (30): x ∈ [-4, -3.5] across c, recorded as marking c.
    crosswalk w (31): x ∈ [-3, 0] across c, recorded as marking c (crosswalk witness only).
    highways 40 (the approach's way, x ∈ [-100, 100], y ∈ [-8, 12]) and 41 (the through way,
    x ∈ [0, 20], y ∈ [-100, 100]).
    x (track 1): a motor vehicle on y = 2 heading east, half-length 2 m, half-width 1 m; its
    position is given along x, one observation per second. Occupancy is stated per observation
    from the body's extent [px - 2, px + 2] (a body across two regions occupies both).
    Devices: stop sign 60 and yield sign 61 governing c; a police officer 62 and a signal head 63
    governing i.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: x ↦ 1

def laneC : Structure :=
  { Build.lane 10 [(m (-100), m 0), (m 0, m 0), (m 0, m 4), (m (-100), m 4)] Build.east (enters := some 20)
    with ways := some [40] }
def junction : Structure :=
  { Build.rect 20 .intersection (m 0) (m (-8)) (m 20) (m 12) with ways := some [40, 41] }
def stopLine : Structure :=
  { Build.rect 30 .stopLine (m (-4)) (m 0) (cm (-350)) (m 4) with entranceOf := [10], entranceObserved := true }
def crosswalk : Structure :=
  { Build.rect 31 .crosswalk (m (-3)) (m 0) (m 0) (m 4)
    with entranceOf := [10], entranceObserved := true, marked := some true }
def approachWay : Structure := Build.rect 40 .highway (m (-100)) (m (-8)) (m 100) (m 12)
def throughWay : Structure := Build.rect 41 .highway (m 0) (m (-100)) (m 20) (m 100)

def withLine : List Structure := [laneC, junction, stopLine, approachWay, throughWay]
def withWalk : List Structure := [laneC, junction, crosswalk, approachWay, throughWay]
def bare : List Structure := [laneC, junction, approachWay, throughWay]

def stopSign : Device := Build.sign 60 .stopSign [10]
def yieldSign : Device := Build.sign 61 .yieldSign [10]
def officer : Device :=
  { Build.device 62 .humanDirection [20] with humanRole := some .policeOfficer, humanIndication := some .proceed }
def signalHead : Device :=
  { Build.signal 63 [20] [.circularGreen] with inoperative := some false, uncovered := some true }

/-- One observation of x: position along the lane (cm), speed, the regions its body overlaps. -/
structure Step where
  px : Q
  speed : Q
  occ : List RegionId

def step (pxCm : Int) (speed : Q) (occ : List RegionId) : Step := ⟨cm pxCm, speed, occ⟩

def body : Q × Q × Q := (m 2, m 1, m 1)

def run (steps : List Step) (structures : List Structure) (devices : List Device)
    (sight : Option (List (RegionId × Q)) := none) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    let s := steps.getD k ⟨Q.zero, Q.zero, []⟩
    let u : RoadUser := { Build.user 1 [.motorVehicle] (s.px, m 2) Build.east s.speed body with sightAlongWay := sight }
    -- x is always on way 40, and on way 41 exactly where it overlaps i
    let ways : List RegionId := if s.occ.contains 20 then [40, 41] else [40]
    Build.scene t (some 1) [u] structures devices (occupies := some ((s.occ ++ ways).map fun r => (1, r)))

def span (steps : List Step) : Option (Timestamp × Timestamp) :=
  some (0, 1000 * (Int.ofNat (steps.length - 1)))

/-- Approach to the stop line at 2 m/s without halting, entering i at the last observation. -/
def rollSteps : List Step :=
  [ step (-8000) (mps 12) [10], step (-4000) (mps 10) [10], step (-1200) (mps 4) [10]
  , step (-650) (mps 2) [10], step (-450) (mps 2) [10, 30], step (-250) (mps 2) [10, 30]
  , step (-50) (mps 2) [10, 20] ]

/-- `forbid` (violated): A dev.stop_sign governs lane c (st.lane_enters c i); stop line s marks c. No signal or officer controls c or i. x approaches from 80 m at 12 m/s, slows to 2 m/s at s and enters i without kin.speed reaching the tolerance. -/
def forbidTrace : Trace := run rollSteps withLine [stopSign]

/-- x halts with its front 0.3 m short of s, then enters i. -/
def haltSteps : List Step :=
  [ step (-8000) (mps 12) [10], step (-4000) (mps 10) [10], step (-1200) (mps 4) [10]
  , step (-630) (mps 0) [10], step (-450) (mps 2) [10, 30], step (-250) (mps 3) [10, 30]
  , step (-50) (mps 3) [10, 20] ]

/-- `permit` (compliant): Same; x halts 0.3 m short of s, then enters i. -/
def permitTrace : Trace := run haltSteps withLine [stopSign]

/-- `idle` (not_applicable): No stop or yield sign governs c or i; x enters without halting. -/
def idleTrace : Trace := run rollSteps withLine []

/-- `blind` (unknown): As forbid, but dev.governs is not observed, so whether the stop sign governs x's approach is unknown. -/
def blindTrace : Trace := run rollSteps withLine [stopSign]

/-- x slows to 3 m/s with its front 1 m short of s and enters without halting. -/
def slowSteps : List Step :=
  [ step (-8000) (mps 12) [10], step (-4000) (mps 10) [10], step (-1200) (mps 8) [10]
  , step (-700) (mps 3) [10], step (-450) (mps 3) [10, 30], step (-250) (mps 3) [10, 30]
  , step (-50) (mps 4) [10, 20] ]

/-- `branch_1` (compliant): Only a dev.yield_sign governs c; x slows to 3 m/s within 1 m short of s without halting, then enters. -/
def branch_1Trace : Trace := run slowSteps withLine [yieldSign]

/-- `branch_2` (not_applicable): As forbid, but a dev.human_direction with role police_officer governs i and directs x to proceed. -/
def branch_2Trace : Trace := run rollSteps withLine [stopSign, officer]

/-- The recording begins with x's front 0.5 m short of s, creeping at 0.8 m/s into i. -/
def creepSteps : List Step :=
  let v := Units.micrometresPerSecond 800000
  [ step (-650) v [10], step (-570) v [10, 30], step (-490) v [10, 30], step (-410) v [10, 30]
  , step (-330) v [10, 30], step (-250) v [10, 30], step (-170) v [10, 20, 30] ]

/-- `history_boundary` (unknown): The recording begins with x already within the stopping zone of s on c, creeping at 0.8 m/s; no halt is recorded and x enters i. -/
def history_boundaryTrace : Trace := run creepSteps withLine [stopSign]

-- branch_3 (not_applicable): as forbid, but an operating signal head (green) governs i.
def branch_3Trace : Trace := run rollSteps withLine [stopSign, signalHead]

/-- No stop line; x halts 0.5 m short of crosswalk w, then enters i across it. -/
def walkSteps : List Step :=
  [ step (-8000) (mps 12) [10], step (-4000) (mps 10) [10], step (-1200) (mps 5) [10]
  , step (-550) (mps 0) [10], step (-350) (mps 2) [10, 31], step (-150) (mps 3) [10, 20, 31] ]

-- branch_4 (compliant): stop sign, no stop line, crosswalk w marks c; x halts short of w.
def branch_4Trace : Trace := run walkSteps withWalk [stopSign]

/-- No stop line, no crosswalk; x halts with its front 1 m short of i, then enters. -/
def edgeSteps : List Step :=
  [ step (-8000) (mps 12) [10], step (-4000) (mps 10) [10], step (-1000) (mps 5) [10]
  , step (-300) (mps 0) [10], step (-100) (mps 2) [10, 20] ]

-- branch_5 (compliant): no stop line or crosswalk; x halts 1 m short of i with an 80 m view
-- along the through way 41.
def branch_5Trace : Trace := run edgeSteps bare [stopSign] (sight := some [(41, m 80)])

-- branch_6 (violated): as branch_5, but the view along the through way is 30 m.
def branch_6Trace : Trace := run edgeSteps bare [stopSign] (sight := some [(41, m 30)])

/-- x halts at s and enters i, backs out onto c past s, and enters i again without halting. -/
def reentrySteps : List Step :=
  [ step (-8000) (mps 12) [10], step (-4000) (mps 10) [10], step (-1200) (mps 4) [10]
  , step (-630) (mps 0) [10], step (-450) (mps 2) [10, 30], step (-250) (mps 3) [10, 30]
  , step (-50) (mps 3) [10, 20], step 100 (mps 1) [10, 20], step (-250) (mps 1) [10, 30]
  , step (-50) (mps 2) [10, 20] ]

-- branch_7 (violated): the second entry's search ends at the first entry through c, so the
-- earlier halt does not count for it.
def branch_7Trace : Trace := run reentrySteps withLine [stopSign]

def stopSignAtI : Device := Build.sign 64 .stopSign [20]
def yieldSignAtI : Device := Build.sign 65 .yieldSign [20]
def officerAtC : Device :=
  { Build.device 66 .humanDirection [10] with humanRole := some .policeOfficer, humanIndication := some .proceed }
def signalAtC : Device :=
  { Build.signal 67 [10] [.circularGreen] with inoperative := some false, uncovered := some true }

-- branch_8 (violated): as forbid, but the stop sign governs i rather than c.
def branch_8Trace : Trace := run rollSteps withLine [stopSignAtI]

/-- x passes s at 8 m/s, above the yield check speed, and enters i. -/
def fastSteps : List Step :=
  [ step (-8000) (mps 12) [10], step (-4000) (mps 10) [10], step (-1200) (mps 9) [10]
  , step (-650) (mps 8) [10], step (-450) (mps 8) [10, 30], step (-250) (mps 8) [10, 30]
  , step (-50) (mps 8) [10, 20] ]

-- branch_9 (violated): only a yield sign, governing i; x neither halts nor slows to the check speed.
def branch_9Trace : Trace := run fastSteps withLine [yieldSignAtI]

-- branch_10 (violated): only a yield sign, governing c; x neither halts nor slows to the check speed.
def branch_10Trace : Trace := run fastSteps withLine [yieldSign]

-- branch_11 (not_applicable): as forbid, but a police officer governs c.
def branch_11Trace : Trace := run rollSteps withLine [stopSign, officerAtC]

-- branch_12 (not_applicable): as forbid, but an operating signal head governs c.
def branch_12Trace : Trace := run rollSteps withLine [stopSign, signalAtC]

/-- x rolls past s and halts with its front 1 m short of i, then enters. -/
def pastLineSteps : List Step :=
  [ step (-8000) (mps 12) [10], step (-4000) (mps 10) [10], step (-1200) (mps 6) [10]
  , step (-650) (mps 4) [10], step (-450) (mps 3) [10, 30], step (-300) (mps 0) [10, 30]
  , step (-100) (mps 2) [10, 20] ]

-- branch_13 (violated): stop line s marks c; x halts past it, 1 m short of i with a full view:
-- the stop line, not the intersection edge, is the place.
def branch_13Trace : Trace := run pastLineSteps withLine [stopSign] (sight := some [(41, m 80)])

/-- No stop line; x rolls onto crosswalk w and halts on it, its front 1 m short of i. -/
def onWalkSteps : List Step :=
  [ step (-8000) (mps 12) [10], step (-4000) (mps 10) [10], step (-1200) (mps 6) [10]
  , step (-650) (mps 4) [10], step (-450) (mps 3) [10, 31], step (-300) (mps 0) [10, 31]
  , step (-100) (mps 2) [10, 20, 31] ]

-- branch_14 (violated): crosswalk w marks c; x halts on it, 1 m short of i with a full view:
-- the crosswalk, not the intersection edge, is the place.
def branch_14Trace : Trace := run onWalkSteps withWalk [stopSign] (sight := some [(41, m 80)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := span rollSteps)
  , witness "permit" permitTrace .compliant (window := span haltSteps)
  , witness "idle" idleTrace .notApplicable (window := span rollSteps)
  , witness "blind" blindTrace (.unknown []) ["dev.governs"] (window := span rollSteps)
  , witness "branch_1" branch_1Trace .compliant (window := span slowSteps)
  , witness "branch_2" branch_2Trace .notApplicable (window := span rollSteps)
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach start of x on c (its last observation outside the stopping zone of s), before the recording begins") (window := span creepSteps)
  , witness "branch_3" branch_3Trace .notApplicable (window := span rollSteps)
  , witness "branch_4" branch_4Trace .compliant (window := span walkSteps)
  , witness "branch_5" branch_5Trace .compliant (window := span edgeSteps)
  , witness "branch_6" branch_6Trace .violated (window := span edgeSteps)
  , witness "branch_7" branch_7Trace .violated (window := span reentrySteps)
  , witness "branch_8" branch_8Trace .violated (window := span rollSteps)
  , witness "branch_9" branch_9Trace .violated (window := span fastSteps)
  , witness "branch_10" branch_10Trace .violated (window := span fastSteps)
  , witness "branch_11" branch_11Trace .notApplicable (window := span rollSteps)
  , witness "branch_12" branch_12Trace .notApplicable (window := span rollSteps)
  , witness "branch_13" branch_13Trace .violated (window := span pastLineSteps)
  , witness "branch_14" branch_14Trace .violated (window := span onWalkSteps) ]

end TrafficSpecWitness.NRS_484B_257_1_o1
