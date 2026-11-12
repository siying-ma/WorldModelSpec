/-
  Witnesses for NRS_484B_227_1_o3.

  The divided highway runs east–west: highway 100 (x −300…300, y −40…40), the eastbound roadway 101
  (y −14…−2), the median 102 (y −2…2, no opening) and the westbound roadway 103 (y 2…14), each lying
  on 100. Variants split the median around an opening (opening attribute set) or around an
  intersection 105 with a cross street (highway 106), or drop the median (an undivided road).

  Ego (track 1, a motor vehicle, half-extents 2 m × 1 m × 1 m) is sampled every second for 42 s.
  Up to t = 32 s it drives straight (yaw rate zero) at 5 m/s; from t = 33 s it turns at 25 deg/s
  (a left turn of 100°, recognized at 75°) or 35–40 deg/s (a U-turn of 175°–185°, its left-turn
  phase recognized at 70°–80°, the U-turn at 160°–175°), well inside each band of the reading
  (left 60°…150°, U-turn 150°…210°, yaw tolerance 5 deg/s). Each witness speaks about t = 30…41 s,
  where every turn window (15 s) and the under-way search behind it are covered by the trace.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def degPerS (n : Int) : Q := Units.degrees n

-- Binders ↦ tracks: ego ↦ 1

def v (x y : Int) : Vec := (m x, m y)

/-- A pose of the turn: position, heading, yaw rate (deg/s). -/
abbrev Pose := Vec × Vec × Q

def pose (x y hx hy : Int) (yaw : Int) : Pose := (v x y, v hx hy, degPerS yaw)

def ego (p h : Vec) (speed : Q) (yaw : Option Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] p h speed (m 2, m 1, m 1)) fun k => { k with yawRate := yaw }

-- Structures
def highway (id : RegionId) (x0 y0 x1 y1 : Int) : Structure :=
  Build.rect id .highway (m x0) (m y0) (m x1) (m y1)
def roadway (id : RegionId) (x0 y0 x1 y1 : Int) (way : RegionId) : Structure :=
  { Build.rect id .roadway (m x0) (m y0) (m x1) (m y1) with ways := some [way] }
def median (id : RegionId) (x0 y0 x1 y1 : Int) (way : RegionId) (opening : Bool) : Structure :=
  { Build.rect id .medianOrDivider (m x0) (m y0) (m x1) (m y1) with ways := some [way], opening := some opening }
def intersection (id : RegionId) (x0 y0 x1 y1 : Int) (ways : List RegionId) : Structure :=
  { Build.rect id .intersection (m x0) (m y0) (m x1) (m y1) with ways := some ways }
def driveway (id : RegionId) (x0 y0 x1 y1 : Int) : Structure :=
  Build.rect id .drivewayOrAlleyEntrance (m x0) (m y0) (m x1) (m y1)

/-- A: divided highway with a solid median along its whole length; a driveway north of it. -/
def layoutA : List Structure :=
  [ highway 100 (-300) (-40) 300 40
  , roadway 101 (-300) (-14) 300 (-2) 100
  , median 102 (-300) (-2) 300 2 100 false
  , roadway 103 (-300) 2 300 14 100
  , driveway 104 0 15 30 40 ]

/-- B: the divided highway crossed by a street (highway 106) at intersection 105; the median ends
    at the intersection; the cross street's roadway 108 runs north. -/
def layoutB : List Structure :=
  [ highway 100 (-300) (-40) 300 40
  , highway 106 (-10) (-40) 10 40
  , roadway 101 (-300) (-14) 300 (-2) 100
  , median 102 (-300) (-2) (-10) 2 100 false
  , median 107 10 (-2) 300 2 100 false
  , roadway 103 (-300) 2 300 14 100
  , intersection 105 (-10) (-14) 10 14 [100, 106]
  , roadway 108 (-10) 14 10 40 106 ]

/-- C: the median opened (crossover) at x −6…6; a driveway north. -/
def layoutC : List Structure :=
  [ highway 100 (-300) (-40) 300 40
  , roadway 101 (-300) (-14) 300 (-2) 100
  , median 102 (-300) (-2) (-6) 2 100 false
  , median 107 (-6) (-2) 6 2 100 true
  , median 109 6 (-2) 300 2 100 false
  , roadway 103 (-300) 2 300 14 100
  , driveway 104 (-7) 15 7 40 ]

