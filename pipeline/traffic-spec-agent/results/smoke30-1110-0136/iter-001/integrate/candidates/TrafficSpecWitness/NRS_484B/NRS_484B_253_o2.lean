/-
  Witnesses for NRS_484B_253_o2.

  Geometry (+x east, +y north, metres): intersection 10 is the square (−10, −10)–(10, 10). Lane 11
  (cx) is the southbound approach x ∈ [−3, 0], y ∈ [10, 100], direction south, entering 10; lane 12
  (cy) is the northbound approach x ∈ [0, 3], y ∈ [−30, −10], direction north, entering 10. The
  directions are opposed (dot product −1).

  Bodies: every road user is a motor vehicle of half-length 2 m, half-width 1 m. x is track 1, the
  left-turner y is track 2, an oncoming vehicle z (branch_2 only) is track 3. Occupancy is stated
  per scene from the footprints (a body across a lane end and the intersection occupies both).
  y is declared to intend a left turn at 10 (idle: declared not to). Instants are 1 s apart
  (k = 0 … 12); each scene's speed and yaw rate are held over the interval before it, so positions
  and headings integrate exactly (a turn is a quarter turn at 90 deg/s).

  forbid: y, indicator left throughout, drives north at 4 m/s along x = 1.5: off cy at k = 0, onto
  cy at k = 1, across its end into 10 at k = 6, stops at (1.5, −2) at k = 9; while it moves x is
  at least 30 m off with a closing time above 3.5 s, so no conflict. At k = 12 y turns left
  standing (heading north → west, yaw rate 90 deg/s). x drives south at 5 m/s along x = −1.5 and at
  k = 12 is at (−1.5, 10), across cx's end and 10, moving: predicted closest approach of the
  centres 3 m in 2.4 s.
  permit: x stops on cx at (−1.5, 15) (outside 10) from k = 6; y turns left moving at k = 9 (north →
  west, 4 m/s, away from x), leaves 10 by k = 12; x enters 10 at k = 12.
  idle: y drives straight north through 10 (yaw rate 0) and is declared not to intend a left turn.
  blind: the forbid scene with the turn indicator and arm signals unobserved.
  branch_1: the forbid scene with y's indicator off and no arm signal.
  branch_2: as forbid, but z comes south from cx ahead of x and is within 10 at k = 8 and 9 while y
  moves (north at 4 m/s at k = 8, turning west at 1 m/s at k = 9): predicted closest approach of
  y and z about 1 m within 1.1 s, so y has not complied with NRS_484B_253_o1; y then stands at
  (0.5, −2) and at k = 12 turns further left standing (west → south) as x enters 10.
  branch_3: the forbid scene with y's indicator off and an arm signal (left) throughout.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def structures : List Structure :=
  [ Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
  , Build.lane 11 [(m (-3), m 10), (m 0, m 10), (m 0, m 100), (m (-3), m 100)] Build.south (enters := some 10)
  , Build.lane 12 [(m 0, m (-30)), (m 3, m (-30)), (m 3, m (-10)), (m 0, m (-10))] Build.north (enters := some 10) ]

/-- A motor vehicle at `(px, py)` (centimetres) with its heading, speed (cm/s), yaw rate (deg/s),
    signals and the regions its footprint overlaps. -/
def place (track : TrackId) (px py : Int) (h : Vec) (speed : Int) (yaw : Int) (regions : List RegionId)
    (ind : TurnIndicatorState := .off) (hand : HandSignal := .noSignal) : RoadUser × List (TrackId × RegionId) :=
  let u := Build.user track [.motorVehicle] (cm px, cm py) h (cm speed) (m 2, m 1, cm 75)
  let u := Build.withKin u fun k => { k with yawRate := some (Units.degrees yaw) }
  let u := Build.withSignals u fun s => { s with turnIndicator := some ind, handSignal := some hand }
  (u, regions.map fun r => (track, r))

def intentOf (turnLeft : Bool) : List DeclaredIntent :=
  [{ vehicle := 2, target := 10, values := [("int.turn_left", turnLeft)] }]

def sceneOf (t : Timestamp) (parts : List (RoadUser × List (TrackId × RegionId))) (turnLeft : Bool := true) : Scene :=
  Build.scene t (some 1) (parts.map (·.1)) structures [] (occupies := some (parts.flatMap (·.2)))
    (intents := intentOf turnLeft)

def instants : Nat := 13

/-- x coming south on cx at 5 m/s, across the lane end into 10 at k = 12. -/
def xApproach (k : Nat) : RoadUser × List (TrackId × RegionId) :=
  place 1 (-150) (1000 + 500 * (12 - (k : Int))) Build.south 500 0 (if k ≥ 12 then [11, 10] else [11])

