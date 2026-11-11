/-
  Witnesses for NRS_484B_253_o2.

  Geometry (world frame, metres): intersection 10 is the square [-10, 10]². Approach lanes:
  11 southbound from the north (x ∈ [-5, 0], y ∈ [10, 200], enters 10) — x's carrier c;
  12 northbound from the south (x ∈ [0, 5], y ∈ [-40, -10], enters 10) — y's carrier c2;
  13 northbound upstream of 12 (y ∈ [-200, -40], leads to 12, enters nothing);
  14 westbound from the east (x ∈ [10, 200], y ∈ [0, 5], enters 10), perpendicular to 12;
  15 westbound exit to the west of 10 (enters nothing). Bodies are 4 m × 2 m.

  Instants every second; headings follow the yaw rate held over the interval before each scene.
  y (track 2): k=0 on 13; k=1 arrives on 12 (indicator left from here on); k=4 enters 10
  straddling 12 and 10 (stated); k=5 halted in 10; k=6 begins its left turn in 10 (4 m/s, yaw
  12 deg/s), the onset; from k=7 halted in 10 (in branch_3 it completes the turn to the west at
  k=7 and is out of 10 from k=8). x (track 1) drives south on 11 at 4 m/s from y = 104, 68 m from 10 at the onset, and
  enters 10 at k=24, straddling 11 and 10 (stated). In branch_2 x drives at 10 m/s and is 1 m from
  10 at the onset, entering at k=7. Every figure is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def ext : Q × Q × Q := (m 2, m 1, m 1)

def junction : List Structure :=
  [ Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
  , Build.lane 11 (box (-5) 10 0 200) Build.south (enters := some 10)
  , Build.lane 12 (box 0 (-40) 5 (-10)) Build.north (enters := some 10)
  , Build.lane 13 (box 0 (-200) 5 (-40)) Build.north (leadsTo := some [12])
  , Build.lane 14 (box 10 0 200 5) Build.west (enters := some 10)
  , Build.lane 15 (box (-200) 0 (-10) 5) Build.west ]

/-- The turning vehicle y at instant k; `signal` its left indicator from its arrival on 12,
    `leaves` whether it drives out of 10 after the onset. -/
def yUser (k : Nat) (signal leaves : Bool) : RoadUser :=
  let kk : Int := k
  -- the heading 12° left of north (−sin 12°, cos 12°), to five places: the onset's turn over 1 s
  let h12 : Vec := (Units.ratio (-20791) 100000, Units.ratio 97815 100000)
  let (pos, hdg, v, yaw) : Vec × Vec × Q × Q :=
    if k ≤ 3 then ((m 2, m (-46 + 10 * kk)), Build.north, Units.metresPerSecond 10, Q.zero)
    else if k == 4 then ((m 2, m (-9)), Build.north, Units.metresPerSecond 7, Q.zero)
    else if k == 5 then ((m 2, m (-9)), Build.north, Q.zero, Q.zero)
    else if k == 6 then ((m 1, m (-5)), h12, Units.metresPerSecond 4, Units.degrees 12)
    else if !leaves then ((m 1, m (-5)), h12, Q.zero, Q.zero)
    -- branch_3: the remaining 78° of the turn over the next second, then out of 10 westward
    else if k == 7 then ((m (-3), m (-5)), Build.west, Units.metresPerSecond 4, Units.degrees 78)
    else ((m (-3 - 8 * (kk - 7)), m (-5)), Build.west, Units.metresPerSecond 8, Q.zero)
  let u := Build.user 2 [.motorVehicle] pos hdg v ext
  let u := Build.withKin u fun kn => { kn with yawRate := some yaw }
  Build.withSignals u fun s =>
    { s with turnIndicator := some (if signal && k ≥ 1 then .left else .off)
             handSignal := some .noSignal }

/-- x driving straight at a constant speed. -/
def xUser (pos hdg : Vec) (v : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos hdg v ext) fun kn => { kn with yawRate := some Q.zero }

/-- A scene of the junction with x, and y unless `withY` is false; `xExtra` is x's stated overlap
    of its carrier at its entry, y's of 12 at its entry is stated here. -/