/-- D: the median opened at x −40…−28 only; a driveway north at x 0…14. -/
def layoutD : List Structure :=
  [ highway 100 (-300) (-40) 300 40
  , roadway 101 (-300) (-14) 300 (-2) 100
  , median 102 (-300) (-2) (-40) 2 100 false
  , median 107 (-40) (-2) (-28) 2 100 true
  , median 109 (-28) (-2) 300 2 100 false
  , roadway 103 (-300) 2 300 14 100
  , driveway 104 0 15 14 40 ]

/-- E: the divided highway ends at x = 0, where an undivided street (highway 110, one two-way
    roadway 111) continues east. -/
def layoutE : List Structure :=
  [ highway 100 (-300) (-40) 0 40
  , roadway 101 (-300) (-14) 0 (-2) 100
  , median 102 (-300) (-2) 0 2 100 false
  , roadway 103 (-300) 2 0 14 100
  , highway 110 0 (-40) 300 40
  , roadway 111 0 (-14) 300 14 110
  , driveway 104 50 15 80 40 ]

/-- F: an undivided two-way road: one roadway, no median. -/
def layoutF : List Structure :=
  [ highway 100 (-300) (-40) 300 40
  , roadway 101 (-300) (-14) 300 14 100
  , driveway 104 0 15 30 40 ]

/-- G: a wide median (y −6…6) with a crossover opening at x −8…8. -/
def layoutG : List Structure :=
  [ highway 100 (-300) (-40) 300 40
  , roadway 101 (-300) (-18) 300 (-6) 100
  , median 102 (-300) (-6) (-8) 6 100 false
  , median 107 (-8) (-6) 8 6 100 true
  , median 109 8 (-6) 300 6 100 false
  , roadway 103 (-300) 6 300 18 100 ]

/-- Ego heading east at 5 m/s, at `x32` at t = 32 s. -/
def eastbound (x32 : Int) (y : Q) : Nat → Vec :=
  fun k => (m (x32 + 5 * ((k : Int) - 32)), y)

/-- 42 scenes 1 s apart: the straight approach up to t = 32 s, then the turn's poses; after the last
    pose ego holds it with no yaw. -/
def turnTrace (structures : List Structure) (pre : Nat → Vec) (h0 : Vec) (speed0 : Q)
    (turn : List Pose) (yawSeen : Bool := true) : Trace :=
  Build.trace 42 0 (Units.seconds 1) fun k t =>
    let held : Pose := match turn.getLast? with
      | some (p, h, _) => (p, h, Q.zero)
      | none => (pre 32, h0, Q.zero)
    let (p, h, ω, sp) : Vec × Vec × Q × Q :=
      if k ≤ 32 then (pre k, h0, Q.zero, speed0)
      else match turn[k - 33]? with
        | some (p, h, ω) => (p, h, ω, Units.metresPerSecond 5)
        | none => (held.1, held.2.1, held.2.2, Units.metresPerSecond 5)
    Build.scene t (some 1) [ego p h sp (if yawSeen then some ω else none)] structures []

/-- The left turn across the median of layout A at x ≈ 7, into the driveway: 25 deg/s for 4 s. -/
def leftAcrossA : List Pose :=
  [ pose 4 (-6) 3 1 25, pose 6 (-3) 1 1 25, pose 7 0 1 3 25, pose 7 4 0 1 25
  , pose 7 9 0 1 0, pose 7 14 0 1 0, pose 7 19 0 1 0, pose 7 24 0 1 0 ]

/-- `forbid` (violated): Ego, on the right-hand roadway of a divided highway, turns left across the solid median, where no opening exists, into a driveway on the far side; its left turn is recognized and at no moment of it did ego overlap an opening or an intersection. -/
def forbidTrace : Trace :=
  turnTrace layoutA (eastbound 0 (m (-8))) Build.east (Units.metresPerSecond 5) leftAcrossA

