/-
  Witnesses for LVMC_11_43_010_C1.

  Geometry (the witness's own figures; none appears in the rule). The roundabout r (region 10) is
  the square (0,0)–(15,15). Its circulation is unrolled schematically along +x: two lanes of one
  direction (east) run through it, the outer lane 12 (y 0–4, ordinal 2 of 2, left neighbour 11)
  and the inner lane 11 (y 4–8, ordinal 1 of 2, the leftmost, right neighbour 12). Nothing is
  built west of x = 0 or east of x = 15.

  The subject (track 1, a motor vehicle, half-extent 2.25 × 0.9 × 0.75 m) moves along a lane's
  centre line (y = 2 in the outer lane, y = 6 in the inner) at 0.5 m per scene (10 m/s),
  x = −3.5 m at scene 0. Scenes are 50 ms apart (the acquisition standard's step), 46 scenes,
  t = 0 … 2250 ms. Occupancy is the footprint's overlap: the body is clear of r at scenes 0–2
  (front at −0.25 m at scene 2), enters r at scene 3 (front at +0.25 m, t = 150 ms), is in r
  through scene 41 (rear at 14.75 m) and leaves at scene 42 (rear at 15.25 m, t = 2100 ms):
  1.95 s inside. Its footprint stays inside one lane (y 1.1–2.9 or 5.1–6.9).
  Its yaw rate is the same at every scene: +45 °/s integrates to ≈ +88° (a left turn, inside
  [45°, 135°) with a wide margin on both sides), +90 °/s to ≈ +176° (a U-turn, inside
  [135°, 225°]), −45 °/s to ≈ −88° (a right turn: in neither band). Because the circulation is
  unrolled, the heading field shows east, skewed by ±1/1000 on alternate scenes so that no two
  consecutive headings are parallel (the trace check needs this when the yaw rate is non-zero);
  the rule does not read the heading.

  Every witness judges t = 50 … 2250 ms (`window`), leaving out scene 0 which has no predecessor.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_C1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_C1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The roundabout and its two lanes (ordinal 1 inner/leftmost, ordinal 2 outer). -/
def structures : List Structure :=
  [ Build.rect 10 .roundabout (m 0) (m 0) (m 15) (m 15)
  , Build.lane 11 [(m 0, m 4), (m 15, m 4), (m 15, m 8), (m 0, m 8)] Build.east
      none (some 12) (some 1) (some 2)
  , Build.lane 12 [(m 0, m 0), (m 15, m 0), (m 15, m 4), (m 0, m 4)] Build.east
      (some 11) none (some 2) (some 2) ]

/-- Lane centre lines: outer lane (ordinal 2) and inner lane (ordinal 1). -/
def yOuter : Q := m 2
def yInner : Q := m 6

/-- The unrolled heading: east, skewed by ±1/1000 alternately so that no two consecutive headings
    are parallel (the yaw rate turns the body between every two scenes). -/
def heading (k : Nat) : Vec :=
  if k % 2 == 0 then (Q.ofInt 1, Units.ratio 1 1000) else (Q.ofInt 1, Units.ratio (-1) 1000)

/-- A passage through r along lane centre `y` at constant yaw rate `yaw` (°/s). -/
def passage (y : Q) (yaw : Q) : Trace :=
  Build.trace 46 0 (Units.milliseconds 50) fun k t =>
    let x := cm (50 * (Int.ofNat k) - 350)
    let u := Build.withKin (Build.user 1 [.motorVehicle] (x, y) (heading k) (Units.metresPerSecond 10)
      (cm 225, cm 90, cm 75)) fun kn => { kn with yawRate := some yaw }
    Build.scene t (some 1) [u] structures []

/-- `forbid` (violated): A two-lane roundabout r (st.roundabout) whose circulatory and approach lanes carry st.lane_adjacency ordinals 1 (inner, leftmost) and 2 (outer). The subject, a passenger car (ru.motor_vehicle), enters r heading east in the lane of ordinal 2, circulates counter-clockwise in the outer lane and leaves r heading north: its yaw rate, observed at every scene at the sampling standard, integrates to a quarter turn to the left since the entry. At the exit the left turn through r is recognized; the subject occupied a lane of ordinal 2 within r. -/
def forbidTrace : Trace := passage yOuter (Units.degrees 45)

/-- `permit` (compliant): Same roundabout and the same left turn, but the subject enters and circulates in the lane of ordinal 1 only and leaves r heading north. -/
def permitTrace : Trace := passage yInner (Units.degrees 45)

/-- `idle` (not_applicable): Same roundabout; the subject enters heading east in the lane of ordinal 2 and leaves at the first exit heading south, a quarter turn to the right since the entry: no left turn or U-turn is recognized. -/
def idleTrace : Trace := passage yOuter (Units.degrees (-45))

/-- `blind` (unknown): As in forbid, but the source does not supply lane ordinals (st.lane_adjacency absent): which lane the subject used is unknown. -/
def blindTrace : Trace := passage yOuter (Units.degrees 45)

/-- `branch_1` (violated): Same roundabout; the subject enters heading east in the lane of ordinal 2, circulates and leaves heading west, a half turn to the left since the entry: a U-turn through r made from the outer lane. -/
def branch_1Trace : Trace := passage yOuter (Units.degrees 90)

/-- `branch_2` (compliant): Same roundabout; the subject makes the U-turn of branch_1 in the lane of ordinal 1 throughout. -/
def branch_2Trace : Trace := passage yInner (Units.degrees 90)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_43_010_C1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (50, 2250)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.LVMC_11_43_010_C1