def junctionScene (k : Nat) (t : Timestamp) (x : RoadUser) (xExtra : List (TrackId × RegionId))
    (withY : Bool := true) (signal leaves intent : Bool := true) : Scene :=
  let users := if withY then [x, yUser k signal leaves] else [x]
  let extra := (if withY && k == 4 then [((2 : TrackId), (12 : RegionId))] else []) ++ xExtra
  Build.scene t (some 1) users junction []
    (occupies := some (Build.occupancyFromGeometry users junction ++ extra))
    (intents := if withY then [{ vehicle := 2, target := 10, values := [("int.left_turn", intent)] }] else [])

/-- x on 11, 4 m/s, entering 10 at k=24. -/
def xSlow (k : Nat) : RoadUser :=
  let kk : Int := k
  xUser (m (-2), m (104 - 4 * kk)) Build.south (Units.metresPerSecond 4)

def xSlowExtra (k : Nat) : List (TrackId × RegionId) := if k == 24 then [(1, 11)] else []

def lateTrace (signal leaves intent : Bool) : Trace :=
  Build.trace 26 0 (Units.seconds 1) fun k t =>
    junctionScene k t (xSlow k) (xSlowExtra k) (signal := signal) (leaves := leaves) (intent := intent)

/-- `forbid` (violated): The recording begins with y on a carrier upstream of c2; y comes onto c2 (recorded) and shows sig.turn_indicator left on c2, int.left_turn y i declared throughout; y enters i through c2 (recorded) and halts in i. While x on c (opposed to c2, st.lane_enters c i) is farther from i than its speed times p.immediate_hazard_gap, y begins turning left within i (4 m/s, kin.yaw_rate 12 deg/s) and is the only other road user; x keeps its speed, and while y is still within i turning, x enters i through c. -/
def forbidTrace : Trace := lateTrace true false true

/-- `permit` (compliant): x on c enters i as the only road user in the scene. -/
def permitTrace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    let kk : Int := k
    junctionScene k t (xUser (m (-2), m (24 - 4 * kk)) Build.south (Units.metresPerSecond 4))
      (if k == 4 then [(1, 11)] else []) (withY := false)

/-- `idle` (not_applicable): x drives along a road segment and enters no intersection. -/
def idleTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let kk : Int := k
    Build.scene t (some 1)
      [ xUser (m (-2), m (50 - 4 * kk)) Build.south (Units.metresPerSecond 4) ]
      [ Build.lane 20 (box (-5) (-200) 0 200) Build.south ]
      []

/-- `blind` (unknown): As forbid, with y's arrival on c2 and its entry into i recorded, but neither sig.turn_indicator nor sig.hand_signal of y is observed. -/
def blindTrace : Trace := lateTrace true false true

/-- `branch_1` (compliant): As forbid, but y's sig.turn_indicator is off and sig.hand_signal no_signal at every observation: y gave no signal, and x owes it no precedence under this duty. -/
def branch_1Trace : Trace := lateTrace false false true

/-- `branch_2` (compliant): As forbid in every respect but one: y begins its turn within i while x on c is within the immediate-hazard bound of i (its distance to i at most its speed times p.immediate_hazard_gap), so NRS_484B_253_o1 is not complied with by y at the onset: y has not so yielded. -/
def branch_2Trace : Trace :=
  Build.trace 12 0 (Units.seconds 1) fun k t =>
    let kk : Int := k
    junctionScene k t (xUser (m (-2), m (73 - 10 * kk)) Build.south (Units.metresPerSecond 10))
      (if k == 7 then [(1, 11)] else [])

/-- `branch_3` (compliant): As forbid, but y completes its turn and leaves i before x enters i. -/
def branch_3Trace : Trace := lateTrace true true true

/-- `branch_4` (compliant): As forbid, but x enters i from a carrier whose designated direction is perpendicular to that of c2: x does not approach from the opposite direction. -/
def branch_4Trace : Trace :=
  Build.trace 26 0 (Units.seconds 1) fun k t =>
    let kk : Int := k
    junctionScene k t (xUser (m (104 - 4 * kk), m 2) Build.west (Units.metresPerSecond 4))
      (if k == 24 then [(1, 14)] else [])

/-- `branch_5` (compliant): As forbid, but the source declares int.left_turn y i false: y is not a driver intending to turn left. -/
def branch_5Trace : Trace := lateTrace true false false

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") (last : Nat := 25) : Scenario :=
  { name := name
    rule := "NRS_484B_253_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (1000, last * 1000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant (last := 5)
  , witness "idle" idleTrace .notApplicable (last := 4)
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator", "sig.hand_signal"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant (last := 11)
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_253_o2