/-- `permit` (compliant): Ego makes a left turn at an intersection of the divided highway; its footprint overlaps the intersection during the turn. -/
def permitTrace : Trace :=
  turnTrace layoutB (eastbound (-12) (m (-8))) Build.east (Units.metresPerSecond 5)
    [ pose (-6) (-7) 3 1 25, pose (-3) (-4) 1 1 25, pose (-1) 0 1 3 25, pose 0 5 0 1 25
    , pose 0 10 0 1 0, pose 0 15 0 1 0, pose 0 20 0 1 0, pose 0 25 0 1 0 ]

/-- `idle` (not_applicable): Ego makes a left turn from a two-way road whose highway carries no median or divider. -/
def idleTrace : Trace :=
  turnTrace layoutF (eastbound 0 (m (-8))) Build.east (Units.metresPerSecond 5) leftAcrossA

/-- `blind` (unknown): Scene of forbid, but the source declares kin.yaw_rate absent: whether ego turned cannot be read. -/
def blindTrace : Trace :=
  turnTrace layoutA (eastbound 0 (m (-8))) Build.east (Units.metresPerSecond 5) leftAcrossA (yawSeen := false)

/-- `branch_1` (violated): Ego reverses direction mid-block on a divided highway by a multi-point U-turn across the median where no opening exists. -/
def branch_1Trace : Trace :=
  -- forward-left onto the median, a stop and a short back-up (no yaw), then forward-left again
  -- onto the westbound roadway: 35+35+35+0+35+35+10 = 185°
  turnTrace layoutA (eastbound 0 (m (-8))) Build.east (Units.metresPerSecond 5)
    [ pose 4 (-6) 10 7 35, pose 6 (-3) 1 3 35, pose 6 0 (-1) 3 35, pose 7 (-3) (-1) 3 0
    , pose 5 1 (-1) 1 35, pose 1 4 (-10) 1 35, pose (-4) 5 (-10) (-1) 10
    , pose (-9) 5 (-10) (-1) 0, pose (-14) 4 (-10) (-1) 0 ]

/-- `branch_2` (compliant): Ego, waiting in a wide median crossover (opening) of the divided highway,
    completes its left turn there before reaching the far roadway: during the turn it overlaps the
    median only, never a roadway. -/
def branch_2Trace : Trace :=
  turnTrace layoutG (fun _ => v 0 (-2)) Build.north Q.zero
    [ pose (-1) 0 (-2) 3 35, pose (-3) 1 (-3) 1 35, pose (-6) 3 (-1) 0 20
    , pose (-10) 9 (-1) 0 0, pose (-15) 9 (-1) 0 0, pose (-20) 9 (-1) 0 0 ]

/-- `branch_3` (violated): Ego starts a U-turn from a lot south of the divided highway: its
    left-turn phase is recognized before it reaches the highway (not applicable there), the U-turn
    is recognized after it has crossed the eastbound roadway and the solid median. -/
def branch_3Trace : Trace :=
  turnTrace layoutA (eastbound 0 (m (-32))) Build.east (Units.metresPerSecond 5)
    [ pose 10 (-29) 10 7 35, pose 17 (-20) 1 3 35, pose 17 (-9) (-1) 4 35, pose 12 0 (-6) 5 35
    , pose 2 4 (-11) 1 35, pose (-3) 4 (-11) 1 0, pose (-8) 5 (-11) 1 0 ]

/-- `occasion_d2` (violated): Ego is on a roadway of the divided highway during the first part of its left turn only, then crosses into a side driveway; at no moment of the turn did it overlap an opening or an intersection. -/
def occasion_d2Trace : Trace :=
  -- 10 deg/s across the highway (40°), then 30 deg/s in the driveway: recognized at 70° there
  turnTrace layoutA (eastbound 0 (m (-8))) Build.east (Units.metresPerSecond 5)
    [ pose 4 (-7) 6 1 10, pose 8 (-5) 3 1 10, pose 11 (-1) 2 1 10, pose 14 5 1 1 10
    , pose 16 18 1 2 30, pose 18 22 1 2 0, pose 20 26 1 2 0, pose 22 30 1 2 0 ]

