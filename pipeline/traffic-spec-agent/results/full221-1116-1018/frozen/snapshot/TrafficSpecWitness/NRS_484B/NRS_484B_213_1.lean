/-
  Witnesses for NRS_484B_213_1.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - A straight east–west highway (region 10) with a centre line (13, a 20 cm strip at y = 0).
    Two-lane: eastbound lane 11 (y ∈ [−4, 0]) and westbound lane 12 (y ∈ [0, 4]), each the single
    lane of its direction. Four-lane: lanes 11 and 14 (y ∈ [−8, −4]) eastbound, 12 and 15
    (y ∈ [4, 8]) westbound, two in each direction. Every lane and the centre line lie on 10.
    Where the sight distance changes along the road, the road is two consecutive two-lane
    segments (10 with 11, 12, 13; 20 with 21, 22, 23), each with its own sight distance.
  - Observations every second, k = 0 … 27, phase j = k − 10 s. The subject (track 1, car, 15 m/s
    east) is at x = 15j; the passed vehicle b (track 2, car, 10 m/s east) at x = 10j + 55 in the
    eastbound lane (y = −2). b is ahead with no longitudinal overlap through j = 9 (gap 10 m),
    alongside at j = 10 … 12, and behind with a 5 m gap at j = 13: the pass is recognized at
    j = 13 and the act runs from j = 9 to j = 13; the 10 s window behind j = 13 starts at j = 3,
    and every other road user's 10 s window is inside the trace too.
  - In the passes on the left, the subject is in the westbound lane (y = +2, left of the centre
    line) at j = 7 … 14 and in its own lane (y = −2) otherwise. Its lateral clearance to b is 4 m.
  - Required distance: 15 m/s × p.passing_sight_time (11 s) = 165 m. Ample sight is 500 m, short
    sight 100 m. An oncoming car (track 3, 15 m/s west) starting at x0 closes on the subject at
    30 m/s: centre distance x0 − 30k.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_213_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_213_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

def carExt : Q × Q × Q := (cm 250, m 1, cm 75)
def mopedExt : Q × Q × Q := (m 1, cm 40, cm 75)

def ample : Q := m 500
def short : Q := m 100

-- ---------------------------------------------------------------------------------------------
-- Roads
-- ---------------------------------------------------------------------------------------------
def strip (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def onWay (w : RegionId) (s : Structure) : Structure := { s with ways := some [w] }

/-- A two-lane highway segment `w` from x0 to x1, with its lanes `le` (east) and `lw` (west), its
    centre line `c`, and the sight distance of its places. -/
def segment (w le lw c : RegionId) (x0 x1 : Int) (sight : Q) : List Structure :=
  [ { Build.rect w .highway (m x0) (m (-6)) (m x1) (m 6) with sightDistance := some sight }
  , onWay w (Build.lane le (strip x0 (-4) x1 0) Build.east (ordinal := some 1) (count := some 1))
  , onWay w (Build.lane lw (strip x0 0 x1 4) Build.west (ordinal := some 1) (count := some 1))
  , onWay w (Build.rect c .centreLine (m x0) (cm (-10)) (m x1) (cm 10)) ]

def twoLaneRoad (sight : Q) : List Structure := segment 10 11 12 13 (-500) 1200 sight

/-- Two consecutive two-lane segments meeting at x = xs, with sight `before` and `after`. -/
def splitRoad (xs : Int) (before after : Q) : List Structure :=
  segment 10 11 12 13 (-500) xs before ++ segment 20 21 22 23 xs 1200 after

def fourLaneRoad (sight : Q) : List Structure :=
  [ { Build.rect 10 .highway (m (-500)) (m (-10)) (m 1200) (m 10) with sightDistance := some sight }
  , onWay 10 (Build.lane 11 (strip (-500) (-4) 1200 0) Build.east (right := some 14) (ordinal := some 1) (count := some 2))
  , onWay 10 (Build.lane 14 (strip (-500) (-8) 1200 (-4)) Build.east (left := some 11) (ordinal := some 2) (count := some 2))
  , onWay 10 (Build.lane 12 (strip (-500) 0 1200 4) Build.west (right := some 15) (ordinal := some 1) (count := some 2))
  , onWay 10 (Build.lane 15 (strip (-500) 4 1200 8) Build.west (left := some 12) (ordinal := some 2) (count := some 2))
  , onWay 10 (Build.rect 13 .centreLine (m (-500)) (cm (-10)) (m 1200) (cm 10)) ]

-- ---------------------------------------------------------------------------------------------
-- Road users
-- ---------------------------------------------------------------------------------------------
-- `j` is the phase of the pass in seconds: observation k (at t = k s) has j = k − 10.
def subjectAt (j : Int) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (15 * j), y) Build.east (mps 15) carExt
def passedAt (j : Int) (y : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (10 * j + 55), y) Build.east (mps 10) carExt
def oncomingAt (x0 : Int) (y : Q) (j : Int) : RoadUser :=
  Build.user 3 [.motorVehicle] (m (x0 - 15 * j), y) Build.west (mps 15) carExt