/-- y's regions while it drives north along x = 1.5 m (centre at `py` cm). -/
def yRegions (py : Int) : List RegionId :=
  if py < -3200 then [] else if py < -1200 then [12] else if py ≤ -800 then [12, 10] else [10]

/-- y driving north at 4 m/s, off cy at k = 0, into 10 at k = 6, at (1.5, −2) at k = 8. -/
def yNorth (k : Nat) (ind : TurnIndicatorState) (hand : HandSignal) : RoadUser × List (TrackId × RegionId) :=
  let py : Int := -3400 + 400 * (k : Int)
  place 2 150 py Build.north 400 0 (yRegions py) ind hand

/-- y as in forbid: stops at (1.5, −2) and turns left standing at k = 12. -/
def yForbid (ind : TurnIndicatorState) (hand : HandSignal) (k : Nat) : RoadUser × List (TrackId × RegionId) :=
  if k ≤ 8 then yNorth k ind hand
  else if k < 12 then place 2 150 (-200) Build.north 0 0 [10] ind hand
  else place 2 150 (-200) Build.west 0 90 [10] ind hand

def forbidLike (ind : TurnIndicatorState) (hand : HandSignal) : Trace :=
  Build.trace instants 0 (Units.seconds 1) fun k t =>
    sceneOf t [xApproach k, yForbid ind hand k]

/-- `forbid` (violated): y occupies i with int.turn_left y i, entered from cy heading north, showed sig.turn_indicator left on cy, yielded to oncoming traffic (no conflict while it moved), and is now turning left (yaw rate 15 deg/s). x approaches on cx heading south and moves into i; predicted closest approach 1 m in 1.2 s. -/
def forbidTrace : Trace := forbidLike .left .noSignal

/-- `permit` (compliant): Same, but x halts on cx short of i until y has cleared, then enters. -/
def permitTrace : Trace :=
  Build.trace instants 0 (Units.seconds 1) fun k t =>
    let x :=
      if k ≤ 5 then place 1 (-150) (1500 + 500 * (5 - (k : Int))) Build.south 500 0 [11]
      else if k < 12 then place 1 (-150) 1500 Build.south 0 0 [11]
      else place 1 (-150) 1000 Build.south 500 0 [11, 10]
    let y :=
      if k ≤ 8 then yNorth k .left .noSignal
      else if k = 9 then place 2 (-250) (-200) Build.west 400 90 [10] .left
      else if k = 10 then place 2 (-650) (-200) Build.west 400 0 [10] .off
      else if k = 11 then place 2 (-1050) (-200) Build.west 400 0 [10] .off
      else place 2 (-1450) (-200) Build.west 400 0 [] .off
    sceneOf t [x, y]

/-- `idle` (not_applicable): x approaches i on cx; no vehicle within i is turning left. -/
def idleTrace : Trace :=
  Build.trace instants 0 (Units.seconds 1) fun k t =>
    let py : Int := -3400 + 400 * (k : Int)
    let y := place 2 150 py Build.north 400 0 (if py > 1200 then [] else yRegions py)
    sceneOf t [xApproach k, y] (turnLeft := false)

/-- `blind` (unknown): As forbid, but neither the turn indicator nor arm signals are observed, so whether y gave a signal is unknown. -/
def blindTrace : Trace := forbidLike .left .noSignal

/-- `branch_1` (not_applicable): As forbid, but y showed no signal (sig.turn_indicator off and sig.hand_signal no_signal throughout its approach). -/
def branch_1Trace : Trace := forbidLike .off .noSignal

/-- `branch_2` (not_applicable): As forbid, but y moved into its turn earlier while an oncoming vehicle within i was in predicted conflict, so y has not complied with NRS_484B_253_o1. -/
def branch_2Trace : Trace :=
  Build.trace instants 0 (Units.seconds 1) fun k t =>
    let y :=
      if k ≤ 8 then yNorth k .left .noSignal
      else if k = 9 then place 2 50 (-200) Build.west 100 90 [10] .left
      else if k < 12 then place 2 50 (-200) Build.west 0 0 [10] .left
      else place 2 50 (-200) Build.south 0 90 [10] .left
    -- z: south at 5 m/s along x = −1.5, 22 m ahead of x; within 10 from k = 8
    let zy : Int := 300 + 500 * (9 - (k : Int))
    let z := place 3 (-150) zy Build.south 500 0
      (if zy > 1200 then [11] else if zy ≥ 800 then [11, 10] else [10])
    sceneOf t [xApproach k, y, z]

/-- `branch_3` (violated): as forbid, but y signals the turn by arm (sig.hand_signal left) with its
    turn indicator off: the arm signal alone is a signal given. -/
def branch_3Trace : Trace := forbidLike .off .left

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o2"
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
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator", "sig.hand_signal"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_253_o2