/-- `occasion_d2_outside` (not_applicable): Ego left the divided highway onto an undivided street before its turn began, then made a left turn there; during the turn it is on no region of a divided highway. -/
def occasion_d2_outsideTrace : Trace :=
  turnTrace layoutE (eastbound 60 (m (-8))) Build.east (Units.metresPerSecond 5)
    [ pose 64 (-6) 3 1 25, pose 66 (-3) 1 1 25, pose 67 0 1 3 25, pose 67 4 0 1 25
    , pose 67 9 0 1 0, pose 67 14 0 1 0, pose 67 19 0 1 0, pose 67 24 0 1 0 ]

/-- `occasion_d7` (compliant): Ego makes a left turn across the median through an opening: during part of the turn its footprint overlaps the median region with the opening attribute set. -/
def occasion_d7Trace : Trace :=
  turnTrace layoutC (eastbound (-7) (m (-8))) Build.east (Units.metresPerSecond 5)
    [ pose (-3) (-6) 3 1 25, pose (-1) (-3) 1 1 25, pose 0 0 1 3 25, pose 0 4 0 1 25
    , pose 0 9 0 1 0, pose 0 14 0 1 0, pose 0 19 0 1 0, pose 0 24 0 1 0 ]

/-- `occasion_d7_outside` (violated): Ego passed through a median opening before its turn began; the turn itself crosses the median where no opening exists and no intersection lies. -/
def occasion_d7_outsideTrace : Trace :=
  -- ego drives along the median's edge (footprint y −3.5…−1.5): it overlaps the opening at
  -- t = 24…26 s, straight, then turns left at x ≈ 4…7 across the solid median 109
  turnTrace layoutD (eastbound 0 (cm (-250))) Build.east (Units.metresPerSecond 5)
    [ pose 4 (-1) 3 1 25, pose 6 2 1 1 25, pose 7 5 1 3 25, pose 7 9 0 1 25
    , pose 7 14 0 1 0, pose 7 19 0 1 0, pose 7 24 0 1 0, pose 7 29 0 1 0 ]

/-- `occasion_d8` (compliant): Ego makes a U-turn whose middle part lies within an intersection of the divided highway. -/
def occasion_d8Trace : Trace :=
  turnTrace layoutB (eastbound (-8) (m (-5))) Build.east (Units.metresPerSecond 5)
    [ pose (-3) (-4) 6 5 40, pose 0 (-1) 1 6 40, pose 0 3 (-6) 10 40, pose (-3) 5 (-3) 1 40
    , pose (-8) 5 (-1) 0 20, pose (-13) 5 (-1) 0 0, pose (-18) 5 (-1) 0 0, pose (-23) 5 (-1) 0 0 ]

/-- `occasion_d8_outside` (violated): Ego was in an intersection of the divided highway only before its U-turn began; it makes the U-turn mid-block across a median with no opening. -/
def occasion_d8_outsideTrace : Trace :=
  -- straight through intersection 105 at t = 18…22 s, U-turn at x ≈ 60…68 across median 107
  turnTrace layoutB (eastbound 60 (m (-5))) Build.east (Units.metresPerSecond 5)
    [ pose 65 (-4) 6 5 40, pose 68 (-1) 1 6 40, pose 68 3 (-6) 10 40, pose 65 5 (-3) 1 40
    , pose 60 5 (-1) 0 20, pose 55 5 (-1) 0 0, pose 50 5 (-1) 0 0, pose 45 5 (-1) 0 0 ]

/-- The instants every witness speaks about: from 30 s, where the turn windows are covered. -/
def judged : Option (Timestamp × Timestamp) := some (30000, 41000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "occasion_d2" occasion_d2Trace .violated
  , witness "occasion_d2_outside" occasion_d2_outsideTrace .notApplicable
  , witness "occasion_d7" occasion_d7Trace .compliant
  , witness "occasion_d7_outside" occasion_d7_outsideTrace .violated
  , witness "occasion_d8" occasion_d8Trace .compliant
  , witness "occasion_d8_outside" occasion_d8_outsideTrace .violated ]

end TrafficSpecWitness.NRS_484B_227_1_o3