/-- The subject is out of its lane at j = 7 … 14. -/
def outPhase (j : Int) : Bool := decide (7 ≤ j) && decide (j ≤ 14)
/-- The subject's lateral place in a pass on the left of the centre line. -/
def leftPass (j : Int) : Q := if outPhase j then m 2 else m (-2)

def passTrace (road : List Structure) (users : Int → List RoadUser) : Trace :=
  Build.trace 28 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (users ((k : Int) - 10)) road []

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): On a highway with a centre line and one lane in each direction, the subject moves left of the centre line to pass b; a road user u of traffic is oncoming in that lane at a centre distance below the subject's speed times p.passing_sight_time, and its closest approach within p.conflict_horizon falls below p.conflict_centre_clearance; the pass is recognized.
    Oncoming car from x0 = 450 in the westbound lane: 150 m at k = 10, 60 m at k = 13 (head-on,
    closest approach in 2 s at 0 m). -/
def forbidTrace : Trace :=
  passTrace (twoLaneRoad ample)
    (fun j => [subjectAt j (leftPass j), passedAt j (m (-2)), oncomingAt 450 (m 2) j])

/-- `permit` (compliant): The same pass with st.sight_distance at the subject's point far above its speed times p.passing_sight_time at every observation of the act and no oncoming road user in the scene; the subject keeps clear of b. -/
def permitTrace : Trace :=
  passTrace (twoLaneRoad ample)
    (fun j => [subjectAt j (leftPass j), passedAt j (m (-2))])

/-- `idle` (not_applicable): The subject follows b on the two-lane highway without passing it.
    Both at 10 m/s in the eastbound lane, b 30 m ahead throughout. -/
def idleTrace : Trace :=
  passTrace (twoLaneRoad ample)
    (fun j =>
      [ Build.user 1 [.motorVehicle] (m (10 * j), m (-2)) Build.east (mps 10) carExt
      , Build.user 2 [.motorVehicle] (m (10 * j + 30), m (-2)) Build.east (mps 10) carExt ])

/-- `blind` (unknown): The pass of permit with st.sight_distance not observed on the source. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["st.sight_distance"]) permitTrace

/-- `branch_1` (compliant): The subject passes b on a highway with two lanes in each direction, using the other lane of its own direction, with an oncoming vehicle near on the far side of the centre line: the subject is never left of the centre of a two-lane highway.
    b in the outer eastbound lane (y = −6); the subject moves to the inner eastbound lane (y = −2);
    the oncoming car from x0 = 450 in the inner westbound lane (y = +2). -/
def branch_1Trace : Trace :=
  passTrace (fourLaneRoad ample)
    (fun j => [subjectAt j (if outPhase j then m (-2) else m (-6)), passedAt j (m (-6)), oncomingAt 450 (m 2) j])

/-- `branch_2` (compliant): on the two-lane highway the subject passes a moped riding at the right
    edge of the eastbound lane without leaving its lane (y = −1, right of the centre line), with an
    oncoming car near and closing: never left of the centre, so the duty does not arise. -/
def branch_2Trace : Trace :=
  passTrace (twoLaneRoad short)
    (fun j =>
      [ subjectAt j (cm (-100))
      , Build.user 2 [.moped] (m (10 * j + 55), cm (-320)) Build.east (mps 10) mopedExt
      , oncomingAt 450 (m 2) j ])

/-- `branch_3` (compliant): on a highway with two lanes in each direction the subject crosses the
    centre line to pass b (y = +2) with sight short and an oncoming car in the outer westbound lane
    (y = +6) within the required distance: not a two-lane highway, so this duty does not arise. -/
def branch_3Trace : Trace :=
  passTrace (fourLaneRoad short)
    (fun j => [subjectAt j (leftPass j), passedAt j (m (-2)), oncomingAt 450 (m 6) j])

/-- `branch_4` (violated): a slow pass (subject 8 m/s past b at 4 m/s, b 46 m ahead at j = 0;
    beginning j = 10, recognition j = 13; required distance 88 m) with ample sight and an
    oncoming car at 35 m/s that stays beyond the required distance at every observation of the act
    (100 m at j = 13) but is head-on within p.conflict_horizon there (closest approach in 2.3 s at
    0 m): only the interference with an oncoming vehicle breaks the duty. -/
def branch_4Trace : Trace :=
  passTrace (twoLaneRoad ample)
    (fun j =>
      [ Build.user 1 [.motorVehicle] (m (8 * j), leftPass j) Build.east (mps 8) carExt
      , Build.user 2 [.motorVehicle] (m (4 * j + 46), m (-2)) Build.east (mps 4) carExt
      , Build.user 3 [.motorVehicle] (m (659 - 35 * j), m 2) Build.west (mps 35) carExt ])

/-- `branch_5` (violated): the pass of permit with the subject only just over the centre line
    (y = +1) and b hugging it (y = −1.2): no contact (0.2 m apart) and no oncoming traffic, but the
    closest approach to b within p.conflict_horizon is 2.2 m: the vehicle overtaken is interfered
    with. -/
def branch_5Trace : Trace :=
  passTrace (twoLaneRoad ample)
    (fun j => [subjectAt j (if outPhase j then cm 100 else m (-2)), passedAt j (cm (-120))])

/-- `branch_6` (violated): the subject draws past b (b at x = 10j + 57, y = −1.2; beginning j = 10,
    recognition j = 13) 3.2 m clear of it, but at j = 12, b's centre 3 m behind its own, it cuts
    towards b (y = +0.7) and the bodies touch: a contact while the centres already separate. -/
def branch_6Trace : Trace :=
  passTrace (twoLaneRoad ample)
    (fun j =>
      [ subjectAt j (if j = 12 then cm 70 else leftPass j)
      , Build.user 2 [.motorVehicle] (m (10 * j + 57), cm (-120)) Build.east (mps 10) carExt ])

/-- `branch_7` (violated): the pass of permit on a road whose sight distance is short only on the
    stretch x ∈ [127, 142], where the subject is at the act's beginning (j = 9, x = 135), and ample
    everywhere else: the duty is required from the act's beginning. -/
def branch_7Trace : Trace :=
  passTrace (segment 10 11 12 13 (-500) 127 ample ++ segment 20 21 22 23 127 142 short
      ++ segment 30 31 32 33 142 1200 ample)
    (fun j => [subjectAt j (leftPass j), passedAt j (m (-2))])

/-- `occasion_s5` (violated): While the subject is left of the centre line, st.sight_distance at its point is above the subject's speed times p.passing_sight_time for the first part of the act and falls below it approaching a crest; no oncoming traffic.
    Sight 500 m on the segment before x = 172 (the subject's places through j = 11), 100 m on the
    segment after it (from j = 12, x = 180). -/
def occasion_s5Trace : Trace :=
  passTrace (splitRoad 172 ample short)
    (fun j => [subjectAt j (leftPass j), passedAt j (m (-2))])

/-- `occasion_s5_outside` (compliant): st.sight_distance was below the bound before the act began and is above it at every observation of the act; no oncoming traffic.
    Sight 100 m on the segment before x = 127 (the subject's places through j = 8, already left of
    the centre line at j = 7, 8 with b still ahead with a gap), 500 m after it (from j = 9, x = 135,
    the act's beginning). -/
def occasion_s5_outsideTrace : Trace :=
  passTrace (splitRoad 127 short ample)
    (fun j => [subjectAt j (leftPass j), passedAt j (m (-2))])

/-- `occasion_s6` (violated): Sight distance is ample; an oncoming road user of traffic comes within the required distance during the second half of the act while the subject is still left of the centre line.
    Oncoming car from x0 = 510: 180 m at j = 11, 150 m at j = 12, 120 m at j = 13 (closest
    approach beyond the conflict horizon). -/
def occasion_s6Trace : Trace :=
  passTrace (twoLaneRoad ample)
    (fun j => [subjectAt j (leftPass j), passedAt j (m (-2)), oncomingAt 510 (m 2) j])

/-- `occasion_s6_outside` (compliant): An oncoming road user passed the subject before the act began; during the act no oncoming road user is within the required distance.
    Oncoming car from x0 = 200 meets the subject at j ≈ 6.7, while the subject is still in its own
    lane; from j = 7 it is behind and receding. -/
def occasion_s6_outsideTrace : Trace :=
  passTrace (twoLaneRoad ample)
    (fun j => [subjectAt j (leftPass j), passedAt j (m (-2)), oncomingAt 200 (m 2) j])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_213_1"
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
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "occasion_s5" occasion_s5Trace .violated
  , witness "occasion_s5_outside" occasion_s5_outsideTrace .compliant
  , witness "occasion_s6" occasion_s6Trace .violated
  , witness "occasion_s6_outside" occasion_s6_outsideTrace .compliant ]

end TrafficSpecWitness.NRS_484B_213_1
